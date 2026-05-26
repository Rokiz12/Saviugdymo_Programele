import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import 'diary_provider.dart';
import 'diary_dialogs.dart';

class CalendarTab extends StatelessWidget {
  const CalendarTab({super.key});

  List<DateTime?> _getDaysInMonth(DateTime currentMonth) {
    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(currentMonth.year, currentMonth.month);
    final firstWeekday = firstDay.weekday; // 1 = Monday
    final totalCells = daysInMonth + (firstWeekday - 1);

    return List.generate(totalCells, (index) {
      if (index < firstWeekday - 1) return null; // leading empty cells
      final day = index - (firstWeekday - 2);
      return DateTime(currentMonth.year, currentMonth.month, day);
    });
  }

  String _getMonthName(int m) => [
    'Sausis', 'Vasaris', 'Kovas', 'Balandis', 'Gegužė', 'Birželis',
    'Liepa', 'Rugpjūtis', 'Rugsėjis', 'Spalis', 'Lapkritis', 'Gruodis'
  ][m - 1];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = context.watch<DiaryProvider>();
    final weekDays = ['Pr', 'An', 'Tr', 'Kt', 'Pn', 'Št', 'Sk'];
    final cells = _getDaysInMonth(provider.currentMonth);

    return Column(
      children: [
        // Month navigation header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => provider.setMonth(
                  DateTime(provider.currentMonth.year, provider.currentMonth.month - 1),
                ),
              ),
              Text(
                '${_getMonthName(provider.currentMonth.month)} ${provider.currentMonth.year}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => provider.setMonth(
                  DateTime(provider.currentMonth.year, provider.currentMonth.month + 1),
                ),
              ),
            ],
          ),
        ),

        // Weekday labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: weekDays
                .map((d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.textColor,
                  ),
                ),
              ),
            ))
                .toList(),
          ),
        ),

        const SizedBox(height: 8),

        // Calendar grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              final date = cells[index];

              // Empty leading cell
              if (date == null) return const SizedBox.shrink();

              final isToday = DateUtils.isSameDay(DateTime.now(), date);
              final isSelected = provider.selectedDay != null &&
                  DateUtils.isSameDay(provider.selectedDay!, date);
              final hasEntry = provider.entriesByDate
                  .containsKey(DateTime(date.year, date.month, date.day));

              // Match statistics: fill with intenseColor if selected,
              // primary if has entry, background2 otherwise
              final bgColor = isSelected
                  ? colors.intenseColor
                  : hasEntry
                  ? colors.primary
                  : colors.background2;

              return GestureDetector(
                onTap: () {
                  provider.setDay(date);
                  final entries = provider.entriesByDate[
                  DateTime(date.year, date.month, date.day)];
                  if (entries == null || entries.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Nėra įrašų")),
                    );
                  } else if (entries.length == 1) {
                    DiaryDialogs.showEntryDialog(context, entries.first);
                  } else {
                    DiaryDialogs.showEntriesList(context, entries);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(color: colors.intenseColor, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontWeight: isToday || isSelected || hasEntry
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? Colors.black : colors.textColor,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Add entry button
        Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton.icon(
            onPressed: () => DefaultTabController.of(context)?.animateTo(0),
            icon: const Icon(Icons.add),
            label: const Text("Pridėti naują įrašą"),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.intenseColor,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}