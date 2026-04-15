import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart'; // 🟢 Use Dio
import 'add_product_screen.dart'; 
import '../../dashboard/view/vendor_root_category_screen.dart';

class StockManagementScreen extends StatefulWidget {
  final String? categoryId;
  final String? categoryName;
  final bool showLowStockInitial;

  const StockManagementScreen({
    Key? key, 
    this.categoryId,
    this.categoryName,
    this.showLowStockInitial = false,
  }) : super(key: key);

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  bool _isLoading = true;
  List<dynamic> _products = [];
  Map<String, List<dynamic>> _groupedProducts = {}; 
  String _selectedCategory = "All Categories"; 
  String _searchQuery = ""; 
  bool _showLowStockOnly = false; 
  final TextEditingController _searchCtrl = TextEditingController();

  List<dynamic> _masterCategories = []; // Categories for the vertical sidebar with images
  final String _apiUrl = "https://ecom.thesmartedgetech.com/mobikul-vendor-api.php"; 

  @override
  void initState() {
    super.initState();
    _showLowStockOnly = widget.showLowStockInitial;
    _fetchProducts();
    _fetchCategories();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final response = await Dio().post(
        _apiUrl,
        data: {
          "action": "get_vendor_products",
          if (widget.categoryId != null) "category_id": widget.categoryId,
        },
        options: Options(
           headers: {"Content-Type": "application/json"},
           sendTimeout: const Duration(seconds: 10),
           receiveTimeout: const Duration(seconds: 10),
        )
      );

      if (response.statusCode == 200) {
        final data = response.data;
        _processData(data is String ? jsonDecode(data) : data);
      }
    } catch (e) {
      debugPrint("Error Fetching Products: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  void _processData(dynamic data) {
    if (data['success'] == true) {
      final rawList = data['data'] as List;
      final list = widget.categoryName != null 
          ? rawList.where((p) => (p['category_name']?.toString() ?? '').trim().toLowerCase() == widget.categoryName!.trim().toLowerCase()).toList()
          : rawList;
      
      final Map<String, List<dynamic>> groups = {};
      for (var p in list) {
        final cat = (p['category_name']?.toString() ?? 'Other').trim();
        if (!groups.containsKey(cat)) groups[cat] = [];
        groups[cat]!.add(p);
      }
      
      final sortedKeys = groups.keys.toList()..sort();
      final Map<String, List<dynamic>> sortedGroups = { for (var k in sortedKeys) k : groups[k]! };

      if (mounted) {
        setState(() {
          _products = list;
          _groupedProducts = sortedGroups;
        });
      }
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final resp = await Dio().post(_apiUrl, data: {"action": "get_categories"});
      if (resp.data['success'] == true) {
        setState(() {
          _masterCategories = resp.data['data'] as List<dynamic>;
        });
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
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
      await Dio().post(_apiUrl, data: {"action": "update_stock", "product_id": productId, "qty": newQty});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Stock Updated ✅"), backgroundColor: Colors.green, duration: Duration(milliseconds: 500)));
    } catch (_) { _fetchProducts(); }
  }

  String _getCategoryImage(String catName) {
     String _findImg(List<dynamic> list, String name) {
       for (var item in list) {
         if ((item['name']?.toString() ?? '').trim().toLowerCase() == name.trim().toLowerCase()) {
           return item['imageUrl'] ?? item['bannerUrl'] ?? "";
         }
         final sub = item['children'] as List<dynamic>?;
         if (sub != null && sub.isNotEmpty) {
           final img = _findImg(sub, name);
           if (img.isNotEmpty) return img;
         }
       }
       return "";
     }
     return _findImg(_masterCategories, catName);
  }

  int get _totalLowStockCount {
    return _products.where((p) {
      final s = int.tryParse(p['stock'].toString()) ?? 0;
      return s < 10;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF27C16B);

    // 🟢 Filter Logic
    Map<String, List<dynamic>> filteredByCat = (_selectedCategory == "All Categories") 
        ? _groupedProducts 
        : {_selectedCategory: _groupedProducts[_selectedCategory] ?? []};

    Map<String, List<dynamic>> displayGroups = {};
    final query = _searchQuery.toLowerCase();
    
    filteredByCat.forEach((cat, products) {
      final matches = products.where((p) {
        final matchesSearch = query.isEmpty || (p['name'] ?? "").toString().toLowerCase().contains(query);
        final stock = int.tryParse(p['stock'].toString()) ?? 0;
        final isLowStock = stock < 10;
        return matchesSearch && (!_showLowStockOnly || isLowStock);
      }).toList();
      if (matches.isNotEmpty) displayGroups[cat] = matches;
    });

    // 🟢 Sidebar Dynamic List
    List<String> sidebarItems = ["All Items"];
    _groupedProducts.forEach((cat, products) {
       final hasLowStock = products.any((p) => (int.tryParse(p['stock'].toString()) ?? 0) < 10);
       if (!_showLowStockOnly || hasLowStock) {
         sidebarItems.add(cat);
       }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categoryName ?? "Stock Management",
          style: const TextStyle(color: Color(0xFF27C16B), fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF27C16B)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF27C16B)),
            onPressed: () {
              if (widget.categoryId != null) {
                Navigator.push(context, MaterialPageRoute(builder: (c) => AddProductScreen(initialCategoryId: widget.categoryId, initialCategoryName: widget.categoryName))).then((_) => _fetchProducts());
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (c) => const VendorRootCategoryScreen())).then((_) => _fetchProducts());
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (widget.categoryId != null) {
            Navigator.push(context, MaterialPageRoute(builder: (c) => AddProductScreen(initialCategoryId: widget.categoryId, initialCategoryName: widget.categoryName))).then((_) => _fetchProducts());
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (c) => const VendorRootCategoryScreen())).then((_) => _fetchProducts());
          }
        },
        child: const Icon(Icons.add),
        backgroundColor: const Color(0xFF27C16B),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildTopBar(isDark),

              Expanded(
                child: Row(
                  children: [
                    // 🟢 LEFT SIDEBAR (Smart Filtering)
                    _buildSmartVerticalSidebar(isDark, sidebarItems),
                    
                    // 🟢 RIGHT CONTENT (Product Grid)
                    Expanded(
                      child: displayGroups.isEmpty 
                        ? const Center(child: Text("No Products found."))
                        : CustomScrollView(
                          slivers: [
                            ...displayGroups.entries.expand((entry) => [
                              if (_selectedCategory == "All Categories")
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                                    child: Text(entry.key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                                  ),
                                ),
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                sliver: SliverGrid(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                    childAspectRatio: 0.6,
                                  ),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) => _buildProductGridItem(entry.value[index], isDark),
                                    childCount: entry.value.length,
                                  ),
                                ),
                              ),
                            ]).toList(),
                            const SliverToBoxAdapter(child: SizedBox(height: 100)),
                          ],
                        ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildTopBar(bool isDark) {
    return Container(
      color: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: "Search products...",
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilterChip(
                avatar: Icon(Icons.warning_amber_rounded, size: 14, color: _showLowStockOnly ? Colors.white : Colors.red),
                label: const Text("Low Stock Only", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                selected: _showLowStockOnly,
                onSelected: (v) => setState(() => _showLowStockOnly = v),
                selectedColor: Colors.redAccent,
                checkmarkColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              const Spacer(),
              if (_selectedCategory != "All Categories")
                 TextButton.icon(
                   icon: const Icon(Icons.clear, size: 14, color: Colors.red),
                   label: const Text("Clear Filter", style: TextStyle(fontSize: 11, color: Colors.red)),
                   onPressed: () => setState(() => _selectedCategory = "All Categories"),
                 )
            ],
          ),
        ],
      ),
    );
  }

  int _getLowStockCountForCategory(String name) {
    if (name == "All Items") return _totalLowStockCount;
    final products = _groupedProducts[name] ?? [];
    return products.where((p) => (int.tryParse(p['stock'].toString()) ?? 0) < 10).length;
  }

  Widget _buildSmartVerticalSidebar(bool isDark, List<String> sidebarItems) {
    return Container(
      width: 75, // 🟢 Reduced width
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        border: Border(right: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey.shade200)),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sidebarItems.length,
        itemBuilder: (context, index) {
          final name = sidebarItems[index];
          final isSelected = (name == "All Items" && _selectedCategory == "All Categories") || _selectedCategory == name;
          final imageUrl = name == "All Items" ? "" : _getCategoryImage(name);
          final alertCount = _getLowStockCountForCategory(name);

          return _buildSidebarItem(
            name: name,
            image: imageUrl,
            isSelected: isSelected,
            alertCount: alertCount,
            onTap: () => setState(() => _selectedCategory = name == "All Items" ? "All Categories" : name),
          );
        },
      ),
    );
  }

  Widget _buildSidebarItem({required String name, required String image, required bool isSelected, required int alertCount, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: isSelected ? const Color(0xFF27C16B) : Colors.transparent, width: 3)),
          color: isSelected ? const Color(0xFF27C16B).withOpacity(0.05) : Colors.transparent,
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 38, // 🟢 Reduced size
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [if(isSelected) BoxShadow(color: const Color(0xFF27C16B).withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
                    border: Border.all(color: isSelected ? const Color(0xFF27C16B) : Colors.grey.withOpacity(0.15)),
                  ),
                  child: image.isNotEmpty
                      ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(image, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.category, color: Colors.grey, size: 20)))
                      : Icon(name == "All Items" ? Icons.inventory : Icons.category, size: 20, color: isSelected ? const Color(0xFF27C16B) : Colors.grey),
                ),
                // 🟢 Smart Badge Overlay
                if (alertCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Center(
                        child: Text(
                          "$alertCount",
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 8, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? const Color(0xFF27C16B) : Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGridItem(dynamic product, bool isDark) {
    final stock = int.tryParse(product['stock'].toString()) ?? 0;
    final isLow = stock < 10;
    final imageUrl = product['image'] ?? "";

    return InkWell(
      onTap: () => _showEditDialog(product['id'].toString(), product['name'], stock),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isLow ? Colors.red.withOpacity(0.3) : Colors.grey.withOpacity(0.1), width: 1),
          boxShadow: [BoxShadow(color: isLow ? Colors.red.withOpacity(0.05) : Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: Container(
                  width: double.infinity,
                  color: isDark ? Colors.grey[800] : Colors.grey[50],
                  child: imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 20, color: Colors.grey))
                      : const Icon(Icons.image, size: 20, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Stock", style: TextStyle(fontSize: 8, color: Colors.grey)),
                          Text("$stock", style: TextStyle(color: isLow ? Colors.red : const Color(0xFF27C16B), fontWeight: FontWeight.w800, fontSize: 12)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(color: const Color(0xFF27C16B).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: const Icon(Icons.edit, size: 12, color: Color(0xFF27C16B)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(String id, String name, int currentStock) {
    final TextEditingController _controller = TextEditingController(text: currentStock.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Update Stock', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(name, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 20),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                      labelText: 'New Quantity',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27C16B), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
