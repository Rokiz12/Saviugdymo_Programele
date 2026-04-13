import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'pages/combined_avatar_and_collection.dart';
import 'pages/avatar.dart';
import 'pages/diary.dart';
import 'pages/habits.dart';
import 'pages/settings.dart';
import 'pages/login_page.dart';
import 'pages/minigames.dart';
import 'services/reward_notifier.dart';
import 'services/reward_service.dart';
import '/data/repositories/user_repository.dart';
import 'widgets/reward_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (_) => RewardNotifier(),
      child: const MyApp(),
    ),
  );
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
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
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

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  bool _rewardDialogShowing = false;
  int selectedIndex = 2;
  late TabController tabController;
  late List<Widget> pages;

  @override
  void initState() {
    super.initState();

    pages = [
      CombinedAvatarAndCollectionPage(userId: widget.userId),
      HabitsPage(),
      DiaryPage(),
      SettingsPage(),
    ];

    tabController = TabController(
        length: 5, vsync: this, initialIndex: selectedIndex);
    tabController.addListener(() {
      if (tabController.index != selectedIndex) {
        setState(() => selectedIndex = tabController.index);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RewardNotifier>().addListener(_onRewardChanged);
      _checkDailyReward();
    });
  }

  Future<void> _checkDailyReward() async {
    final user = await UserRepository().getUser(widget.userId);
    if (user == null || !mounted) return;
    final notifier = context.read<RewardNotifier>();
    await RewardService().checkDailyReward(user, notifier);
  }

  void _onRewardChanged() {
    final notifier = context.read<RewardNotifier>();
    if (notifier.hasPending && !_rewardDialogShowing && mounted) {
      _rewardDialogShowing = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => RewardDialog(
          reward: notifier.current!,
          onClaim: () {
            Navigator.of(dialogContext).pop();
            _rewardDialogShowing = false;
            notifier.dismiss();
          },
        ),
      ).then((_) {
        if (mounted) _rewardDialogShowing = false;
      });
    }
  }

  @override
  void dispose() {
    context.read<RewardNotifier>().removeListener(_onRewardChanged);
    tabController.dispose();
    super.dispose();
  }

  void onItemTapped(int index) => tabController.animateTo(index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(controller: tabController, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Avataras"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Statistikos"),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: "Įpročiai"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Dienoraštis"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Nustatymai"),
        ],
      ),
    );
  }
}