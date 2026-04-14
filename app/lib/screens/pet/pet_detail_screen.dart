import 'package:flutter/material.dart';

import '../../models/pet.dart';
import 'widgets/pet_detail_view.dart';

class PetDetailScreen extends StatelessWidget {
  const PetDetailScreen({super.key, required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8),
      appBar: AppBar(
        title: const Text('宠物详情'),
        backgroundColor: const Color(0xFFF5F1E8),
        foregroundColor: const Color(0xFF5A3A21),
        surfaceTintColor: const Color(0xFFF5F1E8),
      ),
      body: PetDetailView(pet: pet),
    );
  }
}
