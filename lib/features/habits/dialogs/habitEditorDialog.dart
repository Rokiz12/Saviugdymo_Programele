import 'package:flutter/material.dart';
import '../models/models.dart';

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
                  color: isSelected ? Colors.yellow : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? Colors.yellow.shade700 : Colors.grey.shade300,
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
  final _nameCtrl = TextEditingController();
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  final _optionsCtrl = TextEditingController();

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


      if (h.min != null) _minCtrl.text = "${h.min}";
      if (h.max != null) _maxCtrl.text = "${h.max}";
      if (h.options != null && h.options!.isNotEmpty) {
        _optionsCtrl.text = h.options!.join(", ");
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
                      RatingKind.checkbox => "Pažyma (✔/✖)",
                      RatingKind.number => "Skaičius",
                      RatingKind.scale => "Skalė",
                      RatingKind.enumerator => "Kategorija",
                    },
                  ),
                );
              }).toList(),
              onChanged: (k) => setState(() => _kind = k ?? RatingKind.checkbox),
            ),

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

            if (_kind == RatingKind.enumerator) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _optionsCtrl,
                decoration: const InputDecoration(
                  labelText: "Parinktys (atskirti kableliais)",
                ),
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
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;

            int? min = int.tryParse(_minCtrl.text);
            int? max = int.tryParse(_maxCtrl.text);

            if (!(_kind == RatingKind.number || _kind == RatingKind.scale)) {
              min = null;
              max = null;
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
            );

            Navigator.pop(context, habit);
          },
          child: Text(editing ? "Išsaugoti" : "Pridėti"),
        )
      ],
    );
  }
}