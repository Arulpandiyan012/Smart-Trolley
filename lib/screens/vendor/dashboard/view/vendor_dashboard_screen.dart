import 'package:flutter/material.dart';
import 'vendor_root_category_screen.dart';
import '../../orders/view/vendor_orders_screen.dart';
import '../../vendor_login/view/vendor_login_screen.dart'; // import vendor login screen
import 'package:bagisto_app_demo/utils/index.dart'; // For appStoragePref & Routes

class VendorDashboardScreen extends StatelessWidget {
  const VendorDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final appBarColor = isDark ? Theme.of(context).appBarTheme.backgroundColor ?? Colors.grey[900] : const Color(0xFF27C16B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Dashboard'),
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: "Logout",
            onPressed: () {
               showDialog(
                 context: context,
                 builder: (BuildContext context) {
                   return AlertDialog(
                     title: const Text('Confirm Logout'),
                     content: const Text('Are you sure you want to log out?'),
                     actions: [
                       TextButton(
                         onPressed: () {
                           Navigator.pop(context); // Close dialog
                         },
                         child: const Text('Cancel'),
                       ),
                       TextButton(
                         onPressed: () {
                           // 🟢 Logout Vendor
                           appStoragePref.setVendorLoggedIn(false);
                           
                           // Show message
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('Logged out successfully')),
                           );

                           // Redirect to Vendor Login
                           Navigator.pushAndRemoveUntil(
                             context,
                             MaterialPageRoute(builder: (context) => const VendorLoginScreen()),
                             (route) => false,
                           );
                         },
                         child: const Text('Logout', style: TextStyle(color: Colors.red)),
                       ),
                     ],
                   );
                 },
               );
            },
          )
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildDashboardCard(
            context,
            icon: Icons.inventory,
            title: 'Stock Management',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const VendorRootCategoryScreen()));
            },
          ),
          _buildDashboardCard(
            context,
            icon: Icons.local_shipping,
            title: 'Pending Deliveries',
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const VendorOrdersScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Theme.of(context).colorScheme.secondary : const Color(0xFF27C16B);

    return Card(
      elevation: isDark ? 2 : 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: iconColor),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

