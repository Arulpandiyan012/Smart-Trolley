import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Screens
import 'package:bagisto_app_demo/screens/home_page/home_page.dart';
import 'package:bagisto_app_demo/screens/categories_screen/sidebar_category_screen.dart'; 
import 'package:bagisto_app_demo/screens/orders/screen/order_list.dart'; // Correct Order Screen
import 'package:bagisto_app_demo/screens/dashboard/view/dashboard.dart'; // Correct Dashboard Screen

// Logic Imports
import 'package:bagisto_app_demo/screens/categories_screen/bloc/categories_bloc.dart';
import 'package:bagisto_app_demo/screens/categories_screen/bloc/categories_repository.dart';
import 'package:bagisto_app_demo/screens/categories_screen/utils/index.dart';

// Orders Logic Imports
import 'package:bagisto_app_demo/screens/orders/bloc/order_list_bloc.dart';
import 'package:bagisto_app_demo/screens/orders/bloc/order_list_repo.dart';

import 'package:bagisto_app_demo/utils/route_constants.dart';
import 'package:bagisto_app_demo/utils/app_global_data.dart';
import 'package:bagisto_app_demo/utils/shared_preference_helper.dart';

class BottomNavScaffold extends StatefulWidget {
  const BottomNavScaffold({super.key});
  @override
  State<BottomNavScaffold> createState() => _BottomNavScaffoldState();
}

class _BottomNavScaffoldState extends State<BottomNavScaffold> {
  int _index = 0;

  // 🟢 FIXED LIST: Only 4 pages (removed the Cart placeholder)
  late final List<Widget> _pages = [
    // Index 0: Home
    const HomeScreen(),
    
    // Index 1: Categories
    BlocProvider(
      create: (context) => CategoryBloc(CategoriesRepo()), 
      child: const SidebarCategoryScreen(),
    ),

    // Index 2: Orders (This will now correctly show on Tab 3)
    BlocProvider(
      create: (context) => OrderListBloc(
        repository: OrderListRepositoryImp()
      ),
      child: const OrdersList(isFromDashboard: false),
    ),

    // Index 3: Dashboard/Profile (This will now correctly show on Tab 4)
    const DashboardScreen(),
  ];

  void _onTabTapped(int visualIndex) {
    if (visualIndex == 2) {
      // 🛒 Cart Tab (Middle): Pushes a new screen, doesn't change bottom tabs
      Navigator.pushNamed(context, cartScreen);
    } else {
      // 🔄 Switch Tab
      // Logic: If index is > 2 (Orders or Profile), subtract 1 to skip the Cart button
      // Tab 0 (Home) -> Index 0
      // Tab 1 (Cat)  -> Index 1
      // Tab 3 (Ord)  -> Index 2
      // Tab 4 (Prof) -> Index 3
      setState(() {
        _index = (visualIndex > 2) ? visualIndex - 1 : visualIndex; 
      });
    }
  }

  // Helper to highlight the correct bottom bar icon based on the current page
  int _getCurrentVisualIndex() {
    if (_index == 0) return 0; // Home
    if (_index == 1) return 1; // Categories
    if (_index == 2) return 3; // Orders (Skip Cart at 2)
    if (_index == 3) return 4; // Profile
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: StreamBuilder<int>(
        stream: GlobalData.cartCountController.stream.cast<int>(),
        builder: (context, snapshot) {
          final count = snapshot.data ?? appStoragePref.getCartCount();
          final visualIndex = _getCurrentVisualIndex();

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 65,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _navItem(0, visualIndex, Icons.home_outlined, Icons.home, "Home"),
                    _navItem(1, visualIndex, Icons.grid_view_outlined, Icons.grid_view_rounded, "Categories"),
                    _cartNavItem(2, count),
                    _navItem(3, visualIndex, Icons.receipt_long_outlined, Icons.receipt_long, "Orders"),
                    _navItem(4, visualIndex, Icons.person_outline, Icons.person, "Profile"),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _navItem(int buttonIndex, int currentVisualIndex, IconData iconOutlined, IconData iconFilled, String label) {
    final isSelected = currentVisualIndex == buttonIndex;
    const Color activeColor = Color(0xFFBDB76B); // Khaki Color

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(buttonIndex),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isSelected)
              Positioned(
                top: 0,
                child: Container(
                  width: 40,
                  height: 3,
                  decoration: const BoxDecoration(
                    color: activeColor, 
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
                  ),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? iconFilled : iconOutlined,
                  size: 24,
                  color: isSelected ? activeColor : Colors.grey[600], 
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? activeColor : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartNavItem(int index, int count) {
    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: count > 0,
              label: Text('$count'),
              backgroundColor: const Color(0xFFD32F2F),
              textColor: Colors.white,
              child: Icon(Icons.shopping_cart_outlined, size: 24, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              "Cart",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}