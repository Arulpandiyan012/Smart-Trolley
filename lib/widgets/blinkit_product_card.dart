import 'package:bagisto_app_demo/screens/categories_screen/utils/index.dart';
import 'package:flutter/material.dart'; // Ensure material is imported

class BlinkitProductCard extends StatelessWidget {
  final NewProducts? data;
  final bool isLoggedIn;
  final CategoryBloc? subCategoryBloc;

  const BlinkitProductCard({
    super.key,
    required this.data,
    this.isLoggedIn = false,
    this.subCategoryBloc,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Safe Data Extraction
    String imageUrl = "";
    if ((data?.images ?? []).isNotEmpty) {
      imageUrl = data?.images?.first.url ?? "";
    }

    // Safe Price Logic
    String price = data?.priceHtml?.formattedFinalPrice ?? "";
    if (price.isEmpty) {
      price = "₹${data?.price ?? '0'}";
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
        // 🟢 Reduced margins for a tighter list
        margin: const EdgeInsets.only(bottom: 8, left: 6, right: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10), // Slightly smaller radius
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            // --- MAIN CONTENT ---
            Row(
              children: [
                // LEFT: IMAGE (Reduced width to save space)
                Container(
                  width: 88, // 🟢 Reduced from 100 to 88
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          SizedBox(
                            height: 70, // 🟢 Reduced height
                            width: 70,
                            child: ImageView(
                              url: imageUrl,
                              fit: BoxFit.contain,
                            ),
                          ),
                          if (data?.isInSale ?? false)
                            Positioned(
                              top: 0,
                              left: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5365E3),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  "SALE",
                                  style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // RIGHT: DETAILS
                Expanded(
                  child: Padding(
                    // 🟢 Reduced padding for compactness
                    padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timer Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F6F8),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.timer_outlined, size: 9, color: Colors.black54),
                              SizedBox(width: 3),
                              Text("11 MINS", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Title (Reduced Font Size)
                        Padding(
                          padding: const EdgeInsets.only(right: 24.0), 
                          child: Text(
                            data?.name ?? "",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600, 
                              fontSize: 12, // 🟢 Reduced from 13 to 12
                              height: 1.2
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),

                        // Unit
                        Text(
                          "1 Unit",
                          style: TextStyle(color: Colors.grey[600], fontSize: 10),
                        ),
                        const SizedBox(height: 10),

                        // Price & ADD Button Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  price,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700, 
                                    fontSize: 13 // 🟢 Reduced from 14 to 13
                                  ),
                                ),
                                if (data?.priceHtml?.formattedRegularPrice != null &&
                                    (data?.priceHtml?.formattedRegularPrice?.isNotEmpty ?? false) &&
                                    data?.priceHtml?.formattedRegularPrice != price)
                                  Text(
                                    data!.priceHtml!.formattedRegularPrice!,
                                    style: const TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey,
                                        fontSize: 9),
                                  ),
                              ],
                            ),

                            // 🟢 COMPACT "ADD" BUTTON
                            InkWell(
                              onTap: () {
                                if (data?.isSaleable ?? false) {
                                  subCategoryBloc?.add(OnClickSubCategoriesLoaderEvent(isReqToShowLoader: true));
                                  if (data?.type == "simple" || data?.type == "virtual") {
                                    subCategoryBloc?.add(AddToCartSubCategoriesEvent((data?.id ?? ""), 1, ""));
                                  } else {
                                    ShowMessage.warningNotification("Select Options", context);
                                    subCategoryBloc?.add(OnClickSubCategoriesLoaderEvent(isReqToShowLoader: false));
                                  }
                                }
                              },
                              child: Container(
                                // 🟢 Significantly reduced padding
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5), 
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFF0C831F), width: 1),
                                  borderRadius: BorderRadius.circular(6),
                                  color: const Color(0xFFF7FFF9),
                                ),
                                child: const Text(
                                  "ADD",
                                  style: TextStyle(
                                    color: Color(0xFF0C831F),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11, // 🟢 Reduced from 12 to 11
                                  ),
                                ),
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

            // --- ICONS (Wishlist / Compare) ---
            Positioned(
              top: 6,
              right: 6,
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      subCategoryBloc?.add(OnClickSubCategoriesLoaderEvent(isReqToShowLoader: true));
                      if (isLoggedIn) {
                        if (data?.isInWishlist ?? false) {
                          subCategoryBloc?.add(FetchDeleteItemEvent(data?.id ?? "", data));
                        } else {
                          subCategoryBloc?.add(FetchDeleteAddItemCategoryEvent(data?.id, data));
                        }
                      } else {
                        ShowMessage.warningNotification(StringConstants.pleaseLogin.localized(), context);
                        subCategoryBloc?.add(OnClickSubCategoriesLoaderEvent(isReqToShowLoader: false));
                      }
                    },
                    child: _buildIconContainer(
                      icon: (data?.isInWishlist ?? false) ? Icons.favorite : Icons.favorite_border,
                      color: (data?.isInWishlist ?? false) ? Colors.red : Colors.grey,
                    ),
                  ),
                  
                  const SizedBox(height: 6), // Reduced gap

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
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- COMPACT ICON BUTTON ---
  Widget _buildIconContainer({required IconData icon, required Color color}) {
    return Container(
      width: 24, // 🟢 Reduced from 28
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Icon(
        icon,
        size: 14, // 🟢 Reduced from 16
        color: color,
      ),
    );
  }
}