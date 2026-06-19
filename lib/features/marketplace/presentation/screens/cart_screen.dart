import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/petfolio_empty_state.dart';
import '../../data/models/cart_item.dart';
import '../../data/models/promo.dart';
import '../../data/repositories/promo_repository.dart';
import '../controllers/address_controller.dart';
import '../widgets/address_sheet.dart';
import '../../data/models/marketplace_order.dart';
import '../controllers/cart_controller.dart';
import '../controllers/checkout_controller.dart';
import '../controllers/shop_list_controller.dart';
import '../widgets/cart_line_item.dart';
import '../widgets/web_checkout_resume_listener.dart';

const _petfolioOfficialShopId = 'cccccccc-0000-0000-0000-cccccccccccc';

// ─────────────────────────────────────────────────────────────────────────────
// CartScreen — Phase 4: Pathao stacked-section-card checkout layout
// ─────────────────────────────────────────────────────────────────────────────

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final shopsAsync = ref.watch(shopListProvider);
    final verifiedShopIds = shopsAsync.value?.map((s) => s.id).toSet() ?? {};

    ref.listen(checkoutProvider, (_, next) {
      if (next.status == CheckoutStatus.success && next.orderId != null) {
        context.pushReplacement('/marketplace/order/${next.orderId}');
        ref.read(checkoutProvider.notifier).reset();
      }
      if (next.status == CheckoutStatus.failure && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        );
        ref.read(checkoutProvider.notifier).reset();
      }
    });

    final groups = cart.itemsByShop.entries.toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surface1D : AppColors.surface3;

    return WebCheckoutResumeListener(
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────────
              _CartHeader(
                itemCount: cart.itemCount,
                onBack: () => context.pop(),
                onClear: cart.isEmpty
                    ? null
                    : () => ref.read(cartProvider.notifier).clear(),
              ),

              // ── Body ────────────────────────────────────────────────────────
              Expanded(
                child: cart.isEmpty
                    ? const PetfolioEmptyState(
                        icon: Icons.shopping_bag_outlined,
                        title: 'Your cart is empty',
                        subtitle: 'Browse the shop to find food, gear, treats and more.',
                      )
                    : ListView(
                        padding: EdgeInsets.fromLTRB(
                          16, 8, 16,
                          32 + MediaQuery.paddingOf(context).bottom,
                        ),
                        children: [
                          // Multi-vendor summary banner (2+ shops only)
                          if (groups.length > 1) ...[
                            _MultiVendorSummaryBanner(
                              shopCount: groups.length,
                              totalFormatted: cart.totalFormatted,
                              itemCount: cart.itemCount,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 10),
                          ],

                          // Shared deliver-to card (once at top)
                          _DeliverToCard(isDark: isDark),
                          const SizedBox(height: 10),

                          // Per-vendor stacked sections
                          for (final entry in groups) ...[
                            _VendorCheckoutSection(
                              shopId: entry.key,
                              shopName: entry.value.first.product.shopName.trim().isNotEmpty
                                  ? entry.value.first.product.shopName
                                  : 'Shop',
                              items: entry.value,
                              canCheckout: entry.key == _petfolioOfficialShopId ||
                                  verifiedShopIds.contains(entry.key),
                              isDark: isDark,
                            ),
                            if (entry.key != groups.last.key)
                              const SizedBox(height: 20),
                          ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Cart header
// ─────────────────────────────────────────────────────────────────────────────

class _CartHeader extends StatelessWidget {
  const _CartHeader({
    required this.itemCount,
    required this.onBack,
    required this.onClear,
  });

  final int itemCount;
  final VoidCallback onBack;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
      final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          _IconBtn(icon: Icons.arrow_back_ios_new_rounded, label: 'Back', onTap: onBack),
          const SizedBox(width: 12),
          Text(
            'Your Cart',
            style: GoogleFonts.sora(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: pt.ink950,
            ),
          ),
          if (itemCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.mint.withAlpha(30),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$itemCount item${itemCount == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mint700,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (onClear != null)
            TextButton(
              onPressed: onClear,
              child: const Text(
                'Clear',
                style: TextStyle(fontSize: 13, color: AppColors.danger),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Deliver To card — shared across all vendor groups
// ─────────────────────────────────────────────────────────────────────────────

class _DeliverToCard extends ConsumerWidget {
  const _DeliverToCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedAddressProvider);
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return _SectionCard(
      isDark: isDark,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          AddressSheet.show(context);
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.mint.withAlpha(isDark ? 50 : 25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      size: 20,
                      color: AppColors.mint,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DELIVER TO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                            color: pt.ink500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          selected != null
                              ? selected.displayLine1
                              : 'Add your delivery address',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: pt.ink950,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    selected != null ? 'Change' : 'Add',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.poppy,
                    ),
                  ),
                ],
              ),
              if (selected != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 54),
                  child: Text(
                    selected.displayLine2,
                    style: TextStyle(fontSize: 12, color: pt.ink500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// One vendor's complete checkout section — stacked cards + Place Order CTA
// ─────────────────────────────────────────────────────────────────────────────

class _VendorCheckoutSection extends ConsumerStatefulWidget {
  const _VendorCheckoutSection({
    required this.shopId,
    required this.shopName,
    required this.items,
    required this.canCheckout,
    required this.isDark,
  });

  final String shopId;
  final String shopName;
  final List<CartItem> items;
  final bool canCheckout;
  final bool isDark;

  @override
  ConsumerState<_VendorCheckoutSection> createState() =>
      _VendorCheckoutSectionState();
}

class _VendorCheckoutSectionState
    extends ConsumerState<_VendorCheckoutSection> {
  PaymentMethod _method = PaymentMethod.sslcommerz;
  final _promoCtrl = TextEditingController();
  bool _promoExpanded = false;
  bool _promoApplied = false;
  bool _promoLoading = false;
  Promo? _appliedPromo;

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyPromo(int subtotalCents) async {
    final code = _promoCtrl.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(_snack('Enter a promo code first', error: true));
      return;
    }
    setState(() => _promoLoading = true);
    try {
      final promo = await ref.read(promoRepositoryProvider).validateCode(code);
      if (!mounted) return;
      if (promo == null) {
        ScaffoldMessenger.of(context).showSnackBar(_snack('Promo code not valid or expired', error: true));
        setState(() { _promoLoading = false; _promoExpanded = false; });
      } else if (subtotalCents < promo.minOrderCents) {
        final min = '\$${(promo.minOrderCents / 100).toStringAsFixed(0)}';
        ScaffoldMessenger.of(context).showSnackBar(_snack('Minimum order $min required for this code', error: true));
        setState(() { _promoLoading = false; _promoExpanded = false; });
      } else {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(_snack('${promo.discountLabel} applied!'));
        setState(() { _appliedPromo = promo; _promoApplied = true; _promoLoading = false; _promoExpanded = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _promoLoading = false; _promoExpanded = false; });
    }
  }

  SnackBar _snack(String msg, {bool error = false}) => SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.danger : AppColors.mint700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      );

  void _handleCheckout(int subtotalCents) {
    if (_method == PaymentMethod.cod) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _CodConfirmSheet(
          shopName: widget.shopName,
          items: widget.items,
          subtotalCents: subtotalCents,
          onConfirm: () {
            Navigator.pop(context);
            ref.read(checkoutProvider.notifier).startCodCheckoutForShop(widget.shopId);
          },
        ),
      );
    } else if (_method == PaymentMethod.bkash ||
               _method == PaymentMethod.nagad ||
               _method == PaymentMethod.sslcommerz) {
      ref.read(checkoutProvider.notifier).startSslcommerzCheckoutForShop(widget.shopId, _method);
    } else {
      ref.read(checkoutProvider.notifier).startCheckoutForShop(widget.shopId);
    }
  }

  @override
  Widget build(BuildContext context) {
      final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cart = ref.watch(cartProvider);
    final checkout = ref.watch(checkoutProvider);
    final subtotalCents = cart.totalCentsForShop(widget.shopId);
    final isLoading = checkout.isLoadingShop(widget.shopId);
    final shopItems = widget.items;
    final shopSavingsCents = shopItems.fold<int>(0, (s, i) => s + i.savingsCentsTotal);
    final deliveryCents = 0; // free delivery
    final promoCents = _appliedPromo == null ? 0 : _appliedPromo!.discountType == PromoDiscountType.percent
        ? (subtotalCents * _appliedPromo!.discountValue ~/ 100)
            .clamp(0, _appliedPromo!.maxDiscountCents ?? 999999)
        : _appliedPromo!.discountValue.clamp(0, subtotalCents);
    final totalCents = (subtotalCents + deliveryCents - promoCents).clamp(0, subtotalCents);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Your Products card ────────────────────────────────────────────
        _SectionCard(
          isDark: widget.isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shop header row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.tangerine.withAlpha(25),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.shopName.isNotEmpty
                            ? widget.shopName[0].toUpperCase()
                            : 'S',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.tangerine,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.shopName,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: pt.ink950,
                            ),
                          ),
                          Text(
                            'Est. delivery: 2-3 business days',
                            style: TextStyle(fontSize: 12, color: pt.ink500),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${shopItems.fold<int>(0, (s, i) => s + i.quantity)} items',
                      style: TextStyle(fontSize: 12, color: pt.ink500),
                    ),
                  ],
                ),
              ),

              // Not-ready-to-checkout warning
              if (!widget.canCheckout)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.warningSoft,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 16, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This shop is not ready to accept payments yet.',
                            style: TextStyle(fontSize: 12, color: pt.ink700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Line items
              for (final item in shopItems) CartLineItem(item: item),

              const SizedBox(height: 4),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ── Apply Promo card ──────────────────────────────────────────────
        _SectionCard(
          isDark: widget.isDark,
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _promoExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: InkWell(
              onTap: () => setState(() => _promoExpanded = true),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.mint.withAlpha(25),
                      ),
                      child: const Icon(
                        Icons.local_offer_outlined,
                        size: 18,
                        color: AppColors.mint,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _promoApplied
                            ? 'Promo code applied ✓'
                            : 'Apply promo code',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _promoApplied
                              ? AppColors.mint700
                              : AppColors.ink950,
                        ),
                      ),
                    ),
                    Icon(
                      _promoApplied
                          ? Icons.check_circle_rounded
                          : Icons.chevron_right_rounded,
                      color: _promoApplied ? AppColors.mint : AppColors.ink500,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promoCtrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Enter promo code',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: pt.ink500,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10,
                        ),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.mint,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _promoLoading ? null : () => _applyPromo(subtotalCents),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.mint,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10,
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ── Pay via card ──────────────────────────────────────────────────
        _SectionCard(
          isDark: widget.isDark,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.lilac.withAlpha(25),
                      ),
                      child: const Icon(
                        Icons.credit_card_rounded,
                        size: 18,
                        color: AppColors.lilac,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Pay via',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: pt.ink950,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _PaymentChip(
                            label: 'Card (BD)',
                            icon: Icons.credit_card_rounded,
                            selected: _method == PaymentMethod.sslcommerz,
                            onTap: () => setState(() => _method = PaymentMethod.sslcommerz),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PaymentChip(
                            label: "Int'l Card",
                            icon: Icons.language_rounded,
                            selected: _method == PaymentMethod.stripe,
                            onTap: () => setState(() => _method = PaymentMethod.stripe),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _PaymentChip(
                            label: 'bKash',
                            icon: Icons.phone_android_rounded,
                            selected: _method == PaymentMethod.bkash,
                            onTap: () => setState(() => _method = PaymentMethod.bkash),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PaymentChip(
                            label: 'Nagad',
                            icon: Icons.phone_android_rounded,
                            selected: _method == PaymentMethod.nagad,
                            onTap: () => setState(() => _method = PaymentMethod.nagad),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _PaymentChip(
                            label: 'Cash on Delivery',
                            icon: Icons.payments_outlined,
                            selected: _method == PaymentMethod.cod,
                            onTap: () => setState(() => _method = PaymentMethod.cod),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ── Receipt card ─────────────────────────────────────────────────
        _SectionCard(
          isDark: widget.isDark,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Receipt',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: pt.ink950,
                  ),
                ),
                const SizedBox(height: 12),
                _SumRow(
                  label: 'Total item price (${shopItems.fold<int>(0, (s, i) => s + i.quantity)} items)',
                  value: '\$${((subtotalCents + shopSavingsCents) / 100).toStringAsFixed(2)}',
                  labelColor: AppColors.ink500,
                ),
                if (shopSavingsCents > 0) ...[
                  const SizedBox(height: 6),
                  _SumRow(
                    label: 'Store Discount',
                    value: '- \$${(shopSavingsCents / 100).toStringAsFixed(2)}',
                    valueColor: AppColors.poppy,
                  ),
                ],
                const SizedBox(height: 6),
                _SumRow(
                  label: 'Subtotal',
                  value: '\$${(subtotalCents / 100).toStringAsFixed(2)}',
                ),
                if (promoCents > 0) ...[
                  const SizedBox(height: 6),
                  _SumRow(
                    label: 'Promo (${_appliedPromo!.code})',
                    value: '- \$${(promoCents / 100).toStringAsFixed(2)}',
                    valueColor: AppColors.mint700,
                  ),
                ],
                const SizedBox(height: 6),
                _SumRow(
                  label: 'Delivery Charge',
                  value: deliveryCents == 0 ? 'Free' : '\$${(deliveryCents / 100).toStringAsFixed(2)}',
                  valueColor: deliveryCents == 0 ? AppColors.mint700 : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Divider(
                    height: 1,
                    color: widget.isDark
                        ? Colors.white.withAlpha(14)
                        : AppColors.line,
                  ),
                ),
                _SumRow(
                  label: 'Total',
                  value: '\$${(totalCents / 100).toStringAsFixed(2)}',
                  bold: true,
                  valueFontSize: 18,
                ),
              ],
            ),
          ),
        ),

        // ── Green savings banner ──────────────────────────────────────────
        if (shopSavingsCents > 0) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  AppColors.mint.withAlpha(widget.isDark ? 50 : 35),
                  AppColors.mint.withAlpha(widget.isDark ? 30 : 20),
                ],
              ),
              border: Border.all(
                color: AppColors.mint.withAlpha(widget.isDark ? 70 : 60),
              ),
            ),
            child: Row(
              children: [
                const Text('🎉', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You are saving \$${(shopSavingsCents / 100).toStringAsFixed(2)} on this order!',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mint700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 14),

        // ── Place Order CTA ───────────────────────────────────────────────
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: widget.canCheckout && !isLoading
                ? () {
                    HapticFeedback.mediumImpact();
                    _handleCheckout(subtotalCents);
                  }
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: widget.canCheckout
                  ? AppColors.poppy
                  : AppColors.ink300,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.ink300,
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        switch (_method) {
                          PaymentMethod.cod        => Icons.payments_outlined,
                          PaymentMethod.bkash ||
                          PaymentMethod.nagad      => Icons.phone_android_rounded,
                          PaymentMethod.sslcommerz => Icons.credit_card_rounded,
                          _                        => Icons.lock_outline_rounded,
                        },
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        switch (_method) {
                          PaymentMethod.cod        => 'Place Order (COD)',
                          PaymentMethod.bkash      => 'Pay with bKash',
                          PaymentMethod.nagad      => 'Pay with Nagad',
                          PaymentMethod.sslcommerz => 'Pay with Card (BD)',
                          _                        => 'Pay · \$${(totalCents / 100).toStringAsFixed(2)}',
                        },
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Multi-vendor summary banner — shown at top when cart has items from 2+ shops
// ─────────────────────────────────────────────────────────────────────────────

class _MultiVendorSummaryBanner extends StatelessWidget {
  const _MultiVendorSummaryBanner({
    required this.shopCount,
    required this.totalFormatted,
    required this.itemCount,
    required this.isDark,
  });

  final int shopCount;
  final String totalFormatted;
  final int itemCount;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
      final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.surface0D, AppColors.surface2D]
              : [AppColors.poppy.withAlpha(18), AppColors.tangerine.withAlpha(12)],
        ),
        border: Border.all(
          color: AppColors.poppy.withAlpha(isDark ? 60 : 40),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.poppy.withAlpha(isDark ? 50 : 25),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              size: 20,
              color: AppColors.poppy,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ordering from $shopCount shops',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: pt.ink950,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$itemCount item${itemCount == 1 ? '' : 's'} · Each shop ships separately',
                  style: TextStyle(fontSize: 12, color: pt.ink500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                totalFormatted,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.poppy,
                ),
              ),
              Text(
                'combined',
                style: TextStyle(fontSize: 10, color: pt.ink500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable section card — white elevated card with warm shadow
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, required this.isDark});
  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? AppColors.surface0D : Colors.white,
        boxShadow: isDark
            ? null
            : [
                const BoxShadow(
                  color: AppColors.shadowE3L,
                  blurRadius: 18,
                  offset: Offset(0, 4),
                  spreadRadius: -2,
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Order summary row
// ─────────────────────────────────────────────────────────────────────────────

class _SumRow extends StatelessWidget {
  const _SumRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueFontSize = 14,
    this.valueColor,
    this.labelColor,
  });

  final String label;
  final String value;
  final bool bold;
  final double valueFontSize;
  final Color? valueColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: labelColor ?? (bold ? AppColors.ink950 : AppColors.ink500),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w700,
            fontSize: valueFontSize,
            color: valueColor ?? (bold ? AppColors.ink950 : AppColors.ink700),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment method chip
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label${selected ? ", selected" : ""}',
      button: true,
      child: GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? AppColors.lilac.withAlpha(20) : AppColors.surface1,
          border: Border.all(
            color: selected ? AppColors.lilac : AppColors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.lilac : AppColors.ink500,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.lilac700 : AppColors.ink700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COD confirm bottom sheet — unchanged logic, cleaner styling
// ─────────────────────────────────────────────────────────────────────────────

class _CodConfirmSheet extends StatelessWidget {
  const _CodConfirmSheet({
    required this.shopName,
    required this.items,
    required this.subtotalCents,
    required this.onConfirm,
  });

  final String shopName;
  final List<CartItem> items;
  final int subtotalCents;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
      final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface0D : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: AppColors.line2,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Confirm Order',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: pt.ink950,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                shopName,
                style: TextStyle(fontSize: 13, color: pt.ink500),
              ),
              const SizedBox(height: 16),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.product.name} × ${item.quantity}',
                          style: TextStyle(
                              fontSize: 13, color: pt.ink700),
                        ),
                      ),
                      Text(
                        '\$${((item.product.priceCents * item.quantity) / 100).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: pt.ink950,
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 24, color: AppColors.line),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: pt.ink950,
                    ),
                  ),
                  Text(
                    '\$${(subtotalCents / 100).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: pt.ink950,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.warningSoft,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payments_outlined,
                        size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pay when you receive your order.',
                        style: TextStyle(fontSize: 12, color: pt.ink700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Place Order'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.poppy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Icon button helper
// ─────────────────────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap, required this.label});

  final IconData icon;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
      final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface0,
          boxShadow: [
            BoxShadow(color: AppColors.line, spreadRadius: 0.5),
            BoxShadow(
              color: AppColors.shadowE1L,
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: pt.ink700),
      ),
    ),
    );
  }
}
