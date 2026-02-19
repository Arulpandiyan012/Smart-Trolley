import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VendorOrdersScreen extends StatelessWidget {
  const VendorOrdersScreen({Key? key}) : super(key: key);

  // Mock Data
  final List<Map<String, dynamic>> _orders = const [
    {
      'id': '#1001',
      'customer': 'Arul Pandiyan',
      'items': 'Milk, Bread, Eggs',
      'total': '₹450',
      'status': 'Pending',
      'date': '03 Feb 2026',
    },
    {
      'id': '#1002',
      'customer': 'John Doe',
      'items': 'Tomato, Butter',
      'total': '₹200',
      'status': 'Pending',
      'date': '03 Feb 2026',
    },
    {
      'id': '#1003',
      'customer': 'Jane Smith',
      'items': 'Shampoo, Soap',
      'total': '₹800',
      'status': 'Out for Delivery',
      'date': '02 Feb 2026',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pending Deliveries',
          style: GoogleFonts.poppins(
            color: const Color(0xFF2E7D32),
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.1)),
        ),
        iconTheme: IconThemeData(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          final isPending = order['status'] == 'Pending';
          
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
                      Text(order['id']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPending ? Colors.orange[100] : Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          order['status']!,
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
                  _buildRow(Icons.person, order['customer']!),
                  const SizedBox(height: 8),
                  _buildRow(Icons.shopping_bag, order['items']!),
                  const SizedBox(height: 8),
                  _buildRow(Icons.calendar_today, order['date']!),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total: ${order['total']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (isPending)
                        ElevatedButton(
                          onPressed: () {
                             // TODO: Mark as ready/dispatched
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Marked as Ready")));
                          },
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
}
