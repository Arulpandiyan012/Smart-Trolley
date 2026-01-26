/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagisto_app_demo/screens/order_detail/utils/index.dart';
import 'package:bagisto_app_demo/utils/server_configuration.dart';

class OrderDetailTile extends StatelessWidget with OrderStatusBGColorHelper {
  final OrderDetail? orderDetailModel;
  final int? orderId;
  final OrderDetailBloc? orderDetailBloc;
  final bool? isLoading;
  final VoidCallback? onCancelOrder;

  OrderDetailTile({
    super.key,
    this.orderDetailModel,
    this.orderId,
    this.orderDetailBloc,
    this.isLoading,
    this.onCancelOrder, 
  });

  @override
  Widget build(BuildContext context) {
    if (orderDetailModel == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }

    bool isPending = (orderDetailModel?.status?.toLowerCase() ?? "") == "pending";

    return Container(
      color: Colors.grey[100], 
      child: Stack(
        children: [
          RefreshIndicator(
            color: Colors.black,
            onRefresh: () {
              return Future.delayed(const Duration(seconds: 1), () {
                context.read<OrderDetailBloc>().add(OrderDetailFetchDataEvent(orderId));
              });
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  // --- THE SINGLE TILE (All Details in One Card) ---
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. HEADER: Order ID & Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "ORDER #${orderDetailModel?.id ?? ''}",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                
                                // 🟢 FIXED: Using helper to convert UTC -> Local Time
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Placed on: ${_formatDateToLocal(orderDetailModel?.createdAt)}",
                                      style: TextStyle(
                                        fontSize: 13, 
                                        color: Colors.grey[800], 
                                        fontWeight: FontWeight.w500
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: getOrderBgColor(orderDetailModel?.status ?? "").withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                (orderDetailModel?.status ?? "").toUpperCase(),
                                style: TextStyle(
                                  color: getOrderBgColor(orderDetailModel?.status ?? ""),
                                  fontSize: 11, fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        const Divider(thickness: 1, height: 1),
                        const SizedBox(height: 16),

                        // 2. ITEMS ORDERED
                        const Text("Items Ordered", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 12),
                        ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: orderDetailModel?.items?.length ?? 0,
                          separatorBuilder: (context, index) => const Divider(height: 20),
                          itemBuilder: (context, index) {
                            return _buildProductItem(orderDetailModel?.items?[index]);
                          },
                        ),

                        const SizedBox(height: 16),
                        const Divider(thickness: 1, height: 1),
                        const SizedBox(height: 16),

                        // 3. ADDRESS DETAILS
                        const Text("Delivery Details", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 16),
                        
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LEFT: BILLING
                            Expanded(
                              flex: 4,
                              child: _buildAddressNode(
                                icon: Icons.receipt_long, 
                                title: "Billing Address",
                                address: orderDetailModel?.billingAddress,
                                alignLeft: true
                              ),
                            ),
                            
                            // CENTER: LINE
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: _buildDottedLine(),
                              ),
                            ),

                            // RIGHT: SHIPPING
                            Expanded(
                              flex: 4,
                              child: _buildAddressNode(
                                icon: Icons.local_shipping_outlined, 
                                title: "Shipping Address",
                                address: orderDetailModel?.shippingAddress,
                                alignLeft: false 
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        const Divider(thickness: 1, height: 1),
                        const SizedBox(height: 16),

                        // 4. TOTAL & PAYMENT
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total Amount", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(
                              orderDetailModel?.formattedPrice?.grandTotal ?? "0.00",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        Text(
                          "Payment: ${orderDetailModel?.payment?.methodTitle ?? 'N/A'}", 
                          style: TextStyle(fontSize: 12, color: Colors.grey[600])
                        ),

                        // 5. CANCEL BUTTON
                        if (isPending) ...[
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 45,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[50],
                                foregroundColor: Colors.red,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(color: Colors.red, width: 1)
                                ),
                              ),
                              onPressed: onCancelOrder,
                              child: const Text("Cancel Order", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          if (isLoading ?? false)
            Container(
              color: Colors.white.withOpacity(0.6),
              child: const Center(child: CircularProgressIndicator()),
            )
        ],
      ),
    );
  }

  // --- 🟢 NEW HELPER: Formats Server Date (UTC) to Local Time ---
  String _formatDateToLocal(String? serverDate) {
    if (serverDate == null || serverDate.isEmpty) return "N/A";
    try {
      // 1. Parse string to DateTime (Initially it might be parsed as local but with wrong values)
      DateTime temp = DateTime.parse(serverDate);
      
      // 2. Force it to be UTC because server sends UTC without 'Z' usually
      DateTime utcDate = DateTime.utc(temp.year, temp.month, temp.day, temp.hour, temp.minute, temp.second);
      
      // 3. Convert to Device Local Time (Adds +5:30 for India)
      DateTime localDate = utcDate.toLocal();

      // 4. Format manually to "14 Jan 2026, 11:42 PM"
      const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      String month = months[localDate.month - 1];
      
      String amPm = localDate.hour >= 12 ? "PM" : "AM";
      int hour12 = localDate.hour > 12 ? localDate.hour - 12 : (localDate.hour == 0 ? 12 : localDate.hour);
      String minute = localDate.minute.toString().padLeft(2, '0');

      return "${localDate.day} $month ${localDate.year}, $hour12:$minute $amPm";
    } catch (e) {
      return serverDate; // Fallback
    }
  }

  Widget _buildAddressNode({required IconData icon, required String title, required dynamic address, required bool alignLeft}) {
    CrossAxisAlignment align = alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    TextAlign textAlign = alignLeft ? TextAlign.left : TextAlign.right;

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[200]!)
          ),
          child: Icon(icon, size: 20, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          "${address?.firstName ?? ''} ${address?.lastName ?? ''}", 
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          textAlign: textAlign,
        ),
        const SizedBox(height: 2),
        Text(
          _getFullAddress(address), 
          style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.4),
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
        ),
        const SizedBox(height: 4),
        if (address?.phone != null)
          Text(
            "Phone: ${address?.phone}",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
            textAlign: textAlign,
          ),
      ],
    );
  }

  Widget _buildProductItem(var item) {
    if (item == null) return const SizedBox();
    
    // 🟢 ULTIMATE BRUTE-FORCE IMAGE CRAWLER
    String imageUrl = "";
    
    // 1. Recursive Helper to find ANY image url in a dynamic Map
    String? crawlForImage(Map? data) {
       if (data == null) return null;
       
       // Priority 1: Known Bagisto Image Keys
       final keys = [
         "image_url", "image", "imageUrl", "url", "path", "product_image", 
         "base_image", "thumbnail", "small_image", "swatch_url",
         "small_image_url", "medium_image_url", "large_image_url", "original_image_url",
         "smallImageUrl", "mediumImageUrl", "largeImageUrl", "originalImageUrl"
       ];
       for (var k in keys) {
          if (data[k] != null && data[k] is String && data[k].toString().isNotEmpty) {
             String v = data[k].toString();
             if (v.contains(".") || v.startsWith("http") || v.startsWith("storage/")) return v;
          }
       }

       // Priority 2: Crawler (Check every value recursively)
       for (var entry in data.entries) {
          var v = entry.value;
          if (v is String && v.isNotEmpty) {
             if (v.toLowerCase().contains(".jpg") || v.toLowerCase().contains(".png") || v.toLowerCase().contains(".jpeg") || v.toLowerCase().contains(".webp")) {
                if (!v.contains(" ") && (v.contains("/") || v.startsWith("http"))) return v;
             }
          } else if (v is Map) {
             String? deep = crawlForImage(v);
             if (deep != null) return deep;
          } else if (v is List) {
             for (var item in v) {
                if (item is Map) {
                   String? deep = crawlForImage(item);
                   if (deep != null) return deep;
                } else if (item is String && item.isNotEmpty) {
                   if (item.toLowerCase().contains(".jpg") || item.toLowerCase().contains(".png")) return item;
                }
             }
          }
       }
       return null;
    }

    // 2. Start Crawling
    if (item is Items) {
       // Try item direct image first, then crawl item JSON, then try product images
       imageUrl = (item.image != null && item.image!.isNotEmpty) ? item.image! : (crawlForImage(item.rawData) ?? "");
       
       if (imageUrl.isEmpty && item.product != null) {
          imageUrl = (item.product!.image != null && item.product!.image!.isNotEmpty) ? item.product!.image! : (crawlForImage(item.product!.rawData) ?? "");
       }
    }

    // 3. Last Fallback: Check nested structures if crawling failed
    if (imageUrl.isEmpty && item.product?.baseImage != null) {
       imageUrl = item.product!.baseImage!.originalImageUrl ?? 
                  item.product!.baseImage!.largeImageUrl ??
                  item.product!.baseImage!.mediumImageUrl ?? 
                  item.product!.baseImage!.smallImageUrl ?? "";
    }

    // Fix Relative URLs OR Wrong Domains (Internal IPs / Localhost)
    if (imageUrl.isNotEmpty) {
       // 1. Convert suspicious absolute URLs (internal IPs) to relative paths
       if (imageUrl.startsWith("http")) {
          if (imageUrl.contains("192.168.") || imageUrl.contains("localhost") || imageUrl.contains("127.0.0.1")) {
              try {
                Uri uri = Uri.parse(imageUrl);
                imageUrl = uri.path; 
                if (uri.query.isNotEmpty) imageUrl = "$imageUrl?${uri.query}";
              } catch (_) {}
          }
       }
       
       // 2. Prefix relative URLs with baseDomain
       if (!imageUrl.startsWith("http")) {
          // Bagisto specific: Ensure storage/ prefix for paths like "products/1/x.jpg"
          if (!imageUrl.startsWith("/") && !imageUrl.startsWith("storage/")) {
             imageUrl = "storage/$imageUrl";
          }
          
          if (!imageUrl.startsWith("/")) {
             imageUrl = "/$imageUrl";
          }
          imageUrl = "$baseDomain$imageUrl";
       }
        
        // 3. STORAGE FIX: The server returns 500 for direct /storage/ but works for /cache/medium/
        if (imageUrl.contains("/storage/")) {
           imageUrl = imageUrl.replaceAll("/storage/", "/cache/medium/");
        }
     }
    
    return Row(
      children: [
        Container(
          width: 54, height: 54, // Slightly larger
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ImageView(
              url: imageUrl,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name ?? "", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2),
              const SizedBox(height: 4),
              Text("x${item.qtyOrdered}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
            ],
          ),
        ),
        Text(
          item.formattedPrice?.price ?? "", 
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black)
        ),
      ],
    );
  }

  Widget _buildDottedLine() {
    return SizedBox(
      height: 1,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 8,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => Container(
          width: 4, height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          color: Colors.grey[300],
        ),
      ),
    );
  }

  String _getFullAddress(dynamic address) {
    if (address == null) return "";
    String street = "";
    var addr1 = address.address1;
    if (addr1 is List && addr1.isNotEmpty) {
       street = addr1[0].toString();
    } else if (addr1 is String) {
       street = addr1;
    }
    street = street.replaceAll("[", "").replaceAll("]", "").replaceAll("\"", "");

    String city = address.city ?? "";
    String state = address.state ?? "";
    String country = address.country ?? "";
    String postcode = address.postcode ?? "";

    List<String> parts = [];
    if (street.isNotEmpty) parts.add(street);
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (country.isNotEmpty) parts.add(country);
    if (postcode.isNotEmpty) parts.add(postcode);

    return parts.join(", ");
  }
}