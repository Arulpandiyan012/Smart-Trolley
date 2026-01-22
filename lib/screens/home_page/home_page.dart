/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; 
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:bagisto_app_demo/screens/home_page/utils/index.dart';
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

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _registerStreamListener();
    _fetchSharedPreferenceData();
    drawerBloc = context.read<DrawerBloc>();

    // Initial Cart Load
    getCartCount().then((v) => GlobalData.cartCountController.sink.add(v));
    
    // Sync with Server
    _syncCartCount();

    customerLanguage = appStoragePref.getLanguageName();
    customerCurrency = appStoragePref.getCurrencyLabel();
    
    // 1. Load Offline Data
    fetchOfflineProductData();
    
    // 2. Fetch Fresh Data
    fetchHomepageData();
    
    GlobalData.locale = appStoragePref.getCustomerLanguage();

    _loadInitialAddress(); 
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

  Future<void> _loadInitialAddress() async {
    setState(() => _addrLoading = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _addrLoading = false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _addrLoading = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);

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
      }
    } catch (_) {} finally {
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

  Widget _drawerData(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: DrawerListView(
        isLoggedIn: isLoggedIn,
        customerUserName: customerUserName ?? "Guest",
        image: image,
        customerLanguage: customerLanguage,
        customerCurrency: customerCurrency ?? "",
        customerDetails: customerDetails,
        currencyLanguageList: currencyLanguageList,
        loginCallback: (isLogged) {
          setState(() {
             isLoggedIn = isLogged;
             _fetchSharedPreferenceData(); 
          });
        },
      ),
    );
  }

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
           homePageBloc?.add(FetchCMSDataEvent());
           setState(() {});
        }

        if (state is AddToCartState) {
          if (state.status == Status.success) {
            addToCartModel = state.graphQlBaseModel;
            appStoragePref.setCartCount(addToCartModel?.cart?.itemsQty ?? 0);
            GlobalData.cartCountController.sink.add(addToCartModel?.cart?.itemsQty ?? 0);
            GlobalData.cartUpdateStream.add(null); // 🟢 Notify Cart Screen

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
        endDrawer: _drawerData(context),

        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(145), 
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF9CCC65), 
                  Color(0xFFDCEDC8), 
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              isLoggedIn
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Welcome back,",
                                          style: TextStyle(
                                            fontSize: 11, 
                                            color: Colors.black54,
                                            fontWeight: FontWeight.w500
                                          ),
                                        ),
                                        Text(
                                          customerUserName ?? "", 
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    )
                                  : SizedBox(
                                      height: 34,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(builder: (context) => const SignInScreen()),
                                          ).then((_) {
                                            _fetchSharedPreferenceData(); 
                                          });
                                        },
                                        child: const Text(
                                          "Sign In",
                                          style: TextStyle(
                                            color: Colors.white, 
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14
                                          ),
                                        ),
                                      ),
                                    ),
                              
                              const SizedBox(height: 2),
                              GestureDetector(
                                onTap: _openDeliveryLocation,
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
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
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 18,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        Builder(
                          builder: (ctx) => IconButton(
                            icon: const Icon(Icons.menu, color: Colors.black87),
                            onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                            tooltip: MaterialLocalizations.of(ctx).openAppDrawerTooltip,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    InkWell(
                      onTap: _goToSearch, 
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            const Icon(Icons.search, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                enabled: false, 
                                controller: _searchController,
                                decoration: const InputDecoration(
                                  hintText: "Search for fruits, snacks, groceries…",
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.mic, color: Colors.grey),
                              onPressed: _goToSearch, 
                              tooltip: 'Voice search',
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
        isLoggedIn = true;
      });
    } else {
      setState(() {
        customerUserName = StringConstants.signInLabel.localized();
        image = null; // Clear image
        isLoggedIn = false;
      });
    }
  }

  void _registerStreamListener() {
    GlobalData.productsStream.stream.listen((event) {
      if ((event?.data ?? []).isNotEmpty) {
        GlobalData.allProducts?.add(event);
      }
      if (mounted) setState(() {});
    });
  }

  Future<void> getHomePageData(ThemeCustomDataModel? customHomeData) async {
    customHomeData?.themeCustomization ??= [];
    await Future.wait(customHomeData!.themeCustomization!.map((element) async {
      List<Map<String, dynamic>> filters = [];
      if (element.type == "category_carousel") {
        element.translations
            ?.firstWhereOrNull((e) => e.localeCode == GlobalData.locale)
            ?.options
            ?.filters
            ?.forEach((f) {
          filters.add({"key": '"${f.key}"', "value": '"${f.value}"'});
        });
        homePageBloc?.add(FetchHomePageCategoriesEvent(filters: filters));
      } else if (element.type == "product_carousel") {
        element.translations
            ?.firstWhereOrNull((e) => e.localeCode == GlobalData.locale)
            ?.options
            ?.filters
            ?.forEach((f) {
          filters.add({"key": '"${f.key}"', "value": '"${f.value}"'});
        });
        homePageBloc?.add(FetchAllProductsEvent(filters));
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }));
  }
}