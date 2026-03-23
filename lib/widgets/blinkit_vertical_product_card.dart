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
       if (priceText.isNotEmpty) {
         // API sometimes returns 4 decimals even in formatted strings, so enforce 2
         priceText = priceText.replaceAllMapped(RegExp(r'(\.\d{2})\d+'), (match) => match.group(1)!);
       }
     } catch (_) {}
     
     if (priceText.isNotEmpty) return priceText;

     final sym = "₹";
     try {
       final val = (p as dynamic).price;
       if (val != null) {
          double parsed = double.tryParse(val.toString()) ?? 0;
          return "$sym${parsed.toStringAsFixed(2)}";
       }
     } catch (_) {}
     
     return "";
  }

  int _getProductStock(dynamic p) {
      if (p == null) return 0;
      try {
          // 1. Try inventories sum
          if ((p as dynamic).inventories is List && (p as dynamic).inventories.isNotEmpty) {
              int total = 0;
              for (var i in (p as dynamic).inventories) {
                  var q = (i as dynamic).qty;
                  if (q != null) {
                      total += int.tryParse(q.toString()) ?? 0;
                  }
              }
              return total;
          }
          
          // 2. Fallback to totalQty
          var tq = (p as dynamic).totalQty;
          if (tq != null) {
            int? val = int.tryParse(tq.toString());
            if (val != null) return val;
          }
          
          // 3. Fallback to quantity
          var q = (p as dynamic).quantity;
          if (q != null) {
            int? val = int.tryParse(q.toString());
            if (val != null) return val;
          }
      } catch (_) {}
      return 0;
  }

  bool _isOutOfStock(dynamic p) {
      if (p == null) return true;
      try { if ((p as dynamic).isSaleable == false) return true; } catch (_) {}
      
      int stock = _getProductStock(p);
      bool hasData = false;
      try {
          if ((p as dynamic).inventories is List && (p as dynamic).inventories.isNotEmpty) hasData = true;
          if ((p as dynamic).totalQty != null) hasData = true;
          if ((p as dynamic).quantity != null) hasData = true;
      } catch (_) {}

      if (hasData && stock <= 0) return true;
      
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
                      ? Builder(
                          builder: (context) {
                            bool outOfStock = _isOutOfStock(data);
                            return Opacity(
                              opacity: outOfStock ? 0.6 : 1.0,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  ImageView(url: imageUrl, fit: BoxFit.contain),
                                  if (outOfStock)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        "OUT OF STOCK", 
                                        style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }
                        )
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

                        if (_isOutOfStock(data)) {
                            return Container(
                              height: 24,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Center(
                                child: Text(
                                  "OOS", 
                                  style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold, fontSize: 9)
                                ),
                              ),
                            );
                        }

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
                                   onTap: () {
                                     int stock = _getProductStock(data);
                                     bool hasInventory = false;
                                     try { hasInventory = (data?.inventories != null && data!.inventories!.isNotEmpty); } catch (_) {}
                                     
                                     if (!hasInventory || currentQty < stock) {
                                       onAddToCart?.call(productId);
                                     } else {
                                       ShowMessage.warningNotification("Only $stock items available", context);
                                     }
                                   },
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
                          onTap: () {
                             int stock = _getProductStock(data);
                             bool isSaleable = true;
                             try { if ((data as dynamic).isSaleable == false) isSaleable = false; } catch (_) {}
                             
                             bool block = !isSaleable;
                             try {
                               if ((data as dynamic).inventories is List && (data as dynamic).inventories.isNotEmpty) {
                                 if (stock <= 0) block = true;
                               }
                             } catch (_) {}

                             if (!block) {
                               onAddToCart?.call(productId);
                             } else {
                               ShowMessage.warningNotification("Out of Stock", context);
                             }
                          },
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
                  Text(
                    (data as dynamic).weight ?? (data as dynamic).unit ?? '1 Unit', 
                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 9, fontWeight: FontWeight.normal)
                  ),
                  
                  const SizedBox(height: 2),
                  Builder(
                    builder: (context) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      double rating = 0.0;
                      try {
                        var r = (data as dynamic).averageRating ?? 
                                (data as dynamic).rating ?? 
                                (data as dynamic).avg_rating ?? 
                                (data as dynamic).average_rating;
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
                                size: 10, // Slightly smaller for space
                                color: index < rating.round() ? Colors.amber : (isDark ? Colors.white24 : Colors.grey[300]),
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
                  const SizedBox(height: 2),
                  
                  // Low Stock / Timer Row
                  Builder(builder: (context) {
                    int stock = _getProductStock(data);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (stock > 0 && stock <= 5)
                          Text("Only $stock left", style: const TextStyle(color: Colors.red, fontSize: 8, fontWeight: FontWeight.bold))
                        else
                          const SizedBox(),
                        
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor.withOpacity(0.05), 
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.timer_outlined, size: 8, color: Theme.of(context).textTheme.bodySmall?.color),
                              const SizedBox(width: 2),
                              Text("12 MINS", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodySmall?.color)),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),

                  const Spacer(),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "₹",
                          style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).textTheme.titleSmall?.color),
                        ),
                        TextSpan(
                          text: priceText.replaceAll("₹", "").trim(),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.titleSmall?.color),
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
