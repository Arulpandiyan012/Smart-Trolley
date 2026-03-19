import 'package:flutter/material.dart';
import 'package:bagisto_app_demo/utils/index.dart'; 
import 'package:bagisto_app_demo/utils/app_global_data.dart'; 
import 'package:bagisto_app_demo/widgets/image_view.dart';
import 'package:bagisto_app_demo/screens/home_page/utils/route_argument_helper.dart';
import 'package:bagisto_app_demo/utils/app_global_data.dart';

class BlinkitVerticalProductCard extends StatelessWidget {
  final dynamic data;
  final void Function(int id)? onAddToCart;
  final void Function(String id, bool isInWishlist, dynamic product)? onAddToWishlist;
  final double width;
  final bool? isLoggedIn;

  const BlinkitVerticalProductCard({
    Key? key, 
    required this.data, 
    this.onAddToCart, 
    this.onAddToWishlist,
    this.width = 150.0,
    this.isLoggedIn,
  }) : super(key: key);

  String? _imageFromAny(dynamic img) {
    if (img == null) return null;
    try { if (img.url is String && img.url.isNotEmpty) return img.url; } catch (_) {}
    try { if (img.imageUrl is String && img.imageUrl.isNotEmpty) return img.imageUrl; } catch (_) {}
    try { if (img.path is String && img.path.isNotEmpty) return img.path; } catch (_) {}
    return null;
  }

  String? _productImage(dynamic p) {
    if (p == null) return null;
    
    // 🟢 PRIORITY 1: Check direct URL fields (from API injection)
    try {
      final directUrl = (p as dynamic).imageUrl ?? 
                       (p as dynamic).base_image_url ?? 
                       (p as dynamic).small_image_url ?? 
                       (p as dynamic).base_image;
      if (directUrl is String && directUrl.isNotEmpty && !directUrl.endsWith("/storage/product/")) {
        return directUrl;
      }
    } catch (_) {}

    // 🟢 PRIORITY 2: Check images array
    try {
      final imgs = (p as dynamic).images;
      if (imgs is List && imgs.isNotEmpty) {
        for(var i in imgs) {
           final u = _imageFromAny(i);
           if (u != null && u.isNotEmpty && !u.endsWith("/storage/product/")) return u;
        }
      }
    } catch (_) {}
    
    // 🟢 PRIORITY 3: Check baseImage.url
    try {
      final v = (p as dynamic).baseImage?.url;
      if (v is String && v.isNotEmpty && !v.endsWith("/storage/product/")) return v;
    } catch (_) {}
    
    return null;
  }

  String _productPrice(dynamic p) {
     dynamic ph;
     try { ph = (p as dynamic).priceHtml; } catch (_) {}
     
     String priceText = "";
     try {
       priceText = (ph as dynamic)?.formattedFinalPrice?.toString() ?? "";
     } catch (_) {}
     
     if (priceText.isEmpty) {
       try {
         final val = (p as dynamic).price;
         if (val != null) priceText = "₹$val";
       } catch (_) {}
     }
     
     if (priceText.isNotEmpty) {
        // Enforce 2 decimals if it's a numeric string with more (e.g. 100.0000 -> 100.00)
        return priceText.replaceAllMapped(RegExp(r'(\.\d{2})\d+'), (match) => match.group(1)!);
     }
     
     return "";
  }

  bool _isOutOfStock(dynamic p) {
      if (p == null) return true;
      try { if ((p as dynamic).isSaleable == false) return true; } catch (_) {}
      
      try {
          // Check Inventories List to see actual qty
          // Because 'isSaleable' might be true even if request quantity logic differs
          if ((p as dynamic).inventories is List) {
              int total = 0;
              bool found = false;
              for (var i in (p as dynamic).inventories) {
                  if (i.qty != null) {
                      total += (i.qty as int);
                      found = true;
                  }
              }
              if (found) return total <= 0;
          }
      } catch (_) {}
      
      return false; 
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _productImage(data);
    final name = (data as dynamic).name?.toString() ?? "";
    final priceText = _productPrice(data);
    final productId = int.tryParse((data as dynamic).id?.toString() ?? '0') ?? 0;
    bool isInWishlist = (data as dynamic).isInWishlist ?? false;

    return InkWell(
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
        width: width,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 84,
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  ),
                  child: (imageUrl != null && imageUrl.isNotEmpty)
                      ? ImageView(url: imageUrl, fit: BoxFit.contain)
                      : const Icon(Icons.image, size: 40, color: Colors.grey),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: StreamBuilder<Set<String>>(
                    stream: GlobalData.wishlistUpdateStream,
                    builder: (context, snapshot) {
                      final currentWishlist = snapshot.data ?? GlobalData.wishlistProductIds;
                      bool active = currentWishlist.contains(productId.toString());
                      
                      // 🟢 If we don't have global data yet (snapshot is null/empty), 
                      // we can fallback to the data model's value as a hint.
                      if (currentWishlist.isEmpty && isInWishlist) {
                        active = true;
                      }
                      return InkWell(
                        onTap: () {
                          if (onAddToWishlist != null) {
                            onAddToWishlist!(productId.toString(), active, data);
                          }
                        },
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle, 
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              active ? Icons.favorite : Icons.favorite_border,
                              size: 16,
                              color: active ? Colors.red : Colors.black54, // Darker grey for visibility
                            ),
                          ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: _isOutOfStock(data) 
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red.shade200, width: 1),
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.red.shade50,
                      ),
                      child: Text(
                        "OOS", // Out of stock
                        style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold, fontSize: 8),
                      ),
                    )
                  : StreamBuilder<Map<String, Map<String, dynamic>>>(
                      stream: GlobalData.cartItemsController.stream,
                      builder: (context, snapshot) {
                        final cartMap = snapshot.data ?? GlobalData.cartItemsController.value;
                        final itemInfo = cartMap[productId.toString()];
                        final int currentQty = itemInfo?['qty'] ?? 0;
                        final String? cartItemId = itemInfo?['cartItemId']?.toString();

                        if (currentQty > 0) {
                          return Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9), // Transparent/Frosted
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF27C16B)), // Green Border
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () {
                                    if (onAddToCart != null) {
                                      onAddToCart?.call(-productId); 
                                    }
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6),
                                    child: Icon(Icons.remove, color: Color(0xFF27C16B), size: 12), // Green Icon
                                  ),
                                ),
                                Text(
                                  "$currentQty",
                                  style: const TextStyle(color: Color(0xFF27C16B), fontWeight: FontWeight.bold, fontSize: 10), // Green Text
                                ),
                                InkWell(
                                  onTap: () => onAddToCart?.call(productId),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6),
                                    child: Icon(Icons.add, color: Color(0xFF27C16B), size: 12), // Green Icon
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return InkWell(
                          onTap: () => onAddToCart?.call(productId),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9), // Transparent/Frosted
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF27C16B)), // Green Border
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.add, color: Color(0xFF27C16B), size: 18), // Green Icon
                          ),
                        );
                      }
                    ),
                ),
              ],
            ),
            Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, height: 1.1, color: Theme.of(context).textTheme.titleSmall?.color),
                  ),
                  const SizedBox(height: 1),
                  Text("1 Unit", style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 10)),
                  const SizedBox(height: 2),
                  Builder(
                    builder: (context) {
                      double rating = 0.0;
                      try {
                        var r = (data as dynamic).averageRating ?? (data as dynamic).rating;
                        if (r != null) rating = double.tryParse(r.toString()) ?? 0.0;
                        var reviews = (data as dynamic).reviews;
                        if (reviews is List && rating == 0 && reviews.isNotEmpty) {
                          double totalObj = 0;
                          for (var r in reviews) {
                            var val = (r as dynamic).rating;
                            if (val != null) totalObj += double.tryParse(val.toString()) ?? 0;
                          }
                          rating = totalObj / reviews.length;
                        }
                      } catch (_) {}
                      int reviewCount = 0;
                      try {
                        var reviews = (data as dynamic).reviews;
                        if (reviews is List) reviewCount = reviews.length;
                      } catch (_) {}
                      return Row(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(5, (index) {
                              return Icon(
                                index < rating.round() ? Icons.star : Icons.star_border,
                                size: 10,
                                color: index < rating.round() ? Colors.amber : Theme.of(context).dividerColor,
                              );
                            }),
                          ),
                          const SizedBox(width: 4),
                          if (reviewCount > 0)
                            Text(
                              "($reviewCount)",
                              style: TextStyle(fontSize: 8, color: Theme.of(context).textTheme.bodySmall?.color, fontWeight: FontWeight.w500),
                            ),
                        ],
                      );
                    },
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 1, bottom: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor.withOpacity(0.1), 
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, size: 10, color: Theme.of(context).textTheme.bodySmall?.color),
                        const SizedBox(width: 4),
                        Text("12 MINS", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodySmall?.color)),
                      ],
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "₹",
                          style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).textTheme.titleSmall?.color),
                        ),
                        TextSpan(
                          text: priceText.replaceAll("₹", "").trim(),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.titleSmall?.color),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
