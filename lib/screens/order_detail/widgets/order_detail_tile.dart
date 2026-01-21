/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagisto_app_demo/screens/order_detail/utils/index.dart';
import 'package:bagisto_app_demo/utils/index.dart'; 

class OrderDetailTile extends StatelessWidget with OrderStatusBGColorHelper {
  final OrderDetail? orderDetailModel;
  final int? orderId;
  final OrderDetailBloc? orderDetailBloc;
  final bool? isLoading;
  final VoidCallback? onCancelOrder;

  OrderDetailTile({
    Key? key,
    this.orderDetailModel,
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
                        // 1. HEADER: Order ID & Status (🟢 FIXED OVERFLOW)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start, 
                          children: [
                            // 🟢 Wrapped in Expanded to prevent right-side overflow
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "ORDER #${orderDetailModel?.id ?? ''}",
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  
                                  // 🟢 FIXED: Date Conversion Logic
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      // Flexible ensures text wraps if screen is small
                                      Flexible(
                                        child: Text(
                                          "Placed on: ${_formatDateToLocal(orderDetailModel?.createdAt)}",
                                          style: TextStyle(
                                            fontSize: 13, 
                                            color: Colors.grey[800], 
                                            fontWeight: FontWeight.w500
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(width: 8),

                            // Status Chip
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
    String imageUrl = "";
    if ((item.product?.images ?? []).isNotEmpty) {
        imageUrl = item.product?.images?[0].url ?? "";
    }

    return Row(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
            image: imageUrl.isNotEmpty 
              ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
              : null
          ),
          child: imageUrl.isEmpty ? const Icon(Icons.shopping_bag_outlined, size: 20, color: Colors.grey) : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name ?? "", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 2),
              const SizedBox(height: 2),
              Text("x${item.qtyOrdered}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
            ],
          ),
        ),
        Text(
          item.formattedPrice?.price ?? "", 
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)
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