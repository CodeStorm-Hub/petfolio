import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/audit_logs_provider.dart';

class AuditLogsTab extends ConsumerWidget {
  const AuditLogsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(auditLogsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Audit Logs',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'System-wide administrative actions and events.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink500,
                    ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.line),
        Expanded(
          child: state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text(
                'Error loading audit logs: \$err',
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
            data: (logs) {
              if (logs.isEmpty) {
                return Center(
                  child: Text(
                    'No audit logs available.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.ink500,
                        ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: logs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface0,
                      borderRadius: BorderRadius.circular(
                        PetfolioThemeExtension.radiusMd,
                      ),
                      border: Border.all(color: AppColors.line),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.lilac.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.history_rounded,
                            color: AppColors.lilac,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    log.action.toUpperCase(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  Text(
                                    _formatDate(log.createdAt),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.ink500,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'By: ${log.adminName ?? 'Unknown Admin'}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Entity: ${log.entityType}${log.entityId != null ? ' (${log.entityId})' : ''}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.ink700,
                                    ),
                              ),
                              if (log.details != null && log.details!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface1,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  width: double.infinity,
                                  child: Text(
                                    log.details.toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontFamily: 'monospace',
                                          color: AppColors.ink700,
                                        ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    String pad(int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${pad(local.month)}-${pad(local.day)} ${pad(local.hour)}:${pad(local.minute)}';
  }
}
