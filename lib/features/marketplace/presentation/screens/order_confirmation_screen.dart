import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_pill_button.dart';
import '../../../../core/theme/app_theme.dart';


// ─────────────────────────────────────────────────────────────────────────────
// OrderConfirmationScreen — shown after successful payment
// ─────────────────────────────────────────────────────────────────────────────

class OrderConfirmationScreen extends StatefulWidget {
  const OrderConfirmationScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 0.7, curve: Curves.elasticOut),
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Interval(0.4, 1.0, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    // bottom: false — we add bottomPad manually so SafeArea doesn't
    // double-count the home-indicator inset.
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: ClampingScrollPhysics(),
          child: ConstrainedBox(
            // On tall devices the Column fills the screen (Spacers absorb space).
            // On very short devices (≤ 568 dp) the content scrolls instead of
            // overflowing.
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).top,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: EdgeInsets.fromLTRB(32, 0, 32, bottomPad + 24),
                child: Column(
                  children: [
                    Spacer(),

                    // Success badge
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: pt.success.withAlpha(26),
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 56,
                          color: pt.success,
                        ),
                      ),
                    ),
                    SizedBox(height: 32),

                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(
                        children: [
                          Text(
                            'Order placed!',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 28,
                              letterSpacing: -0.28,
                              color: pt.ink950,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Your order is confirmed and will\narrive within 3–5 business days.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          SizedBox(height: 24),

                          // Order reference chip
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: pt.surface2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.receipt_long_outlined,
                                    size: 16, color: Color(0xFF64748B)),
                                SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ORDER REFERENCE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    Text(
                                      widget.orderId.substring(0, 8).toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: pt.ink950,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Spacer(),

                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(
                        children: [
                          PrimaryPillButton(
                            label: 'Continue shopping',
                            size: PillButtonSize.lg,
                            isFullWidth: true,
                            onPressed: () => context.go('/marketplace'),
                          ),
                          SizedBox(height: 12),
                          PrimaryPillButton(
                            label: 'View Order',
                            size: PillButtonSize.lg,
                            isFullWidth: true,
                            onPressed: () => context.go('/marketplace/orders/${widget.orderId}'),
                          ),
                          SizedBox(height: 12),
                          TextButton(
                            onPressed: () => context.go('/home'),
                            child: Text(
                              'Back to home',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
