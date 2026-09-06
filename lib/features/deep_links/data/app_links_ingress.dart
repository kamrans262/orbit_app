// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:app_links/app_links.dart';

abstract interface class DeepLinkIngress {
  Future<Uri?> getInitialUri();
  Stream<Uri> get uriStream;
}

class AppLinksDeepLinkIngress implements DeepLinkIngress {
  AppLinksDeepLinkIngress({AppLinks? appLinks})
    : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  @override
  Future<Uri?> getInitialUri() => _appLinks.getInitialLink();

  @override
  Stream<Uri> get uriStream => _appLinks.uriLinkStream;
}

class CompositeDeepLinkIngress implements DeepLinkIngress {
  CompositeDeepLinkIngress({
    required DeepLinkIngress appLinks,
    required Stream<Uri> pushOpenedUris,
  }) : _appLinks = appLinks,
       _pushOpenedUris = pushOpenedUris;

  final DeepLinkIngress _appLinks;
  final Stream<Uri> _pushOpenedUris;

  @override
  Future<Uri?> getInitialUri() => _appLinks.getInitialUri();

  @override
  Stream<Uri> get uriStream async* {
    final controller = StreamController<Uri>();
    final subscriptions = <StreamSubscription<Uri>>[];
    subscriptions.add(_appLinks.uriStream.listen(controller.add));
    subscriptions.add(_pushOpenedUris.listen(controller.add));
    try {
      yield* controller.stream;
    } finally {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      await controller.close();
    }
  }
}
