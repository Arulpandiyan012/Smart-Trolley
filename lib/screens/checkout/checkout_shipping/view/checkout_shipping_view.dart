/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagisto_app_demo/screens/checkout/utils/index.dart';
import '../../data_model/checkout_save_address_model.dart';
import '../../data_model/checkout_save_shipping_model.dart';

//ignore: must_be_immutable
class CheckoutShippingPageView extends StatefulWidget {
  String? billingCompanyName;
  String? billingFirstName;
  String? billingLastName;
  String? billingAddress;
  String? billingEmail;
  String? billingAddress2;
  String? billingCountry;
  String? billingState;
  String? billingCity;
  String? billingPostCode;
  String? billingPhone;
  String? shippingCompanyName;
  String? shippingFirstName;
  String? shippingLastName;
  String? shippingAddress;
  String? shippingEmail;
  String? shippingAddress2;
  String? shippingCountry;
  String? shippingState;
  String? shippingCity;
  String? shippingPostCode;
  String? shippingPhone;
  int billingId;
  int shippingId;
  ValueChanged<String>? callBack;
  bool isDownloadable;
  Function? callbackNavigate;
  bool? useForShipping;
  Function(PaymentMethods)? paymentCallback;
  
  // 🟢 NEW: Accept Cart ID
  String? cartId;

  CheckoutShippingPageView(
      {Key? key,
      this.billingCompanyName,
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
      this.callBack, required this.shippingId, required this.billingId, this.isDownloadable = false,
      this.callbackNavigate, this.paymentCallback, this.useForShipping,
      this.cartId // 🟢 Initialize it
      })
      : super(key: key);

  @override
  State<CheckoutShippingPageView> createState() => _CheckoutShippingPageViewState();
}

class _CheckoutShippingPageViewState extends State<CheckoutShippingPageView> {
  String selectedShippingCode = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: _shippingBloc(context),
    );
  }

  Widget _shippingBloc(BuildContext context) {
    CheckOutShippingBloc checkOutShippingBloc = context.read<CheckOutShippingBloc>();
    
    // 🟢 PASS CART ID HERE TO PREVENT REVERTING TO OLD CART
    checkOutShippingBloc.add(CheckOutFetchShippingEvent(
      billingCompanyName: widget.billingCompanyName,
      billingFirstName: widget.billingFirstName,
      billingLastName: widget.billingLastName,
      billingAddress: widget.billingAddress,
      billingEmail: widget.billingEmail,
      billingAddress2: widget.billingAddress2,
      billingCountry: widget.billingCountry,
      billingState: widget.billingState,
      billingCity: widget.billingCity,
      billingPostCode: widget.billingPostCode,
      billingPhone: widget.billingPhone,
      shippingCompanyName: widget.shippingCompanyName,
      shippingFirstName: widget.shippingFirstName,
      shippingLastName: widget.shippingLastName,
      shippingAddress: widget.shippingAddress,
      shippingEmail: widget.shippingEmail,
      shippingAddress2: widget.shippingAddress2,
      shippingCountry: widget.shippingCountry,
      shippingState: widget.shippingState,
      shippingCity: widget.shippingCity,
      shippingPostCode: widget.shippingPostCode,
      shippingPhone: widget.shippingPhone,
      billingId: widget.billingId,
      shippingId: widget.shippingId,
      useForShipping: widget.useForShipping ?? true,
      cartId: widget.cartId // 🟢 CRITICAL FIX
    ));

    return BlocConsumer<CheckOutShippingBloc, CheckOutShippingBaseState>(
      listener: (BuildContext context, CheckOutShippingBaseState state) {
        if(state is CheckOutFetchShippingState){
          if(state.checkOutSaveAddressModel?.jumpToSection == "payment" && widget.paymentCallback != null){
            PaymentMethods payment = PaymentMethods(paymentMethods: state.checkOutSaveAddressModel?.paymentMethods,
                cart: state.checkOutSaveAddressModel?.cart);
            widget.paymentCallback!(payment);
          }
        }
      },
      builder: (BuildContext context, CheckOutShippingBaseState state) {
        return buildUI(context, state);
      },
    );
  }

  Widget buildUI(BuildContext context, CheckOutShippingBaseState state) {
    if (state is CheckOutFetchShippingState) {
      if (state.status == CheckOutShippingStatus.success) {
        // Handle case where PaymentMethods came from saveShippingMethod
        if (state.paymentMethods != null) {
           // We are in a payment state, no need to show shipping list, or show selected
           return const SizedBox(); 
        }
        return _buildShippingList(state.checkOutSaveAddressModel!);
      }
    }
    if (state is CheckOutShippingLoaderState) { // Updated state check
      return const Center(child: CircularProgressIndicator());
    }
    if (state is CheckOutShippingInitialState) {
       return const Center(child: CircularProgressIndicator());
    }
    return const SizedBox();
  }

  Widget _buildShippingList(SaveCheckoutAddresses model) {
    var methods = model.shippingMethods ?? [];
    if (methods.isEmpty) {
       return const Center(child: Text("No shipping methods available"));
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: methods.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        var method = methods[i];
        var code = method.methods?.code ?? '';
        bool isSelected = selectedShippingCode == code;

        return InkWell(
          onTap: () {
            setState(() => selectedShippingCode = code);
            if (widget.callBack != null) widget.callBack!(code);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF0C831F) : Colors.transparent, 
                width: 1.5
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isSelected ? const Color(0xFF0C831F) : Colors.grey),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(method.title ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(method.methods?.formattedPrice ?? '', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}