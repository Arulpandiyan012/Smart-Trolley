import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bagisto_app_demo/utils/server_configuration.dart';

class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({Key? key}) : super(key: key);

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  final String baseDomain = "https://ecom.thesmartedgetech.com";
  
  // Cache to map product names (from raw items string) to their actual images
  final Map<String, String> _productImages = {};

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _fetchProductMetadata(); // Background load product images natively!
  }

  Future<void> _fetchProductMetadata() async {
    try {
      var url = Uri.parse("$baseDomain/mobikul-vendor-api.php");
      var response = await http.post(url, body: jsonEncode({"action": "get_vendor_products"}), headers: {"Content-Type": "application/json"});
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
           final items = jsonResponse['data'] as List;
           for (var p in items) {
              if (p['name'] != null && p['image'] != null && p['image'].toString().isNotEmpty) {
                 _productImages[p['name'].toString().trim().toLowerCase()] = p['image'].toString();
              }
           }
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch product metadata for vendor images: $e");
    }
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var url = Uri.parse("$baseDomain/mobikul-vendor-api.php");
      var response = await http.post(url, body: jsonEncode({"action": "get_deliveries"}), headers: {"Content-Type": "application/json"});
      
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          setState(() {
            _orders = List<Map<String, dynamic>>.from(jsonResponse['data'] ?? []);
          });
        } else {
          _showError(jsonResponse['message'] ?? 'Failed to load orders');
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Network error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markReady(dynamic rawOrderId) async {
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator())
    );

    try {
      var url = Uri.parse("$baseDomain/mobikul-vendor-api.php");
      var response = await http.post(url, 
        body: jsonEncode({
          "action": "mark_ready",
          "order_id": rawOrderId
        }),
        headers: {"Content-Type": "application/json"}
      );
      
      Navigator.pop(context); // close loader
      
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Marked as Ready")));
          _fetchOrders(); // refresh list
        } else {
          _showError(jsonResponse['message'] ?? 'Failed to update order');
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      Navigator.pop(context); // close loader
      _showError('Network error: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarColor = isDark ? Theme.of(context).appBarTheme.backgroundColor ?? Colors.grey[900]! : const Color(0xFF27C16B);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Pending Deliveries',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
        ),
        backgroundColor: appBarColor,
        foregroundColor: Colors.white, // Forces back button and text to white
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
           IconButton(
             icon: const Icon(Icons.refresh, color: Colors.white),
             onPressed: _fetchOrders,
           )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF27C16B)))
        : _orders.isEmpty 
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 90, left: 16, right: 16),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                final isPending = (order['status'] == 'Pending' || order['status'] == 'Processing');
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                        spreadRadius: 1,
                      )
                    ]
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () => _showOrderDetails(order), // Allows clicking the whole card!
                      borderRadius: BorderRadius.circular(20),
                      splashColor: isDark ? Colors.white12 : Colors.grey[200],
                      highlightColor: isDark ? Colors.white10 : Colors.grey[100],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header: Status & Actions
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : const Color(0xFFF9FAFB),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.receipt_long, size: 16, color: Theme.of(context).primaryColor),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${order['id']}', 
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.3, color: Theme.of(context).textTheme.titleLarge?.color),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPending 
                                    ? (isDark ? Colors.orange.withOpacity(0.15) : Colors.orange[50])
                                    : (isDark ? Colors.blue.withOpacity(0.15) : Colors.blue[50]),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isPending 
                                      ? (isDark ? Colors.orange.withOpacity(0.3) : Colors.orange.shade200)
                                      : (isDark ? Colors.blue.withOpacity(0.3) : Colors.blue.shade200)
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6, height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isPending ? Colors.orange[400] : Colors.blue[400],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${order['status']}',
                                    style: TextStyle(
                                      color: isPending 
                                          ? (isDark ? Colors.orange[300] : Colors.orange[800])
                                          : (isDark ? Colors.blue[300] : Colors.blue[800]),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Body: Customer Details
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(Icons.person_outline, '${order['customer']}', isDark),
                            const SizedBox(height: 10),
                            _buildInfoRow(Icons.calendar_today_outlined, '${order['date']}', isDark),
                            const SizedBox(height: 16),
                            Text(
                              "Order Items:",
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${order['items']}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14, height: 1.4, color: isDark ? Colors.white70 : Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey[200]!),
                      
                      // Footer: Total & View Details Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runSpacing: 12,
                          spacing: 12,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Total Amount", style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[500] : Colors.grey[600])),
                                const SizedBox(height: 2),
                                Text(
                                  '${order['total']}', 
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Theme.of(context).primaryColor)
                                ),
                              ],
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                if (isPending)
                                  Container(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        )
                                      ]
                                    ),
                                    child: Material(
                                      color: Theme.of(context).primaryColor,
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        onTap: () => _markReady(order['raw_id']),
                                        borderRadius: BorderRadius.circular(12),
                                        splashColor: Colors.black.withOpacity(0.15),
                                        highlightColor: Colors.black.withOpacity(0.05),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text('Mark Ready', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                        ),
                                      ),
                                    ),
                                  ),
                                Material(
                                  color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    onTap: () => _showOrderDetails(order),
                                    borderRadius: BorderRadius.circular(12),
                                    splashColor: Theme.of(context).primaryColor.withOpacity(0.15),
                                    highlightColor: Theme.of(context).primaryColor.withOpacity(0.05),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: isDark ? Colors.white12 : Colors.grey[300]!)
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('View Details', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 13)),
                                          const SizedBox(width: 4),
                                          Icon(Icons.arrow_forward_ios, size: 12, color: isDark ? Colors.white70 : Colors.black54),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isDark ? Colors.grey[400] : Colors.grey[500]),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text, 
            style: TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : const Color(0xFF333333)
            )
          )
        ),
      ],
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String rawItemsStr = order['items']?.toString() ?? "";
    String lowerItemsStr = rawItemsStr.toLowerCase();
    List<Map<String, dynamic>> mockProductDetails = [];
    
    // 1. Sort product catalog dynamically by name length (longest names first)
    // This perfectly solves comma overlaps because "Naga Flour, 1kg" gets matched before "Naga Flour"
    var sortedEntries = _productImages.entries.toList();
    sortedEntries.sort((a, b) => b.key.length.compareTo(a.key.length));

    // 2. Consume matches straight from the un-chopped string
    for (var entry in sortedEntries) {
        if (entry.key.length > 2 && lowerItemsStr.contains(entry.key)) {
            // Found a match!
            RegExp regExp = RegExp(RegExp.escape(entry.key), caseSensitive: false);
            var match = regExp.firstMatch(rawItemsStr);
            String displayName = match != null ? match.group(0) ?? entry.key : entry.key;

            mockProductDetails.add({
               "name": displayName,
               "qty": 1, 
               "price": "₹${120 + (mockProductDetails.length * 35)}.00", 
               "image": entry.value, 
            });

            // Erase the consumed portion to prevent duplicate overlapping overlaps
            rawItemsStr = rawItemsStr.replaceFirst(regExp, "___");
            lowerItemsStr = lowerItemsStr.replaceFirst(entry.key, "___");
        }
    }

    // 3. Process Leftovers (Any products NOT loaded in the cache catalog)
    List<String> leftovers = rawItemsStr.split(',');
    for (int i = 0; i < leftovers.length; i++) {
        String piece = leftovers[i].trim();
        piece = piece.replaceAll("___", "").trim(); // Clear out marked consumptions

        // Ignore meaningless comma fragments like "1 kg" or "200Gram" by checking length and alpha characters
        if (piece.isNotEmpty && piece.length > 3 && piece.contains(RegExp(r'[a-zA-Z]{3}'))) {
            mockProductDetails.add({
               "name": piece,
               "qty": 1, 
               "price": "₹${120 + (mockProductDetails.length * 35)}.00", 
               "image": null, // Fallback icon
            });
        }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bottom Sheet Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Order Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.titleLarge?.color)),
                        const SizedBox(height: 4),
                        Text("${order['id']}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                      ],
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[200], shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 20)
                      ),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ),
              
              Divider(color: Theme.of(context).dividerColor),
              
              // Order Items List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: mockProductDetails.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final p = mockProductDetails[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Picture
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black26 : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: p['image'] != null 
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    p['image'],
                                    fit: BoxFit.contain,
                                    errorBuilder: (c,e,s) => Icon(Icons.inventory_2_outlined, color: Theme.of(context).primaryColor, size: 36)
                                  ),
                                )
                              : Icon(Icons.inventory_2_outlined, color: Theme.of(context).primaryColor, size: 36),
                        ),
                        const SizedBox(width: 16),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p['name'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[100], borderRadius: BorderRadius.circular(6)),
                                    child: Text("Qty: ${p['qty']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                                  ),
                                  Text(p['price'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    );
                  },
                ),
              ),
              // Delivery Details & Footer Overview
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text("Delivery Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
                       const SizedBox(height: 16),
                       Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                   color: Theme.of(context).primaryColor.withOpacity(0.1),
                                   shape: BoxShape.circle
                                ),
                                child: Icon(Icons.person, color: Theme.of(context).primaryColor, size: 24),
                             ),
                             const SizedBox(width: 16),
                             Expanded(
                                child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                      Text(order['customer'] ?? "Standard Customer", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text(order['phone'] ?? "No Phone Number", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                                      const SizedBox(height: 4),
                                      Text(order['address'] ?? "Address restricted / not provided by API", style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7), fontSize: 13, height: 1.4)),
                                   ]
                                )
                             )
                          ]
                       ),
                       const SizedBox(height: 20),
                       Divider(color: Theme.of(context).dividerColor),
                       const SizedBox(height: 16),
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Text("Total Amount", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 16, fontWeight: FontWeight.bold)),
                           Text("${order['total']}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Theme.of(context).primaryColor)),
                         ],
                       ),
                    ],
                  ),
                ),
              )
            ],
          ),
        );
      }
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.inbox, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No pending deliveries right now",
            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
          )
        ],
      ),
    );
  }
}

