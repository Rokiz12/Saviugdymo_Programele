import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  // Main categories
  bool fitness = false;
  bool nutrition = false;
  bool sleep = false;
  bool productivity = false;

  // Fitness types
  bool running = false;
  bool gym = false;
  bool walking = false;

  // Controllers
  final TextEditingController fitnessDaysController = TextEditingController();
  final TextEditingController sleepHoursController = TextEditingController();
  final TextEditingController productivityHoursController = TextEditingController();

  final TextEditingController runningKmController = TextEditingController();
  final TextEditingController gymDaysController = TextEditingController();
  final TextEditingController walkingStepsController = TextEditingController();

  List<String> generateGoals() {
    List<String> goals = [];

    if (fitness) {
      final days = fitnessDaysController.text;
      if (days.isNotEmpty) {
        goals.add("Sportuoti $days dienas per savaitę");
      }

      if (running) {
        final km = runningKmController.text;
        if (km.isNotEmpty) {
          goals.add("Bėgti $km km per savaitę");
        }
      }

      if (gym) {
        final gymDays = gymDaysController.text;
        if (gymDays.isNotEmpty) {
          goals.add("Eiti į sporto salę $gymDays kartus per savaitę");
        }
      }

      if (walking) {
        final steps = walkingStepsController.text;
        if (steps.isNotEmpty) {
          goals.add("Nueiti $steps žingsnių per dieną");
        }
      }
    }

    if (sleep) {
      final hours = sleepHoursController.text;
      if (hours.isNotEmpty) {
        goals.add("Miegoti $hours valandas per parą");
      }
    }

    if (productivity) {
      final hours = productivityHoursController.text;
      if (hours.isNotEmpty) {
        goals.add("Būti produktyviam $hours valandas per dieną");
      }
    }

    return goals;
  }

  void submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final goals = generateGoals();

    print(goals);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Goals sugeneruoti!")),
    );

    Navigator.pop(context, goals);
  }

  Widget numberInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Klausimynas'),
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ką nori pagerinti?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            CheckboxListTile(
              title: const Text("Sportas"),
              value: fitness,
              onChanged: (val) => setState(() => fitness = val!),
            ),

            CheckboxListTile(
              title: const Text("Miegas"),
              value: sleep,
              onChanged: (val) => setState(() => sleep = val!),
            ),

            CheckboxListTile(
              title: const Text("Produktyvumas"),
              value: productivity,
              onChanged: (val) => setState(() => productivity = val!),
            ),

            const SizedBox(height: 20),

            if (fitness) ...[

              const Text(
                "Pasirink sporto tipą:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              CheckboxListTile(
                title: const Text("Bėgimas"),
                value: running,
                onChanged: (val) => setState(() => running = val!),
              ),

              if (running)
                numberInput("Kiek km per savaitę?", runningKmController),

              CheckboxListTile(
                title: const Text("Sporto salė"),
                value: gym,
                onChanged: (val) => setState(() => gym = val!),
              ),

              if (gym)
                numberInput("Kiek kartų per savaitę?", gymDaysController),

              CheckboxListTile(
                title: const Text("Vaikščiojimas"),
                value: walking,
                onChanged: (val) => setState(() => walking = val!),
              ),

              if (walking)
                numberInput("Kiek žingsnių per dieną?", walkingStepsController),
            ],

            if (sleep)
              numberInput("Kiek valandų miego per parą?", sleepHoursController),

            if (productivity)
              numberInput("Kiek valandų produktyvumo per dieną?", productivityHoursController),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: submit,
                child: const Text("Išsaugoti ir generuoti dienos užduotis"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}