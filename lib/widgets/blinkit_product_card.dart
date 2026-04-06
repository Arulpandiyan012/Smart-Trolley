import 'package:bagisto_app_demo/screens/categories_screen/utils/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagisto_app_demo/screens/cart_screen/utils/cart_index.dart';
import 'package:bagisto_app_demo/screens/cart_screen/bloc/cart_screen_event.dart';
import 'package:bagisto_app_demo/screens/cart_screen/bloc/cart_screen_state.dart';
import 'package:bagisto_app_demo/widgets/smart_add_button.dart';

class BlinkitProductCard extends StatelessWidget {
  final NewProducts? data;
  final bool isLoggedIn;
  final void Function(String id, bool isInWishlist, dynamic product)? onAddToWishlist;
  final void Function(int productId, int quantity)? onAddToCart;
  final CategoryBloc? subCategoryBloc;

  const BlinkitProductCard({
    Key? key,
    required this.data,
    this.isLoggedIn = false,
    this.subCategoryBloc,
    this.onAddToWishlist,
    this.onAddToCart, 
  }) : super(key: key);

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

  String _productUnit(dynamic p) {
    if (p == null) return "1 Unit";
    try {
      String? weight, unit;
      
      // 1. Try productFlats
      if (p.productFlats is List && (p.productFlats as List).isNotEmpty) {
        final pf = (p.productFlats as List).first;
        try {
          weight = (pf as dynamic).weight?.toString();
          unit = (pf as dynamic).unit?.toString();
        } catch (_) {}
      }

      // 2. Try additionalData (EAV)
      if (p.additionalData is List && (p.additionalData as List).isNotEmpty) {
        for (var d in (p.additionalData as List)) {
          try {
            if (d.code == 'weight') weight = d.value?.toString();
            if (d.code == 'unit') unit = d.value?.toString();
          } catch (_) {}
        }
      }

      if (weight != null && weight.isNotEmpty) {
        // Clean up "500.0" -> "500"
        if (weight.endsWith(".0")) weight = weight.substring(0, weight.length - 2);
        
        // 🟢 FORMATTING: If grams >= 1000, show as kg
        double? wVal = double.tryParse(weight);
        if (wVal != null && wVal >= 1000) {
           if (unit?.toLowerCase() == "g") {
              return "${(wVal / 1000).toStringAsFixed(wVal % 1000 == 0 ? 0 : 1)} kg";
           }
           if (unit?.toLowerCase() == "ml") {
              return "${(wVal / 1000).toStringAsFixed(wVal % 1000 == 0 ? 0 : 1)} l";
           }
        }
        
        if (unit != null && unit.isNotEmpty && unit != "pcs" && unit != "Units") {
           return "$weight $unit";
        }
        return "$weight ${unit ?? 'Unit'}";
      }

      if (unit != null && unit.isNotEmpty) return unit;

    } catch (_) {}
    return "1 Unit";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    String imageUrl = "";
    if ((data?.images ?? []).isNotEmpty) {
      imageUrl = data?.images?.first.url ?? "";
    }
    if (imageUrl.isEmpty) {
      imageUrl = data?.imageUrl ?? "";
    }

    String formatPrice(String? raw, dynamic fallbackP) {
      String? srcStr = raw;
      if (srcStr == null || srcStr.isEmpty) {
        if (fallbackP != null) srcStr = fallbackP.toString();
      }
      if (srcStr == null || srcStr.isEmpty) return "";
      
      final cleanStr = srcStr.replaceAll(RegExp(r'[^0-9.]'), '');
      if (cleanStr.isNotEmpty) {
        final parsed = double.tryParse(cleanStr);
        if (parsed != null) {
          return "₹${parsed.toStringAsFixed(2)}";
        }
      }
      return srcStr; // fallback
    }

    String sellingPrice = formatPrice(data?.priceHtml?.formattedFinalPrice, data?.price);
    String originalPrice = formatPrice(data?.priceHtml?.formattedRegularPrice, null);

    bool hasDiscount = originalPrice.isNotEmpty && 
                       originalPrice != sellingPrice && 
                       originalPrice != "₹0.00";

    return StreamBuilder<Map<String, Map<String, dynamic>>>(
      stream: GlobalData.cartItemsController.stream,
      builder: (context, snapshot) {
        int currentQty = 0;
        String? cartItemId;
        
        final cartMap = snapshot.data ?? {};
        final info = cartMap[data?.id ?? ""];
        if (info != null) {
          currentQty = info['qty'] ?? 0;
          cartItemId = info['cartItemId']?.toString();
        }

        bool outOfStock = _isOutOfStock(data);

        return InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              productScreen,
              arguments: PassProductData(
                title: data?.name ?? data?.productFlats?.firstOrNull?.name ?? "",
                urlKey: data?.urlKey,
                productId: int.tryParse(data?.id ?? "0"),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white24 : Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.03), 
                  blurRadius: 4, 
                  offset: const Offset(0, 2)
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TOP: IMAGE & ICONS
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      // Image
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Builder(
                            builder: (context) {
                              return Opacity(
                                opacity: outOfStock ? 0.6 : 1.0,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ImageView(url: imageUrl, fit: BoxFit.contain),
                                    if (outOfStock)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
                          ),
                        ),
                      ),
                      
                      // Sale Tag
                      if (data?.isInSale ?? false)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5365E3), 
                              borderRadius: BorderRadius.circular(4)
                            ),
                            child: const Text(
                              "SALE", 
                              style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)
                            ),
                          ),
                        ),

                      // Wishlist Icon
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () {
                             if (onAddToWishlist != null) {
                               onAddToWishlist!(data?.id ?? "", data?.isInWishlist ?? false, data);
                             }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, shape: BoxShape.circle), // clean bg
                            child: Icon(
                              (data?.isInWishlist ?? false) ? Icons.favorite : Icons.favorite_border,
                              size: 16,
                              color: (data?.isInWishlist ?? false) ? Colors.red : (isDark ? Colors.white70 : Colors.grey[400]),
                            ),
                          ),
                        ),
                      ),

                      // Add Button placed bottom right of image
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: SizedBox(
                          width: 48, 
                          height: 20, 
                          child: outOfStock
                            ? Container(
                               padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                               decoration: BoxDecoration(
                                 color: Colors.grey[100],
                                 borderRadius: BorderRadius.circular(8),
                                 border: Border.all(color: Colors.grey[300]!),
                               ),
                               child: Center(
                                 child: Text(
                                   "OOS", 
                                   style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold, fontSize: 9)
                                 ),
                               ),
                             )
                            : SmartAddButton(
                            qty: currentQty,
                            isLoading: false,
                            onAdd: () {
                              if (isLoggedIn) {
                                int stock = _getProductStock(data);
                                bool isSaleable = true;
                                try { if ((data as dynamic).isSaleable == false) isSaleable = false; } catch (_) {}
                                
                                bool block = !isSaleable;
                                try {
                                  if (data?.inventories != null && data!.inventories!.isNotEmpty) {
                                    if (stock <= 0) block = true;
                                  }
                                } catch (_) {}

                                if (!block) {
                                  if (data?.type == "simple" || data?.type == "virtual") {
                                    if (onAddToCart != null) onAddToCart!(int.tryParse(data?.id ?? "0") ?? 0, 1);
                                  } else {
                                    ShowMessage.warningNotification("Select Options", context);
                                  }
                                } else {
                                  ShowMessage.warningNotification("Out of Stock", context);
                                }
                              } else {
                                ShowMessage.warningNotification(StringConstants.pleaseLogin.localized(), context);
                              }
                            },
                            onIncrease: () {
                              if (cartItemId != null) {
                                int stock = _getProductStock(data);
                                bool hasInventory = false;
                                try { hasInventory = (data?.inventories != null && data!.inventories!.isNotEmpty); } catch (_) {}

                                if (!hasInventory || currentQty < stock) {
                                    GlobalData.optimisticUpdateCart(int.tryParse(data?.id ?? "0") ?? 0, 1);
                                    context.read<CartScreenBloc>().add(UpdateCartEvent(
                                      [{'cartItemId': cartItemId, 'quantity': (currentQty + 1).toString()}]
                                    ));
                                } else {
                                    ShowMessage.warningNotification("Limited Stock: Only $stock items available", context);
                                }
                              }
                            },
                            onDecrease: () {
                              if (cartItemId != null) {
                                GlobalData.optimisticUpdateCart(int.tryParse(data?.id ?? "0") ?? 0, -1);
                                if (currentQty > 1) {
                                  context.read<CartScreenBloc>().add(UpdateCartEvent(
                                    [{'cartItemId': cartItemId, 'quantity': (currentQty - 1).toString()}]
                                  ));
                                } else {
                                   context.read<CartScreenBloc>().add(RemoveCartItemEvent(
                                     cartItemId: int.parse(cartItemId!)
                                   ));
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. BOTTOM: DETAILS
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                           Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF4F6F8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.timer_outlined, size: 8, color: theme.textTheme.bodySmall?.color),
                                  const SizedBox(width: 2),
                                  Text("12 MINS", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: theme.textTheme.bodySmall?.color)),
                                ],
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            data?.name ?? "",
                            maxLines: 2, 
                            overflow: TextOverflow.ellipsis, 
                            style: TextStyle(
                              fontWeight: FontWeight.w600, 
                              fontSize: 10,  
                              height: 1.1,
                            )
                          ),
                          const SizedBox(height: 1),

                          Text(
                            _productUnit(data), 
                            style: TextStyle(color: theme.textTheme.bodySmall?.color ?? (isDark ? Colors.white70 : Colors.grey[500]), fontSize: 9, fontWeight: FontWeight.w500) 
                          ),
                          
                          // Removed SizedBox(height:2) here to fix 6px overflow

                          Builder(
                            builder: (context) {
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
                                        size: 10,
                                        color: index < rating.round() ? Colors.amber : (isDark ? Colors.white24 : Colors.grey[300]),
                                      );
                                    }),
                                  ),
                                  const SizedBox(width: 4),
                                  if (reviewCount > 0)
                                    Text(
                                      "($reviewCount)",
                                      style: TextStyle(fontSize: 8, color: theme.textTheme.bodySmall?.color, fontWeight: FontWeight.w500),
                                    ),
                                ],
                              );
                            },
                          ),
                          
                          const Spacer(),

                          Builder(builder: (context) {
                            int stock = _getProductStock(data);
                            if (stock > 0 && stock <= 5) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  "Only $stock left", 
                                  style: const TextStyle(color: Colors.red, fontSize: 8.5, fontWeight: FontWeight.bold)
                                ),
                              );
                            }
                            return const SizedBox();
                          }),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (hasDiscount)
                                    Text(
                                      originalPrice, 
                                      style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 9)
                                    ),
                                  Text(
                                    sellingPrice, 
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: isDark ? const Color(0xFF27C16B) : const Color(0xFF1B5E20))
                                  ),
                                ],
                              ),
                            ],
                          )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildIconContainer({required BuildContext context, required IconData icon, required Color color}) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Icon(
        icon,
        size: 14,
        color: color,
      ),
    );
  }
}