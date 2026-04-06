import '../cart_model/cart_data_model.dart';

extension CartModelExtension on CartModel {
  double get subTotalValue {
    return _parsePrice(formattedPrice?.subTotal);
  }

  double get discountValue {
    return _parsePrice(formattedPrice?.discountAmount);
  }

  double get taxValue {
    return _parsePrice(formattedPrice?.taxAmount ?? taxTotal);
  }

  double get deliveryFeeValue {
    if (subTotalValue > 500) {
      return 0.0;
    }
    return 30.0;
  }

  double get adjustedGrandTotal {
    return subTotalValue + taxValue + deliveryFeeValue - discountValue;
  }

  double _parsePrice(dynamic p) {
    if (p == null) return 0.0;
    String s = p.toString().replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(s) ?? 0.0;
  }
}
