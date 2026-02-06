import 'package:flutter/material.dart';
import '../../stock_management/view/stock_management_screen.dart';
import '../../orders/view/vendor_orders_screen.dart';

import 'package:bagisto_app_demo/utils/index.dart'; // For appStoragePref & Routes

class VendorDashboardScreen extends StatelessWidget {
  const VendorDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Dashboard'),
        backgroundColor: const Color(0xFF27C16B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: "Logout",
            onPressed: () {
               // 🟢 Logout Vendor
               appStoragePref.setVendorLoggedIn(false);
               
               // Redirect to App Home
               Navigator.pushNamedAndRemoveUntil(context, home, (route) => false);
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
              Navigator.push(context, MaterialPageRoute(builder: (context) => const StockManagementScreen()));
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF27C16B)),
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
