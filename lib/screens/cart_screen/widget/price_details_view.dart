import '../utils/cart_index.dart';

class PriceDetailView extends StatelessWidget {
  final CartModel cartDetailsModel;

  const PriceDetailView({Key? key, required this.cartDetailsModel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
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

          // 🟢 FIX: Delivery Charges (Robust Calculation)
          Builder(builder: (context) {
             String ship = cartDetailsModel.formattedPrice?.shippingAmount ?? "0";
             
             // 1. Try direct field
             if (ship != "₹0.00" && ship != "0" && ship != "") {
                return _buildRow(context, "Delivery Charges", ship);
             }

             // 2. Try selected rate
             var rate = cartDetailsModel.selectedShippingRate?.formattedPrice?.price;
             if (rate != null && rate.toString() != "₹0.00" && rate.toString() != "0") {
                return _buildRow(context, "Delivery Charges", rate.toString());
             }

             // 3. Fallback: Calculate Difference (Grand - (Sub + Tax - Discount))
             try {
                double parsePrice(dynamic p) {
                   if (p == null) return 0.0;
                   String s = p.toString().replaceAll(RegExp(r'[^\d.]'), ''); // Remove ₹, args
                   return double.tryParse(s) ?? 0.0;
                }

                double grand = parsePrice(cartDetailsModel.formattedPrice?.grandTotal);
                double sub = parsePrice(cartDetailsModel.formattedPrice?.subTotal);
                double tax = parsePrice(cartDetailsModel.formattedPrice?.taxAmount ?? cartDetailsModel.taxTotal);
                double discount = parsePrice(cartDetailsModel.formattedPrice?.discountAmount);

                double calculatedDiff = grand - (sub + tax - discount);

                if (calculatedDiff > 0.5) { // Tolerance for rounding
                   return _buildRow(context, "Delivery Charges", "₹${calculatedDiff.toStringAsFixed(2)}");
                }
             } catch (e) {
                debugPrint("Price Calc Error: $e");
             }

             return const SizedBox();
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
              Text(
                cartDetailsModel.formattedPrice?.grandTotal.toString() ?? "",
                style: TextStyle(
                  fontWeight: FontWeight.w800, 
                  fontSize: 16,
                  color: Theme.of(context).textTheme.titleLarge?.color
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