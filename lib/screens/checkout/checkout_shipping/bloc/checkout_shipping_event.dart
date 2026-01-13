/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:equatable/equatable.dart';

abstract class CheckOutShippingBaseEvent extends Equatable {}

class CheckOutFetchShippingEvent extends CheckOutShippingBaseEvent {
  // Existing fields...
  final String? billingCompanyName;
  final String? billingFirstName;
  final String? billingLastName;
  final String? billingAddress;
  final String? billingEmail;
  final String? billingAddress2;
  final String? billingCountry;
  final String? billingState;
  final String? billingCity;
  final String? billingPostCode;
  final String? billingPhone;
  final String? shippingCompanyName;
  final String? shippingFirstName;
  final String? shippingLastName;
  final String? shippingAddress;
  final String? shippingEmail;
  final String? shippingAddress2;
  final String? shippingCountry;
  final String? shippingState;
  final String? shippingCity;
  final String? shippingPostCode;
  final String? shippingPhone;
  final int? billingId;
  final int? shippingId;
  final bool useForShipping;
  
  // 🟢 NEW FIELD
  final String? cartId; 

  CheckOutFetchShippingEvent(
      {this.billingCompanyName,
      this.billingFirstName,
      this.billingLastName,
      this.billingAddress,
      this.billingEmail,
      this.billingAddress2,
      this.billingCountry,
      this.billingState,
      this.billingCity,
      this.billingPostCode,
      this.billingPhone,
      this.shippingCompanyName,
      this.shippingFirstName,
      this.shippingLastName,
      this.shippingAddress,
      this.shippingEmail,
      this.shippingAddress2,
      this.shippingCountry,
      this.shippingState,
      this.shippingCity,
      this.shippingPostCode,
      this.shippingPhone,
      this.billingId,
      this.shippingId,
      this.useForShipping = true,
      this.cartId}); // 🟢 Add to constructor

  @override
  List<Object> get props => [];
}

class CheckOutSaveShippingMethodEvent extends CheckOutShippingBaseEvent {
  final String shippingMethod;
  CheckOutSaveShippingMethodEvent(this.shippingMethod);
  @override
  List<Object> get props => [shippingMethod];
}