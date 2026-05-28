import 'dart:math';
import 'package:flutter/material.dart';
import '../data/models/pet_model.dart';
import '../data/models/user_model.dart';
import '../data/models/user_pet_progress.dart';
import '../data/repositories/pet_repository.dart';
import '../data/repositories/user_repository.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

class CollectionPage extends StatefulWidget {
  final String userId;
  const CollectionPage({super.key, required this.userId});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  final PetRepository _petRepository = PetRepository();
  final UserRepository _userRepository = UserRepository();

  List<PetModel> _allPets = [];
  Map<String, UserPetProgress> _ownedPets = {};
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _userSubscription;
  String? _equippedPetId;

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pets = await _petRepository.getAllPets();
      setState(() {
        _allPets = pets;
        _isLoading = false;
      });

      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .snapshots()
          .listen((doc) {
        if (!mounted) return;
        if (doc.exists) {
          final user = UserModel.fromMap(doc.id, doc.data()!);
          setState(() {
            _ownedPets = user.ownedPets;
            _equippedPetId = user.equippedPetId;
          });
        }
      });

    } catch (e) {
      setState(() {
        _error = 'Failed to load pets: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {


    if (_isLoading) {
      return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: CircularProgressIndicator(),
          ));
    }




    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }



    const rarityOrder = ['Common', 'Rare', 'Epic', 'Legendary'];

    final Map<String, List<PetModel>> petsByRarity = {};
    for (final pet in _allPets) {
      petsByRarity.putIfAbsent(pet.rarity, () => []).add(pet);
    }

    final sortedEntries = rarityOrder
        .where((r) => petsByRarity.containsKey(r))
        .map((r) => MapEntry(r, petsByRarity[r]!))
        .toList();


    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sortedEntries.map((entry) {
          return _RaritySection(
            rarity: entry.key,
            pets: entry.value,
            ownedPets: _ownedPets,
            userId: widget.userId,
            userRepository: _userRepository,
            equippedPetId: _equippedPetId,
          );
        }).toList(),
      ),
    );
  }
}

Color _rarityColor(String rarity) {
  switch (rarity) {
    case 'Rare':
      return Colors.blue.shade300;
    case 'Epic':
      return Colors.purple.shade400;
    case 'Legendary':
      return Colors.orange.shade400;
    default:
      return Colors.grey.shade400;
  }
}



class _RaritySection extends StatelessWidget {
  final String? equippedPetId;
  final String rarity;
  final List<PetModel> pets;
  final Map<String, UserPetProgress> ownedPets;
  final String userId;
  final UserRepository userRepository;

  const _RaritySection({
    required this.rarity,
    required this.pets,
    required this.ownedPets,
    required this.userId,
    required this.userRepository,
    this.equippedPetId,
  });

  @override
  Widget build(BuildContext context) {
    final color = _rarityColor(rarity);
    final ownedIds = ownedPets.keys.toSet();

    final ownedCount =
        ownedIds.intersection(pets.map((p) => p.id).toSet()).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              rarity,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '($ownedCount/${pets.length})',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pets.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            final pet = pets[index];
            final userPet = ownedPets[pet.id];
            final isOwned = userPet != null;


            return _PetCard(
              pet: pet,
              userPet: userPet,
              isOwned: isOwned,
              rarityColor: color,
              rarityBackColor: Colors.white,
              userId: userId,
              userRepository: userRepository,
              equippedPetId: equippedPetId,
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _PetCard extends StatelessWidget {
  final PetModel pet;
  final UserPetProgress? userPet;
  final bool isOwned;
  final Color rarityColor;
  final Color rarityBackColor;
  final String userId;
  final UserRepository userRepository;
  final String? equippedPetId;

  const _PetCard({
    required this.pet,
    required this.userPet,
    required this.isOwned,
    required this.rarityColor,
    required this.rarityBackColor,
    required this.userId,
    required this.userRepository,
    this.equippedPetId,
  });

  void _openPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PetDetailSheet(
        pet: pet,
        userPet: userPet,
        isOwned: isOwned,
        rarityColor: rarityColor,
        rarityBackColor: rarityBackColor,
        userId: userId,
        userRepository: userRepository,
        equippedPetId: equippedPetId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final duplicateCount = userPet?.duplicateCount ?? 0;

    final imageKey = context.colors.petImageKey;

    final imageUrl = pet.images[imageKey] ??
        pet.images.values.firstOrNull ??
        '';

    return GestureDetector(
      onTap: () => _openPopup(context),
      child: Container(
        decoration: BoxDecoration(
          color: colors.background2,
          border: Border.all(
            color: rarityColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Positioned.fill(
                child: ColorFiltered(
                  colorFilter: isOwned
                      ? const ColorFilter.mode(
                      Colors.transparent, BlendMode.dst)
                      : const ColorFilter.matrix(<double>[
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0,      0,      0,      1, 0,
                  ]),
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                    const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) =>
                        Icon(Icons.pets,
                            size: 40,
                            color: colors.background2),
                  )
                      : Icon(Icons.pets,
                      size: 40, color: colors.background2),
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
                    child:
                    const Icon(Icons.lock, size: 12, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PetDetailSheet extends StatefulWidget {
  final PetModel pet;
  final UserPetProgress? userPet;
  final bool isOwned;
  final Color rarityColor;
  final Color rarityBackColor;
  final String userId;
  final UserRepository userRepository;
  final String? equippedPetId;

  const _PetDetailSheet({
    required this.pet,
    required this.userPet,
    required this.isOwned,
    required this.rarityColor,
    required this.rarityBackColor,
    required this.userId,
    required this.userRepository,
    this.equippedPetId,
  });

  @override
  State<_PetDetailSheet> createState() => _PetDetailSheetState();
}

class _PetDetailSheetState extends State<_PetDetailSheet> {
  bool _isEquipping = false;

  Future<void> _equip() async {
    setState(() => _isEquipping = true);
    try {
      await widget.userRepository.equipPet(widget.userId, widget.pet.id);

      switch (widget.pet.name) {
        case 'Cat':
          SoundService.playCat();
          break;
        case 'Chicken':
          SoundService.playCock();
          break;
        case 'Mouse':
          SoundService.playMouse();
          break;
        case 'Worm':
          SoundService.playWorm();
          break;
        default:
          break;
      }



      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.pet.name} equipped!'),
            backgroundColor: widget.rarityColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to equip pet: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isEquipping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final duplicateCount = widget.userPet?.duplicateCount ?? 0;

    final imageKey = context.colors.petImageKey;

    final imageUrl = widget.pet.images[imageKey] ??
        widget.pet.images.values.firstOrNull ??
        '';

    final screenHeight = MediaQuery.of(context).size.height;

    String _buildLore(Map<String, dynamic> lore, int currentLevel) {
      final parts = <String>[];
      for (int i = 1; i <= currentLevel; i++) {
        final part = lore['level_$i'];
        if (part != null) parts.add(part);
      }
      return parts.isEmpty ? 'No lore available.' : parts.join('\n\n');
    }

    return Container(
      height: screenHeight * 0.75,
      decoration: BoxDecoration(
        color: colors.background2,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: widget.rarityColor,
            width: 3,
          ),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.rarityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: colors.background2,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: widget.rarityColor,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.isOwned
                              ? widget.rarityColor.withValues(alpha: 0.2)
                              : colors.textColor.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: ColorFiltered(
                        colorFilter: widget.isOwned
                            ? const ColorFilter.mode(
                            Colors.transparent, BlendMode.dst)
                            : const ColorFilter.matrix(<double>[
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0,      0,      0,      1, 0,
                        ]),
                        child: imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                          const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.pets,
                                  size: 40,
                                  color: Colors.grey.shade400),
                        )
                            : Icon(Icons.pets,
                            size: 60, color: Colors.grey.shade400),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    widget.isOwned ? widget.pet.name : '???',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: widget.isOwned ? colors.textColor : colors.appBarUnpickedColor,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 6),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.isOwned
                          ? widget.rarityColor.withValues(alpha: 0.15)
                          : colors.background2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.rarityColor,
                      ),
                    ),
                    child: Text(
                      widget.pet.rarity,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.rarityColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (widget.isOwned && widget.userPet != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatChip(
                          label: 'Level',
                          value: '${widget.userPet!.level}',
                          color: widget.rarityColor,
                        ),
                        const SizedBox(width: 12),
                        _StatChip(
                          label: 'XP',
                          value: '${widget.userPet!.xp}',
                          color: widget.rarityColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  Divider(color: colors.appBarUnpickedColor.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.isOwned ? 'Lore' : 'Lore (Locked)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.isOwned ? colors.textColor : colors.appBarUnpickedColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!widget.isOwned)
                    Text(
                      'Unlock this pet to reveal its secrets...',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.appBarUnpickedColor,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.left,
                    )
                  else if (widget.userPet != null)
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.appBarUnpickedColor,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                        children: [
                          if (widget.userPet!.level > 1)
                            TextSpan(
                              text: _buildLore(widget.pet.lore, widget.userPet!.level - 1) + '\n\n',
                            ),
                          TextSpan(
                            text: widget.pet.lore['level_${widget.userPet!.level}'] ?? '',
                            style: TextStyle(
                              color: colors.textColor,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 28),

                  if (widget.isOwned)
                    widget.equippedPetId == widget.pet.id
                        ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: widget.rarityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.rarityColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle,
                              size: 18,
                              color: widget.rarityColor.withValues(alpha: 0.7)),
                          const SizedBox(width: 8),
                          Text(
                            'Equipped',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: widget.rarityColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                        : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isEquipping ? null : _equip,
                        icon: _isEquipping
                            ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: colors.background2
                          ),
                        )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(_isEquipping ? 'Equipping...' : 'Equip'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.rarityColor,
                          foregroundColor: colors.background,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }


}
