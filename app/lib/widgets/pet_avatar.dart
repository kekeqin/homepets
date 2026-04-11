import 'package:flutter/material.dart';

import '../models/pet.dart';

class PetAvatar extends StatelessWidget {
  final Pet pet;
  final double size;
  final bool showBackground;

  const PetAvatar({
    super.key,
    required this.pet,
    this.size = 48,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final defaultAssetPath = _assetPathForPet(pet);
    final assetPath = showBackground
        ? defaultAssetPath
        : (_homeAssetPathForPet(pet) ?? defaultAssetPath);
    final avatarChild = Padding(
      padding: EdgeInsets.all(showBackground ? size * 0.08 : 0),
      child: assetPath == null
          ? Icon(
              pet.isEgg ? Icons.egg_alt_rounded : Icons.pets_rounded,
              size: showBackground ? size * 0.58 : size * 0.82,
              color: pet.isEgg
                  ? const Color(0xFFD89B00)
                  : const Color(0xFF628222),
            )
          : Image.asset(assetPath, fit: BoxFit.contain),
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (showBackground)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: pet.isEgg
                    ? const Color(0xFFFFF4CF)
                    : Colors.white.withValues(alpha: 0.94),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x22000000),
                    blurRadius: size * 0.12,
                    offset: Offset(0, size * 0.05),
                  ),
                ],
              ),
              child: ClipOval(child: avatarChild),
            )
          else
            SizedBox(width: size, height: size, child: avatarChild),
          if (pet.hasCrown)
            Positioned(
              top: -size * 0.02,
              child: Icon(
                Icons.workspace_premium_rounded,
                size: size * 0.28,
                color: const Color(0xFFFFCA4D),
              ),
            ),
        ],
      ),
    );
  }

  String? _assetPathForPet(Pet pet) {
    if (pet.isEgg) {
      return null;
    }

    switch (pet.petType) {
      case 'bird':
        return 'assets/images/pets/bird.png';
      case 'cat':
        return 'assets/images/pets/cat.png';
      case 'dog':
        return 'assets/images/pets/dog.png';
      case 'fish':
        return 'assets/images/pets/fish.png';
      case 'hamster':
        return 'assets/images/pets/hamster.png';
      case 'panda':
        return 'assets/images/pets/panda.png';
      case 'rabbit':
        return 'assets/images/pets/rabbit.png';
      case 'turtle':
        return 'assets/images/pets/turtle.png';
      default:
        return null;
    }
  }

  String? _homeAssetPathForPet(Pet pet) {
    switch (pet.petType) {
      case 'bird':
        return 'assets/images/pets/bird_home.png';
      case 'cat':
        return 'assets/images/pets/cat_home.png';
      case 'dog':
        return 'assets/images/pets/dog_home.png';
      case 'fish':
        return 'assets/images/pets/fish_home.png';
      case 'hamster':
        return 'assets/images/pets/hamster_home.png';
      case 'panda':
        return 'assets/images/pets/panda_home.png';
      case 'rabbit':
        return 'assets/images/pets/rabbit_home.png';
      case 'turtle':
        return 'assets/images/pets/turtle_home.png';
      default:
        return null;
    }
  }
}
