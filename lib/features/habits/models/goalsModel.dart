enum GoalPeriod {day, week, month, year, custom}

class Goal {
  final String id;
  final String name;
  final String habbitID;
  final int target;
  final GoalPeriod period;
  final int? customDays;
  final bool repeat;

  const Goal({
    required this.id,
    required this.name,
    required this.habbitID,
    required this.target,
    required this.period,
    this.customDays,
    required this.repeat,

  });


  Map<String, dynamic> toJson() =>{
    'id' : id,
    'name' : name,
    'habbitID' : habbitID,
    'target' : target,
    'period' : period.name,
    'customDays': customDays,
    'repeat': repeat,

  };

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      name: json['name'],
      habbitID: json['habbitID'],
      target: json['target'],
      period: GoalPeriod.values.firstWhere((p) => p.name == json['period']),
      customDays: json['customDays'],
      repeat: json['repeat'] ?? false,
    );
  }
}