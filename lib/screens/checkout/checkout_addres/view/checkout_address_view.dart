import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagisto_app_demo/screens/checkout/utils/index.dart';
import 'package:bagisto_app_demo/utils/current_location_manager.dart';
import 'package:bagisto_app_demo/screens/home_page/widget/delivery_location_page.dart';
import 'package:bagisto_app_demo/screens/home_page/widget/address_details_sheet.dart';
import 'package:bagisto_app_demo/screens/checkout/checkout_addres/bloc/checkout_address_repository.dart';
import 'package:collection/collection.dart'; 

class CheckoutAddressView extends StatefulWidget {
  final Function(
      String? billingCompanyName,
      String? billingFirstName,
      String? billingLastName,
      String? billingAddress,
      String? billingAddress2,
      String? billingCountry,
      String? billingState,
      String? billingCity,
      String? billingPostCode,
      String? billingPhone,
      String? shippingCompanyName,
      String? shippingFirstName,
      String? shippingLastName,
      String? shippingAddress,
      String? shippingAddress2,
      String? shippingCountry,
      String? shippingState,
      String? shippingCity,
      String? shippingPostCode,
      String? shippingPhone, int billingAddressId, int shippingAddressId,
      AddressType addressType, bool isShippingSame
      )? callBack;

  const CheckoutAddressView({Key? key, this.callBack}) : super(key: key);

  @override
  State<CheckoutAddressView> createState() => _CheckoutAddressViewState();
}

class _CheckoutAddressViewState extends State<CheckoutAddressView> {
  AddressModel? _addressModel;
  AddressData? selectedAddress; 
  CheckOutBloc? checkOutBloc;
  String? _currentLocationAddress;
  String? email; 

  @override
  void initState() {
    super.initState();
    checkOutBloc = context.read<CheckOutBloc>();
    checkOutBloc?.add(CheckOutAddressEvent());
    
    email = appStoragePref.getCustomerEmail();
    _currentLocationAddress = CurrentLocationManager.address;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: BlocConsumer<CheckOutBloc, CheckOutBaseState>(
        listener: (context, state) {
          if (state is CheckOutAddressState && state.status == CheckOutStatus.success) {
            setState(() {
              _addressModel = state.addressModel;
              
              // 🟢 FIX: Robust Auto-Selection
              if (_addressModel?.addressData != null && _addressModel!.addressData!.isNotEmpty) {
                
                // 1. Try to maintain previous selection if valid
                if (selectedAddress != null) {
                   var exists = _addressModel!.addressData!.firstWhereOrNull((e) => e.id == selectedAddress!.id);
                   if (exists != null) selectedAddress = exists;
                }

                // 2. If no selection, try Default
                if (selectedAddress == null) {
                  selectedAddress = _addressModel?.addressData?.firstWhereOrNull((e) => e.isDefault == true);
                }

                // 3. Fallback to First Address (Safe Default)
                selectedAddress ??= _addressModel?.addressData?.first;
                
                // 🟢 DEBUG LOG
                debugPrint("✅ Auto-Selected Address ID: ${selectedAddress?.id}");
              }
            });

            // Trigger callback safely
            if (selectedAddress != null) {
               WidgetsBinding.instance.addPostFrameCallback((_) {
                 _passAddressToParent();
               });
            }
          }
          
          if (state is AddAddressState) {
            if (state.status == CheckOutStatus.success) {
               checkOutBloc?.add(CheckOutAddressEvent()); 
            } else if (state.status == CheckOutStatus.fail) {
               ShowMessage.errorNotification(state.error ?? "Failed to save address", context);
            }
          }
        },
        builder: (context, state) {
          if (state is CheckOutLoaderState) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0C831F)));
          }
          return _buildContent();
        },
      ),
    );
  }

  Widget _buildContent() {
    bool isEmpty = _addressModel?.addressData?.isEmpty ?? true;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Saved Addresses", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              TextButton.icon(
                onPressed: () => _openAddAddressSheet(), 
                icon: const Icon(Icons.add_circle_outline, size: 18, color: Color(0xFF0C831F)),
                label: const Text("Add New", style: TextStyle(color: Color(0xFF0C831F), fontWeight: FontWeight.bold)),
              )
            ],
          ),
          
          const SizedBox(height: 12),

          if (isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _addressModel!.addressData!.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 16),
              itemBuilder: (ctx, i) {
                var item = _addressModel!.addressData![i];
                return _buildAddressCard(item);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.location_off_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text("No saved addresses", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _openAddAddressSheet(),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0C831F)),
              child: const Text("Add Address Now", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

 Widget _buildAddressCard(var item) {
    bool isSelected = selectedAddress?.id == item.id;
    
    // Clean up the address string (Remove brackets if API sends them)
    String cleanAddress = item.address1?.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '') ?? '';

    return InkWell(
      onTap: () {
        setState(() { selectedAddress = item; });
        debugPrint("👉 User Tapped Address ID: ${item.id}");
        _passAddressToParent();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0C831F) : Colors.transparent, 
            width: 2
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio Button
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? const Color(0xFF0C831F) : Colors.grey[400],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            
            // Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🟢 "DELIVER TO" LABEL
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.companyName != null && item.companyName!.isNotEmpty 
                          ? item.companyName!.toUpperCase() // e.g., HOME / WORK
                          : "DELIVER TO",
                      style: TextStyle(color: Colors.grey[700], fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),

                  // Name
                  Text(
                    "${item.firstName} ${item.lastName}",
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  
                  // 🟢 FULL ADDRESS (Max 3 lines)
                  Text(
                    cleanAddress, 
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[800], fontSize: 14, height: 1.4),
                  ),
                  
                  // City & Pincode
                  Text(
                    "${item.city}, ${item.postcode}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  
                  // Phone
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 14, color: Colors.black54),
                      const SizedBox(width: 4),
                      Text(
                        item.phone ?? "", 
                        style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddAddressSheet({String? initialAddress}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: AddressDetailsSheet(
          initialArea: initialAddress,
          initialPincode: CurrentLocationManager.pincode,
          initialCity: CurrentLocationManager.city,
          initialState: CurrentLocationManager.state,
        ),
      ),
    ).then((value) {
      if (value != null && value is Map) {
         String fName = value['firstName'] ?? "Guest";
         String lName = value['lastName'] ?? "User";
         if (lName.isEmpty) lName = "User";

         String phone = value['phone'] ?? "0000000000";
         String safeEmail = email ?? "$phone@mobile.com";

         // 🟢 FIX: Combine ALL fields so nothing is lost
         String house = value['flatHouseBuilding'] ?? '';
         String area = value['area'] ?? '';
         String landmark = value['landmark'] ?? '';

         List<String> addressParts = [];
         if (house.isNotEmpty) addressParts.add(house);
         if (area.isNotEmpty) addressParts.add(area);
         if (landmark.isNotEmpty) addressParts.add("Near $landmark");

         // Join them with commas (e.g., "Flat 4B, MG Road, Near Park")
         String fullAddress1 = addressParts.join(", ");
         
         // Fallback if empty
         if (fullAddress1.trim().isEmpty) fullAddress1 = area;
         
         checkOutBloc?.add(AddAddressEvent(
             address1: fullAddress1, // 🟢 Sends the Full Address now
             address2: "",           // We already combined it above, so leave this empty
             city: value['city'] ?? "Chennai", 
             state: value['state'] ?? "Tamil Nadu", 
             country: "IN", 
             postCode: value['pincode'] ?? "600001", 
             phone: phone, 
             firstName: fName,
             lastName: lName,
             email: safeEmail 
         ));
      }
    });
  }

void _passAddressToParent() {
    if (widget.callBack != null && selectedAddress != null) {
      
      // 🟢 DEBUG: Print what we are sending
      debugPrint("🚀 Sending Address ID to Checkout: ${selectedAddress!.id}");

      // 🟢 FIX: Ensure ID is parsed safely from String/Int
      int id = 0;
      try {
        id = int.parse(selectedAddress!.id.toString());
      } catch (_) {
        id = 0;
      }

      widget.callBack!(
          selectedAddress!.companyName,
          selectedAddress!.firstName,
          selectedAddress!.lastName,
          selectedAddress!.address1,
          selectedAddress!.address1,
          selectedAddress!.country ?? selectedAddress!.countryName,
          selectedAddress!.state ?? selectedAddress!.stateName,
          selectedAddress!.city,
          selectedAddress!.postcode,
          selectedAddress!.phone,
          selectedAddress!.companyName,
          selectedAddress!.firstName,
          selectedAddress!.lastName,
          selectedAddress!.address1,
          selectedAddress!.address1,
          selectedAddress!.country ?? selectedAddress!.countryName,
          selectedAddress!.state ?? selectedAddress!.stateName,
          selectedAddress!.city,
          selectedAddress!.postcode,
          selectedAddress!.phone,
          id, // 🟢 THIS MUST BE THE CORRECT ID (e.g., 478)
          id, // 🟢 THIS MUST BE THE CORRECT ID
          AddressType.both,
          true
      );
    } else {
      debugPrint("⚠️ No Address Selected to Pass!");
    }
  }
}