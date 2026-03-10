import 'dart:math';
import 'package:flutter/material.dart';
import '../data/models/pet_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/pet_repository.dart';
import '../data/repositories/user_repository.dart';

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
  Set<String> _ownedPetIds = {};
  bool _isLoading = true;
  String? _error;

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
      final results = await Future.wait([
        _petRepository.getAllPets(),
        _userRepository.getUser(widget.userId),
      ]);

      final pets = results[0] as List<PetModel>;
      final user = results[1] as UserModel?;

      setState(() {
        _allPets = pets;
        _ownedPetIds = user?.ownedPetIds.toSet() ?? {};
        _isLoading = false;
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kolekcija',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.yellow,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: sortedEntries.map((entry) {
            return _RaritySection(
              rarity: entry.key,
              pets: entry.value,
              ownedPetIds: _ownedPetIds,
            );
          }).toList(),
        ),
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

Color _rarityBackColor(String rarity) {
  switch (rarity) {
    case 'Rare':
      return Colors.blue.shade50;
    case 'Epic':
      return Colors.purple.shade50;
    case 'Legendary':
      return Colors.orange.shade50;
    default:
      return Colors.grey.shade50;
  }
}

class _RaritySection extends StatelessWidget {
  final String rarity;
  final List<PetModel> pets;
  final Set<String> ownedPetIds;

  const _RaritySection({
    required this.rarity,
    required this.pets,
    required this.ownedPetIds,
  });

  @override
  Widget build(BuildContext context) {
    final color = _rarityColor(rarity);
    final ownedCount =
        ownedPetIds.intersection(pets.map((p) => p.id).toSet()).length;

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
            final isOwned = ownedPetIds.contains(pet.id);
            return _FlipPetCard(
              pet: pet,
              isOwned: isOwned,
              rarityColor: color,
              rarityBackColor: _rarityBackColor(rarity),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}


class _FlipPetCard extends StatefulWidget {
  final PetModel pet;
  final bool isOwned;
  final Color rarityColor;
  final Color rarityBackColor;

  const _FlipPetCard({
    required this.pet,
    required this.isOwned,
    required this.rarityColor,
    required this.rarityBackColor,
  });

  @override
  State<_FlipPetCard> createState() => _FlipPetCardState();
}

class _FlipPetCardState extends State<_FlipPetCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final showBack = _animation.value >= 0.5;
          final angle = showBack
              ? (1 - _animation.value) * pi
              : _animation.value * pi;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: showBack
                ? _CardBack(
              pet: widget.pet,
              isOwned: widget.isOwned,
              rarityColor: widget.rarityColor,
              rarityBackColor: widget.rarityBackColor,
            )
                : _CardFront(
              pet: widget.pet,
              isOwned: widget.isOwned,
              rarityColor: widget.rarityColor,
            ),
          );
        },
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  final PetModel pet;
  final bool isOwned;
  final Color rarityColor;

  const _CardFront({
    required this.pet,
    required this.isOwned,
    required this.rarityColor,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = pet.images['collection'] ??
        pet.images.values.firstOrNull ??
        '';

    return Container(
      decoration: BoxDecoration(
        color: isOwned ? Colors.white : Colors.grey.shade100,
        border: Border.all(
          color: isOwned ? rarityColor : Colors.grey.shade300,
          width: isOwned ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isOwned
            ? [
          BoxShadow(
            color: rarityColor.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            // Pet image
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
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.pets,
                          size: 40, color: Colors.grey.shade400),
                )
                    : Icon(Icons.pets,
                    size: 40, color: Colors.grey.shade400),
              ),
            ),
            // Lock badge for unowned
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
            // Tap hint
            Positioned(
              bottom: 5,
              right: 5,
              child: Icon(
                Icons.info_outline,
                size: 14,
                color: isOwned
                    ? rarityColor.withValues(alpha: 0.85)
                    : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card back — shows name + lore
// ---------------------------------------------------------------------------

class _CardBack extends StatelessWidget {
  final PetModel pet;
  final bool isOwned;
  final Color rarityColor;
  final Color rarityBackColor;

  const _CardBack({
    required this.pet,
    required this.isOwned,
    required this.rarityColor,
    required this.rarityBackColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isOwned ? rarityBackColor : Colors.grey.shade100,
        border: Border.all(
          color: isOwned ? rarityColor : Colors.grey.shade300,
          width: isOwned ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isOwned
            ? [
          BoxShadow(
            color: rarityColor.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Rarity dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOwned ? rarityColor : Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 5),
          // Pet name
          Text(
            isOwned ? pet.name : '???',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isOwned ? Colors.black87 : Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          // Divider
          Container(
            height: 1,
            color: isOwned
                ? rarityColor.withValues(alpha: 0.3)
                : Colors.grey.shade300,
          ),
          const SizedBox(height: 5),
          // Lore
          Expanded(
            child: Text(
              isOwned
                  ? pet.lore
                  : 'Unlock this pet to reveal its secrets...',
              style: TextStyle(
                fontSize: 9,
                color: isOwned ? Colors.black54 : Colors.grey.shade400,
                fontStyle: FontStyle.italic,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.fade,
            ),
          ),
        ],
      ),
    );
  }
}