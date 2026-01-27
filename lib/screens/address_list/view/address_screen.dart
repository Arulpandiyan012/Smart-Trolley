/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 * @author Webkul <support@webkul.com>
 * @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 * @license https://store.webkul.com/license.html
 * @link https://store.webkul.com/license.html
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagisto_app_demo/screens/address_list/utils/index.dart';
import 'package:bagisto_app_demo/screens/categories_screen/utils/index.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key, this.isFromDashboard});
  final bool? isFromDashboard;

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

AddressModel? _addressModel;

class _AddressScreenState extends State<AddressScreen> {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  bool isLoading = false;
  AddressBloc? addressBloc;

  @override
  void initState() {
    addressBloc = context.read<AddressBloc>();
    addressBloc?.add(FetchAddressEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: Colors.white, // Clean background
        appBar: (widget.isFromDashboard ?? false)
            ? null
            : AppBar(
                centerTitle: false,
                elevation: 0.5,
                backgroundColor: Colors.white,
                title: Text(
                  StringConstants.address.localized(),
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
                iconTheme: const IconThemeData(color: Colors.black),
              ),
        body: _addressBloc(context),
      ),
    );
  }

  ///ADDRESS BLOC CONTAINER///
  BlocConsumer<AddressBloc, AddressBaseState> _addressBloc(BuildContext context) {
    return BlocConsumer<AddressBloc, AddressBaseState>(
      listener: (BuildContext context, AddressBaseState state) {
        if (state is FetchAddressState) {
          if (state.status == AddressStatus.fail) {
          } else if (state.status == AddressStatus.success) {
            _addressModel = state.addressModel;
          }
        }
        if (state is RemoveAddressState) {
          if (state.status == AddressStatus.fail) {
            ShowMessage.errorNotification(state.error ?? "", context);
          } else if (state.status == AddressStatus.success) {
            ShowMessage.successNotification(
                state.response?.message ?? "", context);
          }
        }
        if (state is SetDefaultAddressState) {
          addressBloc?.add(FetchAddressEvent());
          if (state.status == AddressStatus.fail) {
            ShowMessage.errorNotification(state.message ?? "", context);
          } else if (state.status == AddressStatus.success) {
            ShowMessage.successNotification(
                state.addressModel?.message ?? "", context);
          }
        }
      },
      builder: (BuildContext context, AddressBaseState state) {
        return buildUI(context, state);
      },
    );
  }

  ///ADDRESS UI METHODS///
  Widget buildUI(BuildContext context, AddressBaseState state) {
    if (state is FetchAddressState) {
      isLoading = false;
      if (state.status == AddressStatus.success) {
        _addressModel == null ? _addressModel = state.addressModel : null;
        return _addressList(state.addressModel!);
      }
      if (state.status == AddressStatus.fail) {
        return const EmptyDataView();
      }
    }
    if (state is ShowLoaderState) {
      isLoading = true;
    }
    if (state is InitialAddressState) {
      return AddressLoader(
        isFromDashboard: widget.isFromDashboard,
      );
    }
    if (state is RemoveAddressState) {
      if (state.status == AddressStatus.success) {
        var customerId = state.customerDeletedId;
        if (_addressModel?.addressData != null) {
          _addressModel?.addressData!.removeWhere(
              (element) => element.id.toString() == customerId.toString());
          return _addressList(_addressModel);
        } else {}
      }
    }

    return _addressList(_addressModel);
  }

  /// 🟢 MODERN ADDRESS LIST
  StatelessWidget _addressList(AddressModel? addressModel) {
    if (addressModel == null) {
      appStoragePref.setAddressData(true);
      return const EmptyDataView(assetPath: AssetConstants.emptyAddress);
    } else if (addressModel.addressData?.isEmpty ?? false) {
      appStoragePref.setAddressData(true);
      return AddNewAddressButton(
        reload: fetchAddressData,
        isFromDashboard: widget.isFromDashboard,
      );
    } else {
      appStoragePref.setAddressData(false);
      return SafeArea(
        child: Column(
          children: [
            // 🟢 "Add New Address" Button (If not in dashboard)
            if (!(widget.isFromDashboard ?? false))
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, addAddressScreen,
                          arguments: AddressNavigationData(
                              isEdit: false, addressModel: null, isCheckout: false))
                          .then((value) => fetchAddressData());
                    },
                    icon: const Icon(Icons.add, color: Color(0xFF2E7D32)),
                    label: Text(
                      StringConstants.addNewAddress.localized().toUpperCase(),
                      style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),

            // 🟢 List of Addresses
            Flexible(
              child: RefreshIndicator(
                color: const Color(0xFF2E7D32),
                onRefresh: () {
                  return Future.delayed(const Duration(seconds: 1), () {
                    fetchAddressData();
                  });
                },
                child: Stack(
                  children: [
                    ListView.separated(
                        padding: const EdgeInsets.all(16),
                        separatorBuilder: (ctx, index) => const SizedBox(height: 16),
                        shrinkWrap: true,
                        itemCount: (widget.isFromDashboard ?? false)
                            ? ((addressModel.addressData?.length ?? 0) > 5)
                                ? 5
                                : addressModel.addressData?.length ?? 0
                            : addressModel.addressData?.length ?? 0,
                        itemBuilder: (context, index) {
                          final data = addressModel.addressData?[index];
                          // 🟢 Using the new Custom Card
                          return _buildModernAddressCard(data);
                        }),
                    Visibility(visible: isLoading, child: const Loader())
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  /// 🟢 NEW: Modern Address Card Widget (Blinkit Style)
  Widget _buildModernAddressCard(var data) {
    if (data == null) return const SizedBox();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and Icon
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Color(0xFF2E7D32), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "${data.firstName ?? ""} ${data.lastName ?? ""}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Address Details
          Padding(
            padding: const EdgeInsets.only(left: 36), // Align with text above
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    data.address1,
                    data.city,
                    data.state,
                    data.postcode,
                    data.countryName
                  ].where((s) => s != null && s.isNotEmpty).join(", "),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Phone: ${data.phone ?? "N/A"}",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),

          // Action Buttons (Edit / Remove)
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, addAddressScreen,
                        arguments: AddressNavigationData(
                            isEdit: true,
                            addressModel: data,
                            isCheckout: false))
                        .then((value) => fetchAddressData());
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2E7D32)),
                  label: const Text("EDIT", style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                ),
              ),
              Container(width: 1, height: 24, color: Colors.grey[300]), // Vertical Divider
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _confirmDelete(data.id),
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                  label: const Text("REMOVE", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🟢 Delete Confirmation Dialog
  void _confirmDelete(var addressId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Address?"),
        content: const Text("Are you sure you want to remove this address?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              addressBloc?.add(RemoveAddressEvent(addressId));
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> fetchAddressData() async {
    AddressBloc addressBloc = context.read<AddressBloc>();
    addressBloc.add(FetchAddressEvent());
  }
}