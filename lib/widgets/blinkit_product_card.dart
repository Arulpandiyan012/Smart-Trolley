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
      sellingPrice = "₹${data?.price ?? '0'}";
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
            margin: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16), // 🟢 Modern Rounded Corners
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
                        // height: 135, // Removed to allow dynamic sizing
                        padding: const EdgeInsets.fromLTRB(4, 12, 12, 12),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
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
                            
                            const SizedBox(height: 6),

                            // 🟢 PRICE SECTION (Vertical Stack)
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
                                          fontSize: 17, // 🟢 Bold & Visible
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
                            
                            const SizedBox(height: 12),

                            // 🟢 BOTTOM ROW (ADD BUTTON)
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
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                      ),
                    ),
                  ],
                ),
                
                // FLOATING ICONS
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