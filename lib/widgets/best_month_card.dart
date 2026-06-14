import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/language_notifier.dart';

class BestMonthCard extends StatefulWidget {
  final String monthName;
  final double completionRate;
  final int completedDays;
  final int totalDays;
  final int longestStreak;
  final int habitsLogged;
  final double avgRate;
  final int betterThanMonths;
  final int totalMonths;

  const BestMonthCard({
    super.key,
    required this.monthName,
    required this.completionRate,
    required this.completedDays,
    required this.totalDays,
    required this.longestStreak,
    required this.habitsLogged,
    required this.avgRate,
    required this.betterThanMonths,
    required this.totalMonths,
  });

  @override
  State<BestMonthCard> createState() => _BestMonthCardState();
}

class _BestMonthCardState extends State<BestMonthCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    Future.delayed(const Duration(milliseconds: 300), () => _ctrl.forward());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageNotifier>();
    final amber = const Color(0xFFBA7517);
    final amberLight = const Color(0xFFFAEEDA);
    final surface = Theme.of(context).colorScheme.surfaceContainerHighest
        .withOpacity(0.5);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge row
          Row(
            children: [
              Icon(Icons.emoji_events_outlined, size: 15, color: amber),
              const SizedBox(width: 6),
              Text(
                lang.t('best_month'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Month name
          Text(
            widget.monthName,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),

          // Ring + label row
          Row(
            children: [
              AnimatedBuilder(
                animation: _anim,
                builder: (_, __) => SizedBox(
                  width: 96,
                  height: 96,
                  child: CustomPaint(
                    painter: _RingPainter(
                      progress: _anim.value * widget.completionRate,
                      trackColor: surface,
                      fillColor: amber,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(_anim.value * widget.completionRate * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            lang.t('done'),
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface
                                  .withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(widget.completionRate * 100).round()}% ${lang.t('completed')}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lang.t('highest_rate_desc'),
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Theme.of(context).dividerColor.withOpacity(0.15)),
          const SizedBox(height: 16),

          // Stats 2x2 grid
          Row(
            children: [
              Expanded(child: _StatTile(
                icon: Icons.calendar_month_outlined,
                iconColor: const Color(0xFF639922),
                value: '${widget.completedDays} / ${widget.totalDays}',
                label: lang.t('days_completed'),
                surface: surface,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(
                icon: Icons.local_fire_department_outlined,
                iconColor: const Color(0xFFD85A30),
                value: '${widget.longestStreak} ${lang.t('days_streak')}',
                label: lang.t('longest_streak'),
                surface: surface,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatTile(
                icon: Icons.checklist_outlined,
                iconColor: const Color(0xFF378ADD),
                value: '${widget.habitsLogged}',
                label: lang.t('habits_logged'),
                surface: surface,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(
                icon: Icons.track_changes_outlined,
                iconColor: const Color(0xFF7F77DD),
                value: '4 / 4',
                label: lang.t('goals_on_track'),
                surface: surface,
              )),
            ],
          ),
          const SizedBox(height: 20),

          // Progress bar vs average
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${lang.t('vs_monthly_average')} (${(widget.avgRate * 100).round()}%)',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.45),
                ),
              ),
              Text(
                '+${((widget.completionRate - widget.avgRate) * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.65),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: _anim.value * widget.completionRate,
                minHeight: 6,
                backgroundColor: surface,
                valueColor: AlwaysStoppedAnimation(amber),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Compare chip
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                  size: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.4),
                ),
                const SizedBox(width: 5),
                Text(
                  lang.t('better_than'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: amberLight,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${widget.betterThanMonths} ${lang.t('of')} ${widget.totalMonths} ${lang.t('months')}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF854F0B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final Color surface;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color fillColor;

  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 9) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..color = fillColor
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress;
}