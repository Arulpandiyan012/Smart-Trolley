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
    super.key,
    required this.data,
    this.isLoggedIn = false,
    this.subCategoryBloc,
    this.onAddToWishlist,
    this.onAddToCart, 
  });

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
      sellingPrice = "₹${data?.price ?? '0'}";
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
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03), 
                  blurRadius: 4, 
                  offset: const Offset(0, 2)
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
                      width: 88, 
                      padding: const EdgeInsets.all(8),
                      child: Stack(
                        children: [
                          Center(
                            child: SizedBox(
                              height: 80, 
                              width: 80,
                              child: ImageView(url: imageUrl, fit: BoxFit.contain),
                            ),
                          ),
                          
                          // 🟢 FIX: SALE BADGE MOVED TO TOP-RIGHT
                          if (data?.isInSale ?? false)
                            Positioned(
                              top: 0,
                              right: 0, // Changed from left: 0 to right: 0
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
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 12, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Timer Tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F6F8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.timer_outlined, size: 10, color: Colors.black54),
                                  SizedBox(width: 3),
                                  Text("12 MINS", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54)),
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
                                fontWeight: FontWeight.w600, 
                                fontSize: 13, 
                                height: 1.2,
                                color: Colors.black87
                              )
                            ),
                            const SizedBox(height: 4),
                            
                            // Unit
                            Text(
                              "1 Unit", 
                              style: TextStyle(color: Colors.grey[500], fontSize: 11)
                            ),
                            
                            const SizedBox(height: 12), 

                            // BOTTOM ROW: Price & Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end, 
                              children: [
                                // PRICE COLUMN (With FittedBox to prevent overflow)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (hasDiscount)
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            originalPrice, 
                                            style: const TextStyle(
                                              decoration: TextDecoration.lineThrough,
                                              color: Colors.grey,
                                              fontSize: 11,
                                            )
                                          ),
                                        ),
                                        
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          sellingPrice, 
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700, 
                                            fontSize: 14, 
                                            color: Colors.black
                                          )
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(width: 4), 

                                // ADD BUTTON
                                SizedBox(
                                  width: 72, 
                                  height: 32, 
                                  child: SmartAddButton(
                                    qty: currentQty,
                                    isLoading: false,
                                    onAdd: () {
                                      if (isLoggedIn) {
                                        if (data?.type == "simple" || data?.type == "virtual") {
                                          if (onAddToCart != null) {
                                            onAddToCart!(int.parse(data?.id ?? "0"), 1);
                                          }
                                        } else {
                                          ShowMessage.warningNotification("Select Options", context);
                                        }
                                      } else {
                                        ShowMessage.warningNotification(StringConstants.pleaseLogin.localized(), context);
                                      }
                                    },
                                    onIncrease: () {
                                      if (cartItemId != null) {
                                        context.read<CartScreenBloc>().add(UpdateCartEvent(
                                          [{'cartItemId': cartItemId, 'quantity': (currentQty + 1).toString()}]
                                        ));
                                      }
                                    },
                                    onDecrease: () {
                                      if (cartItemId != null) {
                                        if (currentQty > 1) {
                                          context.read<CartScreenBloc>().add(UpdateCartEvent(
                                            [{'cartItemId': cartItemId, 'quantity': (currentQty - 1).toString()}]
                                          ));
                                        } else {
                                          context.read<CartScreenBloc>().add(RemoveCartItemEvent(
                                            cartItemId: int.parse(cartItemId)
                                          ));
                                        }
                                      }
                                    },
                                  ),
                                )
                              ],
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
            color: Colors.black.withValues(alpha: 0.05),
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