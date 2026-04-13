import 'package:flutter/material.dart';
import 'package:pvp/pages/avatar.dart';
import 'package:pvp/pages/minigames.dart';

class CombinedAvatarAndCollectionPage extends StatelessWidget {
  final String userId;

  const CombinedAvatarAndCollectionPage({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text(
          "Avataras",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.yellow,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: Colors.transparent,
              child: AvatarPage(userId: userId),
            ),

            const SizedBox(height: 20),

            SizedBox(
              child: CollectionPage(userId: userId),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}