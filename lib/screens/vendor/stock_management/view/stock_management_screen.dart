import 'package:flutter/material.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({Key? key}) : super(key: key);

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  // Mock Data
  final List<Map<String, dynamic>> _products = [
    {'id': '1', 'name': 'Fresh Milk (1L)', 'stock': 50, 'image': 'assets/images/milk_carton.png'},
    {'id': '2', 'name': 'Whole Wheat Bread', 'stock': 20, 'image': 'assets/images/bread_packet.png'},
    {'id': '3', 'name': 'Eggs (12 Pack)', 'stock': 100, 'image': 'assets/images/eggs_carton.png'},
    {'id': '4', 'name': 'Butter Block (500g)', 'stock': 5, 'image': 'assets/images/butter_block.webp'},
    {'id': '5', 'name': 'Tomato (1kg)', 'stock': 0, 'image': 'assets/images/tomato_fresh.png'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Management'),
        backgroundColor: const Color(0xFF27C16B),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(product['image'], fit: BoxFit.contain, errorBuilder: (c,o,s) => const Icon(Icons.image_not_supported)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          'Current Stock: ${product['stock']}',
                          style: TextStyle(
                            color: (product['stock'] as int) < 10 ? Colors.red : Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editStock(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _editStock(int index) {
    final TextEditingController _controller = TextEditingController(text: _products[index]['stock'].toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Stock: ${_products[index]['name']}'),
        content: TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'New Quantity'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              int? newStock = int.tryParse(_controller.text);
              if (newStock != null) {
                setState(() {
                  _products[index]['stock'] = newStock;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock Updated Successfully')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27C16B), foregroundColor: Colors.white),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
