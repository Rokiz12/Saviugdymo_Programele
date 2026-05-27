import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../data/models/diary_entry_model.dart';
import '../../theme/app_theme.dart';
import 'diary_provider.dart';

class DiaryDialogs {
  static void showUpgradeDialog(BuildContext context, String message) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.background2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Text('⭐', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text('Premium funkcija', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textColor)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: TextStyle(color: colors.textColor)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.intenseColor.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Premium privalumai:', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textColor)),
                  const SizedBox(height: 6),
                  Text('✅ Neriboti dienoraščio įrašai', style: TextStyle(color: colors.textColor)),
                  Text('✅ Neriboti nuotraukų prisegimas', style: TextStyle(color: colors.textColor)),
                  Text('✅ Visi statistikos įrankiai', style: TextStyle(color: colors.textColor)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Vėliau', style: TextStyle(color: colors.appBarUnpickedColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: navigate to paywall
            },
            style: ElevatedButton.styleFrom(backgroundColor: colors.intenseColor, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Gauti Premium', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static void showAddCategoryDialog(BuildContext context, DiaryProvider provider) {
    final colors = context.colors;

    // Premium gate: max 1 category for free users
    if (!provider.isPremium && provider.categories.length >= 1) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: colors.background2,
          title: Text("⭐ Premium funkcija", style: TextStyle(color: colors.textColor)),
          content: Text(
            "Nemokama versija leidžia turėti tik 1 kategoriją. Gauk Premium ir turėk neribotai!",
            style: TextStyle(color: colors.appBarUnpickedColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Atšaukti", style: TextStyle(color: colors.textColor)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: navigate to paywall
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.intenseColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Gauti Premium"),
            ),
          ],
        ),
      );
      return; // ← stop here, don't show add dialog
    }

    // Free user with 0 categories OR premium user — show normal dialog
    final TextEditingController catController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colors.background2,
          title: Text("Nauja kategorija", style: TextStyle(color: colors.textColor)),
          content: TextField(
            controller: catController,
            style: TextStyle(color: colors.textColor),
            decoration: InputDecoration(
              hintText: "Pvz.: Sporto progresas",
              hintStyle: TextStyle(color: colors.appBarUnpickedColor),
              filled: true,
              fillColor: colors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Atšaukti", style: TextStyle(color: colors.textColor))),
            ElevatedButton(
              onPressed: () {
                final text = catController.text.trim();
                if (text.isNotEmpty && !provider.categories.contains(text)) {
                  provider.addCategory(text);
                  Navigator.pop(context);
                } else if (provider.categories.contains(text)) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tokia kategorija jau egzistuoja!")));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: colors.intenseColor, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text("Pridėti"),
            ),
          ],
        );
      },
    );
  }

  static void showDeleteCategoryDialog(BuildContext context, DiaryProvider provider, String category) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colors.background2,
          title: Text("Ištrinti kategoriją?", style: TextStyle(color: colors.textColor)),
          content: Text("Ar tikrai norite ištrinti aplankalą '$category'?\n\nNuotraukos nebus ištrintos, jos atsiras skiltyje 'Visos'.", style: TextStyle(color: colors.textColor)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Atšaukti", style: TextStyle(color: colors.textColor))),
            ElevatedButton(
              onPressed: () {
                provider.deleteCategory(category);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Kategorija '$category' ištrinta!"), backgroundColor: Colors.redAccent));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text("Ištrinti"),
            ),
          ],
        );
      },
    );
  }

  static void showImagePickerOptions(BuildContext context, DiaryProvider provider) {
    final colors = context.colors;
    if (!provider.canAddPhoto) {
      showUpgradeDialog(context, 'Nemokamoje versijoje galima prisegti tik 3 nuotraukas per savaitę.\n\nŠi savaitė: ${provider.photosThisWeek} / 3 nuotraukos.');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.appBarUnpickedColor.withOpacity(0.5), borderRadius: BorderRadius.circular(2)))),
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: colors.textColor),
                title: Text('Pasirinkti iš galerijos', style: TextStyle(color: colors.textColor)),
                onTap: () {
                  Navigator.pop(context);
                  provider.pickImage(ImageSource.gallery).catchError((e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Klaida: $e")));
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera, color: colors.textColor),
                title: Text('Daryti naują nuotrauką', style: TextStyle(color: colors.textColor)),
                onTap: () {
                  Navigator.pop(context);
                  provider.pickImage(ImageSource.camera).catchError((e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Klaida: $e")));
                  });
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  static void showEntryDialog(BuildContext context, DiaryEntryModel e) {
    final colors = context.colors;
    final dateStr = '${e.createdAt.year}-${e.createdAt.month.toString().padLeft(2, '0')}-${e.createdAt.day.toString().padLeft(2, '0')}';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.background2,
        title: Text(dateStr, style: TextStyle(color: colors.textColor)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (e.moodImage != null && e.moodImage!.isNotEmpty)
                    Image.asset(e.moodImage!, width: 32, height: 32),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(8)),
                    child: Text(e.mood, style: TextStyle(color: colors.textColor)),
                  ),
                ],
              ),
              if (e.highlight.isNotEmpty) ...[const SizedBox(height: 12), Text("✨ ${e.highlight}", style: TextStyle(color: colors.textColor))],
              if (e.diaryText.isNotEmpty) ...[const SizedBox(height: 12), Text("📖 ${e.diaryText}", style: TextStyle(color: colors.textColor))],
              if (e.imageUrl != null && e.imageUrl!.isNotEmpty) ...[
                 const SizedBox(height: 16),
                 ClipRRect(
                   borderRadius: BorderRadius.circular(14),
                   child: CachedNetworkImage(imageUrl: e.imageUrl!, fit: BoxFit.contain, placeholder: (context, url) => Center(child: CircularProgressIndicator(color: colors.intenseColor))),
                 ),
              ]
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Uždaryti", style: TextStyle(color: colors.textColor)))],
      ),
    );
  }

  static void showEntriesList(BuildContext context, List<DiaryEntryModel> entries) {
    final colors = context.colors;
    final dateStr = '${entries.first.createdAt.year}-${entries.first.createdAt.month.toString().padLeft(2, '0')}-${entries.first.createdAt.day.toString().padLeft(2, '0')}';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.appBarUnpickedColor.withOpacity(0.5), borderRadius: BorderRadius.circular(2))))),
            Text(dateStr, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textColor)),
            const SizedBox(height: 16),
            ...entries.map((e) => ListTile(
              leading: e.moodImage != null && e.moodImage!.isNotEmpty
                  ? Image.asset(e.moodImage!, width: 32, height: 32)
                  : Text(e.mood.split(' ')[0], style: const TextStyle(fontSize: 24)),              title: Text('${e.createdAt.hour}:${e.createdAt.minute.toString().padLeft(2, '0')}', style: TextStyle(color: colors.textColor)),
              subtitle: Text(e.preview, maxLines: 1, style: TextStyle(color: colors.appBarUnpickedColor)),
              onTap: () { Navigator.pop(context); showEntryDialog(context, e); },
            )),
          ],
        ),
      ),
    );
  }
}