/// Coercion helpers shared by every model's `fromJson`.
///
/// The FastAPI backend is stricter and looser than the mock layer in two ways
/// that would otherwise crash a cast:
///
///  * Pydantic serialises `Decimal` as a **JSON string** (`"139900.00"`), not a
///    number, so `as num` throws on prices, costs, and incentive totals.
///  * Plenty of columns are nullable server-side (`variant`, `service_type`,
///    `dealer_id`, ...) while the Dart models declare them non-null because the
///    screens only ever display them.
///
/// Keeping the coercion here means one place to look when the API shape and the
/// model shape disagree.
library;

/// Parses a number that may arrive as `num`, or as a `String` (Pydantic
/// `Decimal`). Returns [fallback] for null/unparseable input.
double asDouble(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

/// Nullable variant of [asDouble] — distinguishes "absent" from "zero", which
/// matters for costs and optional readings.
double? asDoubleOrNull(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int asInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? asDouble(value).toInt();
  return fallback;
}

int? asIntOrNull(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Non-null string with a default, for columns the API may leave null.
String asString(Object? value, {String fallback = ''}) {
  if (value is String) return value;
  if (value == null) return fallback;
  return value.toString();
}

DateTime? asDateOrNull(Object? value) {
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

/// For non-null `DateTime` fields; falls back to [fallback] (default: now) so a
/// missing timestamp renders instead of throwing.
DateTime asDate(Object? value, {DateTime? fallback}) {
  return asDateOrNull(value) ?? fallback ?? DateTime.now();
}

/// Formats a `DateTime` as `YYYY-MM-DD` for the API's date-only fields, which
/// reject a full ISO timestamp.
String dateOnly(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

Map<String, dynamic> asMap(Object? value) {
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}

/// `List<Map>` payloads, tolerating null and non-map entries.
List<Map<String, dynamic>> asMapList(Object? value) {
  if (value is List) {
    return value.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }
  return const [];
}
