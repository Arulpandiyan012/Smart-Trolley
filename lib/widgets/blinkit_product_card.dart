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
                // ==============================
                // 1. TOP: IMAGE & ICONS
                // ==============================
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      // Image
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: ImageView(url: imageUrl, fit: BoxFit.contain),
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
                        bottom: -4,
                        right: 0,
                        child: SizedBox(
                          width: 48, 
                          height: 20, 
                          child: SmartAddButton(
                            qty: currentQty,
                            isLoading: false,
                            onAdd: () {
                              if (isLoggedIn) {
                                if (data?.type == "simple" || data?.type == "virtual") {
                                  if (onAddToCart != null) onAddToCart!(int.tryParse(data?.id ?? "0") ?? 0, 1);
                                } else {
                                  ShowMessage.warningNotification("Select Options", context);
                                }
                              } else {
                                ShowMessage.warningNotification(StringConstants.pleaseLogin.localized(), context);
                              }
                            },
                            onIncrease: () {
                              if (cartItemId != null) {
                                GlobalData.optimisticUpdateCart(int.tryParse(data?.id ?? "0") ?? 0, 1);
                                context.read<CartScreenBloc>().add(UpdateCartEvent(
                                  [{'cartItemId': cartItemId, 'quantity': (currentQty + 1).toString()}]
                                ));
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

                // ==============================
                // 2. BOTTOM: DETAILS
                // ==============================
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
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
                          const SizedBox(height: 6),

                          // Name
                          Text(
                            data?.name ?? "",
                            maxLines: 2, 
                            overflow: TextOverflow.ellipsis, 
                            style: TextStyle(
                              fontWeight: FontWeight.w600, 
                              fontSize: 10,  // Reduced from 12
                              height: 1.1,
                              color: theme.textTheme.titleSmall?.color ?? (isDark ? Colors.white : Colors.black87)
                            )
                          ),
                          const SizedBox(height: 4),

                          // Unit
                          Text(
                            "1 Unit", 
                            style: TextStyle(color: theme.textTheme.bodySmall?.color ?? (isDark ? Colors.white70 : Colors.grey[500]), fontSize: 9, fontWeight: FontWeight.w500) // Reduced from 10
                          ),
                          
                          const Spacer(),

                          // Price & Add Button Row
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
                                      style: const TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey,
                                        fontSize: 9,
                                      )
                                    ),
                                  Text(
                                    sellingPrice, 
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800, 
                                      fontSize: 12, 
                                      color: isDark ? const Color(0xFF27C16B) : const Color(0xFF1B5E20)
                                    )
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