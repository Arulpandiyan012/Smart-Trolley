/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagisto_app_demo/data_model/order_model/order_detail_model.dart';
import 'package:bagisto_app_demo/data_model/graphql_base_model.dart';
import 'package:bagisto_app_demo/screens/order_detail/utils/index.dart';
import '../../cart_screen/cart_model/add_to_cart_model.dart';

class OrderDetailBloc extends Bloc<OrderDetailBaseEvent, OrderDetailBaseState> {
  OrderDetailRepository? repository;
  BuildContext? context;

  OrderDetailBloc({@required this.repository}) : super(OrderDetailInitialState()) {
    on<OrderDetailBaseEvent>(mapEventToState);
  }

  void mapEventToState(OrderDetailBaseEvent event, Emitter<OrderDetailBaseState> emit) async {
    if (event is OrderDetailFetchDataEvent) {
      try {
        OrderDetail orderDetailModel = await repository!.getOrderDetails(event.orderId ?? 1);
        
        bool isSuccess = false;
        if (orderDetailModel.responseStatus is bool) {
          isSuccess = orderDetailModel.responseStatus == true;
        } else {
          isSuccess = orderDetailModel.responseStatus.toString().toLowerCase() == "true";
        }

        if (isSuccess) {
          emit(OrderDetailFetchDataState.success(orderDetailModel: orderDetailModel));
        } else {
          emit(OrderDetailFetchDataState.fail(error: orderDetailModel.success.toString()));
        }
      } catch (e) {
        emit(OrderDetailFetchDataState.fail(error: e.toString()));
      }
    } 
    else if (event is CancelOrderEvent) {
      try {
        BaseModel baseModel = await repository!.cancelOrder(event.id ?? 0);
        
        // 🟢 FIX START: Robust check for Success
        bool isSuccess = false;

        // 1. Check Status (Handle Bool or String)
        if (baseModel.status is bool) {
          isSuccess = baseModel.status == true;
        } else if (baseModel.status != null) {
          isSuccess = baseModel.status.toString().toLowerCase() == "true";
        }

        // 2. Fallback: If status is false/null, check if message implies success
        // This catches "false negatives" where API says status: false but message is "Order Cancelled Successfully"
        if (!isSuccess && (baseModel.message?.toLowerCase().contains("success") ?? false)) {
           isSuccess = true;
        }
        if (!isSuccess && (baseModel.message?.toLowerCase().contains("cancelled") ?? false)) {
           isSuccess = true;
        }
        // 🟢 FIX END

        if (isSuccess) {
          emit(CancelOrderState.success(baseModel: baseModel, successMsg: baseModel.message));
        } else {
          // If it really failed, send the server error or message
          emit(CancelOrderState.fail(error: baseModel.graphqlErrors ?? baseModel.message ?? "Failed to cancel"));
        }
      } catch (e) {
        emit(CancelOrderState.fail(error: StringConstants.somethingWrong.localized()));
      }
    } 
    else if (event is OnClickOrderLoadingEvent) {
      emit(OnClickLoadingState(isReqToShowLoader: event.isReqToShowLoader));
    } 
    else if (event is ReOrderEvent) {
      try {
        AddToCartModel? baseModel = await repository?.reOrderCustomerOrder(event.id);
        if (baseModel?.success == true) {
          emit(ReOrderState.success(model: baseModel));
        } else {
          emit(ReOrderState.fail(message: baseModel?.message ?? baseModel?.graphqlErrors));
        }
      } catch (e) {
        emit(ReOrderState.fail(message: StringConstants.somethingWrong.localized()));
      }
    }
  }
}