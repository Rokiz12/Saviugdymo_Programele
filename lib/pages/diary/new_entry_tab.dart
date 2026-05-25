import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/sound_service.dart';
import '../../services/reward_service.dart';
import '../../services/reward_notifier.dart';
import 'diary_provider.dart';
import 'diary_dialogs.dart';

class NewEntryTab extends StatelessWidget {
  const NewEntryTab({super.key});

  void _handleSave(BuildContext context, DiaryProvider provider) async {
    if (!provider.canAddEntry) {
      DiaryDialogs.showUpgradeDialog(context, 'Nemokamoje versijoje galima pridėti tik 2 įrašus per savaitę.');
      return;
    }

    if (provider.selectedMood.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pasirink nuotaiką!")));
      return;
    }

    final moodImagePath = context.colors.moodImages[provider.moods.indexOf(provider.selectedMood)];

    if (provider.moods.indexOf(provider.selectedMood) <= 1) {
      SoundService.playHappyDiary();
    } else {
      SoundService.playSadDiary();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator(color: context.colors.intenseColor)),
    );

    try {
      final (gotXp, oldLvl, newLvl) = await provider.saveEntry(moodImagePath);
      if (!context.mounted) return;
      Navigator.pop(context); // close loading
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Įrašas išsaugotas!"), backgroundColor: Colors.green));
      
      if (gotXp) {
        RewardService().checkLevelUp(userId: provider.userId, oldLevel: oldLvl, newLevel: newLvl, notifier: context.read<RewardNotifier>());
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gavai +20 XP!", style: TextStyle(fontWeight: FontWeight.bold))));
      }
      DefaultTabController.of(context)?.animateTo(1);
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Klaida: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = context.watch<DiaryProvider>();

    if (!provider.questionsLoaded) {
      return Center(child: CircularProgressIndicator(color: colors.intenseColor));
    }

    if (provider.currentQuestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.appBarUnpickedColor),
            const SizedBox(height: 16),
            Text("Atsiprašome, klausimai nėra prieinami", style: TextStyle(fontSize: 16, color: colors.textColor)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: provider.loadQuestions,
              icon: const Icon(Icons.refresh),
              label: const Text("Bandyti dar kartą"),
              style: ElevatedButton.styleFrom(backgroundColor: colors.intenseColor, foregroundColor: Colors.black),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Kaip jautiesi?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textColor)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) => _moodBtn(context, provider, i)),
          ),
          const SizedBox(height: 32),
          
          ...[
            for (int i = 0; i < provider.currentQuestions.length; i++)
              _buildField(context, provider, provider.currentQuestions[i].question, i, maxLines: provider.currentQuestions[i].maxLines),
          ],
          
          _buildField(context, provider, "Laisvas dienoraštis", 3, maxLines: 4),
          
          const SizedBox(height: 16),
          Text("Prisegti nuotrauką (neprivaloma)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colors.textColor)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => DiaryDialogs.showImagePickerOptions(context, provider),
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: colors.background2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.background, width: 1.5),
              ),
              child: provider.selectedImage != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(provider.selectedImage!, fit: BoxFit.cover)),
                        Positioned(
                          top: 8, right: 8,
                          child: GestureDetector(
                            onTap: provider.clearImage,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 48, color: colors.appBarUnpickedColor),
                        const SizedBox(height: 12),
                        Text("Paspauskite, kad pridėtumėte", style: TextStyle(color: colors.appBarUnpickedColor, fontWeight: FontWeight.w500)),
                      ],
                    ),
            ),
          ),

          if (provider.selectedImage != null) ...[
            const SizedBox(height: 20),
            if (provider.categories.isNotEmpty) ...[
              Text("Pasirinkite kategoriją:", style: TextStyle(fontWeight: FontWeight.bold, color: colors.textColor)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: provider.categories.contains(provider.selectedUploadCategory) ? provider.selectedUploadCategory : provider.categories.first,
                dropdownColor: colors.background2,
                style: TextStyle(color: colors.textColor, fontSize: 16),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  filled: true, fillColor: colors.background2,
                ),
                items: provider.categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) { if (val != null) provider.setUploadCategory(val); },
              ),
            ] else ...[
              Text("Neturite sukūrę jokių kategorijų. Galite jas pridėti Prisiminimų skiltyje!", style: TextStyle(color: colors.appBarUnpickedColor, fontStyle: FontStyle.italic))
            ],
          ],

          const SizedBox(height: 40),

          ElevatedButton(
            onPressed: () => _handleSave(context, provider),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.intenseColor, foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text("Išsaugoti įrašą", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _moodBtn(BuildContext context, DiaryProvider provider, int i) {
    final colors = context.colors;
    final isSelected = provider.selectedMood == provider.moods[i];
    return GestureDetector(
      onTap: () => provider.setMood(provider.moods[i]),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transform: isSelected
                ? (Matrix4.identity()..translate(0.0, -12.0))
                : Matrix4.identity(),
            child: Image.asset(
              colors.moodImages[i],
              width: 60,
              height: 60,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            provider.moods[i],
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: colors.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(BuildContext context, DiaryProvider provider, String hint, int index, {int maxLines = 2}) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hint, style: TextStyle(fontWeight: FontWeight.bold, color: colors.textColor, fontSize: 15)),
          const SizedBox(height: 8),
          TextField(
            controller: provider.textControllers[index],
            maxLines: maxLines,
            style: TextStyle(color: colors.textColor),
            decoration: InputDecoration(
              hintText: "Rašyk čia...", hintStyle: TextStyle(color: colors.appBarUnpickedColor),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              filled: true, fillColor: colors.background2,
            ),
          ),
        ],
      ),
    );
  }
}