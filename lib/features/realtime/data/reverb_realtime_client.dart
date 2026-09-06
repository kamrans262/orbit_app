// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/logging/orbit_logger.dart';
import '../../../core/network/orbit_broadcast_auth_client.dart';
import '../domain/orbit_realtime_event.dart';
import '../domain/realtime_environment.dart';

enum OrbitRealtimeConnectionState {
  disabled,
  disconnected,
  connecting,
  connected,
  reconnecting,
}

class ReverbRealtimeClient {
  ReverbRealtimeClient({
    required RealtimeEnvironment environment,
    required OrbitBroadcastAuthClient authClient,
    required OrbitLogger logger,
  }) : _environment = environment,
       _authClient = authClient,
       _logger = logger;

  final RealtimeEnvironment _environment;
  final OrbitBroadcastAuthClient _authClient;
  final OrbitLogger _logger;

  final StreamController<OrbitRealtimeEvent> _events =
      StreamController<OrbitRealtimeEvent>.broadcast();
  final StreamController<OrbitRealtimeConnectionState> _states =
      StreamController<OrbitRealtimeConnectionState>.broadcast();
  final Set<String> _persistentChannels = <String>{};
  final Set<String> _sosChannels = <String>{};
  final Set<String> _subscribedChannels = <String>{};

  WebSocketChannel? _channel;
  StreamSubscription<Object?>? _socketSubscription;
  Timer? _reconnectTimer;
  String? _socketId;
  bool _running = false;
  int _reconnectAttempt = 0;
  OrbitRealtimeConnectionState _state =
      OrbitRealtimeConnectionState.disconnected;

  Stream<OrbitRealtimeEvent> get events => _events.stream;
  Stream<OrbitRealtimeConnectionState> get states => _states.stream;
  OrbitRealtimeConnectionState get currentState =>
      _environment.isEnabled ? _state : OrbitRealtimeConnectionState.disabled;

  Future<void> start() async {
    _running = true;
    if (!_environment.isEnabled) {
      _setState(OrbitRealtimeConnectionState.disabled);
      return;
    }
    if (_channel != null) {
      return;
    }
    await _connect(reconnecting: false);
  }

  Future<void> stop() async {
    _running = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _socketId = null;
    _subscribedChannels.clear();
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      await channel.sink.close();
    }
    _setState(
      _environment.isEnabled
          ? OrbitRealtimeConnectionState.disconnected
          : OrbitRealtimeConnectionState.disabled,
    );
  }

  Future<void> dispose() async {
    await stop();
    await _events.close();
    await _states.close();
  }

  Future<void> setPersistentChannels(Iterable<String> channelNames) async {
    final next = channelNames.map(_privateChannel).toSet();
    final removed = _persistentChannels.difference(next);
    _persistentChannels
      ..clear()
      ..addAll(next);

    for (final channel in removed) {
      if (!_sosChannels.contains(channel)) {
        await _unsubscribe(channel);
      }
    }
    for (final channel in next) {
      await _subscribe(channel);
    }
  }

  Future<void> watchSos(String sosId) async {
    final channel = _privateChannel('orbit.sos.$sosId');
    _sosChannels.add(channel);
    await _subscribe(channel);
  }

  Future<void> retrySos(String sosId) async {
    final channel = _privateChannel('orbit.sos.$sosId');
    _sosChannels.add(channel);
    _subscribedChannels.remove(channel);
    await _subscribe(channel);
  }

  Future<void> unwatchSos(String sosId) async {
    final channel = _privateChannel('orbit.sos.$sosId');
    _sosChannels.remove(channel);
    if (!_persistentChannels.contains(channel)) {
      await _unsubscribe(channel);
    }
  }

  Future<void> reconnectNow() async {
    if (!_running || !_environment.isEnabled) {
      return;
    }
    _reconnectTimer?.cancel();
    await _closeSocketOnly();
    await _connect(reconnecting: true);
  }

  Future<void> _connect({required bool reconnecting}) async {
    if (!_running || !_environment.isEnabled || _channel != null) {
      return;
    }

    _setState(
      reconnecting
          ? OrbitRealtimeConnectionState.reconnecting
          : OrbitRealtimeConnectionState.connecting,
    );
    try {
      final channel = WebSocketChannel.connect(_environment.socketUri);
      _channel = channel;
      await channel.ready;
      if (!_running || !identical(_channel, channel)) {
        await channel.sink.close();
        return;
      }
      _socketSubscription = channel.stream.listen(
        _handleSocketMessage,
        onError: (Object error, StackTrace stackTrace) {
          _logger.error('Realtime socket error');
          unawaited(_handleDisconnect(channel));
        },
        onDone: () => unawaited(_handleDisconnect(channel)),
        cancelOnError: false,
      );
    } on Object {
      _logger.error('Realtime connection failed');
      await _closeSocketOnly();
      _scheduleReconnect();
    }
  }

  void _handleSocketMessage(Object? raw) {
    if (raw is! String) {
      return;
    }
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return;
    }
    if (decoded is! Map) {
      return;
    }
    final message = decoded.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    final eventName = message['event'];
    if (eventName is! String || eventName.isEmpty) {
      return;
    }

    if (eventName == 'pusher:connection_established') {
      final data = _dataMap(message['data']);
      final socketId = data['socket_id'];
      if (socketId is! String || socketId.isEmpty) {
        return;
      }
      _socketId = socketId;
      _reconnectAttempt = 0;
      _setState(OrbitRealtimeConnectionState.connected);
      unawaited(_subscribeDesiredChannels());
      return;
    }

    if (eventName == 'pusher:ping') {
      _send(<String, Object?>{
        'event': 'pusher:pong',
        'data': <String, Object?>{},
      });
      return;
    }

    if (eventName == 'pusher_internal:subscription_succeeded') {
      final channelName = message['channel'];
      if (channelName is String) {
        _subscribedChannels.add(channelName);
      }
      return;
    }

    if (eventName.startsWith('pusher:') ||
        eventName.startsWith('pusher_internal:')) {
      return;
    }

    final channelName = message['channel'];
    if (channelName is! String || channelName.isEmpty) {
      return;
    }
    _events.add(
      OrbitRealtimeEvent(
        channel: channelName,
        name: eventName,
        data: _dataMap(message['data']),
      ),
    );
  }

  Future<void> _subscribeDesiredChannels() async {
    final desired = <String>{..._persistentChannels, ..._sosChannels};
    for (final channel in desired) {
      await _subscribe(channel);
    }
  }

  Future<void> _subscribe(String channelName) async {
    final socketId = _socketId;
    if (!_running ||
        socketId == null ||
        _channel == null ||
        _subscribedChannels.contains(channelName)) {
      return;
    }
    try {
      final authorization = await _authClient.authorizePrivateChannel(
        socketId: socketId,
        channelName: channelName,
      );
      if (!_running || _socketId != socketId || _channel == null) {
        return;
      }
      _send(<String, Object?>{
        'event': 'pusher:subscribe',
        'data': <String, Object?>{
          'channel': channelName,
          'auth': authorization.auth,
          'channel_data': ?authorization.channelData,
        },
      });
    } on Object {
      // Authorization failure is deliberately non-fatal. This is expected for
      // an SOS channel until the user is the originator or an engaged responder.
      _logger.debug(
        'Realtime private channel authorization declined',
        fields: <String, Object?>{'channel': _safeChannelLabel(channelName)},
      );
    }
  }

  Future<void> _unsubscribe(String channelName) async {
    if (_channel != null && _socketId != null) {
      _send(<String, Object?>{
        'event': 'pusher:unsubscribe',
        'data': <String, Object?>{'channel': channelName},
      });
    }
    _subscribedChannels.remove(channelName);
  }

  void _send(Map<String, Object?> payload) {
    final channel = _channel;
    if (channel == null) {
      return;
    }
    channel.sink.add(jsonEncode(payload));
  }

  Future<void> _handleDisconnect(WebSocketChannel disconnected) async {
    if (!identical(_channel, disconnected)) {
      return;
    }
    await _closeSocketOnly();
    if (_running) {
      _scheduleReconnect();
    }
  }

  Future<void> _closeSocketOnly() async {
    _socketId = null;
    _subscribedChannels.clear();
    final subscription = _socketSubscription;
    _socketSubscription = null;
    await subscription?.cancel();
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      try {
        await channel.sink.close();
      } on Object {
        // Socket is already gone.
      }
    }
  }

  void _scheduleReconnect() {
    if (!_running || !_environment.isEnabled || _reconnectTimer != null) {
      return;
    }
    _setState(OrbitRealtimeConnectionState.reconnecting);
    final seconds = switch (_reconnectAttempt) {
      0 => 1,
      1 => 2,
      2 => 4,
      3 => 8,
      4 => 16,
      _ => 30,
    };
    _reconnectAttempt += 1;
    _reconnectTimer = Timer(Duration(seconds: seconds), () {
      _reconnectTimer = null;
      unawaited(_connect(reconnecting: true));
    });
  }

  Map<String, Object?> _dataMap(Object? raw) {
    Object? value = raw;
    if (value is String) {
      try {
        value = jsonDecode(value);
      } on FormatException {
        return <String, Object?>{};
      }
    }
    if (value is! Map) {
      return <String, Object?>{};
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  String _privateChannel(String value) {
    final normalized = value.startsWith('private-') ? value : 'private-$value';
    if (!RegExp(r'^private-[A-Za-z0-9._-]+$').hasMatch(normalized)) {
      throw ArgumentError.value(
        value,
        'channelName',
        'Invalid realtime channel.',
      );
    }
    return normalized;
  }

  String _safeChannelLabel(String channel) {
    if (channel.startsWith('private-orbit.sos.')) {
      return 'private-orbit.sos.<redacted>';
    }
    if (channel.startsWith('private-devices.')) {
      return 'private-devices.<redacted>';
    }
    return channel;
  }

  void _setState(OrbitRealtimeConnectionState state) {
    if (_state == state) {
      return;
    }
    _state = state;
    _states.add(state);
  }
}
