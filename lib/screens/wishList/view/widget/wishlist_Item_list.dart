/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:bagisto_app_demo/screens/wishList/utils/index.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  // Store quantity for each product ID
  Map<String, int> quantityMap = {};

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
            
            // Initialize Qty if not set
            if (productId.isNotEmpty && !quantityMap.containsKey(productId)) {
              quantityMap[productId] = 0; 
            }

            // Image URL
            String imageUrl = "";
            if((item?.product?.images ?? []).isNotEmpty) {
                 imageUrl = item?.product?.images![0].url ?? "";
            }

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
                  Stack(
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
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                                )
                              : const Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                      ),
                    ],
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
                              child: Text(
                                item?.product?.name ?? "",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            
                            // 🟢 DELETE ICON (INDIVIDUAL REMOVE)
                            GestureDetector(
                              onTap: () {
                                if (productId.isEmpty || productId == "0") {
                                  // Safety check to prevent accidental "Delete All"
                                  ShowMessage.errorNotification("Invalid Product ID", context);
                                  return;
                                }

                                widget.wishListBloc?.add(OnClickWishListLoaderEvent(isReqToShowLoader: true));
                                // 🟢 Sends only this product ID to delete
                                widget.wishListBloc?.add(FetchDeleteAddItemEvent(productId));
                              },
                              child: const Icon(Icons.close, size: 20, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        
                        Text(
                          item?.product?.priceHtml?.priceHtml ?? "",
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0C831F)),
                        ),

                        const SizedBox(height: 12),

                        // 3. BLINKIT STYLE ADD BUTTON
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildBlinkitAddButton(productId, wishlistId, isSaleable),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        
        if (widget.isLoading)
          Container(
            color: Colors.white.withOpacity(0.5),
            child: const Center(child: CircularProgressIndicator(color: Color(0xFF0C831F))),
          )
      ],
    );
  }

  // Blinkit Style Add Button
  Widget _buildBlinkitAddButton(String productId, String wishlistId, bool isSaleable) {
    if (productId.isEmpty) return const SizedBox(); // Safety

    int qty = quantityMap[productId] ?? 0;
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
                    setState(() {
                       if (qty > 0) quantityMap[productId] = qty - 1;
                    });
                  },
                  child: const Icon(Icons.remove, color: Colors.white, size: 18),
                ),
                Text(
                  "$qty",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                       quantityMap[productId] = qty + 1;
                       _addToCart(productId, wishlistId, (qty + 1).toString());
                    });
                  },
                  child: const Icon(Icons.add, color: Colors.white, size: 18),
                ),
              ],
            )
          : InkWell(
              onTap: () {
                setState(() {
                   quantityMap[productId] = 1;
                   _addToCart(productId, wishlistId, "1");
                });
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