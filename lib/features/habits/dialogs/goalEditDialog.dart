import 'package:flutter/material.dart';
import '../models/models.dart';
import '../../../services/language_notifier.dart';
import 'package:provider/provider.dart';

final _customDaysCtrl = TextEditingController();
bool _repeat = false;


class GoalEditorDialog extends StatefulWidget {
  final Goal? initial;
  final List<Habit> habits;

  const GoalEditorDialog({
    super.key,
    required this.habits,
    this.initial,
  });

  @override
  State<GoalEditorDialog> createState() => _GoalEditorDialogState();
}

class _GoalEditorDialogState extends State<GoalEditorDialog> {
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();

  String? _selectedHabitId;
  GoalPeriod _period = GoalPeriod.month;

  @override
  void initState() {
    super.initState();

    final g = widget.initial;

    if (g != null) {
      _nameCtrl.text = g.name;
      _targetCtrl.text = "${g.target}";
      _selectedHabitId = g.habbitID;
      _period = g.period;
      _repeat = g.repeat;
    } else {
      _selectedHabitId = widget.habits.isNotEmpty ? widget.habits.first.id : null;
    }


    if (g != null && g.period == GoalPeriod.custom) {
      _customDaysCtrl.text = "${g.customDays ?? 1}";
    }
    _repeat = g?.repeat ?? false;

  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    final lang = context.watch<LanguageNotifier>();

    return AlertDialog(
      title: Text(
        editing
            ? lang.t('edit_goal')
            : lang.t('new_goal'),
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: lang.t('title'),
              ),
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: _selectedHabitId,
                decoration: InputDecoration(
                  labelText: lang.t('habit'),
                ),
              items: widget.habits.map((h) {
                return DropdownMenuItem(
                  value: h.id,
                  child: Text(h.name),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedHabitId = v),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _targetCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: lang.t('goal_number'),
              ),
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<GoalPeriod>(
              value: _period,
              decoration: InputDecoration(
                labelText: lang.t('period'),
              ),
              items: GoalPeriod.values.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(
                    switch (p) {
                      GoalPeriod.day    => lang.t('period_day'),
                      GoalPeriod.week   => lang.t('period_week'),
                      GoalPeriod.month  => lang.t('period_month'),
                      GoalPeriod.year   => lang.t('period_year'),
                      GoalPeriod.custom => lang.t('period_custom'),
                    },
                  ),

                );

              }).toList(),
              onChanged: (v) => setState(() => _period = v ?? GoalPeriod.month),

            ),



            if (_period == GoalPeriod.custom) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _customDaysCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: lang.t('period_days'),
                  hintText: lang.t('period_days_hint'),
                ),
              ),
            ]

          ],
        ),
      ),

      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.t('cancel'))),

        TextButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            final target = int.tryParse(_targetCtrl.text.trim()) ?? 0;

            if (name.isEmpty || _selectedHabitId == null) return;

            final id = widget.initial?.id ??
                "${name.toLowerCase().replaceAll(' ', '-')}-${DateTime.now().millisecondsSinceEpoch}";


            final goal = Goal(
              id: id,
              name: name,
              habbitID: _selectedHabitId!,
              target: target,
              period: _period,
              customDays: _period == GoalPeriod.custom
                  ? int.tryParse(_customDaysCtrl.text.trim()) ?? 1
                  : null,
              repeat: _repeat,
            );


            Navigator.pop(context, goal);
          },
          child: Text(
            editing
                ? lang.t('save')
                : lang.t('add'),
          ),
        )
      ],
    );
  }
}