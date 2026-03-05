import 'package:flutter/material.dart';

// mock avatar model
class CollectibleAvatar {
  final String title;
  final String imageUrl;
  final int xp;
  final int level;

  CollectibleAvatar({
    required this.title,
    required this.imageUrl,
    required this.xp,
    required this.level,
  });
}

// mock player stats model
class PlayerStats {
  final int coins;
  final int dailyStreak;

  PlayerStats({
    required this.coins,
    required this.dailyStreak,
  });
}

// mock data
final CollectibleAvatar mockAvatar = CollectibleAvatar(
  title: 'Squid',
  imageUrl: 'https://i.imgur.com/P4oM7W3.png',
  xp: 71,
  level: 2,
);

final PlayerStats mockStats = PlayerStats(
  coins: 120,
  dailyStreak: 7,
);

class AvatarPage extends StatelessWidget {
  const AvatarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final CollectibleAvatar avatar = mockAvatar;
    final PlayerStats stats = mockStats;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Avataras',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.yellow,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                avatar.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // avatar image placeholder
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.yellow, 
                    width: 3, 
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    avatar.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 14),


              // rarity indicator  
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(1, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.star, size: 24, color: Colors.white),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 14),

              // xp and level info
              SizedBox(
                height: 120,
                child: Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.bar_chart),
                              const SizedBox(height: 8),
                              Text('Level: ${avatar.level}',
                                  style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.show_chart),
                              const SizedBox(height: 8),
                              Text('XP: ${avatar.xp}',
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: (avatar.xp % 100) / 100,
                                minHeight: 6,
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),


              // coins
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.monetization_on),
                        title: Text('Coins: ${stats.coins}'),
                      ),
                    ),
                  ),
                  
                ],
              ),

              // daily streak
              Row(
                children: [
                 Expanded(
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.whatshot),
                        title: Text('Daily Streak: ${stats.dailyStreak} days'),
                      ),
                    ),
                  ),              
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}