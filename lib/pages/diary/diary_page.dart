import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../services/language_notifier.dart';
import 'diary_provider.dart';
import 'new_entry_tab.dart';
import 'calendar_tab.dart';
import 'memories_tab.dart';

class DiaryPage extends StatelessWidget {
  const DiaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lang = context.watch<LanguageNotifier>();

    return ChangeNotifierProvider(
      create: (_) => DiaryProvider(),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: colors.background,
          appBar: CustomAppBar(
            title: lang.t('nav_diary'),
            bottom: TabBar(
              indicatorColor: colors.intenseColor,
              labelColor: colors.textColor,
              unselectedLabelColor: colors.appBarUnpickedColor,
              tabs: [
                Tab(icon: const Icon(Icons.add), text: lang.t('diary_new')),
                Tab(icon: const Icon(Icons.calendar_month), text: lang.t('diary_calendar')),
                Tab(icon: const Icon(Icons.photo_library), text: lang.t('diary_memories')),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              NewEntryTab(),
              CalendarTab(),
              MemoriesTab(),
            ],
          ),
        ),
      ),
    );
  }
}