/// Formats a raw integer count into a compact display string.
/// 284 -> '284', 12800 -> '12.8K', 1540000 -> '1.5M'
///
/// NOTE: if other features need this too, move it to `core/utils/formatters.dart`
/// rather than duplicating — keeping it here for now to stay scoped to profile.
String formatCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toString();
}
