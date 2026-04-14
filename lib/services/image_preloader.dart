import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';


import '../data/repositories/pet_repository.dart'; 

Future<void> preloadPetImages() async {
  try {
    final petRepository = PetRepository();
    final pets = await petRepository.getAllPets();

    for (var pet in pets) {
      final imageUrl = pet.images['collection'] ?? pet.images.values.firstOrNull ?? '';

      if (imageUrl.isNotEmpty) {
        DefaultCacheManager().getSingleFile(imageUrl).catchError((e) {
          debugPrint('Failed to preload image: $imageUrl - $e');
          throw e;
        });
      }
    }
    debugPrint('Background image preloading check finished.');
  } catch (e) {
    debugPrint('Error fetching pets for preloading: $e');
  }
}