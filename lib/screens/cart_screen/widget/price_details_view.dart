import '../utils/cart_index.dart';

class PriceDetailView extends StatelessWidget {
  final CartModel cartDetailsModel;

  const PriceDetailView({Key? key, required this.cartDetailsModel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double parsePrice(dynamic p) {
      if (p == null) return 0.0;
      String s = p.toString().replaceAll(RegExp(r'[^\d.]'), ''); 
      return double.tryParse(s) ?? 0.0;
    }

    double sub = parsePrice(cartDetailsModel.formattedPrice?.subTotal);
    bool isFreeDelivery = sub > 500;
    double diffToFree = 500 - sub;

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
          // 🟢 FREE DELIVERY BANNER
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
                      "Add ₹${diffToFree.toStringAsFixed(0)} more for FREE Delivery!",
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
          _buildRow(context, StringConstants.subTotal.localized(), cartDetailsModel.formattedPrice?.subTotal ?? ""),
          
          // Discount
          if (cartDetailsModel.formattedPrice?.discountAmount != null)
             _buildRow(context, StringConstants.discount.localized(), cartDetailsModel.formattedPrice?.discountAmount ?? "", isGreen: true),

          // Tax
          if (cartDetailsModel.taxTotal > 0)
             _buildRow(context, StringConstants.tax.localized(), cartDetailsModel.formattedPrice?.taxTotal.toString() ?? ""),

          // 🟢 FIX: Delivery Charges (Robust Calculation with Fixed ₹30 / FREE Threshold)
          Builder(builder: (context) {
             if (isFreeDelivery) {
                return _buildRow(context, "Delivery Charges", "FREE", isGreen: true);
             } else {
                return _buildRow(context, "Delivery Charges", "₹30.00");
             }
          }),

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
              Builder(builder: (context) {
                 double tax = parsePrice(cartDetailsModel.formattedPrice?.taxAmount ?? cartDetailsModel.taxTotal);
                 double discount = parsePrice(cartDetailsModel.formattedPrice?.discountAmount);
                 
                 double deliveryFee = isFreeDelivery ? 0 : 30;
                 double adjustedGrand = sub + tax + deliveryFee - discount;
                 
                 return Text(
                    "₹${adjustedGrand.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontWeight: FontWeight.w800, 
                      fontSize: 16,
                      color: Theme.of(context).textTheme.titleLarge?.color
                    ),
                  );
              }),
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