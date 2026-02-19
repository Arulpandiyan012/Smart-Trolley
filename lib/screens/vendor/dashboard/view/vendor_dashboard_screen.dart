import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../stock_management/view/stock_management_screen.dart';
import '../../orders/view/vendor_orders_screen.dart';

import 'package:bagisto_app_demo/utils/index.dart'; // For appStoragePref & Routes

class VendorDashboardScreen extends StatelessWidget {
  const VendorDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vendor Dashboard',
          style: GoogleFonts.poppins(
            color: const Color(0xFF2E7D32),
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false, 
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.1)),
        ),
        iconTheme: IconThemeData(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
            tooltip: "Logout",
            onPressed: () => _showLogoutConfirmation(context),
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

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout from Vendor Dashboard?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("No", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                appStoragePref.setVendorLoggedIn(false);
                Navigator.pushNamedAndRemoveUntil(context, home, (route) => false);
              },
              child: const Text("Yes", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDashboardCard(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, Color? iconColor, Color? textColor}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: iconColor ?? const Color(0xFF27C16B)),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 16,
                color: textColor ?? Theme.of(context).textTheme.titleMedium?.color
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
