import 'package:flutter/material.dart';

// TODO: replace with your real screens
import 'package:bagisto_app_demo/screens/home_page/home_page.dart'; // your existing HomeScreen

class MainNavScaffold extends StatefulWidget {
  const MainNavScaffold({Key? key}) : super(key: key);

  @override
  State<MainNavScaffold> createState() => _MainNavScaffoldState();
}

class _MainNavScaffoldState extends State<MainNavScaffold> {
  int _currentIndex = 0;

  // Use IndexedStack to preserve state of each tab
  late final List<Widget> _tabs = const [
    _KeepAlive(child: HomeScreen()),
    _KeepAlive(child: CategoriesScreen()),
    _KeepAlive(child: CartScreen()),
    _KeepAlive(child: AccountScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove appBar here if your tab pages already provide their own app bars
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        height: 64,
        // optional surface tint
        // surfaceTintColor: Colors.white,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

/// Keeps child widget alive across tab switches
class _KeepAlive extends StatefulWidget {
  final Widget child;
  const _KeepAlive({required this.child});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// ---------- PLACEHOLDER SCREENS (replace with your actual ones) ----------

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _SimpleAppBar(title: 'Categories'),
      body: Center(child: Text('Categories Screen')),
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _SimpleAppBar(title: 'My Cart'),
      body: Center(child: Text('Cart Screen')),
    );
  }
}

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _SimpleAppBar(title: 'Account'),
      body: Center(child: Text('Account Screen')),
    );
  }
}

class _SimpleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const _SimpleAppBar({required this.title, super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }
}
