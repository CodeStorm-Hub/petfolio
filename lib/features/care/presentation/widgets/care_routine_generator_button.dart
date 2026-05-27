import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class CareRoutineGeneratorButton extends StatelessWidget {
  const CareRoutineGeneratorButton({
    super.key,
    required this.hasNoTasks,
    required this.isGenerating,
    required this.onTap,
  });

  final bool hasNoTasks;
  final bool isGenerating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!hasNoTasks) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: OutlinedButton.icon(
          onPressed: isGenerating ? null : onTap,
          icon: isGenerating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.lilac,
                  ),
                )
              : const Icon(Icons.auto_awesome, size: 16, color: AppColors.lilac),
          label: Text(isGenerating ? 'Generating…' : 'Refresh AI Routine'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.lilac,
            side: const BorderSide(color: AppColors.lilac),
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: isGenerating ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lilacSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lilac.withAlpha(60)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.lilac,
                  shape: BoxShape.circle,
                ),
                child: isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGenerating ? 'Generating...' : 'Generate AI Routine',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.lilac700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isGenerating
                          ? 'Building personalized care plan...'
                          : 'Get daily, weekly & monthly tasks tailored for your pet',
                      style: const TextStyle(
                        color: AppColors.lilac700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isGenerating) const Icon(Icons.chevron_right, color: AppColors.lilac),
            ],
          ),
        ),
      ),
    );
  }
}
