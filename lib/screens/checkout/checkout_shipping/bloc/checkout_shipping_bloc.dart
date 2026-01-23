/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 * @author Webkul <support@webkul.com>
 * @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 * @license https://store.webkul.com/license.html
 * @link https://store.webkul.com/license.html
 */

//import 'package:flutter/foundation.dart';
import 'package:bagisto_app_demo/screens/checkout/data_model/checkout_save_address_model.dart';
import 'package:bagisto_app_demo/screens/checkout/data_model/checkout_save_shipping_model.dart';
import 'package:bagisto_app_demo/screens/checkout/utils/index.dart';

// ... imports ...

class CheckOutShippingBloc extends Bloc<CheckOutShippingBaseEvent, CheckOutShippingBaseState> {
  CheckOutShippingRepository? repository;

  CheckOutShippingBloc(this.repository) : super(CheckOutShippingInitialState()) {
    on<CheckOutShippingBaseEvent>(mapEventToState);
  }

void mapEventToState(CheckOutShippingBaseEvent event, Emitter<CheckOutShippingBaseState> emit) async {
    
    // CASE 1: Save Address
    if (event is CheckOutFetchShippingEvent) {
      emit(CheckOutShippingLoaderState());
      try {
        // 🔴 OLD BUGGY LINE:
        // int id = appStoragePref.getCustomerId(); 

        // 🟢 NEW CORRECT LINE:
        // Use the ID passed from the View (which we verified is 478)
        // Note: Check your CheckOutFetchShippingEvent file if the variable is named 'billingAddressId' or 'billingId'
        int id = event.billingId ?? 0; 

        // Safety check: if billing is 0, try shipping (since they are usually the same)
        if (id == 0) id = event.shippingId ?? 0;

        SaveCheckoutAddresses? checkOutSaveAddressModel = await repository?.saveCheckOutShipping(
            event.billingCompanyName,
            event.billingFirstName,
            event.billingLastName,
            event.billingAddress,
            event.billingEmail,
            event.billingAddress2,
            event.billingCountry,
            event.billingState,
            event.billingCity,
            event.billingPostCode,
            event.billingPhone,
            event.shippingCompanyName,
            event.shippingFirstName,
            event.shippingLastName,
            event.shippingAddress,
            event.shippingEmail,
            event.shippingAddress2,
            event.shippingCountry,
            event.shippingState,
            event.shippingCity,
            event.shippingPostCode,
            event.shippingPhone,
            id, // ✅ NOW PASSING 478
            billingId: event.billingId,
            shippingId: event.shippingId,
            useForShipping: event.useForShipping,
            cartId: event.cartId 
        );
        
        if (checkOutSaveAddressModel?.responseStatus == false) {
          emit(CheckOutFetchShippingState.fail(error: checkOutSaveAddressModel?.success));
        } else {
          emit(CheckOutFetchShippingState.success(checkOutSaveAddressModel: checkOutSaveAddressModel));
        }
      } catch (e) {
        emit(CheckOutFetchShippingState.fail(error: StringConstants.somethingWrong.localized()));
      }
    }
    
    // ... Case 2 (Save Shipping Method) ...
    if (event is CheckOutSaveShippingMethodEvent) {
       PaymentMethods? result = await repository?.saveShippingMethod(event.shippingMethod);
       bool isSuccess = (result?.responseStatus == true) || (result?.paymentMethods != null && result!.paymentMethods!.isNotEmpty);
       if (isSuccess) {
          emit(CheckOutFetchShippingState.success(paymentMethods: result));
       } else {
          emit(CheckOutFetchShippingState.fail(error: "Could not save shipping method."));
       }
    }
  }
}