/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagisto_app_demo/screens/checkout/utils/index.dart';
import '../checkout_payment/view/checkout_payment_view.dart';
import 'package:bagisto_app_demo/screens/checkout/data_model/checkout_save_shipping_model.dart';
import 'modern_checkout_header.dart';

import 'package:bagisto_app_demo/screens/checkout/checkout_addres/bloc/checkout_address_bloc.dart';
import 'package:bagisto_app_demo/screens/checkout/checkout_addres/bloc/checkout_address_repository.dart';
import 'package:bagisto_app_demo/screens/checkout/checkout_shipping/bloc/checkout_shipping_bloc.dart';
import 'package:bagisto_app_demo/screens/checkout/checkout_shipping/bloc/checkout_shipping_repository.dart';
import 'package:bagisto_app_demo/screens/checkout/checkout_shipping/bloc/checkout_shipping_event.dart';
import 'package:bagisto_app_demo/screens/checkout/checkout_shipping/bloc/checkout_shipping_state.dart';

import 'package:bagisto_app_demo/services/api_client.dart'; 
import 'package:bagisto_app_demo/screens/checkout/data_model/save_order_model.dart';
import 'package:dio/dio.dart'; 

class CheckoutScreenFinal extends StatefulWidget {
  final CartScreenBloc? cartScreenBloc;
  final String? total;
  final bool? isDownloadable;
  final CartModel? cartDetailsModel;
  const CheckoutScreenFinal(
      {Key? key,
      this.total,
      this.cartScreenBloc,
      this.cartDetailsModel,
      this.isDownloadable = false})
      : super(key: key);

  @override
  State<CheckoutScreenFinal> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreenFinal> {
  int currentIndex = 1;
  PaymentMethods? paymentMethods;
  
  String? billingCompanyName, billingFirstName, billingLastName, billingAddress, billingEmail;
  String? billingAddress2, billingCountry, billingState, billingCity, billingPostCode, billingPhone;
  String? shippingCompanyName, shippingFirstName, shippingLastName, shippingAddress, shippingEmail;
  String? shippingAddress2, shippingCountry, shippingState, shippingCity, shippingPostCode, shippingPhone;
  
  String? _cachedDisplayAddress;
  String shippingRateCode = ''; 
  String paymentId = "";
  int? billingAddressId;
  int? shippingAddressId;
  bool isUser = false;
  bool useForShipping = true;
  bool isLoading = false;
  String? _latestCartId;

  String? email;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final StreamController _myStreamCtrl = StreamController.broadcast();
  Stream get onVariableChanged => _myStreamCtrl.stream;

  CheckOutShippingBloc? _shippingBloc;

  @override
  void initState() {
    isUser = appStoragePref.getCustomerLoggedIn();
    email = appStoragePref.getCustomerEmail();
    _shippingBloc = CheckOutShippingBloc(CheckOutShippingRepositoryImp());
    
    _latestCartId = widget.cartDetailsModel?.id?.toString();
    _fetchFreshCartId();
    
    super.initState();
  }

  Future<void> _fetchFreshCartId() async {
    try {
      CartModel? freshCart = await ApiClient().getCartDetails();
      if (freshCart != null && freshCart.id != null) {
        String newId = freshCart.id.toString();
        setState(() => _latestCartId = newId);
        appStoragePref.setCartId(newId); 
      }
    } catch (e) {
      debugPrint("⚠️ Failed to fetch fresh cart ID: $e");
    }
  }

  Future<void> _callBackendFixer({int? targetAddressId}) async {
    try {
      String customerId = "0";
      try { 
        var data = appStoragePref.getCustomerId(); 
        if (data != null) customerId = data.toString(); 
      } catch (_) {}

      var dio = Dio();
      var formData = FormData.fromMap({
        'customer_id': customerId,
        'cart_id': _latestCartId ?? "0",
        'address_id': targetAddressId ?? 0
      });

      await dio.post(
        'https://ecom.thesmartedgetech.com/mobikul-save-checkout-address.php', 
        data: formData
      );
    } catch (e) {
      debugPrint("⚠️ Fixer Error: $e");
    }
  }

  // 🟢 V14 SCRIPT: SEND CUSTOMER ID
  Future<void> _executeVersion14Order() async {
     debugPrint("🚀 V14: SENDING CUSTOMER ID FOR MOBILE USER...");
     
     try {
       String customerId = appStoragePref.getCustomerId()?.toString() ?? "0";
       
       var dio = Dio();
       var formData = FormData.fromMap({
         'cart_id': _latestCartId ?? "0",
         'customer_id': customerId 
       });

       var response = await dio.post(
         'https://ecom.thesmartedgetech.com/mobikul_final_order.php',
         data: formData
       );

       debugPrint("✅ V14 Response: ${response.data}");

       if (mounted) setState(() => isLoading = false);

       if (response.data['success'] == true) {
           var orderId = response.data['order_id'];
           if (mounted) {
             Navigator.pushNamedAndRemoveUntil(
               context,
               orderPlacedScreen, 
               (route) => false, 
               arguments: orderId
             );
           }
       } else {
           if (mounted) {
             ShowMessage.errorNotification(response.data['message'] ?? "Failed", context);
           }
       }
     } catch(e) {
       if (mounted) setState(() => isLoading = false);
       debugPrint("❌ V14 Failed: $e");
       ShowMessage.errorNotification("Network Error: $e", context);
     }
  }

  @override
  void dispose() {
    _myStreamCtrl.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0, 
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text("Checkout", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: BlocListener<CheckOutShippingBloc, CheckOutShippingBaseState>(
          bloc: _shippingBloc,
          listener: (context, state) {
            if (state is CheckOutFetchShippingState) {
              setState(() => isLoading = false);
              
              if (state.status == CheckOutShippingStatus.success) {
                if (currentIndex == 1) {
                   setState(() { currentIndex = 2; });
                } else if (currentIndex == 2) {
                   if (state.paymentMethods != null) {
                      paymentMethods = state.paymentMethods;
                   }
                   setState(() { currentIndex = 3; });
                }
              } else {
                if (currentIndex == 1) {
                   shippingRateCode = 'flatrate_flatrate';
                   setState(() { currentIndex = 2; });
                } else {
                   ShowMessage.errorNotification(state.error ?? "Operation Failed", context);
                }
              }
            } else if (state is CheckOutShippingLoaderState) {
               setState(() => isLoading = true);
            }
          },
          child: Stack(
            children: [
              Column(
                children: [
                  ModernCheckoutHeader(
                    currentStep: currentIndex,
                    total: widget.total ?? "",
                  ),
                  Expanded(child: _getBody()),
                  // 🟢 This is the Fixed Bottom Bar
                  _buildBottomBar(),
                ],
              ),
              if (isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator(color: Color(0xFF0C831F))),
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _getBody() {
    switch (currentIndex) {
      case 1:
        return isUser
            ? BlocProvider(
                create: (context) => CheckOutBloc(CheckOutRepositoryImp()),
                child: CheckoutAddressView(
                  callBack: (bName, bFirst, bLast, bAddr, bAddr2, bCountry, bState, bCity, bZip, bPhone,
                      sName, sFirst, sLast, sAddr, sAddr2, sCountry, sState, sCity, sZip, sPhone,
                      bId, sId, type, isSame) {
                    
                    String addrStr = "$sAddr";
                    if(sCity != null) addrStr += ", $sCity";
                    
                    setState(() {
                      _cachedDisplayAddress = addrStr;
                      if (type == AddressType.both || isSame) useForShipping = true;
                      else useForShipping = false;

                      billingAddressId = bId;
                      shippingAddressId = sId;

                      billingCompanyName = bName; billingFirstName = bFirst; billingLastName = bLast;
                      billingAddress = bAddr; billingAddress2 = bAddr2; billingCountry = bCountry;
                      billingState = bState; billingCity = bCity; billingPostCode = bZip; billingPhone = bPhone;
                      if(email!=null) billingEmail = email;
                      
                      shippingCompanyName = sName; shippingFirstName = sFirst; shippingLastName = sLast;
                      shippingAddress = sAddr; shippingAddress2 = sAddr2; shippingCountry = sCountry;
                      shippingState = sState; shippingCity = sCity; shippingPostCode = sZip; shippingPhone = sPhone;
                      if(email!=null) shippingEmail = email;
                    });
                  },
                ),
              )
            : BlocProvider(
                create: (context) => GuestAddressBloc(GuestAddressRepositoryImp()),
                child: GuestAddAddressForm(
                  callBack: (bName, bFirst, bLast, bAddr, bAddr2, bCountry, bState, bCity, bZip, bPhone, bEmail,
                      sEmail, sName, sFirst, sLast, sAddr, sAddr2, sCountry, sState, sCity, sZip, sPhone) {
                    
                    setState(() {
                      _cachedDisplayAddress = "$sAddr, $sCity";
                      billingCompanyName = bName; billingFirstName = bFirst; billingLastName = bLast;
                      billingAddress = bAddr; billingAddress2 = bAddr2; billingCountry = bCountry;
                      billingState = bState; billingCity = bCity; billingPostCode = bZip; billingPhone = bPhone; billingEmail = bEmail;
                      shippingCompanyName = sName; shippingFirstName = sFirst; shippingLastName = sLast;
                      shippingAddress = sAddr; shippingAddress2 = sAddr2; shippingCountry = sCountry;
                      shippingState = sState; shippingCity = sCity; shippingPostCode = sZip; shippingPhone = sPhone; shippingEmail = sEmail;
                    });
                  },
                ),
              );
      case 2:
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Select Shipping Method", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                   setState(() { shippingRateCode = 'flatrate_flatrate'; });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFF0C831F), width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.radio_button_checked, color: Color(0xFF0C831F)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Standard Delivery", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("Flat Rate - ₹0.00", style: TextStyle(color: Colors.grey)),
                        ],
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        );
      case 3:
        return BlocProvider(
          create: (context) => CheckOutPaymentBloc(CheckOutPaymentRepositoryImp()),
          child: CheckoutPaymentView(
            total: widget.total, 
            shippingId: shippingRateCode, 
            paymentMethods: paymentMethods,
            callBack: (id) { paymentId = id; },
            priceCallback: (price) { _myStreamCtrl.sink.add(price); },
          ),
        );
      case 4:
        String displayAddress = _cachedDisplayAddress ?? "";
        if (displayAddress.isEmpty && shippingAddress != null) {
           displayAddress = "$shippingAddress, $shippingCity";
        }
        
        return BlocProvider(
          create: (context) => CheckOutReviewBloc(CheckOutReviewRepositoryImp()),
          child: CheckoutOrderReviewView(
            paymentId: paymentId, 
            cartDetailsModel: widget.cartDetailsModel, 
            cartScreenBloc: widget.cartScreenBloc,
            callBack: (price) { _myStreamCtrl.sink.add(price); },
            displayAddress: displayAddress, 
          ),
        );
      default:
        return const SizedBox();
    }
  }

 // 🟢 REPLACEMENT FOR _buildBottomBar in checkout_screen.dart

Widget _buildBottomBar() {
  return StreamBuilder(
    stream: onVariableChanged,
    builder: (context, snapshot) {
      String displayTotal = snapshot.data?.toString() ?? widget.total ?? "";
      
      return SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Ensure space distribution
            children: [
              // LEFT SIDE: TOTAL
              Expanded( // Allow this to take available space
                flex: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Shrink to fit
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTotal, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "TOTAL", 
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600])
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12), // Spacing
              
              // RIGHT SIDE: BUTTON
              Expanded(
                flex: 6,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _onProceedFinalV14, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C831F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 8), // Reduce padding to fit text
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 🟢 FIX: Flexible prevents overflow by shrinking text if needed
                        Flexible(
                          child: Text(
                            currentIndex == 4
                                ? StringConstants.placeOrder.localized()
                                : StringConstants.proceed.localized().toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 14 // Keep font size readable
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis, // Add "..." if still too long
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (currentIndex < 4) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward, color: Colors.white, size: 16)
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  void _onProceedFinalV14() async {
    // Step 1: Address
    if (currentIndex == 1) {
      if (shippingAddressId == null || shippingAddressId == 0) {
        ShowMessage.warningNotification("Please select a delivery address", context);
        return;
      }
      
      setState(() => isLoading = true);

      await _callBackendFixer(targetAddressId: shippingAddressId);

      int finalId = shippingAddressId!;
      String cartIdToSend = _latestCartId ?? widget.cartDetailsModel?.id?.toString() ?? "0";
      
      _shippingBloc?.add(CheckOutFetchShippingEvent(
        billingCompanyName: billingCompanyName, billingFirstName: billingFirstName, billingLastName: billingLastName,
        billingAddress: billingAddress, billingEmail: billingEmail, billingAddress2: billingAddress2,
        billingCountry: billingCountry, billingState: billingState, billingCity: billingCity, billingPostCode: billingPostCode, billingPhone: billingPhone,
        shippingCompanyName: shippingCompanyName, shippingFirstName: shippingFirstName, shippingLastName: shippingLastName,
        shippingAddress: shippingAddress, shippingEmail: shippingEmail, shippingAddress2: shippingAddress2,
        shippingCountry: shippingCountry, shippingState: shippingState, shippingCity: shippingCity, shippingPostCode: shippingPostCode, shippingPhone: shippingPhone,
        billingId: finalId, shippingId: finalId, cartId: cartIdToSend, useForShipping: useForShipping
      ));
      return; 
    }

    // Step 2: Shipping
    if (currentIndex == 2) {
      if (shippingRateCode == '') shippingRateCode = 'flatrate_flatrate';
      setState(() { currentIndex = 3; });
      return;
    }

    // Step 3: Payment
    if (currentIndex == 3) {
      if (paymentId == '') {
        ShowMessage.warningNotification(StringConstants.pleaseSelectPayment.localized(), context);
        return;
      }
      setState(() { currentIndex = 4; });
      return;
    }
    
    // Step 4: PLACE ORDER
    if (currentIndex == 4) {
      debugPrint("🚀 USER CLICKED V14 BUTTON");
      setState(() => isLoading = true);
      
      await _executeVersion14Order();
      
      return;
    }
  }
}