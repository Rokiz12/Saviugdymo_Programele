import 'package:flutter/material.dart';
import 'package:pvp/features/habits/data/HabitRepository.dart';
import 'package:pvp/features/habits/data/foreground_time_tracker.dart';
import 'package:pvp/features/habits/models/models.dart';
import 'package:pvp/features/habits/utils/goalProgress.dart';
import 'package:pvp/features/habits/dialogs/habitEditorDialog.dart';
import 'package:pvp/features/habits/dialogs/goalEditDialog.dart';
import '../widgets/custom_app_bar.dart';

class HabitsPage extends StatefulWidget {
  final String userId;
  const HabitsPage({super.key, required this.userId});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  final _repo = FirebaseDayLogRepository();

  List<Habit> _habits = [];
  List<Goal> _goals = [];
  List<DayLog> _monthLogs = [];
  DayLog? _today;

  ForegroundTimeTracker? _tracker;

  // INIT

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadInitial();
    await _ensureAutoHabitExists();
    _startTracker();
  }

  // DATA LOAD

  Future<void> _loadInitial() async {
    final habits = await _repo.getHabits(userId: widget.userId);
    final goals = await _repo.getGoals(userId: widget.userId);

    final now = DateTime.now().toUtc();
    final start = DateTime.utc(now.year, now.month, 1);
    final end = DateTime.utc(now.year, now.month + 1, 0);

    final monthLogs = await _repo.getLogsForRange(
      userId: widget.userId,
      startInclusive: start,
      endInclusive: end,
    );

    DayLog today = monthLogs.firstWhere(
          (log) =>
      log.dateUtc.year == now.year &&
          log.dateUtc.month == now.month &&
          log.dateUtc.day == now.day,
      orElse: () =>
          DayLog(dateUtc: DateTime.utc(now.year, now.month, now.day), entries: {}),
    );

    setState(() {
      _habits = habits;
      _goals = goals;
      _today = today;
      _monthLogs = monthLogs;
    });
  }

  // GOAL PROGRESS CALCULATION

  int _calculateGoalProgress(Goal g) {
    final habitId = g.habbitID;
    final habit = _habits.firstWhere(
          (h) => h.id == habitId,
      orElse: () => Habit(id: "missing", name: "Missing", kind: RatingKind.checkbox),
    );

    switch (g.period) {
      case GoalPeriod.day:
        return goalValueOf(_today?.entries[habitId], habit);

      case GoalPeriod.week:
        return _monthLogs
            .where((log) => _isInCurrentWeek(log.dateUtc))
            .map((log) => goalValueOf(log.entries[habitId], habit))
            .fold(0, (a, b) => a + b);

      case GoalPeriod.month:
        return _monthLogs
            .map((log) => goalValueOf(log.entries[habitId], habit))
            .fold(0, (a, b) => a + b);

      case GoalPeriod.year:
        return _monthLogs
            .map((log) => goalValueOf(log.entries[habitId], habit))
            .fold(0, (a, b) => a + b);

      case GoalPeriod.custom:
        final days = g.customDays ?? 1;
        final now = DateTime.now().toUtc();
        final start = now.subtract(Duration(days: days));

        return _monthLogs
            .where((log) => log.dateUtc.isAfter(start))
            .map((log) => goalValueOf(log.entries[habitId], habit))
            .fold(0, (a, b) => a + b);
    }
  }

  bool _isInCurrentWeek(DateTime d) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    return d.isAfter(monday.subtract(const Duration(days: 1))) &&
        d.isBefore(sunday.add(const Duration(days: 1)));
  }

  // HABITS CRUD

  Future<void> _addHabit() async {
    final habit = await showDialog<Habit>(
      context: context,
      builder: (_) => HabitEditorDialog(),
    );
    if (habit == null) return;

    await _repo.addHabit(userId: widget.userId, habit: habit);

    setState(() => _habits.add(habit));

    final initVal = _initialValueFor(habit);
    if (initVal != null) _setValue(habit, initVal);
  }

  Future<void> _editHabit(Habit h) async {
    final updated = await showDialog<Habit>(
      context: context,
      builder: (_) => HabitEditorDialog(initial: h),
    );
    if (updated == null) return;

    await _repo.updateHabit(userId: widget.userId, habit: updated);

    setState(() {
      final i = _habits.indexWhere((x) => x.id == updated.id);
      if (i >= 0) _habits[i] = updated;
    });

    if (_today?.entries[updated.id] case final v?) {
      final coerced = _coerceValueIfNeeded(updated, v);
      if (coerced != v) _setValue(updated, coerced ?? v);
    }
  }

  Future<void> _deleteHabit(Habit h) async {
    if (h.systemOnly) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ištrinti įprotį?"),
        content: Text("Ar tikrai norite ištrinti '${h.name}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Ne")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Taip")),
        ],
      ),
    );

    if (confirm != true) return;

    await _repo.deleteHabit(userId: widget.userId, habitId: h.id);

    setState(() {
      _habits.removeWhere((x) => x.id == h.id);
      _today = _today?.removeValue(h.id);
    });
  }

  // GOALS CRUD

  Future<void> _addGoal() async {
    final goal = await showDialog<Goal>(
      context: context,
      builder: (_) => GoalEditorDialog(
        habits: _habits,
      ),
    );

    if (goal == null) return;

    await _repo.addGoal(userId: widget.userId, goal: goal);

    setState(() => _goals.add(goal));
  }

  Future<void> _editGoal(Goal g) async {
    final updated = await showDialog<Goal>(
      context: context,
      builder: (_) => GoalEditorDialog(
        habits: _habits,
        initial: g,
      ),
    );

    if (updated == null) return;

    await _repo.updateGoal(userId: widget.userId, goal: updated);

    setState(() {
      final i = _goals.indexWhere((x) => x.id == updated.id);
      if (i >= 0) _goals[i] = updated;
    });
  }

  Future<void> _deleteGoal(Goal g) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ištrinti tikslą?"),
        content: Text("Ar tikrai norite ištrinti '${g.name}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Ne")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Taip")),
        ],
      ),
    );

    if (confirm != true) return;

    await _repo.deleteGoal(userId: widget.userId, goalId: g.id);

    setState(() => _goals.removeWhere((x) => x.id == g.id));
  }

  // HABIT VALUE HANDLING

  RatingValue? _initialValueFor(Habit h) {
    switch (h.kind) {
      case RatingKind.checkbox:
        return const BoolValue(false);
      case RatingKind.number:
        return NumberValue(h.min ?? 0);
      case RatingKind.scale:
        return NumberValue(h.min ?? 1);
      case RatingKind.enumerator:
        return h.options != null && h.options!.isNotEmpty
            ? EnumValue(h.options!.first)
            : null;
    }
  }

  RatingValue? _coerceValueIfNeeded(Habit h, RatingValue v) {
    switch (h.kind) {
      case RatingKind.checkbox:
        return v is BoolValue ? v : const BoolValue(false);

      case RatingKind.number:
        if (v is NumberValue) {
          final min = h.min ?? -999999;
          final max = h.max ?? 999999;
          return NumberValue(v.value.clamp(min, max));
        }
        return NumberValue(h.min ?? 0);

      case RatingKind.scale:
        final min = h.min ?? 1;
        final max = h.max ?? 5;
        if (v is NumberValue) {
          return NumberValue(v.value.clamp(min, max));
        }
        return NumberValue(min);

      case RatingKind.enumerator:
        final opts = h.options ?? const [];
        if (v is EnumValue && opts.contains(v.option)) return v;
        return opts.isNotEmpty ? EnumValue(opts.first) : null;
    }
  }

  void _setValue(Habit h, RatingValue v) {
    final newLog = (_today ??
        DayLog(
          dateUtc: DateTime.now().toUtc(),
          entries: {},
        ))
        .setValue(h.id, v);

    setState(() => _today = newLog);

    _repo.upsertDayLog(userId: widget.userId, log: newLog);
  }

  // AUTO HABIT TRACKER

  Future<void> _ensureAutoHabitExists() async {
    const auto = Habit(
      id: 'app2min',
      name: '2minutes',
      kind: RatingKind.checkbox,
      systemOnly: true,
    );

    if (!_habits.any((h) => h.id == auto.id)) {
      await _repo.addHabit(userId: widget.userId, habit: auto);
      setState(() => _habits.add(auto));
    }
  }

  void _startTracker() {
    _tracker = ForegroundTimeTracker(
      threshold: const Duration(minutes: 2),
      onReached: (day) async {
        DayLog log = _today ??
            DayLog(dateUtc: day, entries: {});

        if (log.dateUtc.year != day.year ||
            log.dateUtc.month != day.month ||
            log.dateUtc.day != day.day) {
          log = DayLog(dateUtc: day, entries: {});
        }

        log = log.setValue('app2min', const BoolValue(true));

        await _repo.upsertDayLog(userId: widget.userId, log: log);

        final now = DateTime.now().toUtc();
        if (day.year == now.year && day.month == now.month && day.day == now.day) {
          setState(() => _today = log);
        }
      },
    )..start();
  }

  @override
  void dispose() {
    _tracker?.stop();
    super.dispose();
  }

  // UI

  @override
  Widget build(BuildContext context) {
    if (_today == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(

      appBar: const CustomAppBar(title: "Įpročiai"),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // HABITS TABLE
            _buildHabitsSection(),

            const SizedBox(height: 30),

            const SizedBox(height: 30),

            // GOALS TABLE
            _buildGoalsSection(),
          ],
        ),
      ),
    );
  }

  // UI SUBWIDGETS

  Widget _buildHabitsSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          ListView.separated(
            separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Colors.black12),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _habits.length,
            itemBuilder: (context, index) {
              final h = _habits[index];
              final v = _today!.entries[h.id];


              return SizedBox(
                height: 44,
                child: Row(
                  children: [
                    // LEFT: habit name
                    Expanded(
                      child: GestureDetector(
                        onTap: h.systemOnly ? null : () => _editHabit(h),
                        onLongPress: h.systemOnly ? null : () => _deleteHabit(h),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              h.name,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // RIGHT: indicator / controls
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildTrailingFor(h, v),
                    ),
                  ],
                ),
              );

            },
          ),

          const Divider(height: 1, color: Colors.black),

          TextButton.icon(
            onPressed: _addHabit,
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text("Pridėti įprotį", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }


  Widget _buildGoalsSection() {
    return Container(
      width: 450,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _goals.length,
            itemBuilder: (context, index) {
              final g = _goals[index];
              final progress = _calculateGoalProgress(g);
              double percent = (progress / g.target).clamp(0, 1.0);

              return ListTile(
                title: Text(g.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("$progress / ${g.target}"),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: percent,
                      backgroundColor: Colors.grey[300],
                      color: percent >= 1 ? Colors.green : Colors.blue,
                    ),
                  ],
                ),
                trailing: Text("${(percent * 100).round()}%"),
                onTap: () => _editGoal(g),
                onLongPress: () => _deleteGoal(g),
              );
            },
          ),

          const Divider(height: 1),

          TextButton.icon(
            onPressed: _addGoal,
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text("Pridėti Tikslą", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HABIT TRAILING WIDGET
  // ---------------------------------------------------------------------------

  Widget _buildTrailingFor(Habit h, RatingValue? v) {
    switch (h.kind) {
      case RatingKind.checkbox:
        final checked = (v is BoolValue) ? v.value : false;

        if (h.systemOnly) {
          return IgnorePointer(
            child: Checkbox(
              value: checked,
              onChanged: null,
            ),
          );
        }

        return Checkbox(
          value: checked,
          onChanged: (val) => _setValue(h, BoolValue(val ?? false)),
        );


      case RatingKind.number:
        final numVal = (v is NumberValue) ? v.value : (h.min ?? 0);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              iconSize: 18,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(),
              onPressed: () => _setValue(
                h,
                NumberValue((numVal - 5).clamp(
                  h.min ?? -999999,
                  h.max ?? 999999,
                )),
              ),
            ),
            SizedBox(
              width: 24,
              child: Center(
                child: Text(
                  "$numVal",
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              iconSize: 18,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(),
              onPressed: () => _setValue(
                h,
                NumberValue((numVal + 5).clamp(
                  h.min ?? -999999,
                  h.max ?? 999999,
                )),
              ),
            ),
          ],
        );


      case RatingKind.scale:
        final min = h.min ?? 1;
        final max = h.max ?? 5;
        final current = (v is NumberValue) ? v.value.toDouble() : min.toDouble();

        return SizedBox(
          width: 160,
          child: Row(
            children: [
              Text("$min"),
              Expanded(
                child: Slider(
                  min: min.toDouble(),
                  max: max.toDouble(),
                  divisions: max - min,
                  value: current.clamp(min.toDouble(), max.toDouble()),
                  onChanged: (val) => _setValue(h, NumberValue(val.round())),
                ),
              ),
              Text("$max"),
            ],
          ),
        );

      case RatingKind.enumerator:
        final options = h.options ?? const ["A", "B", "C"];
        final selected = (v is EnumValue) ? v.option : null;

        return DropdownButton<String>(
          value: options.contains(selected) ? selected : null,
          hint: const Text("Pasirinkti"),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: (val) {
            if (val != null) _setValue(h, EnumValue(val));
          },
        );
    }
  }
}