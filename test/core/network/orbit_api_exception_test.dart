import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/core/network/orbit_api_exception.dart';

void main() {
  test('parses the Laravel validation error contract', () {
    final error = OrbitApiException.fromPayload(
      statusCode: 422,
      payload: <String, Object?>{
        'success': false,
        'message': 'The submitted data is invalid.',
        'code': 'VALIDATION_ERROR',
        'errors': <String, Object?>{
          'email': <String>['The email field is required.'],
        },
      },
    );

    expect(error.code, 'VALIDATION_ERROR');
    expect(error.statusCode, 422);
    expect(error.validationErrors, contains('email'));
  });

  test('maps a transport failure without exposing technical details', () {
    final error = OrbitApiException.fromPayload(
      statusCode: null,
      payload: null,
    );

    expect(error.code, 'NETWORK_ERROR');
    expect(error.message, contains('Unable to reach Orbit'));
  });
}
