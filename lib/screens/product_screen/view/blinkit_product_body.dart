import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:share_plus/share_plus.dart';

// Import Utils (Contains ProductScreenBLoc, ProductScreenRepo, Events)
import 'package:bagisto_app_demo/screens/product_screen/utils/index.dart';

// Global Utils & Models
import 'package:bagisto_app_demo/utils/index.dart'; 
import 'package:bagisto_app_demo/screens/home_page/data_model/new_product_data.dart';
import 'package:bagisto_app_demo/screens/product_screen/view/product_screen.dart';

// Import shared Blinkit Product Card
import 'package:bagisto_app_demo/widgets/blinkit_product_card.dart';
import 'package:bagisto_app_demo/widgets/blinkit_vertical_product_card.dart';
import 'package:bagisto_app_demo/screens/cart_screen/bloc/cart_screen_bloc.dart';
import 'package:bagisto_app_demo/screens/cart_screen/bloc/cart_screen_state.dart';
import 'package:bagisto_app_demo/screens/cart_screen/utils/cart_index.dart'; // For CartStatus and CartModel linkage if needed
import 'package:bagisto_app_demo/screens/product_screen/bloc/product_page_repository.dart';

// SEARCH SCREEN
import 'package:bagisto_app_demo/screens/search_screen/view/search_screen.dart';
import 'package:bagisto_app_demo/screens/search_screen/utils/index.dart' hide Status; 

class BlinkitProductBody extends StatefulWidget {
  final NewProducts? productData;
  final ProductScreenBLoc? productScreenBLoc;

  const BlinkitProductBody({
    Key? key,
    this.productData,
    this.productScreenBLoc,
  }) : super(key: key);

  @override
  State<BlinkitProductBody> createState() => _BlinkitProductBodyState();
}

class _BlinkitProductBodyState extends State<BlinkitProductBody> {
  int _currentImageIndex = 0;
  int _quantity = 0;
  bool _isDescriptionExpanded = false; 

 @override
  Widget build(BuildContext context) {
    if (widget.productData == null) return const SizedBox();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBlinkitCarousel(), 
          
          Container(
            color: Theme.of(context).cardColor, 
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 _buildProductInfo(), 
                 _buildExpandableDescription(),
                 
                 // 🟢 ADDED: Review Section
                 if (widget.productData != null)
                   ProductReviewSummaryView(
                     review: widget.productData!.reviews,
                     productId: widget.productData!.id,
                     averageRating: widget.productData!.averageRating,
                     percentage: widget.productData!.percentageRating,
                     productName: widget.productData!.name,
                     productImage: (widget.productData!.images?.isNotEmpty ?? false) 
                        ? widget.productData!.images![0].url 
                        : "",
                     isLogin: appStoragePref.getCustomerLoggedIn(),
                   ),
              ],
            ),
          ),
          
          const SizedBox(height: 16), 
          
          _buildRelatedProductsList(), 
          
          const SizedBox(height: 100), 
        ],
      ),
    );
  }

  // 🟢 NEW HELPER: Robust Price Formatter
  // Handles "1,200.0000", "₹500.00", "500", etc.
  String _getFormattedPrice(dynamic product) {
    try {
       String raw = "";
       
       // 1. Try to get the most accurate price string
       if (product?.priceHtml?.finalPrice != null) {
         raw = product!.priceHtml!.finalPrice!;
       } else if (product?.price != null) {
         raw = product!.price.toString();
       } else if (product?.formatedPrice != null) {
         raw = product!.formatedPrice!;
       }
       
       if (raw.isEmpty) return "₹0.00";

       // 2. Clean it: Remove everything except digits and dots
       // Example: "₹1,200.5000" -> "1200.5000"
       String clean = raw.replaceAll(RegExp(r'[^0-9.]'), '');
       
       // 3. Parse to double
       double val = double.tryParse(clean) ?? 0.0;
       
       // 4. Return formatted with 2 decimal places
       return "₹${val.toStringAsFixed(2)}";
    } catch (e) {
       return "₹0.00";
    }
  }

  // =========================================================
  // 1. CAROUSEL
  // =========================================================
  Widget _buildBlinkitCarousel() {
    var images = widget.productData?.images ?? [];
    bool isInWishlist = widget.productData?.isInWishlist ?? false;
    
    Widget imageWidget = images.isEmpty
        ? Container(height: 280, color: Colors.grey[100])
        : CarouselSlider(
            options: CarouselOptions(
              height: 280, 
              viewportFraction: 1.0,
              enableInfiniteScroll: false,
              onPageChanged: (index, reason) {
                setState(() => _currentImageIndex = index);
              },
            ),
            items: images.map((image) {
              return Image.network(
                image.url ?? "",
                fit: BoxFit.cover,
                errorBuilder: (ctx, _, __) => Container(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey[200], 
                  child: Icon(Icons.broken_image, color: Theme.of(context).hintColor)
                ),
              );
            }).toList(),
          );

    return Stack(
      children: [
        Container(
          height: 380, 
          width: double.infinity,
          color: Theme.of(context).cardColor,
          padding: const EdgeInsets.only(top: 60), 
          child: Column(
            children: [
              imageWidget,
              if (images.length > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: images.asMap().entries.map((entry) {
                    return Container(
                      width: 6.0,
                      height: 6.0,
                      margin: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 3.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == entry.key
                            ? const Color(0xFF27C16B)
                            : Colors.grey.withOpacity(0.3),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),

        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircleIcon(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                       _buildCircleIcon(
                        icon: Icons.search,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BlocProvider(
                                create: (context) => SearchBloc(SearchRepositoryImp()), 
                                child: const SearchScreen(),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      
                      _buildCircleIcon(
                        icon: Icons.share_outlined,
                        onTap: () {
                          String productName = widget.productData?.name ?? "Product";
                          String urlKey = widget.productData?.urlKey ?? "";
                          String shareText = "Check out $productName! \nhttps://your-website.com/$urlKey";
                          Share.share(shareText);
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),

        Positioned(
          right: 16.0,
          top: 280.0, 
          child: _buildCircleIcon(
            icon: isInWishlist ? Icons.favorite : Icons.favorite_border,
            color: isInWishlist ? Colors.red : Colors.grey,
            onTap: () {
              if (appStoragePref.getCustomerLoggedIn()) {
                setState(() {
                  widget.productData?.isInWishlist = !isInWishlist;
                });
                if (isInWishlist) {
                  widget.productScreenBLoc?.add(RemoveFromWishlistEvent(
                      widget.productData?.id, null)); 
                } else {
                  widget.productScreenBLoc?.add(AddToWishListProductEvent(
                      widget.productData?.id, null)); 
                }
              } else {
                ShowMessage.warningNotification("Please login to add to wishlist", context);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCircleIcon({required IconData icon, required VoidCallback onTap, Color color = Colors.black87}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, size: 22, color: color == Colors.black87 ? Theme.of(context).iconTheme.color : color),
      ),
    );
  }

  // =========================================================
  // 2. PRODUCT INFO
  // =========================================================
  Widget _buildProductInfo() {
    // 🟢 Use new robust formatter
    String finalPrice = _getFormattedPrice(widget.productData);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF4F6F8),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined, 
                  size: 12, 
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7)
                ),
                SizedBox(width: 4),
                Text(
                  "12 mins", 
                  style: TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.bold, 
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7)
                  )
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Text(
            widget.productData?.name ?? "",
            style: TextStyle(
              fontSize: 17, 
              fontWeight: FontWeight.w600, 
              color: Theme.of(context).textTheme.titleLarge?.color,
              height: 1.3,
              fontFamily: 'sans-serif', 
            ),
          ),
          const SizedBox(height: 8),

          if (widget.productData?.sku != null)
            Text(
              "1 Unit", 
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    finalPrice,
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF81C784) : Colors.black
                    ),
                  ),
                  const Text(
                    "(Inclusive of all taxes)",
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
              _buildBlinkitAddButton(),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // 3. ADD BUTTON
  // =========================================================
  Widget _buildBlinkitAddButton() {
    return StreamBuilder<Map<String, Map<String, dynamic>>>(
      stream: GlobalData.cartItemsController.stream,
      builder: (context, snapshot) {
        int currentQty = 0;
        String? cartItemId;

        final cartMap = snapshot.data ?? GlobalData.cartItemsController.value;
        final info = cartMap[widget.productData?.id?.toString() ?? ""];
        if (info != null) {
          currentQty = info['qty'] ?? 0;
          cartItemId = info['cartItemId']?.toString();
        }
        
        bool hasItems = currentQty > 0;

        return Container(
          height: 36, 
          width: 100,
          decoration: BoxDecoration(
            color: hasItems ? const Color(0xFF27C16B) : Theme.of(context).cardColor,
            border: Border.all(color: const Color(0xFF27C16B)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: hasItems
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    InkWell(
                      onTap: () {
                         // DECREASE
                         if (cartItemId != null) {
                            int pid = int.tryParse(widget.productData?.id?.toString() ?? "0") ?? 0;
                            GlobalData.optimisticUpdateCart(pid, -1);

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
                      child: const Icon(Icons.remove, color: Colors.white, size: 18),
                    ),
                    Text(
                      "$currentQty",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    InkWell(
                      onTap: () {
                         // INCREASE
                         if (cartItemId != null) {
                            int pid = int.tryParse(widget.productData?.id?.toString() ?? "0") ?? 0;
                            GlobalData.optimisticUpdateCart(pid, 1);
                            
                            context.read<CartScreenBloc>().add(UpdateCartEvent(
                              [{'cartItemId': cartItemId, 'quantity': (currentQty + 1).toString()}]
                            ));
                         }
                      },
                      child: const Icon(Icons.add, color: Colors.white, size: 18),
                    ),
                  ],
                )
              : InkWell(
                  onTap: () {
                    // ADD INITIAL (1)
                    _addToCart(); 
                  },
                  child: const Center(
                    child: Text(
                      "ADD",
                      style: TextStyle(
                        color: Color(0xFF27C16B),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
        );
      }
    );
  }

  // =========================================================
  // 4. DESCRIPTION
  // =========================================================
  Widget _buildExpandableDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isDescriptionExpanded = !_isDescriptionExpanded;
              });
            },
            child: Row(
              children: [
                const Text(
                  "View product details",
                  style: TextStyle(
                    color: Color(0xFF27C16B), 
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isDescriptionExpanded 
                      ? Icons.keyboard_arrow_up 
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF27C16B),
                  size: 20,
                ),
              ],
            ),
          ),
          if (_isDescriptionExpanded) ...[
            const SizedBox(height: 12),
            Text(
              widget.productData?.description ?? "No description available.",
              style: TextStyle(
                fontSize: 13, 
                color: Colors.grey[700], 
                height: 1.5
              ),
            ),
          ]
        ],
      ),
    );
  }

  // =========================================================
  // 5. RELATED PRODUCTS
  // =========================================================
  Widget _buildRelatedProductsList() {
    List<dynamic> relatedProducts = [];
    
    if (widget.productData?.relatedProducts != null && 
        widget.productData!.relatedProducts!.isNotEmpty) {
      relatedProducts = widget.productData!.relatedProducts!;
    } 
    else {
      if (GlobalData.allProducts != null) {
        for (var section in GlobalData.allProducts!) {
           if (section?.data is List) {
             var items = section?.data as List;
             for (var item in items) {
               if (item.id != widget.productData?.id) {
                 relatedProducts.add(item); 
               }
             }
           }
        }
        relatedProducts.shuffle();
      }
    }

    if (relatedProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    if (relatedProducts.length > 10) {
      relatedProducts = relatedProducts.sublist(0, 10);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text(
            "Top products in this category",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(
          height: 260, // 🟢 Reduced from 320 to 260 for compact layout
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: relatedProducts.length,
            itemBuilder: (context, index) {
              var item = relatedProducts[index];
              return _buildRelatedProductCard(item); 
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedProductCard(dynamic product) {
    // We can cast `product` to `NewProducts` if possible, or `BlinkitProductCard` handles the data via the same model.
    // The `relatedProducts` list contains items from `GlobalData.allProducts` or `productData.relatedProducts`.
    // These are usually `NewProducts` or similar maps.
    // `BlinkitProductCard` expects `NewProducts?`.
    
    // Safety check:
    if (product is! NewProducts && product is Map) {
       // If it's a map (implied by previous code handling), we might need to convert or just fail gracefully.
       // But global allProducts usually has NewProducts objects inside `data`.
       return const SizedBox(); 
    }
    
    // Note: The previous code handled `product` as dynamic but accessed `.name`, `.id` etc.
    // We will assume it acts like NewProducts or IS one.
    
    return SizedBox(
      width: 160, // 🟢 Increased from 130 to 160 to prevent horizontal overflow
      child: BlinkitVerticalProductCard(
        data: product, // Assuming this is compatible
        isLoggedIn: appStoragePref.getCustomerLoggedIn(),
        // We pass callbacks if we want specific behavior, OR rely on BlinkitProductCard's internal logic.
        // BlinkitProductCard internal logic uses `subCategoryBloc` which we don't have here (we have ProductScreenBloc).
        // So we MUST provide callbacks OR pass a Bloc.
        // Since we are in ProductScreen, let's provide callbacks that use `widget.productScreenBLoc`.
        
        onAddToCart: (int id) {
           if (id > 0) {
             GlobalData.optimisticUpdateCart(id, 1);
             widget.productScreenBLoc?.add(AddToCartProductEvent(
               1, id.toString(), [], [], [], [], null, ""
             ));
           } else {
             // 🟢 Decrement Logic
             int pid = -id;
             final cartMap = GlobalData.cartItemsController.value;
             final info = cartMap[pid.toString()];
             if (info != null) {
               int currentQty = info['qty'] ?? 0;
               String? cartItemId = info['cartItemId']?.toString();
               
               GlobalData.optimisticUpdateCart(pid, -1);
               
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
             }
           }
        },
        
        onAddToWishlist: (String id, bool isInWishlist, dynamic p) {
           // Reuse wishlist logic
           if (isInWishlist) {
              widget.productScreenBLoc?.add(RemoveFromWishlistEvent(id, null));
           } else {
              widget.productScreenBLoc?.add(AddToWishListProductEvent(id, null));
           }
        },
      ),
    );
  }
  
  void _addToCart() {
  String safeProductId = widget.productData?.id?.toString() ?? "";

  if (safeProductId.isEmpty) {
     print("❌ Error: Product ID is missing");
     return;
  }

  GlobalData.optimisticUpdateCart(int.parse(safeProductId), 1);

  widget.productScreenBLoc?.add(
    AddToCartProductEvent(
      1,                // Quantity
      safeProductId,    
      [],               // Download links
      [],               // Grouped params
      [],               // Bundle params
      [],               // Configurable params
      null,             // Configurable ID
      "",               // Price
    ),
  );
}
}