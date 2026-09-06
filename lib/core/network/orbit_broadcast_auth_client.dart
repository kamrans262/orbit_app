class OrbitBroadcastAuthorization {
  const OrbitBroadcastAuthorization({required this.auth, this.channelData});

  final String auth;
  final String? channelData;
}

abstract interface class OrbitBroadcastAuthClient {
  Future<OrbitBroadcastAuthorization> authorizePrivateChannel({
    required String socketId,
    required String channelName,
  });
}
