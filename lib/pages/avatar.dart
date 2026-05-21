import 'dart:math';
import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/models/pet_model.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/pet_repository.dart';
import "package:cached_network_image/cached_network_image.dart";
import '../data/repositories/quote_repository.dart';
import '../theme/app_theme.dart';

class AvatarPage extends StatefulWidget {
  final String userId;
  const AvatarPage({super.key, required this.userId});

  @override
  State<AvatarPage> createState() => _AvatarPageState();
}

class _AvatarPageState extends State<AvatarPage>
    with SingleTickerProviderStateMixin {
  final UserRepository _userRepository = UserRepository();
  final PetRepository _petRepository = PetRepository();
  final QuoteRepository _quoteRepository = QuoteRepository();

  late AnimationController _floatingController;
  late Animation<double> _floatingAnimation;
  double _avatarScale = 1.0;

  late Future<(UserModel?, PetModel?)> _dataFuture;

  // speech bubble state
  List<String> _quotes = [];
  String _currentQuote = '';
  bool _bubbleVisible = false;
  bool _quotesLoaded = false;

  @override
  void initState() {
    super.initState();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )
      ..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _dataFuture = _fetchData();
    _loadQuotes();
  }

  Future<(UserModel?, PetModel?)> _fetchData() async {
    final user = await _userRepository.getUser(widget.userId);
    if (user == null) return (null, null);

    PetModel? pet;
    if (user.equippedPetId.isNotEmpty) {
      pet = await _petRepository.getPet(user.equippedPetId);
    }

    return (user, pet);
  }

  Future<void> _loadQuotes() async {
    final quotes = await _quoteRepository.getQuotes();
    if (mounted) {
      setState(() {
        _quotes = quotes;
        _quotesLoaded = true;
      });
    }
  }

  void _onAvatarTap(String petName) {
    if (!_quotesLoaded || _quotes.isEmpty) return;

    // pick random quote
    String newQuote = _currentQuote;
    if (_quotes.length > 1) {
      while (newQuote == _currentQuote) {
        newQuote = _quotes[Random().nextInt(_quotes.length)];
      }
    } else {
      newQuote = _quotes.first;
    }

    setState(() {
      _currentQuote = newQuote;
      _bubbleVisible = true;
    });
  }

  void _dismissBubble() {
    setState(() {
      _bubbleVisible = false;
    });
  }

  Future<void> refreshData() async {
    setState(() {
      _dataFuture = _fetchData();
    });
  }

  @override
  void dispose() {
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return FutureBuilder<(UserModel?, PetModel?)>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final (user, pet) = snapshot.data ?? (null, null);
        if (user == null) {
          return const Center(child: Text("User not found"));
        }

        final petProgress = user.ownedPets[user.equippedPetId];
        final userXp = user.xp;
        final userLevel = user.level;
        const nextLevelXp = 100;
        final petName = pet?.name ?? "No Pet";
        final petRarity = pet?.rarity ?? "Common";
        final duplicateCount = petProgress?.duplicateCount ?? 0;
        final imageKey = duplicateCount >= 10 ? 'Skin' : 'collection';
        final imageUrl = pet?.images[imageKey] ??
            pet?.images.values.firstOrNull ?? '';
        final streak = user.streak;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Pet image card ──────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: colors.background2,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                    vertical: 24, horizontal: 20),
                child: Column(
                  children: [
                    // Speech bubble
                    AnimatedOpacity(
                      opacity: _bubbleVisible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: AnimatedSlide(
                        offset: _bubbleVisible ? Offset.zero : const Offset(
                            0, 0.08),
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        child: IgnorePointer(
                          ignoring: !_bubbleVisible,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 46, vertical: 22),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              _currentQuote,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: colors.textColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Pet image
                    AnimatedBuilder(
                      animation: _floatingAnimation,
                      builder: (context, child) =>
                          Transform.translate(
                            offset: Offset(0, _floatingAnimation.value),
                            child: child,
                          ),
                      child: AnimatedScale(
                        scale: _avatarScale,
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOutCubic,
                        child: GestureDetector(
                          onTapDown: (_) => setState(() => _avatarScale = 0.92),
                          onTapUp: (_) {
                            setState(() => _avatarScale = 1.0);
                            _bubbleVisible ? _dismissBubble() : _onAvatarTap(
                                petName);
                          },
                          onTapCancel: () => setState(() => _avatarScale = 1.0),
                          child: SizedBox(
                            width: 180,
                            height: 180,
                            child: imageUrl.isEmpty
                                ? const Icon(Icons.pets, size: 100)
                                : CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.contain,
                              memCacheWidth: 512,
                              memCacheHeight: 512,
                              placeholder: (_, __) =>
                              const Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                              errorWidget: (_, __, ___) =>
                              const Icon(Icons.pets, size: 100),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Text(
                      _bubbleVisible
                          ? 'Paspausk, kad paslėptum'
                          : 'Paspausk motyvacijai!',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.appBarUnpickedColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ── Name + level card ────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: colors.background2,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            petName,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: colors.textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '"${petRarity}"',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.appBarUnpickedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Level circle
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: colors.background2,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: colors.intenseColor, width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$userLevel',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: colors.intenseColor,
                              height: 1,
                            ),
                          ),
                          Text(
                            'Lygis',
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.intenseColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ── Stats + Apranga card ─────────────────────────────────
        Row(
        children: [
        // Stats card
        Expanded(
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
        color: colors.background2,
        borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        _StatRow('Dienų streakas', '$streak', colors),
        const SizedBox(height: 8),
        _StatRow('Patirties taškai', '$userXp | $nextLevelXp', colors),
        ],
        ),
        ),
        ),

        const SizedBox(width: 10),

        // Apranga card
        GestureDetector(
        onTap: () {
        // TODO: open wardrobe
        },
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
        'Apranga',
        style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colors.textColor,
        ),
        ),
        ),
        ),
        ],
        ),
            ],
          ),
        );
      },
    );

  }

  Widget _StatRow(String label, String value, AppColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 13, color: colors.textColor)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.textColor)),
      ],
    );
  }


}