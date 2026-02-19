import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart'; // 🟢 Use Dio
import 'add_product_screen.dart'; 

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({Key? key}) : super(key: key);

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  bool _isLoading = true;
  List<dynamic> _products = [];
  Map<String, List<dynamic>> _groupedProducts = {}; 
  // Removed _selectedCategory
  String _selectedCategory = "All Categories"; // 🟢 Filter State

  final String _apiUrl = "https://ecom.thesmartedgetech.com/mobikul-vendor-api.php"; 


  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      // 🟢 Dio Request
      final response = await Dio().post(
        _apiUrl,
        data: {"action": "get_vendor_products"},
        options: Options(
           headers: {"Content-Type": "application/json"},
           sendTimeout: const Duration(seconds: 10),
           receiveTimeout: const Duration(seconds: 10),
        )
      );

      if (response.statusCode == 200) {
        final data = response.data; // 🟢 Dio decodes automatically
        if (data is String) {
           // Fallback if Dio didn't decode (rare but possible with some server headers)
           try {
             final decoded = jsonDecode(data);
             if(decoded is Map) _processData(decoded);
           } catch (_) {}
        } else {
           _processData(data);
        }
      } else {
         if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("HTTP Error: ${response.statusCode}")));
      }
    } catch (e) {
      debugPrint("Error Fetching Products: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connection Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  void _processData(dynamic data) {
        if (data['success'] == true) {
          final list = data['data'] as List;
          
          final Map<String, List<dynamic>> groups = {};
          for (var p in list) {
            final cat = p['category_name'] ?? 'Other';
            if (!groups.containsKey(cat)) groups[cat] = [];
            groups[cat]!.add(p);
          }
          
          // Sort keys
          final sortedKeys = groups.keys.toList()..sort();
          final Map<String, List<dynamic>> sortedGroups = { for (var k in sortedKeys) k : groups[k]! };

          if (mounted) {
            setState(() {
              _products = list;
              _groupedProducts = sortedGroups;
            });
          }
        } else {
           if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${data['message']}")));
        }
  }

  Future<void> _updateStock(String productId, int newQty) async {
       for(var key in _groupedProducts.keys) {
          final idx = _groupedProducts[key]!.indexWhere((p) => p['id'].toString() == productId);
          if (idx != -1) {
              setState(() { _groupedProducts[key]![idx]['stock'] = newQty; }); 
              break;
          }
      }
      try {
        await Dio().post(
           _apiUrl, 
           data: {"action": "update_stock", "product_id": productId, "qty": newQty},
           options: Options(headers: {"Content-Type": "application/json"})
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Stock Updated ✅"), backgroundColor: Colors.green, duration: Duration(milliseconds: 500)));
      } catch (_) { _fetchProducts(); }
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 Filter Logic
    final categories = ["All Categories", ..._groupedProducts.keys];
    final displayGroups = (_selectedCategory == "All Categories") 
        ? _groupedProducts 
        : {_selectedCategory: _groupedProducts[_selectedCategory] ?? []};

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Stock Management',
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
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchProducts)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AddProductScreen())).then((_) => _fetchProducts()),
        label: const Text("Add Product"),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF27C16B),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
               // 🟢 DROPDOWN FILTER
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                 color: Colors.white,
                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12),
                   decoration: BoxDecoration(
                     border: Border.all(color: Colors.grey.shade300),
                     borderRadius: BorderRadius.circular(8)
                   ),
                   child: DropdownButton<String>(
                     value: categories.contains(_selectedCategory) ? _selectedCategory : "All Categories",
                     isExpanded: true, // Prevent Overflow
                     underline: const SizedBox(),
                     items: categories.map((c) => DropdownMenuItem(
                        value: c, 
                        child: Text(
                             c, 
                             style: const TextStyle(fontWeight: FontWeight.w600),
                             overflow: TextOverflow.ellipsis,
                             maxLines: 1,
                        )
                     )).toList(),
                     onChanged: (v) => setState(() => _selectedCategory = v!),
                   ),
                 ),
               ),

               // 🟢 LIST
               Expanded(
                 child: displayGroups.isEmpty 
                    ? const Center(child: Text("No Products")) 
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        children: displayGroups.entries.map((entry) {
                           if (entry.value.isEmpty) return const SizedBox.shrink();
                           return Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Padding(
                                 padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                                 child: Text(entry.key, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                               ),
                               ...entry.value.map((product) {
                                  final stock = int.tryParse(product['stock'].toString()) ?? 0;
                                  final imageUrl = product['image'] ?? "";
                                  
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 50, height: 50,
                                            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                                            child: (imageUrl.isNotEmpty) 
                                                ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image))
                                                : const Icon(Icons.image, color: Colors.grey),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                Text(product['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                                                const SizedBox(height: 4),
                                                Text('Stock: $stock', style: TextStyle(color: stock < 10 ? Colors.red : Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 12)),
                                            ]),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                            onPressed: () => _showEditDialog(product['id'].toString(), product['name'], stock),
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                               }).toList()
                             ],
                           );
                        }).toList(),
                      ),
               ),
            ],
          ),
    );
  }

  void _showEditDialog(String id, String name, int currentStock) {
    final TextEditingController _controller = TextEditingController(text: currentStock.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Stock'),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(name, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 10),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'New Quantity',
                      border: OutlineInputBorder()
                  ),
                ),
            ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              int? newStock = int.tryParse(_controller.text);
              if (newStock != null) {
                Navigator.pop(context);
                _updateStock(id, newStock);
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
