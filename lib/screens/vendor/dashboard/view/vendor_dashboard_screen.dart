import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'vendor_root_category_screen.dart';
import '../../orders/view/vendor_orders_screen.dart';
import '../../stock_management/view/stock_management_screen.dart';
import '../../vendor_login/view/vendor_login_screen.dart'; 
import 'package:bagisto_app_demo/utils/index.dart'; 

class VendorDashboardScreen extends StatefulWidget {
  final Function(int)? onTabChange; // 🟢 Added callback for tab switching
  const VendorDashboardScreen({Key? key, this.onTabChange}) : super(key: key);

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  int _lowStockCount = 0;
  bool _isLoadingCount = true;
  final String _apiUrl = "https://ecom.thesmartedgetech.com/mobikul-vendor-api.php";

  @override
  void initState() {
    super.initState();
    _fetchLowStockCount();
  }

  Future<void> _fetchLowStockCount() async {
    if (!mounted) return;
    setState(() => _isLoadingCount = true);
    
    try {
      final response = await Dio().post(
        _apiUrl,
        data: {"action": "get_vendor_products"},
        options: Options(headers: {"Content-Type": "application/json"})
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final products = response.data['data'] as List;
        int count = 0;
        for (var p in products) {
          final stock = int.tryParse(p['stock'].toString()) ?? 0;
          if (stock < 10) {
            count++;
          }
        }
        if (mounted) {
          setState(() {
            _lowStockCount = count;
            _isLoadingCount = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching low stock count: $e");
      if (mounted) setState(() => _isLoadingCount = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF27C16B);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vendor Dashboard',
          style: TextStyle(
            color: primaryColor, 
            fontWeight: FontWeight.w800, 
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false, // 🟢 Modern apps favor left-alignment
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: primaryColor),
            tooltip: "Refresh Data",
            onPressed: _fetchLowStockCount,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 🟢 DASHBOARD CONTENT
          GridView.count(
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
                  if (widget.onTabChange != null) {
                    widget.onTabChange!(0); // 🟢 Switch to Stock Tab
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const VendorRootCategoryScreen())).then((_) => _fetchLowStockCount());
                  }
                },
              ),
              _buildDashboardCard(
                context,
                icon: Icons.local_shipping,
                title: 'Pending Deliveries',
                onTap: () {
                  if (widget.onTabChange != null) {
                    widget.onTabChange!(1); // 🟢 Switch to Orders Tab
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const VendorOrdersScreen()));
                  }
                },
              ),
              _buildDashboardCard(
                context,
                icon: Icons.warning_amber_rounded,
                title: 'Low Stock Alerts',
                color: Colors.redAccent,
                badgeCount: _lowStockCount,
                onTap: () {
                  if (widget.onTabChange != null) {
                    widget.onTabChange!(3); // 🟢 Switch to Alerts Tab
                  } else {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (context) => const StockManagementScreen(showLowStockInitial: true)
                      )
                    ).then((_) => _fetchLowStockCount());
                  }
                },
              ),
            ],
          ),

          // 🟢 MODERN FLOATING ALERT CARD (BOTTOM)
          if (!_isLoadingCount && _lowStockCount > 0)
            _buildFloatingAlertCard(context),
        ],
      ),
    );
  }

  Widget _buildFloatingAlertCard(BuildContext context) {
    return Positioned(
      bottom: 100, // 🟢 Increased to avoid overlap with Bottom Nav Bar
      left: 16,
      right: 16,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: 1.0,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF5252), Color(0xFFFF8A65)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (widget.onTabChange != null) {
                    widget.onTabChange!(3); // 🟢 Switch to Alerts Tab
                  } else {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (context) => const StockManagementScreen(showLowStockInitial: true)
                      )
                    ).then((_) => _fetchLowStockCount());
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Low Stock Alert!",
                              style: TextStyle(
                                color: Colors.white, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 18,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              "$_lowStockCount items are running low.",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9), 
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (widget.onTabChange != null) {
                            widget.onTabChange!(3); // 🟢 Switch to Alerts Tab
                          } else {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (context) => const StockManagementScreen(showLowStockInitial: true)
                              )
                            ).then((_) => _fetchLowStockCount());
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFFF5252),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text(
                          "Restock",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, {
    required IconData icon, 
    required String title, 
    required VoidCallback onTap, 
    Color? color,
    int badgeCount = 0,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = color ?? (isDark ? Theme.of(context).colorScheme.secondary : const Color(0xFF27C16B));

    return Card(
      elevation: isDark ? 2 : 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
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
            if (badgeCount > 0)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 26,
                    minHeight: 26,
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
