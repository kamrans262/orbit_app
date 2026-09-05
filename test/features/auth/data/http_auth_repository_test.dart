import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/core/logging/orbit_logger.dart';
import 'package:orbit_app/core/network/orbit_api_exception.dart';
import 'package:orbit_app/features/auth/data/auth_repository.dart';
import 'package:orbit_app/features/auth/domain/auth_results.dart';

import '../../../support/auth_test_fakes.dart';

void main() {
  late QueueOrbitApiClient api;
  late MemorySessionStore sessionStore;
  late MemoryPendingBootstrapStore pendingStore;
  late HttpAuthRepository repository;

  setUp(() {
    api = QueueOrbitApiClient();
    sessionStore = MemorySessionStore();
    pendingStore = MemoryPendingBootstrapStore();
    repository = HttpAuthRepository(
      apiClient: api,
      sessionStore: sessionStore,
      pendingStore: pendingStore,
      clientDeviceIdStore: const FixedClientDeviceIdStore('client-device-1'),
      deviceMetadataReader: const FixedDeviceMetadataReader(),
      logger: const OrbitLogger(),
    );
  });

  test(
    'OTP verification upgrades into the hardened Identity session',
    () async {
      final now = DateTime.now().toUtc();
      api.postResponses['v1/auth/email-otp/verify'] = <Object>[
        <String, Object?>{
          'user': <String, Object?>{
            'id': 7,
            'name': 'Maya',
            'email': 'maya@example.com',
            'email_verified_at': now.toIso8601String(),
          },
          'access_token': 'bootstrap-access',
          'token_type': 'Bearer',
          'expires_at': now.add(const Duration(days: 30)).toIso8601String(),
        },
      ];
      api.postResponses['v1/devices'] = <Object>[
        <String, Object?>{'id': 'server-device-1'},
      ];
      api.postResponses['v1/identity/sessions'] = <Object>[
        <String, Object?>{
          'token_type': 'Bearer',
          'access_token': 'identity-access',
          'access_expires_at': now
              .add(const Duration(minutes: 15))
              .toIso8601String(),
          'refresh_token': 'identity-refresh',
          'refresh_expires_at': now
              .add(const Duration(days: 60))
              .toIso8601String(),
          'session_id': 'identity-session-1',
        },
      ];
      api.postResponses['v1/auth/logout'] = <Object>[<String, Object?>{}];

      final result = await repository.verifyEmailOtp(
        email: 'maya@example.com',
        otp: '123456',
      );

      expect(result.status, AuthBootstrapStatus.authenticated);
      expect(sessionStore.value?.accessToken, 'identity-access');
      expect(sessionStore.value?.refreshToken, 'identity-refresh');
      expect(sessionStore.value?.deviceId, 'server-device-1');
      expect(pendingStore.value, isNull);
      expect(api.calls.map((call) => call.path).toList(), <String>[
        'v1/auth/email-otp/verify',
        'v1/devices',
        'v1/identity/sessions',
        'v1/auth/logout',
      ]);
    },
  );

  test(
    'second device remains pending until a trusted device approves it',
    () async {
      final now = DateTime.now().toUtc();
      api.postResponses['v1/auth/email-otp/verify'] = <Object>[
        <String, Object?>{
          'user': <String, Object?>{
            'id': 7,
            'name': 'Maya',
            'email': 'maya@example.com',
            'email_verified_at': now.toIso8601String(),
          },
          'access_token': 'bootstrap-access',
          'token_type': 'Bearer',
          'expires_at': now.add(const Duration(days: 30)).toIso8601String(),
        },
      ];
      api.postResponses['v1/devices'] = <Object>[
        <String, Object?>{'id': 'server-device-2'},
      ];
      api.postResponses['v1/identity/sessions'] = <Object>[
        const OrbitApiException(
          code: 'HTTP_409',
          message:
              'Trusted device approval is required before a secure session can be issued.',
          statusCode: 409,
        ),
        <String, Object?>{
          'token_type': 'Bearer',
          'access_token': 'approved-access',
          'access_expires_at': now
              .add(const Duration(minutes: 15))
              .toIso8601String(),
          'refresh_token': 'approved-refresh',
          'refresh_expires_at': now
              .add(const Duration(days: 60))
              .toIso8601String(),
          'session_id': 'identity-session-2',
        },
      ];
      api.postResponses['v1/auth/logout'] = <Object>[<String, Object?>{}];

      final pending = await repository.verifyEmailOtp(
        email: 'maya@example.com',
        otp: '123456',
      );

      expect(pending.status, AuthBootstrapStatus.approvalRequired);
      expect(pendingStore.value?.serverDeviceId, 'server-device-2');
      expect(sessionStore.value, isNull);

      final approved = await repository.retryPendingDeviceApproval();

      expect(approved.status, AuthBootstrapStatus.authenticated);
      expect(sessionStore.value?.accessToken, 'approved-access');
      expect(pendingStore.value, isNull);
    },
  );
}
