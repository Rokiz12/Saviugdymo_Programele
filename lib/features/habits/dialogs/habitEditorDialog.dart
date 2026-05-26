import 'package:flutter/material.dart';
import '../models/models.dart';
import '../../../theme/app_theme.dart';

class HabitEditorDialog extends StatefulWidget {
  final Habit? initial;
  const HabitEditorDialog({super.key, this.initial});

  @override
  State<HabitEditorDialog> createState() => _HabitEditorDialogState();
}

class IconPickerField extends StatefulWidget {
  final String? initial;
  final ValueChanged<String?> onChanged;
  const IconPickerField({super.key, this.initial, required this.onChanged});

  @override
  State<IconPickerField> createState() => _IconPickerFieldState();
}

class _IconPickerFieldState extends State<IconPickerField> {
  static const _icons = {
    'run':        Icons.directions_run,
    'water':      Icons.water_drop,
    'book':       Icons.menu_book,
    'sleep':      Icons.bedtime,
    'food':       Icons.restaurant,
    'heart':      Icons.favorite,
    'gym':        Icons.fitness_center,
    'meditation': Icons.self_improvement,
    'music':      Icons.music_note,
    'code':       Icons.code,
    'study':      Icons.school,
    'money':      Icons.attach_money,
    'walk':       Icons.directions_walk,
    'bike':       Icons.directions_bike,
    'clean':      Icons.cleaning_services,
    'journal':    Icons.edit_note,
  };

  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Ikonėlė", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _icons.entries.map((e) {
            final isSelected = _selected == e.key;
            return GestureDetector(
              onTap: () {
                setState(() => _selected = e.key);
                widget.onChanged(e.key);
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? colors.primary : colors.background2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? colors.primary : colors.background2,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Icon(e.value, size: 24),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _HabitEditorDialogState extends State<HabitEditorDialog> {
  final _nameCtrl     = TextEditingController();
  final _minCtrl      = TextEditingController();
  final _maxCtrl      = TextEditingController();
  final _optionsCtrl  = TextEditingController();
  final _stepGoalCtrl = TextEditingController(); // ← new

  RatingKind _kind = RatingKind.checkbox;
  String? _selectedIcon;

  @override
  void initState() {
    super.initState();
    final h = widget.initial;
    if (h != null) {
      _nameCtrl.text = h.name;
      _kind = h.kind;
      _selectedIcon = h.icon;
      if (h.min != null) _minCtrl.text = '${h.min}';
      if (h.max != null) _maxCtrl.text = '${h.max}';
      if (h.stepGoal != null) _stepGoalCtrl.text = '${h.stepGoal}';
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
    _stepGoalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final editing = widget.initial != null;

    return AlertDialog(

      title: Text(editing ? "Redaguoti įprotį" : "Naujas įprotis"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: "Pavadinimas"),
            ),
            const SizedBox(height: 16),

            IconPickerField(
              initial: _selectedIcon,
              onChanged: (key) => setState(() => _selectedIcon = key),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<RatingKind>(
              value: _kind,
              decoration: const InputDecoration(labelText: 'Tipas'),
              items: RatingKind.values.map((k) {
                return DropdownMenuItem(
                  value: k,
                  child: Text(
                    switch (k) {
                      RatingKind.checkbox   => "Pažyma (✔/✖)",
                      RatingKind.number     => "Skaičius",
                      RatingKind.scale      => "Skalė",
                      RatingKind.enumerator => "Kategorija",
                      RatingKind.steps      => "Žingsniai 👟",  // ← new
                    },
                  ),
                );
              }).toList(),
              onChanged: (k) => setState(() => _kind = k ?? RatingKind.checkbox),
            ),

            // Number / Scale fields
            if (_kind == RatingKind.number || _kind == RatingKind.scale) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _minCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Min"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _maxCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Max"),
              ),
            ],

            // Enumerator fields
            if (_kind == RatingKind.enumerator) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _optionsCtrl,
                decoration: const InputDecoration(
                  labelText: "Parinktys (atskirti kableliais)",
                ),
              ),
            ],

            // Steps field  ← new
            if (_kind == RatingKind.steps) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _stepGoalCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Tikslas (žingsniai)",
                  hintText: "pvz. 10000",
                  prefixIcon: Icon(Icons.directions_walk),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Pažymės kaip atliktą automatiškai, kai pasieksite tikslą.",
                style: TextStyle(fontSize: 12, color : colors.textColor),
              ),
            ],
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Atšaukti"),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(editing ? "Išsaugoti" : "Pridėti"),
        ),
      ],
    );
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    int? min = int.tryParse(_minCtrl.text);
    int? max = int.tryParse(_maxCtrl.text);
    int? stepGoal = int.tryParse(_stepGoalCtrl.text);

    // Clear irrelevant fields per kind
    if (!(_kind == RatingKind.number || _kind == RatingKind.scale)) {
      min = null;
      max = null;
    }
    if (_kind != RatingKind.steps) {
      stepGoal = null;
    }

    List<String>? opts;
    if (_kind == RatingKind.enumerator) {
      final raw = _optionsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty && s != '---')
          .toList();
      opts = ['---', ...raw];
    }

    final id = widget.initial?.id ??
        "${name.toLowerCase().replaceAll(' ', '-')}-${DateTime.now().millisecondsSinceEpoch}";

    final habit = Habit(
      id: id,
      name: name,
      kind: _kind,
      min: min,
      max: max,
      options: opts,
      icon: _selectedIcon,
      stepGoal: stepGoal,   // ← new
    );

    Navigator.pop(context, habit);
  }
}