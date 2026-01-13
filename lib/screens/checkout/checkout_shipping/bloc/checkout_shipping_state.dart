/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import '../../data_model/checkout_save_address_model.dart';
import '../../data_model/checkout_save_shipping_model.dart'; // Import for PaymentMethods

abstract class CheckOutShippingBaseState {}

enum CheckOutShippingStatus { success, fail }

class CheckOutShippingInitialState extends CheckOutShippingBaseState {}

// 🟢 ADDED: Loader State (Fixes Error)
class CheckOutShippingLoaderState extends CheckOutShippingBaseState {}

class CheckOutFetchShippingState extends CheckOutShippingBaseState {
  CheckOutShippingStatus? status;
  String? error;
  SaveCheckoutAddresses? checkOutSaveAddressModel;
  
  // 🟢 ADDED: Hold PaymentMethods directly (Fixes Constructor Error)
  PaymentMethods? paymentMethods; 

  CheckOutFetchShippingState.success({
    this.checkOutSaveAddressModel, 
    this.paymentMethods // Optional parameter
  }) : status = CheckOutShippingStatus.success;

  CheckOutFetchShippingState.fail({this.error}) 
      : status = CheckOutShippingStatus.fail;
}