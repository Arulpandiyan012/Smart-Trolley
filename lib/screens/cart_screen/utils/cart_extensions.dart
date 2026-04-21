import '../cart_model/cart_data_model.dart';
import 'package:bagisto_app_demo/utils/app_global_data.dart';

extension CartModelExtension on CartModel {
  double get subTotalValue {
    return _parsePrice(formattedPrice?.subTotal);
  }

  double get discountValue {
    double backendDiscount = _parsePrice(formattedPrice?.discountAmount);
    
    // 🟢 SIMULATE FIRST25 (25% off subtotal)
    if (GlobalData.appliedCouponCode == "FIRST25") {
       double simulated = subTotalValue * 0.25;
       // Prioritize whichever is higher (usually simulated if backend hasn't applied it)
       return simulated > backendDiscount ? simulated : backendDiscount;
    }
    
    return backendDiscount;
  }

  double get taxValue {
    return _parsePrice(formattedPrice?.taxAmount ?? taxTotal);
  }

  double get deliveryFeeValue {
    // Standard rule: ₹30 fee if subtotal <= 500, else FREE
    if (subTotalValue > 500) {
      return 0.0;
    }
    return 30.0;
  }

  double get adjustedGrandTotal {
    double total = subTotalValue + taxValue + deliveryFeeValue - discountValue;
    if (total < 0) return 0.0;
    return total;
  }

  double _parsePrice(dynamic p) {
    if (p == null) return 0.0;
    String s = p.toString().replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(s) ?? 0.0;
  }
}
