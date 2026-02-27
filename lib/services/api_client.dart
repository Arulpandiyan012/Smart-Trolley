/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'dart:developer';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import 'package:bagisto_app_demo/data_model/account_models/account_update_model.dart';
import 'package:bagisto_app_demo/data_model/order_model/order_detail_model.dart';
import 'package:bagisto_app_demo/data_model/order_model/order_refund_model.dart';
import 'package:bagisto_app_demo/data_model/order_model/orders_list_data_model.dart';
import 'package:bagisto_app_demo/data_model/review_model/review_model.dart';
import 'package:bagisto_app_demo/data_model/sign_in_model/signin_model.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../data_model/account_models/account_info_details.dart';
import '../data_model/currency_language_model.dart';
import '../data_model/order_model/order_invoices_model.dart';
import '../data_model/order_model/shipment_model.dart';
import '../screens/add_review/data_model/add_review_model.dart';

import '../screens/address_list/data_model/default_address_model.dart' hide AddressData;
import '../screens/address_list/data_model/update_address_model.dart';
import '../screens/cart_screen/cart_model/apply_coupon.dart';
import '../screens/categories_screen/utils/index.dart';
import '../screens/checkout/data_model/checkout_save_address_model.dart';
import '../screens/checkout/data_model/checkout_save_shipping_model.dart';
import '../screens/checkout/data_model/save_order_model.dart';
import '../screens/checkout/data_model/save_payment_model.dart';

import '../screens/checkout/utils/index.dart' hide AddressData;
import '../screens/address_list/data_model/address_model.dart';

import '../screens/cms_screen/data_model/cms_details.dart';
import '../screens/cms_screen/data_model/cms_model.dart';
import '../screens/compare/utils/index.dart';
import '../screens/downloadable_products/data_model/download_product_Image_model.dart';
import '../screens/downloadable_products/data_model/download_product_model.dart';
import '../screens/downloadable_products/data_model/downloadable_product_model.dart' hide Order; 

import '../screens/home_page/data_model/get_categories_drawer_data_model.dart';
import '../screens/home_page/data_model/theme_customization.dart';
import '../screens/product_screen/data_model/download_sample_model.dart';
import '../screens/wishList/data_model/wishlist_model.dart';
import 'graph_ql.dart';
import 'mutation_query.dart';
import '../utils/server_configuration.dart';

typedef Parser<T> = T Function(Map<String, dynamic> json);

class ApiClient {
  GraphQlApiCalling client = GraphQlApiCalling();
  MutationsData mutation = MutationsData();

  // 🟢 1. GLOBAL HANDLER (Brute-Force Parser)
  Future<T?> handleResponse<T>(
    QueryResult<Object?> result,
    String operation,
    Parser<T> parser,
  ) async {
    if (result.hasException) {
      String token = appStoragePref.getCustomerToken();
      String tokenPreview = token.length > 5 ? token.substring(0, 5) : token;
      print("❌ GRAPHQL EXCEPTION ($operation) [Token: $tokenPreview...]: ${result.exception.toString()}");
    }

    String responseCookie = result.context.entry<HttpLinkResponseContext>()?.headers?['set-cookie'] ?? "";
    if (responseCookie.isNotEmpty) {
      appStoragePref.setCookieGet(responseCookie);
      GlobalData.cookie = responseCookie;
    }

    Map<String, dynamic> baseData = {};
    String errorMsg = "";

    if (result.hasException) {
      errorMsg = result.exception?.graphqlErrors.firstOrNull?.message ?? 
                 result.exception?.linkException.toString() ?? "Unknown Error";
      baseData['graphqlErrors'] = errorMsg;
      baseData['message'] = errorMsg;
    } else {
      if (result.data != null && result.data![operation] is List) {
        baseData = {'data': result.data![operation]};
      } else {
        var raw = result.data?[operation];
        if (raw is Map<String, dynamic>) {
          baseData = Map<String, dynamic>.from(raw);
        }
      }
    }

    // 🟢 BRUTE FORCE PARSING (Tries all combos to fix crashes)
    
    // 1. All Boolean
    try {
      var d = Map<String, dynamic>.from(baseData);
      d['success'] = true; d['status'] = true; d['responseStatus'] = true;
      if (errorMsg.isNotEmpty) { d['success'] = false; d['status'] = false; }
      return parser(d);
    } catch (_) {}

    // 2. All String
    try {
      var d = Map<String, dynamic>.from(baseData);
      d['success'] = "true"; d['status'] = "true"; d['responseStatus'] = "true";
      if (errorMsg.isNotEmpty) { d['success'] = "false"; d['status'] = "false"; }
      return parser(d);
    } catch (_) {}

    // 3. Mix A (Success=Bool, Status=String)
    try {
      var d = Map<String, dynamic>.from(baseData);
      d['success'] = true; d['status'] = "true"; d['responseStatus'] = "true";
      if (errorMsg.isNotEmpty) { d['success'] = false; d['status'] = "false"; }
      return parser(d);
    } catch (_) {}

    // 4. Mix B (Success=String, Status=Bool)
    try {
      var d = Map<String, dynamic>.from(baseData);
      d['success'] = "true"; d['status'] = true; d['responseStatus'] = true;
      if (errorMsg.isNotEmpty) { d['success'] = "false"; d['status'] = false; }
      return parser(d);
    } catch (e) {
      debugPrint("☠️ ALL PARSING ATTEMPTS FAILED for $operation");
    }

    return null;
  }

  // 🟢 2. LOGIN FIX (Prioritize Name over Phone)
  Future<SignInModel?> firebaseOtpLogin(String idToken, String? phone) async {
    try {
      var url = Uri.parse("$baseDomain/mobikul-login.php");
      String safePhone = phone ?? "";
      var response = await http.post(url, body: { "idToken": idToken, "phone": safePhone }, headers: {"Accept": "application/json"});
      debugPrint("📥 Login Body Response: ${response.body}"); // 🟢 Added full body log
      if (response.statusCode == 200) {
        // 🟢 CAPTURE COOKIES 
        String? setCookie = response.headers['set-cookie'];
        if (setCookie != null && setCookie.isNotEmpty) {
           appStoragePref.setCookieGet(setCookie);
           debugPrint("🍪 Captured Cookie from login: $setCookie");
        }

        var data = jsonDecode(response.body);
        if (data['success'] == true) {
          String token = data['customerToken'];
          appStoragePref.setCustomerToken(token);
          appStoragePref.setCustomerLoggedIn(true);
          
            if (data['customerData'] != null) {
              var cData = data['customerData'];
              debugPrint("🔑 LOGIN DATA KEYS: ${cData.keys.toList()}"); // 🟢 DIAGNOSTIC LOG
              
              // Robust ID extraction
              int cId = int.tryParse(cData['id']?.toString() ?? "") ?? 0;
              if (cId == 0) cId = int.tryParse(cData['customer_id']?.toString() ?? "") ?? 0;
              appStoragePref.setCustomerId(cId);
              
              // Extract Real Name (Check both formats)
              String fName = (cData['first_name'] ?? cData['firstName'])?.toString() ?? "";
              String lName = (cData['last_name'] ?? cData['lastName'])?.toString() ?? "";
              String fullName = "$fName $lName".trim();
              
              if (fullName.isEmpty) fullName = (cData['name'] ?? cData['fullName'])?.toString() ?? "";
              
              if (fullName.isNotEmpty) {
                 appStoragePref.setCustomerName(fullName);
              } else {
                 appStoragePref.setCustomerName(safePhone);
              }

              String email = (cData['email'] ?? cData['customer_email'])?.toString() ?? "";
              appStoragePref.setCustomerEmail(email);

              // 🟢 EXTENDED STORAGE: Save all details for Edit Screen auto-population
              String fNameSaved = (cData['first_name'] ?? cData['firstName'])?.toString() ?? "";
              String lNameSaved = (cData['last_name'] ?? cData['lastName'])?.toString() ?? "";
              String phoneSaved = (cData['phone'] ?? cData['customer_phone'])?.toString() ?? "";
              String genderSaved = (cData['gender'] ?? cData['customer_gender'])?.toString() ?? "";
              // 🟢 CHECK ALL KEYS: snake_case, camelCase, short
              String dobSaved = (cData['date_of_birth'] ?? cData['dob'] ?? cData['customer_dob'] ?? cData['dateOfBirth'])?.toString() ?? "";
              if (dobSaved == "0000-00-00") dobSaved = ""; // 🟢 Sanitize placeholder
              String imageUrl = (cData['profile_image_url'] ?? cData['image_url'] ?? cData['imageUrl'] ?? cData['profile_image'])?.toString() ?? "";

              appStoragePref.setCustomerFirstName(fNameSaved);
              appStoragePref.setCustomerLastName(lNameSaved);
              appStoragePref.setCustomerPhone(phoneSaved);
              appStoragePref.setCustomerGender(genderSaved);
              appStoragePref.setCustomerDob(dobSaved);
              appStoragePref.setCustomerNewsletter(cData['subscribed_to_newsletter'] == true || cData['is_subscribed'] == 1);

              debugPrint("💾 SAVED TO STORAGE: FName: $fNameSaved, LName: $lNameSaved, DOB: $dobSaved");
              // 🟢 NEW: Log ALL customer data keys and values for debugging
              debugPrint("🔍 FULL LOGIN CUSTOMER DATA: $cData");

              if (imageUrl.isNotEmpty) {
                appStoragePref.setCustomerImage(imageUrl);
              }

              // 🟢 SYNC FULL MODEL: Helper for Drawer/Header listeners
              // DrawerListView listens to 'customerDetails' key. We must construct and save it.
              AccountInfoModel authModel = AccountInfoModel(
                firstName: fNameSaved,
                lastName: lNameSaved,
                name: fullName,
                email: email,
                phone: phoneSaved,
                dateOfBirth: dobSaved,
                gender: genderSaved,
                imageUrl: imageUrl.isNotEmpty ? imageUrl : appStoragePref.getCustomerImage(),
                id: cId.toString()
              );
              appStoragePref.setCustomerDetails(authModel);

              // 🟢 Broadcast update globally for instant Home UI sync
            GlobalData.profileUpdateStream.add({
              "image": imageUrl,
              "name": fullName,
              "email": email
            });
            }

          // 🟢 SYNC PROFILE AFTER PERSISTENCE (Ensure ID and values are available for fallback)
          _syncProfileAfterLogin();

          return SignInModel.fromJson({ "status": true, "message": data['message'], "customerToken": token, "data": data['customerData'] });
        }
 else {
          return SignInModel.fromJson({ "status": false, "message": data['message'] ?? "Rejected", "customerToken": "", "data": null });
        }
      } else {
        return SignInModel.fromJson({ "status": false, "message": "HTTP Error ${response.statusCode}", "customerToken": "", "data": null });
      }
    } catch (e) {
      return SignInModel.fromJson({ "status": false, "message": "App Error: $e", "customerToken": "", "data": null });
    }
  }


Future<OrderDetail?> getOrderDetail(int id) async {
    try {
      var url = Uri.parse("$baseDomain/mobikul-order-details-api.php");
      String customerId = appStoragePref.getCustomerId().toString();
      String token = appStoragePref.getCustomerToken() ?? "";

      print("🔵 DEBUG: Fetching Order ID: $id");

      var response = await http.post(
        url, 
        headers: {"Content-Type": "application/json"}, 
        body: jsonEncode({
          "customer_id": customerId,
          "order_id": id.toString(),
          "token": token,
          "store_id": "1",
          "currency_code": GlobalData.currencyCode ?? "INR"
        })
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        
        // 1. UNWRAPPER
        var innerData = jsonResponse;
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
             innerData = jsonResponse['data'];
        }

        if (innerData is Map) {
            Map<String, dynamic> safeData = Map<String, dynamic>.from(innerData);

            // 🟢 CRITICAL FIX: Inject the success flag so the Bloc doesn't reject the data
            safeData['success'] = true;
            safeData['responseStatus'] = true;

            // 2. Address Key Fix (Camel vs Snake)
            var rawBilling = safeData['billingAddress'] ?? safeData['billing_address'];
            var rawShipping = safeData['shippingAddress'] ?? safeData['shipping_address'];

            print("🧐 ADDRESS DEBUG - Billing: $rawBilling | Shipping: $rawShipping");

            safeData['billingAddress'] = rawBilling;
            safeData['shippingAddress'] = rawShipping;
            
            // Fix ID
            if (safeData['id'] is String) safeData['id'] = int.tryParse(safeData['id']);

            // Parse Prices
            List<String> priceFields = ['grandTotal', 'grand_total', 'subTotal', 'sub_total'];
            for (var field in priceFields) {
              if (safeData[field] is String) {
                String clean = safeData[field].replaceAll(RegExp(r'[^0-9.]'), '');
                safeData[field] = double.tryParse(clean) ?? 0.0;
              }
            }

            return OrderDetail.fromJson(safeData);
        }
      } 
    } catch (e) {
      print("🔥 API ERROR: $e (Token: ${appStoragePref.getCustomerToken()})");
    }
    return null; 
  }
  // 🟢 4. LOGOUT (Clears Data)
  Future<BaseModel?> customerLogout() async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(
        operationName: 'customerLogout',
        document: gql(mutation.customerLogout()),
        fetchPolicy: FetchPolicy.networkOnly));
    
    // Clear all authentication and profile data
    appStoragePref.setCustomerLoggedIn(false);
    appStoragePref.setCustomerName("");
    appStoragePref.setCustomerEmail("");
    appStoragePref.setCartCount(0);
    
    // 🟢 Clear extended profile details to prevent stale cache after relogin
    appStoragePref.setCustomerFirstName("");
    appStoragePref.setCustomerLastName("");
    appStoragePref.setCustomerPhone("");
    appStoragePref.setCustomerGender("");
    appStoragePref.setCustomerDob("");
    appStoragePref.setCustomerImage("");
    appStoragePref.setCustomerNewsletter(false);
    appStoragePref.setCustomerId(0);
    appStoragePref.setCustomerToken("");
    
    // 🟢 Broadcast profile clear to update UI immediately
    GlobalData.profileUpdateStream.add({
      "image": null,
      "name": ""
    });
        
    return handleResponse(response, 'customerLogout', (json) => BaseModel.fromJson(json));
  }

  // 🟢 5. ADD TO COMPARE (Fixed Missing Method)
  Future<BaseModel?> addToCompare(String? id) async {
    try {
      String customerId = appStoragePref.getCustomerId().toString();
      var url = Uri.parse("$baseDomain/mobikul-compare-api.php");
      var response = await http.post(url, body: {"action": "add", "customer_id": customerId, "product_id": id});
      if (response.statusCode == 200 && response.body.isNotEmpty) {
         var jsonResponse = jsonDecode(response.body);
         if (jsonResponse['success'] == true) {
             return BaseModel.fromJson({"success": true, "status": true, "message": jsonResponse['message'] ?? "Added to compare list", "graphqlErrors": null});
         }
      }
    } catch (e) {}
    var response = await (client.clientToQuery()).mutate(MutationOptions(operationName: 'addToCompare', document: gql(mutation.addToCompare(id: id)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'addToCompare', (json) => BaseModel.fromJson(json));
  }

  // ... [OTHER METHODS] ...

  Future<GetDrawerCategoriesData?> homeCategories({int? id, List<Map<String, dynamic>>? filters}) async {
    List<Map<String, dynamic>>? idFilter = [{"key": "id", "value": "$id"}];
    var response = await (client.clientToQuery()).query(QueryOptions(
        operationName: 'homeCategories',
        document: gql((filters ?? []).isNotEmpty ? mutation.homeCategoriesFilters(filters: filters) : mutation.homeCategoriesFilters(filters: idFilter)),
        fetchPolicy: FetchPolicy.networkOnly
    ));
    return handleResponse(response, 'homeCategories', (json) => GetDrawerCategoriesData.fromJson(json));
  }

  Future<NewProductsModel?> getAllProducts({List<Map<String, dynamic>>? filters, int? page, int limit = 15}) async {
    var response = await (client.clientToQuery()).query(QueryOptions(
      operationName: 'allProducts',
      document: gql(mutation.allProductsList(filters: filters ?? [], page: page ?? 1, limit: limit)), 
      fetchPolicy: FetchPolicy.noCache
    ));
    NewProductsModel? model = await handleResponse(response, 'allProducts', (json) => NewProductsModel.fromJson(json));
    
    // 🟢 FIX: Removed the customizableOptions filter because it was hiding newly added products.
    // We only filter out 'booking' products now.
    if (model != null && (model.data ?? []).isNotEmpty) {
      model.data = model.data?.where((product) => product.type?.toLowerCase() != 'booking').toList();
    }
    return model;
  }

  /// 🟢 NEW: Fetch a single product by urlKey using the dedicated `product()` query.
  /// Falls back to product(id:) then allProducts.
  Future<NewProducts?> getProductDetail(String urlKey, {int? productId, String? name}) async {
    // ── Strategy 1: product(urlKey: "...") ──
    if (urlKey.isNotEmpty) {
      try {
        debugPrint("🔵 Fetching product detail by urlKey: $urlKey");
        var response = await (client.clientToQuery()).query(QueryOptions(
          operationName: 'productDetail',
          document: gql(mutation.getProductByUrlKey(urlKey)),
          fetchPolicy: FetchPolicy.noCache,
        ));

        if (!response.hasException && response.data != null) {
          var raw = response.data!['product'];
          if (raw is Map<String, dynamic>) {
            debugPrint("✅ [S1] productDetail by urlKey: Got '${raw['name']}'");
            try { return NewProducts.fromJson(raw); } catch (e) {
              debugPrint("⚠️ [S1] parse error: $e");
            }
          }
        } else {
          debugPrint("⚠️ [S1] productDetail exception: ${response.exception}");
        }
      } catch (e) {
        debugPrint("⚠️ [S1] productDetail failed: $e");
      }
    }

    // ── Strategy 2: product(id: ...) ──
    if (productId != null && productId > 0) {
      try {
        debugPrint("🔄 [S2] Fetching product by ID: $productId");
        var response = await (client.clientToQuery()).query(QueryOptions(
          operationName: 'productDetailById',
          document: gql(mutation.getProductById(productId)),
          fetchPolicy: FetchPolicy.noCache,
        ));

        if (!response.hasException && response.data != null) {
          var raw = response.data!['product'];
          if (raw is Map<String, dynamic>) {
            debugPrint("✅ [S2] productDetailById: Got '${raw['name']}'");
            try { return NewProducts.fromJson(raw); } catch (e) {
              debugPrint("⚠️ [S2] parse error: $e");
            }
          }
        } else {
          debugPrint("⚠️ [S2] productDetailById exception: ${response.exception}");
        }
      } catch (e) {
        debugPrint("⚠️ [S2] productDetailById failed: $e");
      }
    }

    // ── Strategy 3: allProducts (last resort) ──
    debugPrint("🔄 [S3] Falling back to allProducts");
    List<Map<String, dynamic>> filters = [];
    if (urlKey.isNotEmpty) {
      filters = [{"key": '"url_key"', "value": '"$urlKey"'}];
      NewProductsModel? model = await getAllProducts(filters: filters, limit: 1);
      return model?.data?.firstOrNull;
    } else if (productId != null && productId > 0) {
      // 🟢 FIX: The backend ignores 'id' filters and product() needs admin token.
      // Also, `name` filtering on allProducts can be flaky with special characters.
      // So we fetch a large page of products and find it locally by ID or fuzzy Name match.
      debugPrint("🔄 [S3] Fetching generic allProducts to scan for ID $productId or Name locally");
      NewProductsModel? model = await getAllProducts(limit: 500); // Fetch enough to likely find new ones
      if (model != null && model.data != null) {
        String safeTargetName = (name ?? "").toLowerCase().trim();
        for (var p in model.data!) {
          String pName = (p.name ?? "").toLowerCase().trim();
          bool matchesId = (p.id?.toString() == productId.toString() && productId != null && productId > 0);
          bool matchesName = (safeTargetName.isNotEmpty && pName == safeTargetName);

          if (matchesId || matchesName) {
            debugPrint("✅ [S3] Found product locally (ID: $matchesId, Name: $matchesName)! urlKey: ${p.urlKey}");
            
            // If it has a urlKey now, try to fetch its full details using S1,
            // otherwise just return the abbreviated data we got from allProducts.
            if (p.urlKey != null && p.urlKey!.isNotEmpty) {
              return await getProductDetail(p.urlKey!); 
            }
            return p;
          }
        }
      }
    }
    
    return null;
  }




  Future<ThemeCustomDataModel?> getThemeCustomizationData() async {
    var response = await (client.clientToQuery()).query(QueryOptions(
        operationName: 'themeCustomization',
        document: gql(mutation.themeCustomizationData()),
        fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'themeCustomization', (json) => ThemeCustomDataModel.fromJson(json));
  }

  Future<CmsData?> getCmsPagesData() async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(
      operationName: 'cmsPages',
      document: gql(mutation.getCmsPagesData()),
      fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'cmsPages', (json) => CmsData.fromJson(json));
  }

  Future<CmsPage?> getCmsPageDetails(String id) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(
      operationName: 'cmsPage',
      document: gql(mutation.getCmsPageDetails(id)),
      fetchPolicy: FetchPolicy.networkOnly
    ));
    return handleResponse(response, 'cmsPage', (json) => CmsPage.fromJson(json));
  }

  Future<GetFilterAttribute?> getFilterAttributes(String categorySlug) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(operationName: 'getFilterAttribute', document: gql(mutation.getFilterAttributes(categorySlug)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'getFilterAttribute', (json) => GetFilterAttribute.fromJson(json));
  }

  Future<CurrencyLanguageList?> getLanguageCurrency() async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(
        operationName: 'getDefaultChannel',
        document: gql(mutation.getLanguageCurrencyList()),
        fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'getDefaultChannel', (json) => CurrencyLanguageList.fromJson(json));
  }

  Future<CartModel?> getCartDetails() async {
    var response = await (client.clientToQuery()).query(QueryOptions(
        operationName: 'cartDetail',
        document: gql(mutation.cartDetails()), 
        fetchPolicy: FetchPolicy.noCache
    ));
    return handleResponse(response, 'cartDetail', (json) => CartModel.fromJson(json));
  }

  Future<CartModel?> getCartCount() async {
    var response = await (client.clientToQuery()).query(QueryOptions(
        operationName: 'cartDetail',
        document: gql(mutation.cartDetails()), 
        cacheRereadPolicy: CacheRereadPolicy.mergeOptimistic,
        fetchPolicy: FetchPolicy.networkOnly
    ));
    return handleResponse(response, 'cartDetail', (json) => CartModel.fromJson(json));
  }

  Future<SaveOrderModel?> placeOrder([String? paymentMethod]) async {
    try {
      var url = Uri.parse("$baseDomain/mobikul-place-order.php");
      String realCartId = appStoragePref.getCartId().toString(); 
      String customerId = appStoragePref.getCustomerId().toString();
      String method = paymentMethod ?? "cashondelivery"; 

      var response = await http.post(url, body: {
        "cart_id": realCartId,
        "payment_method": method,
        "customer_id": customerId,
        "checkout_method": appStoragePref.getCustomerLoggedIn() ? "customer" : "guest",
      });

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
             appStoragePref.setCartCount(0); // Clear Cart
             return SaveOrderModel(success: true, order: Order(id: jsonResponse['order_id']));
        } else {
             return SaveOrderModel(success: false, message: jsonResponse['message'] ?? "Failed");
        }
      }
    } catch (e) {}
    return SaveOrderModel(success: false, message: "Network Error");
  }

  Future<SaveCheckoutAddresses?> checkoutSaveAddress(
      String? billingCompanyName, String? billingFirstName, String? billingLastName, String? billingAddress, String? billingEmail, String? billingAddress2, String? billingCountry, String? billingState, String? billingCity, String? billingPostCode, String? billingPhone, String? shippingCompanyName, String? shippingFirstName, String? shippingLastName, String? shippingAddress, String? shippingEmail, String? shippingAddress2, String? shippingCountry, String? shippingState, String? shippingCity, String? shippingPostCode, String? shippingPhone, int id, {int? billingId, int? shippingId, bool useForShipping = true, String? cartId}) async { 
    try {
      var url = Uri.parse("$baseDomain/mobikul-save-checkout-address.php");
      String customerId = appStoragePref.getCustomerId()?.toString() ?? "0";
      String finalCartId = (cartId != null && cartId.isNotEmpty) ? cartId : "121";

      var response = await http.post(url, body: {
        "address_id": id.toString(),
        "customer_id": customerId,
        "cart_id": finalCartId, 
      });

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        var data = jsonResponse['data'] ?? jsonResponse;
        try {
           return SaveCheckoutAddresses.fromJson(data);
        } catch (parsingError) {
           return null;
        }
      }
    } catch (e) {}
    return null;
  }
  
  Future<AddToCartModel?> addToCart(int quantity, String productId, List downloadLinks, List groupedParams, List bundleParams, List configurableParams, String? configurableId) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(
        operationName: 'addItemToCart',
        document: gql(mutation.addToCart(quantity: quantity, productId: productId, downloadableLinks: downloadLinks, groupedParams: groupedParams, bundleParams: bundleParams, configurableParams: configurableParams, configurableId: configurableId)),
        fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'addItemToCart', (json) => AddToCartModel.fromJson(json));
  }

  Future<AddWishListModel?> addToWishlist(String? id) async {
    try {
      String customerId = appStoragePref.getCustomerId().toString();
      var url = Uri.parse("$baseDomain/mobikul-wishlist-api.php");
      var response = await http.post(url, body: {"action": "add", "customer_id": customerId, "product_id": id});
      if (response.statusCode == 200) {
        return AddWishListModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {}
    return AddWishListModel.fromJson({"success": false, "message": "Network Error"});
  }

  Future<AddToCartModel?> removeFromWishlist(String? id) async {
    try {
      String customerId = appStoragePref.getCustomerId().toString();
      var url = Uri.parse("$baseDomain/mobikul-wishlist-api.php");
      var response = await http.post(url, body: {"action": "remove", "customer_id": customerId, "product_id": id});
      if (response.statusCode == 200) {
        return AddToCartModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {}
    return AddToCartModel.fromJson({"success": false, "message": "Network Error"});
  }

  Future<AccountInfoModel?> getCustomerData() async {
    try {
      var response = await (client.clientToQuery()).query(QueryOptions(
        operationName: 'accountInfo',
        document: gql(mutation.getCustomerData()), 
        fetchPolicy: FetchPolicy.networkOnly
      ));
      
      if (!response.hasException) {
        var data = await handleResponse(response, 'accountInfo', (json) => AccountInfoModel.fromJson(json));
        if (data != null && data.name != null) return data;
      } else {
        debugPrint("⚠️ GraphQL getCustomerData had exception, skipping to fallback");
      }
    } catch (e) {
      debugPrint("⚠️ GraphQL getCustomerData failed, using cache: $e");
    }

    // 🟢 FALLBACK: If GraphQL fails (unauthenticated), return data from appStoragePref
    if (appStoragePref.getCustomerLoggedIn()) {
        var model = AccountInfoModel(
          name: appStoragePref.getCustomerName(),
          email: appStoragePref.getCustomerEmail(),
          imageUrl: appStoragePref.getCustomerImage(),
          id: appStoragePref.getCustomerId().toString(),
          firstName: appStoragePref.getCustomerFirstName(),
          lastName: appStoragePref.getCustomerLastName(),
          phone: appStoragePref.getCustomerPhone(),
          gender: appStoragePref.getCustomerGender(),
          dateOfBirth: appStoragePref.getCustomerDob() == "0000-00-00" ? "" : appStoragePref.getCustomerDob(), // 🟢 Sanitize
          subscribedToNewsLetter: appStoragePref.getCustomerNewsletter(),
        );
        debugPrint("📦 RESTORED FROM STORAGE: FName: ${model.firstName}, LName: ${model.lastName}, DOB: ${model.dateOfBirth}");
        return model;
    }
    return null;
  }

  Future<AddToCartModel?> updateItemToCart(List<Map<dynamic, String>> items) async {
    var response = await (client.clientToQuery()).query(QueryOptions(operationName: 'updateItemToCart', document: gql(mutation.updateItemToCart(items: items)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'updateItemToCart', (json) => AddToCartModel.fromJson(json));
  }

  Future<AddToCartModel?> removeItemFromCart(int id) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(operationName: 'removeCartItem', document: gql(mutation.removeFromCart(id)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'removeCartItem', (json) => AddToCartModel.fromJson(json));
  }

  Future<ApplyCoupon?> applyCoupon(String couponCode) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(operationName: 'applyCoupon', document: gql(mutation.applyCoupon(couponCode)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'applyCoupon', (json) => ApplyCoupon.fromJson(json));
  }

  Future<ApplyCoupon?> removeCoupon() async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(operationName: 'removeCoupon', document: gql(mutation.removeCoupon()), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'removeCoupon', (json) => ApplyCoupon.fromJson(json));
  }

  Future<AddToCartModel?> moveCartToWishlist(dynamic idParam) async {
    try {
      String cartItemId = "";
      String productId = "";
      if (idParam.toString().contains(":")) {
        var parts = idParam.toString().split(":");
        cartItemId = parts[0];
        productId = parts[1];
      } else {
        return AddToCartModel.fromJson({"success": false, "message": "Internal Error: Missing ID"});
      }
      var wishListResponse = await addToWishlist(productId);
      if (wishListResponse?.success == true || wishListResponse?.status == true) {
         return await removeItemFromCart(int.parse(cartItemId)); 
      } else {
         return AddToCartModel.fromJson({"success": false, "message": wishListResponse?.message ?? "Failed to add to wishlist"});
      }
    } catch (e) {
      return AddToCartModel.fromJson({"success": false, "message": "App Error: $e"});
    }
  }

  Future<BaseModel?> removeAllCartItem() async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(operationName: 'removeAllCartItem', document: gql(mutation.removeAllCartItem()), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'removeAllCartItem', (json) => BaseModel.fromJson(json));
  }

  Future<WishListData?> getWishList() async {
    try {
      String customerId = appStoragePref.getCustomerId().toString();
      debugPrint("🚀 FETCHING WISHLIST (PHP) - Customer: $customerId");
      var url = Uri.parse("$baseDomain/mobikul-wishlist-api.php?action=get&customer_id=$customerId");
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        String rawResponse = jsonResponse.toString();
        debugPrint("🔍 WISHLIST RAW RESPONSE: ${rawResponse.length > 200 ? rawResponse.substring(0, 200) : rawResponse}...");
        
        if (jsonResponse['success'] == true) {
             // 🟢 ROBUST FIX: Handle nested data structure {data: {data: [...]}}
             List<dynamic> items = [];
             
             var dataField = jsonResponse['data'];
             
             // Check if data is nested (has a 'data' property inside)
             if (dataField is Map && dataField.containsKey('data')) {
                debugPrint("🔍 Detected nested data structure");
                dataField = dataField['data']; // Extract inner data
             }
             
             // Now handle the actual items
             if (dataField is List) {
                items = dataField;
             } else if (dataField is Map) {
                // Single item as a map, wrap it in a list
                items = [dataField];
             }
             
             debugPrint("🔍 WISHLIST ITEMS COUNT: ${items.length}");
             
             // Ensure images are found
             for(var item in items) {
                var p = item['product'];
                if (p != null) {
                   debugPrint("🔍 Product keys: ${p.keys.toList()}");
                   
                   // 🟢 Discover best possible image URL
                   String? bestUrl = p['imageUrl'] ?? p['base_image_url'] ?? p['small_image_url'] ?? p['base_image'];
                   
                   // Check nested baseImage
                   if ((bestUrl == null || bestUrl.isEmpty) && p['baseImage'] != null) {
                      bestUrl = p['baseImage']['url'];
                   }
                   
                   debugPrint("🔍 Best URL found: $bestUrl");

                   // 🟢 Inject into 'images' array if 'images' is missing, empty, or contains only directory paths
                   bool needsInjection = false;
                   var existingImages = p['images'];
                   
                   if (existingImages == null || (existingImages is List && existingImages.isEmpty)) {
                      needsInjection = true;
                   } else if (existingImages is List) {
                      // Check if all existing images are just directory paths/invalid
                      bool allInvalid = true;
                      for (var img in existingImages) {
                         String? u = img is Map ? img['url'] : img.toString();
                         if (u != null && u.isNotEmpty && !u.endsWith("/storage/product/")) {
                            allInvalid = false;
                            break;
                         }
                      }
                      if (allInvalid) needsInjection = true;
                   }

                   if (bestUrl != null && bestUrl.isNotEmpty && needsInjection) {
                      p['images'] = [{"url": bestUrl}];
                      debugPrint("💚 Injected image URL for wishlist item: $bestUrl");
                   }
                }
             }
             
             // Wrap data array in proper structure for model
             var wishListModel = WishListData.fromJson({'data': items});
             wishListModel.status = true;
             wishListModel.success = true;
             return wishListModel;
        }
      }
    } catch (e, stackTrace) { 
      debugPrint("❌ FETCH WISHLIST ERROR: $e"); 
      debugPrint("Stack: $stackTrace");
    }
    return WishListData(data: []);
  }

  Future<AddToCartModel?> moveFromWishlistToCart(dynamic idParam, String quantity) async {
    try {
      String wishlistId = "";
      String productId = "";
      if (idParam.toString().contains(":")) {
        var parts = idParam.toString().split(":");
        wishlistId = parts[0];
        productId = parts[1];
      } else {
        wishlistId = idParam.toString(); 
        return AddToCartModel.fromJson({"success": false, "message": "Internal Error: Missing Product ID"});
      }
      var cartResponse = await addToCart(int.tryParse(quantity) ?? 1, productId, [], [], [], [], null);
      if (cartResponse?.status == true || cartResponse?.success == true) {
        await removeFromWishlist(wishlistId);
        return cartResponse;
      } else {
        return AddToCartModel.fromJson({"success": false, "message": cartResponse?.graphqlErrors ?? "Failed to add to cart"});
      }
    } catch (e) {
      return AddToCartModel.fromJson({"success": false, "message": "App Error: $e"});
    }
  }

  Future<BaseModel?> removeAllWishlistProducts() async {
    try {
      WishListData? currentList = await getWishList();
      if (currentList?.data == null || currentList!.data!.isEmpty) return BaseModel(success: true, message: "Wishlist already empty");
      List<dynamic> items = currentList.data!;
      for (var item in items) {
         String productId = item.product?.id ?? ""; 
         if (productId.isNotEmpty && productId != "0") {
            await removeFromWishlist(productId);
         }
      }
      return BaseModel(success: true, message: "Wishlist Cleared Successfully");
    } catch (e) {
      return BaseModel(success: false, message: "App Error: $e");
    }
  }

  Future<SignInModel?> socialLogin(String email, String firstName, String lastName, String phone, String signUpType) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(operationName: 'customerSocialSignUp', document: gql(mutation.getSocialLoginResponse(firstName: firstName, lastName: lastName, email: email, phone: phone, signUpType: signUpType)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'customerSocialSignUp', (json) => SignInModel.fromJson(json));
  }

  Future<SignInModel?> getSignInData(String email, String password, bool remember) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(operationName: 'customerLogin', document: gql(mutation.customerLogin(email: email, password: password, remember: remember))));
    return handleResponse(response, 'customerLogin', (json) => SignInModel.fromJson(json));
  }

  Future<SignInModel?> getSignUpData(String email, String firstName, String lastName, String password, String confirmPassword, bool subscribeNewsletter, bool agreement) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(operationName: 'customerSignUp', document: gql(mutation.customerRegister(firstName: firstName, lastName: lastName, email: email, password: password, confirmPassword: confirmPassword, subscribedToNewsLetter: subscribeNewsletter, agreement: agreement)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'customerSignUp', (json) => SignInModel.fromJson(json));
  }

  Future<AccountUpdate?> updateCustomerData(
      String? firstName,
      String? lastName,
      String? email,
      String? gender,
      String? dateOfBirth,
      String? phone,
      String? avatar,
      bool? subscribedToNewsLetter) async {
    
    // 🟢 1. FORMAT DATE: Ensure yyyy-MM-dd
    String finalDob = dateOfBirth ?? "";
    if (finalDob.contains("-") && finalDob.split("-").first.length == 2) {
      try {
        var parts = finalDob.split("-");
        if (parts.length == 3) {
          finalDob = "${parts[2]}-${parts[1]}-${parts[0]}";
        }
      } catch (e) {
        debugPrint("Date Parsing Error: $e");
      }
    }

    // 🟢 2. ENCODE IMAGE: Convert path to Base64 if needed
    String finalAvatar = avatar ?? "";
    if (finalAvatar.isNotEmpty && !finalAvatar.startsWith("http") && !finalAvatar.contains("base64")) {
      try {
        final bytes = File(finalAvatar).readAsBytesSync();
        finalAvatar = "data:image/png;base64,${base64Encode(bytes)}";
        print("📸 API: Encoded image to Base64 (Length: ${finalAvatar.length})");
      } catch (e) {
        print("⚠️ Image Encoding Error: $e");
      }
    }

    // 🟢 3. EXECUTE GRAPHQL MUTATION (Uniform with Login)
    String token = appStoragePref.getCustomerToken();
    print("🚀 SAVING PROFILE (AccountUpdate) - Token: ${token.isNotEmpty ? "PRESENT" : "MISSING"}");

    var response = await (client.clientToQuery()).mutate(MutationOptions(
        operationName: 'updateAccount',
        document: gql(mutation.updateAccount(
          firstName: firstName,
          lastName: lastName,
          email: email,
          gender: gender,
          dateOfBirth: finalDob,
          phone: phone,
          avatar: finalAvatar,
          subscribedToNewsLetter: subscribedToNewsLetter,
          oldPassword: "", 
          password: "",
          confirmPassword: ""
        ))));

    var model = await handleResponse(response, 'updateAccount', (json) => AccountUpdate.fromJson(json));

    // 🟢 AGGRESSIVE FALLBACK: If GraphQL fails for ANY reason (schema error, auth error, etc.), try the PHP Bridge
    if (model == null || (model.graphqlErrors != null && model.graphqlErrors!.isNotEmpty)) {
      print("⚠️ GraphQL Profile Update FAILED (Error: ${model?.graphqlErrors ?? 'null model'}). Trying PHP Fallback...");
      try {
        String customerId = appStoragePref.getCustomerId().toString();
        String token = appStoragePref.getCustomerToken() ?? "";
        var url = Uri.parse("$baseDomain/mobikul-profile-api.php");
        
        var phpBody = {
          "action": "update", 
          "customer_id": customerId,
          "token": token,
          "first_name": firstName ?? "",
          "last_name": lastName ?? "",
          "email": email ?? "",
          "gender": gender ?? "",
          "date_of_birth": finalDob,
          "phone": phone ?? "",
          "avatar": finalAvatar, 
          "subscribed_to_newsletter": subscribedToNewsLetter.toString()
        };

        var phpResponse = await http.post(url, body: phpBody);
        print("📥 PHP FALLBACK RESPONSE: ${phpResponse.statusCode} - ${phpResponse.body}");
        
        if (phpResponse.statusCode == 200) {
          var data = jsonDecode(phpResponse.body);
          if (data['success'] == true || data['success'] == "true") {
             print("✅ PHP Fallback Succeeded!");
             return AccountUpdate.fromJson({
               "success": true, 
               "message": data['message'] ?? "Updated via fallback",
               "customer": data['data'] ?? {}
             });
          }
        }
      } catch (e) {
        print("❌ PHP Fallback Failed: $e");
      }
    }

    return model;
  }

  Future<BaseModel?> deleteCustomerAccount(String password) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(operationName: 'deleteAccount', document: gql(mutation.deleteAccount(password: password)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'deleteAccount', (json) => BaseModel.fromJson(json));
  }

  Future<BaseModel?> forgotPassword(String email) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(operationName: 'forgotPassword', document: gql(mutation.forgotPassword(email: email))));
    return handleResponse(response, 'forgotPassword', (json) => BaseModel.fromJson(json));
  }

  Future<ReviewModel?> getReviewList(int page) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(operationName: 'reviewsList', document: gql(mutation.getReviewList(page)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'reviewsList', (json) => ReviewModel.fromJson(json));
  }

  // 🟢 REPLACED: Use Custom PHP API to bypass broken Server Resource
  Future<OrdersListModel?> getOrderList(String? id, String? startDate, String? endDate, String? status, double? total, int? page, bool? isFilterApply) async {
    try {
      var url = Uri.parse("$baseDomain/mobikul-orders-api.php");
      String customerId = appStoragePref.getCustomerId().toString();
      debugPrint("🚀 FETCHING ORDERS (PHP) - Customer: $customerId, Page: $page, Status: $status");
      
      Map<String, String> bodyParams = {
        "customer_id": customerId,
        "page": page.toString()
      };

      if (status != null && status.isNotEmpty) bodyParams["status"] = status;
      if (id != null && id.isNotEmpty) bodyParams["order_id"] = id;
      if (startDate != null && startDate.isNotEmpty) bodyParams["from_date"] = startDate;
      if (endDate != null && endDate.isNotEmpty) bodyParams["to_date"] = endDate;
      if (total != null && total > 0) bodyParams["total"] = total.toString();

      var response = await http.post(url, body: bodyParams);
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          // Wrapped data handling to match model expectation
          var rawData = jsonResponse['data'];
          Map<String, dynamic> wrappedData = (rawData is Map<String, dynamic>) ? rawData : {'data': rawData};
          return OrdersListModel.fromJson(wrappedData);
        }
      }
    } catch (e) {
      debugPrint("❌ FETCH ORDER ERROR: $e");
    }
    return OrdersListModel(data: []);
  }

  Future<BaseModel?> cancelOrder(int orderId) async {
    try {
      var url = Uri.parse("$baseDomain/mobikul-order-cancel-api.php");
      String customerId = appStoragePref.getCustomerId().toString();
      
      debugPrint("🔵 PHP CANCEL: Order $orderId for Customer $customerId");

      var response = await http.post(
        url, 
        body: jsonEncode({
          "order_id": orderId.toString(),
          "customer_id": customerId
        }),
        headers: {"Content-Type": "application/json"}
      );
      
      debugPrint("🔵 RAW RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        try {
          var data = jsonDecode(response.body);
          return BaseModel(
            success: data['success'] == true, 
            message: data['message'] ?? "Unknown Server Error"
          );
        } catch (e) {
          return BaseModel(success: false, message: "Invalid JSON from server");
        }
      } else {
        return BaseModel(success: false, message: "HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Cancel Error: $e");
      return BaseModel(success: false, message: "App Error: $e");
    }
  }

  Future<AddressModel?> getAddressData() async {
    try {
      String customerId = appStoragePref.getCustomerId().toString();
      // 🟢 FIX: Add timestamp to prevent caching
      String antiCache = DateTime.now().millisecondsSinceEpoch.toString();
      var url = Uri.parse("$baseDomain/mobikul-get-addresses.php?customer_id=$customerId&t=$antiCache");
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          List<dynamic> list = jsonResponse['data'];
          List<AddressData> addressDataList = list.map((item) => AddressData.fromJson(item)).toList();
          AddressModel model = AddressModel(addressData: addressDataList);
          model.success = true; 
          model.message = "Fetched successfully";
          return model;
        }
      }
    } catch (e) {}
    AddressModel errorModel = AddressModel(addressData: []);
    errorModel.success = false;
    errorModel.message = "Failed to load";
    return errorModel;
  }

  Future<BaseModel?> deleteAddress(String? id) async {
    // 🟢 CUSTOM BACKEND DELETE
    // Uses mobikul-delete-address.php (Raw PHP/PDO) checks 'addresses' table
    try {
      String customerId = appStoragePref.getCustomerId().toString(); 
      String token = appStoragePref.getCustomerToken() ?? "";

      var url = Uri.parse("$baseDomain/mobikul-delete-address.php");
      debugPrint("🚀 PHP CUSTOM DELETE: $url (ID: $id, Cust: $customerId)");

      var response = await http.post(url, body: { 
        "id": id, 
        "address_id": id, // Backup key
        "customer_id": customerId,
        "token": token // Sent for completeness
      });
      
      debugPrint("🚀 PHP RESPONSE: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        // Robust success check matching the PHP script
        if (data['success'] == true || data['success'] == "true") {
           return BaseModel(success: true, message: data['message'] ?? "Deleted Successfully");
        }
      }
    } catch (e) {
      debugPrint("❌ PHP FAIL: $e");
    }
    
    return BaseModel(success: false, message: "Could not delete address");
  }

  Future<BaseModel?> createAddress(String companyName, String firstName, String lastName, String address, String address2, String country, String state, String city, String postCode, String phone, String vatId, bool? isDefault, String email) async {
    try {
      String customerId = appStoragePref.getCustomerId().toString(); 
      String token = appStoragePref.getCustomerToken() ?? ""; // 🟢 FIX: Add Token
      
      var url = Uri.parse("$baseDomain/mobikul-save-address.php");
      var response = await http.post(url, body: { 
        "customer_id": customerId, 
        "token": token, // 🟢 Added Token to fix "Unauthenticated"
        "company_name": companyName, 
        "first_name": firstName, 
        "last_name": lastName, 
        "address1": address, 
        "address2": address2, 
        "country": country, 
        "state": state, 
        "city": city, 
        "postcode": postCode, 
        "phone": phone, 
        "vat_id": vatId, 
        "default_address": isDefault.toString(), 
        "email": email 
      });
      
      var data = jsonDecode(response.body);
      return BaseModel(success: data['success'] == true, message: data['message'] ?? "Unknown Error");
    } catch (e) {
      return BaseModel(success: false, message: "App Error: $e");
    }
  }

  Future<UpdateAddressModel?> updateAddress(int id, String companyName, String firstName, String lastName, String address, String address2, String country, String state, String city, String postCode, String phone, String vatId, String email) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(operationName: 'updateAddress', document: gql(mutation.updateAddress(id: id, companyName: companyName, firstName: firstName, lastName: lastName, address: address, address2: address2, country: country, state: state, city: city, email: email, postCode: postCode, phone: phone, vatId: vatId)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'updateAddress', (json) => UpdateAddressModel.fromJson(json));
  }

  Future<CountriesData?> getCountryStateList() async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(operationName: 'countries', document: gql(mutation.getCountryStateList()), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'countries', (json) => CountriesData.fromJson(json));
  }

  Future<PaymentMethods?> saveShippingMethods(String? shippingMethod) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(operationName: 'paymentMethods', document: gql(mutation.paymentMethods(shippingMethod: shippingMethod)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'paymentMethods', (json) => PaymentMethods.fromJson(json));
  }

  Future<SavePayment?> saveAndReview(String? paymentMethod) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(operationName: 'savePayment', document: gql(mutation.savePaymentAndReview(paymentMethod: paymentMethod)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'savePayment', (json) => SavePayment.fromJson(json));
  }

  Future<CompareProductsData?> getCompareProducts() async {
    try {
      String customerId = appStoragePref.getCustomerId().toString();
      var url = Uri.parse("$baseDomain/mobikul-compare-api.php");
      var response = await http.post(url, body: { "action": "get", "customer_id": customerId });
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
             return CompareProductsData.fromJson({ "data": jsonResponse['data'], "paginatorInfo": { "count": jsonResponse['data'].length, "total": jsonResponse['data'].length } });
        }
      }
    } catch (e) {}
    return CompareProductsData(data: []);
  }

  Future<BaseModel?> removeFromCompare(int id) async {
    try {
      String customerId = appStoragePref.getCustomerId().toString();
      var url = Uri.parse("$baseDomain/mobikul-compare-api.php");
      var response = await http.post(url, body: { "action": "remove", "customer_id": customerId, "product_id": id.toString() });
      if (response.statusCode == 200) {
         var jsonResponse = jsonDecode(response.body);
         return BaseModel(success: true, message: jsonResponse['message']);
      }
    } catch (e) {}
    return BaseModel(success: false, message: "Network Error");
  }
  
  Future<BaseModel?> removeAllCompareProducts() async {
    try {
      String customerId = appStoragePref.getCustomerId().toString();
      var url = Uri.parse("$baseDomain/mobikul-compare-api.php");
      var response = await http.post(url, body: { "action": "remove_all", "customer_id": customerId });
      if (response.statusCode == 200) { return BaseModel(success: true, message: "Cleared"); }
    } catch (e) {}
    return BaseModel(success: false, message: "Network Error");
  }

  Future<AddReviewModel?> addReview(String name, String title, int rating, String comment, int productId, List<Map<String, String>> attachments) async {
    // 🟢 CUSTOM PHP API: Bypass GraphQL for Review due to Auth issues
    try {
      String customerId = appStoragePref.getCustomerId().toString(); 
      String token = appStoragePref.getCustomerToken() ?? "";

      var url = Uri.parse("$baseDomain/mobikul-review-api.php");
      debugPrint("🚀 SUBMITTING REVIEW (PHP): $url (Cust: $customerId, Prod: $productId)");

      var body = {
        "customer_id": customerId,
        "token": token,
        "product_id": productId.toString(),
        "name": name,
        "title": title,
        "rating": rating.toString(),
        "comment": comment,
        "attachments": jsonEncode(attachments)
      };

      var response = await http.post(url, body: body);
      debugPrint("🚀 REVIEW RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
            return AddReviewModel(
              success: true, 
              message: jsonResponse['message'] ?? "Review Submitted Successfully",
            );
        } else {
             return AddReviewModel(
              success: false, 
              message: jsonResponse['message'] ?? "Failed to submit review",
            );
        }
      } else {
        return AddReviewModel(success: false, message: "Server Error: ${response.statusCode} - ${response.reasonPhrase}");
      }
    } catch (e) {
      debugPrint("❌ REVIEW ERROR: $e");
      return AddReviewModel(success: false, message: "App Error: $e");
    }
  }

  Future<DownloadableProductModel?> getCustomerDownloadableProducts(int page, int limit, {String? title, String? status, String? orderId, String? orderDateFrom, String? orderDateTo}) async {
    var response = await (client.clientToQuery()).query(QueryOptions(operationName: 'downloadableLinkPurchases', document: gql(mutation.downloadableProductsCustomer(page, limit, title: title ?? "", status: status ?? "", orderId: orderId ?? "", orderDateFrom: orderDateFrom ?? "", orderDateTo: orderDateTo ?? "")), cacheRereadPolicy: CacheRereadPolicy.mergeOptimistic, fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'downloadableLinkPurchases', (json) => DownloadableProductModel.fromJson(json));
  }

  Future<DownloadLinkDataModel?> downloadLinksProductAPI(int id) async {
    var response = await (client.clientToQuery()).query(QueryOptions(operationName: 'downloadLink', document: gql(mutation.downloadProductQuery(id)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'downloadLink', (json) => DownloadLinkDataModel.fromJson(json));
  }

  Future<Download?> downloadLinksProduct(int id) async {
    var response = await (client.clientToQuery()).query(QueryOptions(operationName: 'downloadableLinkPurchase', document: gql(mutation.downloadProduct(id)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'downloadableLinkPurchase', (json) => Download.fromJson(json));
  }

  Future<InvoicesModel?> getInvoicesList(int orderId) async {
    var response = await (client.clientToQuery()).query(QueryOptions(operationName: 'viewInvoices', document: gql(mutation.getInvoicesList(orderId)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'viewInvoices', (json) => InvoicesModel.fromJson(json));
  }

  Future<ShipmentModel?> getShipmentsList(int orderId) async {
    var response = await (client.clientToQuery()).query(QueryOptions(operationName: 'viewShipments', document: gql(mutation.getShipmentsList(orderId)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'viewShipments', (json) => ShipmentModel.fromJson(json));
  }

  Future<OrderRefundModel?> getRefundList(int orderId) async {
    var response = await (client.clientToQuery()).query(QueryOptions(operationName: 'viewRefunds', document: gql(mutation.getRefundList(orderId)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'viewRefunds', (json) => OrderRefundModel.fromJson(json));
  }

  Future<AddToCartModel?> reOrderCustomerOrder(String? orderId) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(operationName: 'reorder', document: gql(mutation.reOrderCustomerOrder(orderId)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'reorder', (json) => AddToCartModel.fromJson(json));
  }

  Future<BaseModel?> contactUsApiClient(String name, String? email, String? phone, String? describe) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(operationName: 'contactUs', document: gql(mutation.contactUsApi(name: name, email: email, phone: phone, describe: describe)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'contactUs', (json) => BaseModel.fromJson(json));
  }

  Future<SetDefaultAddress?> setDefaultAddress(String id) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(operationName: 'setDefaultAddress', document: gql(mutation.setDefaultAddress(id)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'setDefaultAddress', (json) => SetDefaultAddress.fromJson(json));
  }

  Future<DownloadSampleModel?> downloadSample(String type, String id) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(operationName: 'downloadSample', document: gql(mutation.downloadSample(type, id)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'downloadSample', (json) => DownloadSampleModel.fromJson(json));
  }
  // 🟢 NEW: Robust Profile Synchronization after Login
  Future<void> _syncProfileAfterLogin() async {
    try {
      debugPrint("🔄 Syncing profile after login...");

      // 🟢 NEW: Try direct PHP API first (more reliable than GraphQL for these custom fields)
      try {
        String customerId = appStoragePref.getCustomerId().toString();
        String token = appStoragePref.getCustomerToken() ?? "";
        // 🟢 ADDED CACHE BUSTER: Ensure we don't get a cached server response
        String t = DateTime.now().millisecondsSinceEpoch.toString();
        var url = Uri.parse("$baseDomain/mobikul-profile-api.php?action=get&customer_id=$customerId&token=$token&t=$t");
        var response = await http.get(url);
        
        debugPrint("🔍 SYNC PROFILE ATTEMPT (PHP API) - Code: ${response.statusCode}, URL: $url");
        
        if (response.statusCode == 200) {
          var jsonResponse = jsonDecode(response.body);
          debugPrint("🔍 DIRECT PHP PROFILE RESPONSE: $jsonResponse");
          
          if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
            var profileData = jsonResponse['data'];
            
            // Update storage with fresh data from server
            if (profileData['firstName'] != null) {
              appStoragePref.setCustomerFirstName(profileData['firstName']);
            }
            if (profileData['lastName'] != null) {
              appStoragePref.setCustomerLastName(profileData['lastName']);
            }
            if (profileData['email'] != null) {
              appStoragePref.setCustomerEmail(profileData['email']);
            }
            if (profileData['phone'] != null) {
              appStoragePref.setCustomerPhone(profileData['phone']);
            }
            if (profileData['gender'] != null) {
              appStoragePref.setCustomerGender(profileData['gender']);
            }
            if (profileData['date_of_birth'] != null && profileData['date_of_birth'] != "0000-00-00") {
              appStoragePref.setCustomerDob(profileData['date_of_birth']);
            }
            
            String fullName = profileData['name'] ?? "";
            if (fullName.isEmpty) {
              fullName = "${profileData['firstName'] ?? ''} ${profileData['lastName'] ?? ''}".trim();
            }
            if (fullName.isNotEmpty) {
              appStoragePref.setCustomerName(fullName);
            }

            // 🟢 ENSURE IMAGE IS SAVED
            String img = profileData['imageUrl'] ?? "";
            if (img.isNotEmpty) {
              appStoragePref.setCustomerImage(img);
            }
            
            debugPrint("✅ Profile synced from PHP API: $fullName");
            
            // 🟢 SYNC FULL MODEL: Helper for Drawer/Header listeners
            // DrawerListView listens to 'customerDetails' key. We must construct and save it.
            AccountInfoModel updatedModel = AccountInfoModel(
              firstName: profileData['first_name'] ?? "",
              lastName: profileData['last_name'] ?? "",
              name: fullName,
              email: profileData['email'] ?? "",
              phone: profileData['phone'] ?? "",
              dateOfBirth: profileData['date_of_birth'] ?? "",
              gender: profileData['gender'] ?? "",
              imageUrl: img.isNotEmpty ? img : appStoragePref.getCustomerImage(),
              id: appStoragePref.getCustomerId().toString()
            );
            appStoragePref.setCustomerDetails(updatedModel);

            // Broadcast updates for UI
          GlobalData.profileUpdateStream.add({
            "image": img,
            "name": fullName,
            "email": profileData['email'] ?? ""
          });
            
            return; // Success, exit early and skip GraphQL sync
          }
        }
      } catch (e) {
        debugPrint("⚠️ PHP API profile fetch failed: $e");
      }

      var data = await getCustomerData();
      if (data != null) {
        debugPrint("🔍 SYNC PROFILE RESPONSE (GraphQL): Name=${data.name}, FirstName=${data.firstName}, LastName=${data.lastName}");
        
        if (data.id != null && data.id!.isNotEmpty && (data.name == null || data.name!.isEmpty)) {
            debugPrint("💡 Note: Using cached/fallback profile data");
        }
        debugPrint("✅ Profile synced: ${data.name}");
        if (data.name != null && data.name!.isNotEmpty) {
           appStoragePref.setCustomerName(data.name!);
        }
        if (data.email != null && data.email!.isNotEmpty) {
           appStoragePref.setCustomerEmail(data.email!);
        }
        if (data.imageUrl != null && data.imageUrl!.isNotEmpty) {
           appStoragePref.setCustomerImage(data.imageUrl!);
        }

        // 🟢 SYNC EXTENDED DETAILS (If GraphQL succeeds)
        if (data.firstName != null) appStoragePref.setCustomerFirstName(data.firstName!);
        if (data.lastName != null) appStoragePref.setCustomerLastName(data.lastName!);
        if (data.phone != null) appStoragePref.setCustomerPhone(data.phone!);
        if (data.gender != null) appStoragePref.setCustomerGender(data.gender!);
        if (data.dateOfBirth != null) {
          String dob = data.dateOfBirth!;
          if (dob == "0000-00-00") dob = ""; // 🟢 Sanitize placeholder
          appStoragePref.setCustomerDob(dob);
        }
        if (data.subscribedToNewsLetter != null) appStoragePref.setCustomerNewsletter(data.subscribedToNewsLetter!);
        
        // 🟢 SYNC FULL MODEL: Helper for Drawer/Header listeners
        AccountInfoModel updatedModel = AccountInfoModel(
          firstName: data.firstName ?? "",
          lastName: data.lastName ?? "",
          name: data.name ?? "",
          email: data.email ?? "",
          phone: data.phone ?? "",
          dateOfBirth: data.dateOfBirth ?? "",
          gender: data.gender ?? "",
          imageUrl: data.imageUrl ?? appStoragePref.getCustomerImage(),
          id: data.id ?? appStoragePref.getCustomerId().toString()
        );
        appStoragePref.setCustomerDetails(updatedModel);

        // Broadcast updates for UI
        GlobalData.profileUpdateStream.add({
          "image": data.imageUrl,
          "name": data.name
        });
      }
    } catch (e) {
      debugPrint("❌ Profile sync failed: $e");
    }
  }
}
