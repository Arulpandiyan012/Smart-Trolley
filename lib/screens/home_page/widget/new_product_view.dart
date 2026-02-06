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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.48, // 🟢 Adjusted to 0.48 to fix 15px bottom overflow
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
      margin: const EdgeInsets.symmetric(vertical: AppSizes.spacingNormal),
      color: Theme.of(context).colorScheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
          ]),
          const SizedBox(height: AppSizes.spacingMedium),
          SizedBox(
            height: 320, // 🟢 Increased from 280 to 320 to prevent overflow 
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              controller: _controller,
              itemCount: items.length,
              itemBuilder: (context, index) => SizedBox(
                width: 170, // 🟢 Increased width (was 150)
                child: BlinkitVerticalProductCard(
                  data: items[index],
                  onAddToCart: widget.onAddToCart,
                  onAddToWishlist: widget.onAddToWishlist,
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
