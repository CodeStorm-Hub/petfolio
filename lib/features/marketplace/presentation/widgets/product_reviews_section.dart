import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/product_review.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/primary_pill_button.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../data/models/product.dart';
import '../controllers/product_reviews_controller.dart';
import 'star_rating_widget.dart';

class ProductReviewsSection extends ConsumerWidget {
  const ProductReviewsSection({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(productReviewsProvider(product.id));
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Reviews',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: pt.ink950,
              ),
            ),
            const Spacer(),
            if (product.rating != null)
              StarRatingWidget(
                rating: product.rating!,
                size: 16,
                semanticLabel:
                    '${product.rating!.toStringAsFixed(1)} average from ${product.reviewCount ?? 0} ${(product.reviewCount ?? 0) == 1 ? 'review' : 'reviews'}',
              ),
          ],
        ),
        const SizedBox(height: 12),
        PrimaryPillButton(
          label: 'Write a review',
          size: PillButtonSize.md,
          variant: PillButtonVariant.soft,
          isFullWidth: true,
          leadingIcon: Icon(Icons.rate_review_outlined, color: pt.ink950),
          onPressed: () => _openReviewSheet(context, ref),
        ),
        const SizedBox(height: 16),
        reviewsAsync.when(
          loading: () => Column(
            children: List.generate(
              2,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: SkeletonLoader(width: double.infinity, height: 72),
              ),
            ),
          ),
          error: (_, _) => Text(
            'Could not load reviews',
            style: TextStyle(color: pt.ink500),
          ),
          data: (reviews) {
            if (reviews.isEmpty) {
              return Text(
                'No reviews yet — be the first to share your experience.',
                style: TextStyle(color: pt.ink500, height: 1.45),
              );
            }
            return Column(
              children: [
                for (final review in reviews.take(8))
                  _ReviewTile(review: review, pt: pt),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _openReviewSheet(BuildContext context, WidgetRef ref) async {
    final own = await ref.read(ownProductReviewProvider(product.id).future);
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ReviewSheet(
        productId: product.id,
        initialRating: own?.rating ?? 5,
        initialBody: own?.body ?? '',
      ),
    );
  }
}

class _ReviewSheet extends ConsumerStatefulWidget {
  const _ReviewSheet({
    required this.productId,
    required this.initialRating,
    required this.initialBody,
  });

  final String productId;
  final int initialRating;
  final String initialBody;

  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet> {
  late int _rating = widget.initialRating;
  late final TextEditingController _bodyCtrl =
      TextEditingController(text: widget.initialBody);
  bool _saving = false;

  @override
  void dispose() {
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await ref.read(productReviewsProvider(widget.productId).notifier).submitReview(
            rating: _rating,
            body: _bodyCtrl.text,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) AppSnackBar.showError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: pt.line,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Rate this product',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: pt.ink950,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: StarRatingWidget(
              rating: _rating.toDouble(),
              size: 36,
              onRatingChanged: (v) => setState(() => _rating = v),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bodyCtrl,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: 'Your review (optional)',
              hintText: 'What did your pet think?',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: pt.line),
              ),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryPillButton(
            label: 'Submit review',
            isLoading: _saving,
            isFullWidth: true,
            onPressed: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review, required this.pt});

  final ProductReview review;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pt.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StarRatingWidget(rating: review.rating.toDouble(), size: 14),
              const Spacer(),
              Text(
                formatTimeAgo(review.createdAt),
                style: TextStyle(fontSize: 11, color: pt.ink500),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            review.isOwn ? 'Your review' : 'Verified buyer',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: review.isOwn ? AppColors.lilac700 : pt.ink500,
            ),
          ),
          if (review.body != null && review.body!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              review.body!,
              style: TextStyle(fontSize: 14, height: 1.45, color: pt.ink950),
            ),
          ],
        ],
      ),
    );
  }
}
