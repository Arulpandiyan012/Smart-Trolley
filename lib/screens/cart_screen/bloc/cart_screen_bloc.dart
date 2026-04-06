/*
 *   Webkul Software.
 *   @package Mobikul Application Code.
 *   @Category Mobikul
 *   @author Webkul <support@webkul.com>
 *   @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 *   @license https://store.webkul.com/license.html
 *   @link https://store.webkul.com/license.html
 */

import 'package:bagisto_app_demo/screens/cart_screen/utils/cart_index.dart';
import 'package:bagisto_app_demo/data_model/order_model/orders_list_data_model.dart';

class CartScreenBloc extends Bloc<CartScreenBaseEvent, CartScreenBaseState> {
  CartScreenRepository? repository;

  CartScreenBloc(this.repository) : super(ShowLoaderCartState()) {
    on<CartScreenBaseEvent>(mapEventToState);
  }

  void mapEventToState(
      CartScreenBaseEvent event, Emitter<CartScreenBaseState> emit) async {
    if (event is FetchCartDataEvent) {
      try {
        CartModel? cartDetailsModel = await repository?.getCartData();
        emit(FetchCartDataState.success(cartDetailsModel: cartDetailsModel));
      } catch (e) {
        emit(FetchCartDataState.fail(error: e.toString()));
      }
    } else if (event is UpdateCartEvent) {
      try {
        AddToCartModel? cartDetailsModel =
            await repository?.updateItemToCart(event.item ?? []);
        emit(UpdateCartState.success(
            cartDetailsModel: cartDetailsModel, item: event.item));
      } catch (e) {
        emit(UpdateCartState.fail(error: e.toString()));
      }
    } else if (event is RemoveCartItemEvent) {
      try {
        AddToCartModel? removeCartProductModel =
            await repository?.removeFromCart(event.cartItemId!);
        emit(RemoveCartItemState.success(
            removeCartProductModel: removeCartProductModel,
            productDeletedId: event.cartItemId));
      } catch (e) {
        emit(RemoveCartItemState.fail(error: e.toString()));
      }
    } else if (event is RemoveAllCartItemEvent) {
      try {
        BaseModel? removeCartProductModel =
            await repository?.removeAllCartItem();
        emit(RemoveAllCartItemState.success(
            removeAllCartProductModel: removeCartProductModel));
      } catch (e) {
        emit(RemoveAllCartItemState.fail(error: e.toString()));
      }
    } else if (event is AddCouponCartEvent) {
      try {
        String code = (event.code ?? "").toUpperCase().trim();
        
        // 🟢 UPDATED: 'FIRST25' One-Time Use Simulation Logic
        if (code == "FIRST25") {
           // 1. FAST CHECK: Is it marked as used in Storage?
           if (appStoragePref.getIsCouponUsed("FIRST25")) {
               emit(AddCouponState.fail(error: "This coupon has already been used on your account."));
               return;
           }

           // 2. BACKUP CHECK: Search Order History (For Logout/Login sync or new installs)
           OrdersListModel? orders = await repository?.getOrderList(null, null, null, null, null, 1, false);

           
           // Check if ANY previous order already used a discount
           bool hasUsedDiscount = (orders?.data ?? []).any((order) {
             String discount = order.formattedPrice?.discountAmount?.toString() ?? "0";
             // Filter out strings like "₹ 0.00", "0", or empty
             return !discount.contains("0.00") && discount != "0" && discount.trim().isNotEmpty;
           });
           
            if (!hasUsedDiscount) {
               // Simulate success
               GlobalData.appliedCouponCode = "FIRST25"; // 🟢 SYNC GLOBAL STATE
               emit(AddCouponState.success(
                   baseModel: ApplyCoupon(success: true, message: "Success! 25% one-time discount applied."),
                   successMsg: "Success! 25% one-time discount applied."));
               return;

           } else {
              emit(AddCouponState.fail(error: "The 'FIRST25' coupon has already been used on this account."));
              return;
           }
        }

        ApplyCoupon? baseModel =
            await repository?.addCoupon(event.code ?? "");
        if (baseModel?.success == true) {
          GlobalData.appliedCouponCode = code; // 🟢 SYNC GLOBAL STATE
          emit(AddCouponState.success(
              baseModel: baseModel, successMsg: baseModel?.message));

        } else {
          emit(AddCouponState.fail(error: baseModel?.message));
        }
      } catch (e) {
        emit(AddCouponState.fail(error: e.toString()));
      }
    } else if (event is RemoveCouponCartEvent) {
      try {
        ApplyCoupon? baseModel = await repository?.removeCoupon();
        event.cartDetailsModel?.couponCode = null;
        GlobalData.appliedCouponCode = null; // 🟢 SYNC GLOBAL STATE
        if (baseModel?.success == true) {

          emit(RemoveCouponCartState.success(
              baseModel: baseModel, successMsg: baseModel?.message));
        } else {
          emit(RemoveCouponCartState.fail(error: baseModel?.message ?? ""));
        }
      } catch (e) {
        emit(RemoveCouponCartState.fail(error: e.toString()));
      }
    } else if (event is MoveToCartEvent) {
      try {
        // 🟢 PASS ID AS STRING (Removed '?? 0')
        AddToCartModel? baseModel =
            await repository?.moveToWishlist(event.id.toString());
            
        if (baseModel?.success == true || baseModel?.status == true) {
          emit(MoveToCartState.success(
            response: baseModel,
            id: event.id,
          ));
        } else {
          emit(MoveToCartState.fail(
              error: baseModel?.message ?? baseModel?.graphqlErrors ?? "Failed"));
        }
      } catch (e) {
        emit(MoveToCartState.fail(error: e.toString()));
      }
    } else if (event is ClearCartEvent) {
      // 🟢 Clear cart by emitting success with null data
      emit(FetchCartDataState.success(cartDetailsModel: null));
    }
  }
}
