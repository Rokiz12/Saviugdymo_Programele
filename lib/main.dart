import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:pvp/features/habits/data/foreground_time_tracker.dart';

import 'features/habits/data/HabitRepository.dart';
import 'features/habits/models/dayLog.dart';
import 'features/habits/models/ratingValue.dart';
import 'pages/combined_avatar_and_collection.dart';
import 'pages/diary/diary_page.dart';
import 'pages/statistics.dart';
import 'pages/habits.dart';
import 'pages/settings.dart';
import 'pages/login_page.dart';
import 'services/reward_notifier.dart';
import 'services/reward_service.dart';
import 'services/image_preloader.dart';
import '/data/repositories/user_repository.dart';
import 'widgets/reward_dialog.dart';
import 'services/fcm_service.dart';
import 'services/theme_notifier.dart';
import 'services/language_notifier.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  preloadPetImages();

  // Create and initialize language notifier (loads date symbols)
  final languageNotifier = LanguageNotifier();
  await languageNotifier.initializeDateSymbols();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RewardNotifier()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => languageNotifier),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, _) {
        return MaterialApp(
          theme: AppTheme.of(themeNotifier.mode),
          debugShowCheckedModeBanner: false,
          routes: {
            '/settings': (context) => SettingsPage(),
          },
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasData) {
                return MainScreen(key: ValueKey(snapshot.data!.uid), userId: snapshot.data!.uid);
              }
              return const LoginPage();
            },
          ),
        );
      },
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
  late RewardNotifier _rewardNotifier;
  bool _rewardDialogShowing = false;
  int selectedIndex = 2;
  late TabController tabController;
  late List<Widget> pages;

  ForegroundTimeTracker? _tracker;

  @override
  void initState() {
    super.initState();

    pages = [
      CombinedAvatarAndCollectionPage(userId: widget.userId),
      StatisticsPage(userId: widget.userId),
      HabitsPage(userId: widget.userId),
      DiaryPage(),
    ];

    tabController = TabController(
        length: 4, vsync: this, initialIndex: selectedIndex);
    tabController.addListener(() {
      if (tabController.index != selectedIndex) {
        setState(() => selectedIndex = tabController.index);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FCMService.init(widget.userId);
      _rewardNotifier = context.read<RewardNotifier>();
      _rewardNotifier.addListener(_onRewardChanged);
      _checkDailyReward();

      context.read<ThemeNotifier>().loadFromDb(widget.userId);

    });

    _startTracker();
  }

  void _startTracker() {
    _tracker = ForegroundTimeTracker(
      threshold: const Duration(minutes: 2),
      onReached: (day) async {
        final repo = FirebaseDayLogRepository();

        // Load today's log
        final now = DateTime.now().toUtc();
        final logDay = DateTime.utc(now.year, now.month, now.day);
        final logs = await repo.getLogsForRange(
          userId: widget.userId,
          startInclusive: logDay,
          endInclusive: logDay,
        );

        DayLog log = logs.isNotEmpty
            ? logs.first
            : DayLog(dateUtc: logDay, entries: {});

        final alreadyCompleted = (log.entries['app2min'] as Map?)?['v'] == true;
        if (alreadyCompleted) return;

        // Mark completed & save
        log = log.setValue('app2min', const BoolValue(true));
        await repo.upsertDayLog(userId: widget.userId, log: log);

        // Give XP
        final userRepo = UserRepository();
        final (:oldLevel, :newLevel) = await userRepo.addUserXp(widget.userId, 20);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Gavai +20 XP!", style: TextStyle(fontWeight: FontWeight.bold))),
          );
        }

        final rewardNotifier = context.read<RewardNotifier>();
        await RewardService().checkLevelUp(
          userId: widget.userId,
          oldLevel: oldLevel,
          newLevel: newLevel,
          notifier: rewardNotifier,
        );
      },
    )..start();
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
    _rewardNotifier.removeListener(_onRewardChanged);
    tabController.dispose();
    super.dispose();
  }

  void onItemTapped(int index) => tabController.animateTo(index);

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageNotifier>();
    return Scaffold(
      body: TabBarView(controller: tabController, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: lang.t('nav_avatar')),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: lang.t('nav_statistics')),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: lang.t('nav_habits')),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: lang.t('nav_diary')),
        ],
      ),
    );
  }
}