import 'package:flutter/material.dart';
import '../models/models.dart';
import '../../../theme/app_theme.dart';

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
    final colors = context.colors;
    final editing = widget.initial != null;

    return AlertDialog(
      title: Text(editing ? "Redaguoti tikslą" : "Naujas tikslas"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: "Pavadinimas"),
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: _selectedHabitId,
              decoration: const InputDecoration(labelText: "Įprotis"),
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
              decoration: const InputDecoration(labelText: "Tikslas (skaičius)"),
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<GoalPeriod>(
              value: _period,
              decoration: const InputDecoration(labelText: "Laikotarpis"),
              items: GoalPeriod.values.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(
                    switch (p) {
                      GoalPeriod.day    => "Diena",
                      GoalPeriod.week   => "Savaitė",
                      GoalPeriod.month  => "Mėnuo",
                      GoalPeriod.year   => "Metai",
                      GoalPeriod.custom => "Custom (dienomis)",
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
                decoration: const InputDecoration(
                  labelText: "Laikotarpis (dienomis)",
                  hintText: "pvz.: 10 (kas 10 dienų)",
                ),
              ),
            ]

          ],
        ),
      ),

      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text("Atšaukti", style: TextStyle(color: colors.intenseColor))),

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
          child: Text(editing ? "Išsaugoti" : "Pridėti", style: TextStyle(color: colors.intenseColor)),
        )
      ],
    );
  }
}