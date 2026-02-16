/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; 
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:bagisto_app_demo/screens/home_page/utils/index.dart';
import 'package:bagisto_app_demo/screens/cart_screen/utils/cart_index.dart';
import 'package:bagisto_app_demo/screens/home_page/data_model/theme_customization.dart'; 
import 'package:bagisto_app_demo/screens/home_page/widget/home_page_view.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:bagisto_app_demo/screens/home_page/widget/delivery_location_page.dart';
import 'package:bagisto_app_demo/utils/current_location_manager.dart';
import 'package:bagisto_app_demo/screens/sign_in/view/sign_in_screen.dart';
import 'package:bagisto_app_demo/utils/app_global_data.dart'; 
import 'package:bagisto_app_demo/utils/shared_preference_helper.dart';
import 'package:bagisto_app_demo/utils/string_constants.dart';
import 'package:bagisto_app_demo/utils/index.dart'; 
import 'package:collection/collection.dart'; 

// 🟢 Services Import (Crucial for ApiClient)
import 'package:bagisto_app_demo/services/api_client.dart';

// 🟢 Search Imports
import 'package:bagisto_app_demo/screens/search_screen/view/search_screen.dart';
import 'package:bagisto_app_demo/screens/search_screen/utils/index.dart' hide Status; 
import 'package:bagisto_app_demo/widgets/image_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoggedIn = false, isLoading = false, callPreCache = true;
  String? image, customerLanguage, customerCurrency, customerUserName;
  HomePageBloc? homePageBloc;
  AddToCartModel? addToCartModel;
  ThemeCustomDataModel? customHomeData;
  CurrencyLanguageList? currencyLanguageList;
  GetDrawerCategoriesData? getHomeCategoriesData;
  AccountInfoModel? customerDetails;
  DrawerBloc? drawerBloc;

  // Location
  String? _address;
  bool _addrLoading = false;

  // Voice search
  final TextEditingController _searchController = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  StreamSubscription? _profileSubscription;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _registerStreamListener();
    _fetchSharedPreferenceData();
    drawerBloc = context.read<DrawerBloc>();

    // Initial Cart Load
    getCartCount().then((v) => GlobalData.cartCountController.sink.add(v));
    
    // Sync with Server (Wait 2s to allow UI to settle)
    Future.delayed(const Duration(seconds: 2), () => _syncCartCount());

    customerLanguage = appStoragePref.getLanguageName();
    customerCurrency = appStoragePref.getCurrencyLabel();
    
    // 1. Load Offline Data
    fetchOfflineProductData();
    
    // 2. Fetch Fresh Data (Staggered to avoid connection loss)
    Future.delayed(const Duration(milliseconds: 500), () => fetchHomepageData());
    
    GlobalData.locale = appStoragePref.getCustomerLanguage();

    // 🔴 OPTIMIZATION: Wait 3s before triggering location/address to avoid thread hammer
    Future.delayed(const Duration(seconds: 3), () => _loadInitialAddress()); 

    // 🟢 Listen for profile updates (Image, Name, and Full Model)
    _profileSubscription = GlobalData.profileUpdateStream.listen((data) {
      if (!mounted) return;
      if (data.isNotEmpty) {
        debugPrint("👤 HOME PAGE [STREAM]: name=${data['name']}, email=${data['email']}");
        setState(() {
          image = data['image'];
          customerUserName = data['name'];
          isLoggedIn = appStoragePref.getCustomerLoggedIn(); 
          
          // 🟢 CRITICAL: Also update the details object so Drawer gets fresh data
          if (customerDetails != null) {
              customerDetails!.name = data['name'];
              customerDetails!.imageUrl = data['image'];
              if (data.containsKey('email')) customerDetails!.email = data['email'];
              List<String> names = (data['name'] ?? "").toString().split(" ");
              if (names.isNotEmpty) customerDetails!.firstName = names.first;
              if (names.length > 1) customerDetails!.lastName = names.sublist(1).join(" ");
          }
        });
      }
    });
  }

  // 🟢 HELPER: Sync Cart Count
  void _syncCartCount() async {
    int localCount = appStoragePref.getCartCount();
    GlobalData.cartCountController.sink.add(localCount);

    try {
      var cartModel = await ApiClient().getCartCount(); 
      if (cartModel != null) {
        int serverCount = cartModel.itemsQty ?? 0;
        appStoragePref.setCartCount(serverCount);
        GlobalData.cartCountController.sink.add(serverCount);
      }
    } catch (e) {
      debugPrint("Cart Sync Error: $e");
    }
  }

  Future<int> getCartCount() async => appStoragePref.getCartCount();

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialAddress() async {
    setState(() => _addrLoading = true);
    try {
      // Add timeout protection to prevent crashes
      final serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
      
      if (!serviceEnabled) {
        debugPrint('📍 Location services disabled');
        setState(() => _addrLoading = false);
        return;
      }

      var permission = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 3));
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 5));
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('📍 Location permission denied');
        setState(() => _addrLoading = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude)
          .timeout(const Duration(seconds: 5));

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        
        final parts = [
          p.name, p.subLocality, p.locality,
          p.administrativeArea, p.postalCode,
        ].where((e) => (e ?? '').trim().isNotEmpty).map((e) => e!.trim()).toList();

        final fullAddress = parts.join(', ');
        setState(() => _address = fullAddress);
        
        CurrentLocationManager.setLocation(
          fullAddress, 
          pos.latitude, 
          pos.longitude,
          cityVal: p.locality ?? p.subAdministrativeArea,
          stateVal: p.administrativeArea,
          countryVal: p.isoCountryCode ?? "IN",
          pinVal: p.postalCode
        );
        debugPrint('📍 Location loaded: $fullAddress');
      }
    } catch (e) {
      // Catch all errors including DeadSystemException
      debugPrint('📍 Location error (non-fatal): $e');
    } finally {
      if (mounted) setState(() => _addrLoading = false);
    }
  }

  Future<void> _openDeliveryLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DeliveryLocationPage()),
    );
    if (result is Map && result['address'] is String) {
      String newAddr = result['address'];
      double? lat = result['lat'];
      double? lng = result['lng'];
      
      setState(() => _address = newAddr);
      
      if(lat != null && lng != null) {
         CurrentLocationManager.setLocation(newAddr, lat, lng);
      }
    }
  }

  fetchHomepageData() async {
    homePageBloc = context.read<HomePageBloc>();
    homePageBloc?.add(FetchHomeCustomData());
  }

  fetchOfflineProductData() async {
    var offlineCategories = appStoragePref.getDrawerCategories();
    GlobalData.categoriesDrawerData = offlineCategories;
    
    if (offlineCategories != null) {
      if(mounted) {
        setState(() {
          getHomeCategoriesData = offlineCategories;
        });
      }
    }
  }

  void _goToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => SearchBloc(SearchRepositoryImp()), 
          child: const SearchScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => buildView(context);

  Widget buildView(BuildContext context) {
    return BlocConsumer<HomePageBloc, HomePageBaseState>(
      listener: (context, state) {
        if (state is FetchHomeCustomDataState && state.status == Status.success) {
           GlobalData.allProducts?.clear();
           customHomeData = state.homepageSliders;
           getHomePageData(customHomeData);
           setState(() {}); 
        }
        
        if (state is FetchHomeCategoriesState && state.status == Status.success) {
           getHomeCategoriesData = state.getCategoriesData;
           GlobalData.categoriesDrawerData = state.getCategoriesData;
           // 🟢 OPTIMIZATION: CMC data already fetched by buildContainer if needed, 
           // or we can just fetch it once here.
           homePageBloc?.add(FetchCMSDataEvent());
           setState(() {});
        }

        if (state is AddToCartState) {
          if (state.status == Status.success) {
            addToCartModel = state.graphQlBaseModel;
            // 🟢 SYNC
            GlobalData.updateCartState(addToCartModel?.cart);
            if (addToCartModel?.cart != null) {
              appStoragePref.setCartCount(addToCartModel!.cart!.itemsQty ?? 0);
            }
            // Notify other screens
            GlobalData.cartUpdateStream.add(null); 
            // Ensure full fetch if items logic in addToCart is incomplete
            context.read<CartScreenBloc>().add(FetchCartDataEvent());

            ShowMessage.successNotification(
                state.successMsg ?? "Item added to cart successfully", context);
                
          } else if (state.status == Status.fail) {
            ShowMessage.errorNotification(
                state.error ?? "Failed to add to cart", context);
          }
        }
      },
      
      builder: (context, state) {
        if (state is ShowLoaderState) return const HomePageLoader();
        
        bool hasProducts = (GlobalData.allProducts ?? []).isNotEmpty;
        bool hasCategories = getHomeCategoriesData != null;
        
        if (!hasProducts && !hasCategories) {
           return const HomePageLoader();
        }

        return buildContainer(context);
      },
    );
  }

  Widget buildContainer(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),

        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(130), // Slightly reduced height
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF9C4), Colors.white], // Subtle soft yellow to white gradient
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TOP ROW: Delivery Header + Profile/Menu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start, // Align to top
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🟢 1. "Delivery in..." Header
                              Row(
                                children: [
                                  Text(
                                    "Delivery in 11 minutes", 
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      color: const Color(0xFF2E7D32), // Direct Blinkit Green highlight
                                      height: 1.0, 
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2), // Small gap
                              
                              // 🟢 2. Address Selector
                              GestureDetector(
                                onTap: _openDeliveryLocation,
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _addrLoading
                                            ? 'Detecting location…'
                                            : ((_address?.trim().isNotEmpty ?? false)
                                                ? _address!.trim()
                                                : 'Select delivery address'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_drop_down,
                                      size: 20,
                                      color: Colors.black87,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Profile Icon (Blinkit style is minimal, usually just profile icon)
                        Builder(
                          builder: (ctx) => InkWell(
                            onTap: () => Navigator.pushNamed(context, modernAccount),
                            child: Container(
                              height: 38, width: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[100],
                              ),
                              child: Center(
                                  child: isLoggedIn && image != null 
                                    ? CircleAvatar(
                                        backgroundImage: ImageView.getImageProvider(image), 
                                        radius: 18
                                      )
                                    : const Icon(Icons.person, color: Colors.black87, size: 24),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // SEARCH BAR (Blinkit Style: Rounded, soft shadow)
                    InkWell(
                      onTap: _goToSearch, 
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Color(0xFF27C16B), size: 24), // Green Search Icon
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Search 'Milk'",
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                            ),
                            Container(
                                width: 1, height: 20, color: Colors.grey[300]
                            ),
                            IconButton(
                              icon: const Icon(Icons.mic, color: Colors.grey, size: 22),
                              onPressed: _goToSearch, 
                              tooltip: 'Voice search',
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.only(left: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: HomePageView(
                  customHomeData: customHomeData,
                  isLoading: isLoading,
                  getCategoriesData: getHomeCategoriesData,
                  isLogin: isLoggedIn,
                  homePageBloc: homePageBloc,
                  callPreCache: callPreCache,
                ),
              ),
            ],
          ),
        ),
      );
  }

  void _fetchSharedPreferenceData() async {
    bool isLogged = appStoragePref.getCustomerLoggedIn();
    if (isLogged) {
      setState(() {
        customerUserName = appStoragePref.getCustomerName();
        image = appStoragePref.getCustomerImage();
        customerDetails = appStoragePref.getCustomerDetails(); // 🟢 NEW: Load full model
        isLoggedIn = true;
      });
    } else {
      setState(() {
        customerUserName = StringConstants.signInLabel.localized();
        image = null; 
        customerDetails = null; // 🟢 NEW: Clear model
        isLoggedIn = false;
      });
    }
  }

  void _registerStreamListener() {
    GlobalData.productsStream.stream.listen((event) {
      if ((event?.data ?? []).isNotEmpty) {
        GlobalData.allProducts?.add(event);
        if (mounted) setState(() {});
      }
    });
  }

  Future<void> getHomePageData(ThemeCustomDataModel? customHomeData) async {
    customHomeData?.themeCustomization ??= [];
    await Future.wait(customHomeData!.themeCustomization!.map((element) async {
      List<Map<String, dynamic>> filters = [];
      if (element.type == "category_carousel") {
        // ... (existing code for category carousel)
        element.translations
            ?.firstWhereOrNull((e) => e.localeCode == GlobalData.locale)
            ?.options
            ?.filters
            ?.forEach((f) {
          filters.add({"key": '"${f.key}"', "value": '"${f.value}"'});
        });
        homePageBloc?.add(FetchHomePageCategoriesEvent(filters: filters));
      } else if (element.type == "product_carousel") {
        // Get section title for tagging
        String sectionTitle = "";
        try {
          final trans = element.translations?.firstWhereOrNull(
            (e) => e.localeCode == GlobalData.locale
          );
          sectionTitle = trans?.options?.title ?? "";
        } catch (_) {}
        
        element.translations
            ?.firstWhereOrNull((e) => e.localeCode == GlobalData.locale)
            ?.options
            ?.filters
            ?.forEach((f) {
          filters.add({"key": '"${f.key}"', "value": '"${f.value}"'});
        });
        
        // 🟢 FIX: Force sort by 'created_at-desc' for New Products section
        if (sectionTitle.toLowerCase().contains("new products")) {
          // Remove existing sort filter if any
          filters.removeWhere((f) => f['key'].toString().contains('sort'));
          
          // 🟢 REMOVE 'new' FILTER too (User wants chronologically new, not manually marked 'new')
          filters.removeWhere((f) => f['key'].toString().contains('new'));

          // Add correct sort filter
          filters.add({"key": '"sort"', "value": '"created_at-desc"'});
        }
        
        // Pass sectionTitle as ID to solve race condition
        homePageBloc?.add(FetchAllProductsEvent(filters, sectionId: sectionTitle));
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }));
  }
}