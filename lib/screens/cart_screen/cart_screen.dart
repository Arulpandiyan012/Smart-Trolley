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
import 'package:bagisto_app_demo/services/api_client.dart'; 

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
  AddressData? _selectedAddressObj;
  StreamSubscription? _cartSubscription;

  @override
  void initState() {
    cartScreenBloc = context.read<CartScreenBloc>();
    fetchCartData();
    _deliveryAddress = CurrentLocationManager.address;
    _fetchUserName();
    _fetchDefaultAddress(); 
    
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

  void _fetchDefaultAddress() async {
    if (!appStoragePref.getCustomerLoggedIn()) return;
    try {
      final addressModel = await ApiClient().getAddressData();
      if (addressModel != null && addressModel.addressData != null && addressModel.addressData!.isNotEmpty) {
        // Find default address
        AddressData? def = addressModel.addressData!.firstWhereOrNull((a) => a.isDefault == true);
        if (def == null && addressModel.addressData!.isNotEmpty) {
           def = addressModel.addressData!.first;
        }

        if (def != null && mounted) {
          setState(() {
            _selectedAddressObj = def;
            _deliveryAddress = "${def?.address1}, ${def?.city}";
            _userName = def?.firstName;
            CurrentLocationManager.address = _deliveryAddress;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching default address: $e");
    }
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    super.dispose();
  }

  fetchCartData() {
    cartScreenBloc?.add(FetchCartDataEvent());
  }

  // 🟢 NEW: Simulated Discount Calculation for FIRST25
  void _simulateDiscountCalculation(double percent, String code) {
    if (_cartDetailsModel == null) return;
    setState(() {
      GlobalData.appliedCouponCode = code; 
    });
    _updateGlobalCartData(_cartDetailsModel);
  }

  void _fetchUserName() {
    if (appStoragePref.getCustomerLoggedIn()) {
      String fullName = appStoragePref.getCustomerName();
      if (fullName.isNotEmpty) {
        _userName = fullName.split(' ')[0];
      }
    }
  }

  // 🟢 NEW: Update Global State for reactive UI
  void _updateGlobalCartData(CartModel? model) {
    if (!mounted) return;
    GlobalData.updateCartState(model);
    appStoragePref.setCartCount(model?.itemsQty ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
          elevation: 0.5,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          automaticallyImplyLeading: false,
          leading: widget.isFromBottomNav 
              ? null 
              : IconButton(
                  icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
                  onPressed: () => Navigator.pop(context),
                ),
          title: Text(
            StringConstants.cart.localized(),
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color ?? Colors.black, 
              fontWeight: FontWeight.bold, 
              fontSize: 18
            ),
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
             _selectedAddressObj = selectedAddress;
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
    String currency = GlobalData.currencyCode ?? "₹";
    Navigator.pushNamed(context, checkoutScreen, arguments: CartNavigationData(
        total: "$currency ${_cartDetailsModel?.adjustedGrandTotal.toStringAsFixed(2)}",
        cartDetailsModel: _cartDetailsModel!,
        cartScreenBloc: cartScreenBloc,
        selectedAddress: _selectedAddressObj,
    ));
  }

  _cartScreenData(BuildContext context) {
    return BlocConsumer<CartScreenBloc, CartScreenBaseState>(
      listener: (BuildContext context, CartScreenBaseState state) {
        if (state is FetchCartDataState && state.status == CartStatus.success) {
            _cartDetailsModel = state.cartDetailsModel;
            _updateGlobalCartData(_cartDetailsModel); // 🟢 SYNC
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
            _updateGlobalCartData(_cartDetailsModel); // 🟢 SYNC
            setState(() {});
          } else if (state.status == CartStatus.fail) {
            ShowMessage.errorNotification(state.error ?? "", context);
          }
        }
        
        if (state is RemoveAllCartItemState) {
          if (state.status == CartStatus.success) {
            _cartDetailsModel = null; // 🟢 Force clear UI
            GlobalData.optimisticClearCart(); // 🟢 SYNC ALL SCREENS
            setState(() {});
            ShowMessage.successNotification(state.limitMsg ?? "Cart cleared", context); 
          } else if (state.status == CartStatus.fail) {
            ShowMessage.errorNotification(state.error ?? "", context);
          }
        }

        // 🟢 NEW: Handle Coupon Application
        if (state is AddCouponState) {
          if (state.status == CartStatus.success) {
             String code = _discountController.text.toUpperCase().trim();
             if (code == "FIRST25") {
                // 🔥 LOCAL SIMULATION: Recalculate prices locally so they persist for demonstration
                _simulateDiscountCalculation(0.25, code);
                ShowMessage.successNotification(state.successMsg ?? "25% First Order discount applied!", context);
                // DO NOT call fetchCartData() - server doesn't know about FIRST25 simulation
             } else {
                ShowMessage.successNotification(state.successMsg ?? "Coupon applied!", context);
                fetchCartData(); // Normal refresh for real coupons
             }
          } else if (state.status == CartStatus.fail) {
             ShowMessage.errorNotification(state.error ?? "Invalid coupon", context);
          }
        }

        // 🟢 NEW: Handle Coupon Removal
        if (state is RemoveCouponCartState) {
          if (state.status == CartStatus.success) {
             GlobalData.appliedCouponCode = null; // 🟢 Clear simulation
             ShowMessage.successNotification(state.successMsg ?? "Coupon removed", context);
             fetchCartData(); // 🔥 REFRESH TO REVERT TOTALS
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
              _buildAddressSection(context),
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

  // 🟢 NEW: Integrated Address Section in the Cart body
  Widget _buildAddressSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), 
            blurRadius: 4, 
            offset: const Offset(0, -2)
          )
        ],
        border: Border.all(color: Colors.grey.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    "Delivery Address",
                    style: TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.w800, 
                      color: Theme.of(context).textTheme.titleMedium?.color
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _handleAddressChange,
                child: Text(
                  "CHANGE",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_userName != null)
                      Text(
                        _userName!,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      _deliveryAddress ?? "Select an address to proceed",
                      style: TextStyle(
                        fontSize: 12, 
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}