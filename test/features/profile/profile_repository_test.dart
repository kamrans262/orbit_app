import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/features/profile/data/profile_repository.dart';

import '../../support/m9_test_api_client.dart';

void main() {
  test('loads and updates the consumer profile contract', () async {
    final api = M9TestApiClient();
    api.getMapResponses['v1/profile'] = <Object>[_profileJson(name: 'Kamran')];
    api.patchResponses['v1/profile'] = <Object>[_profileJson(name: 'Kamran S')];
    final repository = HttpProfileRepository(apiClient: api);

    final profile = await repository.loadProfile();
    final updated = await repository.updateProfile(
      name: '  Kamran S  ',
      timezone: ' Asia/Karachi ',
      locale: ' en-PK ',
    );

    expect(profile.displayName, 'Kamran');
    expect(updated.name, 'Kamran S');
    final patch = api.calls.last;
    expect(patch.method, 'PATCH');
    expect(patch.path, 'v1/profile');
    expect(patch.allowAuthRetry, isTrue);
    expect(patch.data, <String, Object?>{
      'name': 'Kamran S',
      'timezone': 'Asia/Karachi',
      'locale': 'en-PK',
    });
  });

  test('sends a null name when display name is cleared', () async {
    final api = M9TestApiClient();
    api.patchResponses['v1/profile'] = <Object>[_profileJson(name: null)];
    final repository = HttpProfileRepository(apiClient: api);

    await repository.updateProfile(name: '   ', timezone: 'UTC', locale: 'en');

    expect(api.calls.single.data, containsPair('name', null));
  });
}

Map<String, dynamic> _profileJson({required String? name}) {
  return <String, dynamic>{
    'id': 1,
    'name': name,
    'email': 'kamran@example.test',
    'email_verified_at': '2026-09-01T12:00:00Z',
    'timezone': 'Asia/Karachi',
    'locale': 'en-PK',
    'created_at': '2026-08-01T12:00:00Z',
    'updated_at': '2026-09-06T12:00:00Z',
  };
}
