import 'package:flutter/material.dart';
import 'package:bagisto_app_demo/utils/index.dart'; // 🟢 ADDED: Unified GlobalData & StringConstants
import 'package:bagisto_app_demo/screens/cart_screen/utils/cart_index.dart'; // 🟢 FIXED: Package import
import 'package:bagisto_app_demo/screens/cart_screen/utils/cart_extensions.dart'; // 🟢 FIXED: Package import


class PriceDetailView extends StatelessWidget {
  final CartModel cartDetailsModel;

  const PriceDetailView({Key? key, required this.cartDetailsModel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🟢 UNIFIED CALCULATIONS (Via Extension)
    double sub = cartDetailsModel.subTotalValue;
    double tax = cartDetailsModel.taxValue;
    double discount = cartDetailsModel.discountValue;
    double deliveryFee = cartDetailsModel.deliveryFeeValue;
    double adjustedGrand = cartDetailsModel.adjustedGrandTotal;

    
    // Delivery Threshold Info
    bool isFreeDelivery = sub > 500;
    double diffToFree = 500 - sub;

    String currency = GlobalData.currencyCode ?? "₹";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), 
            blurRadius: 4, 
            offset: const Offset(0, 2)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🟢 FREE DELIVERY BANNER (Synced with Extension)
          if (!isFreeDelivery && sub > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Add $currency${diffToFree.toStringAsFixed(0)} more for FREE Delivery!",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            )
          else if (isFreeDelivery)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Awesome! You've unlocked FREE Delivery",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),

          Text(
             StringConstants.priceDetails.localized(), 
             style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.w800, 
                color: Theme.of(context).textTheme.titleMedium?.color
              ),
          ),
          const SizedBox(height: 16),
          
          // Subtotal
          _buildRow(context, StringConstants.subTotal.localized(), "$currency ${sub.toStringAsFixed(2)}"),
          
          // Discount
          if (discount > 0)
             _buildRow(context, StringConstants.discount.localized(), "-$currency ${discount.toStringAsFixed(2)}", isGreen: true),

          // Tax
          if (tax > 0)
             _buildRow(context, StringConstants.tax.localized(), "$currency ${tax.toStringAsFixed(2)}"),

          // Delivery Charges
          _buildRow(
            context, 
            "Delivery Charges", 
            deliveryFee == 0 ? "FREE" : "$currency ${deliveryFee.toStringAsFixed(2)}", 
            isGreen: deliveryFee == 0
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1),
          ),
          
          // Grand Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                StringConstants.grandTotal.localized(),
                style: TextStyle(
                  fontWeight: FontWeight.w800, 
                  fontSize: 16,
                  color: Theme.of(context).textTheme.titleLarge?.color
                ),
              ),
              Text(
                "$currency ${adjustedGrand.toStringAsFixed(2)}",
                style: TextStyle(
                  fontWeight: FontWeight.w800, 
                  fontSize: 16,
                  color: const Color(0xFF27C16B)
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildRow(BuildContext context, String label, String value, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label, 
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 13, fontWeight: FontWeight.w500)
          ),
          Text(
            value, 
            style: TextStyle(
              color: isGreen ? Colors.green : Theme.of(context).textTheme.bodyLarge?.color, 
              fontSize: 13, 
              fontWeight: FontWeight.w600
            )
          ),
        ],
      ),
    );
  }
}