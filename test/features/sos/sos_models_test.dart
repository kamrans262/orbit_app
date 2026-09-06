import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/features/sos/domain/sos_models.dart';

void main() {
  test('parses privacy-shaped SOS incident payloads', () {
    final incident = SosIncident.fromJson(<String, Object?>{
      'id': 'sos-1',
      'circle_id': 'circle-1',
      'originator_user_id': 7,
      'status': 'active',
      'escalation_stage': 1,
      'activated_at': '2026-09-06T12:00:00Z',
      'resolved_at': null,
      'resolution_reason': null,
      'recording_ref': null,
      'recording_expires_at': null,
      'originator_location': <String, Object?>{
        'latitude': 31.5204,
        'longitude': 74.3587,
        'accuracy_m': 8.5,
        'recorded_at': '2026-09-06T12:00:01Z',
      },
      'responders': <Object?>[
        <String, Object?>{
          'user_id': 8,
          'status': 'engaged',
          'engaged_at': '2026-09-06T12:00:05Z',
          'responded_at': '2026-09-06T12:00:05Z',
          'location': null,
        },
      ],
    });

    expect(incident.isActive, isTrue);
    expect(incident.escalationStage, 1);
    expect(incident.originatorLocation?.accuracyMeters, 8.5);
    expect(incident.responderFor(8)?.status, SosResponderStatus.engaged);
    expect(incident.responderFor(999), isNull);
  });

  test(
    'activation payload only includes optional emergency fields when present',
    () {
      const input = SosActivationInput(
        id: 'sos-1',
        circleId: 'circle-1',
        latitude: 31.5,
        longitude: 74.3,
        locationAccuracyMeters: 5,
      );

      expect(input.toApiPayload(), <String, Object?>{
        'id': 'sos-1',
        'circle_id': 'circle-1',
        'latitude': 31.5,
        'longitude': 74.3,
        'location_accuracy_m': 5.0,
      });
    },
  );
}
