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

class CheckOutSaveOrder extends StatefulWidget {
  const CheckOutSaveOrder({super.key});

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
}