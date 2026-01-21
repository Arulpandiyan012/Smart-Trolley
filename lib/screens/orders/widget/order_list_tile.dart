/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:bagisto_app_demo/screens/orders/utils/index.dart';
import 'package:flutter/material.dart';

class OrdersListTile extends StatelessWidget with OrderStatusBGColorHelper {
  final Data? data;
  final VoidCallback? reload;

  String capitalize(String str) {
    if (str.isEmpty) return "";
    return str[0].toUpperCase() + str.substring(1);
  }

  const OrdersListTile({Key? key, this.data, this.reload}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🟢 1. ROBUST DATE PARSING
    // We pass the raw string. If it's null, we handle it inside the helper.
    String displayDate = _formatDateToLocal(data?.createdAt);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // 🟢 2. CLICK ACTION
            Navigator.pushNamed(context, orderDetailPage, arguments: data?.id)
                .then((value) {
              if (reload != null) {
                reload!();
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🟢 ROW 1: Order ID & Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ORDER #${data?.id ?? '0'}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              displayDate,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    _buildStatusBadge(context, data?.status),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFF0F0F0)),
                ),

                // 🟢 ROW 2: Quantity & Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Column 1: Quantity
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ITEMS",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${data?.totalQtyOrdered ?? 1} Items",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),

                    // Column 2: Total Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "TOTAL AMOUNT",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data?.formattedPrice?.grandTotal ?? "₹0.00",
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Color(0xFF0C831F), // Brand Green
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // 🟢 ROW 3: Footer (View Details)
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "View Details",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🟢 HELPER: Stronger Date Parsing
  String _formatDateToLocal(String? serverDate) {
    // 1. Handle Nulls explicitly
    if (serverDate == null || serverDate == "null" || serverDate.isEmpty) {
      return "Date Not Available"; 
    }
    
    // 2. 🛠 FIX: Replace Space with T (e.g. "2026-01-20 18:00" -> "2026-01-20T18:00")
    // This fixes the most common parsing error in Flutter/Dart
    String cleanDate = serverDate.replaceAll(" ", "T");

    DateTime? utcDate;
    try {
      // 3. Try Standard Parse with "T"
      DateTime temp = DateTime.parse(cleanDate);
      // Force UTC interpretation
      utcDate = DateTime.utc(temp.year, temp.month, temp.day, temp.hour, temp.minute, temp.second);
    } catch (_) {
      // 4. Fallback: If parse fails, return the RAW string so we can see it.
      // This is better than "N/A" because you can debug the format.
      return serverDate; 
    }

    if (utcDate != null) {
      DateTime localDate = utcDate.toLocal(); // Convert to Device Time (IST)
      
      const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      String month = months[localDate.month - 1];
      
      String amPm = localDate.hour >= 12 ? "PM" : "AM";
      int hour12 = localDate.hour > 12 ? localDate.hour - 12 : (localDate.hour == 0 ? 12 : localDate.hour);
      String minute = localDate.minute.toString().padLeft(2, '0');

      return "${localDate.day} $month ${localDate.year}, $hour12:$minute $amPm";
    }

    return serverDate;
  }

  // 🟢 HELPER: Colorful Status Badges
  Widget _buildStatusBadge(BuildContext context, String? status) {
    Color bgColor = const Color(0xFFF5F5F5);
    Color textColor = Colors.grey;
    String text = capitalize(status ?? "Pending");

    if (status == "pending") {
      bgColor = const Color(0xFFFFF8E1); 
      textColor = const Color(0xFFFFA000); 
    } else if (status == "processing") {
      bgColor = const Color(0xFFE3F2FD); 
      textColor = const Color(0xFF1976D2); 
    } else if (status == "completed") {
      bgColor = const Color(0xFFE8F5E9); 
      textColor = const Color(0xFF388E3C); 
    } else if (status == "canceled") {
      bgColor = const Color(0xFFFFEBEE); 
      textColor = const Color(0xFFD32F2F); 
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: bgColor.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3
        ),
      ),
    );
  }
}