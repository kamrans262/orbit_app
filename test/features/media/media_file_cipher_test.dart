import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/features/media/data/orbit_media_file_cipher.dart';

void main() {
  test(
    'encrypted media file round-trips without storing plaintext ciphertext',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'orbit-media-test-',
      );
      addTearDown(() => directory.delete(recursive: true));

      final sourceBytes = List<int>.generate(
        1024 * 1024 + 37,
        (index) => (index * 31 + 7) & 0xff,
      );
      final source = File('${directory.path}/source.bin');
      final encrypted = '${directory.path}/encrypted.orbitcipher';
      final clear = '${directory.path}/clear.bin';
      await source.writeAsBytes(sourceBytes, flush: true);

      final cipher = OrbitMediaFileCipher();
      final result = await cipher.encryptFile(
        sourcePath: source.path,
        destinationPath: encrypted,
      );

      expect(result.mediaKeyBytes, hasLength(32));
      expect(result.sha256Ciphertext, hasLength(64));
      expect(await File(encrypted).readAsBytes(), isNot(sourceBytes));

      await cipher.decryptFile(
        encryptedPath: encrypted,
        destinationPath: clear,
        mediaKeyBytes: result.mediaKeyBytes,
      );

      expect(await File(clear).readAsBytes(), sourceBytes);
    },
  );

  test(
    'tampered ciphertext fails closed and removes partial plaintext',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'orbit-media-tamper-',
      );
      addTearDown(() => directory.delete(recursive: true));

      final source = File('${directory.path}/source.bin');
      final encrypted = File('${directory.path}/encrypted.orbitcipher');
      final clear = File('${directory.path}/clear.bin');
      await source.writeAsBytes(
        List<int>.generate(4096, (index) => index & 0xff),
        flush: true,
      );

      final cipher = OrbitMediaFileCipher();
      final result = await cipher.encryptFile(
        sourcePath: source.path,
        destinationPath: encrypted.path,
      );
      final bytes = await encrypted.readAsBytes();
      bytes[bytes.length - 1] ^= 0xff;
      await encrypted.writeAsBytes(bytes, flush: true);

      await expectLater(
        cipher.decryptFile(
          encryptedPath: encrypted.path,
          destinationPath: clear.path,
          mediaKeyBytes: result.mediaKeyBytes,
        ),
        throwsA(isA<OrbitMediaCipherException>()),
      );
      expect(await clear.exists(), isFalse);
    },
  );
}
