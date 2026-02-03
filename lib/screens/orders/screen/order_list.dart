/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 * @author Webkul <support@webkul.com>
 * @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 * @license https://store.webkul.com/license.html
 * @link https://store.webkul.com/license.html
 */

import 'package:bagisto_app_demo/screens/orders/utils/index.dart';
import 'package:bagisto_app_demo/utils/prefetching_helper.dart';
import 'package:flutter/material.dart';

class OrdersList extends StatefulWidget {
  const OrdersList({Key? key, this.isFromDashboard}) : super(key: key);
  final bool? isFromDashboard;

  @override
  State<OrdersList> createState() => _OrdersListState();
}

class _OrdersListState extends State<OrdersList> with OrderStatusBGColorHelper {
  final orderId = TextEditingController();
  final total = TextEditingController();
  final endDateController = TextEditingController();
  final startDateController = TextEditingController();
  List<String>? status = [];
  int _currentStatus = 0;
  int page = 1;
  OrderListBloc? orderListBloc;
  String date = "";
  OrdersListModel? ordersListModel;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    orderListBloc = context.read<OrderListBloc>();
    orderListBloc?.add(FetchOrderListEvent(
        id: "", status: "", startDate: "", endDate: "", total: 0, page: 1));
    _scrollController.addListener(() {
      paginationFunction();
    });
    status = [
      StringConstants.all.localized(),
      StringConstants.pending.localized(),
      StringConstants.closed.localized(),
      StringConstants.canceled.localized(),
      StringConstants.processing.localized(),
      StringConstants.completed.localized(),
      StringConstants.pendingPayment.localized(),
      StringConstants.fraud.localized()
    ];

    _quickFilters = [
      {"label": StringConstants.all.localized(), "value": ""},
      {"label": StringConstants.pending.localized(), "value": "pending"},
      {"label": "Delivered", "value": "completed"},
      {"label": StringConstants.canceled.localized(), "value": "canceled"},
    ];
    super.initState();
  }

  int _selectedTabIndex = 0;
  List<Map<String, dynamic>> _quickFilters = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: (widget.isFromDashboard ?? false)
            ? null
            : AppBar(
                backgroundColor: Colors.white,
                elevation: 0.5,
                centerTitle: false,
                iconTheme: const IconThemeData(color: Colors.black),
                title: Text(
                  StringConstants.orders.localized(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  // 🟢 MODERN FILTER CAPSULE
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Center(
                      child: InkWell(
                        onTap: () {
                          showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (context) => _getOrderFilter());
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2)
                              )
                            ]
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.tune_rounded, size: 16, color: Colors.black),
                              SizedBox(width: 6),
                              Text(
                                "Filter", 
                                style: TextStyle(
                                  color: Colors.black, 
                                  fontWeight: FontWeight.w600, 
                                  fontSize: 13
                                )
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
        body: Column(
          children: [
            if (widget.isFromDashboard != true) _buildTopStatusTabs(),
            Expanded(child: _orderList(context)),
          ],
        ));
  }

  Widget _buildTopStatusTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(_quickFilters.length, (index) {
            bool isSelected = _selectedTabIndex == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                  page = 1; // Reset page
                });
                _fetchOrdersByStatus(_quickFilters[index]['value']);
              },
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF27C16B) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF27C16B) : Colors.transparent
                  )
                ),
                child: Text(
                  _quickFilters[index]['label'],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 14
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _fetchOrdersByStatus(String statusKey) {
     orderListBloc?.add(FetchOrderListEvent(
          id: "",
          status: statusKey,
          startDate: "",
          endDate: "",
          total: 0,
          page: 1));
  }

  ///bloc method
  _orderList(BuildContext context) {
    return BlocConsumer<OrderListBloc, OrderListBaseState>(
      listener: (BuildContext context, OrderListBaseState state) {},
      builder: (BuildContext context, OrderListBaseState state) {
        return buildContainer(context, state);
      },
    );
  }

  ///build container method
  Widget buildContainer(BuildContext context, OrderListBaseState state) {
    if (state is OrderInitialState) {
      return const OrderLoader();
    }
    if (state is FetchOrderListState) {
      if (state.status == OrderStatus.success) {
        if (page > 1) {
          ordersListModel?.data?.addAll(state.ordersListModel?.data ?? []);
          ordersListModel?.paginatorInfo = state.ordersListModel?.paginatorInfo;
        } else {
          ordersListModel = state.ordersListModel;
        }
        return _getOrdersList(ordersListModel);
      }
      if (state.status == OrderStatus.fail) {
        return EmptyDataView();
      }
    }
    return const SizedBox();
  }

  void paginationFunction() {
    if (_scrollController.offset ==
            _scrollController.position.maxScrollExtent &&
        ((ordersListModel?.paginatorInfo?.currentPage ?? 0) <
            (ordersListModel?.paginatorInfo?.lastPage ?? 0))) {
      page++;
      orderListBloc?.add(FetchOrderListEvent(
          id: "",
          status: _quickFilters[_selectedTabIndex]['value'],
          startDate: "",
          endDate: "",
          total: 0,
          page: page));
    }
  }

  ///to get order list
  _getOrdersList(OrdersListModel? ordersListModel) {
    if (ordersListModel == null) {
      return const NoDataFound();
    } else if ((ordersListModel.data ?? []).isEmpty) {
      return const EmptyDataView();
    } else {
      return RefreshIndicator(
        color: const Color(0xFF27C16B),
        onRefresh: () {
          return Future.delayed(const Duration(seconds: 1), () {
            orderListBloc?.add(FetchOrderListEvent(
                id: "",
                status: _quickFilters[_selectedTabIndex]['value'],
                startDate: "",
                endDate: "",
                total: 0,
                page: 1));
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ListView.separated(
            shrinkWrap: true,
            controller: _scrollController,
            itemBuilder: (BuildContext context, int itemIndex) {
              return OrdersListTile(
                data: ordersListModel.data?[itemIndex],
                reload: fetchOrder,
              );
            },
            separatorBuilder: (context, index) {
              return const SizedBox();
            },
            itemCount: (widget.isFromDashboard ?? false)
                ? ((ordersListModel.data?.length ?? 0) > 5)
                    ? 5
                    : ordersListModel.data?.length ?? 0
                : ordersListModel.data?.length ?? 0,
          ),
        ),
      );
    }
  }

  /// 🟢 MODERN FILTER SHEET UI (Blinkit Style)
  _getOrderFilter() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20)
        )
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    StringConstants.filterBy.localized(),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  TextButton(
                    onPressed: () {
                      _clearFilters();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      StringConstants.clear.localized().toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // 1. SEARCH SECTION
                  _buildSectionTitle(StringConstants.searchOrder.localized()),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildModernTextField(orderId, StringConstants.orderId.localized())),
                      const SizedBox(width: 12),
                      Expanded(child: _buildModernTextField(total, StringConstants.total.localized())),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 2. DATE SECTION
                  _buildSectionTitle(StringConstants.orderDate.localized()),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CommonDatePicker(
                            controller: startDateController,
                            hintText: "Start Date",
                            labelText: "", // Hidden label for cleaner look
                            isRequired: false,
                            save: 0,
                          ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                         child: CommonDatePicker(
                            controller: endDateController,
                            hintText: "End Date",
                            labelText: "",
                            isRequired: false,
                            save: 1,
                          ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. STATUS SECTION
                  _buildSectionTitle(StringConstants.orderStatus.localized()),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        decoration: const InputDecoration(border: InputBorder.none),
                        style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500),
                        items: status?.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            _currentStatus = status!.indexOf(value!);
                          });
                        },
                        value: status?[_currentStatus],
                    ),
                  ),
                ],
              ),
            ),

            // --- FOOTER BUTTONS ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.black12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        StringConstants.cancel.localized().toUpperCase(), 
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27C16B),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      onPressed: () {
                        _applyFilters();
                      },
                      child: Text(
                        StringConstants.submit.localized().toUpperCase(), 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10)
          ],
        ),
      ),
    );
  }

  // Helper for Section Titles
  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5
      ),
    );
  }

  // Helper for Modern Text Fields
  Widget _buildModernTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF5F5F5), // Soft Grey Background
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF27C16B), width: 1.5)
        )
      ),
    );
  }

  void _clearFilters() {
      page = 1;
      orderId.clear();
      total.clear();
      endDateController.clear();
      startDateController.clear();
      _currentStatus = 0;
      orderListBloc?.add(FetchOrderListEvent(
          id: "",
          status: "",
          startDate: "",
          endDate: "",
          total: 0,
          page: 1));
      Navigator.pop(context);
  }

  void _applyFilters() {
      page = 1;
      String startDate = startDateController.text != ""
          ? "${startDateController.text} 00:00:01"
          : startDateController.text;
      String endDate = endDateController.text != ""
          ? "${endDateController.text} 23:59:59"
          : endDateController.text;
      
      orderListBloc?.add(FetchOrderListEvent(
        id: orderId.text,
        startDate: startDate,
        endDate: endDate,
        status: status?[_currentStatus] == StringConstants.all.localized()
            ? ""
            : status?[_currentStatus],
        total: double.tryParse(total.text),
        page: page,
        isFilterApply: true,
      ));
      Navigator.pop(context);
  }

  fetchOrder() async {
    orderListBloc?.add(FetchOrderListEvent(
        id: "", status: _quickFilters[_selectedTabIndex]['value'], startDate: "", endDate: "", total: 0, page: 1));
  }
}