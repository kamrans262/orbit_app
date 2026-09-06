import 'package:flutter_riverpod/flutter_riverpod.dart';

final circleChangeRevisionProvider =
    NotifierProvider<CircleChangeRevisionNotifier, int>(
      CircleChangeRevisionNotifier.new,
    );

class CircleChangeRevisionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void markChanged() => state += 1;
}
