class OrbitRealtimeEvent {
  const OrbitRealtimeEvent({
    required this.channel,
    required this.name,
    required this.data,
  });

  final String channel;
  final String name;
  final Map<String, Object?> data;

  String? stringValue(String key) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (value is num) {
      return value.toString();
    }
    return null;
  }

  int? intValue(String key) {
    final value = data[key];
    return switch (value) {
      int item => item,
      num item => item.toInt(),
      String item => int.tryParse(item),
      _ => null,
    };
  }
}
