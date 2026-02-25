/*
 *   Webkul Software.
 *   @package Mobikul Application Code.
 *   @Category Mobikul
 *   @author Webkul <support@webkul.com>
 *   @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 *   @license https://store.webkul.com/license.html
 *   @link https://store.webkul.com/license.html
 */

// ignore_for_file: file_names, avoid_print


import '../../../data_model/add_to_wishlist_model/add_wishlist_model.dart';
import 'package:bagisto_app_demo/screens/categories_screen/utils/index.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bagisto_app_demo/utils/server_configuration.dart';

abstract class CategoriesRepository{
  Future<NewProductsModel?> callCategoriesData({List<Map<String, dynamic>>? filters, int? page});
  Future<AddWishListModel?> callWishListDeleteItem(var wishListProductId);
  Future<AddToCartModel> callAddToCartAPi(int productId, int quantity);
  Future<BaseModel> callAddToCompareListApi(int productId);
  Future<AddToCartModel> removeItemFromWishlist(var wishListProductId);
  Future<GetFilterAttribute> getFilterProducts(String categorySlug);

}
class CategoriesRepo implements CategoriesRepository {
  @override
  Future<NewProductsModel?> callCategoriesData({List<Map<String, dynamic>>? filters, int? page}) async {
    // 🟢 GRAPHQL REPO: Robust product fetching with filter sanitization
    try {
       // Ensure keys/values are properly quoted for the GraphQL schema
       List<Map<String, dynamic>> sanitizedFilters = [];
       if (filters != null) {
          for (var f in filters) {
             String key = f['key'].toString().replaceAll("\"", "");
             String val = f['value'].toString().replaceAll("\"", "");
             sanitizedFilters.add({"key": '"$key"', "value": '"$val"'});
          }
       }

       debugPrint("🚀 CATEGORY REPO: Fetching GraphQL Products | Filters: $sanitizedFilters | Page: $page");
       
       var result = await ApiClient().getAllProducts(filters: sanitizedFilters, page: page);

       if (result != null) {
           int count = result.data?.length ?? 0;
           if (count > 0) {
             debugPrint("✅ GRAPHQL SUCCESS: Found $count products for filters $sanitizedFilters");
           } else {
             debugPrint("⚠️ GRAPHQL EMPTY: API returned 0 products for $sanitizedFilters.");
           }
       }
       return result;
    } catch (e, stack) {
       debugPrint("❌ GRAPHQL REPO CRASH: $e");
       debugPrint("Stack: $stack");
       return null;
    }
  }

  // 🟢 HELPER: Sanitize JSON to fix Type Cast Errors
  Map<String, dynamic> _sanitizeProductIds(Map<String, dynamic> json) {
      try {
        if (json['data'] != null) {
            List<dynamic> list = json['data'];
            for (var i = 0; i < list.length; i++) {
                // Fix boolean fields that might be int/string
                if (list[i]['isNew'] is int) list[i]['isNew'] = (list[i]['isNew'] == 1);
                if (list[i]['isNew'] is String) list[i]['isNew'] = (list[i]['isNew'] == "1");

                if (list[i]['isInSale'] is int) list[i]['isInSale'] = (list[i]['isInSale'] == 1);
                if (list[i]['isInSale'] is String) list[i]['isInSale'] = (list[i]['isInSale'] == "1");
                
                // Fix numeric fields that might be String
                if (list[i]['totalQty'] is String) list[i]['totalQty'] = int.tryParse(list[i]['totalQty'] ?? "0");
                if (list[i]['quantity'] is String) list[i]['quantity'] = int.tryParse(list[i]['quantity'] ?? "0");
                if (list[i]['totalQtyOrdered'] is String) list[i]['totalQtyOrdered'] = int.tryParse(list[i]['totalQtyOrdered'] ?? "0");
            }
        }
        
        // Fix Paginator Info
        if (json['paginatorInfo'] != null) {
             var p = json['paginatorInfo'];
             if (p['count'] is String) p['count'] = int.tryParse(p['count']);
             if (p['currentPage'] is String) p['currentPage'] = int.tryParse(p['currentPage']);
             if (p['lastPage'] is String) p['lastPage'] = int.tryParse(p['lastPage']);
             if (p['total'] is String) p['total'] = int.tryParse(p['total']);
        }
      } catch (e) {
         debugPrint("⚠️ SANITIZATION FAILED: $e");
      }
      return json;
  }
  @override
  Future<GetFilterAttribute> getFilterProducts(String categorySlug) async {
    GetFilterAttribute? filterAttribute;
    try{
      filterAttribute=await ApiClient().getFilterAttributes(categorySlug);
    }
    catch(error,stacktrace){
      print("Error --> $error");
      print("StackTrace --> $stacktrace");
    }
    return filterAttribute!;
  }

  
  @override
  Future<AddWishListModel?> callWishListDeleteItem(
      var wishListProductId) async {

    AddWishListModel? addWishListModel;
    try {
      addWishListModel = await ApiClient().addToWishlist(wishListProductId??"");
    } catch (error, stacktrace) {
      print("Error -->${error.toString()}");
      print("StackTrace -->${stacktrace.toString()}");
    }
    return addWishListModel;
  }

  @override
  Future<AddToCartModel> callAddToCartAPi(
      int productId,int quantity ) async {
    AddToCartModel? graphQlBaseModel;

    graphQlBaseModel = await ApiClient().addToCart(quantity,productId.toString(),[] ,[],[],[],null);

    return graphQlBaseModel!;
  }

  @override
  Future<BaseModel> callAddToCompareListApi(int productId) async {
    BaseModel? baseModel;
    baseModel = await ApiClient()
        .addToCompare(productId.toString());
    return baseModel!;
  }


  @override
  Future<AddToCartModel> removeItemFromWishlist(var wishListProductId) async {
    AddToCartModel? removeFromWishlist;
    try{
      removeFromWishlist=await ApiClient().removeFromWishlist(wishListProductId);

    }catch(error, stacktrace){
      debugPrint("Error -->${error.toString()}");
      debugPrint("StackTrace -->${ stacktrace.toString()}");
    }
    return removeFromWishlist!;
  }

}
