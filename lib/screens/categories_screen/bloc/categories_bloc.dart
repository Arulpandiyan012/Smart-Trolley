/*
 *   Webkul Software.
 *   @package Mobikul Application Code.
 *   @Category Mobikul
 *   @author Webkul <support@webkul.com>
 *   @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 *   @license https://store.webkul.com/license.html
 *   @link https://store.webkul.com/license.html
 */


import 'package:bagisto_app_demo/data_model/add_to_wishlist_model/add_wishlist_model.dart';
import 'package:bagisto_app_demo/screens/categories_screen/utils/index.dart';


class CategoryBloc
    extends Bloc<CategoryBaseEvent, CategoriesBaseState> {
  CategoriesRepository? repository;

  CategoryBloc(this.repository) : super(ShowLoaderCategoryState()) {
    on<CategoryBaseEvent>(mapEventToState);
  }

  void mapEventToState(
      CategoryBaseEvent event, Emitter<CategoriesBaseState> emit) async {
    if (event is FetchSubCategoryEvent) {
      try {
        NewProductsModel? categoriesData = await repository
            ?.callCategoriesData(filters: event.filters, page: event.page);
        emit(FetchSubCategoryState.success(categoriesData: categoriesData));
      } catch (e) {
        emit(FetchSubCategoryState.fail(error: e.toString()));
      }
    } 
    
    // 🟢 1. ADD TO WISHLIST EVENT (Force True)
    else if (event is FetchDeleteAddItemCategoryEvent) {
      try {
        AddWishListModel? addWishListModel =
            await repository!.callWishListDeleteItem(event.productId);
            
        if (addWishListModel?.success == true) {
          // 🟢 FIX: Don't toggle. Force it to TRUE because this is an ADD event.
          if (event.datum != null) {
            event.datum?.isInWishlist = true;
          }

          emit(FetchDeleteAddItemCategoryState.success(
              response: addWishListModel,
              productDeletedId: event.productId,
              successMsg: addWishListModel!.message));
        } else {
          emit(FetchDeleteAddItemCategoryState.fail(
              error: addWishListModel?.graphqlErrors));
        }
      } catch (e) {
        emit(FetchDeleteAddItemCategoryState.fail(
            error: StringConstants.somethingWrong.localized()));
      }
    } 
    
    // 🟢 2. REMOVE FROM WISHLIST EVENT (Force False)
    else if (event is FetchDeleteItemEvent) {
      try {
        AddToCartModel removeFromWishlist =
            await repository!.removeItemFromWishlist(event.productId);
            
        if (removeFromWishlist.status == true) {
          // 🟢 FIX: Don't toggle. Force it to FALSE because this is a REMOVE event.
          if (event.datum != null) {
            event.datum?.isInWishlist = false;
          }

          emit(RemoveWishlistState.success(
              productDeletedId: event.productId,
              successMsg: removeFromWishlist.message,
              response: removeFromWishlist));
        }
      } catch (e) {
        emit(RemoveWishlistState.fail(error: StringConstants.somethingWrong.localized()));
      }
    } 
    
    // ... (Keep the rest of the events like AddToCartSubCategoriesEvent unchanged) ...
    else if (event is AddToCartSubCategoriesEvent) {
      try {
        AddToCartModel graphQlBaseModel = await repository!.callAddToCartAPi(
            int.parse(event.productId ?? ""), event.quantity);
        if (graphQlBaseModel.graphqlErrors != true) {
          emit(AddToCartSubCategoriesState.success(
              response: graphQlBaseModel,
              successMsg: graphQlBaseModel.message ?? ""));
        } else {
          emit(AddToCartSubCategoriesState.fail(
              error: graphQlBaseModel.message ?? ""));
        }
      } catch (e) {
        emit(AddToCartSubCategoriesState.fail(
            error: StringConstants.somethingWrong.localized()));
      }
    } else if (event is AddToCompareSubCategoryEvent) {
      try {
        BaseModel baseModel = await repository!
            .callAddToCompareListApi(int.parse(event.productId ?? ""));
        if (baseModel.status == true) {
          emit(AddToCompareSubCategoryState.success(
              baseModel: baseModel, successMsg: baseModel.message));
        } else {
          emit(AddToCompareSubCategoryState.fail(error: baseModel.graphqlErrors));
        }
      } catch (e) {
        emit(AddToCompareSubCategoryState.fail(
            error: StringConstants.somethingWrong.localized()));
      }
    } else if (event is OnClickSubCategoriesLoaderEvent) {
      emit(OnClickSubCategoriesLoaderState(
          isReqToShowLoader: event.isReqToShowLoader));
    } else if (event is FilterFetchEvent) {
      try {
        GetFilterAttribute? filterModel =
            await repository?.getFilterProducts(event.categorySlug ?? "");
        emit(FilterFetchState.success(filterModel: filterModel));
      } catch (e) {
        emit(FilterFetchState.fail(error: e.toString()));
      }
    }
    // Inside categories_bloc.dart

// 🟢 CORRECTED LOGIC
    else if (event is AddToCartSubCategoryEvent) {
      // 1. Remove 'yield', use 'emit'
      // emit(ShowLoaderCategoryState()); 
      
      try {
        // 2. Use the CORRECT method name 'callAddToCartAPi'
        AddToCartModel response = await repository!.callAddToCartAPi(
            event.productId ?? 0, 
            event.quantity ?? 1
        );

        if (response.graphqlErrors != true) {
          // 3. Use NAMED arguments (response: ..., successMsg: ...)
          emit(AddToCartSubCategoriesState.success(
              response: response, 
              successMsg: response.message ?? "Success"));
        } else {
          emit(AddToCartSubCategoriesState.fail(
              error: response.message ?? "Failed"));
        }
      } catch (e) {
        emit(AddToCartSubCategoriesState.fail(
            error: e.toString()));
      }
    }
  }
  
}
