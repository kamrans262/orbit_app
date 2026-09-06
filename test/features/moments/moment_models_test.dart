import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/features/media/domain/media_models.dart';
import 'package:orbit_app/features/moments/domain/moment_models.dart';

void main() {
  test(
    'parses Laravel Moment presenter contract without plaintext metadata',
    () {
      final moment = OrbitMoment.fromJson(<String, Object?>{
        'id': 'moment-id',
        'circle_id': 'circle-id',
        'author': <String, Object?>{'user_id': 7, 'name': 'Avery'},
        'media': <String, Object?>{
          'asset_id': 'asset-id',
          'kind': 'image',
          'content_type_hint': 'image/jpeg',
          'size_bytes': 1200,
          'sha256_ciphertext': ''.padLeft(64, 'a'),
        },
        'view_count': 3,
        'is_mine': true,
        'expires_at': '2026-09-07T00:00:00Z',
        'created_at': '2026-09-06T00:00:00Z',
      });

      expect(moment.id, 'moment-id');
      expect(moment.media.kind, OrbitMediaKind.image);
      expect(moment.viewCount, 3);
      expect(moment.isMine, isTrue);
    },
  );
}
