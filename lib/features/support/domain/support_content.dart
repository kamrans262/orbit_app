class SupportContent {
  const SupportContent({
    required this.id,
    required this.slug,
    required this.title,
    required this.body,
  });

  factory SupportContent.fromJson(Map<String, Object?> json) {
    return SupportContent(
      id: _requiredString(json, 'id'),
      slug: _requiredString(json, 'slug'),
      title: _requiredString(json, 'title'),
      body: _requiredString(json, 'body'),
    );
  }

  final String id;
  final String slug;
  final String title;
  final String body;
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  if (value is num) {
    return value.toString();
  }
  throw FormatException('Missing or invalid $key.');
}
