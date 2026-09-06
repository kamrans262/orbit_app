import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/features/identity/domain/identity_models.dart';

void main() {
  test('privacy summary accepts compact deletion and export summaries', () {
    final summary = PrivacySummary.fromJson(<String, Object?>{
      'global_ghost_mode': true,
      'read_receipts_enabled': false,
      'notification_preferences': <String, Object?>{
        'push_enabled': true,
        'in_app_enabled': true,
        'quiet_hours_enabled': false,
      },
      'circles': <Object?>[
        <String, Object?>{'circle_id': 'circle-1'},
      ],
      'account_deletion': <String, Object?>{
        'status': 'blocked',
        'scheduled_for': '2026-10-06T12:00:00Z',
        'blocking_reason': 'Transfer Circle ownership first.',
      },
      'data_export': <String, Object?>{
        'id': 'export-1',
        'status': 'ready',
        'expires_at': '2026-09-13T12:00:00Z',
      },
    });

    expect(summary.globalGhostMode, isTrue);
    expect(summary.readReceiptsEnabled, isFalse);
    expect(summary.circleCount, 1);
    expect(summary.accountDeletion?.id, isNull);
    expect(summary.accountDeletion?.status, 'blocked');
    expect(summary.dataExport?.id, 'export-1');
  });

  test('audit model intentionally does not expose metadata', () {
    final entry = SecurityAuditEntry.fromJson(<String, Object?>{
      'id': 'audit-1',
      'action': 'identity.session.revoked',
      'target_type': 'identity_session',
      'target_id': 'session-1',
      'metadata': <String, Object?>{'private': 'must-not-render'},
      'occurred_at': '2026-09-06T12:00:00Z',
    });

    expect(entry.action, 'identity.session.revoked');
    expect(entry.targetId, 'session-1');
  });
}
