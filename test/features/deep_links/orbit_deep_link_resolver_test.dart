import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/features/deep_links/domain/orbit_deep_link_resolver.dart';

void main() {
  const resolver = OrbitDeepLinkResolver();

  const circleId = '11111111-1111-4111-8111-111111111111';
  const momentId = '22222222-2222-4222-8222-222222222222';
  const pingId = '33333333-3333-4333-8333-333333333333';
  const sosId = '44444444-4444-4444-8444-444444444444';

  test('allowlists backend-defined Orbit destinations with UUID ids', () {
    expect(
      resolver.resolve(Uri.parse('orbit://circles/$circleId/chat')),
      '/circles/$circleId/messages',
    );
    expect(
      resolver.resolve(Uri.parse('orbit://moments/$momentId')),
      '/moments/$momentId',
    );
    expect(resolver.resolve(Uri.parse('orbit://pings/$pingId')), '/pings');
    expect(resolver.resolve(Uri.parse('orbit://sos/$sosId')), '/sos/$sosId');
  });

  test('rejects arbitrary and ambiguous deep links', () {
    expect(resolver.resolve(Uri.parse('https://evil.example/sos/1')), isNull);
    expect(resolver.resolve(Uri.parse('orbit://admin/users')), isNull);
    expect(resolver.resolve(Uri.parse('orbit://sos/../secret')), isNull);
    expect(resolver.resolve(Uri.parse('orbit://sos/secret')), isNull);
    expect(resolver.resolve(Uri.parse('orbit://moments/moment-1')), isNull);
    expect(resolver.resolve(Uri.parse('orbit://pings/ping_1')), isNull);
    expect(
      resolver.resolve(Uri.parse('orbit://circles/circle_1/chat')),
      isNull,
    );
    expect(
      resolver.resolve(Uri.parse('orbit://sos/$sosId?next=/admin')),
      isNull,
    );
    expect(resolver.resolve(Uri.parse('orbit://sos/$sosId#fragment')), isNull);
    expect(resolver.resolve(Uri.parse('orbit://sos/$sosId/')), isNull);
  });
}
