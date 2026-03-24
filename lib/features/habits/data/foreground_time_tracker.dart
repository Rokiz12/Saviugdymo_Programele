
import 'dart:async';
import 'package:flutter/widgets.dart';


class ForegroundTimeTracker with WidgetsBindingObserver {
  final Duration threshold;
  final void Function(DateTime dateUtc) onReached;
  final DateTime Function() now;
  DateTime _currentDayUtc = _toUtcMidnight(DateTime.now());
  Duration _accumulatedToday = Duration.zero;

  Timer? _pendingTimer;
  DateTime? _sessionStart;

  bool _reachedToday = false;

  ForegroundTimeTracker({
    required this.threshold,
    required this.onReached,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  void start() {
    WidgetsBinding.instance.addObserver(this);

    _handleResume();
  }

  /// Stop observing and clean up.
  void stop() {
    _cancelTimer();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _handleResume();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _handlePauseLike();
        break;
      case AppLifecycleState.detached:
        _handlePauseLike();
        break;
    }
  }

  void _handleResume() {
    _rolloverIfNewDay();

    if (_reachedToday) return;

    _sessionStart = now();

    final remaining = threshold - _accumulatedToday;
    if (remaining.isPositive) {
      _pendingTimer = Timer(remaining, () {
        _reachedToday = true;
        onReached(_currentDayUtc);
      });
    } else {
      _reachedToday = true;
      onReached(_currentDayUtc);
    }
  }

  void _handlePauseLike() {
    _cancelTimer();

    if (_sessionStart != null) {
      final end = now();
      final delta = end.difference(_sessionStart!);
      _sessionStart = null;

      _accumulatedToday += delta;

      if (!_reachedToday && _accumulatedToday >= threshold) {
        _reachedToday = true;
        onReached(_currentDayUtc);
      }
    }
  }

  void _cancelTimer() {
    _pendingTimer?.cancel();
    _pendingTimer = null;
  }

  void _rolloverIfNewDay() {
    final todayUtc = _toUtcMidnight(now());
    if (todayUtc.isAfter(_currentDayUtc)) {
      _currentDayUtc = todayUtc;
      _accumulatedToday = Duration.zero;
      _reachedToday = false;
      _cancelTimer();
    }
  }

  static DateTime _toUtcMidnight(DateTime d) => DateTime.utc(d.year, d.month, d.day);
}

extension on Duration {
  bool get isPositive => inMilliseconds > 0;
}
