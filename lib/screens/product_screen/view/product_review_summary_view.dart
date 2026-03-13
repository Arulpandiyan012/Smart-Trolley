/*
 *   Webkul Software.
 *   @package Mobikul Application Code.
 *   @Category Mobikul
 *   @author Webkul <support@webkul.com>
 *   @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 *   @license https://store.webkul.com/license.html
 *   @link https://store.webkul.com/license.html
 */

import 'package:bagisto_app_demo/screens/product_screen/utils/index.dart';

class ProductReviewSummaryView extends StatefulWidget {
  final List<Reviews>? review;
  final String? productId;
  final String? averageRating;
  final dynamic percentage;
  final String? productName;
  final String? productImage;
  final bool? isLogin;

  const ProductReviewSummaryView({
    Key? key,
    this.review,
    this.productName,
    this.productImage,
    this.averageRating,
    this.percentage,
    this.productId,
    this.isLogin,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => ProductReviewSummaryViewState();
}

class ProductReviewSummaryViewState extends State<ProductReviewSummaryView> {
  dynamic percentage;
  bool _showAll = false;

  @override
  void initState() {
    percentage = (widget.percentage.toString()) != "[]"
        ? json.decode(widget.percentage.toString())
        : [];
    super.initState();
  }

  String _getInitial(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    return name.trim()[0].toUpperCase();
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviews = widget.review ?? [];
    final hasReviews = reviews.isNotEmpty;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        iconColor: Theme.of(context).iconTheme.color,
        collapsedIconColor: Theme.of(context).iconTheme.color,
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingLarge),
        title: Text(
          StringConstants.customerRating.localized(),
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        initiallyExpanded: true,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Rating Summary ─────────────────────────────────────────
                if (hasReviews) ...[
                  _buildRatingSummary(reviews),
                  const SizedBox(height: 12),
                  const Divider(),
                ],

                // ── Write a Review Button ──────────────────────────────────
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF27C16B), width: 1.2),
                    backgroundColor: const Color(0xFFF0FDF4),
                    foregroundColor: const Color(0xFF27C16B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  onPressed: () {
                    widget.isLogin ?? false
                        ? Navigator.pushNamed(context, addReviewScreen,
                            arguments: AddReviewDetail(
                                imageUrl: widget.productImage,
                                productId: widget.productId,
                                productName: widget.productName))
                        : ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(StringConstants.pleaseLoginReview.localized()),
                            duration: const Duration(seconds: 3),
                          ));
                  },
                  icon: const Icon(Icons.edit_note, size: 20),
                  label: Text(
                    StringConstants.writeReview.localized().toUpperCase(),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ),

                // ── Review Cards ───────────────────────────────────────────
                if (hasReviews) ...[
                  const SizedBox(height: 16),
                  Text(
                    "${reviews.length} Customer Review${reviews.length != 1 ? 's' : ''}",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...(_showAll ? reviews : reviews.take(3).toList())
                      .map((item) => _buildReviewCard(context, item))
                      .toList(),

                  if (reviews.length > 3)
                    TextButton(
                      onPressed: () => _showAll
                          ? _showAllReviewsSheet(context)
                          : setState(() => _showAll = true),
                      child: Text(
                        _showAll
                            ? "See all ${reviews.length} reviews →"
                            : "View all ${reviews.length} reviews",
                        style: const TextStyle(
                          color: Color(0xFF27C16B),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],

                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary(List<Reviews> reviews) {
    final avg = double.tryParse(widget.averageRating?.toString() ?? '0') ?? 0.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          children: [
            Text(
              avg.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).textTheme.headlineLarge?.color,
                height: 1.0,
              ),
            ),
            RatingBar(
              starCount: 5,
              rating: avg,
              color: const Color(0xFFFFA000),
              size: 16,
            ),
            const SizedBox(height: 2),
            Text(
              "${reviews.length} review${reviews.length != 1 ? 's' : ''}",
              style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: ReviewLinearProgressIndicator(percentage: percentage),
        ),
      ],
    );
  }

  Widget _buildReviewCard(BuildContext context, Reviews item) {
    final name = item.customerName?.isNotEmpty == true ? item.customerName! : 'Customer';
    final initial = _getInitial(name);
    final rating = double.tryParse(item.rating?.toString() ?? '0') ?? 0.0;

    Color ratingColor;
    if (rating >= 4) {
      ratingColor = const Color(0xFF388E3C);
    } else if (rating >= 3) {
      ratingColor = const Color(0xFFF57C00);
    } else {
      ratingColor = const Color(0xFFC62828);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Avatar + Name/Badge + Date
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF667EEA).withOpacity(0.15),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Color(0xFF667EEA),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Theme.of(context).textTheme.titleSmall?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Compact rating badge (Flipkart style)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ratingColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.rating?.toString() ?? '-',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.star, size: 10, color: Colors.white),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Verified Buyer badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF27C16B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified, size: 10, color: Color(0xFF27C16B)),
                              const SizedBox(width: 2),
                              const Text(
                                "Verified",
                                style: TextStyle(
                                  color: Color(0xFF27C16B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Date
              if (item.createdAt?.isNotEmpty == true)
                Text(
                  _formatDate(item.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Review title
          if (item.title?.isNotEmpty == true) ...[
            Text(
              item.title!,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            const SizedBox(height: 4),
          ],

          // Review comment
          if (item.comment?.isNotEmpty == true)
            Text(
              item.comment!,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.85),
              ),
            ),
        ],
      ),
    );
  }

  void _showAllReviewsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.96,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        "All Reviews (${widget.review?.length ?? 0})",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: widget.review?.length ?? 0,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      return _buildReviewCard(context, widget.review![index]);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
