/*
 *   Webkul Software.
 *   @package Mobikul Application Code.
 *   @Category Mobikul
 *   @author Webkul <support@webkul.com>
 *   @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 *   @license https://store.webkul.com/license.html
 *   @link https://store.webkul.com/license.html
 */

import 'package:bagisto_app_demo/screens/home_page/utils/index.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bagisto_app_demo/utils/server_configuration.dart'; 
import '../../../data_model/add_to_wishlist_model/add_wishlist_model.dart';

import '../../cart_screen/cart_model/cart_data_model.dart';
import '../../cms_screen/data_model/cms_model.dart';
import '../data_model/theme_customization.dart';

abstract class HomePageRepository {
  Future<AddToCartModel?> callAddToCartAPi(int productId, int quantity);
  Future<AddWishListModel?> addItemToWishlist(String? wishListProductId);
  Future<BaseModel?> callLogoutApi();
  Future<BaseModel?> callAddToCompareListApi(String? productId);
  Future<ThemeCustomDataModel?> getThemeCustomizationData();
  Future<CartModel?> cartCountApi();
  Future<CmsData?> callCmsData(String id);
  Future<AddToCartModel?> removeItemFromWishlist(String? wishListProductId);
  Future<AccountInfoModel?> callAccountDetailsApi();
  Future<NewProductsModel?> getAllProducts(
      {List<Map<String, dynamic>>? filters});
  Future<GetDrawerCategoriesData?> getHomeCategoriesList(
      {List<Map<String, dynamic>>? filters});
}

class HomePageRepositoryImp implements HomePageRepository {
  @override
  Future<GetDrawerCategoriesData?> getHomeCategoriesList(
      {List<Map<String, dynamic>>? filters}) async {
    
    // 🟢 CUSTOM API IMPLEMENTATION (Matches Sidebar Logic)
    try {
        var url = Uri.parse("$baseDomain/mobikul-vendor-api.php");
        debugPrint("🔵 HOME REPO: Fetching Categories from Custom API: $url");
        
        var response = await http.post(url, body: {"action": "get_categories"});

        if (response.statusCode == 200) {
            var json = jsonDecode(response.body);
            if (json['success'] == true) {
                 List<dynamic> rawList = json['data'];
                 List<HomeCategories> homeCats = rawList.map((c) => _mapToHomeCategory(c)).toList();
                 
                 var model = GetDrawerCategoriesData();
                 model.success = "true";
                 model.responseStatus = true;
                 model.data = homeCats;
                 return model;
            }
        }
    } catch (e) {
        debugPrint("🔴 HOME REPO ERROR: $e");
    }
    return null;
  }

  // Helper to Map JSON -> HomeCategories (Recursive)
  HomeCategories _mapToHomeCategory(Map<String, dynamic> json) {
      List<Children> childrenList = [];
      if (json['children'] != null) {
          json['children'].forEach((v) {
              childrenList.add(_mapToChildren(v));
          });
      }
      var cat = HomeCategories();
      cat.id = json['id'].toString();
      cat.name = json['name'];
      cat.slug = json['slug'];
      cat.bannerUrl = json['bannerUrl'];
      cat.logoUrl = json['logoUrl'];
      cat.children = childrenList;
      return cat;
  }

  // Helper to Map JSON -> Children (Recursive)
  Children _mapToChildren(Map<String, dynamic> json) {
       List<Children> subChildren = [];
       if (json['children'] != null) {
           json['children'].forEach((v) {
               subChildren.add(_mapToChildren(v));
           });
       }
       var child = Children();
       child.id = json['id'].toString();
       child.name = json['name'];
       child.slug = json['slug'];
       child.bannerUrl = json['bannerUrl'];
       child.logoUrl = json['logoUrl'];
       child.children = subChildren;
       return child;
  }

  @override
  Future<AddToCartModel?> callAddToCartAPi(int productId, int quantity) async {
    AddToCartModel? addToCartModel;
    addToCartModel = await ApiClient()
        .addToCart(quantity, productId.toString(), [], [], [], [], null);

    return addToCartModel;
  }

  @override
  Future<AddWishListModel?> addItemToWishlist(var wishListProductId) async {
    AddWishListModel? addWishListModel;
    try {
      addWishListModel = await ApiClient().addToWishlist(wishListProductId);
    } catch (error, stacktrace) {
      debugPrint("Error -->${error.toString()}");
      debugPrint("StackTrace -->${stacktrace.toString()}");
    }
    return addWishListModel;
  }

  ///Log Out Api
  @override
  Future<BaseModel?> callLogoutApi() async {
    BaseModel? response;
    try {
      response = await ApiClient().customerLogout();
    } catch (error, stacktrace) {
      debugPrint("Error --> $error");
      debugPrint("StackTrace --> $stacktrace");
    }
    return response;
  }

  @override
  Future<BaseModel?> callAddToCompareListApi(String? productId) async {
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
  Future<ThemeCustomDataModel?> getThemeCustomizationData() async {
    ThemeCustomDataModel? homeSlidersData;
    try {
      homeSlidersData = await ApiClient().getThemeCustomizationData();
    } catch (error, stacktrace) {
      debugPrint("Error --> $error");
      debugPrint("StackTrace --> $stacktrace");
    }
    return homeSlidersData;
  }

  @override
  Future<CartModel?> cartCountApi() async {
    CartModel? cartDetails;
    try {
      cartDetails = await ApiClient().getCartCount();
    } catch (error, stacktrace) {
      debugPrint("Error --> $error");
      debugPrint("StackTrace --> $stacktrace");
    }
    return cartDetails;
  }

  @override
  Future<AddToCartModel?> removeItemFromWishlist(
      String? wishListProductId) async {
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
  Future<AccountInfoModel?> callAccountDetailsApi() async {
    AccountInfoModel? accountInfoDetails;
    try {
      accountInfoDetails = await ApiClient().getCustomerData();
    } catch (error, stacktrace) {
      debugPrint("Error --> $error");
      debugPrint("StackTrace --> $stacktrace");
    }
    return accountInfoDetails;
  }

  //todo
  @override
  Future<NewProductsModel?> getAllProducts(
      {List<Map<String, dynamic>>? filters}) async {
    NewProductsModel? newProductsData;
    try {
      newProductsData = await ApiClient().getAllProducts(filters: filters);
    } catch (error, stacktrace) {
      debugPrint("Error --> $error");
      debugPrint("StackTrace --> $stacktrace");
    }
    return newProductsData;
  }

  @override
  Future<CmsData?> callCmsData(String id) async {
    CmsData? cmsData;
    try {
      cmsData = await ApiClient().getCmsPagesData();
    } catch (error, stacktrace) {
      debugPrint("Error --> $error");
      debugPrint("StackTrace --> $stacktrace");
    }
    return cmsData;
  }
}
