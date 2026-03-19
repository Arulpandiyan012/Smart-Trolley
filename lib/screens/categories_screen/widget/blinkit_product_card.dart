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
                              child: ImageView(url: imageUrl, fit: BoxFit.contain),
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
                              "1 Unit", 
                              style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500)
                            ),
                            
                            const SizedBox(height: 6), // 🟢 Price now directly under unit

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

                            // 🟢 BOTTOM ROW (ADD BUTTON MOVED HERE)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
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
                                            onAddToCart!(int.tryParse(data?.id ?? "0") ?? 0, 1);
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
                                             cartItemId: int.tryParse(cartItemId ?? "") ?? 0
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