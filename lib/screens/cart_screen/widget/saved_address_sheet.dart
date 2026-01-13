import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagisto_app_demo/screens/checkout/utils/index.dart';
import 'package:bagisto_app_demo/screens/home_page/widget/delivery_location_page.dart';
import 'package:bagisto_app_demo/screens/home_page/widget/address_details_sheet.dart';

class SavedAddressSheet extends StatefulWidget {
  const SavedAddressSheet({Key? key}) : super(key: key);

  @override
  State<SavedAddressSheet> createState() => _SavedAddressSheetState();
}

class _SavedAddressSheetState extends State<SavedAddressSheet> {
  CheckOutBloc? _bloc;

  @override
  void initState() {
    _bloc = context.read<CheckOutBloc>();
    _bloc?.add(CheckOutAddressEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckOutBloc, CheckOutBaseState>(
      builder: (context, state) {
        
        // 1. Loading
        if (state is CheckOutLoaderState) {
          return _buildContainer(
            context, 
            const Center(child: CircularProgressIndicator(color: Color(0xFF0C831F)))
          );
        }

        // 2. Error
        if (state is CheckOutAddressState && state.status == CheckOutStatus.fail) {
           return _buildContainer(
            context, 
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 8),
                  Text("Error: ${state.error}", textAlign: TextAlign.center),
                  TextButton(
                    onPressed: () => _bloc?.add(CheckOutAddressEvent()),
                    child: const Text("Retry"),
                  )
                ],
              ),
            )
          );
        }

        // 3. Success
        if (state is CheckOutAddressState && state.status == CheckOutStatus.success) {
          var addressData = state.addressModel?.addressData ?? [];

          if (addressData.isEmpty) {
             return _buildContainer(context, const Center(child: Text("No saved addresses")));
          }

          return _buildContainer(
            context,
            ListView.separated(
              itemCount: addressData.length,
              separatorBuilder: (ctx, i) => const Divider(),
              itemBuilder: (ctx, i) {
                var address = addressData[i];
                
                // Safe String Handling
                String rawAddr = address.address1.toString();
                String cleanAddress = rawAddr
                    .replaceAll("[", "")
                    .replaceAll("]", "")
                    .replaceAll("\"", "");

                return InkWell(
                  onTap: () => Navigator.pop(context, address),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, color: Colors.grey, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${address.firstName} ${address.lastName}", 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "$cleanAddress, ${address.city}, ${address.postcode}",
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Phone: ${address.phone}",
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (address.isDefault == true)
                          const Icon(Icons.check_circle, color: Color(0xFF0C831F), size: 20)
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }
        
        // Initial Default
        return _buildContainer(context, const Center(child: CircularProgressIndicator(color: Color(0xFF0C831F))));
      },
    );
  }

  Widget _buildContainer(BuildContext context, Widget content) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Select Delivery Address", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const Divider(),
          InkWell(
            onTap: () => _addNewAddress(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(children: const [
                Icon(Icons.add, color: Color(0xFF0C831F)), 
                SizedBox(width: 8), 
                Text("Add New Address", style: TextStyle(color: Color(0xFF0C831F), fontWeight: FontWeight.bold))
              ]),
            ),
          ),
          const Divider(),
          Expanded(child: content),
        ],
      ),
    );
  }

  // 🟢 THIS IS THE CRITICAL FIX
  void _addNewAddress(BuildContext ctx) async {
    final mapResult = await Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryLocationPage()));
    
    if (mapResult != null && mapResult is Map) {
      if (!mounted) return;
      
      // 1. Get Data from Form
      final newAddressData = await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => FractionallySizedBox(
          heightFactor: 0.85,
          child: AddressDetailsSheet(initialArea: mapResult['address']),
        ),
      );
      
      // 2. If data exists, Send it to Server
      if (mounted && newAddressData != null && newAddressData is Map) {
        
        // Construct Address1 from parts if needed
        String addr1 = newAddressData['flatHouseBuilding'] ?? "";
        if (newAddressData['area'] != null) {
          addr1 += ", " + newAddressData['area'];
        }

        // Dispatch Event to Save
        _bloc?.add(AddAddressEvent(
           firstName: newAddressData['firstName'] ?? "",
           lastName: newAddressData['lastName'] ?? "",
           phone: newAddressData['phone'] ?? "",
           email: newAddressData['email'] ?? "",
           address1: addr1, 
           address2: newAddressData['address2'] ?? "",
           city: newAddressData['city'] ?? "",
           state: newAddressData['state'] ?? "",
           country: newAddressData['country'] ?? "IN",
           postCode: newAddressData['postCode'] ?? "",
        ));
      }
    }
  }
}