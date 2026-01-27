/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 * @author Webkul <support@webkul.com>
 * @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 * @license https://store.webkul.com/license.html
 * @link https://store.webkul.com/license.html
 */

// ignore_for_file: file_names, implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagisto_app_demo/screens/order_detail/utils/index.dart';
import 'package:bagisto_app_demo/utils/index.dart'; 
import 'package:bagisto_app_demo/screens/order_detail/bloc/order_detail_bloc.dart';
import 'package:bagisto_app_demo/screens/order_detail/bloc/order_detail_event.dart';
import 'package:bagisto_app_demo/screens/order_detail/bloc/order_detail_state.dart';
import 'package:bagisto_app_demo/data_model/order_model/order_detail_model.dart';

class OrderDetailScreen extends StatefulWidget {
  final int? orderId;

  const OrderDetailScreen({
    Key? key,
    this.orderId,
  }) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with OrderStatusBGColorHelper {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  OrderDetailBloc? orderDetailBloc;
  OrderDetail? orderDetail;
  bool isLoading = false;

  @override
  void initState() {
    orderDetailBloc = context.read<OrderDetailBloc>();
    orderDetailBloc?.add(OrderDetailFetchDataEvent(widget.orderId));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: BlocConsumer<OrderDetailBloc, OrderDetailBaseState>(
        listener: (BuildContext context, OrderDetailBaseState state) {
          if (state is CancelOrderState) {
            if (state.status == OrderDetailStatus.fail) {
              ShowMessage.errorNotification(state.error ?? "Failed to cancel", context);
            } else if (state.status == OrderDetailStatus.success) {
              ShowMessage.successNotification(
                  state.baseModel?.message ?? "Order Cancelled Successfully", context);
              
              // Refresh to update status text
              orderDetailBloc?.add(OrderDetailFetchDataEvent(widget.orderId));
            }
          } else if (state is ReOrderState) {
            if (state.status == OrderDetailStatus.success) {
              ShowMessage.successNotification(state.model?.message ?? "", context);
              Future.delayed(const Duration(seconds: 2)).then((value) {
                Navigator.pushNamed(context, cartScreen);
              });
            } else {
              ShowMessage.errorNotification(state.model?.message ?? "", context);
            }
          }
        },
        builder: (BuildContext context, OrderDetailBaseState state) {
          if (state is OrderDetailFetchDataState && state.status == OrderDetailStatus.success) {
            orderDetail = state.orderDetailModel;
          }
          
          return Scaffold(
            appBar: AppBar(
              centerTitle: false,
              title: Text(StringConstants.orderDetails.localized()),
            ),
            body: buildContainer(context, state),
          );
        },
      ),
    );
  }

  /// 🟢 FIX: Handle Type Conversion Safely (Object -> String -> Int)
  void _cancelOrderFunc() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cancel Order"),
        content: const Text("Are you sure you want to cancel this order?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              
              // 🟢 CRITICAL FIX HERE
              // 1. Check if widget.orderId exists.
              // 2. If not, safely convert orderDetail?.id to String, then parse to Int.
              int idToCancel = 0;
              
              if (widget.orderId != null) {
                idToCancel = widget.orderId!;
              } else if (orderDetail?.id != null) {
                idToCancel = int.tryParse(orderDetail!.id.toString()) ?? 0;
              }

              if (idToCancel != 0) {
                 orderDetailBloc?.add(CancelOrderEvent(idToCancel, ""));
              } else {
                 ShowMessage.errorNotification("Invalid Order ID", context);
              }
            },
            child: const Text("Yes, Cancel", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget buildContainer(BuildContext context, OrderDetailBaseState state) {
    if (state is OrderDetailInitialState) {
      return const OrderDetailLoader();
    }
    
    if (state is OrderDetailFetchDataState) {
      if (state.status == OrderDetailStatus.success) {
        orderDetail = state.orderDetailModel;
        return OrderDetailTile(
          orderId: widget.orderId,
          orderDetailModel: state.orderDetailModel,
          orderDetailBloc: orderDetailBloc,
          isLoading: isLoading,
          onCancelOrder: _cancelOrderFunc, // Pass function
        );
      }
      if (state.status == OrderDetailStatus.fail) {
        return ErrorMessage.errorMsg(state.error ?? "");
      }
    }

    if (state is CancelOrderState) {
      isLoading = false;
    }
    
    if (state is OnClickLoadingState) {
      isLoading = state.isReqToShowLoader ?? false;
    }

    return OrderDetailTile(
      orderId: widget.orderId,
      orderDetailModel: orderDetail,
      orderDetailBloc: orderDetailBloc,
      isLoading: isLoading,
      onCancelOrder: _cancelOrderFunc, // Pass function
    );
  }
}