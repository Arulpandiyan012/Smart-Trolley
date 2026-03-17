/*
 *   Webkul Software.
 *   @package Mobikul Application Code.
 *   @Category Mobikul
 *   @author Webkul <support@webkul.com>
 *   @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 *   @license https://store.webkul.com/license.html
 *   @link https://store.webkul.com/license.html
 */


import 'package:bagisto_app_demo/screens/orders/utils/index.dart';

abstract class OrderListRepository {
  Future<OrdersListModel> getOrderList(String? id, String? startDate,
      String? endDate, String? status, double? total, int? page,bool? isFilterApply);
}

class OrderListRepositoryImp implements OrderListRepository {
  @override
  Future<OrdersListModel> getOrderList(String? id, String? startDate,
      String? endDate, String? status, double? total, int? page,bool? isFilterApply) async {
    OrdersListModel? ordersListModel;

    try {
      // 🟢 NEW: Handle client-side filtering for multiple statuses
      // Backend PHP api doesn't support comma-separated status. 
      // We fetch ALL and filter locally when a multi-status filter is active.
      bool isMultiStatus = status != null && status.contains(",");
      String? apiStatus = isMultiStatus ? "" : status;

      ordersListModel = await ApiClient()
          .getOrderList(id, startDate, endDate, apiStatus, total, page, isFilterApply);

      if (isMultiStatus && ordersListModel?.data != null) {
        debugPrint("🎯 OrderListRepo: Filtering orders locally for multi-status: $status");
        List<String> allowedStatuses = status!.split(",").map((e) => e.trim().toLowerCase()).toList();
        ordersListModel!.data = ordersListModel.data!.where((order) {
           String s = order.status?.toLowerCase() ?? "";
           return allowedStatuses.contains(s);
        }).toList();
      }
    } catch (error, stacktrace) {
      debugPrint("Error --> $error");
      debugPrint("StackTrace --> $stacktrace");
    }
    return ordersListModel ?? OrdersListModel(data: []);
  }
}
