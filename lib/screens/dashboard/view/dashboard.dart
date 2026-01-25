import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagisto_app_demo/screens/dashboard/utils/index.dart';
import 'package:bagisto_app_demo/screens/wishList/bloc/wishlist_bloc.dart';
import 'package:bagisto_app_demo/screens/wishList/bloc/wishlist_repository.dart';
import 'package:bagisto_app_demo/screens/wishList/view/wishlist_screen.dart';
// 🟢 NEW IMPORTS
import 'package:bagisto_app_demo/screens/address_list/bloc/address_event.dart'; // 🟢 FIX: Import Event
import 'package:bagisto_app_demo/screens/home_page/widget/address_details_sheet.dart';
import 'package:bagisto_app_demo/utils/current_location_manager.dart';
import 'package:bagisto_app_demo/screens/add_edit_address/bloc/add_edit_address_bloc.dart';
import 'package:bagisto_app_demo/screens/add_edit_address/bloc/add_edit_address_repository.dart';
import 'package:bagisto_app_demo/screens/add_edit_address/bloc/add_edit_address_state.dart';
import 'package:bagisto_app_demo/screens/add_edit_address/bloc/add_edit_address_event.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  bool addressIsEmpty = false;

  // 🟢 LOGIC: Keeping your existing BlocProviders intact
  Widget orderScreen = BlocProvider(
      create: (context) => OrderListBloc(repository: OrderListRepositoryImp()),
      child: const OrdersList(isFromDashboard: true));

  Widget reviewsScreen = BlocProvider(
      create: (context) =>
          ReviewsBloc(repository: ReviewsRepositoryImp(), context: context),
      child: const ReviewsScreen(isFromDashboard: true));



  // 🟢 NEW: Wishlist Screen (Moved from Sidebar)
  Widget wishlistScreen = BlocProvider(
      create: (context) => WishListBloc(WishListRepositoryImp()), 
      child: const WishListScreen()); // Verify constructor args if any
  
  // 🟢 Address Bloc Reference for Refreshing
  AddressBloc? _addressBloc;
  Widget? addressScreen;

  @override
  void initState() {
    super.initState();
    // Initialize AddressBloc here to access it later
    _addressBloc = AddressBloc(AddressRepositoryImp());
    addressScreen = BlocProvider.value( // Use .value
      value: _addressBloc!,
      child: const AddressScreen(isFromDashboard: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    addressIsEmpty = appStoragePref.getAddressData();

    return DefaultTabController(
      length: 4, // 🟢 NOW 4 TABS
      child: Scaffold(
        backgroundColor: Colors.white, // Clean white background
        // 🟢 Remove Header Title as requested
        appBar: AppBar(
          toolbarHeight: 0, 
          elevation: 0,
          backgroundColor: Colors.white,
        ),
        body: dashboardView(),
      ),
    );
  }

  Widget dashboardView() {
    return Column(
      children: [
        // 1. Header (Make sure you updated dashboard_header_view.dart as well)
        const DashboardHeaderView(),

        // 2. Thick Divider for clear separation
        Container(height: 8, color: Colors.grey.shade100),

        // 3. Modern Tab Bar (Blinkit Style)
        Container(
          color: Colors.white,
          width: double.infinity,
          child: TabBar(
            isScrollable: false,
            labelColor: const Color(0xFF2E7D32), // Active: Dark Green
            unselectedLabelColor: Colors.grey.shade500, // Inactive: Grey
            indicatorColor: const Color(0xFF2E7D32), // Indicator: Green
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700, 
              fontSize: 13, 
              letterSpacing: 0.5
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600, 
              fontSize: 13
            ),
            tabs: [
              Tab(text: StringConstants.recentOrders.localized()),
              Tab(text: StringConstants.addressTitle.localized()),
              Tab(text: StringConstants.reviewsTitle.localized()),
              Tab(text: StringConstants.wishlist.localized()), // 🟢 NEW TAB
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

        // 4. Tab Content Area
        Expanded(
          child: TabBarView(
            children: [
              // --- Orders Tab ---
              _buildTabContent(
                child: orderScreen,
                btnText: "", 
                icon: Icons.abc, // Dummy
                onPressed: () {},
                showButton: false, // 🟢 HIDE BUTTON
              ),

              // --- Address Tab ---
              _buildTabContent(
                child: addressScreen!, // Use nullable widget
                btnText: addressIsEmpty
                    ? StringConstants.addNewAddress.localized()
                    : StringConstants.manageAddress.localized(),
                icon: addressIsEmpty ? Icons.add_location_alt_rounded : Icons.edit_location_alt_rounded,
                onPressed: () {
                  if (addressIsEmpty) {
                    _openAddAddressSheet(); // 🟢 NEW FORM logic
                  } else {
                    Navigator.of(context).pushNamed(addressList);
                  }
                },
              ),

              // --- Reviews Tab ---
              _buildTabContent(
                child: reviewsScreen,
                btnText: "",
                icon: Icons.abc, // Dummy
                onPressed: () {},
                showButton: false, // 🟢 HIDE BUTTON
              ),

              // --- Wishlist Tab ---
              _buildTabContent(
                child: wishlistScreen, 
                btnText: "", // Text doesn't matter if hidden
                icon: Icons.favorite_border_rounded,
                onPressed: () {},
                showButton: false, // 🟢 HIDE BUTTON
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 🟢 Helper Widget: Wraps Tab Content + Modern Bottom Button
  Widget _buildTabContent({
    required Widget child,
    required String btnText,
    required IconData icon,
    required VoidCallback onPressed,
    bool showButton = true, // 🟢 Default to true
  }) {
    return Column(
      children: [
        // The List Content (Orders/Address/Reviews)
        Expanded(child: child),
        
        // Modern Bottom Button Container
        if (showButton)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 50, // Taller, easier to tap
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32), // Blinkit Green
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Modern rounded corners
                ),
              ),
              onPressed: onPressed,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    btnText.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700, 
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, size: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  // 🟢 NEW: Open the Modern Address Sheet (Same as Checkout)
  void _openAddAddressSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: AddressDetailsSheet(
          initialArea: "",
          initialPincode: CurrentLocationManager.pincode,
          initialCity: CurrentLocationManager.city,
          initialState: CurrentLocationManager.state,
        ),
      ),
    ).then((value) {
      if (value != null && value is Map) {
         _saveNewAddress(value);
      }
    });
  }

  // 🟢 NEW: Handle API Call to Save Address
  void _saveNewAddress(Map data) {
    // 1. Create Repository & Bloc
    final repo = AddEditAddressRepositoryImp();
    final bloc = AddEditAddressBloc(repo);

    // 2. Prepare Data
    String fName = data['firstName'] ?? "User";
    String lName = data['lastName'] ?? ".";
    String phone = data['phone'] ?? "";
    
    // Combine Address Parts
    String house = data['flatHouseBuilding'] ?? '';
    String area = data['area'] ?? '';
    String landmark = data['landmark'] ?? '';
    List<String> parts = [];
    if (house.isNotEmpty) parts.add(house);
    if (area.isNotEmpty) parts.add(area);
    if (landmark.isNotEmpty) parts.add("Near $landmark");
    String fullAddress = parts.join(", ");
    if (fullAddress.trim().isEmpty) fullAddress = area;
    
    String stateName = data['state'] ?? "";
    String stateCode = _mapStateToCode(stateName);

    // 3. Dispatch Event
    bloc.add(FetchAddAddressEvent(
         firstName: fName,
         lastName: lName,
         phone: phone,
         address: fullAddress, 
         country: "IN",
         state: stateCode,
         city: data['city'],
         postCode: data['pincode'],
         isDefault: false
    ));

    // 4. Show Loader & Listen for Result
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: BlocConsumer<AddEditAddressBloc, AddEditAddressBaseState>(
          listener: (context, state) {
            if (state is FetchAddAddressState && state.status == AddEditStatus.success) {
               Navigator.pop(ctx); 
               
               // 🟢 REFRESH ADDRESS LIST
               _addressBloc?.add(FetchAddressEvent());
               setState(() { addressIsEmpty = false; }); // Optimistic update

               ShowMessage.successNotification("Address Added Successfully", context);
            }
            else if (state is FetchAddAddressState && state.status == AddEditStatus.fail) {
               Navigator.pop(ctx);
               String err = state.error ?? "Failed";
               if (err.contains("state")) err = "Invalid State. Try: TN, KA, KL, DL, MH";
               ShowMessage.errorNotification(err, context);
            }
          },
          builder: (context, state) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
          },
        ),
      ),
    );
  }

  // 🟢 HELPER: Map State Name to Code
  String _mapStateToCode(String stateName) {
    String clean = stateName.trim().toUpperCase();
    Map<String, String> codes = {
      "TAMIL NADU": "TN", "TAMILNADU": "TN",
      "KERALA": "KL", "KARNATAKA": "KA",
      "ANDHRA PRADESH": "AP", "TELANGANA": "TG",
      "MAHARASHTRA": "MH", "DELHI": "DL",
      "NEW DELHI": "DL", "PUDUCHERRY": "PY",
      "WEST BENGAL": "WB", "UTTAR PRADESH": "UP",
      "MADHYA PRADESH": "MP", "GUJARAT": "GJ",
      "RAJASTHAN": "RJ", "PUNJAB": "PB",
      "HARYANA": "HR", "BIHAR": "BR",
      "ODISHA": "OR", "JHARKHAND": "JH",
      "CHHATTISGARH": "CT", "ASSAM": "AS",
      "UTTARAKHAND": "UK", "HIMACHAL PRADESH": "HP",
      "JAMMU AND KASHMIR": "JK", "GOA": "GA",
      "TRIPURA": "TR", "MEGHALAYA": "ML",
      "MANIPUR": "MN", "NAGALAND": "NL",
      "ARUNACHAL PRADESH": "AR", "MIZORAM": "MZ",
      "SIKKIM": "SK"
    };
    return codes[clean] ?? stateName;
  }
}
