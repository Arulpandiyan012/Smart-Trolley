import 'package:flutter/material.dart';
import 'package:bagisto_app_demo/utils/index.dart'; 
import 'package:bagisto_app_demo/utils/app_global_data.dart'; 
import 'package:bagisto_app_demo/widgets/image_view.dart';
import 'package:bagisto_app_demo/screens/home_page/utils/route_argument_helper.dart';

class BlinkitVerticalProductCard extends StatelessWidget {
  final dynamic data;
  final void Function(int id)? onAddToCart;
  final void Function(String id, bool isInWishlist, dynamic product)? onAddToWishlist;
  final double width;
  final bool? isLoggedIn;

  const BlinkitVerticalProductCard({
    Key? key, 
    required this.data, 
    this.onAddToCart, 
    this.onAddToWishlist,
    this.width = 150.0,
    this.isLoggedIn,
  }) : super(key: key);

  String? _imageFromAny(dynamic img) {
    if (img == null) return null;
    try { if (img.url is String && img.url.isNotEmpty) return img.url; } catch (_) {}
    try { if (img.imageUrl is String && img.imageUrl.isNotEmpty) return img.imageUrl; } catch (_) {}
    try { if (img.path is String && img.path.isNotEmpty) return img.path; } catch (_) {}
    return null;
  }

  String? _productImage(dynamic p) {
    try {
      final imgs = (p as dynamic).images;
      if (imgs is List && imgs.isNotEmpty) {
        final u = _imageFromAny(imgs.first);
        if (u != null && u.isNotEmpty) return u;
      }
    } catch (_) {}
    try {
      final v = (p as dynamic).baseImage?.url;
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}
    return null;
  }

  String _productPrice(dynamic p) {
     dynamic ph;
     try { ph = (p as dynamic).priceHtml; } catch (_) {}
     
     try {
       final f = (ph as dynamic)?.formattedFinalPrice?.toString();
       if (f != null) return f;
     } catch (_) {}
     
     final sym = "₹";
     try {
       final val = (p as dynamic).price;
       if (val != null) return "$sym$val";
     } catch (_) {}
     
     return "";
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _productImage(data);
    final name = (data as dynamic).name?.toString() ?? "";
    final priceText = _productPrice(data);
    final productId = int.tryParse((data as dynamic).id?.toString() ?? '0') ?? 0;
    bool isInWishlist = (data as dynamic).isInWishlist ?? false;

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          productScreen,
          arguments: PassProductData(
            title: name,
            urlKey: (data as dynamic).urlKey,
            productId: productId,
          ),
        );
      },
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE SECTION
            // IMAGE SECTION with ADD BUTTON Overlay
            Stack(
              clipBehavior: Clip.none, // Allow overflow if needed
              children: [
                Container(
                  height: 85, // 🟢 Reduced to 85 to save vertical space
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  ),
                  child: (imageUrl != null && imageUrl.isNotEmpty)
                      ? ImageView(
                          url: imageUrl,
                          fit: BoxFit.contain,
                        )
                      : const Icon(Icons.image, size: 40, color: Colors.grey),
                ),

                // Wishlist Icon (Top Right)
                Positioned(
                  top: 4,
                  right: 4,
                  child: InkWell(
                    onTap: () {
                       if (onAddToWishlist != null) {
                         onAddToWishlist!(productId.toString(), isInWishlist, data);
                       }
                    },
                    child: Container(
                      width: 24, height: 24,
                      decoration: const BoxDecoration(
                         shape: BoxShape.circle,
                         color: Colors.transparent, 
                      ),
                      child: Icon(
                        isInWishlist ? Icons.favorite : Icons.favorite_border, 
                        size: 16, 
                        color: isInWishlist ? Colors.red : Colors.grey[400]
                      ),
                    ),
                  ),
                ),
                


                // 🟢 ADD BUTTON (Overlays Bottom Right of Image)
                Positioned(
                  bottom: 6, 
                  right: 6,
                  child: InkWell(
                    onTap: () => onAddToCart?.call(productId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), // 🟢 Further Reduced Size
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF27C16B), width: 1),
                        borderRadius: BorderRadius.circular(6),
                        color: const Color(0xFFF7FFF9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 2,
                            offset: const Offset(0, 1)
                          )
                        ]
                      ),
                      child: const Text(
                        "ADD",
                        style: TextStyle(
                          color: Color(0xFF27C16B),
                          fontWeight: FontWeight.w800,
                          fontSize: 9, // 🟢 Further Reduced Font
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 2), // 🟢 Minimal Padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NAME
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11, // Slightly larger font
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        color: Colors.black87,
                      ),
                    ),

                    
                    // UNIT
                    Text(
                      "1 Unit",
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    ),
                    const SizedBox(height: 4),

                    // 🟢 RATING STARS
                    Builder(
                      builder: (context) {
                        // 1. Extract Product ID
                        String pid = (data as dynamic).id?.toString() ?? "0";

                        // 2. Extract Rating & Count (Standard Way)
                        double rating = 0.0;
                        int reviewCount = 0;
                        try {
                           var r = (data as dynamic).averageRating;
                           if (r == null) r = (data as dynamic).rating;
                           if (r != null) rating = double.tryParse(r.toString()) ?? 0.0;
                           
                           var reviews = (data as dynamic).reviews;
                           if (reviews is List) reviewCount = reviews.length;
                        } catch (_) {}
                        
                        // 🟢 3. FALLBACK: Check Custom Global Map (If Standard is Empty)
                        if (rating == 0 && reviewCount == 0 && GlobalData.customRatings.containsKey(pid)) {
                            var custom = GlobalData.customRatings[pid];
                            if (custom != null) {
                                rating = (custom['rating'] is num) ? (custom['rating'] as num).toDouble() : 0.0;
                                reviewCount = (custom['count'] is int) ? (custom['count'] as int) : 0;
                            }
                        }

                        return Row(
                          children: [
                            // Stars
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < rating.round() ? Icons.star : Icons.star_border, 
                                  size: 11,
                                  color: index < rating.round() ? const Color(0xFFF5C518) : Colors.grey[300], // Amber vs Grey
                                );
                              }),
                            ),
                            const SizedBox(width: 4),
                            // Count (Only show if > 0)
                            if (reviewCount > 0)
                              Text(
                                "($reviewCount)",
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500
                                ),
                              )
                          ],
                        );
                      }
                    ),
                    


                    // TIMER TAG (Moved from Image)
                    Container(
                      margin: const EdgeInsets.only(bottom: 2, top: 2), // Added top margin
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
                          Text("12 MINS", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),

                    const Spacer(), 

                    // PRICE (Rate) - Now below name
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "₹", 
                            style: TextStyle(
                              fontFamily: 'Roboto', 
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.black87,
                            ) 
                          ),
                          TextSpan(
                            text: priceText.replaceAll("₹", "").trim(), 
                            style: TextStyle(
                               fontSize: 12,
                               fontWeight: FontWeight.w700,
                               color: Colors.black87,
                            )
                          )
                        ]
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
