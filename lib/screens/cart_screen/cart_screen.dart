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
import 'package:dio/dio.dart'; 

class CartScreen extends StatefulWidget {
  final bool isFromBottomNav; 
  
  const CartScreen({Key? key, this.isFromBottomNav = false}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _discountController = TextEditingController();
  CartModel? _cartDetailsModel;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  CartScreenBloc? cartScreenBloc;
  bool quantityChanged = false;
  
  String? _deliveryAddress;
  String? _userName;
  StreamSubscription? _cartSubscription;

  @override
  void initState() {
    cartScreenBloc = context.read<CartScreenBloc>();
    fetchCartData();
    _deliveryAddress = CurrentLocationManager.address;
    _fetchUserName();
    
    _cartSubscription = GlobalData.cartUpdateStream.stream.listen((_) async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) fetchCartData();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
       await Future.delayed(const Duration(milliseconds: 500));
       if (mounted) fetchCartData();
    });

    super.initState();
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    super.dispose();
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
          automaticallyImplyLeading: false,
          leading: widget.isFromBottomNav 
              ? null 
              : IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
          title: Text(
            StringConstants.cart.localized(),
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        body: _cartScreenData(context),
        bottomNavigationBar: (_cartDetailsModel?.items?.isNotEmpty ?? false)
            ? BlinkitBottomCartBar(
                currentAddress: _deliveryAddress,
                userName: _userName,
                cartDetailsModel: _cartDetailsModel!,
                quantityChanged: quantityChanged,
                onChangeAddressTap: _handleAddressChange,
                onProceedTap: _handleProceedTap,
                buttonText: appStoragePref.getCustomerLoggedIn() ? "Proceed to Pay" : "Login Required", 
              )
            : null,
      ),
    );
  }

  // Logic handlers (Addresses and Proceed)
  void _handleAddressChange() async {
    bool isLogged = appStoragePref.getCustomerLoggedIn();
    if (!isLogged) {
      final mapResult = await Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryLocationPage()));
      if (mapResult != null && mapResult is Map) _openAddressForm(mapResult['address']);
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
    if (!appStoragePref.getCustomerLoggedIn()) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const SignInScreen())).then((_) {
        fetchCartData();
        _fetchUserName();
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
    Navigator.pushNamed(context, checkoutScreen, arguments: CartNavigationData(
        total: _cartDetailsModel?.formattedPrice?.grandTotal.toString() ?? "0",
        cartDetailsModel: _cartDetailsModel!,
        cartScreenBloc: cartScreenBloc,
    ));
  }

  _cartScreenData(BuildContext context) {
    return BlocConsumer<CartScreenBloc, CartScreenBaseState>(
      listener: (BuildContext context, CartScreenBaseState state) {
        if (state is FetchCartDataState && state.status == CartStatus.success) {
            _cartDetailsModel = state.cartDetailsModel;
            setState(() {}); 
        }

        if (state is RemoveCartItemState) {
          if (state.status == CartStatus.success) {
            ShowMessage.successNotification(state.removeCartProductModel?.message ?? "", context);
            fetchCartData(); 
          } else if (state.status == CartStatus.fail) {
             ShowMessage.errorNotification(state.error ?? "", context);
          }
        }

        if (state is UpdateCartState) {
          if (state.status == CartStatus.success) {
            setState(() => quantityChanged = false);
            _cartDetailsModel = state.cartDetailsModel?.cart;
            setState(() {});
          } else if (state.status == CartStatus.fail) {
            ShowMessage.errorNotification(state.error ?? "", context);
          }
        }
        
        if (state is RemoveAllCartItemState) {
          if (state.status == CartStatus.success) {
            _cartDetailsModel = null; // 🟢 Force clear UI
            GlobalData.cartCountController.sink.add(0);
            setState(() {});
            ShowMessage.successNotification(state.limitMsg ?? "Cart cleared", context); // 🟢 Uses your new field
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

  // 🟢 FIXED: This method now handles the "White Screen" by checking for empty data
  Widget buildContainer(BuildContext context, CartScreenBaseState state) {
    if (state is ShowLoaderCartState) return const CartLoaderView();

    // 1. If we have no model or the items list is empty, show the Empty View
    if (_cartDetailsModel == null || (_cartDetailsModel?.items?.isEmpty ?? true)) {
      return EmptyDataView(
        assetPath: AssetConstants.emptyCart,
        message: StringConstants.emptyCartPageLabel.localized(),
        showDescription: true,
        width: MediaQuery.of(context).size.width / 1.5,
      );
    }

    // 2. Otherwise, we have data, show the list
    _discountController.text = _cartDetailsModel?.couponCode ?? "";
    return RefreshIndicator(
      onRefresh: () async => fetchCartData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              CartListItem(
                  cartDetailsModel: _cartDetailsModel!,
                  cartScreenBloc: cartScreenBloc,
              ),
              const SizedBox(height: 16),
              ApplyCouponView(
                discountController: _discountController,
                cartScreenBloc: cartScreenBloc,
                cartDetailsModel: _cartDetailsModel!,
              ),
              const SizedBox(height: 16),
              PriceDetailView(cartDetailsModel: _cartDetailsModel!),
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