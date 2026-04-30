import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/habits/models/habit.dart';
import '../features/habits/models/goalsModel.dart';
import '../features/habits/models/ratingKind.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {

  bool fitness = false;
  bool sleep = false;
  bool productivity = false;

  bool running = false;
  bool gym = false;
  bool walking = false;

  final runningKmController = TextEditingController();
  final gymDaysController = TextEditingController();
  final walkingStepsController = TextEditingController();
  final sleepHoursController = TextEditingController();
  final productivityHoursController = TextEditingController();

  // 🔥 UNIVERSALI FUNKCIJA (be copy-paste)
  Future<void> _createHabitWithGoal({
    required String userId,
    required String habitName,
    required RatingKind kind,
    required int target,
    required GoalPeriod period,
    required String goalName,
    int? min,
    int? max,
  }) async {
    final db = FirebaseFirestore.instance;

    // 🔥 Firestore sugeneruoja ID
    final habitRef = db
        .collection('users')
        .doc(userId)
        .collection('habits')
        .doc();

    final habit = Habit(
      id: habitRef.id,
      name: habitName,
      kind: kind,
      min: min,
      max: max,
    );

    await habitRef.set(habit.toJson());

    // 🔥 Goal su tuo pačiu habit ID
    final goalRef = db
        .collection('users')
        .doc(userId)
        .collection('goals')
        .doc();

    final goal = Goal(
      id: goalRef.id,
      name: goalName,
      habbitID: habit.id,
      target: target,
      period: period,
      repeat: true,
    );

    await goalRef.set(goal.toJson());
  }

  // 🔥 MAIN SAVE LOGIC
  Future<void> saveToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;

    // RUNNING
    if (running && runningKmController.text.isNotEmpty) {
      await _createHabitWithGoal(
        userId: userId,
        habitName: "Bėgimas",
        kind: RatingKind.number,
        target: int.parse(runningKmController.text),
        period: GoalPeriod.week,
        goalName: "Bėgti ${runningKmController.text} km per savaitę",
        min: 0,
        max: 200,
      );
    }

    // GYM
    if (gym && gymDaysController.text.isNotEmpty) {
      await _createHabitWithGoal(
        userId: userId,
        habitName: "Sporto salė",
        kind: RatingKind.checkbox,
        target: int.parse(gymDaysController.text),
        period: GoalPeriod.week,
        goalName: "Eiti į salę ${gymDaysController.text} kartus/sav.",
      );
    }

    // WALKING
    if (walking && walkingStepsController.text.isNotEmpty) {
      await _createHabitWithGoal(
        userId: userId,
        habitName: "Vaikščiojimas",
        kind: RatingKind.number,
        target: int.parse(walkingStepsController.text),
        period: GoalPeriod.day,
        goalName: "Nueiti ${walkingStepsController.text} žingsnių per dieną",
        min: 0,
        max: 50000,
      );
    }

    // SLEEP
    if (sleep && sleepHoursController.text.isNotEmpty) {
      await _createHabitWithGoal(
        userId: userId,
        habitName: "Miegas",
        kind: RatingKind.number,
        target: int.parse(sleepHoursController.text),
        period: GoalPeriod.day,
        goalName: "Miegoti ${sleepHoursController.text} valandas",
        min: 0,
        max: 24,
      );
    }

    // PRODUCTIVITY
    if (productivity && productivityHoursController.text.isNotEmpty) {
      await _createHabitWithGoal(
        userId: userId,
        habitName: "Produktyvumas",
        kind: RatingKind.number,
        target: int.parse(productivityHoursController.text),
        period: GoalPeriod.day,
        goalName: "Dirbti ${productivityHoursController.text} valandas",
        min: 0,
        max: 24,
      );
    }
  }

  void submit() async {
    await saveToFirebase();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Goals išsaugoti!")),
    );

    Navigator.pop(context);
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
              const Text("Pasirink sporto tipą:", style: TextStyle(fontWeight: FontWeight.bold)),

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
                child: const Text("Išsaugoti ir generuoti goals"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}