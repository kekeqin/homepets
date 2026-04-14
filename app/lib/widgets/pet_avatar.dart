import 'package:flutter/material.dart';

import '../models/pet.dart';
import '../models/pet_artwork.dart';

class PetAvatar extends StatelessWidget {
  final Pet pet;
  final double size;
  final bool showBackground;
  final int? poseSeed;

  const PetAvatar({
    super.key,
    required this.pet,
    this.size = 48,
    this.showBackground = true,
    this.poseSeed,
  });

  @override
  Widget build(BuildContext context) {
    final seed = poseSeed ?? pet.id;
    final assetPath = petAvatarAssetPath(
      pet.petType,
      deterministicPetPoseIndex(pet.petType, seed),
    );
    final avatarChild = Padding(
      padding: EdgeInsets.all(showBackground ? size * 0.08 : 0),
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Icon(
          Icons.pets_rounded,
          size: showBackground ? size * 0.58 : size * 0.82,
          color: const Color(0xFF628222),
        ),
      ),
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
                color: Colors.white.withValues(alpha: 0.94),
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
}
