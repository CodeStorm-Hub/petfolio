import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
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
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.42),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "It's a Match!",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.sora(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.05,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${activePet.name} and $matchedPetName want to connect',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _MatchAvatarRing(
                            child: PetAvatar(
                              imageUrl: activePet.avatarUrl,
                              initials: activePet.name,
                              semanticLabel: activePet.name,
                              size: PetAvatarSize.xl,
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(-18, 0),
                            child: _MatchAvatarRing(
                              highlight: true,
                              child: PetAvatar(
                                imageUrl: matchedPetAvatarUrl,
                                initials: matchedPetName,
                                semanticLabel: matchedPetName,
                                size: PetAvatarSize.xl,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),
                      PrimaryPillButton(
                        label: 'Send a Message',
                        isFullWidth: true,
                        leadingIcon: const Icon(
                          Icons.chat_bubble_rounded,
                          size: 20,
                        ),
                        onPressed: onSendMessage,
                      ),
                      const SizedBox(height: 12),
                      PrimaryPillButton(
                        label: 'Keep Swiping',
                        isFullWidth: true,
                        variant: PillButtonVariant.secondary,
                        onPressed: onKeepSwiping,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You can message anytime from Match',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchAvatarRing extends StatelessWidget {
  const _MatchAvatarRing({
    required this.child,
    this.highlight = false,
  });

  final Widget child;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: highlight ? AppColors.coral500 : Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: (highlight ? AppColors.coral500 : Colors.white)
                .withValues(alpha: 0.35),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}
