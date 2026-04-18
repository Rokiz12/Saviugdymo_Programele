import 'package:flutter/material.dart';
import 'dart:math';

class MonthChartStrip extends StatefulWidget {
  final DateTime initialMonth;
  final ValueChanged<DateTime> onMonthChanged;
  final Map<DateTime, List<double>> dataByMonth;

  const MonthChartStrip({
    super.key,
    required this.initialMonth,
    required this.onMonthChanged,
    required this.dataByMonth,
  });

  @override
  State<MonthChartStrip> createState() => _MonthChartStripState();
}

class _MonthChartStripState extends State<MonthChartStrip> {
  late PageController _controller;
  late List<DateTime> _months;
  double _page = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Oldest → newest, left to right (no reverse needed)
    _months = List.generate(12, (i) {
      return DateTime(now.year, now.month - (11 - i));
    });

    final initialIndex = _months.indexWhere(
          (m) => m.year == widget.initialMonth.year &&
          m.month == widget.initialMonth.month,
    );
    final startPage = initialIndex < 0 ? _months.length - 1 : initialIndex;

    _controller = PageController(
      viewportFraction: 0.28,
      initialPage: startPage,
    );
    _page = startPage.toDouble();

    _controller.addListener(() {
      setState(() => _page = _controller.page ?? 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: Stack(
        children: [
          // Line chart behind pills
          Positioned.fill(
            child: CustomPaint(
              painter: _MonthChartPainter(
                months: _months,
                dataByMonth: widget.dataByMonth,
                activePage: _page,
              ),
            ),
          ),
          // Month pill pager
          PageView.builder(
            controller: _controller,
            itemCount: _months.length,
            onPageChanged: (i) => widget.onMonthChanged(_months[i]),
            itemBuilder: (context, index) {
              final month = _months[index];
              final active = (_page.round() == index);
              return Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFFD4537E) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _label(month),
                    style: TextStyle(
                      color: active ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _label(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return m[d.month - 1];
  }
}

class _MonthChartPainter extends CustomPainter {
  final List<DateTime> months;
  final Map<DateTime, List<double>> dataByMonth;
  final double activePage;

  _MonthChartPainter({
    required this.months,
    required this.dataByMonth,
    required this.activePage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Gather all (x, y) points across all months
    final allPoints = <Offset>[];

    int globalIndex = 0;
    int totalPoints = 0;
    for (final m in months) {
      totalPoints += dataByMonth[DateTime(m.year, m.month)]?.length ?? 0;
    }

    for (final month in months) {
      final key = DateTime(month.year, month.month);
      final values = dataByMonth[key];
      if (values == null) continue;
      for (final rawValue in values) {
        final amp = pow(rawValue.clamp(0.0, 1.0), 0.55).toDouble();
        final t = globalIndex / max(1, totalPoints - 1);
        final x = size.width * t;
        final y = size.height * (1 - amp) * 0.85 + size.height * 0.05;
        allPoints.add(Offset(x, y));
        globalIndex++;
      }
    }

    if (allPoints.length < 2) return;

    // Build smooth bezier path
    final path = Path();
    path.moveTo(allPoints[0].dx, allPoints[0].dy);
    for (int i = 1; i < allPoints.length; i++) {
      final prev = allPoints[i - 1];
      final curr = allPoints[i];
      final cx = (prev.dx + curr.dx) / 2;
      path.cubicTo(cx, prev.dy, cx, curr.dy, curr.dx, curr.dy);
    }

    // Glow / thick background stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFD4537E).withOpacity(0.18)
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Main line
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFD4537E)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Dots — larger for active month's points
    final int activeMonthIdx = activePage.round().clamp(0, months.length - 1);
    int gi = 0;
    for (int mi = 0; mi < months.length; mi++) {
      final key = DateTime(months[mi].year, months[mi].month);
      final values = dataByMonth[key];
      if (values == null) continue;
      for (int vi = 0; vi < values.length; vi++) {
        final pt = allPoints[gi];
        final isActive = mi == activeMonthIdx;
        canvas.drawCircle(
          pt,
          isActive ? 5 : 3,
          Paint()..color = const Color(0xFFD4537E).withOpacity(isActive ? 1.0 : 0.5),
        );
        if (isActive) {
          canvas.drawCircle(
            pt,
            5,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }
        gi++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MonthChartPainter old) =>
      old.activePage != activePage || old.dataByMonth != dataByMonth;
}