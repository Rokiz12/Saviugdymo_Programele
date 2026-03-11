import 'ratingValue.dart';

class DayLog {
  final DateTime dateUtc;                 // normalized to UTC midnight
  final Map<String, RatingValue> entries; // habitId -> value

  const DayLog({
    required this.dateUtc,
    required this.entries,
  });

  String get yyyymmdd =>
      "${dateUtc.year.toString().padLeft(4,'0')}-"
          "${dateUtc.month.toString().padLeft(2,'0')}-"
          "${dateUtc.day.toString().padLeft(2,'0')}";

  DayLog copyWith({
    DateTime? dateUtc,
    Map<String, RatingValue>? entries,
  }) => DayLog(
    dateUtc: dateUtc ?? this.dateUtc,
    entries: entries ?? this.entries,
  );

  RatingValue? getValue(String habitId) => entries[habitId];

  DayLog setValue(String habitId, RatingValue value) {
    final next = Map<String, RatingValue>.from(entries)..[habitId] = value;
    return copyWith(entries: next);
  }

  DayLog removeValue(String habitId) {
    final next = Map<String, RatingValue>.from(entries)..remove(habitId);
    return copyWith(entries: next);
  }

  Map<String, dynamic> toJson() => {
    'date': yyyymmdd,
    'entries': entries.map((k, v) => MapEntry(k, v.toJson())),
  };

  factory DayLog.fromJson(Map<String, dynamic> json) {
    final parts = (json['date'] as String).split('-').map(int.parse).toList();
    final d = DateTime.utc(parts[0], parts[1], parts[2]);
    final raw = (json['entries'] as Map<String, dynamic>? ?? {});
    final map = <String, RatingValue>{};
    for (final e in raw.entries) {
      map[e.key] = RatingValue.fromJson((e.value as Map).cast<String, dynamic>());
    }
    return DayLog(dateUtc: d, entries: map);
  }
}