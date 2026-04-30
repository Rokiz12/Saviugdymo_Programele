import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../features/habits/data/HabitRepository.dart';
import '../features/habits/models/models.dart';
import '../widgets/month_chart_strip.dart';


class StatisticsPage extends StatefulWidget {
  final String userId;

  const StatisticsPage({
    super.key,
    required this.userId,
  });

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {


  DateTime _currentMonth = DateTime.now();


  final FirebaseDayLogRepository _repo = FirebaseDayLogRepository();

  bool _loading = true;
  List<Habit> _habits = [];
  Map<DateTime, DayLog> _logsByDay = {};

  @override
  void initState() {
    super.initState();
    _loadMonth();
  }

  // ---------------------------------------------------------------------------
  // DATA LOADING
  // ---------------------------------------------------------------------------

  Future<void> _loadMonth() async {
    setState(() => _loading = true);

    final habits = await _repo.getHabits(userId: widget.userId);

    final start = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    ).toUtc();

    final end = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).toUtc();

    final logs = await _repo.getLogsForRange(
      userId: widget.userId,
      startInclusive: start,
      endInclusive: end,
    );

    final map = <DateTime, DayLog>{};
    for (final log in logs) {
      final key = DateTime.utc(
        log.dateUtc.year,
        log.dateUtc.month,
        log.dateUtc.day,
      );
      map[key] = log;
    }

    setState(() {
      _habits = habits;
      _logsByDay = map;
      _loading = false;
    });
  }

  void _prevMonth() {
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    _loadMonth();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    _loadMonth();
  }

  // ---------------------------------------------------------------------------
  // HABIT COMPLETION CALCULATION
  // ---------------------------------------------------------------------------



  Map<DateTime, List<double>> _buildMonthChartData() {
    final map = <DateTime, List<double>>{};

    for (int m = 1; m <= 12; m++) {
      final month = DateTime(_currentMonth.year, m);
      final weeks = <double>[];

      for (int w = 0; w < 4; w++) {
        final startDay = w * 7 + 1;
        final values = <double>[];

        for (int d = startDay; d < startDay + 7; d++) {
          final date = DateTime(month.year, month.month, d);
          if (date.month != month.month) continue;
          values.add(_completionRatioForDay(date));
        }

        if (values.isNotEmpty) {
          weeks.add(values.reduce((a, b) => a + b) / values.length);
        }
      }

      map[DateTime(month.year, month.month)] = weeks;
    }

    return map;
  }



  double _completionRatioForDay(DateTime day) {
    if (_habits.isEmpty) return 0;

    final key = DateTime.utc(day.year, day.month, day.day);
    final log = _logsByDay[key];
    if (log == null) return 0;

    int completed = 0;

    for (final h in _habits) {
      final v = log.entries[h.id];
      if (v == null) continue;

      if (v is BoolValue && v.value) completed++;
      if (v is NumberValue && v.value > (h.min ?? 0)) completed++;
      if (v is EnumValue && v.option != '---') completed++;
    }

    return completed / _habits.length;
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final firstDayOfMonth =
    DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth =
    DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);

    final firstWeekday = firstDayOfMonth.weekday; // 1 = Monday
    final totalCells = daysInMonth + (firstWeekday - 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Statistika",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.yellow,
        centerTitle: true,
      ),
      body: Column(
        children: [

          // --------------
          // top months
          // --------------

          MonthChartStrip(
            initialMonth: _currentMonth,
            dataByMonth: _buildMonthChartData(),
            onMonthChanged: (m) {
              setState(() => _currentMonth = m);
              _loadMonth();
            },
          ),

          const SizedBox(height: 8),

          // -----------------------------------------------------------------
          // MONTH SELECTOR
          // -----------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _prevMonth,
                ),
                Text(
                  DateFormat.yMMMM().format(_currentMonth),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          // -----------------------------------------------------------------
          // WEEKDAY HEADERS
          // -----------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: const [
                _Weekday("Pr"),
                _Weekday("An"),
                _Weekday("Tr"),
                _Weekday("Kt"),
                _Weekday("Pn"),
                _Weekday("Št"),
                _Weekday("Sk"),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // -----------------------------------------------------------------
          // CALENDAR GRID
          // -----------------------------------------------------------------
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                itemCount: totalCells,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemBuilder: (context, index) {
                  if (index < firstWeekday - 1) {
                    return const SizedBox.shrink();
                  }

                  final day = index - (firstWeekday - 2);
                  final date = DateTime(
                    _currentMonth.year,
                    _currentMonth.month,
                    day,
                  );

                  final isToday =
                  DateUtils.isSameDay(DateTime.now(), date);

                  final ratio = _completionRatioForDay(date);

                  final bgColor = ratio == 0
                      ? Colors.grey.shade200
                      : Color.lerp(
                    Colors.green.shade100,
                    Colors.green.shade700,
                    ratio.clamp(0, 1),
                  )!;

                  return Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(color: Colors.black, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        "$day",
                        style: TextStyle(
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}



// ---------------------------------------------------------------------------
// WEEKDAY LABEL
// ---------------------------------------------------------------------------


class _Weekday extends StatelessWidget {
  final String label;
  const _Weekday(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}