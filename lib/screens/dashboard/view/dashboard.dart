import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagisto_app_demo/screens/dashboard/utils/index.dart';
import 'package:bagisto_app_demo/screens/wishList/bloc/wishlist_bloc.dart';
import 'package:bagisto_app_demo/screens/wishList/bloc/wishlist_repository.dart';
import 'package:bagisto_app_demo/screens/wishList/view/wishlist_screen.dart';

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

  Widget addressScreen = BlocProvider(
      create: (context) => AddressBloc(AddressRepositoryImp()),
      child: const AddressScreen(isFromDashboard: true));

  // 🟢 NEW: Wishlist Screen (Moved from Sidebar)
  Widget wishlistScreen = BlocProvider(
      create: (context) => WishListBloc(WishListRepositoryImp()), 
      child: const WishListScreen()); // Verify constructor args if any

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
                child: addressScreen,
                btnText: addressIsEmpty
                    ? StringConstants.addNewAddress.localized()
                    : StringConstants.manageAddress.localized(),
                icon: addressIsEmpty ? Icons.add_location_alt_rounded : Icons.edit_location_alt_rounded,
                onPressed: () {
                  addressIsEmpty
                      ? Navigator.pushNamed(context, addAddressScreen,
                          arguments: AddressNavigationData(
                              isEdit: false, addressModel: null, isCheckout: false))
                      : Navigator.of(context).pushNamed(addressList);
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
}