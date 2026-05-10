import 'dart:math';
import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/models/pet_model.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/pet_repository.dart';
import "package:cached_network_image/cached_network_image.dart";
import '../data/repositories/quote_repository.dart';

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
  List<String> _quotes =[];
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

  @override
  void dispose() {
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(UserModel?, PetModel?)>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text("User not found")),
          );
        }

        final (user, pet) = snapshot.data!;
        if (user == null) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text("User not found")),
          );
        }

        final petProgress = user.ownedPets[user.equippedPetId];
        final userXp = user.xp;
        final userLevel = user.level;
        final nextLevelXp = 100;
        final progress = nextLevelXp == 0 ? 0.0 : userXp / nextLevelXp;

        final petName = pet?.name ?? "No Pet";
        final petRarity = pet?.rarity ?? "Common";
        final duplicateCount = petProgress?.duplicateCount ?? 0;
        final imageKey = duplicateCount >= 10 ? 'Skin' : 'collection';
        
        final imageUrl = pet?.images[imageKey] ??
            pet?.images.values.firstOrNull ??
            '';
            
        final streak = user.streak; 

        
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors:[Color(0xfff5e1), Color(0xfff5e1)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors:[Color(0xFFF6F8FF), Color(0xFFE9EEFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children:[
                const SizedBox(height: 32),

                Text(
                  petName,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2D3142),
                  ),
                ),

                const SizedBox(height: 24),

                
                SizedBox(
                  height: 290,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children:[
                      Positioned(
                        bottom: 0,
                        child: AnimatedBuilder(
                          animation: _floatingAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _floatingAnimation.value),
                              child: child,
                            );
                          },
                          child: AnimatedScale(
                            scale: _avatarScale,
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeOutCubic,
                            child: GestureDetector(
                              onTapDown: (_) =>
                                  setState(() => _avatarScale = 0.92),
                              onTapUp: (_) {
                                setState(() => _avatarScale = 1.0);
                                if (_bubbleVisible) {
                                  _dismissBubble();
                                } else {
                                  _onAvatarTap(petName);
                                }
                              },
                              onTapCancel: () =>
                                  setState(() => _avatarScale = 1.0),
                              child: Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow:[
                                    BoxShadow(
                                      color: Colors.purpleAccent.withOpacity(0.4),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                      offset: const Offset(0, 10),
                                    )
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children:[
                                    Container(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.purpleAccent,
                                            Colors.deepPurple
                                          ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: ClipOval(
                                        child: imageUrl.isEmpty
                                            ? const Icon(Icons.pets, size: 120)
                                            : CachedNetworkImage( 
                                                imageUrl: imageUrl,
                                                fit: BoxFit.cover,
                                                width: 220,
                                                height: 220,
                                                memCacheWidth: 512,
                                                memCacheHeight: 512,
                                                placeholder: (context, url) =>
                                                    const Center(
                                                      child: CircularProgressIndicator(strokeWidth: 2),
                                                    ),
                                                errorWidget: (context, url, error) =>
                                                    const Icon(Icons.pets, size: 120),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // speech bubble
                      Positioned(
                        top: 0,
                        child: AnimatedOpacity(
                          opacity: _bubbleVisible ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: AnimatedSlide(
                            offset: _bubbleVisible
                                ? Offset.zero
                                : const Offset(0, 0.08),
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            child: IgnorePointer(
                              ignoring: !_bubbleVisible,
                              child: _SpeechBubble(text: _currentQuote),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _quotesLoaded && _quotes.isNotEmpty
                      ? Text(
                    _bubbleVisible
                        ? 'Paspausk, kad paslėptum'
                        : 'Paspausk motyvacijai!',
                    key: ValueKey(_bubbleVisible),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.purple.withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: Text(
                    petRarity,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Colors.purple,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow:[
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      children:[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children:[
                            Text("Level $userLevel",
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2D3142))),
                            Text("$userXp / $nextLevelXp XP",
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: progress),
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Stack(
                              children:[
                                Container(
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: value,
                                  child: Container(
                                    height: 18,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: const LinearGradient(
                                        colors:[
                                          Colors.orangeAccent,
                                          Colors.deepOrange
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children:[
                      Expanded(
                        child: _StatCard(
                          title: "Daily Streak",
                          value: "$streak d.",
                          icon: Icons.local_fire_department_rounded,
                          iconColor: Colors.deepOrange,
                          bgColor: Colors.deepOrange.shade50,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: "Total XP",
                          value: userXp.toString(),
                          icon: Icons.star_rounded,
                          iconColor: Colors.blue,
                          bgColor: Colors.blue.shade50,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}



class _SpeechBubble extends StatelessWidget {
  final String text;

  const _SpeechBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children:[
        Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow:[
              BoxShadow(
                color: Colors.purple.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: Colors.purple.withOpacity(0.18),
              width: 1,
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3142),
              height: 1.45,
            ),
          ),
        ),

        CustomPaint(
          size: const Size(20, 10),
          painter: _BubbleTailPainter(),
        ),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.purple.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow:[
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children:[
          Container(
            padding: const EdgeInsets.all(12),
            decoration:
            BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, size: 28, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: Color(0xFF2D3142))),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey)),
        ],
      ),
    );
  }
}