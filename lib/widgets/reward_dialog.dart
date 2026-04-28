import 'package:flutter/material.dart';
import '../services/reward_notifier.dart';
import '../services/sound_service.dart';

class RewardDialog extends StatefulWidget {
  final PendingReward reward;
  final VoidCallback onClaim;

  const RewardDialog({super.key, required this.reward, required this.onClaim});

  @override
  State<RewardDialog> createState() => _RewardDialogState();
}

class _RewardDialogState extends State<RewardDialog>
    with SingleTickerProviderStateMixin {
  bool _revealed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onClaim() {
    SoundService.palyClaimReward();

    setState(() => _revealed = true);
    _controller.forward();
  }

  String get _title => widget.reward.type == RewardType.dailyLogin
      ? 'Daily Reward!'
      : 'Level Up! (Lvl ${widget.reward.newLevel})';

  Color get _rarityColor {
    switch (widget.reward.pet.rarity) {
      case 'Legendary': return const Color(0xFFFFD700);
      case 'Epic':      return const Color(0xFF9B59B6);
      case 'Rare':      return const Color(0xFF3498DB);
      default:          return const Color(0xFF95A5A6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.reward.pet;
    final imageUrl = pet.images['collection'] ??
        pet.images['idle'] ??
        pet.images.values.firstOrNull ?? '';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_title,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Box or revealed pet
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _revealed
                  ? ScaleTransition(
                key: const ValueKey('pet'),
                scale: _scaleAnim,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: _rarityColor, width: 3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: imageUrl.isNotEmpty
                          ? Image.network(imageUrl,
                          width: 120, height: 120, fit: BoxFit.contain)
                          : const Icon(Icons.pets, size: 80),
                    ),
                    const SizedBox(height: 12),
                    Text(pet.name,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _rarityColor)),
                    Text(pet.rarity.toUpperCase(),
                        style: TextStyle(
                            fontSize: 13,
                            color: _rarityColor,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    if (widget.reward.isDuplicate)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Oops! A duplicate!',
                          style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              )
                  : const _LootBoxWidget(key: ValueKey('box')),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _revealed ? widget.onClaim : _onClaim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(_revealed ? 'Awesome!' : 'Claim Reward',
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LootBoxWidget extends StatelessWidget {
  const _LootBoxWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade50, Colors.grey.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.card_giftcard, size: 200, color: Colors.yellow),
    );
  }
}