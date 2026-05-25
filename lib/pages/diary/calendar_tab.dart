import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import 'diary_provider.dart';
import 'diary_dialogs.dart';

class CalendarTab extends StatelessWidget {
  const CalendarTab({super.key});

  List<DateTime> _getDaysInMonth(DateTime currentMonth) {
    DateTime first = DateTime(currentMonth.year, currentMonth.month, 1);
    DateTime last = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    int leading = first.weekday - 1;
    var days = List.generate(leading, (i) => DateTime(first.year, first.month, -i)).reversed.toList();
    days.addAll(List.generate(last.day, (i) => DateTime(first.year, first.month, i + 1)));
    return days;
  }

  String _getMonthName(int m) => ['Sausis', 'Vasaris', 'Kovas', 'Balandis', 'Gegužė', 'Birželis', 'Liepa', 'Rugpjūtis', 'Rugsėjis', 'Spalis', 'Lapkritis', 'Gruodis'][m - 1];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = context.watch<DiaryProvider>();
    final weekDays = ['P', 'A', 'T', 'K', 'P', 'Š', 'S'];
    final daysInMonth = _getDaysInMonth(provider.currentMonth);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: () => provider.setMonth(DateTime(provider.currentMonth.year, provider.currentMonth.month - 1)), icon: Icon(Icons.chevron_left, color: colors.textColor)),
              Text('${provider.currentMonth.year} ${_getMonthName(provider.currentMonth.month)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textColor)),
              IconButton(onPressed: () => provider.setMonth(DateTime(provider.currentMonth.year, provider.currentMonth.month + 1)), icon: Icon(Icons.chevron_right, color: colors.textColor)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((d) => Expanded(child: Center(child: Text(d, style: TextStyle(fontWeight: FontWeight.bold, color: colors.appBarUnpickedColor))))).toList(),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1, crossAxisSpacing: 4, mainAxisSpacing: 4),
              itemCount: daysInMonth.length,
              itemBuilder: (context, index) {
                final day = daysInMonth[index];
                final isCurrent = day.month == provider.currentMonth.month;
                final hasEntry = provider.entriesByDate.containsKey(DateTime(day.year, day.month, day.day));
                final isSelected = provider.selectedDay != null && day.year == provider.selectedDay!.year && day.month == provider.selectedDay!.month && day.day == provider.selectedDay!.day;

                return GestureDetector(
                  onTap: isCurrent ? () {
                    provider.setDay(day);
                    final entries = provider.entriesByDate[DateTime(day.year, day.month, day.day)];
                    if (entries == null || entries.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Nėra įrašų")));
                    } else if (entries.length == 1) {
                      DiaryDialogs.showEntryDialog(context, entries.first);
                    } else {
                      DiaryDialogs.showEntriesList(context, entries);
                    }
                  } : null,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? colors.intenseColor : (isCurrent && hasEntry ? colors.primary : Colors.transparent),
                    ),
                    child: Center(child: Text(
                      day.day.toString(),
                      style: TextStyle(
                        fontWeight: isSelected || hasEntry ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? (isSelected ? Colors.black : colors.textColor) : colors.appBarUnpickedColor.withOpacity(0.3)
                      ),
                    )),
                  ),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton.icon(
            onPressed: () => DefaultTabController.of(context)?.animateTo(0),
            icon: const Icon(Icons.add),
            label: const Text("Pridėti naują įrašą"),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.intenseColor, foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}