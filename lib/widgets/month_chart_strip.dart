import 'package:flutter/material.dart';
import 'dart:math';
import '../theme/app_theme.dart';

class MonthChartStrip extends StatefulWidget {
  final DateTime initialMonth;
  final DateTime selectedMonth;          // NEW: drives the strip externally
  final ValueChanged<DateTime> onMonthChanged;
  final Map<DateTime, List<double>> dataByMonth;
  final double maxHeightFraction;
  final double verticalOffset;

  const MonthChartStrip({
    super.key,
    required this.initialMonth,
    required this.selectedMonth,         // NEW
    required this.onMonthChanged,
    required this.dataByMonth,
    this.maxHeightFraction = 0.9,
    this.verticalOffset = -0.15,
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

  // NEW: when parent changes selectedMonth (via chevrons), sync the strip
  @override
  void didUpdateWidget(covariant MonthChartStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMonth != widget.selectedMonth) {
      final newIndex = _months.indexWhere(
            (m) => m.year == widget.selectedMonth.year &&
            m.month == widget.selectedMonth.month,
      );
      if (newIndex >= 0 && newIndex != _page.round()) {
        _controller.animateToPage(
          newIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 110,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _MonthChartPainter(
                months: _months,
                dataByMonth: widget.dataByMonth,
                activePage: _page,
                maxHeightFraction: widget.maxHeightFraction,
                verticalOffset: widget.verticalOffset,
              ),
            ),
          ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? colors.intenseColor : colors.background2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _label(month),
                    style: TextStyle(
                      color: colors.textColor,
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
  final double maxHeightFraction;
  final double verticalOffset;

  _MonthChartPainter({
    required this.months,
    required this.dataByMonth,
    required this.activePage,
    required this.maxHeightFraction,
    required this.verticalOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centre = size.height * (0.5 + verticalOffset);
    final double halfSwing = size.height * maxHeightFraction * 0.5;

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
        final y = centre + halfSwing * (1 - 2 * amp);
        allPoints.add(Offset(x, y));
        globalIndex++;
      }
    }

    if (allPoints.length < 2) return;

    final path = Path();
    path.moveTo(allPoints[0].dx, allPoints[0].dy);
    for (int i = 1; i < allPoints.length; i++) {
      final prev = allPoints[i - 1];
      final curr = allPoints[i];
      final cx = (prev.dx + curr.dx) / 2;
      path.cubicTo(cx, prev.dy, cx, curr.dy, curr.dx, curr.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFD4537E).withOpacity(0.18)
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFD4537E)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final int activeMonthIdx = activePage.round().clamp(0, months.length - 1);
    int gi = 0;
    for (int mi = 0; mi < months.length; mi++) {
      final key = DateTime(months[mi].year, months[mi].month);
      final values = dataByMonth[key];
      if (values == null) continue;
      for (int vi = 0; vi < values.length; vi++) {
        final pt = allPoints[gi];
        if (mi == activeMonthIdx) {
          canvas.drawCircle(pt, 5, Paint()..color = const Color(0xFFD4537E));
          canvas.drawCircle(
            pt, 5,
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
      old.activePage != activePage ||
          old.dataByMonth != dataByMonth ||
          old.maxHeightFraction != maxHeightFraction ||
          old.verticalOffset != verticalOffset;
}