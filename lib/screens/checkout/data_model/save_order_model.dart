/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 * @author Webkul <support@webkul.com>
 * @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 * @license https://store.webkul.com/license.html
 * @link https://store.webkul.com/license.html
 */

import 'package:json_annotation/json_annotation.dart';
import '../../cart_screen/cart_model/cart_data_model.dart';

part 'save_order_model.g.dart';

@JsonSerializable()
class SaveOrderModel {
  String? redirectUrl;
  bool? success; // 🟢 New Field for PHP Fix
  String? message; // 🟢 New Field for PHP Fix
  Order? order;
  dynamic selectedMethod;
  
  // 🟢 RESTORED: Fields required by existing .g.dart file
  String? graphqlErrors;
  bool? status;
  int? cartCount;
  dynamic error;

  SaveOrderModel({
    this.redirectUrl,
    this.success,
    this.message,
    this.selectedMethod,
    this.order,
    // 🟢 Initialize restored fields
    this.graphqlErrors,
    this.status,
    this.cartCount,
    this.error,
  });

  factory SaveOrderModel.fromJson(Map<String, dynamic> json) =>
      _$SaveOrderModelFromJson(json);

  Map<String, dynamic> toJson() => _$SaveOrderModelToJson(this);
}

@JsonSerializable()
class Order {
  int? id;
  String? incrementId;
  
  // 🟢 RESTORED: Fields required by existing .g.dart file
  String? customerEmail;
  String? customerFirstName;
  String? customerLastName;

  Order({
    this.id, 
    this.incrementId,
    // 🟢 Initialize restored fields
    this.customerEmail,
    this.customerFirstName,
    this.customerLastName,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  Map<String, dynamic> toJson() => _$OrderToJson(this);
}