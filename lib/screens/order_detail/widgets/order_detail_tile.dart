/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bagisto_app_demo/widgets/image_view.dart';
import 'package:bagisto_app_demo/screens/order_detail/utils/index.dart';
import 'package:bagisto_app_demo/utils/index.dart';
import 'package:bagisto_app_demo/screens/tracking/live_tracking_map_screen.dart';
import 'package:bagisto_app_demo/screens/home_page/utils/route_argument_helper.dart';
import 'package:bagisto_app_demo/screens/product_screen/bloc/product_page_bloc.dart';
import 'package:bagisto_app_demo/screens/product_screen/bloc/product_page_event.dart';
import 'package:bagisto_app_demo/screens/product_screen/bloc/product_page_state.dart';
import 'package:bagisto_app_demo/data_model/app_route_arguments.dart';
import 'package:bagisto_app_demo/data_model/review_model/review_model.dart';
import 'package:bagisto_app_demo/screens/product_screen/bloc/product_page_repository.dart';

// Cache for product images to avoid repeated API calls
class _ProductImageCache {
  static final Map<String, String?> _cache = {};
  
  static Future<String?> getProductImage(int productId) async {
    final key = 'product_$productId';
    if (_cache.containsKey(key)) {
      return _cache[key];
    }
    // Mark as loading to prevent duplicate requests
    _cache[key] = '';
    return null;
  }
  
  static void setProductImage(int productId, String? imageUrl) {
    _cache['product_$productId'] = imageUrl;
  }
} 

class OrderDetailTile extends StatelessWidget with OrderStatusBGColorHelper {
  final OrderDetail? orderDetailModel;
  final List<ReviewData>? reviews;
  final int? orderId;
  final OrderDetailBloc? orderDetailBloc;
  final bool? isLoading;
  final VoidCallback? onCancelOrder;

  OrderDetailTile({
    Key? key,
    this.orderDetailModel,
    this.reviews,
    this.orderId,
    this.orderDetailBloc,
    this.isLoading,
    this.onCancelOrder, 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (orderDetailModel == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }

    bool isPending = (orderDetailModel?.status?.toLowerCase() ?? "") == "pending";
    bool isPickedUp = (orderDetailModel?.status?.toLowerCase() ?? "").contains("picked");

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor, 
      child: Stack(
        children: [
          RefreshIndicator(
            color: Theme.of(context).primaryColor,
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
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.05), 
                          blurRadius: 20, 
                          offset: const Offset(0, 8)
                        )
                      ],
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withOpacity(0.05),
                        width: 1
                      )
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. HEADER: Order ID & Date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "ORDER #${orderDetailModel?.id ?? ''}",
                                  style: TextStyle(
                                    fontSize: 18, 
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                    color: Theme.of(context).textTheme.titleLarge?.color
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDateToLocal(orderDetailModel?.createdAt),
                                  style: TextStyle(
                                    fontSize: 12, 
                                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                                    fontWeight: FontWeight.w500
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: getOrderBgColor(orderDetailModel?.status ?? "").withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getStatusIcon(orderDetailModel?.status),
                                color: getOrderBgColor(orderDetailModel?.status ?? ""),
                                size: 20,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        
                        // 🟢 TRENDY STATUS TIMELINE
                        _buildStatusTimeline(context, orderDetailModel?.status ?? ""),

                        const SizedBox(height: 24),
                        Divider(thickness: 1, height: 1, color: Theme.of(context).dividerColor.withOpacity(0.1)),
                        const SizedBox(height: 20),

                        // 2. ITEMS ORDERED
                        const Text("Items Ordered", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 12),
                        if ((orderDetailModel?.items?.length ?? 0) == 0)
                          const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text('No items in this order', style: TextStyle(color: Colors.grey)),
                          )
                        else
                          ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: orderDetailModel?.items?.length ?? 0,
                            separatorBuilder: (context, index) => const Divider(height: 20),
                            itemBuilder: (buildContext, index) {
                              final item = orderDetailModel?.items?[index];
                              return _buildProductItem(item, buildContext);
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
                                context: context,
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
                                context: context,
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
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Total Amount", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Theme.of(context).textTheme.titleMedium?.color)),
                                  Text(
                                    orderDetailModel?.formattedPrice?.grandTotal ?? "0.00",
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.green),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Payment Method", style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6))),
                                  Text(
                                    orderDetailModel?.payment?.methodTitle ?? 'N/A', 
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodySmall?.color)
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // 5. CANCEL BUTTON
                        if (isPending) ...[
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withOpacity(0.1),
                                foregroundColor: Colors.red,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  side: const BorderSide(color: Colors.red, width: 1.5)
                                ),
                              ),
                              onPressed: onCancelOrder,
                              child: const Text("CANCEL ORDER", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.2)),
                            ),
                          ),
                        ],

                        // 🟢 ADDED: TRACK ORDER BUTTON (Manual Entry)
                        if (isPickedUp) ...[
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LiveTrackingMapScreen(
                                      orderId: (orderDetailModel?.id ?? 0).toString(),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.location_on),
                              label: const Text(
                                "Track Your Order Live", 
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                              ),
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
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            )
        ],
      ),
    );
  }

  // --- 🟢 UPDATED HELPER: Handles both ISO and "20 Jan 2026" formats ---
  String _formatDateToLocal(String? serverDate) {
    if (serverDate == null || serverDate.isEmpty) return "N/A";
    
    DateTime? utcDate;

    try {
      // Strategy 1: Try Standard ISO Parse (e.g. "2026-01-20 16:56:00")
      DateTime temp = DateTime.parse(serverDate);
      utcDate = DateTime.utc(temp.year, temp.month, temp.day, temp.hour, temp.minute, temp.second);
    } catch (_) {
      // Strategy 2: Try parsing "20 Jan 2026, 04:56 PM" manually
      try {
        // Clean string: "20 Jan 2026 04:56 PM"
        String clean = serverDate.replaceAll(",", ""); 
        List<String> parts = clean.split(" "); 
        // Expected parts: [20, Jan, 2026, 04:56, PM]
        
        if (parts.length >= 5) {
            int day = int.parse(parts[0]);
            String monthStr = parts[1];
            int year = int.parse(parts[2]);
            
            List<String> timeParts = parts[3].split(":");
            int hour = int.parse(timeParts[0]);
            int minute = int.parse(timeParts[1]);
            String amPm = parts[4];

            const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
            int month = months.indexOf(monthStr) + 1;

            if (amPm == "PM" && hour < 12) hour += 12;
            if (amPm == "AM" && hour == 12) hour = 0;

            utcDate = DateTime.utc(year, month, day, hour, minute);
        }
      } catch (e) {
         // If both fail, return original
         return serverDate;
      }
    }

    if (utcDate != null) {
      // Convert to Local (Device Time)
      DateTime localDate = utcDate.toLocal();

      // Format back to readable string
      const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      String month = months[localDate.month - 1];
      
      String amPm = localDate.hour >= 12 ? "PM" : "AM";
      int hour12 = localDate.hour > 12 ? localDate.hour - 12 : (localDate.hour == 0 ? 12 : localDate.hour);
      String minute = localDate.minute.toString().padLeft(2, '0');

      return "${localDate.day} $month ${localDate.year}, $hour12:$minute $amPm";
    }

    return serverDate;
  }

  IconData _getStatusIcon(String? status) {
    if (status == null) return Icons.hourglass_empty;
    String s = status.toLowerCase();
    if (s == "completed" || s == "delivered" || s == "picked up" || s == "picked_up" || s == "received") {
      return Icons.check_circle;
    }
    if (s == "canceled" || s == "closed") return Icons.cancel;
    if (s == "processing") return Icons.sync;
    return Icons.info_outline;
  }

  Widget _buildStatusTimeline(BuildContext context, String currentStatus) {
    String s = currentStatus.toLowerCase();
    bool isCanceled = s == "canceled" || s == "closed";
    
    // Normal Flow: Pending -> Processing -> Delivered
    List<Map<String, dynamic>> stages = [
      {"label": "Pending", "icon": Icons.assignment_outlined, "active": true},
      {"label": "Processing", "icon": Icons.sync, "active": s == "processing" || s == "completed" || s == "delivered" || s == "picked_up" || s == "picked up"},
      {"label": "Delivered", "icon": Icons.done_all, "active": s == "completed" || s == "delivered" || s == "picked_up" || s == "picked up"},
    ];

    if (isCanceled) {
      stages = [
        {"label": "Placed", "icon": Icons.assignment_outlined, "active": true},
        {"label": "Canceled", "icon": Icons.cancel, "active": true, "color": Colors.red},
      ];
    }

    return Row(
      children: List.generate(stages.length, (index) {
        bool isActive = stages[index]["active"];
        Color color = stages[index]["color"] ?? (isActive ? getOrderBgColor(currentStatus) : Theme.of(context).dividerColor.withOpacity(0.2));
        
        return Expanded(
          child: Row(
            children: [
              // Point + Label
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withOpacity(isActive ? 0.5 : 0.1), width: 1)
                    ),
                    child: Icon(stages[index]["icon"], size: 16, color: color),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stages[index]["label"],
                    style: TextStyle(
                      fontSize: 10, 
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w400,
                      color: isActive ? color : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5)
                    ),
                  )
                ],
              ),
              // Connector Line
              if (index < stages.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(left: 4, right: 4, bottom: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(isActive ? 0.5 : 0.1),
                          stages[index+1]["active"] ? getOrderBgColor(currentStatus).withOpacity(0.5) : Theme.of(context).dividerColor.withOpacity(0.1)
                        ]
                      )
                    ),
                  ),
                )
            ],
          ),
        );
      }),
    );
  }

  // --- 🟢 RESTORED: Status Label Mapping ---
  String _getStatusLabel(String? status) {
    if (status == null) return "PENDING";
    String s = status.toLowerCase();
    if (s == "completed" || s == "delivered" || s == "picked up" || s == "picked_up" || s == "received") {
      return "DELIVERED";
    }
    return s.toUpperCase();
  }

  Widget _buildAddressNode({required BuildContext context, required IconData icon, required String title, required dynamic address, required bool alignLeft}) {
    CrossAxisAlignment align = alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    TextAlign textAlign = alignLeft ? TextAlign.left : TextAlign.right;

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
            boxShadow: [
               BoxShadow(
                 color: Colors.black.withOpacity(0.05),
                 blurRadius: 10,
                 offset: const Offset(0, 4)
               )
            ]
          ),
          child: Icon(icon, size: 22, color: Theme.of(context).iconTheme.color?.withOpacity(0.8)),
        ),
        const SizedBox(height: 12),
        Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5))),
        const SizedBox(height: 6),
        Text(
          "${address?.firstName ?? ''} ${address?.lastName ?? ''}", 
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Theme.of(context).textTheme.titleSmall?.color),
          textAlign: textAlign,
        ),
        const SizedBox(height: 4),
        Text(
          _getFullAddress(address), 
          style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7), height: 1.5),
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
        ),
        const SizedBox(height: 8),
        if (address?.phone != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4)
            ),
            child: Text(
              "📞 ${address?.phone}",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodySmall?.color),
              textAlign: textAlign,
            ),
          ),
      ],
    );
  }

  Widget _buildProductItem(var item, BuildContext buildContext) {
    if (item == null) return const SizedBox();
    
    final hasProductId = item.product?.id != null && item.product!.id!.isNotEmpty;
    final hasUrlKey = item.product?.urlKey != null && item.product!.urlKey!.isNotEmpty;
    final canNavigate = hasProductId || hasUrlKey;
    final productId = hasProductId ? int.tryParse(item.product?.id ?? "") : null;

    return GestureDetector(
      onTap: () {
        if (canNavigate) {
          String? urlKeyToUse = hasUrlKey ? item.product?.urlKey : null;
          int? productIdToUse = productId;
          
          print('✅ NAVIGATION - Product: ${item.product?.name}, ID: ${item.product?.id}, Parsed ID: $productIdToUse, URLKey: $urlKeyToUse');
          
          Navigator.pushNamed(buildContext, productScreen,
            arguments: PassProductData(
              title: item.product?.name,
              urlKey: urlKeyToUse,
              productId: productIdToUse ?? 0
            )
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(buildContext).cardColor,
          border: Border.all(color: Theme.of(buildContext).dividerColor.withOpacity(0.05)),
          boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(0.02),
               blurRadius: 10,
               offset: const Offset(0, 4)
             )
          ]
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product Image - Fetch from API instead of broken order endpoint
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: Theme.of(buildContext).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(buildContext).dividerColor.withOpacity(0.1)),
              ),
              child: productId != null && productId > 0
                ? _ProductImageWidget(productId: productId)
                : Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.shopping_bag_outlined, size: 32, color: Colors.grey)
                    ),
                  ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.name ?? "", 
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(buildContext).textTheme.titleMedium?.color), 
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.formattedPrice?.price ?? "", 
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.green)
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "SKU: ${item.sku ?? 'N/A'}", 
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Theme.of(buildContext).textTheme.bodySmall?.color?.withOpacity(0.5)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "x${item.qtyOrdered}", 
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)
                        ),
                      ),
                      // Existing View Button
                      GestureDetector(
                        onTap: () {
                           if (canNavigate) {
                            String? urlKeyToUse = hasUrlKey ? item.product?.urlKey : null;
                            int? productIdToUse = productId;
                            Navigator.pushNamed(buildContext, productScreen,
                              arguments: PassProductData(
                                title: item.product?.name,
                                urlKey: urlKeyToUse,
                                productId: productIdToUse ?? 0
                              )
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: canNavigate ? Colors.green[50] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: canNavigate ? Colors.green[200]! : Colors.grey[300]!, 
                              width: 0.5
                            )
                          ),
                          child: Text(
                            canNavigate ? "View" : "N/A",
                            style: TextStyle(
                              fontSize: 10, 
                              fontWeight: FontWeight.bold, 
                              color: canNavigate ? Colors.green : Colors.grey
                            )
                          ),
                        ),
                      ),
                    ],
                  ),
                  // 🟢 NEW ROW FOR REVIEW (Eliminates horizontal overflow)
                  if ((orderDetailModel?.status?.toLowerCase() ?? "") == "completed" || 
                      (orderDetailModel?.status?.toLowerCase() ?? "") == "delivered" ||
                      (orderDetailModel?.status?.toLowerCase() ?? "") == "picked up" ||
                      (orderDetailModel?.status?.toLowerCase() ?? "") == "picked_up" ||
                      (orderDetailModel?.status?.toLowerCase() ?? "") == "received") ...[
                      const SizedBox(height: 10),
                      _buildReviewSection(item, buildContext),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🟢 RESTORED: Review Widget Section
  Widget _buildReviewSection(var item, BuildContext context) {
    // 1. Find if a review exists for this product
    ReviewData? existingReview;
    
    if (reviews != null) {
      try {
        final itemPid = item.productId?.toString();
        final itemObjPid = item.product?.id?.toString();
        final itemSku = item.sku?.toString().toLowerCase();

        print("🔍 MATCHING START - Item: pid=$itemPid, objPid=$itemObjPid, sku=$itemSku");
        print("🔍 Total reviews to check: ${reviews!.length}");

        existingReview = reviews!.where((r) {
          final rPid = r.productId?.toString();
          final rObjPid = r.product?.id?.toString();
          final rSku = r.product?.sku?.toString().toLowerCase();
          
          bool matchId = false;
          if (rPid != null && (rPid == itemPid || rPid == itemObjPid)) matchId = true;
          if (rObjPid != null && (rObjPid == itemPid || rObjPid == itemObjPid)) matchId = true;
          
          bool matchSku = (itemSku != null && rSku != null && itemSku == rSku);
          
          print("   🤔 Checking Review ${r.id}: rPid=$rPid, rObjPid=$rObjPid, rSku=$rSku -> Match: ${matchId || matchSku}");
          
          return matchId || matchSku;
        }).firstOrNull;
        
        if (existingReview != null) {
          print("   ✅ MATCH FOUND: Review ${existingReview.id}");
        } else {
          print("   ❌ NO MATCH FOUND");
        }
      } catch (e) {
        print("   ⚠️ Match error: $e");
      }
    }

    if (existingReview != null) {
      // ✅ TRENDY DISPLAY: PROMINENT RATINGS for Reviewed Items
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 180),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.amber.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.05 : 0.1),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ],
          border: Border.all(color: Colors.amber.withOpacity(0.4), width: 1)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Display stars prominently
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < (existingReview?.rating ?? 0) ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
                const SizedBox(width: 8),
                // ✏️ TRENDY EDIT LINK
                GestureDetector(
                  onTap: () {
                    String image = "";
                    if (item.product?.images != null && item.product!.images!.isNotEmpty) {
                      image = item.product!.images![0].url ?? "";
                    }
                    Navigator.pushNamed(context, addReviewScreen,
                        arguments: AddReviewDetail(
                            productId: item.product?.id?.toString(), 
                            productName: item.product?.name, 
                            imageUrl: image,
                            reviewId: existingReview!.id,
                            rating: existingReview!.rating,
                            title: existingReview.title,
                            comment: existingReview.comment,
                        )).then((_) {
                          if (orderId != null) {
                            orderDetailBloc?.add(OrderDetailFetchDataEvent(orderId));
                          }
                        });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, size: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
            if (existingReview?.title != null && existingReview!.title!.isNotEmpty) 
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  existingReview.title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodySmall?.color),
                ),
              ),
          ],
        ),
      );
    } else {
      // ✍️ TRENDY "WRITE A REVIEW" BUTTON (Gradient & Animated feel)
      return GestureDetector(
        onTap: () {
          ReviewData? myReview;
          if (reviews != null && reviews!.isNotEmpty) {
            try {
              final itemPid = item.productId?.toString();
              final itemObjPid = item.product?.id?.toString();
              final itemSku = item.sku?.toString().toLowerCase();

              myReview = reviews!.where((r) {
                final rPid = r.productId?.toString();
                final rObjPid = r.product?.id?.toString();
                final rSku = r.product?.sku?.toString().toLowerCase();
                
                bool matchId = false;
                if (rPid != null && (rPid == itemPid || rPid == itemObjPid)) matchId = true;
                if (rObjPid != null && (rObjPid == itemPid || rObjPid == itemObjPid)) matchId = true;
                
                bool matchSku = (itemSku != null && rSku != null && itemSku == rSku);
                return matchId || matchSku;
              }).firstOrNull;
            } catch (_) {}
          }

          String image = "";
          if (item.product?.images != null && item.product!.images!.isNotEmpty) {
            image = item.product!.images![0].url ?? "";
          }
          Navigator.pushNamed(context, addReviewScreen,
              arguments: AddReviewDetail(
                  productId: item.product?.id?.toString(), 
                  productName: item.product?.name, 
                  imageUrl: image,
                  reviewId: myReview?.id,
                  rating: myReview?.rating,
                  title: myReview?.title,
                  comment: myReview?.comment,
              )).then((_) {
                if (orderId != null) {
                  orderDetailBloc?.add(OrderDetailFetchDataEvent(orderId));
                }
              });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber[400]!, Colors.orange[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.star_rounded, size: 14, color: Colors.white),
              SizedBox(width: 6),
              Text(
                "Rate Product",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }
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
          color: Theme.of(context).dividerColor.withOpacity(0.1),
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

// Separate widget to fetch and cache product images from GraphQL API
class _ProductImageWidget extends StatefulWidget {
  final int productId;

  const _ProductImageWidget({required this.productId});

  @override
  State<_ProductImageWidget> createState() => _ProductImageWidgetState();
}

class _ProductImageWidgetState extends State<_ProductImageWidget> {
  String? _cachedImageUrl;
  bool _isLoading = true;
  bool _hasFailed = false;

  @override
  void initState() {
    super.initState();
    _loadProductImage();
  }

  Future<void> _loadProductImage() async {
    try {
      // Try to get from cache first
      final cachedUrl = await _ProductImageCache.getProductImage(widget.productId);
      if (cachedUrl != null && cachedUrl.isNotEmpty) {
        setState(() {
          _cachedImageUrl = cachedUrl;
          _isLoading = false;
        });
        return;
      }

      // Fetch product details using the product API
      // Create a temporary bloc instance to fetch product
      final productsBloc = ProductScreenBLoc(ProductScreenRepo());
      productsBloc.add(FetchProductEvent("", productId: widget.productId));

      // Wait for the result
      await for (final state in productsBloc.stream) {
        if (state is FetchProductState) {
          if (state.productData?.images != null && state.productData!.images!.isNotEmpty) {
            final imageUrl = state.productData!.images![0].url;
            _ProductImageCache.setProductImage(widget.productId, imageUrl);
            if (mounted) {
              setState(() {
                _cachedImageUrl = imageUrl;
                _isLoading = false;
              });
            }
          } else {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasFailed = true;
              });
            }
          }
          break;
        }
      }
      productsBloc.close();
    } catch (e) {
      print('Error loading product image: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Theme.of(context).dividerColor.withOpacity(0.05),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 4),
              Text(
                'Loading...',
                style: TextStyle(fontSize: 9, color: Theme.of(context).textTheme.bodySmall?.color),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasFailed || _cachedImageUrl == null || _cachedImageUrl!.isEmpty) {
      return Container(
        color: Theme.of(context).dividerColor.withOpacity(0.03),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_outlined, size: 32, color: Theme.of(context).disabledColor),
              const SizedBox(height: 2),
              Text(
                'No Image',
                style: TextStyle(fontSize: 9, color: Theme.of(context).disabledColor),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: ImageView(
        url: _cachedImageUrl,
        fit: BoxFit.cover,
      ),
    );
  }
}