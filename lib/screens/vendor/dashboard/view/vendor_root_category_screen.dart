import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'vendor_category_screen.dart';
import '../../stock_management/view/stock_management_screen.dart';

class VendorRootCategoryScreen extends StatefulWidget {
  const VendorRootCategoryScreen({Key? key}) : super(key: key);

  @override
  State<VendorRootCategoryScreen> createState() => _VendorRootCategoryScreenState();
}

class _VendorRootCategoryScreenState extends State<VendorRootCategoryScreen> {
  final String _apiUrl = "https://ecom.thesmartedgetech.com/mobikul-vendor-api.php";
  bool _isLoading = false;
  List<dynamic> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
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
      debugPrint("Error fetching roots: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF27C16B),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _categories.isEmpty 
            ? const Center(child: Text("No Categories found"))
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, 
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final String name = cat['name'] ?? "Unknown";
                  
                  String imageUrl = '';
                  if (cat['imageUrl'] != null && cat['imageUrl'].toString().isNotEmpty) {
                    imageUrl = cat['imageUrl'];
                  } else if (cat['bannerUrl'] != null && cat['bannerUrl'].toString().isNotEmpty) {
                    imageUrl = cat['bannerUrl'];
                  }

                  return InkWell(
                    onTap: () {
                      final children = cat['children'] as List<dynamic>? ?? [];
                      if (children.isNotEmpty) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => VendorCategoryScreen(categories: children, title: name)));
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => StockManagementScreen(categoryId: cat['id'].toString(), categoryName: name))); 
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                        ]
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 3,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: imageUrl.isNotEmpty
                                ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.category, color: Colors.grey, size: 48))
                                : Container(color: Colors.grey[100], child: const Icon(Icons.category, color: Colors.grey, size: 48)),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
