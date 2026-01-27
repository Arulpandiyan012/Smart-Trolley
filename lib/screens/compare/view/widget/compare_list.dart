/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 * @author Webkul <support@webkul.com>
 * @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 * @license https://store.webkul.com/license.html
 * @link https://store.webkul.com/license.html
 */

import 'package:bagisto_app_demo/screens/compare/utils/index.dart';

class CompareList extends StatelessWidget {
  final CompareProductsData compareScreenModel;
  final CompareScreenBloc? compareScreenBloc;

  const CompareList(
      {super.key, this.compareScreenBloc, required this.compareScreenModel});

  @override
  Widget build(BuildContext context) {
    // Fixed width for columns
    double cardWidth = MediaQuery.of(context).size.width / 2.2;

    return SizedBox(
      // 🟢 FIX: Increased height to 420 to prevent "Bottom Overflow" error
      height: 420, 
      width: (compareScreenModel.data?.length ?? 0) * cardWidth,
      child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          scrollDirection: Axis.horizontal,
          itemCount: compareScreenModel.data?.length ?? 0,
          itemBuilder: (context, index) {
            var product = compareScreenModel.data?[index].product;
            int? rating;
            if (product?.averageRating != null) {
              rating = (double.parse(product?.averageRating.toString() ?? "0").toInt());
            }

            return Container(
              width: cardWidth,
              margin: const EdgeInsets.only(right: 12), // Better spacing
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- 1. PRODUCT IMAGE ---
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Container(
                          height: 140, // Reduced slightly to save space
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          color: Colors.white,
                          child: (product?.images?.isNotEmpty == true)
                              ? ImageView(
                                  url: product?.images?[0].url ?? "",
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.contain, 
                                )
                              : Icon(Icons.image_not_supported, color: Colors.grey[300], size: 40),
                        ),
                      ),
                      
                      const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

                      // --- 2. DETAILS SECTION ---
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Price
                            PriceWidgetHtml(
                              priceHtml: product?.priceHtml?.priceHtml ?? "",
                            ),
                            const SizedBox(height: 6),
                            
                            // Name (Limited lines to prevent overflow)
                            SizedBox(
                              height: 40, // Fixed height for text alignment
                              child: Text(
                                product?.name ?? "",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  height: 1.2
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Rating & Wishlist Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Rating Pill
                                if (product?.averageRating != null && product?.averageRating != "0")
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: ReviewColorHelper.getColor(double.parse(product?.averageRating.toString() ?? "0")),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "$rating",
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 2),
                                        const Icon(Icons.star, size: 10, color: Colors.white),
                                      ],
                                    ),
                                  )
                                else
                                  const SizedBox(height: 20), // Placeholder to keep alignment

                                // Wishlist Icon
                                InkWell(
                                  onTap: () {
                                    if (product?.isInWishlist ?? false) {
                                      compareScreenBloc?.add(FetchDeleteWishlistItemEvent(
                                          int.parse(product?.id ?? ""), compareScreenModel.data?[index]));
                                      compareScreenBloc?.add(OnClickCompareLoaderEvent(isReqToShowLoader: true));
                                    } else {
                                      compareScreenBloc?.add(AddToWishlistCompareEvent(
                                          product?.id, compareScreenModel.data?[index]));
                                      compareScreenBloc?.add(OnClickCompareLoaderEvent(isReqToShowLoader: true));
                                    }
                                  },
                                  child: Icon(
                                    (product?.isInWishlist ?? false) ? Icons.favorite : Icons.favorite_border,
                                    color: (product?.isInWishlist ?? false) ? Colors.red : Colors.grey[400],
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // --- 3. ADD TO CART BUTTON ---
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: SizedBox(
                          width: double.infinity,
                          height: 36, // Compact height
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                              padding: EdgeInsets.zero, // Remove internal padding
                            ),
                            onPressed: (product?.isSaleable ?? false)
                                ? () {
                                    compareScreenBloc?.add(OnClickCompareLoaderEvent(isReqToShowLoader: true));
                                    if (product?.type == StringConstants.simple || product?.type == StringConstants.virtual) {
                                      compareScreenBloc?.add(AddToCartCompareEvent((product?.id ?? ""), 1, ""));
                                    } else {
                                      ShowMessage.showNotification(StringConstants.addOptions.localized(), "", Colors.yellow, const Icon(Icons.warning_amber));
                                      compareScreenBloc?.add(OnClickCompareLoaderEvent(isReqToShowLoader: false));
                                    }
                                  }
                                : null,
                            child: Text(
                              StringConstants.addToCart.localized().toUpperCase(),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // --- 4. FLOATING DELETE BUTTON ---
                  Positioned(
                    right: 0,
                    top: 0,
                    child: InkWell(
                      onTap: () {
                        compareScreenBloc?.add(OnClickCompareLoaderEvent(isReqToShowLoader: true));
                        compareScreenBloc?.add(RemoveFromCompareListEvent(compareScreenModel.data?[index].productId ?? "", ""));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.05),
                          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), topRight: Radius.circular(12)),
                        ),
                        child: const Icon(Icons.close, size: 16, color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
    );
  }
}