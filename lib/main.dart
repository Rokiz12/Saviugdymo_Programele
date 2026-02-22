import 'package:flutter/material.dart';

import 'pages/avatar.dart';
import 'pages/diary.dart';
import 'pages/habits.dart';
import 'pages/minigames.dart';
import 'pages/settings.dart';

void main() {
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

class _MainScreenState extends State<MainScreen> {

  int selectedIndex = 2;

  final List<Widget> pages = const[
    MinigamesPage(),
    AvatarPage(),
    HabitsPage(),
    DiaryPage(),
    SettingsPage()
  ];

  void onItemTapped(int index){
    setState((){
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Bottom navigation bar
      body: pages[selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const[
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



