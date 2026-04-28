import 'package:flutter/material.dart';

const habitIcons = {
  'run':        Icons.directions_run,
  'water':      Icons.water_drop,
  'book':       Icons.menu_book,
  'sleep':      Icons.bedtime,
  'food':       Icons.restaurant,
  'heart':      Icons.favorite,
  'gym':        Icons.fitness_center,
  'meditation': Icons.self_improvement,
  'music':      Icons.music_note,
  'code':       Icons.code,
  'study':      Icons.school,
  'money':      Icons.attach_money,
  'walk':       Icons.directions_walk,
  'bike':       Icons.directions_bike,
  'clean':      Icons.cleaning_services,
  'journal':    Icons.edit_note,
};

IconData? habitIconData(String? key) =>
    key != null ? habitIcons[key] : null;