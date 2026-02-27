/*
 *   Webkul Software.
 *   @package Mobikul Application Code.
 *   @Category Mobikul
 *   @author Webkul <support@webkul.com>
 *   @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 *   @license https://store.webkul.com/license.html
 *   @link https://store.webkul.com/license.html
 */

import '../../../data_model/add_to_wishlist_model/add_wishlist_model.dart';
import 'package:bagisto_app_demo/screens/product_screen/utils/index.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bagisto_app_demo/utils/server_configuration.dart';

import '../data_model/download_sample_model.dart';

abstract class ProductScreenRepository {
  Future<NewProductsModel?> getProductDetails(
  List<Map<String, dynamic>>? filters);

  Future<AddToCartModel?> callAddToCartAPi(
      int quantity,
      String productId,
      List downloadLinks,
      List groupedParams,
      List bundleParams,
      List configurableParams,
      String? configurableId);

  Future<BaseModel?> callAddToCompareListApi(
    String productId,
  );

  Future<AddWishListModel?> callWishListDeleteItem(String wishListProductId);

  Future<AddToCartModel?> removeItemFromWishlist(String wishListProductId);

  Future<DownloadSampleModel?> downloadSample(String type, String id);
}

class ProductScreenRepo implements ProductScreenRepository {
  @override
  Future<NewProductsModel?> getProductDetails(
      List<Map<String, dynamic>>? filters) async {
    // 🟢 CUSTOM API PRODUCT DETAILS FETCH (Bypass Bagisto GraphQL EAV logic)
    try {
      var url = Uri.parse("$baseDomain/mobikul-vendor-api.php");
      
      String urlKey = "";
      String productId = "";
      
      if (filters != null) {
         for (var f in filters) {
            if (f['key'] == "\"url_key\"") {
                urlKey = f['value'].toString().replaceAll("\"", "");
            } else if (f['key'] == "\"id\"") {
                productId = f['value'].toString().replaceAll("\"", "");
            }
         }
      }

      debugPrint("🔵 PRODUCT REPO: Fetching Single Product (urlKey: $urlKey, ID: $productId)");
      
      var response = await http.post(url, body: {
          "action": "get_single_product",
          "url_key": urlKey,
          "product_id": productId
      });

      if (response.statusCode == 200) {
          var json = jsonDecode(response.body);
          if (json['success'] == true) {
               return NewProductsModel.fromJson(json);
          }
      }
      
      // Fallback to GraphQL if PHP fails
      return await ApiClient().getAllProducts(filters: filters);
    } catch (e, stack) {
      debugPrint("🔴 PRODUCT REPO ERROR: $e");
      debugPrint("🔴 STACK: $stack");
    }
    return null;
  }

  @override
  Future<AddToCartModel?> callAddToCartAPi(
      int quantity,
      String productId,
      List downloadLinks,
      List groupedParams,
      List bundleParams,
      List configurableParams,
      String? configurableId) async {
    AddToCartModel? addToCartModel;

    try {
      addToCartModel = await ApiClient().addToCart(
          quantity,
          productId,
          downloadLinks,
          groupedParams,
          bundleParams,
          configurableParams,
          configurableId);
    } catch (error, stacktrace) {
      debugPrint("Error --> $error");
      debugPrint("StackTrace --> $stacktrace");
    }
    return addToCartModel;
  }

  @override
  Future<BaseModel?> callAddToCompareListApi(String productId) async {
    BaseModel? baseModel;

    try {
      baseModel = await ApiClient().addToCompare(productId);
    } catch (error, stacktrace) {
      debugPrint("Error --> $error");
      debugPrint("StackTrace --> $stacktrace");
    }

    return baseModel;
  }

  @override
  Future<AddWishListModel?> callWishListDeleteItem(
      String wishListProductId) async {
    AddWishListModel? addWishListModel;
    try {
      addWishListModel = await ApiClient().addToWishlist(wishListProductId);
    } catch (error, stacktrace) {
      debugPrint("Error -->$error");
      debugPrint("StackTrace -->$stacktrace");
    }
    return addWishListModel;
  }

  @override
  Future<AddToCartModel?> removeItemFromWishlist(
      String wishListProductId) async {
    AddToCartModel? removeFromWishlist;
    try {
      removeFromWishlist =
          await ApiClient().removeFromWishlist(wishListProductId);
    } catch (error, stacktrace) {
      debugPrint("Error -->${error.toString()}");
      debugPrint("StackTrace -->${stacktrace.toString()}");
    }
    return removeFromWishlist;
  }

  @override
  Future<DownloadSampleModel?> downloadSample(String type, String id) async {
    DownloadSampleModel? model;
    try {
      model = await ApiClient().downloadSample(type, id);
    } catch (error, stacktrace) {
      debugPrint("Error -->${error.toString()}");
      debugPrint("StackTrace -->${stacktrace.toString()}");
    }
    return model;
  }
}
