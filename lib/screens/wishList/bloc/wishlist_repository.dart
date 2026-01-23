/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:bagisto_app_demo/screens/wishList/utils/index.dart';
import '../../cart_screen/cart_model/cart_data_model.dart';

abstract class WishListRepository {
  Future<WishListData?> callWishListApi();
  Future<AddToCartModel?> callWishListDeleteItem(var wishListProductId);
  
  // 🟢 FIX: Changed 'int' to 'String' to match implementation
  Future<AddToCartModel?> callAddToCartAPi(String productId, String quantity);
  
  Future<BaseModel?> removeAllWishListProducts();
  Future<CartModel?> cartCountApi();
}

class WishListRepositoryImp implements WishListRepository {
  @override
  Future<WishListData?> callWishListApi() async {
    WishListData? wishListData;
    try {
      wishListData = await ApiClient().getWishList();
    } catch (error, stacktrace) {
      debugPrint("Error --> $error");
      debugPrint("StackTrace --> $stacktrace");
    }
    return wishListData;
  }

  @override
  Future<AddToCartModel?> callWishListDeleteItem(var wishListProductId) async {
    AddToCartModel? removeFromWishlist;
    try {
      removeFromWishlist = await ApiClient().removeFromWishlist(wishListProductId);
    } catch (error, stacktrace) {
      debugPrint("Error -->${error.toString()}");
      debugPrint("StackTrace -->${stacktrace.toString()}");
    }
    return removeFromWishlist;
  }

  @override
  // 🟢 FIX: Matches abstract class (String)
  Future<AddToCartModel?> callAddToCartAPi(String productId, String quantity) async {
    AddToCartModel? baseModel;
    try {
      baseModel = await ApiClient().moveFromWishlistToCart(
        productId, quantity
      );
    } catch (error) {
      debugPrint("Error -->${error.toString()}");
    }
    return baseModel;
  }

  @override
  Future<BaseModel?> removeAllWishListProducts() async {
    BaseModel? baseModel;
    baseModel = await ApiClient().removeAllWishlistProducts();
    return baseModel;
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
}