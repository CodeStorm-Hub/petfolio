import 'package:flutter/painting.dart';
import 'package:petfolio/core/theme/app_colors.dart';

/// Each species carries its own accent + tint color that re-skins any
/// species-aware widget (switcher rows, onboarding cards, hero cards).
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
        dog => '🐾',
        cat => '🐱',
        rabbit => '🐇',
        bird => '🐦',
        fish => '🐠',
        reptile => '🦎',
      };

  /// Pillar accent for this species (used for selected borders, icons, CTAs).
  Color get accent => switch (this) {
        dog => AppColors.coral500,
        cat => AppColors.sunset500,
        rabbit => AppColors.meadow500,
        bird => AppColors.mulberry500,
        fish => AppColors.blue500,
        reptile => AppColors.apricot500,
      };

  /// Very light tint background used in selected states (species cards, switcher rows).
  Color get tint => switch (this) {
        dog => const Color(0xFFFBDFD5),
        cat => const Color(0xFFFDEBD6),
        rabbit => const Color(0xFFDAEBE0),
        bird => const Color(0xFFEBDDE6),
        fish => AppColors.blue50,
        reptile => const Color(0xFFFBEAD7),
      };

  List<String> get breeds => switch (this) {
        dog => [
            'Border Collie',
            'Labrador Retriever',
            'Golden Retriever',
            'French Bulldog',
            'Australian Shepherd',
            'Shiba Inu',
            'Dachshund',
            'Poodle (Standard)',
            'Poodle (Miniature)',
            'Cavalier King Charles',
            'Beagle',
            'Mixed breed',
            'Pomeranian',
            'Corgi',
            'Cockapoo',
            'Bernese Mountain Dog',
            "Don't know yet",
          ],
        cat => [
            'Maine Coon',
            'British Shorthair',
            'Ragdoll',
            'Siamese',
            'Bengal',
            'Persian',
            'Russian Blue',
            'Scottish Fold',
            'Sphynx',
            'Domestic Shorthair',
            'Domestic Longhair',
            'Mixed breed',
            "Don't know yet",
          ],
        rabbit => [
            'Holland Lop',
            'Netherland Dwarf',
            'Mini Rex',
            'Lionhead',
            'Flemish Giant',
            'Dutch',
            'English Angora',
            'Mixed breed',
            "Don't know yet",
          ],
        bird => [
            'Cockatiel',
            'Budgerigar',
            'African Grey',
            'Conure',
            'Canary',
            'Lovebird',
            'Cockatoo',
            'Macaw',
            'Finch',
            "Don't know yet",
          ],
        fish => [
            'Betta',
            'Goldfish',
            'Guppy',
            'Tetra',
            'Cichlid',
            'Angelfish',
            'Discus',
            'Mixed tank',
            "Don't know yet",
          ],
        reptile => [
            'Bearded Dragon',
            'Leopard Gecko',
            'Ball Python',
            'Corn Snake',
            'Crested Gecko',
            'Russian Tortoise',
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
