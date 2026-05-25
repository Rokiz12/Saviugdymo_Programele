import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/models/diary_entry_model.dart';
import '../../theme/app_theme.dart';
import 'diary_provider.dart';
import 'diary_dialogs.dart';
import 'comparison_page.dart';

class MemoriesTab extends StatelessWidget {
  const MemoriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = context.watch<DiaryProvider>();
    final memories = provider.allEntries.where((e) => e.imageUrl != null && e.imageUrl!.isNotEmpty).toList();
    memories.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text("Kategorijos"), icon: Icon(Icons.folder)),
                ButtonSegment(value: 1, label: Text("Visos"), icon: Icon(Icons.photo_library)),
              ],
              selected: {provider.memoriesViewIndex},
              onSelectionChanged: (newSelection) => provider.setMemoriesView(newSelection.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>((states) => states.contains(WidgetState.selected) ? colors.intenseColor : colors.background2),
                foregroundColor: WidgetStateProperty.resolveWith<Color>((states) => states.contains(WidgetState.selected) ? Colors.black : colors.textColor),
                side: WidgetStateProperty.all(BorderSide(color: colors.background, width: 1)),
                shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
            ),
          ),
        ),

        if (provider.isSelectionMode)
          Container(
            color: colors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${provider.selectedForDeletion.length} pasirinkta", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colors.textColor)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () {
                        if (provider.selectedForDeletion.isNotEmpty) {
                          showDialog(
                            context: context, barrierDismissible: false,
                            builder: (_) => Center(child: CircularProgressIndicator(color: colors.intenseColor)),
                          );
                          provider.deleteSelectedImages().then((_) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ištrinta!"), backgroundColor: Colors.green));
                          });
                        }
                      },
                    ),
                    IconButton(icon: Icon(Icons.close, color: colors.textColor), onPressed: provider.closeSelectionMode),
                  ],
                ),
              ],
            ),
          ),

        Expanded(
          child: provider.memoriesViewIndex == 0 
            ? _buildCategoriesView(context, provider, memories) 
            : _buildAllPhotosView(context, provider, memories),
        ),
      ],
    );
  }

  Widget _buildCategoriesView(BuildContext context, DiaryProvider provider, List<DiaryEntryModel> memories) {
    final colors = context.colors;

    if (provider.selectedCategoryView == null) {
      return Stack(
        children: [
          if (provider.categories.isEmpty)
            Center(child: Text("Sukurkite pirmąją kategoriją!", style: TextStyle(color: colors.appBarUnpickedColor)))
          else
            GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.0),
              itemCount: provider.categories.length,
              itemBuilder: (context, index) {
                final cat = provider.categories[index];
                final catMemories = memories.where((e) => e.category == cat).toList();

                return GestureDetector(
                  onTap: () => provider.setCategoryView(cat),
                  onLongPress: () => DiaryDialogs.showDeleteCategoryDialog(context, provider, cat),
                  child: Container(
                    decoration: BoxDecoration(color: colors.background2, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.background, width: 1.5)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_special, size: 48, color: colors.intenseColor),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(cat, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colors.textColor), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(height: 4),
                        Text("${catMemories.length} nuotr.", style: TextStyle(color: colors.appBarUnpickedColor, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
            
          Positioned(
            bottom: 24, right: 24,
            child: FloatingActionButton(backgroundColor: colors.intenseColor, foregroundColor: Colors.black, onPressed: () => DiaryDialogs.showAddCategoryDialog(context, provider), child: const Icon(Icons.add)),
          ),
        ],
      );
    } else {
      final categoryMemories = memories.where((e) => e.category == provider.selectedCategoryView).toList();
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                IconButton(icon: Icon(Icons.arrow_back, color: colors.textColor), onPressed: () => provider.setCategoryView(null)),
                Expanded(child: Text(provider.selectedCategoryView!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textColor), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          if (!provider.isSelectionMode) _buildComparisonForCategory(context, categoryMemories),
          Expanded(
            child: categoryMemories.isEmpty
                ? Center(child: Text("Šioje kategorijoje nėra nuotraukų.", style: TextStyle(color: colors.appBarUnpickedColor)))
                : _buildPhotoGrid(context, provider, categoryMemories),
          ),
        ],
      );
    }
  }

  Widget _buildAllPhotosView(BuildContext context, DiaryProvider provider, List<DiaryEntryModel> memories) {
    if (memories.isEmpty) return Center(child: Text("Dar nėra jokių nuotraukų.", style: TextStyle(color: context.colors.appBarUnpickedColor)));
    return _buildPhotoGrid(context, provider, memories);
  }

  Widget _buildPhotoGrid(BuildContext context, DiaryProvider provider, List<DiaryEntryModel> photos) {
    final colors = context.colors;
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4, childAspectRatio: 0.8),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final entry = photos[index];
        final isSelected = provider.selectedForDeletion.contains(entry.id);

        return GestureDetector(
          onLongPress: () => provider.toggleSelectionMode(entry.id),
          onTap: () {
            if (provider.isSelectionMode) {
              provider.toggleSelectionMode(entry.id);
            } else {
              DiaryDialogs.showEntryDialog(context, entry);
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: entry.imageUrl!, fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: colors.background2, child: Center(child: CircularProgressIndicator(color: colors.intenseColor, strokeWidth: 2))),
                  errorWidget: (context, url, error) => Icon(Icons.error, color: colors.appBarUnpickedColor),
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6), color: Colors.black.withOpacity(0.6),
                    child: Text('${entry.createdAt.year}-${entry.createdAt.month}-${entry.createdAt.day}', style: const TextStyle(color: Colors.white, fontSize: 11), textAlign: TextAlign.center),
                  ),
                ),
                if (provider.isSelectionMode)
                  Container(
                    color: isSelected ? Colors.black.withOpacity(0.6) : Colors.black.withOpacity(0.1),
                    alignment: Alignment.center,
                    child: isSelected ? Icon(Icons.check_circle, color: colors.intenseColor, size: 36) : const Icon(Icons.circle_outlined, color: Colors.white70, size: 36),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComparisonForCategory(BuildContext context, List<DiaryEntryModel> categoryMemories) {
    if (categoryMemories.length < 2) return const SizedBox.shrink();
    final today = DateTime.now();
    DiaryEntryModel? memoryFromToday;
    DiaryEntryModel? pastMemory;
    String singleTitle = ""; String comparisonTitle = "";

    try { memoryFromToday = categoryMemories.firstWhere((e) => e.createdAt.year == today.year && e.createdAt.month == today.month && e.createdAt.day == today.day); } catch (_) {}
    try { pastMemory = categoryMemories.firstWhere((e) => e.createdAt.year == today.year - 1 && e.createdAt.month == today.month && e.createdAt.day == today.day); singleTitle = "Prieš metus šioje kategorijoje..."; comparisonTitle = "1 Metų Progresas!"; } catch (_) {}
    if (pastMemory == null) {
      final oneMonthAgo = DateTime(today.year, today.month - 1, today.day);
      try { pastMemory = categoryMemories.firstWhere((e) => e.createdAt.year == oneMonthAgo.year && e.createdAt.month == oneMonthAgo.month && e.createdAt.day == oneMonthAgo.day); singleTitle = "Prieš mėnesį šioje kategorijoje..."; comparisonTitle = "1 Mėnesio Progresas!"; } catch (_) {}
    }

    if (memoryFromToday != null && pastMemory != null && memoryFromToday.id != pastMemory.id) {
      return _buildComparisonPreviewCard(context, pastMemory, memoryFromToday, comparisonTitle);
    } else if (pastMemory != null) {
      return _buildSpecialMemoryCard(context, pastMemory, singleTitle);
    }
    return const SizedBox.shrink();
  }

  Widget _buildComparisonPreviewCard(BuildContext context, DiaryEntryModel beforeEntry, DiaryEntryModel afterEntry, String title) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FullScreenComparisonPage(beforeEntry: beforeEntry, afterEntry: afterEntry, title: title))),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16), height: 120, width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
          image: DecorationImage(image: CachedNetworkImageProvider(afterEntry.imageUrl!), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.compare_arrows, color: colors.intenseColor, size: 40), const SizedBox(height: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 4),
              const Text("Paspauskite, kad palygintumėte!", style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialMemoryCard(BuildContext context, DiaryEntryModel entry, String title) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () => DiaryDialogs.showEntryDialog(context, entry),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16), height: 180, width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
          image: DecorationImage(image: CachedNetworkImageProvider(entry.imageUrl!), fit: BoxFit.cover),
        ),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: const LinearGradient(colors: [Colors.black87, Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.center)),
          padding: const EdgeInsets.all(16), alignment: Alignment.bottomLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: colors.intenseColor, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [const Icon(Icons.history, size: 16, color: Colors.black), const SizedBox(width: 6), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black))],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}