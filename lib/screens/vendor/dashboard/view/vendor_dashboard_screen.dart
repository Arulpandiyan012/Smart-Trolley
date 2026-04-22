import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'vendor_root_category_screen.dart';
import '../../orders/view/vendor_orders_screen.dart';
import '../../stock_management/view/stock_management_screen.dart';
import '../../vendor_login/view/vendor_login_screen.dart'; 
import 'package:bagisto_app_demo/utils/index.dart'; 
import 'slow_moving_products_screen.dart'; 

class VendorDashboardScreen extends StatefulWidget {
  final Function(int)? onTabChange; // 🟢 Added callback for tab switching
  const VendorDashboardScreen({Key? key, this.onTabChange}) : super(key: key);

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  int _lowStockCount = 0;
  int _slowMovingCount = 0;
  bool _isLoadingMetrics = true;
  final String _apiUrl = "https://ecom.thesmartedgetech.com/mobikul-vendor-api.php";

  @override
  void initState() {
    super.initState();
    _fetchDashboardMetrics();
  }

  Future<void> _fetchDashboardMetrics() async {
    if (!mounted) return;
    setState(() => _isLoadingMetrics = true);
    
    try {
      // 🟢 Parallel Fetch for efficiency
      final responses = await Future.wait([
        Dio().post(_apiUrl, data: {"action": "get_vendor_products"}),
        Dio().post(_apiUrl, data: {"action": "get_deliveries"}),
      ]);

      final productsResponse = responses[0];
      final ordersResponse = responses[1];

      if (productsResponse.data['success'] == true) {
        final products = productsResponse.data['data'] as List;
        
        // 1. Calculate Low Stock
        int lowCount = 0;
        for (var p in products) {
          final stock = int.tryParse(p['stock'].toString()) ?? 0;
          if (stock < 10) lowCount++;
        }

        // 2. Calculate Slow Moving (Cross-Reference with Orders)
        int slowCount = 0;
        if (ordersResponse.data['success'] == true) {
           final orders = ordersResponse.data['data'] as List;
           final Map<String, int> salesVelocity = {};
           
           for (var order in orders) {
              String items = (order['items'] ?? "").toString().toLowerCase();
              for (var p in products) {
                 String pName = (p['name'] ?? "").toString().toLowerCase();
                 if (pName.isNotEmpty && items.contains(pName)) {
                    salesVelocity[pName] = (salesVelocity[pName] ?? 0) + 1;
                 }
              }
           }

           for (var p in products) {
              String name = (p['name'] ?? "").toString().toLowerCase();
              final stock = int.tryParse(p['stock'].toString()) ?? 0;
              final sales = salesVelocity[name] ?? 0;
              // Threshold: High stock (>15) but low sales (<2) in recent order history
              if (stock > 15 && sales < 2) {
                 slowCount++;
              }
           }
        }

        if (mounted) {
          setState(() {
            _lowStockCount = lowCount;
            _slowMovingCount = slowCount;
            _isLoadingMetrics = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching dashboard metrics: $e");
      if (mounted) setState(() => _isLoadingMetrics = false);
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
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: primaryColor),
            tooltip: "Refresh Data",
            onPressed: _fetchDashboardMetrics,
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoadingMetrics 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF27C16B)))
          : GridView.count(
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
                    widget.onTabChange!(0);
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const VendorRootCategoryScreen())).then((_) => _fetchDashboardMetrics());
                  }
                },
              ),
              _buildDashboardCard(
                context,
                icon: Icons.local_shipping,
                title: 'Pending Deliveries',
                onTap: () {
                  if (widget.onTabChange != null) {
                    widget.onTabChange!(1);
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
                    widget.onTabChange!(3);
                  } else {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (context) => const StockManagementScreen(showLowStockInitial: true)
                      )
                    ).then((_) => _fetchDashboardMetrics());
                  }
                },
              ),
              // 🟢 NEW: Slow-Moving Products Card
              _buildDashboardCard(
                context,
                icon: Icons.trending_down,
                title: 'Slow-Moving Items',
                color: Colors.orange,
                badgeCount: _slowMovingCount,
                onTap: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => const SlowMovingProductsScreen()
                    )
                  ).then((_) => _fetchDashboardMetrics());
                },
              ),
            ],
          ),

          if (!_isLoadingMetrics && _lowStockCount > 0)
            _buildFloatingAlertCard(context),
        ],
      ),
    );
  }

  // 🟢 Fixed Floating Alert Card to be more dynamic if needed, but keeping it focused on Low Stock for priority
  Widget _buildFloatingAlertCard(BuildContext context) {
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
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
                  widget.onTabChange!(3);
                } else {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const StockManagementScreen(showLowStockInitial: true))
                  ).then((_) => _fetchDashboardMetrics());
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
                            "Critical Actions Required",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Text(
                            "$_lowStockCount items low & $_slowMovingCount moving slow.",
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
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
