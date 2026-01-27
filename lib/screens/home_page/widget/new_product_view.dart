/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:flutter/material.dart';
import '../utils/index.dart';

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
    super.key,
    this.model,
    required this.title,
    this.isLogin,
    this.isRecentProduct = false,
    this.callPreCache = false,
    this.useGrid = false,
    this.onAddToCart,
    this.onAddToWishlist,
  });

  @override
  State<NewProductView> createState() => _NewProductViewState();
}

class _NewProductViewState extends State<NewProductView> {
  final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    final items = widget.model ?? const [];

    if (widget.useGrid) {
      return SizedBox(
        height: 150,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final val = items[index];
            return SizedBox(
              width: 120,
              child: _ProductCard(
                data: val,
                onAddToCart: widget.onAddToCart,
                onAddToWishlist: widget.onAddToWishlist,
              ),
            );
          },
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSizes.spacingNormal),
      color: Theme.of(context).colorScheme.secondaryContainer,
      padding: const EdgeInsets.all(AppSizes.spacingNormal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
          ]),
          const SizedBox(height: AppSizes.spacingMedium),
          SizedBox(
            height: AppSizes.screenHeight * 0.30,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              controller: _controller,
              itemCount: items.length,
              itemBuilder: (context, index) => SizedBox(
                width: AppSizes.screenWidth * 0.52,
                child: _ProductCard(
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

class _ProductCard extends StatelessWidget {
  final dynamic data;
  final void Function(int id)? onAddToCart;
  // 🟢 UPDATED definition
  final void Function(String id, bool isInWishlist, dynamic product)? onAddToWishlist;

  const _ProductCard({super.key, required this.data, this.onAddToCart, this.onAddToWishlist});

  String? _imageFromAny(dynamic img) {
    if (img == null) return null;
    try { if (img.url is String && img.url.isNotEmpty) return img.url; } catch (_) {}
    try { if (img.imageUrl is String && img.imageUrl.isNotEmpty) return img.imageUrl; } catch (_) {}
    try { if (img.path is String && img.path.isNotEmpty) return img.path; } catch (_) {}
    return null;
  }

  String? _productImage(dynamic p) {
    try {
      final imgs = (p as dynamic).images;
      if (imgs is List && imgs.isNotEmpty) {
        final u = _imageFromAny(imgs.first);
        if (u != null && u.isNotEmpty) return u;
      }
    } catch (_) {}
    try {
      final v = (p as dynamic).baseImage?.url;
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}
    return null;
  }

  String _productPrice(dynamic p) {
     dynamic ph;
     try { ph = (p as dynamic).priceHtml; } catch (_) {}
     
     try {
       final f = (ph as dynamic)?.formattedFinalPrice?.toString();
       if (f != null) return f;
     } catch (_) {}
     
     final sym = "₹";
     try {
       final val = (p as dynamic).price;
       if (val != null) return "$sym$val";
     } catch (_) {}
     
     return "";
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _productImage(data);
    final name = (data as dynamic).name?.toString() ?? "";
    final priceText = _productPrice(data);
    final productId = int.tryParse((data as dynamic).id?.toString() ?? '0') ?? 0;
    
    // Check Wishlist Status
    bool isInWishlist = (data as dynamic).isInWishlist ?? false;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.pushNamed(
          context,
          productScreen,
          arguments: PassProductData(
            title: name,
            urlKey: (data as dynamic).urlKey,
            productId: productId,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4F1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  height: 90,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE2E8E4),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  alignment: Alignment.center,
                  child: (imageUrl != null && imageUrl.isNotEmpty)
                      ? ImageView(
                          url: imageUrl,
                          fit: BoxFit.contain,
                          height: 70,
                          width: 70,
                        )
                      : const Icon(Icons.image, size: 44, color: Colors.grey),
                ),

                // 🟢 Wishlist Button
                Positioned(
                  top: 6,
                  right: 6,
                  child: InkWell(
                    onTap: () {
                       if (onAddToWishlist != null) {
                         // 🟢 PASS THE DATA OBJECT SO IT CAN BE UPDATED
                         onAddToWishlist!(productId.toString(), isInWishlist, data);
                       }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                           BoxShadow(color: Colors.black12, blurRadius: 2)
                        ]
                      ),
                      child: Icon(
                        isInWishlist ? Icons.favorite : Icons.favorite_border, 
                        size: 14, 
                        // 🟢 Dynamic Color
                        color: isInWishlist ? Colors.red : Colors.grey
                      ),
                    ),
                  ),
                ),

                if (priceText.isNotEmpty)
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        priceText,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.0,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),

                Positioned(
                  right: 6,
                  bottom: 6,
                  child: InkWell(
                    onTap: () => onAddToCart?.call(productId),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.add, size: 13, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.10,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}