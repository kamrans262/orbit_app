import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/features/identity/data/identity_repository.dart';

import '../../support/m9_test_api_client.dart';

void main() {
  test('uses the canonical device and session endpoints', () async {
    final api = M9TestApiClient();
    api.getListResponses['v1/me/devices'] = <Object>[
      <dynamic>[
        <String, Object?>{
          'id': 'device-1',
          'client_device_id': 'client-1',
          'device_name': 'Pixel',
          'platform': 'android',
          'last_seen_at': '2026-09-06T12:00:00Z',
          'trust_status': 'approved',
        },
      ],
    ];
    api.getListResponses['v1/identity/sessions'] = <Object>[
      <dynamic>[
        <String, Object?>{
          'id': 'session-1',
          'device_id': 'device-1',
          'device_name': 'Pixel',
          'platform': 'android',
          'status': 'active',
          'last_seen_at': '2026-09-06T12:00:00Z',
          'access_expires_at': '2026-09-06T12:15:00Z',
          'refresh_expires_at': '2026-11-05T12:00:00Z',
          'revoked_at': null,
          'created_at': '2026-09-01T12:00:00Z',
        },
      ],
    ];
    api.putResponses['v1/me/devices/device-1/name'] = <Object>[
      <String, dynamic>{'id': 'device-1', 'device_name': 'Travel Pixel'},
    ];
    api.postResponses['v1/identity/sessions/revoke-others'] = <Object>[
      <String, dynamic>{'revoked': 2},
    ];
    final repository = HttpIdentityRepository(apiClient: api);

    final devices = await repository.listDevices();
    final sessions = await repository.listSessions();
    await repository.renameDevice('device-1', ' Travel Pixel ');
    final revoked = await repository.revokeOtherSessions();
    await repository.revokeSession('session-1');

    expect(devices.single.displayName, 'Pixel');
    expect(sessions.single.isActive, isTrue);
    expect(revoked, 2);
    expect(
      api.calls
          .where((call) => call.path == 'v1/me/devices/device-1/name')
          .single
          .allowAuthRetry,
      isTrue,
    );
    expect(
      api.calls
          .where((call) => call.path == 'v1/identity/sessions/session-1')
          .single
          .method,
      'DELETE',
    );
  });

  test(
    'keeps export and deletion actions on identity consumer routes',
    () async {
      final api = M9TestApiClient();
      api.postResponses['v1/identity/data-exports'] = <Object>[
        <String, dynamic>{
          'id': 'export-1',
          'status': 'ready',
          'requested_at': '2026-09-06T12:00:00Z',
          'expires_at': '2026-09-13T12:00:00Z',
        },
      ];
      api.getMapResponses['v1/identity/account-deletion'] = <Object>[
        <String, dynamic>{},
      ];
      api.postResponses['v1/identity/account-deletion'] = <Object>[
        <String, dynamic>{
          'id': 'delete-1',
          'status': 'pending',
          'requested_at': '2026-09-06T12:00:00Z',
          'scheduled_for': '2026-10-06T12:00:00Z',
        },
      ];
      final repository = HttpIdentityRepository(apiClient: api);

      final export = await repository.requestDataExport();
      final beforeDeletion = await repository.getAccountDeletion();
      final deletion = await repository.requestAccountDeletion(
        reason: 'Leaving',
      );
      final cancelled = await repository.cancelAccountDeletion();

      expect(export.status, 'ready');
      expect(beforeDeletion, isNull);
      expect(deletion.status, 'pending');
      expect(cancelled, isTrue);
      expect(
        api.calls
            .where((call) => call.path == 'v1/identity/data-exports')
            .single
            .allowAuthRetry,
        isTrue,
      );
      expect(
        api.calls
            .where(
              (call) =>
                  call.path == 'v1/identity/account-deletion' &&
                  call.method == 'POST',
            )
            .single
            .data,
        containsPair('reason', 'Leaving'),
      );
    },
  );

  test('requests safe audit summaries with a bounded limit', () async {
    final api = M9TestApiClient();
    api.getListResponses['v1/identity/audit-logs'] = <Object>[
      <dynamic>[
        <String, Object?>{
          'id': 'audit-1',
          'action': 'identity.device.renamed',
          'target_type': 'device',
          'target_id': 'device-1',
          'metadata': <String, Object?>{'request_id': 'private'},
          'occurred_at': '2026-09-06T12:00:00Z',
        },
      ],
    ];
    final repository = HttpIdentityRepository(apiClient: api);

    final activity = await repository.listAuditLogs(limit: 500);

    expect(activity.single.action, 'identity.device.renamed');
    expect(api.calls.single.queryParameters, containsPair('limit', 100));
  });
}
