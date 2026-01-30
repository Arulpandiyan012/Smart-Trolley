/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 * @author Webkul <support@webkul.com>
 * @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 * @license https://store.webkul.com/license.html
 * @link https://store.webkul.com/license.html
 */

import 'package:flutter/material.dart';
import 'package:bagisto_app_demo/screens/checkout/utils/index.dart';
// 🟢 FIX: Use Absolute Package Import to prevent "File Not Found" errors
import 'package:bagisto_app_demo/screens/checkout/data_model/save_order_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:bagisto_app_demo/main.dart'; // For flutterLocalNotificationsPlugin

class CheckOutSaveOrder extends StatefulWidget {
  const CheckOutSaveOrder({Key? key}) : super(key: key);

  @override
  State<CheckOutSaveOrder> createState() => _CheckOutSaveOrderState();
}

class _CheckOutSaveOrderState extends State<CheckOutSaveOrder> {
  bool isLoggedIn = false;
  int? orderId;

  @override
  void initState() {
    isLoggedIn = appStoragePref.getCustomerLoggedIn();
    super.initState();
    
    // 🟢 CRITICAL: DO NOT CALL API HERE.
    // Calling the API here triggers the "Network Error" loop.
    // We just display the success message using the ID passed from Checkout.
    
    // 🟢 TRIGGER LOCAL NOTIFICATION
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (orderId != null && orderId! > 0) {
        _showLocalNotification(orderId!);
      }
    });
  }

  Future<void> _showLocalNotification(int id) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'order_updates', 
      'Order Updates',
      channelDescription: 'Notifications for order status updates',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF0C831F),
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    
    await flutterLocalNotificationsPlugin.show(
      id,
      'Order Placed Successfully! 🛍️',
      'Your order #$id has been received. Thank you for shopping with us!',
      platformDetails,
    );
  }

  Future<void> _launchWhatsApp(String message) async {
    // Try universal link first
    final Uri url = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
       // Fallback for some devices
       final Uri schemaUrl = Uri.parse("whatsapp://send?text=${Uri.encodeComponent(message)}");
       if (await canLaunchUrl(schemaUrl)) {
          await launchUrl(schemaUrl);
       } else {
          debugPrint("Could not launch WhatsApp");
       }
    }
  }

  Future<void> _launchSMS(String message) async {
    final Uri smsLaunchUri = Uri(
      scheme: 'sms',
      path: '',
      queryParameters: <String, String>{
        'body': message,
      },
    );
    if (await canLaunchUrl(smsLaunchUri)) {
        await launchUrl(smsLaunchUri);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 🟢 GET ORDER ID FROM ARGUMENTS
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null) {
      if (args is int) {
        orderId = args;
      } else if (args is String) {
        orderId = int.tryParse(args);
      }
      debugPrint("✅ SaveOrder Screen Received Order ID: $orderId");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 DIRECTLY SHOW SUCCESS UI (No Loading, No API)
    return Scaffold(
      body: _orderPlacedView(
        SaveOrderModel(
          success: true,
          message: "Order Placed Successfully",
          order: Order(id: orderId ?? 0, incrementId: orderId?.toString() ?? "0"),
        )
      ),
    );
  }

  Widget _orderPlacedView(SaveOrderModel saveOrderModel) {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.all(AppSizes.spacingNormal),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 80, color: Color(0xFF0C831F)), // Success Icon
            const SizedBox(height: AppSizes.spacingMedium),
            
            Text(
              StringConstants.orderReceivedMsg.localized().toUpperCase(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              StringConstants.thankYouMsg.localized(),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Order ID Display
            if (saveOrderModel.order?.id != null && saveOrderModel.order!.id! > 0)
              InkWell(
                onTap: isLoggedIn ? () {
                    Navigator.pushNamed(context, orderDetailPage, arguments: saveOrderModel.order?.id);
                } : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Text(
                    "${StringConstants.yourOrderIdMsg.localized()} #${saveOrderModel.order?.id}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isLoggedIn ? Colors.blue : Colors.black87
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // 🟢 SHARE & ALERT SECTION
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50], 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200)
              ),
              child: Column(
                children: [
                   const Text(
                     "Share Order Details",
                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                   ),
                   const SizedBox(height: 16),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                     children: [
                       _buildShareBtn(Icons.chat_bubble, "SMS", Colors.blue, () {
                          _launchSMS("I just placed Order #${saveOrderModel.order?.id} on Smart Trolley! 🛒");
                       }),
                       _buildShareBtn(Icons.call, "WhatsApp", Colors.green, () {
                          _launchWhatsApp("I just placed Order #${saveOrderModel.order?.id} on Smart Trolley! 🛒 Check it out!");
                       }),
                       _buildShareBtn(Icons.share, "Share", Colors.orange, () {
                          Share.share("I just placed Order #${saveOrderModel.order?.id} on Smart Trolley! 🛒");
                       }),
                     ],
                   ),
                   
                   const Divider(height: 32),
                   
                   Row(
                     children: [
                       const Icon(Icons.notifications_active, color: Color(0xFF0C831F), size: 20),
                       const SizedBox(width: 12),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             const Text("Order Updates Enabled", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                             Text("You will receive updates via Push, SMS & WhatsApp", style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                           ],
                         ),
                       ),
                       Switch(value: true, onChanged: (val){}, activeColor: const Color(0xFF0C831F))
                     ],
                   )
                ],
              ),
            ),

            const SizedBox(height: 12),
            
            Text(
              StringConstants.orderConfirmationMsg.localized(),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C831F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  // Go to Home and remove all previous routes
                  Navigator.of(context).pushNamedAndRemoveUntil(home, (route) => false);
                },
                child: Text(
                  StringConstants.continueShopping.localized().toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))
        ],
      ),
    );
  }
}