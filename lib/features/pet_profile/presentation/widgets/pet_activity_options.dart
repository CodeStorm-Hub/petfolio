import 'package:flutter/material.dart';

class PetActivityOption {
  const PetActivityOption(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;
}

const kPetActivityOptions = [
  PetActivityOption('sedentary', 'Couch potato', Icons.weekend_rounded),
  PetActivityOption('low', 'Easy going', Icons.directions_walk_rounded),
  PetActivityOption('moderate', 'Active', Icons.directions_run_rounded),
  PetActivityOption('high', 'Very active', Icons.fitness_center_rounded),
  PetActivityOption('very_high', 'Athlete', Icons.bolt_rounded),
];
