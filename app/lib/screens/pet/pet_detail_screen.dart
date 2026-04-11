import 'package:flutter/material.dart';

import '../../models/pet.dart';
import 'enhanced_pet_detail_screen.dart';

class PetDetailScreen extends StatelessWidget {
  const PetDetailScreen({super.key, required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    return EnhancedPetDetailScreen(pet: pet);
  }
}
