/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:flutter/material.dart';
import '../utils/index.dart';
import 'package:bagisto_app_demo/widgets/blinkit_product_card.dart';
import 'package:bagisto_app_demo/widgets/blinkit_vertical_product_card.dart';

class NewProductView extends StatefulWidget {
  final List<dynamic>? model;
  final String title;
  final bool? isLogin;
  final bool isRecentProduct;
  final bool callPreCache;
  final bool useGrid;
  
  final void Function(int id)? onAddToCart;
  // 🟢 UPDATED: Now accepts 'product' (dynamic) as the 3rd argument
  final void Function(String id, bool isInWishlist, dynamic product)? onAddToWishlist;

  const NewProductView({
    Key? key,
    this.model,
    required this.title,
    this.isLogin,
    this.isRecentProduct = false,
    this.callPreCache = false,
    this.useGrid = false,
    this.onAddToCart,
    this.onAddToWishlist,
  }) : super(key: key);

  @override
  State<NewProductView> createState() => _NewProductViewState();
}

class _NewProductViewState extends State<NewProductView> {
  final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    final items = widget.model ?? const [];

    if (widget.useGrid) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.46, // 🟢 Reduced to 0.46 to give more height and prevent overflow
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return BlinkitVerticalProductCard(
            data: items[index],
            onAddToCart: widget.onAddToCart,
            onAddToWishlist: widget.onAddToWishlist,
            width: double.infinity, // Let grid constraints handle width
          );
        },
      );
    }

    return Container(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.secondaryContainer,
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
          ]),
          const SizedBox(height: AppSizes.spacingMedium),
          SizedBox(
            height: 230, // 🟢 Increased to 230 to prevent bottom overflow
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              controller: _controller,
              padding: const EdgeInsets.symmetric(horizontal: 16), // Increased for alignment
              itemCount: items.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 12), // 🟢 Gap between cards
                child: SizedBox(
                  width: 160, // Slightly reduced to match card width logic
                  child: BlinkitVerticalProductCard(
                    data: items[index],
                    onAddToCart: widget.onAddToCart,
                    onAddToWishlist: widget.onAddToWishlist,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// Removed Local _ProductCard Class
