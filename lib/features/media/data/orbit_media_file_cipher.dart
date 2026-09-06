import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';

import '../domain/media_models.dart';

class OrbitMediaCipherException implements Exception {
  const OrbitMediaCipherException(this.message);

  final String message;

  @override
  String toString() => 'OrbitMediaCipherException($message)';
}

class OrbitMediaFileCipher {
  OrbitMediaFileCipher({AesGcm? cipher})
    : _cipher = cipher ?? AesGcm.with256bits();

  static final List<int> _header = utf8.encode('ORBITMEDIA1');
  static const int _plainChunkSize = 1024 * 1024;
  static const int _nonceBytes = 12;
  static const int _macBytes = 16;

  final AesGcm _cipher;

  Future<EncryptedMediaFile> encryptFile({
    required String sourcePath,
    required String destinationPath,
    void Function(double progress)? onProgress,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const OrbitMediaCipherException(
        'Captured media is no longer available.',
      );
    }
    final total = await source.length();
    if (total <= 0) {
      throw const OrbitMediaCipherException('Captured media is empty.');
    }

    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
    var keyHandedOff = false;
    try {
      final key = SecretKeyData(keyBytes);
      final input = await source.open();
      final outputFile = File(destinationPath);
      await outputFile.parent.create(recursive: true);
      final output = await outputFile.open(mode: FileMode.write);
      var processed = 0;
      var completed = false;

      try {
        await output.writeFrom(_header);
        while (true) {
          final chunk = await input.read(_plainChunkSize);
          if (chunk.isEmpty) {
            break;
          }
          final box = await _cipher.encrypt(chunk, secretKey: key);
          if (box.nonce.length != _nonceBytes ||
              box.mac.bytes.length != _macBytes) {
            throw const OrbitMediaCipherException(
              'The media cipher returned an unsupported record format.',
            );
          }
          final length = ByteData(4)
            ..setUint32(0, box.cipherText.length, Endian.big);
          await output.writeFrom(length.buffer.asUint8List());
          await output.writeFrom(box.nonce);
          await output.writeFrom(box.mac.bytes);
          await output.writeFrom(box.cipherText);
          processed += chunk.length;
          onProgress?.call((processed / total).clamp(0.0, 1.0).toDouble());
        }
        completed = true;
      } finally {
        await input.close();
        await output.close();
        if (!completed && await outputFile.exists()) {
          await outputFile.delete();
        }
      }

      final digest = await sha256.bind(outputFile.openRead()).first;
      final result = EncryptedMediaFile(
        path: outputFile.path,
        sizeBytes: await outputFile.length(),
        sha256Ciphertext: digest.toString(),
        mediaKeyBytes: keyBytes,
      );
      keyHandedOff = true;
      return result;
    } finally {
      if (!keyHandedOff) {
        keyBytes.fillRange(0, keyBytes.length, 0);
      }
    }
  }

  Future<void> decryptFile({
    required String encryptedPath,
    required String destinationPath,
    required List<int> mediaKeyBytes,
  }) async {
    if (mediaKeyBytes.length != 32) {
      throw const OrbitMediaCipherException('The media key is invalid.');
    }
    final input = await File(encryptedPath).open();
    final destination = File(destinationPath);
    await destination.parent.create(recursive: true);
    final output = await destination.open(mode: FileMode.write);
    var completed = false;

    try {
      final header = await input.read(_header.length);
      if (!_sameBytes(header, _header)) {
        throw const OrbitMediaCipherException(
          'Unsupported encrypted media format.',
        );
      }
      final key = SecretKeyData(mediaKeyBytes);
      while (true) {
        final lengthBytes = await input.read(4);
        if (lengthBytes.isEmpty) {
          break;
        }
        if (lengthBytes.length != 4) {
          throw const OrbitMediaCipherException(
            'Encrypted media is truncated.',
          );
        }
        final length = ByteData.sublistView(
          lengthBytes,
        ).getUint32(0, Endian.big);
        if (length <= 0 || length > _plainChunkSize) {
          throw const OrbitMediaCipherException(
            'Encrypted media record is invalid.',
          );
        }
        final nonce = await _readExact(input, _nonceBytes);
        final mac = await _readExact(input, _macBytes);
        final ciphertext = await _readExact(input, length);
        try {
          final clear = await _cipher.decrypt(
            SecretBox(ciphertext, nonce: nonce, mac: Mac(mac)),
            secretKey: key,
          );
          await output.writeFrom(clear);
        } on SecretBoxAuthenticationError {
          throw const OrbitMediaCipherException(
            'Encrypted media integrity check failed.',
          );
        }
      }
      completed = true;
    } finally {
      await input.close();
      await output.close();
      if (!completed && await destination.exists()) {
        await destination.delete();
      }
    }
  }

  Future<List<int>> _readExact(RandomAccessFile input, int count) async {
    final bytes = await input.read(count);
    if (bytes.length != count) {
      throw const OrbitMediaCipherException('Encrypted media is truncated.');
    }
    return bytes;
  }

  bool _sameBytes(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }
}
