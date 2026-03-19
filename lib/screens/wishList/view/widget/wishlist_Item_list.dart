/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:bagisto_app_demo/screens/wishList/utils/index.dart';
import 'package:bagisto_app_demo/screens/cart_screen/utils/cart_index.dart';

class WishlistItemList extends StatefulWidget {
  final WishListData? model;
  final bool isLoading;
  final WishListBloc? wishListBloc;

  const WishlistItemList(
      {Key? key,
      required this.model,
      required this.isLoading,
      this.wishListBloc})
      : super(key: key);

  @override
  State<WishlistItemList> createState() => _WishlistItemListState();
}

class _WishlistItemListState extends State<WishlistItemList> {
  // No longer needed: using global cartItemsController

  String? _imageFromAny(dynamic img) {
    if (img == null) return null;
    
    // 1. Try common fields directly if it's an object with properties
    try { if (img.url is String && img.url.isNotEmpty) return img.url; } catch (_) {}
    try { if (img.small_image_url is String && img.small_image_url.isNotEmpty) return img.small_image_url; } catch (_) {}
    try { if (img.medium_image_url is String && img.medium_image_url.isNotEmpty) return img.medium_image_url; } catch (_) {}
    try { if (img.imageUrl is String && img.imageUrl.isNotEmpty) return img.imageUrl; } catch (_) {}
    try { if (img.path is String && img.path.isNotEmpty) return img.path; } catch (_) {}
    try { if (img.original is String && img.original.isNotEmpty) return img.original; } catch (_) {}
    
    // 2. Map-based access for safety/flexibility
    if (img is Map) {
       const keys = [
         'small_image_url', 'medium_image_url', 'large_image_url', 'original_image_url',
         'url', 'imageUrl', 'path', 'original', 'smallImageUrl'
       ];
       for (final k in keys) {
         final v = img[k];
         if (v is String && v.isNotEmpty) return v;
       }
    }
    return null;
  }

  String? _productImage(dynamic p) {
    if (p == null) return null;
    
    // 🟢 PRIORITY 1: Check direct URL fields (from API injection or models)
    try {
      final directUrl = (p as dynamic).imageUrl ?? 
                       (p as dynamic).base_image_url ?? 
                       (p as dynamic).small_image_url ?? 
                       (p as dynamic).base_image;
      if (directUrl is String && directUrl.isNotEmpty && !directUrl.endsWith("/storage/product/")) {
        debugPrint("💚 Found direct image URL: $directUrl");
        return directUrl;
      }
    } catch (_) {}
    
    // 🟢 PRIORITY 2: Check images array
    try {
      final imgs = (p as dynamic).images;
      if (imgs is List && imgs.isNotEmpty) {
        // Try all images, not just first
        for(var i in imgs) {
             final u = _imageFromAny(i);
             // Ensure it's a valid link, not just a folder path
             if (u != null && u.isNotEmpty && !u.endsWith("/storage/product/")) {
               debugPrint("💚 Found image from array: $u");
               return u;
             }
        }
      }
    } catch (_) {}
    
    // 🟢 PRIORITY 3: Check baseImage.url (Nested Object)
    try {
      final v = (p as dynamic).baseImage?.url;
      if (v is String && v.isNotEmpty && !v.endsWith("/storage/product/")) {
        debugPrint("💚 Found baseImage.url: $v");
        return v;
      }
    } catch (_) {}
    
    // 🟢 PRIORITY 4: Check productFlats (if available)
    try {
       final flats = (p as dynamic).productFlats;
       if (flats is List && flats.isNotEmpty) {
          // Sometimes flats has image info or we can use another field
       }
    } catch (_) {}
    
    debugPrint("⚠️ No valid image found for product: ${(p as dynamic).name}");
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: widget.model?.data?.length ?? 0,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (BuildContext context, int index) {
            WishlistData? item = widget.model?.data?[index];
            bool isSaleable = item?.product?.isSaleable ?? false;
            
            // 🟢 ROBUST ID EXTRACTION
            String productId = item?.product?.id ?? "";
            String wishlistId = item?.id ?? "";
            
            // 🟢 QUANTITY SYNC: Use global state
            return StreamBuilder<Map<String, Map<String, dynamic>>>(
              stream: GlobalData.cartItemsController.stream,
              builder: (context, snapshot) {
                int currentQty = 0;
                String? cartItemId;
                final cartMap = snapshot.data ?? {};
                final info = cartMap[productId];
                if (info != null) {
                  currentQty = info['qty'] ?? 0;
                  cartItemId = info['cartItemId']?.toString();
                }

                // 🟢 FIX: Moved imageUrl inside builder scope
                String imageUrl = _productImage(item?.product) ?? "";

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. IMAGE
                      InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            productScreen,
                            arguments: PassProductData(
                              title: item?.product?.name ?? "",
                              urlKey: item?.product?.urlKey,
                              productId: int.tryParse(productId) ?? 0,
                            ),
                          );
                        },
                        child: Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[100],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: imageUrl.isNotEmpty
                                    ? ImageView(
                                        url: imageUrl,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(Icons.image_not_supported, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
    
                      const SizedBox(width: 12),
    
                      // 2. DETAILS
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        productScreen,
                                        arguments: PassProductData(
                                          title: item?.product?.name ?? "",
                                          urlKey: item?.product?.urlKey,
                                          productId: int.tryParse(productId) ?? 0,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      item?.product?.name ?? "",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.2),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                
                                // 🟢 DELETE ICON (INDIVIDUAL REMOVE)
                                GestureDetector(
                                  onTap: () {
                                    if (productId.isEmpty || productId == "0") {
                                      ShowMessage.errorNotification("Invalid Product ID", context);
                                      return;
                                    }
                                    widget.wishListBloc?.add(OnClickWishListLoaderEvent(isReqToShowLoader: true));
                                    widget.wishListBloc?.add(FetchDeleteAddItemEvent(productId));
                                  },
                                  child: const Icon(Icons.close, size: 20, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            
                            Builder(builder: (ctx) {
                              String wishPrice = "";
                              // Use finalPrice (raw numeric) and format to 2 decimals
                              final rawFinal = item?.product?.priceHtml?.finalPrice;
                              if (rawFinal != null && rawFinal.isNotEmpty) {
                                double parsedPrice = double.tryParse(rawFinal) ?? 0;
                                wishPrice = "₹${parsedPrice.toStringAsFixed(2)}";
                              } else {
                                // Fallback: strip HTML tags from priceHtml and enforce 2 decimals
                                wishPrice = (item?.product?.priceHtml?.priceHtml ?? "")
                                    .replaceAllMapped(RegExp(r'(\.\d{2})\d+'), (match) => match.group(1)!);
                              }
                              return Text(
                                wishPrice,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF27C16B)),
                              );
                            }),
    
                            const SizedBox(height: 12),
    
                            // 3. BLINKIT STYLE ADD BUTTON
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _buildBlinkitAddButton(productId, wishlistId, currentQty, cartItemId, isSaleable),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
            );
          },
        ),
        
        if (widget.isLoading)
          Container(
            color: Colors.white.withOpacity(0.5),
            child: const Center(child: CircularProgressIndicator(color: Color(0xFF27C16B))),
          )
      ],
    );
  }

  // Blinkit Style Add Button
  Widget _buildBlinkitAddButton(String productId, String wishlistId, int qty, String? cartItemId, bool isSaleable) {
    if (productId.isEmpty) return const SizedBox(); // Safety

    bool hasItems = qty > 0;

    if (!isSaleable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6)),
        child: const Text("OUT OF STOCK", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
      );
    }

    return Container(
      height: 36,
      width: 100,
      decoration: BoxDecoration(
        color: hasItems ? const Color(0xFF27C16B) : Colors.white,
        border: Border.all(color: const Color(0xFF27C16B)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: hasItems
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  onTap: () {
                    if (cartItemId != null) {
                      if (qty > 1) {
                         context.read<CartScreenBloc>().add(UpdateCartEvent(
                           [{'cartItemId': cartItemId, 'quantity': (qty - 1).toString()}]
                         ));
                      } else {
                         context.read<CartScreenBloc>().add(RemoveCartItemEvent(
                           cartItemId: int.parse(cartItemId)
                         ));
                      }
                    }
                  },
                  child: const Icon(Icons.remove, color: Colors.white, size: 18),
                ),
                Text(
                  "$qty",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                InkWell(
                  onTap: () {
                    if (cartItemId != null) {
                       context.read<CartScreenBloc>().add(UpdateCartEvent(
                         [{'cartItemId': cartItemId, 'quantity': (qty + 1).toString()}]
                       ));
                    }
                  },
                  child: const Icon(Icons.add, color: Colors.white, size: 18),
                ),
              ],
            )
          : InkWell(
              onTap: () {
                 _addToCart(productId, wishlistId, "1");
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

  void _addToCart(String productId, String wishlistId, String qty) {
     if (productId.isEmpty || wishlistId.isEmpty) return;

     widget.wishListBloc?.add(OnClickWishListLoaderEvent(isReqToShowLoader: true));
     // Send Combined ID for Add logic
     widget.wishListBloc?.add(AddToCartWishlistEvent(
       "$wishlistId:$productId", 
       qty
     ));
  }
}