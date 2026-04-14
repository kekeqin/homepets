import 'package:flutter/material.dart';

import '../../../models/pet.dart';
import '../../../widgets/pet_avatar.dart';
import 'member_profile_ipad_common.dart';

class MemberProfileIpadPetCard extends StatelessWidget {
  const MemberProfileIpadPetCard({
    super.key,
    required this.pet,
    required this.onTap,
  });

  final Pet pet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final levelThreshold = pet.levelThreshold ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: MemberProfileIpadColors.cardSoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PetAvatar(pet: pet, size: 66),
              const SizedBox(height: 12),
              Text(
                pet.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: MemberProfileIpadColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                pet.levelName,
                style: const TextStyle(
                  fontSize: 12,
                  color: MemberProfileIpadColors.muted,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: pet.progress,
                  minHeight: 8,
                  backgroundColor: Colors.white,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    MemberProfileIpadColors.green,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${pet.experience}/${levelThreshold == 0 ? '满级' : levelThreshold}',
                style: const TextStyle(
                  fontSize: 11,
                  color: MemberProfileIpadColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
