import 'ratingKind.dart';

class Habit {
  final String id;
  final String name;
  final RatingKind kind;
  final int? min;
  final int? max;
  final List<String>? options;
  final bool archived;
  final bool systemOnly;
  final String? icon;
  final int? stepGoal;

  const Habit({
    required this.id,
    required this.name,
    required this.kind,
    this.min,
    this.max,
    this.options,
    this.archived = false,
    this.systemOnly = false,
    this.icon,
    this.stepGoal,
});

  Habit copyWith({
    String? id,
    String? name,
    RatingKind? kind,
    int? min,
    int? max,
    List<String>? options,
    bool? archived,
    bool? systemOnly,
    String? icon,
    int? stepGoal,
}) {
    return Habit(
      id: id?? this.id,
      name: name?? this.name,
      kind: kind?? this.kind,
      min: min?? this.min,
      max: max?? this.max,
      options: options?? this.options,
      archived: archived?? this.archived,
      systemOnly: systemOnly?? this.systemOnly,
      icon: icon?? this.icon,
      stepGoal: stepGoal ?? this.stepGoal,
    );
  }

  Map<String, dynamic> toJson() => {
    'id' : id,
    'name': name,
    'kind': kind.name,
    'min': min,
    'max': max,
    'options': options,
    'archived': archived,
    'systemOnly': systemOnly,
    'icon': icon,
    'stepGoal': stepGoal,
  };


  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'] as String,
    name: json['name'] as String,
    kind: RatingKind.values.firstWhere((k) => k.name == json['kind']),
    min: json['min'] as int?,
    max: json['max'] as int?,
    options: (json['options'] as List?)?.cast<String>(),
    archived: (json['archived'] as bool?) ?? false,
    systemOnly: (json['systemOnly'] as bool?) ?? false,
    icon: json['icon'] as String?,
    stepGoal: json['stepGoal'] as int?,
  );
}