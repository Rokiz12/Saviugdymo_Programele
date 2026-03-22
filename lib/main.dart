import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'pages/avatar.dart';
import 'pages/diary.dart';
import 'pages/habits.dart';
import 'pages/minigames.dart';
import 'pages/settings.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return MainScreen(userId: snapshot.data!.uid);
          }
          return const LoginPage();
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final String userId;
  const MainScreen({super.key, required this.userId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int selectedIndex = 2;
  late TabController tabController;
  late List<Widget> pages;

  @override
  void initState() {
    super.initState();

    pages = [
      CollectionPage(userId: widget.userId),
      AvatarPage(),
      HabitsPage(),
      DiaryPage(),
      SettingsPage(),
    ];

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
            label: "Kolekcija",
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