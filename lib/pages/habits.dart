// lib/pages/habits.dart
import 'package:flutter/material.dart';
import 'package:pvp/features/habits/models/models.dart';
import 'package:pvp/features/habits/data/dayLogRepository.dart';

// You can keep this in the same file as the page for now.
class HabitEditorDialog extends StatefulWidget {
  const HabitEditorDialog({super.key, this.initial});
  final Habit? initial;

  @override
  State<HabitEditorDialog> createState() => _HabitEditorDialogState();
}

class _HabitEditorDialogState extends State<HabitEditorDialog> {
  final _nameCtrl = TextEditingController();
  RatingKind _kind = RatingKind.checkbox;
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  final _optionsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final h = widget.initial;
    if (h != null) {
      _nameCtrl.text = h.name;
      _kind = h.kind;
      if (h.min != null) _minCtrl.text = '${h.min}';
      if (h.max != null) _maxCtrl.text = '${h.max}';
      if (h.options != null && h.options!.isNotEmpty) {
        _optionsCtrl.text = h.options!.join(', ');
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _optionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return AlertDialog(
      title: Text(isEdit ? 'Redaguoti įprotį' : 'Naujas įprotis'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Pavadinimas'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<RatingKind>(
              value: _kind,
              decoration: const InputDecoration(labelText: 'Tipas'),
              items: RatingKind.values.map((k) {
                return DropdownMenuItem(
                  value: k,
                  child: Text(switch (k) {
                    RatingKind.checkbox     => 'Pažyma (✔/✖)',
                    RatingKind.number       => 'Skaičius',
                    RatingKind.scale        => 'Skalė',
                    RatingKind.enumerator  => 'Kategorija',
                  }),
                );
              }).toList(),
              onChanged: (k) => setState(() => _kind = k ?? RatingKind.checkbox),
            ),
            if (_kind == RatingKind.number || _kind == RatingKind.scale) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _minCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Min'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _maxCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max'),
              ),
            ],
            if (_kind == RatingKind.enumerator) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _optionsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Parinktys (atskirti kableliais)',
                  hintText: 'pvz.: Bad, OK, Great',
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Atšaukti')),
        TextButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;

            int? min = int.tryParse(_minCtrl.text.trim());
            int? max = int.tryParse(_maxCtrl.text.trim());
            if (!(_kind == RatingKind.number || _kind == RatingKind.scale)) {
              min = null; max = null;
            }
            List<String>? opts;
            if (_kind == RatingKind.enumerator) {
              final raw = _optionsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
              opts = raw.isEmpty ? null : raw;
            }

            final id = widget.initial?.id ?? _newHabitId(name);
            final habit = Habit(
              id: id,
              name: name,
              kind: _kind,
              min: min,
              max: max,
              options: opts,
            );
            Navigator.pop(context, habit);
          },
          child: Text(widget.initial == null ? 'Pridėti' : 'Išsaugoti'),
        ),
      ],
    );
  }

  String _newHabitId(String name) {
    // Quick ID: slug + timestamp (replace with proper UUID later)
    final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'-+'), '-');
    return '$slug-${DateTime.now().millisecondsSinceEpoch}';
  }
}


class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  final _repo = InMemoryDayLogRepository(); // swap later for real DB repo
  final _userId = 'demo_user';

  List<Habit> _habits = [];
  DayLog? _today;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final habits = await _repo.getHabits(userId: _userId);

    final now = DateTime.now().toUtc();
    final start = DateTime.utc(now.year, now.month, 1);
    final end   = DateTime.utc(now.year, now.month + 1, 0);
    final monthLogs = await _repo.getLogsForRange(
      userId: _userId, startInclusive: start, endInclusive: end,
    );

    DayLog? today = monthLogs.firstWhere(
          (l) => l.dateUtc.year == now.year && l.dateUtc.month == now.month && l.dateUtc.day == now.day,
      orElse: () => DayLog(dateUtc: DateTime.utc(now.year, now.month, now.day), entries: {}),
    );

    setState(() {
      _habits = habits;
      _today  = today;
    });
  }

  Future<void> _saveToday() async {
    if (_today != null) {
      await _repo.upsertDayLog(userId: _userId, log: _today!);
    }
  }

  void _setValue(Habit h, RatingValue v) {
    setState(() {
      _today = (_today ?? DayLog(dateUtc: DateTime.now().toUtc(), entries: {})).setValue(h.id, v);
    });
    _saveToday();
  }

  Future<void> _addHabit() async {
    final habit = await showDialog<Habit>(
      context: context,
      builder: (_) => HabitEditorDialog(),
    );
    if (habit == null) return;

    await _repo.addHabit(userId: _userId, habit: habit);
    setState(() => _habits = [..._habits, habit]);

    // Optionally set an initial value for today
    final initVal = _initialValueFor(habit);
    if (initVal != null) {
      _setValue(habit, initVal);
    }
  }

  Future<void> _editHabit(Habit h) async {
    final updated = await showDialog<Habit>(
      context: context,
      builder: (_) => HabitEditorDialog(initial: h),
    );
    if (updated == null) return;

    await _repo.updateHabit(userId: _userId, habit: updated);
    setState(() {
      final i = _habits.indexWhere((x) => x.id == updated.id);
      if (i >= 0) _habits[i] = updated;
    });

    // If kind changed, you may want to reset today's value to a compatible default
    if (_today?.entries[updated.id] case final v?) {
      final compatible = _coerceValueIfNeeded(updated, v);
      if (compatible != v) {
        _setValue(updated, compatible ?? _initialValueFor(updated) ?? v);
      }
    }
  }

  Future<void> _deleteHabit(Habit h) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ištrinti įprotį?'),
        content: Text("Ar tikrai norite ištrinti '${h.name}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Ne')),
          TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Taip')),
        ],
      ),
    );
    if (confirm != true) return;

    await _repo.deleteHabit(userId: _userId, habitId: h.id, cascadeDeleteValues: true);

    setState(() {
      _habits.removeWhere((x) => x.id == h.id);
      if (_today != null && _today!.entries.containsKey(h.id)) {
        _today = _today!.removeValue(h.id);
      }
    });
  }

  RatingValue? _initialValueFor(Habit h) {
    switch (h.kind) {
      case RatingKind.checkbox:     return const BoolValue(false);
      case RatingKind.number:       return NumberValue(h.min ?? 0);
      case RatingKind.scale:        return NumberValue((h.min ?? 1));
      case RatingKind.enumerator:  return (h.options?.isNotEmpty ?? false) ? EnumValue(h.options!.first) : null;
    }
  }

  RatingValue? _coerceValueIfNeeded(Habit h, RatingValue v) {
    switch (h.kind) {
      case RatingKind.checkbox:
        return (v is BoolValue) ? v : const BoolValue(false);
      case RatingKind.number:
        if (v is NumberValue) {
          final min = (h.min ?? -0x7fffffff);
          final max = (h.max ??  0x7fffffff);
          final clamped = v.value.clamp(min, max);
          return NumberValue(clamped);
        }
        return NumberValue(h.min ?? 0);
      case RatingKind.scale:
        final min = (h.min ?? 1), max = (h.max ?? 5);
        if (v is NumberValue) {
          final clamped = v.value.clamp(min, max);
          return NumberValue(clamped);
        }
        return NumberValue(min);
      case RatingKind.enumerator:
        final opts = h.options ?? const [];
        if (v is EnumValue && opts.contains(v.option)) return v;
        return opts.isNotEmpty ? EnumValue(opts.first) : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = _today;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Įpročiai'),
        backgroundColor: Colors.yellow,
        centerTitle: true,
      ),
      body: (today == null)
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ----------------- HABITS BOX (same look & feel) -----------------
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  ListView.separated(
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _habits.length,
                    itemBuilder: (context, index) {
                      final h = _habits[index];
                      final v = today.entries[h.id];

                      return SizedBox(
                        height: 44, // compact row, keeps font size
                        child: ListTile(
                          dense: true,
                          minVerticalPadding: 0,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          visualDensity: const VisualDensity(vertical: -1),
                          title: Text(h.name, style: const TextStyle(fontSize: 16)),
                          // Tap = edit, hold = delete
                          onTap: () => _editHabit(h),
                          onLongPress: () => _deleteHabit(h),
                          trailing: _buildTrailingFor(h, v),
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
            ),

            // placeholders
            const SizedBox(height: 30),

            Container( // months or week table
              height: 150,
              width: 450,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text("Month or weeks table")),
            ),

            const SizedBox(height: 30),

            Container( // goals table
              height: 150,
              width: 450,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text("Goals Table")),
            ),
          ],
        ),
      ),
    );
  }

  // Trailing control rendered by Habit.kind, writes DayLog on change
  Widget _buildTrailingFor(Habit h, RatingValue? v) {
    switch (h.kind) {
      case RatingKind.checkbox:
        final checked = (v is BoolValue) ? v.value : false;
        return Checkbox(
          value: checked,
          onChanged: (val) => _setValue(h, BoolValue(val ?? false)),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );

      case RatingKind.number:
        final numVal = (v is NumberValue) ? v.value : (h.min ?? 0);
        return SizedBox(
          width: 96,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove),
                onPressed: () {
                  final next = (numVal - 5).clamp(h.min ?? -999999, h.max ?? 999999);
                  _setValue(h, NumberValue(next));
                },
              ),
              Text('$numVal', style: const TextStyle(fontSize: 16)),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add),
                onPressed: () {
                  final next = (numVal + 5).clamp(h.min ?? -999999, h.max ?? 999999);
                  _setValue(h, NumberValue(next));
                },
              ),
            ],
          ),
        );

      case RatingKind.scale:
        final min = h.min ?? 1, max = h.max ?? 5;
        final current = (v is NumberValue) ? v.value.toDouble() : min.toDouble();
        return SizedBox(
          width: 160,
          child: Row(
            children: [
              Text('$min'),
              Expanded(
                child: Slider(
                  min: min.toDouble(),
                  max: max.toDouble(),
                  divisions: (max - min),
                  value: current.clamp(min.toDouble(), max.toDouble()),
                  onChanged: (val) => _setValue(h, NumberValue(val.round())),
                ),
              ),
              Text('$max'),
            ],
          ),
        );

      case RatingKind.enumerator:
        final options = h.options ?? const ['Bad', 'OK', 'Great'];
        final selected = (v is EnumValue) ? v.option : null;
        return DropdownButton<String>(
          value: (selected != null && options.contains(selected)) ? selected : null,
          hint: const Text('Pasirinkti'),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: (val) {
            if (val == null) return;
            _setValue(h, EnumValue(val));
          },
        );
    }
  }
}
