class OrbitSubscription {
  const OrbitSubscription({
    required this.id,
    required this.userId,
    required this.status,
    required this.plan,
    this.billingInterval,
    required this.priceAmountMinor,
    required this.priceCurrency,
    required this.complimentary,
    this.startedAt,
    this.currentPeriodEnd,
    this.cancelAt,
    this.endsAt,
    required this.entitlements,
  });

  factory OrbitSubscription.fromJson(Map<String, Object?> json) {
    final planMap = _mapValue(json['plan']);
    final priceMap = _mapValue(json['price']);
    final entitlementsMap =
        _mapValue(json['entitlements']) ?? const <String, Object?>{};
    if (planMap == null || priceMap == null) {
      throw const FormatException('Invalid subscription response.');
    }

    return OrbitSubscription(
      id: _requiredString(json, 'id'),
      userId: _requiredInt(json, 'user_id'),
      status: _requiredString(json, 'status'),
      plan: OrbitPlanSummary.fromJson(planMap),
      billingInterval: _nullableString(json['billing_interval']),
      priceAmountMinor: _requiredInt(priceMap, 'amount_minor'),
      priceCurrency: _requiredString(priceMap, 'currency').toUpperCase(),
      complimentary: json['complimentary'] == true,
      startedAt: _dateValue(json['started_at']),
      currentPeriodEnd: _dateValue(json['current_period_end']),
      cancelAt: _dateValue(json['cancel_at']),
      endsAt: _dateValue(json['ends_at']),
      entitlements: Map<String, Object?>.unmodifiable(entitlementsMap),
    );
  }

  final String id;
  final int userId;
  final String status;
  final OrbitPlanSummary plan;
  final String? billingInterval;
  final int priceAmountMinor;
  final String priceCurrency;
  final bool complimentary;
  final DateTime? startedAt;
  final DateTime? currentPeriodEnd;
  final DateTime? cancelAt;
  final DateTime? endsAt;
  final Map<String, Object?> entitlements;

  bool get isFree => priceAmountMinor == 0;
}

class OrbitPlanSummary {
  const OrbitPlanSummary({
    required this.id,
    required this.slug,
    required this.name,
  });

  factory OrbitPlanSummary.fromJson(Map<String, Object?> json) {
    return OrbitPlanSummary(
      id: _requiredString(json, 'id'),
      slug: _requiredString(json, 'slug'),
      name: _requiredString(json, 'name'),
    );
  }

  final String id;
  final String slug;
  final String name;
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

int _requiredInt(Map<String, Object?> json, String key) {
  final value = json[key];
  return switch (value) {
    int number => number,
    num number => number.toInt(),
    String text when int.tryParse(text) != null => int.parse(text),
    _ => throw FormatException('Missing or invalid $key.'),
  };
}

String? _nullableString(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

DateTime? _dateValue(Object? value) {
  return value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;
}

Map<String, Object?>? _mapValue(Object? value) {
  if (value is! Map) {
    return null;
  }
  return value.map((key, item) => MapEntry(key.toString(), item));
}
