import 'package:flutter/painting.dart';
import 'package:petfolio/core/theme/app_colors.dart';

enum PetSpecies {
  dog,
  cat,
  rabbit,
  bird,
  fish,
  reptile;

  String get label => switch (this) {
        dog => 'Dog',
        cat => 'Cat',
        rabbit => 'Rabbit',
        bird => 'Bird',
        fish => 'Fish',
        reptile => 'Reptile',
      };

  String get emoji => switch (this) {
        dog => '🐶',
        cat => '🐱',
        rabbit => '🐰',
        bird => '🐦',
        fish => '🐠',
        reptile => '🦎',
      };

  Color get accent => switch (this) {
        dog => AppColors.tangerine,
        cat => AppColors.poppy,
        rabbit => AppColors.lilac,
        bird => AppColors.sky,
        fish => AppColors.mint,
        reptile => AppColors.sunny,
      };

  Color get accentDark => switch (this) {
        dog => AppColors.tangerineD,
        cat => AppColors.poppyD,
        rabbit => AppColors.lilacD,
        bird => AppColors.skyD,
        fish => AppColors.mintD,
        reptile => AppColors.sunnyD,
      };

  Color get tint => switch (this) {
        dog => AppColors.tangerineSoft,
        cat => AppColors.poppySoft,
        rabbit => AppColors.lilacSoft,
        bird => AppColors.skySoft,
        fish => AppColors.mintSoft,
        reptile => AppColors.sunnySoft,
      };

  Color get tintDark => switch (this) {
        dog => AppColors.tangerineSoftD,
        cat => AppColors.poppySoftD,
        rabbit => AppColors.lilacSoftD,
        bird => AppColors.skySoftD,
        fish => AppColors.mintSoftD,
        reptile => AppColors.sunnySoftD,
      };

  Color resolvedAccent(bool isDark) => isDark ? accentDark : accent;
  Color resolvedTint(bool isDark) => isDark ? tintDark : tint;

  List<String> get breeds => switch (this) {
        dog => [
            'Border Collie', 'Labrador Retriever', 'Golden Retriever',
            'French Bulldog', 'Australian Shepherd', 'Shiba Inu',
            'Dachshund', 'Poodle (Standard)', 'Poodle (Miniature)',
            'Cavalier King Charles', 'Beagle', 'Mixed breed',
            'Pomeranian', 'Corgi', 'Cockapoo', 'Bernese Mountain Dog',
            "Don't know yet",
          ],
        cat => [
            'Maine Coon', 'British Shorthair', 'Ragdoll', 'Siamese',
            'Bengal', 'Persian', 'Russian Blue', 'Scottish Fold',
            'Sphynx', 'Domestic Shorthair', 'Domestic Longhair',
            'Mixed breed', "Don't know yet",
          ],
        rabbit => [
            'Holland Lop', 'Netherland Dwarf', 'Mini Rex', 'Lionhead',
            'Flemish Giant', 'Dutch', 'English Angora', 'Mixed breed',
            "Don't know yet",
          ],
        bird => [
            'Cockatiel', 'Budgerigar', 'African Grey', 'Conure',
            'Canary', 'Lovebird', 'Cockatoo', 'Macaw', 'Finch',
            "Don't know yet",
          ],
        fish => [
            'Betta', 'Goldfish', 'Guppy', 'Tetra', 'Cichlid',
            'Angelfish', 'Discus', 'Mixed tank', "Don't know yet",
          ],
        reptile => [
            'Bearded Dragon', 'Leopard Gecko', 'Ball Python',
            'Corn Snake', 'Crested Gecko', 'Russian Tortoise',
            "Don't know yet",
          ],
      };

  static PetSpecies? fromId(String? id) => switch (id) {
        'dog' => dog,
        'cat' => cat,
        'rabbit' => rabbit,
        'bird' => bird,
        'fish' => fish,
        'reptile' => reptile,
        _ => null,
      };
}
