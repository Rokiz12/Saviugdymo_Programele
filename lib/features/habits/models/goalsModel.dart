enum GoalPeriod {day, week, month, year}

class Goal {
  final String id;
  final String name;
  final String habbitID;
  final int target;
  final GoalPeriod period;

  const Goal({
    required this.id,
    required this.name,
    required this.habbitID,
    required this.target,
    required this.period,
});


  Map<String, dynamic> toJson() =>{
    'id' : id,
    'name' : name,
    'habbitID' : habbitID,
    'target' : target,
    'period' : period,
  };

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      name: json['name'],
      habbitID: json['habbitID'],
      target: json['target'],
      period: GoalPeriod.values.firstWhere((p) => p.name == json['period'])
    );
  }
}