import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Screens
import 'package:bagisto_app_demo/screens/home_page/home_page.dart';
import 'package:bagisto_app_demo/screens/categories_screen/sidebar_category_screen.dart'; 
import 'package:bagisto_app_demo/screens/orders/screen/order_list.dart'; 
import 'package:bagisto_app_demo/screens/dashboard/view/dashboard.dart'; 
// 🟢 NEW: Import Cart Screen & Logic
import 'package:bagisto_app_demo/screens/cart_screen/cart_screen.dart';
import 'package:bagisto_app_demo/screens/cart_screen/utils/cart_index.dart'; 

// Logic Imports
import 'package:bagisto_app_demo/screens/categories_screen/bloc/categories_bloc.dart';
import 'package:bagisto_app_demo/screens/categories_screen/bloc/categories_repository.dart';
import 'package:bagisto_app_demo/screens/orders/bloc/order_list_bloc.dart';
import 'package:bagisto_app_demo/screens/orders/bloc/order_list_repo.dart';

import 'package:bagisto_app_demo/utils/app_global_data.dart';
import 'package:bagisto_app_demo/utils/shared_preference_helper.dart';

class BottomNavScaffold extends StatefulWidget {
  const BottomNavScaffold({super.key});
  @override
  State<BottomNavScaffold> createState() => _BottomNavScaffoldState();
}

class _BottomNavScaffoldState extends State<BottomNavScaffold> {
  int _index = 0;

  // 🟢 UPDATED: CartScreen is now Index 2
  late final List<Widget> _pages = [
    // 0: Home
    const HomeScreen(),
    
    // 1: Categories
    BlocProvider(
      create: (context) => CategoryBloc(CategoriesRepo()), 
      child: const SidebarCategoryScreen(),
    ),

    // 2: 🛒 Cart (Now a proper Tab)
    BlocProvider(
      create: (context) => CartScreenBloc(CartScreenRepositoryImp()), 
      child: const CartScreen(isFromBottomNav: true), // Pass flag to hide back button
    ),

    // 3: Orders
    BlocProvider(
      create: (context) => OrderListBloc(repository: OrderListRepositoryImp()),
      child: const OrdersList(isFromDashboard: false),
    ),

    // 4: Profile
    const DashboardScreen(),
  ];

  void _onTabTapped(int index) {
    // 🟢 Simply switch the index. No Navigator.push needed.
    setState(() {
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      // 🟢 Use IndexedStack to keep pages alive (Cart won't reload every time)
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: StreamBuilder<int>(
        stream: GlobalData.cartCountController.stream.cast<int>(),
        builder: (context, snapshot) {
          final count = snapshot.data ?? appStoragePref.getCartCount();

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -5)),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 65,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _navItem(0, Icons.home_outlined, Icons.home, "Home"),
                    _navItem(1, Icons.grid_view_outlined, Icons.grid_view_rounded, "Categories"),
                    _cartNavItem(2, count), // Index 2 is Cart
                    _navItem(3, Icons.receipt_long_outlined, Icons.receipt_long, "Orders"),
                    _navItem(4, Icons.person_outline, Icons.person, "Profile"),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _navItem(int index, IconData iconOutlined, IconData iconFilled, String label) {
    final isSelected = _index == index;
    const Color activeColor = Color(0xFFBDB76B); 

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        child: Column(
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
      ),
    );
  }

  Widget _cartNavItem(int index, int count) {
    final isSelected = _index == index;
    const Color activeColor = Color(0xFFBDB76B);

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
              child: Icon(
                Icons.shopping_cart_outlined, 
                size: 24, 
                color: isSelected ? activeColor : Colors.grey[600]
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Cart",
              style: TextStyle(
                fontSize: 10, 
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : Colors.grey[600]
              ),
            ),
          ],
        ),
      ),
    );
  }
}