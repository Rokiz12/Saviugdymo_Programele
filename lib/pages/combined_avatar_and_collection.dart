import 'package:flutter/material.dart';
import 'package:pvp/pages/avatar.dart';
import 'package:pvp/pages/minigames.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';

class CombinedAvatarAndCollectionPage extends StatefulWidget {
  final String userId;

  const CombinedAvatarAndCollectionPage({
    super.key,
    required this.userId,
  });

  @override
  State<CombinedAvatarAndCollectionPage> createState() => _CombinedAvatarAndCollectionPageState();
}

class _CombinedAvatarAndCollectionPageState extends State<CombinedAvatarAndCollectionPage> {
  final GlobalKey<AvatarPageState> _avatarKey = GlobalKey<AvatarPageState>();

  Future<void> _onPetEquipped() async {
    // Refresh avatar when pet is equipped
    if (_avatarKey.currentState != null) {
      await _avatarKey.currentState!.refreshData();
    }
  }

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
              child: AvatarPage(key: _avatarKey, userId: widget.userId),
            ),

            const SizedBox(height: 20),

            SizedBox(
              child: CollectionPage(
                userId: widget.userId,
                onPetEquipped: _onPetEquipped,
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
