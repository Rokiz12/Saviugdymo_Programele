import 'package:flutter/material.dart';

class AvatarPage extends StatefulWidget {
  const AvatarPage({super.key});

  @override
  State<AvatarPage> createState() => _AvatarPageState();
}

class _AvatarPageState extends State<AvatarPage> with SingleTickerProviderStateMixin {
  late AnimationController _floatingController;
  late Animation<double> _floatingAnimation;
  
  // State variable to handle the tap scaling effect
  double _avatarScale = 1.0;

  @override
  void initState() {
    super.initState();
    // Gentle floating animation
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(
        parent: _floatingController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mock data
    const String avatarTitle = "Squid";
    const String rarity = "Rare";
    const int level = 4;
    const int xp = 240;
    const int nextLevelXp = 400;
    
    // Stats data
    const int coins = 120;
    const int streak = 6;
    const String totalXp = "3,240";
    const int tasksCompleted = 142;

    final double progress = xp / nextLevelXp;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Avataras",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.yellow,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF6F8FF), Color(0xFFE9EEFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children:[
              const SizedBox(height: 32),

              /// avatar name
              const Text(
                avatarTitle,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2D3142),
                ),
              ),

              const SizedBox(height: 24),

              /// avatar floating animation
              AnimatedBuilder(
                animation: _floatingAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatingAnimation.value),
                    child: child,
                  );
                },
                child: AnimatedScale(
                  scale: _avatarScale,
                  // tap animation
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOutCubic,
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _avatarScale = 0.92),
                    onTapUp: (_) {
                      setState(() => _avatarScale = 1.0);
                      debugPrint("Avatar tapped");
                    },
                    onTapCancel: () => setState(() => _avatarScale = 1.0),
                    
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
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children:[
                          Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Colors.purpleAccent, Colors.deepPurple],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          // avatar image
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: ClipOval(
                              child: Image.network(
                                "https://i.imgur.com/P4oM7W3.png",
                                fit: BoxFit.cover,
                                width: 220,
                                height: 220,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// rarity badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const[
                    Icon(Icons.auto_awesome, color: Colors.purple, size: 20),
                    SizedBox(width: 8),
                    Text(
                      rarity,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.purple,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              /// xp progress
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
                      ),
                    ],
                  ),
                  child: Column(
                    children:[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children:[
                          const Text(
                            "Level 4",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2D3142),
                            ),
                          ),
                          Text(
                            "$xp / $nextLevelXp XP",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      /// animated xp bar
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              return Stack(
                                children:[
                                  Container(
                                    height: 18,
                                    width: constraints.maxWidth,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: const[
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                          blurStyle: BlurStyle.inner,
                                        )
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 18,
                                    width: constraints.maxWidth * value,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: const LinearGradient(
                                        colors:[
                                          Colors.orangeAccent,
                                          Colors.deepOrange,
                                        ],
                                      ),
                                      boxShadow:[
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.5),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
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
                child: Column(
                  children:[
                    // coins and streak row
                    Row(
                      children:[
                        Expanded(
                          child: _StatCard(
                            title: "Coins",
                            value: coins.toString(),
                            icon: Icons.monetization_on_rounded,
                            iconColor: Colors.amber,
                            bgColor: Colors.amber.shade50,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            title: "Streak",
                            value: "$streak d.",
                            icon: Icons.local_fire_department_rounded,
                            iconColor: Colors.deepOrange,
                            bgColor: Colors.deepOrange.shade50,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // total xp and tasks row
                    Row(
                      children:[
                        Expanded(
                          child: _StatCard(
                            title: "Total XP",
                            value: totalXp,
                            icon: Icons.star_rounded,
                            iconColor: Colors.blue,
                            bgColor: Colors.blue.shade50,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            title: "Tasks",
                            value: tasksCompleted.toString(),
                            icon: Icons.fact_check_rounded,
                            iconColor: Colors.green,
                            bgColor: Colors.green.shade50,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
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
          ),
        ],
      ),
      child: Column(
        children:[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 28,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}