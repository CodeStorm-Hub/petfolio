import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/router/transitions.dart';
import '../marketplace/presentation/controllers/address_controller.dart';
import '../marketplace/presentation/widgets/address_sheet.dart';
import 'presentation/screens/settings_screen.dart';
import '../marketplace/data/models/user_address.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

List<GoRoute> settingsRoutes(GlobalKey<NavigatorState> rootKey) => [
      GoRoute(
        path: '/settings',
        parentNavigatorKey: rootKey,
        pageBuilder: (_, state) => pushPage(key: state.pageKey, child: const SettingsScreen()),
      ),
      GoRoute(
        path: '/settings/addresses',
        parentNavigatorKey: rootKey,
        pageBuilder: (_, state) => pushPage(key: state.pageKey, child: const _AddressManagementScreen()),
      ),
    ];

class _AddressManagementScreen extends ConsumerWidget {
  const _AddressManagementScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final addressesAsync = ref.watch(addressListProvider);
    final selected = ref.watch(selectedAddressProvider);

    return Scaffold(
      backgroundColor: isDark ? pt.surface1 : const Color(0xFFF2F3F7),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: pt.ink950,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Saved Addresses',
                    style: GoogleFonts.sora(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: pt.ink950,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => AddAddressSheet.show(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.poppy,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: addressesAsync.when(
                loading: () => const Center(child: TailWagLoader()),
                error: (e, _) => Center(child: Text('$e')),
                data: (addresses) {
                  if (addresses.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('📍', style: TextStyle(fontSize: 56)),
                          const SizedBox(height: 16),
                          Text(
                            'No saved addresses',
                            style: GoogleFonts.sora(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: pt.ink950,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add a delivery address to checkout faster.',
                            style: TextStyle(fontSize: 13, color: pt.ink500),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () => AddAddressSheet.show(context),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add New Address'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.poppy,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      16, 12, 16,
                      MediaQuery.paddingOf(context).bottom + 32,
                    ),
                    itemCount: addresses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final addr = addresses[i];
                      return _AddressCard(
                        address: addr,
                        isSelected: selected?.id == addr.id,
                        isDark: isDark,
                        pt: pt,
                        onSetDefault: () => ref
                            .read(addressListProvider.notifier)
                            .setDefault(addr.id),
                        onDelete: () => ref
                            .read(addressListProvider.notifier)
                            .deleteAddress(addr.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.isSelected,
    required this.isDark,
    required this.pt,
    required this.onSetDefault,
    required this.onDelete,
  });

  final UserAddress address;
  final bool isSelected;
  final bool isDark;
  final PetfolioThemeExtension pt;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? pt.surface2 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.poppy : pt.line,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Text(address.labelEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      address.labelName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: pt.ink950,
                      ),
                    ),
                    if (address.isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.mint.withAlpha(25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Default',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.mint700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  address.displayLine2,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: pt.ink500),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, size: 18, color: pt.ink500),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (v) {
              if (v == 'default') onSetDefault();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              if (!address.isDefault)
                const PopupMenuItem(
                  value: 'default',
                  child: Text('Set as default'),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete',
                    style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
