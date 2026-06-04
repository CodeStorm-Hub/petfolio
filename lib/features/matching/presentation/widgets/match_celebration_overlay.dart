import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../pet_profile/data/models/pet.dart';

class MatchCelebrationOverlay extends StatelessWidget {
  const MatchCelebrationOverlay({
    super.key,
    required this.activePet,
    required this.matchedPetName,
    this.matchedPetAvatarUrl,
    required this.onSendMessage,
    required this.onKeepSwiping,
  });

  final Pet activePet;
  final String matchedPetName;
  final String? matchedPetAvatarUrl;
  final VoidCallback onSendMessage;
  final VoidCallback onKeepSwiping;

  @override
  Widget build(BuildContext context) {
    final activeEmoji = switch (activePet.species.toLowerCase()) {
      'cat' => '🐱',
      'rabbit' => '🐰',
      'bird' => '🦜',
      'reptile' => '🦎',
      _ => '🐶',
    };

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.2,
              colors: [
                AppColors.tangerine,
                AppColors.poppy,
                AppColors.lilac,
              ],
              stops: [0.0, 0.7, 1.0],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Floating paws bg
              const _FloatingPawsBackground(),

              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    // Headline
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '🐾💕🐾',
                            style: TextStyle(
                              fontSize: 80,
                              shadows: [
                                Shadow(
                                  color: Colors.black45,
                                  blurRadius: 22,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "It's a\n Pawfect Match!",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.05,
                              shadows: const [
                                Shadow(
                                  color: Colors.black45,
                                  blurRadius: 22,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${activePet.name} & $matchedPetName both said WOOF',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Avatars pressing paws
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.rotate(
                          angle: -8 * math.pi / 180,
                          child: _AvatarCircle(
                            avatarUrl: activePet.avatarUrl,
                            fallbackEmoji: activeEmoji,
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(-20, 0),
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.sunny,
                              border: Border.all(color: Colors.white, width: 6),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 28,
                                  offset: Offset(0, 12),
                                  spreadRadius: -8,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.pets_rounded,
                              size: 36,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(-40, 0),
                          child: Transform.rotate(
                            angle: 8 * math.pi / 180,
                            child: _AvatarCircle(
                              avatarUrl: matchedPetAvatarUrl,
                              fallbackEmoji: '🐾',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: onSendMessage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.poppy,
                              minimumSize: const Size.fromHeight(56),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Send a tail wag 🐾',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: onKeepSwiping,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            child: const Text('Keep swiping'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.avatarUrl,
    required this.fallbackEmoji,
  });

  final String? avatarUrl;
  final String fallbackEmoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 134,
      height: 134,
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white30,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 40,
            offset: Offset(0, 16),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: avatarUrl != null && avatarUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: avatarUrl!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: Text(
                    fallbackEmoji,
                    style: const TextStyle(fontSize: 70),
                  ),
                ),
                errorWidget: (context, url, error) => Center(
                  child: Text(
                    fallbackEmoji,
                    style: const TextStyle(fontSize: 70),
                  ),
                ),
              )
            : Text(
                fallbackEmoji,
                style: const TextStyle(fontSize: 70),
              ),
      ),
    );
  }
}

class _FloatingPawsBackground extends StatelessWidget {
  const _FloatingPawsBackground();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.2,
      child: Stack(
        children: [
          _buildPaw(10, 10, 38, -10),
          _buildPaw(80, 18, 30, 15),
          _buildPaw(15, 72, 42, -20),
          _buildPaw(78, 80, 36, 18),
          _buildPaw(50, 30, 28, 8),
        ],
      ),
    );
  }

  Widget _buildPaw(double x, double y, double size, double rot) {
    return Positioned(
      left: x * 4,
      top: y * 8,
      child: Transform.rotate(
        angle: rot * math.pi / 180,
        child: Icon(
          Icons.pets_rounded,
          size: size,
          color: Colors.white,
        ),
      ),
    );
  }
}
