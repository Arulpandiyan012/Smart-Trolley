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

import '../data_model/download_sample_model.dart';

class ProductScreenBLoc extends Bloc<ProductScreenBaseEvent, ProductBaseState> {
  ProductScreenRepo? repository;

  ProductScreenBLoc(this.repository) : super(ProductInitialState()) {
    on<ProductScreenBaseEvent>(mapEventToState);
  }

  void mapEventToState(
      ProductScreenBaseEvent event, Emitter<ProductBaseState> emit) async {
    if (event is FetchProductEvent) {
      try {
        String urlKey = event.sku.trim();
        int? productId = event.productId;

        // 🟢 FIX: If urlKey is empty but we have a productId, try to recover urlKey
        // from the in-memory product cache (GlobalData.allProducts).
        // This handles newly added products that are shown on home but have no urlKey passed.
        if (urlKey.isEmpty && productId != null && productId > 0) {
          final String pidStr = productId.toString();
          outerLoop:
          for (final sectionModel in (GlobalData.allProducts ?? [])) {
            for (final product in (sectionModel?.data ?? [])) {
              if (product.id?.toString() == pidStr && (product.urlKey?.isNotEmpty ?? false)) {
                urlKey = product.urlKey!;
                debugPrint("✅ Recovered urlKey from cache: $urlKey (productId=$productId)");
                break outerLoop;
              }
            }
          }
        }

        if (urlKey.isEmpty && (productId == null || productId <= 0)) {
          emit(FetchProductState.fail(error: "No product identifier provided"));
          return;
        }

        debugPrint("🔵 FetchProductEvent: urlKey='$urlKey' productId=$productId");

        List<Map<String, dynamic>> filters = [];
        if (urlKey.isNotEmpty) {
          filters = [{"key": '"url_key"', "value": '"$urlKey"'}];
        } else {
          filters = [{"key": '"id"', "value": '"$productId"'}];
          if (event.title != null && event.title!.isNotEmpty) {
            filters.add({"key": '"name"', "value": '"${event.title}"'});
          }
        }

        NewProductsModel? productData = await repository?.getProductDetails(filters);
        emit(FetchProductState.success(productData: productData?.data?.firstOrNull));
      } catch (e) {
        emit(FetchProductState.fail(error: e.toString()));
      }

    } else if (event is AddToCartProductEvent) {
      try {
        AddToCartModel? cartModel = await repository?.callAddToCartAPi(
            event.quantity,
            event.productId ?? "",
            event.downloadLinks,
            event.groupedParams,
            event.bundleParams,
            event.configurableParams,
            event.configurableId);
        if (cartModel?.success == true) {
          debugPrint("🟢 ProductBloc: Emitting Cart Update Event");
          GlobalData.cartUpdateStream.add(null); // 🟢 Notify Cart Screen
          emit(AddToCartProductState.success(
              response: cartModel, successMsg: cartModel?.message));
        } else {
          emit(AddToCartProductState.fail(error: cartModel?.message));
        }
      } catch (e) {
        emit(AddToCartProductState.fail(error: e.toString()));
      }
    } else if (event is AddToCompareListEvent) {
      try {
        BaseModel? baseModel =
        await repository?.callAddToCompareListApi(event.productId ?? "");
        if (baseModel?.status == true) {
          emit(AddToCompareListState.success(
              baseModel: baseModel, successMsg: baseModel?.message));
        } else {
          emit(AddToCompareListState.fail(error: baseModel?.graphqlErrors));
        }
      } catch (e) {
        emit(AddToCompareListState.fail(
            error: StringConstants.somethingWrong.localized()));
      }
    } else if (event is AddToWishListProductEvent) {
      final pid = event.productId ?? "";
      // 🟢 Optimistic Update
      GlobalData.toggleWishlistOptimistic(pid, true);
      
      try {
        AddWishListModel? addWishListModel =
        await repository!.callWishListDeleteItem(pid);
        debugPrint("❤️ WISHLIST ADD API: success=${addWishListModel?.success}, status=${addWishListModel?.status}");
        
        if (addWishListModel?.success == true || addWishListModel?.status == true) {
          // 🟢 Final Sync (just in case)
          // The repository usually returns the updated wishlist state or success.
          // We rely on the FetchWishlist later or just assume success here.
          emit(AddToWishListProductState.success(
              response: addWishListModel,
              productDeletedId: event.productId,
              successMsg: addWishListModel!.message));
        } else {
          // 🔴 Rollback on failure
          GlobalData.toggleWishlistOptimistic(pid, false);
          emit(AddToWishListProductState.fail(error: addWishListModel?.graphqlErrors));
        }
      } catch (e) {
        // 🔴 Rollback on error
        GlobalData.toggleWishlistOptimistic(pid, false);
        emit(AddToWishListProductState.fail(
            error: StringConstants.somethingWrong.localized()));
      }
    } else if (event is RemoveFromWishlistEvent) {
      final pid = event.productId ?? "";
      // 🟢 Optimistic Update
      GlobalData.toggleWishlistOptimistic(pid, false);

      try {
        AddToCartModel? removeFromWishlist =
        await repository?.removeItemFromWishlist(pid);
        debugPrint("💔 WISHLIST REMOVE API: success=${removeFromWishlist?.success}, status=${removeFromWishlist?.status}");

        if (removeFromWishlist?.status == true || removeFromWishlist?.success == true) {
          emit(RemoveFromWishlistState.success(
              productDeletedId: event.productId,
              successMsg: removeFromWishlist?.message,
              response: removeFromWishlist));
        } else {
          // 🔴 Rollback on failure
          GlobalData.toggleWishlistOptimistic(pid, true);
          emit(RemoveFromWishlistState.fail(error: removeFromWishlist?.message));
        }
      } catch (e) {
        // 🔴 Rollback on error
        GlobalData.toggleWishlistOptimistic(pid, true);
        emit(RemoveFromWishlistState.fail(
            error: StringConstants.somethingWrong.localized()));
      }
    } else if (event is OnClickProductLoaderEvent) {
      emit(OnClickProductLoaderState(
          isReqToShowLoader: event.isReqToShowLoader));
    } else if (event is DownloadProductSampleEvent) {
      try {
        DownloadSampleModel? baseModel =
        await repository?.downloadSample(event.type ?? "", event.id ?? "");
        print("DownloadProductSampleStatebloc --- ${baseModel?.string}");
        if (baseModel?.success == true) {
          emit(DownloadProductSampleState.success(model: baseModel,fileName: event.fileName));
        } else {
          emit(DownloadProductSampleState.fail(error: baseModel?.graphqlErrors));
        }
      } catch (e) {
        emit(DownloadProductSampleState.fail(
            error: StringConstants.somethingWrong.localized()));
      }
    }
  }
}
