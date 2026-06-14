import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../data/models/user_model.dart';
import '../data/models/pet_model.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/pet_repository.dart';
import "package:cached_network_image/cached_network_image.dart";
import '../data/repositories/quote_repository.dart';
import '../theme/app_theme.dart';
import '../data/models/user_pet_progress.dart';
import '../services/language_notifier.dart';

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

  StreamSubscription? _userSubscription;
  UserModel? _user;

  PetModel? _cachedPet;
  String _cachedPetId = '';
  Future<PetModel?>? _petFuture;

  bool _isLoading = true;

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
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _startListening();
    _loadQuotes();
  }

  void _startListening() {
    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .snapshots()
        .listen((doc) {
      if (!mounted) return;
      if (doc.exists) {
        final user = UserModel.fromMap(doc.id, doc.data()!);

        if (user.equippedPetId != _cachedPetId) {
          _cachedPetId = user.equippedPetId;
          _petFuture = user.equippedPetId.isNotEmpty
              ? _petRepository.getPet(user.equippedPetId)
              : Future.value(null);
        }

        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    });
  }

  void _openWardrobe(PetModel pet, String equippedPetId) {
    final colors = context.colors;
    final lang = context.read<LanguageNotifier>();

    final allSkins = pet.images.keys
        .where((k) => k.startsWith('skin_'))
        .toList()
      ..sort();

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final petProgress = _user?.ownedPets[equippedPetId];
            final unlockedSkins = petProgress?.unlockedSkins ?? [];
            final equippedSkin = petProgress?.equippedSkinKey ?? '';

            Future<void> tapSkin(String skinKey) async {
              await _userRepository.equipSkin(widget.userId, equippedPetId, skinKey);
              setSheetState(() {});
              setState(() {});
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.appBarUnpickedColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    lang.t('wardrobe'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: colors.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: allSkins.length + 1,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        final isEquipped = equippedSkin.isEmpty;
                        return GestureDetector(
                          onTap: () => tapSkin(''),
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: colors.background,
                                  borderRadius: BorderRadius.circular(14),
                                  border: isEquipped
                                      ? Border.all(color: colors.intenseColor, width: 2)
                                      : null,
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Center(
                                  child: Icon(
                                    Icons.disabled_visible,
                                    size: 36,
                                    color: colors.appBarUnpickedColor,
                                  ),
                                ),
                              ),
                              if (isEquipped)
                                Positioned(
                                  top: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: colors.intenseColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }

                      final skinKey = allSkins[i - 1];
                      final isOwned = unlockedSkins.contains(skinKey);
                      final isEquipped = equippedSkin == skinKey;
                      final skinUrl = pet.images[skinKey] ?? '';

                      return GestureDetector(
                        onTap: isOwned ? () => tapSkin(skinKey) : null,
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: colors.background,
                                borderRadius: BorderRadius.circular(14),
                                border: isEquipped
                                    ? Border.all(color: colors.intenseColor, width: 2)
                                    : null,
                              ),
                              padding: const EdgeInsets.all(8),
                              child: skinUrl.isEmpty
                                  ? const Icon(Icons.pets)
                                  : CachedNetworkImage(
                                imageUrl: skinUrl,
                                fit: BoxFit.contain,
                                placeholder: (_, __) => const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                errorWidget: (_, __, ___) => const Icon(Icons.pets),
                              ),
                            ),
                            if (!isOwned)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.lock, size: 12, color: Colors.white),
                                ),
                              ),
                            if (isEquipped)
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: colors.intenseColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

  @override
  void dispose() {
    _userSubscription?.cancel();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lang = context.watch<LanguageNotifier>();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = _user;
    if (user == null) {
      return Center(child: Text(lang.t('user_not_found')));
    }

    final userXp = user.xp;
    final userLevel = user.level;
    const nextLevelXp = 100;
    final streak = user.streak;

    return FutureBuilder<PetModel?>(
      future: _petFuture,
      builder: (context, petSnapshot) {
        if (petSnapshot.hasData) {
          _cachedPet = petSnapshot.data;
        }
        final pet = _cachedPet;

        final petProgress = user.ownedPets[user.equippedPetId];
        final petName = pet?.name ?? lang.t('no_pet');
        final petRarity = pet?.rarity ?? lang.t('common');
        final duplicateCount = petProgress?.duplicateCount ?? 0;
        final equippedSkin = petProgress?.equippedSkinKey ?? '';
        final themeKey = context.colors.petImageKey;
        final imageUrl = equippedSkin.isNotEmpty
            ? (pet?.images[equippedSkin] ?? pet?.images[themeKey] ?? '')
            : (pet?.images[themeKey] ?? pet?.images.values.firstOrNull ?? '');

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // Pet image card
              Container(
                decoration: BoxDecoration(
                  color: colors.background2,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                child: Column(
                  children: [
                    // Speech bubble
                    AnimatedOpacity(
                      opacity: _bubbleVisible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: AnimatedSlide(
                        offset: _bubbleVisible ? Offset.zero : const Offset(0, 0.08),
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
                      builder: (context, child) => Transform.translate(
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
                            _bubbleVisible ? _dismissBubble() : _onAvatarTap(petName);
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
                              placeholder: (_, __) => const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
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
                      _bubbleVisible ? lang.t('tap_to_hide') : lang.t('tap_for_motivation'),
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

              // Name + level card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                            '"$petRarity"',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.appBarUnpickedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: colors.background2,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.intenseColor, width: 2),
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
                            lang.t('level'),
                            style: TextStyle(fontSize: 14, color: colors.intenseColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Stats + Wardrobe card
              Row(
                children: [
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
                          _StatRow(lang.t('days_streak'), '$streak', colors),
                          const SizedBox(height: 8),
                          _StatRow(lang.t('experience_points'), '$userXp | $nextLevelXp', colors),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      if (pet != null) _openWardrobe(pet, user.equippedPetId);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        lang.t('wardrobe'),
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
        Text(label, style: TextStyle(fontSize: 13, color: colors.textColor)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.textColor)),
      ],
    );
  }
}