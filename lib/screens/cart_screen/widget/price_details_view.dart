import '../utils/cart_index.dart';

class PriceDetailView extends StatelessWidget {
  final CartModel cartDetailsModel;

  const PriceDetailView({super.key, required this.cartDetailsModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.grey[800]),
          ),
          const SizedBox(height: 16),
          
          // Subtotal
          _buildRow(StringConstants.subTotal.localized(), cartDetailsModel.formattedPrice?.subTotal ?? ""),
          
          // Discount
          if (cartDetailsModel.formattedPrice?.discountAmount != null)
             _buildRow(StringConstants.discount.localized(), cartDetailsModel.formattedPrice?.discountAmount ?? "", isGreen: true),

          // Tax
          if (cartDetailsModel.taxTotal > 0)
             _buildRow(StringConstants.tax.localized(), cartDetailsModel.formattedPrice?.taxTotal.toString() ?? ""),

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
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              Text(
                cartDetailsModel.formattedPrice?.grandTotal.toString() ?? "",
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildRow(String label, String value, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: isGreen ? Colors.green : Colors.black, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}