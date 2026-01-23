/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 * @author Webkul <support@webkul.com>
 * @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 * @license https://store.webkul.com/license.html
 * @link https://store.webkul.com/license.html
 */

import 'package:bagisto_app_demo/screens/orders/utils/index.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 

class OrdersListTile extends StatelessWidget with OrderStatusBGColorHelper {
  final Data? data;
  final VoidCallback? reload;

  String capitalize(String str) {
    if (str.isEmpty) return "";
    return str[0].toUpperCase() + str.substring(1);
  }

  const OrdersListTile({super.key, this.data, this.reload});

  @override
  Widget build(BuildContext context) {
    // 🟢 1. SAFE DATE PARSING
    String displayDate = "Date: N/A";
    if (data?.createdAt != null && data!.createdAt.toString() != "null") {
      try {
        DateTime parsedDate = DateTime.parse(data!.createdAt.toString());
        // Format: 12 Oct 2024
        displayDate = DateFormat("dd MMM yyyy").format(parsedDate);
      } catch (e) {
        displayDate = data!.createdAt.toString();
      }
    }

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
                // 🟢 ROW 1: Order ID & Date & Status
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
                        const SizedBox(height: 4),
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

  // 🟢 HELPER: Colorful Status Badges
  Widget _buildStatusBadge(BuildContext context, String? status) {
    Color bgColor = const Color(0xFFF5F5F5);
    Color textColor = Colors.grey;
    String text = capitalize(status ?? "Pending");

    if (status == "pending") {
      bgColor = const Color(0xFFFFF8E1); // Light Orange
      textColor = const Color(0xFFFFA000); // Dark Orange
    } else if (status == "processing") {
      bgColor = const Color(0xFFE3F2FD); // Light Blue
      textColor = const Color(0xFF1976D2); // Dark Blue
    } else if (status == "completed") {
      bgColor = const Color(0xFFE8F5E9); // Light Green
      textColor = const Color(0xFF388E3C); // Dark Green
    } else if (status == "canceled") {
      bgColor = const Color(0xFFFFEBEE); // Light Red
      textColor = const Color(0xFFD32F2F); // Dark Red
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