import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../domain/messaging_models.dart';

abstract interface class MessageLocalStore {
  Future<void> saveMessage(LocalMessage message);
  Future<void> updateStatus(String messageId, LocalMessageStatus status);
  Future<List<LocalMessage>> listMessages(String circleId);
  Future<int> readCursor(String circleId, String deviceId);
  Future<void> writeCursor(String circleId, String deviceId, int cursor);
  Future<void> cachePeerIdentity(
    String deviceId,
    DevicePublicIdentity identity,
  );
  Future<DevicePublicIdentity?> readPeerIdentity(String deviceId);
  Future<void> close();
}

class SqliteEncryptedMessageLocalStore implements MessageLocalStore {
  SqliteEncryptedMessageLocalStore(this._secureStorage);

  static const _dbName = 'orbit_messages_v1.db';
  static const _localKeyName = 'orbit.messaging.local_database_key.v1';

  final FlutterSecureStorage _secureStorage;
  final AesGcm _cipher = AesGcm.with256bits();
  Database? _database;
  SecretKey? _localKey;

  Future<Database> get _db async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }
    final root = await getDatabasesPath();
    final db = await openDatabase(
      p.join(root, _dbName),
      version: 1,
      onCreate: (database, _) async {
        await database.execute('''
CREATE TABLE messages (
  message_id TEXT PRIMARY KEY,
  circle_id TEXT NOT NULL,
  sender_user_id INTEGER NOT NULL,
  sender_device_id TEXT NOT NULL,
  direction TEXT NOT NULL,
  type TEXT NOT NULL,
  encrypted_body TEXT NOT NULL,
  created_at TEXT NOT NULL,
  status TEXT NOT NULL
)
''');
        await database.execute(
          'CREATE INDEX idx_messages_circle_created '
          'ON messages(circle_id, created_at)',
        );
        await database.execute('''
CREATE TABLE sync_cursors (
  circle_id TEXT NOT NULL,
  device_id TEXT NOT NULL,
  cursor INTEGER NOT NULL,
  PRIMARY KEY(circle_id, device_id)
)
''');
        await database.execute('''
CREATE TABLE peer_identities (
  device_id TEXT PRIMARY KEY,
  public_identity_key TEXT NOT NULL
)
''');
      },
    );
    _database = db;
    return db;
  }

  @override
  Future<void> saveMessage(LocalMessage message) async {
    final db = await _db;
    await db.insert('messages', <String, Object?>{
      'message_id': message.messageId,
      'circle_id': message.circleId,
      'sender_user_id': message.senderUserId,
      'sender_device_id': message.senderDeviceId,
      'direction': message.direction.name,
      'type': message.type.apiValue,
      'encrypted_body': await _encryptLocal(message.body),
      'created_at': message.createdAt.toUtc().toIso8601String(),
      'status': message.status.name,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> updateStatus(String messageId, LocalMessageStatus status) async {
    final db = await _db;
    final preserveDelivered = status != LocalMessageStatus.delivered;
    await db.update(
      'messages',
      <String, Object?>{'status': status.name},
      where: preserveDelivered
          ? 'message_id = ? AND status != ?'
          : 'message_id = ?',
      whereArgs: preserveDelivered
          ? <Object?>[messageId, LocalMessageStatus.delivered.name]
          : <Object?>[messageId],
    );
  }

  @override
  Future<List<LocalMessage>> listMessages(String circleId) async {
    final db = await _db;
    final rows = await db.query(
      'messages',
      where: 'circle_id = ?',
      whereArgs: <Object?>[circleId],
      orderBy: 'created_at ASC',
      limit: 500,
    );

    final messages = <LocalMessage>[];
    for (final row in rows) {
      messages.add(
        LocalMessage(
          messageId: row['message_id']! as String,
          circleId: row['circle_id']! as String,
          senderUserId: row['sender_user_id']! as int,
          senderDeviceId: row['sender_device_id']! as String,
          direction: LocalMessageDirection.values.byName(
            row['direction']! as String,
          ),
          type: OrbitMessageType.parse(row['type']),
          body: await _decryptLocal(row['encrypted_body']! as String),
          createdAt: DateTime.parse(row['created_at']! as String),
          status: LocalMessageStatus.values.byName(row['status']! as String),
        ),
      );
    }
    return messages;
  }

  @override
  Future<int> readCursor(String circleId, String deviceId) async {
    final db = await _db;
    final rows = await db.query(
      'sync_cursors',
      columns: const <String>['cursor'],
      where: 'circle_id = ? AND device_id = ?',
      whereArgs: <Object?>[circleId, deviceId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return 0;
    }
    return rows.first['cursor']! as int;
  }

  @override
  Future<void> writeCursor(String circleId, String deviceId, int cursor) async {
    final db = await _db;
    await db.insert('sync_cursors', <String, Object?>{
      'circle_id': circleId,
      'device_id': deviceId,
      'cursor': cursor,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> cachePeerIdentity(
    String deviceId,
    DevicePublicIdentity identity,
  ) async {
    final db = await _db;
    final existing = await readPeerIdentity(deviceId);
    if (existing != null &&
        existing.toServerValue() != identity.toServerValue()) {
      throw StateError(
        'A messaging identity key changed unexpectedly for device $deviceId.',
      );
    }
    await db.insert('peer_identities', <String, Object?>{
      'device_id': deviceId,
      'public_identity_key': identity.toServerValue(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  @override
  Future<DevicePublicIdentity?> readPeerIdentity(String deviceId) async {
    final db = await _db;
    final rows = await db.query(
      'peer_identities',
      columns: const <String>['public_identity_key'],
      where: 'device_id = ?',
      whereArgs: <Object?>[deviceId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return DevicePublicIdentity.fromServerValue(
      rows.first['public_identity_key']! as String,
    );
  }

  Future<SecretKey> _key() async {
    final existing = _localKey;
    if (existing != null) {
      return existing;
    }
    final raw = await _secureStorage.read(key: _localKeyName);
    if (raw != null && raw.isNotEmpty) {
      final key = SecretKey(base64Url.decode(raw));
      _localKey = key;
      return key;
    }
    final generated = await _cipher.newSecretKey();
    final bytes = await generated.extractBytes();
    await _secureStorage.write(
      key: _localKeyName,
      value: base64Url.encode(bytes),
    );
    final key = SecretKey(bytes);
    _localKey = key;
    return key;
  }

  Future<String> _encryptLocal(String plaintext) async {
    final box = await _cipher.encrypt(
      utf8.encode(plaintext),
      secretKey: await _key(),
    );
    return jsonEncode(<String, Object>{
      'v': 1,
      'nonce': base64Url.encode(box.nonce),
      'ct': base64Url.encode(box.cipherText),
      'mac': base64Url.encode(box.mac.bytes),
    });
  }

  Future<String> _decryptLocal(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Invalid local encrypted message.');
    }
    final map = decoded.map((key, item) => MapEntry(key.toString(), item));
    if (map['v'] != 1 ||
        map['nonce'] is! String ||
        map['ct'] is! String ||
        map['mac'] is! String) {
      throw const FormatException('Invalid local encrypted message.');
    }
    final clear = await _cipher.decrypt(
      SecretBox(
        base64Url.decode(map['ct']! as String),
        nonce: base64Url.decode(map['nonce']! as String),
        mac: Mac(base64Url.decode(map['mac']! as String)),
      ),
      secretKey: await _key(),
    );
    return utf8.decode(clear);
  }

  @override
  Future<void> close() async {
    final db = _database;
    _database = null;
    if (db != null) {
      await db.close();
    }
  }
}
