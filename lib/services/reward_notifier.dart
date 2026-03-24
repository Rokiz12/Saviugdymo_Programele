import 'package:flutter/material.dart';
import '../data/models/pet_model.dart';

enum RewardType { dailyLogin, levelUp }

class PendingReward {
  final RewardType type;
  final PetModel pet;
  final bool isDuplicate;
  final int? newLevel; // only for levelUp

  PendingReward({
    required this.type,
    required this.pet,
    required this.isDuplicate,
    this.newLevel,
  });
}

class RewardNotifier extends ChangeNotifier {
  final List<PendingReward> _queue = [];

  bool get hasPending => _queue.isNotEmpty;
  PendingReward? get current => _queue.isNotEmpty ? _queue.first : null;

  void enqueue(PendingReward reward) {
    _queue.add(reward);
    notifyListeners();
  }

  void dismiss() {
    if (_queue.isNotEmpty) _queue.removeAt(0);
    notifyListeners();
  }
}