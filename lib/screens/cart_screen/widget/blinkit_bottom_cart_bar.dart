import 'package:flutter/material.dart';
import 'package:bagisto_app_demo/utils/index.dart';
import 'package:bagisto_app_demo/screens/cart_screen/utils/cart_index.dart';
import 'package:bagisto_app_demo/screens/cart_screen/utils/cart_extensions.dart'; // 🟢 FIXED: Missing extension import


class BlinkitBottomCartBar extends StatelessWidget {
  final String? currentAddress;
  final String? userName;
  final CartModel cartDetailsModel;
  final bool quantityChanged;
  final VoidCallback onChangeAddressTap;
  final VoidCallback onProceedTap;
  final String buttonText;

  const BlinkitBottomCartBar({
    Key? key,
    required this.currentAddress,
    this.userName,
    required this.cartDetailsModel,
    required this.quantityChanged,
    required this.onChangeAddressTap,
    required this.onProceedTap,
    required this.buttonText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine title
    String title = "Delivering to Home";
    if (userName != null && userName!.isNotEmpty) {
      title = "Delivering to $userName";
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      // 🟢 FIX: Wrap the content in SafeArea so it sits above the gesture bar
      child: SafeArea(
        top: false, // We only care about the bottom padding
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. ADDRESS SECTION
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
                 borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                    ),
                    child: Icon(Icons.home_filled, color: Theme.of(context).primaryColor, size: 16),
                  ),
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Theme.of(context).textTheme.titleSmall?.color
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down, size: 16, color: Theme.of(context).textTheme.bodySmall?.color)
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentAddress ?? "Select an address",
                          style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: onChangeAddressTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).primaryColor),
                        borderRadius: BorderRadius.circular(6),
                        color: Theme.of(context).cardColor,
                      ),
                      child: Text(
                        "CHANGE",
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),

            // 2. PROCEED BUTTON
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${GlobalData.currencyCode ?? "₹"} ${cartDetailsModel.adjustedGrandTotal.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Theme.of(context).textTheme.titleLarge?.color
                        ),
                      ),
                      Text(
                        "TOTAL PAYABLE",
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: onProceedTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                               Text(
                                quantityChanged ? "UPDATE CART" : buttonText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (!quantityChanged) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}