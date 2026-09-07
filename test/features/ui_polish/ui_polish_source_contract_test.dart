import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _source(String path) => File(path).readAsStringSync();

void main() {
  test(
    'profile detail and notification preference routes own Material scaffolds',
    () {
      final profile = _source(
        'lib/features/profile/presentation/pages/edit_profile_page.dart',
      );
      final notifications = _source(
        'lib/features/notifications/presentation/pages/notification_preferences_page.dart',
      );

      expect(profile, contains('return Scaffold('));
      expect(notifications, contains('return Scaffold('));
    },
  );

  test('home header removes the mission tagline and heart decoration', () {
    final source = _source(
      'lib/features/home/presentation/widgets/home_header.dart',
    );

    expect(source, isNot(contains('Safer people')));
    expect(source, isNot(contains('brighter tomorrows')));
    expect(source, isNot(contains('favorite_border_rounded')));
  });

  test(
    'quick actions keep three full cards visible and scroll horizontally',
    () {
      final source = _source(
        'lib/features/home/presentation/widgets/quick_actions.dart',
      );

      expect(source, contains('scrollDirection: Axis.horizontal'));
      expect(source, contains('const visibleCardCount = 3;'));
      expect(source, contains("title: 'Ping'"));
      expect(source, contains("title: 'SOS'"));
      expect(source, contains("title: 'Circle'"));
      expect(source, contains("title: 'Location'"));
    },
  );

  test(
    'floating SOS has one visible SOS label rather than an SOS glyph plus label',
    () {
      final source = _source(
        'lib/features/home/presentation/widgets/sos_floating_action.dart',
      );

      expect(source, contains('Icons.emergency_rounded'));
      expect(source, isNot(contains('Icons.sos_rounded')));
      expect(source, contains("'SOS'"));
    },
  );

  test('camera preview fills without changing the camera aspect ratio', () {
    final source = _source('lib/features/camera/presentation/camera_page.dart');

    expect(source, contains('class _CameraPreviewSurface'));
    expect(source, contains('previewSize'));
    expect(source, contains('fit: BoxFit.cover'));
    expect(source, contains('controller.buildPreview()'));
    expect(source, contains('final OrbitCircle activeCircle = circle;'));
    expect(source, contains('await _finishVideo(activeCircle);'));
    expect(
      source,
      contains('Future<void> _finishVideo(OrbitCircle circle) async'),
    );

    final finishVideoStart = source.indexOf(
      'Future<void> _finishVideo(OrbitCircle circle) async',
    );
    final deleteCaptureStart = source.indexOf(
      'Future<void> _deleteCapture(String path) async',
    );
    expect(finishVideoStart, greaterThanOrEqualTo(0));
    expect(deleteCaptureStart, greaterThan(finishVideoStart));
    final finishVideoSource = source.substring(
      finishVideoStart,
      deleteCaptureStart,
    );
    expect(finishVideoSource, isNot(contains('activeCircle')));
    expect(finishVideoSource, contains('circleId: circle.id'));
    expect(finishVideoSource, contains('circleName: circle.name'));
  });
}
