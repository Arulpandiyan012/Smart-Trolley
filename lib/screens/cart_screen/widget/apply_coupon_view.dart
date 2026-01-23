/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */
import '../utils/cart_index.dart';

class ApplyCouponView extends StatefulWidget {
  final CartModel? cartDetailsModel;
  final CartScreenBloc? cartScreenBloc;
  final TextEditingController discountController;

  const ApplyCouponView({
    super.key,
    this.cartDetailsModel,
    this.cartScreenBloc,
    required this.discountController
  });

  @override
  State<ApplyCouponView> createState() => _ApplyCouponViewState();
}

class _ApplyCouponViewState extends State<ApplyCouponView> {
  @override
  Widget build(BuildContext context) {
    // Check if a coupon is currently applied
    bool isCouponApplied = widget.cartDetailsModel?.couponCode != null && 
                           (widget.cartDetailsModel?.couponCode?.isNotEmpty ?? false);

    // If applied, show the code in the box. If not, show hint text.
    String hintText = isCouponApplied 
        ? (widget.cartDetailsModel?.couponCode ?? "") 
        : "Have a coupon code?";

    return Container(
      height: 54, // Fixed clean height
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300), // Subtle modern border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02), 
            blurRadius: 2, 
            offset: const Offset(0, 1)
          )
        ],
      ),
      child: Row(
        children: [
          // 1. COUPON ICON
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9), // Light Green bg for icon
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_offer, // Ticket Icon
              color: Color(0xFF0C831F), // Blinkit Green
              size: 18,
            ),
          ),
          
          const SizedBox(width: 12),

          // 2. INPUT FIELD
          Expanded(
            child: TextField(
              controller: widget.discountController,
              enabled: !isCouponApplied, // Lock input if code is applied
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: isCouponApplied ? Colors.black87 : Colors.grey,
                  fontWeight: isCouponApplied ? FontWeight.bold : FontWeight.normal,
                ),
                border: InputBorder.none, // Removes the default underline
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              // Update state to remove error styling if user types
              onChanged: (val) {
                if (mounted) setState(() {});
              },
            ),
          ),

          // 3. APPLY / REMOVE BUTTON
          InkWell(
            onTap: () {
              if (isCouponApplied) {
                // --- REMOVE LOGIC ---
                widget.cartScreenBloc?.add(RemoveCouponCartEvent(widget.cartDetailsModel));
                widget.discountController.clear();
              } else {
                // --- APPLY LOGIC ---
                if (widget.discountController.text.trim().isNotEmpty) {
                  widget.cartScreenBloc?.add(AddCouponCartEvent(widget.discountController.text));
                } else {
                  ShowMessage.warningNotification(StringConstants.couponEmpty.localized(), context);
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                isCouponApplied 
                    ? StringConstants.remove.localized().toUpperCase() 
                    : StringConstants.apply.localized().toUpperCase(),
                style: TextStyle(
                  color: isCouponApplied ? Colors.red : const Color(0xFF0C831F),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}