import 'package:flutter/material.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  List<String> tasks = [
    "Sportas",
    "Skaitymas",
    "Meditacija",
    "Sportas",
    "Skaitymas",
    "Meditacija",
    "Sportas",
    "Skaitymas",
    "Meditacija",
  ];

  late List<bool> checked;

  @override
  void initState() {
    super.initState();
    checked = List<bool>.filled(tasks.length, false, growable: true);
  }

  void _addHabit() {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Pridėti įprotį"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: "Pavadinimas"),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Atšaukti")),
            TextButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    setState(() {
                      tasks.add(controller.text);
                      checked.add(false);
                    });
                  }
                  Navigator.pop(context);
                },
                child: const Text("Pridėti")),
          ],
        );
      },
    );
  }

  void _editHabit(int index) {
    TextEditingController controller =
    TextEditingController(text: tasks[index]);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Redaguoti įprotį"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: "Pavadinimas"),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Atšaukti")),
            TextButton(
                onPressed: () {
                  setState(() {
                    tasks[index] = controller.text;
                  });
                  Navigator.pop(context);
                },
                child: const Text("Išsaugoti")),
          ],
        );
      },
    );
  }

  void _deleteHabit(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Ištrinti įprotį?"),
          content: Text("Ar tikrai norite ištrinti '${tasks[index]}'?"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Ne")),
            TextButton(
                onPressed: () {
                  setState(() {
                    tasks.removeAt(index);
                    checked.removeAt(index);
                  });
                  Navigator.pop(context);
                },
                child: const Text("Taip")),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Įpročiai'),
        backgroundColor: Colors.yellow,
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),

          child: Column(
            children: [

              Container( // todays habbit table
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        return SizedBox(
                          height: 40, // ★ THIS controls the spacing (try 36–44)
                          child: ListTile(
                            dense: true,
                            minLeadingWidth: 0,
                            minVerticalPadding: 0,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 0),
                            visualDensity:
                            const VisualDensity(vertical: -1),

                            title: Text(
                              tasks[index],
                              style: const TextStyle(fontSize: 16),
                            ),

                            onTap: () => _editHabit(index),
                            onLongPress: () => _deleteHabit(index),

                            trailing: Checkbox(
                              value: checked[index],
                              onChanged: (value) {
                                setState(() => checked[index] = value!);
                              },
                              materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        );
                      },
                    ),

                    const Divider(height: 1, color: Colors.black),

                    TextButton.icon(
                      onPressed: _addHabit,
                      icon: const Icon(Icons.add, color: Colors.black),
                      label: const Text(
                        "Pridėti įprotį",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Container( //months or week table
                height: 150,
                width: 450,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text("Month or weeks table"),
                ),
              ),

              const SizedBox(height: 30),

              Container( // goals table
                height: 150,
                width: 450,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text("Goals Table"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}