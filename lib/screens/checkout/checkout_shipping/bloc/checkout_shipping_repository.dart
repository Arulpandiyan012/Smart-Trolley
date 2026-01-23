/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:flutter/foundation.dart';
import 'package:bagisto_app_demo/screens/checkout/utils/index.dart';
import '../../data_model/checkout_save_address_model.dart';
import '../../data_model/checkout_save_shipping_model.dart';

abstract class CheckOutShippingRepository {
  Future<SaveCheckoutAddresses> saveCheckOutShipping(
      String? billingCompanyName,
      String? billingFirstName,
      String? billingLastName,
      String? billingAddress,
      String? billingEmail,
      String? billingAddress2,
      String? billingCountry,
      String? billingState,
      String? billingCity,
      String? billingPostCode,
      String? billingPhone,
      String? shippingCompanyName,
      String? shippingFirstName,
      String? shippingLastName,
      String? shippingAddress,
      String? shippingEmail,
      String? shippingAddress2,
      String? shippingCountry,
      String? shippingState,
      String? shippingCity,
      String? shippingPostCode,
      String? shippingPhone,
      int id,
      {int? billingId,
      int? shippingId,
      bool useForShipping,
      String? cartId}); // 🟢 New Param

  Future<PaymentMethods?> saveShippingMethod(String shippingMethod);
}

class CheckOutShippingRepositoryImp implements CheckOutShippingRepository {
  @override
  Future<SaveCheckoutAddresses> saveCheckOutShipping(
      String? billingCompanyName,
      String? billingFirstName,
      String? billingLastName,
      String? billingAddress,
      String? billingEmail,
      String? billingAddress2,
      String? billingCountry,
      String? billingState,
      String? billingCity,
      String? billingPostCode,
      String? billingPhone,
      String? shippingCompanyName,
      String? shippingFirstName,
      String? shippingLastName,
      String? shippingAddress,
      String? shippingEmail,
      String? shippingAddress2,
      String? shippingCountry,
      String? shippingState,
      String? shippingCity,
      String? shippingPostCode,
      String? shippingPhone,
      int id,
      {int? billingId,
      int? shippingId,
      bool useForShipping = true,
      String? cartId}) async { // 🟢 New Param
      
    SaveCheckoutAddresses? checkOutSaveAddressModel;
    try {
      checkOutSaveAddressModel = await ApiClient().checkoutSaveAddress(
          billingCompanyName,
          billingFirstName,
          billingLastName,
          billingAddress,
          billingEmail,
          billingAddress2,
          billingCountry,
          billingState,
          billingCity,
          billingPostCode,
          billingPhone,
          shippingCompanyName,
          shippingFirstName,
          shippingLastName,
          shippingAddress,
          shippingEmail,
          shippingAddress2,
          shippingCountry,
          shippingState,
          shippingCity,
          shippingPostCode,
          shippingPhone,
          id,
          billingId: billingId,
          shippingId: shippingId,
          useForShipping: useForShipping,
          cartId: cartId); // 🟢 Pass it to ApiClient
    } catch (error) {
      debugPrint("Error --> $error");
    }
    return checkOutSaveAddressModel!;
  }

  @override
  Future<PaymentMethods?> saveShippingMethod(String shippingMethod) async {
    PaymentMethods? paymentMethods;
    try {
      paymentMethods = await ApiClient().saveShippingMethods(shippingMethod);
    } catch (error) {
      debugPrint("Error --> $error");
    }
    return paymentMethods;
  }
}