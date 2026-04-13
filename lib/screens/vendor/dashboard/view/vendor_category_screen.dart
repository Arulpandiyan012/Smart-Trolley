import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../stock_management/view/stock_management_screen.dart';

class VendorCategoryScreen extends StatefulWidget {
  final List<dynamic>? categories;
  final String title;

  const VendorCategoryScreen({
    Key? key,
    this.categories,
    this.title = "Select Category",
  }) : super(key: key);

  @override
  State<VendorCategoryScreen> createState() => _VendorCategoryScreenState();
}

class _VendorCategoryScreenState extends State<VendorCategoryScreen> {
  final String _apiUrl = "https://ecom.thesmartedgetech.com/mobikul-vendor-api.php";
  bool _isLoading = false;
  List<dynamic> _categories = [];

  @override
  void initState() {
    super.initState();
    if (widget.categories != null) {
      _categories = widget.categories!;
    } else {
      _fetchRootCategories();
    }
  }

  Future<void> _fetchRootCategories() async {
    setState(() => _isLoading = true);
    try {
      final resp = await Dio().post(_apiUrl, data: {"action": "get_categories"});
      if (resp.data['success'] == true) {
        if (mounted) {
          setState(() {
            _categories = resp.data['data'] as List<dynamic>;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onCategoryTapped(dynamic cat) {
    final children = cat['children'] as List<dynamic>? ?? [];
    
    if (children.isNotEmpty) {
      // Navigate to subcategories
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VendorCategoryScreen(
            categories: children,
            title: cat['name'] ?? "Categories",
          ),
        ),
      );
    } else {
      // Leaf category - go to Stock Management for this category!
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StockManagementScreen(
            categoryId: cat['id'].toString(),
            categoryName: cat['name'] ?? "Category",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF27C16B),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF27C16B)))
          : _categories.isEmpty
              ? const Center(child: Text("No categories found."))
              : ListView.separated(
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final String name = cat['name'] ?? "Unknown";
                    final List<dynamic> children = cat['children'] as List<dynamic>? ?? [];
                    final hasChildren = children.isNotEmpty;

                    // Extract image dynamically
                    String imageUrl = '';
                    if (cat['imageUrl'] != null && cat['imageUrl'].toString().isNotEmpty) {
                      imageUrl = cat['imageUrl'];
                    } else if (cat['bannerUrl'] != null && cat['bannerUrl'].toString().isNotEmpty) {
                      imageUrl = cat['bannerUrl'];
                    }

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.category, color: Colors.grey),
                                ),
                              )
                            : const Icon(Icons.category, color: Colors.grey),
                      ),
                      trailing: hasChildren
                          ? const Icon(Icons.chevron_right, color: Colors.grey)
                          : const Icon(Icons.inventory, color: Color(0xFF27C16B)), // Stock icon for leaf
                      onTap: () => _onCategoryTapped(cat),
                    );
                  },
                ),
    );
  }
}
