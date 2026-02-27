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

  @override
  void initState() {
    super.initState();
    _fetchOrders();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Deliveries'),
        backgroundColor: const Color(0xFF27C16B),
        foregroundColor: Colors.white,
        actions: [
           IconButton(
             icon: const Icon(Icons.refresh),
             onPressed: _fetchOrders,
           )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF27C16B)))
        : _orders.isEmpty 
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                // "Pending" might be "Pending" or "Processing" in DB depending on status name. 
                // But the API returns it as "Pending" or "Processing" Capitalized.
                final isPending = (order['status'] == 'Pending' || order['status'] == 'Processing');
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${order['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPending ? Colors.orange[100] : Colors.blue[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${order['status']}',
                                style: TextStyle(
                                  color: isPending ? Colors.orange[900] : Colors.blue[900],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        _buildRow(Icons.person, '${order['customer']}'),
                        const SizedBox(height: 8),
                        _buildRow(Icons.shopping_bag, '${order['items']}'),
                        const SizedBox(height: 8),
                        _buildRow(Icons.calendar_today, '${order['date']}'),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total: ${order['total']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            if (isPending)
                              ElevatedButton(
                                onPressed: () => _markReady(order['raw_id']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF27C16B), 
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  minimumSize: const Size(0, 36)
                                ),
                                child: const Text('Mark Ready'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
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

