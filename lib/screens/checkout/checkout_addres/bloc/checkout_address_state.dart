/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import '../../../address_list/data_model/address_model.dart';

abstract class CheckOutBaseState {}

enum CheckOutStatus { success, fail }

class CheckOutLoaderState extends CheckOutBaseState {}

class CheckOutAddressState extends CheckOutBaseState {
  CheckOutStatus? status;
  String? error;
  AddressModel? addressModel;
  int? index;

  CheckOutAddressState.success({this.addressModel, this.index}) 
      : status = CheckOutStatus.success;
  CheckOutAddressState.fail({this.error}) 
      : status = CheckOutStatus.fail;
}

// --- ADD THIS NEW STATE CLASS ---
class AddAddressState extends CheckOutBaseState {
  CheckOutStatus? status;
  String? error;
  String? successMsg;

  AddAddressState.success({this.successMsg}) : status = CheckOutStatus.success;
  AddAddressState.fail({this.error}) : status = CheckOutStatus.fail;
}