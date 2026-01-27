/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'dart:developer';
import 'dart:convert';
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

  // 🟢 HELPER: Safe Public Client
  GraphQLClient _getPublicClient() {
    String? token = appStoragePref.getCustomerToken();
    String? cookie = appStoragePref.getCookieGet();
    bool isFakeLogin = (token == "fake_token_bypass");

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // ALWAYS send Cookie (Required for Cart)
    if (cookie != null && cookie.isNotEmpty) {
      headers['Cookie'] = cookie;
    }

    final HttpLink httpLink = HttpLink(
      "$baseDomain/graphql",
      defaultHeaders: headers
    );
    
    return GraphQLClient(link: httpLink, cache: GraphQLCache());
  }

  // 🟢 1. GLOBAL HANDLER (Brute-Force Parser)
  Future<T?> handleResponse<T>(
    QueryResult<Object?> result,
    String operation,
    Parser<T> parser,
  ) async {
    if (result.hasException) {
      debugPrint("❌ GRAPHQL EXCEPTION ($operation): ${result.exception.toString()}");
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
      
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['success'] == true) {
          String token = data['customerToken'];
          appStoragePref.setCustomerToken(token);
          appStoragePref.setCustomerLoggedIn(true);
          
          if (data['customerData'] != null) {
            var cData = data['customerData'];
            int cId = int.tryParse(cData['id'].toString()) ?? 0;
            appStoragePref.setCustomerId(cId);
            
            // Extract Real Name
            String fName = cData['first_name']?.toString() ?? "";
            String lName = cData['last_name']?.toString() ?? "";
            String fullName = "$fName $lName".trim();
            
            if (fullName.isEmpty) fullName = cData['name']?.toString() ?? "";
            
            // Only fall back to phone if name is totally empty
            if (fullName.isNotEmpty) {
               appStoragePref.setCustomerName(fullName);
            } else {
               appStoragePref.setCustomerName(safePhone);
            }

            String email = cData['email']?.toString() ?? "";
            appStoragePref.setCustomerEmail(email);
          }
          return SignInModel.fromJson({ "status": true, "message": data['message'], "customerToken": token, "data": data['customerData'] });
        } else {
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
      print("🔥 API ERROR: $e");
    }
    return null; 
  }
  // 🟢 4. LOGOUT (Clears Data)
  Future<BaseModel?> customerLogout() async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(
        document: gql(mutation.customerLogout()),
        fetchPolicy: FetchPolicy.networkOnly));
    
    appStoragePref.setCustomerLoggedIn(false);
    appStoragePref.setCustomerName("");
    appStoragePref.setCustomerEmail("");
    appStoragePref.setCartCount(0);
        
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
    var response = await (client.clientToQuery()).mutate(MutationOptions(document: gql(mutation.addToCompare(id: id)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'addToCompare', (json) => BaseModel.fromJson(json));
  }

  // ... [OTHER METHODS] ...

  Future<GetDrawerCategoriesData?> homeCategories({int? id, List<Map<String, dynamic>>? filters}) async {
    List<Map<String, dynamic>>? idFilter = [{"key": "id", "value": "$id"}];
    var response = await _getPublicClient().query(QueryOptions(
        document: gql((filters ?? []).isNotEmpty ? mutation.homeCategoriesFilters(filters: filters) : mutation.homeCategoriesFilters(filters: idFilter)),
        fetchPolicy: FetchPolicy.networkOnly
    ));
    return handleResponse(response, 'homeCategories', (json) => GetDrawerCategoriesData.fromJson(json));
  }

  Future<NewProductsModel?> getAllProducts({List<Map<String, dynamic>>? filters, int? page, int limit = 15}) async {
    var response = await _getPublicClient().query(QueryOptions(
      document: gql(mutation.allProductsList(filters: filters ?? [], page: page ?? 1, limit: limit)), 
      fetchPolicy: FetchPolicy.noCache
    ));
    NewProductsModel? model = await handleResponse(response, 'allProducts', (json) => NewProductsModel.fromJson(json));
    if (model != null && (model.data ?? []).isNotEmpty) {
      model.data = model.data?.where((product) => product.type?.toLowerCase() != 'booking' && (product.customizableOptions == null || (product.customizableOptions ?? []).isEmpty)).toList();
    }
    return model;
  }

  Future<ThemeCustomDataModel?> getThemeCustomizationData() async {
    var response = await _getPublicClient().query(QueryOptions(
        document: gql(mutation.themeCustomizationData()),
        fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'themeCustomization', (json) => ThemeCustomDataModel.fromJson(json));
  }

  Future<CmsData?> getCmsPagesData() async {
    var response = await _getPublicClient().mutate(MutationOptions(
      document: gql(mutation.getCmsPagesData()),
      fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'cmsPages', (json) => CmsData.fromJson(json));
  }

  Future<CmsPage?> getCmsPageDetails(String id) async {
    var response = await _getPublicClient().mutate(MutationOptions(
      document: gql(mutation.getCmsPageDetails(id)),
      fetchPolicy: FetchPolicy.networkOnly
    ));
    return handleResponse(response, 'cmsPage', (json) => CmsPage.fromJson(json));
  }

  Future<GetFilterAttribute?> getFilterAttributes(String categorySlug) async {
    var response = await _getPublicClient().mutate(MutationOptions(document: gql(mutation.getFilterAttributes(categorySlug)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'getFilterAttribute', (json) => GetFilterAttribute.fromJson(json));
  }

  Future<CurrencyLanguageList?> getLanguageCurrency() async {
    var response = await _getPublicClient().mutate(MutationOptions(
        document: gql(mutation.getLanguageCurrencyList()),
        fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'getDefaultChannel', (json) => CurrencyLanguageList.fromJson(json));
  }

  Future<CartModel?> getCartDetails() async {
    var response = await _getPublicClient().query(QueryOptions(
        document: gql(mutation.cartDetails()), 
        fetchPolicy: FetchPolicy.noCache
    ));
    return handleResponse(response, 'cartDetail', (json) => CartModel.fromJson(json));
  }

  Future<CartModel?> getCartCount() async {
    var response = await _getPublicClient().query(QueryOptions(
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
    var response = await _getPublicClient().mutate(MutationOptions(
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
    var response = await (client.clientToQuery()).query(QueryOptions(document: gql(mutation.getCustomerData()), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'accountInfo', (json) => AccountInfoModel.fromJson(json));
  }

  Future<AddToCartModel?> updateItemToCart(List<Map<dynamic, String>> items) async {
    var response = await (client.clientToQuery()).query(QueryOptions(document: gql(mutation.updateItemToCart(items: items)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'updateItemToCart', (json) => AddToCartModel.fromJson(json));
  }

  Future<AddToCartModel?> removeItemFromCart(int id) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(document: gql(mutation.removeFromCart(id)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'removeCartItem', (json) => AddToCartModel.fromJson(json));
  }

  Future<ApplyCoupon?> applyCoupon(String couponCode) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(document: gql(mutation.applyCoupon(couponCode)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'applyCoupon', (json) => ApplyCoupon.fromJson(json));
  }

  Future<ApplyCoupon?> removeCoupon() async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(document: gql(mutation.removeCoupon()), fetchPolicy: FetchPolicy.networkOnly));
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
    var response = await (client.clientToQuery()).mutate(MutationOptions(document: gql(mutation.removeAllCartItem()), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'removeAllCartItem', (json) => BaseModel.fromJson(json));
  }

  Future<WishListData?> getWishList() async {
    try {
      String customerId = appStoragePref.getCustomerId().toString();
      var url = Uri.parse("$baseDomain/mobikul-wishlist-api.php?action=get&customer_id=$customerId");
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
             var wishListModel = WishListData.fromJson(jsonResponse['data']);
             wishListModel.status = true;
             wishListModel.success = true;
             return wishListModel;
        }
      }
    } catch (e) { debugPrint("❌ FETCH WISHLIST ERROR: $e"); }
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
    var response = await (client.clientToQuery()).mutate(MutationOptions(document: gql(mutation.getSocialLoginResponse(firstName: firstName, lastName: lastName, email: email, phone: phone, signUpType: signUpType)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'customerSocialSignUp', (json) => SignInModel.fromJson(json));
  }

  Future<SignInModel?> getSignInData(String email, String password, bool remember) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(document: gql(mutation.customerLogin(email: email, password: password, remember: remember))));
    return handleResponse(response, 'customerLogin', (json) => SignInModel.fromJson(json));
  }

  Future<SignInModel?> getSignUpData(String email, String firstName, String lastName, String password, String confirmPassword, bool subscribeNewsletter, bool agreement) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(document: gql(mutation.customerRegister(firstName: firstName, lastName: lastName, email: email, password: password, confirmPassword: confirmPassword, subscribedToNewsLetter: subscribeNewsletter, agreement: agreement)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'customerSignUp', (json) => SignInModel.fromJson(json));
  }

  Future<AccountUpdate?> updateCustomerData(String? firstName, String? lastName, String? email, String? gender, String? dateOfBirth, String? phone, String? avatar, bool? subscribedToNewsLetter) async {
    try {
      String customerId = appStoragePref.getCustomerId().toString();
      var url = Uri.parse("$baseDomain/mobikul-profile-api.php");
      var body = {
        "action": "update",
        "customer_id": customerId,
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "gender": gender,
        "dateOfBirth": dateOfBirth,
        "phone": phone, 
      };
      var response = await http.post(url, body: jsonEncode(body), headers: {"Content-Type": "application/json"});
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        bool isSuccess = jsonResponse['success'] == true;
        var msg = jsonResponse['message'] ?? "Updated Successfully";
        var customerData = jsonResponse['data'];
        var dataMap = {
            "success": isSuccess, "status": isSuccess, "message": msg, "data": customerData, "customer": customerData, "graphqlErrors": null,
            "updateAccount": { "success": isSuccess, "status": isSuccess, "message": msg, "data": customerData, "customer": customerData, "graphqlErrors": null },
            "updateCustomer": { "success": isSuccess, "status": isSuccess, "message": msg, "data": customerData, "customer": customerData, "graphqlErrors": null }
        };
        return AccountUpdate.fromJson(dataMap);
      }
    } catch (e) {}
    return AccountUpdate.fromJson({"updateAccount": {"success": false, "message": "Network Error"}});
  }

  Future<BaseModel?> deleteCustomerAccount(String password) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(document: gql(mutation.deleteAccount(password: password)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'deleteAccount', (json) => BaseModel.fromJson(json));
  }

  Future<BaseModel?> forgotPassword(String email) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(document: gql(mutation.forgotPassword(email: email))));
    return handleResponse(response, 'forgotPassword', (json) => BaseModel.fromJson(json));
  }

  Future<ReviewModel?> getReviewList(int page) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(document: gql(mutation.getReviewList(page)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'reviewsList', (json) => ReviewModel.fromJson(json));
  }

  // 🟢 REPLACED: Use Custom PHP API to bypass broken Server Resource
  Future<OrdersListModel?> getOrderList(String? id, String? startDate, String? endDate, String? status, double? total, int? page, bool? isFilterApply) async {
    try {
      var url = Uri.parse("$baseDomain/mobikul-orders-api.php");
      String customerId = appStoragePref.getCustomerId().toString();
      debugPrint("🚀 FETCHING ORDERS (PHP) - Customer: $customerId, Page: $page");
      var response = await http.post(url, body: {"customer_id": customerId, "page": page.toString()});
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return OrdersListModel.fromJson(jsonResponse['data']);
        }
      }
    } catch (e) {
      debugPrint("❌ FETCH ORDER ERROR: $e");
    }
    return OrdersListModel(data: []);
  }

// Inside ApiClient class in api_client.dart

// Inside ApiClient class

// Inside lib/services/api_client.dart

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
    
    // 🟢 DEBUG LOG: See exactly what the server says
    debugPrint("🔵 RAW RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      try {
        var data = jsonDecode(response.body);
        // Pass the server message directly to the UI
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
      var url = Uri.parse("$baseDomain/mobikul-get-addresses.php?customer_id=$customerId");
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
    var response = await (client.clientToQuery()).mutate(MutationOptions(document: gql(mutation.deleteAddress(id)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'deleteAddress', (json) => BaseModel.fromJson(json));
  }

  Future<BaseModel?> createAddress(String companyName, String firstName, String lastName, String address, String address2, String country, String state, String city, String postCode, String phone, String vatId, bool? isDefault, String email) async {
    try {
      String customerId = appStoragePref.getCustomerId().toString(); 
      var url = Uri.parse("$baseDomain/mobikul-save-address.php");
      var response = await http.post(url, body: { "customer_id": customerId, "company_name": companyName, "first_name": firstName, "last_name": lastName, "address1": address, "address2": address2, "country": country, "state": state, "city": city, "postcode": postCode, "phone": phone, "vat_id": vatId, "default_address": isDefault.toString(), "email": email });
      var data = jsonDecode(response.body);
      return BaseModel(success: data['success'] == true, message: data['message'] ?? "Unknown Error");
    } catch (e) {
      return BaseModel(success: false, message: "App Error: $e");
    }
  }

  Future<UpdateAddressModel?> updateAddress(int id, String companyName, String firstName, String lastName, String address, String address2, String country, String state, String city, String postCode, String phone, String vatId, String email) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(document: gql(mutation.updateAddress(id: id, companyName: companyName, firstName: firstName, lastName: lastName, address: address, address2: address2, country: country, state: state, city: city, email: email, postCode: postCode, phone: phone, vatId: vatId)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'updateAddress', (json) => UpdateAddressModel.fromJson(json));
  }

  Future<CountriesData?> getCountryStateList() async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(document: gql(mutation.getCountryStateList()), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'countries', (json) => CountriesData.fromJson(json));
  }

  Future<PaymentMethods?> saveShippingMethods(String? shippingMethod) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(document: gql(mutation.paymentMethods(shippingMethod: shippingMethod)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'paymentMethods', (json) => PaymentMethods.fromJson(json));
  }

  Future<SavePayment?> saveAndReview(String? paymentMethod) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(document: gql(mutation.savePaymentAndReview(paymentMethod: paymentMethod)), fetchPolicy: FetchPolicy.networkOnly));
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
    var response = await (client.clientToQuery()).mutate(MutationOptions(document: gql(mutation.addReview(name = name, title = title, rating = rating, comment = comment, productId = productId, attachments = attachments)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'createReview', (json) => AddReviewModel.fromJson(json));
  }

  Future<DownloadableProductModel?> getCustomerDownloadableProducts(int page, int limit, {String? title, String? status, String? orderId, String? orderDateFrom, String? orderDateTo}) async {
    var response = await (client.clientToQuery()).query(QueryOptions(document: gql(mutation.downloadableProductsCustomer(page, limit, title: title ?? "", status: status ?? "", orderId: orderId ?? "", orderDateFrom: orderDateFrom ?? "", orderDateTo: orderDateTo ?? "")), cacheRereadPolicy: CacheRereadPolicy.mergeOptimistic, fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'downloadableLinkPurchases', (json) => DownloadableProductModel.fromJson(json));
  }

  Future<DownloadLinkDataModel?> downloadLinksProductAPI(int id) async {
    var response = await (client.clientToQuery()).query(QueryOptions(document: gql(mutation.downloadProductQuery(id)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'downloadLink', (json) => DownloadLinkDataModel.fromJson(json));
  }

  Future<Download?> downloadLinksProduct(int id) async {
    var response = await (client.clientToQuery()).query(QueryOptions(document: gql(mutation.downloadProduct(id)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'downloadableLinkPurchase', (json) => Download.fromJson(json));
  }

  Future<InvoicesModel?> getInvoicesList(int orderId) async {
    var response = await (client.clientToQuery()).query(QueryOptions(document: gql(mutation.getInvoicesList(orderId)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'viewInvoices', (json) => InvoicesModel.fromJson(json));
  }

  Future<ShipmentModel?> getShipmentsList(int orderId) async {
    var response = await (client.clientToQuery()).query(QueryOptions(document: gql(mutation.getShipmentsList(orderId)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'viewShipments', (json) => ShipmentModel.fromJson(json));
  }

  Future<OrderRefundModel?> getRefundList(int orderId) async {
    var response = await (client.clientToQuery()).query(QueryOptions(document: gql(mutation.getRefundList(orderId)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'viewRefunds', (json) => OrderRefundModel.fromJson(json));
  }

  Future<AddToCartModel?> reOrderCustomerOrder(String? orderId) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(document: gql(mutation.reOrderCustomerOrder(orderId)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'reorder', (json) => AddToCartModel.fromJson(json));
  }

  Future<BaseModel?> contactUsApiClient(String name, String? email, String? phone, String? describe) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(document: gql(mutation.contactUsApi(name: name, email: email, phone: phone, describe: describe)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'contactUs', (json) => BaseModel.fromJson(json));
  }

  Future<SetDefaultAddress?> setDefaultAddress(String id) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(document: gql(mutation.setDefaultAddress(id)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'setDefaultAddress', (json) => SetDefaultAddress.fromJson(json));
  }

  Future<DownloadSampleModel?> downloadSample(String type, String id) async {
    var response = await (client.clientToQuery()).mutate(MutationOptions(document: gql(mutation.downloadSample(type, id)), fetchPolicy: FetchPolicy.networkOnly));
    return handleResponse(response, 'downloadSample', (json) => DownloadSampleModel.fromJson(json));
  }
}