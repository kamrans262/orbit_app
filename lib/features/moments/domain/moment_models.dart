import '../../media/domain/media_models.dart';

class OrbitMomentAuthor {
  const OrbitMomentAuthor({required this.userId, required this.name});

  factory OrbitMomentAuthor.fromJson(Map<String, Object?> json) {
    return OrbitMomentAuthor(
      userId: _requiredInt(json, 'user_id'),
      name: _requiredString(json, 'name'),
    );
  }

  final int userId;
  final String name;
}

class OrbitMoment {
  const OrbitMoment({
    required this.id,
    required this.circleId,
    required this.author,
    required this.media,
    required this.viewCount,
    required this.isMine,
    required this.expiresAt,
    required this.createdAt,
  });

  factory OrbitMoment.fromJson(Map<String, Object?> json) {
    final author = _requiredMap(json, 'author');
    final media = _requiredMap(json, 'media');
    return OrbitMoment(
      id: _requiredString(json, 'id'),
      circleId: _requiredString(json, 'circle_id'),
      author: OrbitMomentAuthor.fromJson(author),
      media: OrbitMediaAsset.fromJson(<String, Object?>{
        ...media,
        'circle_id': _requiredString(json, 'circle_id'),
      }),
      viewCount: _requiredInt(json, 'view_count'),
      isMine: json['is_mine'] == true,
      expiresAt: DateTime.parse(_requiredString(json, 'expires_at')),
      createdAt: DateTime.parse(_requiredString(json, 'created_at')),
    );
  }

  final String id;
  final String circleId;
  final OrbitMomentAuthor author;
  final OrbitMediaAsset media;
  final int viewCount;
  final bool isMine;
  final DateTime expiresAt;
  final DateTime createdAt;
}

class MomentViewResult {
  const MomentViewResult({required this.recorded, required this.anonymous});

  factory MomentViewResult.fromJson(Map<String, Object?> json) {
    return MomentViewResult(
      recorded: json['recorded'] == true,
      anonymous: json['anonymous'] == true,
    );
  }

  final bool recorded;
  final bool anonymous;
}

class MomentViewer {
  const MomentViewer({
    required this.userId,
    required this.name,
    required this.viewedAt,
  });

  factory MomentViewer.fromJson(Map<String, Object?> json) {
    return MomentViewer(
      userId: _requiredInt(json, 'user_id'),
      name: _requiredString(json, 'name'),
      viewedAt: DateTime.parse(_requiredString(json, 'viewed_at')),
    );
  }

  final int userId;
  final String name;
  final DateTime viewedAt;
}

class MomentViewers {
  const MomentViewers({
    required this.momentId,
    required this.totalViews,
    required this.anonymousViews,
    required this.viewers,
  });

  factory MomentViewers.fromJson(Map<String, Object?> json) {
    final rawViewers = json['viewers'];
    if (rawViewers is! List) {
      throw const FormatException('Invalid Moment viewers response.');
    }
    return MomentViewers(
      momentId: _requiredString(json, 'moment_id'),
      totalViews: _requiredInt(json, 'total_views'),
      anonymousViews: _requiredInt(json, 'anonymous_views'),
      viewers: rawViewers
          .map((item) => MomentViewer.fromJson(_stringMap(item)))
          .toList(growable: false),
    );
  }

  final String momentId;
  final int totalViews;
  final int anonymousViews;
  final List<MomentViewer> viewers;
}

class MomentCaptureDraft {
  const MomentCaptureDraft({
    required this.circleId,
    required this.circleName,
    required this.sourcePath,
    required this.kind,
    required this.contentTypeHint,
  });

  final String circleId;
  final String circleName;
  final String sourcePath;
  final OrbitMediaKind kind;
  final String contentTypeHint;
}

class RecentMomentItem {
  const RecentMomentItem({required this.moment, required this.circleName});

  final OrbitMoment moment;
  final String circleName;
}

Map<String, Object?> _requiredMap(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! Map) {
    throw FormatException('Invalid $key in Moment response.');
  }
  return value.map((key, item) => MapEntry(key.toString(), item));
}

Map<String, Object?> _stringMap(Object? value) {
  if (value is! Map) {
    throw const FormatException('Invalid Moment response.');
  }
  return value.map((key, item) => MapEntry(key.toString(), item));
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Invalid $key in Moment response.');
  }
  return value;
}

int _requiredInt(Map<String, Object?> json, String key) {
  final value = json[key];
  return switch (value) {
    int item => item,
    num item => item.toInt(),
    String item =>
      int.tryParse(item) ??
          (throw FormatException('Invalid $key in Moment response.')),
    _ => throw FormatException('Invalid $key in Moment response.'),
  };
}
