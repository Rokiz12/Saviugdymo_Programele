import '../models/models.dart';

/// - Checkbox: true → 1
/// - Number: numeric value
/// - Scale: if changed from default/min → 1
/// - Enum: if changed from default/first option → 1
int goalValueOf(RatingValue? value, Habit habit) {
  if (value == null) return 0;

  switch (habit.kind) {
    case RatingKind.checkbox:
      return value is BoolValue && value.value ? 1 : 0;

    case RatingKind.number:
      return value is NumberValue ? value.value.round() : 0;

    case RatingKind.scale:
      if (value is NumberValue) {
        final min = habit.min ?? 1;
        return value.value != min ? 1 : 0;
      }
      return 0;

    case RatingKind.enumerator:
      if (value is EnumValue) {
        final options = habit.options ?? const [];
        if (options.isEmpty) return 0;

        return value.option != options.first ? 1 : 0;
      }
      return 0;

    case RatingKind.steps:
      return value is NumberValue ? value.value.round() : 0;
  }
}