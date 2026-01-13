/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:bagisto_app_demo/screens/checkout/utils/index.dart';

class CheckOutBloc extends Bloc<CheckOutBaseEvent, CheckOutBaseState> {
  CheckOutRepository? repository;

  CheckOutBloc(this.repository) : super(CheckOutLoaderState()) {
    on<CheckOutBaseEvent>(mapEventToState);
  }

  void mapEventToState(
      CheckOutBaseEvent event, Emitter<CheckOutBaseState> emit) async {
    
    // 1. Fetch Addresses
    if (event is CheckOutAddressEvent) {
      try {
        emit(CheckOutLoaderState()); 
        AddressModel? addressModel = await repository?.callCheckoutAddressApi();
        
        if (addressModel != null) {
          emit(CheckOutAddressState.success(addressModel: addressModel));
        } else {
          emit(CheckOutAddressState.fail(error: "No Data Received"));
        }
      } catch (e) {
        emit(CheckOutAddressState.fail(error: e.toString()));
      }
    } 
    
    // 2. Add New Address
    else if (event is AddAddressEvent) {
      try {
        emit(CheckOutLoaderState()); // Show loader

        var response = await repository?.saveAddress({
          "company_name": "",
          "first_name": event.firstName,
          "last_name": event.lastName,
          "address1": event.address1,
          "address2": event.address2,
          "country": event.country,
          "state": event.state,
          "city": event.city,
          "postcode": event.postCode,
          "phone": event.phone,
          "vat_id": "",
          "default_address": true,
          "email": event.email 
        });

        if (response?.success == true) {
          // 🟢 SUCCESS! Now Auto-Refresh the list
          // We trigger the fetch logic immediately
          AddressModel? addressModel = await repository?.callCheckoutAddressApi();
          emit(CheckOutAddressState.success(addressModel: addressModel));
          
        } else {
          emit(AddAddressState.fail(error: response?.message ?? "Failed to save address"));
        }
      } catch (e) {
        emit(AddAddressState.fail(error: e.toString()));
      }
    }
  }
}