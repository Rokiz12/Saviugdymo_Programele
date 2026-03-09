import 'package:flutter/material.dart';

import 'pages/avatar.dart';
import 'pages/diary.dart';
import 'pages/habits.dart';
import 'pages/minigames.dart';
import 'pages/settings.dart';

import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();


  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen ({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int selectedIndex = 2;
  late TabController tabController;

  final List<Widget> pages = const [
    MinigamesPage(),
    AvatarPage(),
    HabitsPage(),
    DiaryPage(),
    SettingsPage()
  ];

  @override
  void initState() {
    super.initState();
    tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: selectedIndex,
    );

    tabController.addListener(() {
      if (tabController.index != selectedIndex) {
        setState(() {
          selectedIndex = tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  void onItemTapped(int index) {
    tabController.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        controller: tabController,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.videogame_asset),
            label: "Žaidimai",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Avataras",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: "Įpročiai",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: "Dienoraštis",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Nustatymai",
          ),
        ],
      ),
    );
  }
}


