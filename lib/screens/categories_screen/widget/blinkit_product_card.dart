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

  String _productUnit(dynamic p) {
    if (p == null) return "1 Unit";
    try {
      if (p.productFlats is List && (p.productFlats as List).isNotEmpty) {
        final pf = (p.productFlats as List).first;
        try {
          final w = (pf as dynamic).weight;
          if (w != null && w.toString().isNotEmpty) return w.toString();
        } catch (_) {}
      }
      if (p.additionalData is List && (p.additionalData as List).isNotEmpty) {
        for (var d in (p.additionalData as List)) {
          try {
            if (d.code == 'weight' || d.code == 'unit') {
              if (d.value != null && d.value.toString().isNotEmpty) return d.value.toString();
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
    return "1 Unit";
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl = "";
    if ((data?.images ?? []).isNotEmpty) {
      imageUrl = data?.images?.first.url ?? "";
    }

    // Price Logic
    String sellingPrice = data?.priceHtml?.formattedFinalPrice ?? "";
    String originalPrice = data?.priceHtml?.formattedRegularPrice ?? ""; 

    if (sellingPrice.isEmpty) {
      double parsedPrice = double.tryParse(data?.price?.toString() ?? "0") ?? 0;
      sellingPrice = "₹${parsedPrice.toStringAsFixed(2)}";
    } else {
      // API sometimes returns 4 decimals even in formatted strings, so enforce 2
      sellingPrice = sellingPrice.replaceAllMapped(RegExp(r'(\.\d{2})\d+'), (match) => match.group(1)!);
    }

    if (originalPrice.isNotEmpty) {
      originalPrice = originalPrice.replaceAllMapped(RegExp(r'(\.\d{2})\d+'), (match) => match.group(1)!);
    }

    bool hasDiscount = originalPrice.isNotEmpty && 
                       originalPrice != sellingPrice && 
                       originalPrice != "₹0.00";

    return BlocBuilder<CartScreenBloc, CartScreenBaseState>(
      buildWhen: (previous, current) {
        return current is FetchCartDataState;
      },
      builder: (context, state) {
        int currentQty = 0;
        String? cartItemId;
        
        if (state is FetchCartDataState && state.status == CartStatus.success) {
             var cartItem = state.cartDetailsModel?.items?.firstWhere(
                (item) => item.productId == data?.id, 
                orElse: () => Items() 
             );
             if (cartItem != null && cartItem.id != null) {
                currentQty = cartItem.quantity ?? 0;
                cartItemId = cartItem.id;
             }
        } 

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
            margin: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16), // 🟢 More rounded for modern feel
              border: Border.all(color: Colors.grey[100]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04), 
                  blurRadius: 8, 
                  offset: const Offset(0, 4)
                ),
              ],
            ),
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==============================
                    // 1. LEFT: IMAGE SECTION
                    // ==============================
                    Container(
                      width: 100, // 🟢 Slightly wider
                      padding: const EdgeInsets.all(10),
                      child: Stack(
                        children: [
                          Center(
                            child: SizedBox(
                              height: 85, 
                              width: 85,
                              child: Builder(
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
                              ),
                            ),
                          ),
                          
                          if (data?.isInSale ?? false)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5365E3), 
                                  borderRadius: BorderRadius.circular(4)
                                ),
                                child: const Text(
                                  "SALE", 
                                  style: TextStyle(
                                    color: Colors.white, 
                                    fontSize: 8, 
                                    fontWeight: FontWeight.bold
                                  )
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ==============================
                    // 2. RIGHT: DETAILS SECTION
                    // ==============================
                    Expanded(
                      child: Container(
                        height: 135, // 🟢 Fixed height to ensure alignment
                        padding: const EdgeInsets.fromLTRB(4, 12, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Timer Tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F6F8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.timer_outlined, size: 10, color: Colors.black54),
                                  SizedBox(width: 4),
                                  Text("12 MINS", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.black54)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Name
                            Text(
                              data?.name ?? "",
                              maxLines: 2, 
                              overflow: TextOverflow.ellipsis, 
                              style: const TextStyle(
                                fontWeight: FontWeight.w700, 
                                fontSize: 13.5, 
                                height: 1.1,
                                letterSpacing: -0.2,
                                color: Colors.black87
                              )
                            ),
                            const SizedBox(height: 4),
                            
                            // Unit
                             Text(
                               _productUnit(data), 
                               style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500)
                             ),
                            
                            const SizedBox(height: 4), 

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
                                          size: 11,
                                          color: index < rating.round() ? Colors.amber : Colors.grey[300],
                                        );
                                      }),
                                    ),
                                    const SizedBox(width: 4),
                                    if (reviewCount > 0)
                                      Text(
                                        "($reviewCount)",
                                        style: TextStyle(fontSize: 9, color: Colors.grey[500], fontWeight: FontWeight.w500),
                                      ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 4), 

                            const Spacer(), 

                             // 🟢 LOW STOCK INDICATOR (Moved here, above Price)
                             Builder(builder: (context) {
                               int stock = _getProductStock(data);
                               if (stock > 0 && stock <= 5) {
                                 return Padding(
                                   padding: const EdgeInsets.only(bottom: 2),
                                   child: Text(
                                     "Only $stock left", 
                                     style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)
                                   ),
                                 );
                               }
                               return const SizedBox();
                             }),

                             // 🟢 BOTTOM ROW (ADD BUTTON MOVED HERE)
                             Builder(
                               builder: (context) {
                                  bool outOfStock = _isOutOfStock(data);
                                  if (outOfStock) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.grey[200]!),
                                        ),
                                        child: Text(
                                          "OUT OF STOCK", 
                                          style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w800, fontSize: 11)
                                        ),
                                      );
                                  }
                                  
                                  return Row(
                                    children: [
                                      // 🟢 PRICE SECTION (Modern Vertical Stack)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (hasDiscount)
                                            Text(
                                              originalPrice, 
                                              style: const TextStyle(
                                                decoration: TextDecoration.lineThrough,
                                                color: Colors.grey,
                                                fontSize: 10,
                                              )
                                            ),
                                            
                                          Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: "₹",
                                                  style: TextStyle(
                                                    fontFamily: 'Roboto', 
                                                    fontWeight: FontWeight.w800, 
                                                    fontSize: 14, 
                                                    color: const Color(0xFF1B5E20)
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: sellingPrice.replaceAll("₹", "").trim(), 
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w900, 
                                                    fontSize: 17, // 🟢 Bold and Clear
                                                    color: Color(0xFF1B5E20)
                                                  )
                                                ),
                                              ],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),

                                      const Spacer(),

                                      // 🟢 Modern Circular ADD Button
                                      SizedBox(
                                        width: 85, // 🟢 Fixed Width for "ADD" buttons
                                        height: 34,
                                        child: SmartAddButton(
                                          qty: currentQty,
                                          isLoading: false,
                                          onAdd: () {
                                            if (isLoggedIn) {
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
                                                if (data?.type == 'configurable') {
                                                  Navigator.pushNamed(context, productScreen, arguments: PassProductData(
                                                    title: data?.name ?? "",
                                                    urlKey: data?.urlKey,
                                                    productId: int.tryParse(data?.id ?? "0"),
                                                  ));
                                                  } else {
                                                    int pId = int.tryParse(data?.id ?? "0") ?? 0;
                                                    if (onAddToCart != null) {
                                                      onAddToCart!(pId, 1);
                                                    } else if (subCategoryBloc != null) {
                                                      GlobalData.optimisticUpdateCart(pId, 1);
                                                      subCategoryBloc?.add(AddToCartSubCategoryEvent(pId, 1));
                                                    }
                                                  }
                                              } else {
                                                ShowMessage.warningNotification("Out of Stock", context);
                                              }
                                            } else {
                                              ShowMessage.warningNotification(StringConstants.pleaseLogin.localized(), context);
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
                                                  cartItemId: int.tryParse(cartItemId ?? "") ?? 0
                                                ));
                                              }
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
                                        ),
                                      ),
                                    ],
                                  );
                               }
                             ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                // FLOATING ICONS (Wishlist/Compare)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                           if (onAddToWishlist != null) {
                             onAddToWishlist!(data?.id ?? "", data?.isInWishlist ?? false, data);
                           }
                        },
                        child: _buildIconContainer(
                          icon: (data?.isInWishlist ?? false) ? Icons.favorite : Icons.favorite_border,
                          color: (data?.isInWishlist ?? false) ? Colors.red : Colors.grey[400]!,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          if (isLoggedIn) {
                            subCategoryBloc?.add(OnClickSubCategoriesLoaderEvent(isReqToShowLoader: true));
                            subCategoryBloc?.add(AddToCompareSubCategoryEvent(data?.id ?? "", ""));
                          } else {
                            ShowMessage.warningNotification(StringConstants.pleaseLogin.localized(), context);
                          }
                        },
                        child: _buildIconContainer(
                          icon: Icons.compare_arrows, 
                          color: Colors.grey[400]!,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildIconContainer({required IconData icon, required Color color}) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Icon(
        icon,
        size: 14,
        color: color,
      ),
    );
  }
}