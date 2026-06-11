import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../features/habits/data/HabitRepository.dart';
import '../features/habits/models/models.dart';
import '../widgets/month_chart_strip.dart';
import '../data/repositories/diary_repository.dart';
import '../data/models/diary_entry_model.dart';
import '../widgets/best_month_card.dart';
import '../theme/app_theme.dart';
import '../services/language_notifier.dart';
import 'package:provider/provider.dart';


class _MonthStats {
  final DateTime month;
  final double completionRate;
  final int completedDays;
  final int totalDays;
  final int longestStreak;
  final int habitsLogged;

  const _MonthStats({
    required this.month,
    required this.completionRate,
    required this.completedDays,
    required this.totalDays,
    required this.longestStreak,
    required this.habitsLogged,
  });
}

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

  _MonthStats? _computeBestMonth() {
    if (_habits.isEmpty) return null;

    final now = DateTime.now();
    final allMonths = List.generate(12, (i) {
      return DateTime(now.year, now.month - (11 - i), 1);
    });

    _MonthStats? best;

    for (final month in allMonths) {
      if (month.year == now.year && month.month == now.month) continue;

      final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
      int completedDays = 0;
      int habitsLogged = 0;
      int currentStreak = 0;
      int longestStreak = 0;
      double rateSum = 0;

      for (int d = 1; d <= daysInMonth; d++) {
        final date = DateTime(month.year, month.month, d);
        
        // Skip future days
        if (date.isAfter(now)) break;

        final ratio = _completionRatioForDay(date);
        rateSum += ratio;

        final key = DateTime.utc(date.year, date.month, date.day);
        final log = _logsByDay[key];
        if (log != null) {
          habitsLogged += log.entries.length;
        }

        if (ratio > 0) {
          completedDays++;
          currentStreak++;
          if (currentStreak > longestStreak) longestStreak = currentStreak;
        } else {
          currentStreak = 0;
        }
      }

      final rate = daysInMonth > 0 ? rateSum / daysInMonth : 0.0;

      if (rate == 0 && habitsLogged == 0) continue;

      final stats = _MonthStats(
        month: month,
        completionRate: rate,
        completedDays: completedDays,
        totalDays: daysInMonth,
        longestStreak: longestStreak,
        habitsLogged: habitsLogged,
      );



      if (best == null || stats.completionRate > best.completionRate) {
        best = stats;
      }
    }

    return best;
  }


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
      final now = DateTime.now();

      // IMPORTANT: Fetch logs for the last 12 months to support the trend line and comparisons
      final start = DateTime.utc(now.year, now.month - 11, 1);
      final end = DateTime.utc(now.year, now.month + 1, 0, 23, 59, 59);

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

      // Load diary entries for the current view month
      final viewStart = DateTime.utc(_currentMonth.year, _currentMonth.month, 1);
      final viewEnd = DateTime.utc(_currentMonth.year, _currentMonth.month + 1, 0, 23, 59, 59);
      
      final allDiaryEntries = await _diaryRepo.getEntriesForDateRange(
        widget.userId,
        viewStart,
        viewEnd,
      );

      setState(() {
        _habits = habits;
        _logsByDay = map;
        _diaryEntries = allDiaryEntries;
        _loading = false;
      });
    } catch (e) {
      print('Error loading: $e');
      setState(() => _loading = false);
    }
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    _loadMonth();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    _loadMonth();
  }

  // ---------------------------------------------------------------------------
  // MOOD CONVERSION
  // ---------------------------------------------------------------------------

  int _moodToValue(String mood) {
    if (mood.contains('Puikiai')) return 5;
    if (mood.contains('Gerai')) return 4;
    if (mood.contains('Normaliai')) return 3;
    if (mood.contains('Prastai')) return 2;
    if (mood.contains('Blogai')) return 1;
    return 0;
  }

  double _getAverageMoodForDay(DateTime day) {
    final dayEntries = _diaryEntries.where((e) {
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
    final now = DateTime.now();

    // Sliding 12-month window to match MonthChartStrip
    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - (11 - i), 1);
      final weeks = <double>[];

      for (int w = 0; w < 4; w++) {
        final startDay = w * 7 + 1;
        final values = <double>[];

        for (int d = startDay; d < startDay + 7; d++) {
          final date = DateTime(month.year, month.month, d);
          if (date.month != month.month) continue;
          values.add(_completionRatioForDay(date));
        }

        weeks.add(values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length);
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
    final lang = context.watch<LanguageNotifier>();
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstWeekday = firstDayOfMonth.weekday; // 1 = Monday
    final totalCells = daysInMonth + (firstWeekday - 1);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            lang.t('statistics'),
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          backgroundColor: Colors.yellow,
          centerTitle: true,
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.check_circle), text: lang.t('habits')),
              Tab(icon: Icon(Icons.mood), text: lang.t('mood')),
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

  Widget _buildHabitsTab(DateTime firstDayOfMonth, int daysInMonth,
      int firstWeekday, int totalCells) {
    final colors = context.colors;
    final lang = context.watch<LanguageNotifier>();
    final locale = lang.language == AppLanguage.lt ? 'lt' : 'en';
    final best = _computeBestMonth();

    // Stats across the historical window (excluding current month)
    final now = DateTime.now();
    final allMonths = List.generate(12, (i) {
      return DateTime(now.year, now.month - (11 - i), 1);
    });

    double historicalTotalRate = 0;
    int monthsWithData = 0;
    List<double> historicalRates = [];

    for (final m in allMonths) {
      // EXCLUDE CURRENT MONTH from the baseline and comparison chip
      if (m.year == now.year && m.month == now.month) continue;

      final monthDays = DateUtils.getDaysInMonth(m.year, m.month);
      double monthRateSum = 0;
      bool hasAnyData = false;
      for (int d = 1; d <= monthDays; d++) {
        final ratio = _completionRatioForDay(DateTime(m.year, m.month, d));
        monthRateSum += ratio;
        if (ratio > 0) hasAnyData = true;
      }
      
      final rate = monthDays > 0 ? monthRateSum / monthDays : 0.0;
      // We only count months that have some recorded activity in the average
      if (hasAnyData || rate > 0) {
        historicalTotalRate += rate;
        monthsWithData++;
        historicalRates.add(rate);
      }
    }
    
    final avgRate = monthsWithData > 0 ? historicalTotalRate / monthsWithData : 0.0;

    int betterThanCount = 0;
    if (best != null) {
      for (final r in historicalRates) {
        if (best.completionRate > r) betterThanCount++;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        children: [
          MonthChartStrip(
            initialMonth: _currentMonth,
            dataByMonth: _buildMonthChartData(),
            showPills: false,
            onMonthChanged: (m) {
              setState(() => _currentMonth = m);
              _loadMonth();
            },
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: _prevMonth),
                Text(DateFormat.yMMMM(locale).format(_currentMonth),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextMonth),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children:  [
                _Weekday(lang.t('mon_short')),
                _Weekday(lang.t('tue_short')),
                _Weekday(lang.t('wed_short')),
                _Weekday(lang.t('thu_short')),
                _Weekday(lang.t('fri_short')),
                _Weekday(lang.t('sat_short')),
                _Weekday(lang.t('sun_short')),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCells,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemBuilder: (context, index) {
                if (index < firstWeekday - 1) return const SizedBox.shrink();
                final day = index - (firstWeekday - 2);
                final date = DateTime(_currentMonth.year, _currentMonth.month, day);
                final isToday = DateUtils.isSameDay(DateTime.now(), date);
                final ratio = _completionRatioForDay(date);
                final bgColor = ratio == 0 ? colors.background2
                    : Color.lerp(colors.background2, colors.intenseColor, ratio.clamp(0, 1))!;

                return Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday ? Border.all(color: colors.intenseColor, width: 2) : null,
                  ),
                  child: Center(
                    child: Text("$day", style: TextStyle(fontWeight: isToday ? FontWeight.bold : FontWeight.normal))),
                );
              },
            ),
          ),

          const SizedBox(height: 32),

          _PremiumBanner(),
          const SizedBox(height: 24),

          if (best != null)
            BestMonthCard(
              monthName: DateFormat.yMMMM(locale).format(best.month),
              completionRate: best.completionRate,
              completedDays: best.completedDays,
              totalDays: best.totalDays,
              longestStreak: best.longestStreak,
              habitsLogged: best.habitsLogged,
              avgRate: avgRate,
              betterThanMonths: betterThanCount,
              totalMonths: monthsWithData,
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMoodTab() {
    final lang = context.watch<LanguageNotifier>();
    final locale = lang.language == AppLanguage.lt ? 'lt' : 'en';
    final spots = _buildMoodChartData();
    if (spots.isEmpty || spots.every((spot) => spot.y == 0)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mood_bad, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              lang.t('no_mood_data'),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
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
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: _prevMonth),
                Text(DateFormat.yMMMM(locale).format(_currentMonth),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextMonth),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1)),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30,
                      getTitlesWidget: (value, meta) => value.toInt() % 5 == 0 ? Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)) : const SizedBox.shrink())),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 80,
                      getTitlesWidget: (value, meta) {
                        final moods = [
                          lang.t('mood_bad'),
                          lang.t('mood_poor'),
                          lang.t('mood_normal'),
                          lang.t('mood_good'),
                          lang.t('mood_great'),
                        ];
                        final index = value.toInt() - 1;
                        return (index >= 0 && index < moods.length) ? Text(moods[index], style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis) : const SizedBox.shrink();
                      })),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withOpacity(0.3))),
                minY: 0, maxY: 5,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots, isCurved: true, color: Colors.yellow[700], barWidth: 3,
                    dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: Colors.yellow[700]!, strokeWidth: 2, strokeColor: Colors.white)),
                    belowBarData: BarAreaData(show: true, color: Colors.yellow.withOpacity(0.2)),
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

class _Weekday extends StatelessWidget {

  final String label;
  const _Weekday(this.label);
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(child: Center(child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: colors.textColor))));
  }
}
class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageNotifier>();
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colors.background2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.intenseColor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
            child: const Text('⭐', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '66 days premium',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 3),
                Text(
                  lang.t('premium_desc'),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              // TODO: navigate to paywall
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colors.intenseColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                lang.t('get'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}