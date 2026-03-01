import 'package:flutter/material.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  final List<String> tasks = [
    "Sportas",
    "Skaitymas",
    "Meditacija",
    "Atsikelti",
    "Atsikelti"
  ];

  late List<bool> checked;

  @override
  void initState() {
    super.initState();
    checked = List<bool>.filled(tasks.length, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Įpročiai',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.yellow,
        centerTitle: true,
      ),

      body: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),

            child: Column(
              children: [
                Row(
                  children: tasks.map((task) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          task,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const Divider(thickness: 1),

                Row(
                  children: List.generate(tasks.length, (index) {
                    return Expanded(
                      child: Center(
                        child: Checkbox(
                          value: checked[index],
                          onChanged: (value) {
                            setState(() {
                              checked[index] = value!;
                            });
                          },
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
