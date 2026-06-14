import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pvp/features/habits/data/HabitRepository.dart';
import 'package:pvp/features/habits/data/foreground_time_tracker.dart';
import 'package:pvp/features/habits/models/models.dart';
import 'package:pvp/features/habits/utils/goalProgress.dart';
import 'package:pvp/features/habits/dialogs/habitEditorDialog.dart';
import 'package:pvp/features/habits/dialogs/goalEditDialog.dart';
import 'package:pvp/services/step_service.dart';
import '../services/sound_service.dart';
import '../features/habits/utils/habitIcons.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/reusables.dart';
import '../theme/app_theme.dart';
import '../services/language_notifier.dart';

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

  int _todaySteps = 0;
  ForegroundTimeTracker? _tracker;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadInitial();
    await _ensureAutoHabitExists();
    await _syncStepHabits();
  }

  Future<void> _loadInitial() async {
    final habits = await _repo.getHabits(userId: widget.userId);
    final goals  = await _repo.getGoals(userId: widget.userId);

    final now   = DateTime.now().toUtc();
    final start = DateTime.utc(now.year, now.month, 1);
    final end   = DateTime.utc(now.year, now.month + 1, 0);

    final monthLogs = await _repo.getLogsForRange(
      userId: widget.userId,
      startInclusive: start,
      endInclusive: end,
    );

    DayLog today = monthLogs.firstWhere(
          (log) =>
      log.dateUtc.year  == now.year &&
          log.dateUtc.month == now.month &&
          log.dateUtc.day   == now.day,
      orElse: () =>
          DayLog(dateUtc: DateTime.utc(now.year, now.month, now.day), entries: {}),
    );

    setState(() {
      _habits    = habits;
      _goals     = goals;
      _today     = today;
      _monthLogs = monthLogs;
    });
  }

  Future<void> _syncStepHabits() async {
    final stepHabits = _habits.where((h) => h.kind == RatingKind.steps).toList();
    if (stepHabits.isEmpty) return;

    final steps = await StepService.getTodaySteps();
    if (steps == null) return;
    if (!mounted) return;



    // Keep for live display in the row
    if (mounted) setState(() => _todaySteps = steps);

    // Save step count and mark complete when goal is reached
    for (final h in stepHabits) {
      final goal   = h.stepGoal ?? 0;
      final isDone = steps >= goal && goal > 0;

      // Always write the step count so the progress bar stays current
      _saveStepValue(h, steps, markDone: isDone);
    }
  }

  /// Persists the step count into the DayLog and optionally marks it done.
  void _saveStepValue(Habit h, int steps, {required bool markDone}) {
    if (!mounted) return;          // 👈 add this


    final now    = DateTime.now().toUtc();
    final logDay = DateTime.utc(now.year, now.month, now.day);

    DayLog log = _today ?? DayLog(dateUtc: logDay, entries: {});
    log = log.setValue(h.id, NumberValue(steps));

    // ── keep _monthLogs in sync so goal progress reads the same value ──
    final idx = _monthLogs.indexWhere(
          (l) =>
      l.dateUtc.year  == logDay.year &&
          l.dateUtc.month == logDay.month &&
          l.dateUtc.day   == logDay.day,
    );
    if (idx >= 0) {
      _monthLogs[idx] = log;
    } else {
      _monthLogs.add(log);
    }

    setState(() {
      _today     = log;
      _monthLogs = List.from(_monthLogs);
    });

    _repo.upsertDayLog(userId: widget.userId, log: log);

    if (markDone) SoundService.playMarkHabit();
  }

  // ─── GOAL PROGRESS ──────────────────────────────────────────────────────────

  int _calculateGoalProgress(Goal g) {
    final habitId = g.habbitID;
    final habit   = _habits.firstWhere(
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
        final days  = g.customDays ?? 1;
        final start = DateTime.now().toUtc().subtract(Duration(days: days));
        return _monthLogs
            .where((log) => log.dateUtc.isAfter(start))
            .map((log) => goalValueOf(log.entries[habitId], habit))
            .fold(0, (a, b) => a + b);
    }
  }

  bool _isInCurrentWeek(DateTime d) {
    final now    = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    return d.isAfter(monday.subtract(const Duration(days: 1))) &&
        d.isBefore(sunday.add(const Duration(days: 1)));
  }

  // ─── HABITS CRUD ────────────────────────────────────────────────────────────

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

    // If a step habit was just created, sync immediately
    if (habit.kind == RatingKind.steps) await _syncStepHabits();
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
    final lang = context.read<LanguageNotifier>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lang.t('delete_habit_title')),
        content: Text("${lang.t('delete_habit_confirm')} '${h.name}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(lang.t('no')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(lang.t('yes')),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await _repo.deleteHabit(userId: widget.userId, habitId: h.id);
    SoundService.playDeleteHabit();

    setState(() {
      _habits.removeWhere((x) => x.id == h.id);
      _today = _today?.removeValue(h.id);
    });
  }

  // ─── GOALS CRUD ─────────────────────────────────────────────────────────────

  Future<void> _addGoal() async {
    final goal = await showDialog<Goal>(
      context: context,
      builder: (_) => GoalEditorDialog(habits: _habits),
    );
    if (goal == null) return;

    await _repo.addGoal(userId: widget.userId, goal: goal);
    setState(() => _goals.add(goal));
  }

  Future<void> _editGoal(Goal g) async {
    final updated = await showDialog<Goal>(
      context: context,
      builder: (_) => GoalEditorDialog(habits: _habits, initial: g),
    );
    if (updated == null) return;

    await _repo.updateGoal(userId: widget.userId, goal: updated);
    setState(() {
      final i = _goals.indexWhere((x) => x.id == updated.id);
      if (i >= 0) _goals[i] = updated;
    });
  }

  Future<void> _deleteGoal(Goal g) async {
    final lang = context.read<LanguageNotifier>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lang.t('delete_goal_title')),
        content: Text("${lang.t('delete_goal_confirm')} '${g.name}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(lang.t('no')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(lang.t('yes')),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await _repo.deleteGoal(userId: widget.userId, goalId: g.id);
    setState(() => _goals.removeWhere((x) => x.id == g.id));
  }

  // ─── HABIT VALUE HANDLING ───────────────────────────────────────────────────

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
      case RatingKind.steps:
        return const NumberValue(0);
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
        if (v is NumberValue) return NumberValue(v.value.clamp(min, max));
        return NumberValue(min);

      case RatingKind.enumerator:
        final opts = h.options ?? const [];
        if (v is EnumValue && opts.contains(v.option)) return v;
        return opts.isNotEmpty ? EnumValue(opts.first) : null;

      case RatingKind.steps:
        return v is NumberValue ? v : const NumberValue(0);
    }
  }

  void _setValue(Habit h, RatingValue v) {
    SoundService.playMarkHabit();

    final newLog = (_today ??
        DayLog(dateUtc: DateTime.now().toUtc(), entries: {}))
        .setValue(h.id, v);

    setState(() => _today = newLog);
    _repo.upsertDayLog(userId: widget.userId, log: newLog);
  }

  // ─── AUTO HABIT TRACKER ─────────────────────────────────────────────────────

  Future<void> _ensureAutoHabitExists() async {
    const auto = Habit(
      id: 'app2min',
      name: '2minutes',
      kind: RatingKind.checkbox,
      systemOnly: true,
    );

    if (!_habits.any((h) => h.id == auto.id)) {
      await _repo.addHabit(userId: widget.userId, habit: auto);
      if (!mounted) return;          // 👈 add this

      setState(() => _habits.add(auto));
    }
  }

  @override
  void dispose() {
    _tracker?.stop();
    super.dispose();
  }

  // ─── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageNotifier>();

    if (_today == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: CustomAppBar(title: lang.t('your_habits')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          children: [
            _buildHabitsSection(),
            const SizedBox(height: 80),
            _buildGoalsSection(),
          ],
        ),
      ),
    );
  }


// ─── FAB ADD BUTTON ──────────────────────────────────────────────────────────

  Widget _fabAdd(VoidCallback onTap) {
    final colors = context.colors;

    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colors.intenseColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add, color: Colors.black, size: 22),
        ),
      ),
    );
  }

// ─── HABITS SECTION ──────────────────────────────────────────────────────────

  Widget _buildHabitsSection() {
    final colors = context.colors;
    final lang = context.watch<LanguageNotifier>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(lang.t('your_habits')),
        const SizedBox(height: 10),

        ..._habits.map((h) {
          final v = _today!.entries[h.id];
          final rowHeight = h.kind == RatingKind.steps ? 74.0 : 56.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            height: rowHeight,
            decoration: BoxDecoration(
              color: colors.background2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.background, width: 0.5),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: h.systemOnly ? null : () => _editHabit(h),
              onLongPress: h.systemOnly ? null : () => _deleteHabit(h),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (h.icon != null) ...[
                      Icon(habitIconData(h.icon),
                          size: 18, color: colors.appBarUnpickedColor),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        h.name,
                        style: TextStyle(fontSize: 14, color: colors.textColor),
                      ),
                    ),
                    _buildTrailingFor(h, v),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 4),
        _fabAdd(_addHabit),
      ],
    );
  }

// ─── GOALS SECTION ───────────────────────────────────────────────────────────

  Widget _buildGoalsSection() {
    final colors = context.colors;
    final lang = context.watch<LanguageNotifier>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(lang.t('your_goals')),
        const SizedBox(height: 10),

        if (_goals.isEmpty)
          const SizedBox.shrink()
        else
          ..._goals.map((g) {
            final progress = _calculateGoalProgress(g);
            final percent = (progress / g.target).clamp(0.0, 1.0);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: colors.background2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.background, width: 0.5),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _editGoal(g),
                onLongPress: () => _deleteGoal(g),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(g.name,
                            style: TextStyle(
                                fontSize: 14, color: colors.textColor)),
                        Text(
                          "$progress / ${g.target}",
                          style: TextStyle(
                              fontSize: 13, color: colors.appBarUnpickedColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 6,
                        backgroundColor: colors.background,
                        color: percent >= 1 ? Colors.green : colors.intenseColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

        const SizedBox(height: 4),
        _fabAdd(_addGoal),
      ],
    );
  }

  // ─── HABIT TRAILING WIDGET ──────────────────────────────────────────────────

  Widget _buildTrailingFor(Habit h, RatingValue? v) {
    final lang = context.read<LanguageNotifier>();

    switch (h.kind) {

      case RatingKind.checkbox:
        final checked = (v is BoolValue) ? v.value : false;

        if (h.systemOnly) {
          return IgnorePointer(child: Checkbox(value: checked, onChanged: null));
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
                NumberValue((numVal - 5).clamp(h.min ?? -999999, h.max ?? 999999)),
              ),
            ),
            SizedBox(
              width: 24,
              child: Center(
                child: Text("$numVal", style: const TextStyle(fontSize: 14)),
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
                NumberValue((numVal + 5).clamp(h.min ?? -999999, h.max ?? 999999)),
              ),
            ),
          ],
        );

      case RatingKind.scale:
        final min     = h.min ?? 1;
        final max     = h.max ?? 5;
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
        final options  = h.options ?? const ["A", "B", "C"];
        final selected = (v is EnumValue) ? v.option : null;

        return DropdownButton<String>(
          value: options.contains(selected) ? selected : null,
          hint: Text(lang.t('select_hint')),
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (val) {
            if (val != null) _setValue(h, EnumValue(val));
          },
        );

    // ── Steps trailing widget ──────────────────────────────────────────────
      case RatingKind.steps:
        final goal    = h.stepGoal ?? 0;
        final steps   = _todaySteps;
        final percent = goal > 0 ? (steps / goal).clamp(0.0, 1.0) : 0.0;
        final isDone  = goal > 0 && steps >= goal;
        return SizedBox(
          width: 140,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isDone)
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  if (isDone) const SizedBox(width: 4),
                  Text(
                    "$steps / $goal",
                    style: TextStyle(
                      fontSize: 13,
                      color: isDone ? Colors.green : Colors.black87,
                      fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.grey[300],
                color: isDone ? Colors.green : Colors.blue,
                minHeight: 6,
              ),
            ],
          ),
        );
    }
  }
}