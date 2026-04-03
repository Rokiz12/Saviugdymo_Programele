import 'package:flutter/material.dart';
import '../models/models.dart';

class HabitEditorDialog extends StatefulWidget {
  final Habit? initial;
  const HabitEditorDialog({super.key, this.initial});

  @override
  State<HabitEditorDialog> createState() => _HabitEditorDialogState();
}

class _HabitEditorDialogState extends State<HabitEditorDialog> {
  final _nameCtrl = TextEditingController();
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  final _optionsCtrl = TextEditingController();

  RatingKind _kind = RatingKind.checkbox;

  @override
  void initState() {
    super.initState();
    final h = widget.initial;

    if (h != null) {
      _nameCtrl.text = h.name;
      _kind = h.kind;

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
            );

            Navigator.pop(context, habit);
          },
          child: Text(editing ? "Išsaugoti" : "Pridėti"),
        )
      ],
    );
  }
}