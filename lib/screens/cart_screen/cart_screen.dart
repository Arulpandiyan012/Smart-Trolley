/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */
import 'package:bagisto_app_demo/screens/cart_screen/utils/cart_index.dart';
import 'package:bagisto_app_demo/screens/cart_screen/widget/cart_actions_view.dart';
import 'package:bagisto_app_demo/screens/cart_screen/widget/blinkit_bottom_cart_bar.dart';
import 'package:bagisto_app_demo/utils/current_location_manager.dart';
import 'package:bagisto_app_demo/screens/home_page/widget/delivery_location_page.dart';
import 'package:bagisto_app_demo/screens/home_page/widget/address_details_sheet.dart';
import 'package:bagisto_app_demo/screens/checkout/utils/index.dart';
import 'package:bagisto_app_demo/screens/cart_screen/widget/saved_address_sheet.dart';
import 'package:bagisto_app_demo/screens/sign_in/view/sign_in_screen.dart';
import 'package:dio/dio.dart'; // 🟢 Added Dio for API call

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _discountController = TextEditingController();
  CartModel? _cartDetailsModel;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  CartScreenBloc? cartScreenBloc;
  bool quantityChanged = false;
  
  String? _deliveryAddress;
  String? _userName;

  @override
  void initState() {
    cartScreenBloc = context.read<CartScreenBloc>();
    fetchCartData();
    _deliveryAddress = CurrentLocationManager.address;
    _fetchUserName();
    super.initState();
  }

  fetchCartData() {
    cartScreenBloc?.add(FetchCartDataEvent());
  }

  void _fetchUserName() {
    if (appStoragePref.getCustomerLoggedIn()) {
      String fullName = appStoragePref.getCustomerName();
      if (fullName.isNotEmpty) {
        _userName = fullName.split(' ')[0];
      }
    }
  }

  // 🟢 NEW: Function to Save Address to Backend immediately
  Future<void> _saveCartAddress(String addressId) async {
      try {
        String customerId = appStoragePref.getCustomerId()?.toString() ?? "0";
        String cartId = _cartDetailsModel?.id?.toString() ?? "0";

        var dio = Dio();
        var formData = FormData.fromMap({
          'customer_id': customerId,
          'cart_id': cartId,
          'address_id': addressId
        });

        debugPrint("🔵 Saving Address ID $addressId for Cart $cartId...");

        await dio.post(
          'https://ecom.thesmartedgetech.com/mobikul-save-checkout-address.php', 
          data: formData
        );
        debugPrint("✅ Address Saved Successfully to Cart!");
      } catch (e) {
        debugPrint("❌ Failed to save address: $e");
      }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            StringConstants.cart.localized(),
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        body: _cartScreenData(context),
        
        // Bottom Bar that updates immediately on state change
        bottomNavigationBar: (_cartDetailsModel?.items?.isNotEmpty ?? false)
            ? BlinkitBottomCartBar(
                currentAddress: _deliveryAddress,
                userName: _userName,
                cartDetailsModel: _cartDetailsModel!,
                quantityChanged: quantityChanged,
                onChangeAddressTap: _handleAddressChange,
                onProceedTap: _handleProceedTap,
                buttonText: appStoragePref.getCustomerLoggedIn() 
                    ? "Proceed to Pay" 
                    : "Login Required", 
              )
            : null,
      ),
    );
  }

  void _handleAddressChange() async {
    bool isLogged = appStoragePref.getCustomerLoggedIn();
    
    if (!isLogged) {
      final mapResult = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DeliveryLocationPage()),
      );
      if (mapResult != null && mapResult is Map) {
         _openAddressForm(mapResult['address']);
      }
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => BlocProvider(
          create: (context) => CheckOutBloc(CheckOutRepositoryImp()),
          child: const SavedAddressSheet(),
        ),
      ).then((selectedAddress) {
        if (selectedAddress != null && selectedAddress is AddressData) {
           
           // 🟢 1. CALL API TO SAVE ADDRESS
           _saveCartAddress(selectedAddress.id.toString());

           // 2. Update UI
           setState(() {
             _deliveryAddress = "${selectedAddress.address1}, ${selectedAddress.city}";
             CurrentLocationManager.address = _deliveryAddress;
             _userName = selectedAddress.firstName; 
           });
        }
      });
    }
  }

  void _openAddressForm(String initialAddress) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => FractionallySizedBox(
          heightFactor: 0.85,
          child: AddressDetailsSheet(initialArea: initialAddress),
        ),
      ).then((value) {
         if (value != null && value is Map) {
            setState(() {
               _deliveryAddress = "${value['flatHouseBuilding']}, ${value['area']}";
               _userName = value['firstName'];
            });
         }
      });
  }

  void _handleProceedTap() {
    bool isLogged = appStoragePref.getCustomerLoggedIn();

    if (!isLogged) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
      ).then((_) {
        fetchCartData();
        _fetchUserName();
        setState(() {}); 
      });
      return; 
    }

    if (quantityChanged) {
      ShowMessage.warningNotification("Please wait, updating cart...", context);
      return;
    }

    if (_deliveryAddress == null) {
      ShowMessage.errorNotification("Please select a delivery address", context);
      return;
    }

    Navigator.pushNamed(
      context, 
      checkoutScreen, 
      arguments: CartNavigationData(
        total: _cartDetailsModel?.formattedPrice?.grandTotal.toString() ?? "0",
        cartDetailsModel: _cartDetailsModel!,
        cartScreenBloc: cartScreenBloc,
      )
    );
  }


  _cartScreenData(BuildContext context) {
    return BlocConsumer<CartScreenBloc, CartScreenBaseState>(
      listener: (BuildContext context, CartScreenBaseState state) {
        // 1. HANDLE DATA FETCH (INITIAL LOAD)
        if (state is FetchCartDataState) {
          if (state.status == CartStatus.success) {
            _cartDetailsModel = state.cartDetailsModel;
            setState(() {}); // Force rebuild so BottomBar appears immediately
          }
        }

        // 2. HANDLE REMOVE ITEM
        if (state is RemoveCartItemState) {
          if (state.status == CartStatus.success) {
            ShowMessage.successNotification(state.removeCartProductModel?.message ?? "", context);
            GlobalData.cartCountController.sink.add(state.removeCartProductModel?.cart?.itemsQty ?? 0);
            
            if (_cartDetailsModel != null) {
               _cartDetailsModel!.items!.removeWhere((element) => element.id == state.productDeletedId);
               fetchCartData(); 
            }
          } else if (state.status == CartStatus.fail) {
             ShowMessage.errorNotification(state.error ?? "", context);
          }
        }

        // 3. HANDLE UPDATE QTY
        if (state is UpdateCartState) {
          if (state.status == CartStatus.success) {
            setState(() => quantityChanged = false);
            fetchCartData(); 
          } else if (state.status == CartStatus.fail) {
            ShowMessage.errorNotification(state.error ?? "", context);
          }
        }
        
        // 4. HANDLE ADD COUPON
        if (state is AddCouponState) {
           if (state.status == CartStatus.success) {
             fetchCartData(); 
           } else if (state.status == CartStatus.fail) {
             ShowMessage.errorNotification(state.error ?? "", context);
           }
        }

        // 5. HANDLE REMOVE COUPON
        if (state is RemoveCouponCartState) {
           if (state.status == CartStatus.success) {
             fetchCartData(); 
           } else if (state.status == CartStatus.fail) {
             ShowMessage.errorNotification(state.error ?? "", context);
           }
        }
      },
      builder: (BuildContext context, CartScreenBaseState state) {
        return buildContainer(context, state);
      },
    );
  }

  Widget buildContainer(BuildContext context, CartScreenBaseState state) {
    if (state is ShowLoaderCartState) return const CartLoaderView();

    if (state is FetchCartDataState && state.status == CartStatus.success) {
       _cartDetailsModel = state.cartDetailsModel;
    }
    
    // Always update counts if model exists
    if (_cartDetailsModel != null) {
        _discountController.text = _cartDetailsModel?.couponCode ?? "";
        GlobalData.cartCountController.sink.add(_cartDetailsModel?.itemsQty ?? 0);
        return _cartScreenBody(_cartDetailsModel!);
    }

    return const SizedBox();
  }

  _cartScreenBody(CartModel cartDetailsModel) {
    if (cartDetailsModel.items?.isEmpty ?? true) {
      return EmptyDataView(
        assetPath: AssetConstants.emptyCart,
        message: StringConstants.emptyCartPageLabel,
        showDescription: true,
        width: MediaQuery.of(context).size.width / 1.5,
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async => fetchCartData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              CartListItem(
                  cartDetailsModel: cartDetailsModel,
                  cartScreenBloc: cartScreenBloc,
              ),
              const SizedBox(height: 16),
              ApplyCouponView(
                discountController: _discountController,
                cartScreenBloc: cartScreenBloc,
                cartDetailsModel: cartDetailsModel,
              ),
              const SizedBox(height: 16),
              PriceDetailView(cartDetailsModel: cartDetailsModel),
              const SizedBox(height: 20),
              CartActionsView(cartScreenBloc: cartScreenBloc),
              const SizedBox(height: 180), 
            ],
          ),
        ),
      ),
    );
  }
}