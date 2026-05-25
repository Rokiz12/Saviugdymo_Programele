import 'package:flutter/material.dart';
import 'package:before_after/before_after.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/diary_entry_model.dart';
import '../../theme/app_theme.dart';

class FullScreenComparisonPage extends StatefulWidget {
  final DiaryEntryModel beforeEntry;
  final DiaryEntryModel afterEntry;
  final String title;

  const FullScreenComparisonPage({
    super.key,
    required this.beforeEntry,
    required this.afterEntry,
    required this.title,
  });

  @override
  State<FullScreenComparisonPage> createState() => _FullScreenComparisonPageState();
}

class _FullScreenComparisonPageState extends State<FullScreenComparisonPage> {
  double _sliderValue = 0.5;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    return Scaffold(
      backgroundColor: Colors.black, 
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 3 / 4, 
          child: BeforeAfter(
            value: _sliderValue,
            before: CachedNetworkImage(imageUrl: widget.afterEntry.imageUrl!, fit: BoxFit.cover),
            after: CachedNetworkImage(imageUrl: widget.beforeEntry.imageUrl!, fit: BoxFit.cover), 
            trackColor: colors.intenseColor,
            thumbColor: colors.intenseColor,
            onValueChanged: (value) => setState(() => _sliderValue = value),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("PRIEŠ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              Text("PO (ŠIANDIEN)", style: TextStyle(color: colors.intenseColor, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}