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

// IMPORTANT: Ensure we import the file defining ProductScreenRepo if not in utils
import 'package:bagisto_app_demo/screens/product_screen/bloc/product_page_repository.dart';

// SEARCH SCREEN
import 'package:bagisto_app_demo/screens/search_screen/view/search_screen.dart';
import 'package:bagisto_app_demo/screens/search_screen/utils/index.dart' hide Status; 

class BlinkitProductBody extends StatefulWidget {
  final NewProducts? productData;
  final ProductScreenBLoc? productScreenBLoc;

  const BlinkitProductBody({
    super.key,
    this.productData,
    this.productScreenBLoc,
  });

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
            color: Colors.white, 
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 _buildProductInfo(), 
                 _buildExpandableDescription(),
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
                errorBuilder: (ctx, _, __) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
              );
            }).toList(),
          );

    return Stack(
      children: [
        Container(
          height: 380, 
          width: double.infinity,
          color: Colors.white,
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
                            ? const Color(0xFF0C831F)
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
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, size: 22, color: color),
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
              color: const Color(0xFFF4F6F8),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.timer_outlined, size: 12, color: Colors.black54),
                SizedBox(width: 4),
                Text(
                  "12 mins", 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Text(
            widget.productData?.name ?? "",
            style: const TextStyle(
              fontSize: 17, 
              fontWeight: FontWeight.w600, 
              color: Colors.black87,
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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    bool hasItems = _quantity > 0;

    return Container(
      height: 36, 
      width: 100,
      decoration: BoxDecoration(
        color: hasItems ? const Color(0xFF0C831F) : Colors.white,
        border: Border.all(color: const Color(0xFF0C831F)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: hasItems
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  onTap: () {
                    setState(() => _quantity--);
                  },
                  child: const Icon(Icons.remove, color: Colors.white, size: 18),
                ),
                Text(
                  "$_quantity",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                InkWell(
                  onTap: () {
                    setState(() => _quantity++);
                    _addToCart();
                  },
                  child: const Icon(Icons.add, color: Colors.white, size: 18),
                ),
              ],
            )
          : InkWell(
              onTap: () {
                setState(() => _quantity = 1);
                _addToCart();
              },
              child: const Center(
                child: Text(
                  "ADD",
                  style: TextStyle(
                    color: Color(0xFF0C831F),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
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
                    color: Color(0xFF0C831F), 
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isDescriptionExpanded 
                      ? Icons.keyboard_arrow_up 
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF0C831F),
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
          height: 270, 
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
    String imageUrl = "";
    if (product.images != null && product.images!.isNotEmpty) {
      imageUrl = product.images![0].url ?? "";
    }
    
    // 🟢 Use new robust formatter
    String displayPrice = _getFormattedPrice(product);

    return InkWell(
      onTap: () {
        ProductScreenRepo? capturedRepo = widget.productScreenBLoc?.repository;
        capturedRepo ??= ProductScreenRepo();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => ProductScreenBLoc(capturedRepo), 
              child: ProductScreen(
                title: product.name,
                productId: int.tryParse(product.id.toString()) ?? 0,
                urlKey: product.urlKey,
              ),
            ),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image, size: 50, color: Colors.grey);
                    },
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                         SizedBox(width: 2),
                         Text("10 MINS", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  Text(
                    product.name ?? "",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text("1 Unit", style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  const SizedBox(height: 8),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        displayPrice,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF0C831F)),
                          borderRadius: BorderRadius.circular(6),
                          color: const Color(0xFFF7FFF9),
                        ),
                        child: const Text(
                          "ADD",
                          style: TextStyle(
                            color: Color(0xFF0C831F),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
  
  void _addToCart() {
  String safeProductId = widget.productData?.id?.toString() ?? "";

  if (safeProductId.isEmpty) {
     print("❌ Error: Product ID is missing");
     return;
  }

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