import 'package:flutter/material.dart';
import 'package:pvp/pages/avatar.dart';
import 'package:pvp/pages/minigames.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';

class CombinedAvatarAndCollectionPage extends StatelessWidget {
  final String userId;

  const CombinedAvatarAndCollectionPage({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,

      appBar:CustomAppBar(title: "Avataras"),

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