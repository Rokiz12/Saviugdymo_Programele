import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../features/habits/data/HabitRepository.dart';
import '../features/habits/models/models.dart';
import '../widgets/month_chart_strip.dart';
import '../data/repositories/diary_repository.dart';
import '../data/models/diary_entry_model.dart';


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
  final DiaryRepository _diaryRepo = DiaryRepository();

  bool _loading = true;
  List<Habit> _habits = [];
  Map<DateTime, DayLog> _logsByDay = {};
  List<DiaryEntryModel> _diaryEntries = [];

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

    try {
      final habits = await _repo.getHabits(userId: widget.userId);

      // Calculate the first day of current month (local time)
      final startOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);

      // Calculate the first day of next month (local time)
      final endOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

      // Convert to UTC for Firebase queries
      final start = DateTime.utc(
        startOfMonth.year,
        startOfMonth.month,
        startOfMonth.day,
      );

      final end = DateTime.utc(
        endOfMonth.year,
        endOfMonth.month,
        endOfMonth.day,
        23,
        59,
        59,
      );

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

      // Load diary entries with proper date range
      final allDiaryEntries = await _diaryRepo.getEntriesForDateRange(
        widget.userId,
        start,
        end,
      );

      setState(() {
        _habits = habits;
        _logsByDay = map;
        _diaryEntries = allDiaryEntries;
        _loading = false;
      });
    } catch (e) {
      print('Error loading month: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  void _prevMonth() {
    setState(() {
      if (_currentMonth.month == 1) {
        _currentMonth = DateTime(_currentMonth.year - 1, 12);
      } else {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      }
    });
    _loadMonth();
  }

  void _nextMonth() {
    setState(() {
      if (_currentMonth.month == 12) {
        _currentMonth = DateTime(_currentMonth.year + 1, 1);
      } else {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      }
    });
    _loadMonth();
  }

  // ---------------------------------------------------------------------------
  // MOOD CONVERSION
  // ---------------------------------------------------------------------------

  /// Convert mood text to numeric value (1-5)
  int _moodToValue(String mood) {
    if (mood.contains('Puikiai')) return 5;
    if (mood.contains('Gerai')) return 4;
    if (mood.contains('Normaliai')) return 3;
    if (mood.contains('Prastai')) return 2;
    if (mood.contains('Blogai')) return 1;
    return 0;
  }

  /// Get average mood for a specific day
  double _getAverageMoodForDay(DateTime day) {
    final dayEntries = _diaryEntries.where((e) {
      // Normalize both dates to compare only year/month/day
      final entryDay = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
      final targetDay = DateTime(day.year, day.month, day.day);
      return entryDay.year == targetDay.year &&
             entryDay.month == targetDay.month &&
             entryDay.day == targetDay.day;
    }).toList();

    if (dayEntries.isEmpty) return 0;

    final sum = dayEntries.fold<int>(
      0,
      (prev, entry) => prev + _moodToValue(entry.mood),
    );
    return sum / dayEntries.length;
  }

  /// Build mood chart data for the month
  List<FlSpot> _buildMoodChartData() {
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final spots = <FlSpot>[];

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final mood = _getAverageMoodForDay(date);
      spots.add(FlSpot(day.toDouble(), mood));
    }

    return spots;
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Statistika",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          backgroundColor: Colors.yellow,
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.check_circle), text: "Įpročiai"),
              Tab(icon: Icon(Icons.mood), text: "Nuotaika"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildHabitsTab(firstDayOfMonth, daysInMonth, firstWeekday, totalCells),
            _buildMoodTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitsTab(DateTime firstDayOfMonth, int daysInMonth, int firstWeekday, int totalCells) {
    return Column(
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
      );
  }

  Widget _buildMoodTab() {
    final spots = _buildMoodChartData();

    if (spots.isEmpty || spots.every((spot) => spot.y == 0)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mood_bad, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "Nėra nuotaikos duomenų",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadMonth,
              icon: const Icon(Icons.refresh),
              label: const Text("Atnaujinti"),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
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
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 5 == 0) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const moods = ['😭 Blogai', '😢 Prastai', '😐 Normaliai', '🙂 Gerai', '😀 Puikiai'];
                        final index = value.toInt() - 1;
                        if (index >= 0 && index < moods.length) {
                          return Text(
                            moods[index],
                            style: const TextStyle(fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 80,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                minY: 0,
                maxY: 5,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.yellow[700],
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.yellow[700]!,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.yellow.withValues(alpha: 0.2),
                    ),
                  ),
                ],
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