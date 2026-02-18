import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagisto_app_demo/screens/categories_screen/utils/index.dart';
import 'package:bagisto_app_demo/utils/app_global_data.dart';
import 'package:bagisto_app_demo/utils/app_constants.dart';
import 'package:bagisto_app_demo/utils/shared_preference_helper.dart';
import 'package:bagisto_app_demo/widgets/image_view.dart';
import 'package:bagisto_app_demo/widgets/blinkit_product_card.dart'; 
import 'package:bagisto_app_demo/widgets/show_message.dart';
import 'package:bagisto_app_demo/screens/cart_screen/bloc/cart_screen_bloc.dart';
import 'package:bagisto_app_demo/screens/cart_screen/bloc/cart_screen_event.dart';
import 'package:bagisto_app_demo/screens/cart_screen/bloc/cart_screen_state.dart';
import 'package:bagisto_app_demo/screens/cart_screen/utils/cart_index.dart';

class SubCategorySidebarScreen extends StatefulWidget {
  final String title;
  final String parentId;
  final List<dynamic> subCategories; // These are L3 Categories

  const SubCategorySidebarScreen({
    Key? key, 
    required this.title,
    required this.parentId,
    required this.subCategories,
  }) : super(key: key);

  @override
  State<SubCategorySidebarScreen> createState() => _SubCategorySidebarScreenState();
}

class _SubCategorySidebarScreenState extends State<SubCategorySidebarScreen> {
  int _selectedSidebarIndex = 0; // Index of L3 Category
  
  // Logic
  CategoryBloc? _categoryBloc;
  NewProductsModel? _productsData;
  GetFilterAttribute? _filterData; 
  String _currentSlug = "";
  
  bool _isLoading = false;
  final ScrollController _listController = ScrollController();
  int _page = 1;
  List<Map<String, dynamic>> _filters = [];

  @override
  void initState() {
    super.initState();
    debugPrint("🟢 OPENING SubCategorySidebarScreen for: ${widget.title}");
    debugPrint("🟢 Passed L3 Categories: ${widget.subCategories.length}");
    widget.subCategories.forEach((c) => debugPrint(" - L3: ${_getName(c)}"));

    _categoryBloc = context.read<CategoryBloc>();
    
    // Initial Load - Select First L3 Category if available
    if (widget.subCategories.isNotEmpty) {
      _onSidebarItemSelected(0);
    } else {
      // Fallback: Load products of L2 itself if no L3
      debugPrint("🟡 No L3 Categories. Loading products for L2 ID: ${widget.parentId}");
       _fetchProducts(widget.parentId, ""); 
    }

    _listController.addListener(() {
      if (_listController.position.pixels == _listController.position.maxScrollExtent) {
        if ((_productsData?.paginatorInfo?.total ?? 0) > (_productsData?.data?.length ?? 0)) {
           _page++;
           _categoryBloc?.add(FetchSubCategoryEvent(_filters, _page));
        }
      }
    });
  }

  void _onSidebarItemSelected(int index) {
      if (widget.subCategories.isEmpty || index >= widget.subCategories.length) return;

      setState(() {
        _selectedSidebarIndex = index;
        final cat = widget.subCategories[index];
        _fetchProducts(_getId(cat), _getSlug(cat));
      });
  }

  void _fetchProducts(String id, String slug) {
    setState(() {
      _isLoading = true;
      _productsData = null; // Clear previous products
      _page = 1;
      _currentSlug = slug;
      _filters = [{"key": "\"category_id\"", "value": "\"$id\""}];
    });
    _categoryBloc?.add(FilterFetchEvent(slug));
  }

  String _getId(dynamic cat) {
    try { return (cat as dynamic).id?.toString() ?? ""; } catch (_) { return ""; }
  }

  String _getSlug(dynamic cat) {
    try { return (cat as dynamic).slug?.toString() ?? ""; } catch (_) { return ""; }
  }

  String _getName(dynamic cat) {
    try { return (cat as dynamic).name ?? (cat as dynamic).label ?? ""; } catch (_) { return ""; }
  }

  String _getImage(dynamic cat) {
    try {
      final c = cat as dynamic;
      if (c.bannerUrl != null) return c.bannerUrl;
      if (c.imageUrl != null) return c.imageUrl;
      if (c.icon != null) return c.icon;
      if (c.logoPath != null) return c.logoPath;
    } catch (_) {}
    return "";
  }
  
  // Reuse Icon Logic
  IconData _categoryIconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('event') || n.contains('party')) return Icons.event_outlined;
    if (n.contains('dairy') || n.contains('bread')) return Icons.breakfast_dining_outlined; 
    if (n.contains('grain') || n.contains('rice')) return Icons.grass_outlined; 
    if (n.contains('fruit')) return Icons.apple_outlined;
    if (n.contains('vegetable') || n.contains('farm')) return Icons.eco_outlined;
    if (n.contains('meat') || n.contains('fish')) return Icons.set_meal_outlined;
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SIDEBAR (Level 3 Categories)
          if (widget.subCategories.isNotEmpty)
          Container(
            width: 85, // Sidebar Width
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5), // Light Grey Bg to match Blinkit
              border: Border(right: BorderSide(color: Colors.grey[200]!)),
            ),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: widget.subCategories.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 0),
              itemBuilder: (context, index) {
                return _buildSidebarItem(index);
              },
            ),
          ),

          // PRODUCT LIST
          Expanded(
            child: BlocListener<CartScreenBloc, CartScreenBaseState>(
               listener: (context, state) {
                  if (state is UpdateCartState) {
                      if (state.status == CartStatus.success) {
                        context.read<CartScreenBloc>().add(FetchCartDataEvent());
                        ShowMessage.successNotification("Cart Updated", context);
                      }
                  }
                  if (state is FetchCartDataState && state.status == CartStatus.success) {
                      GlobalData.updateCartState(state.cartDetailsModel);
                  }
               },
               child: BlocConsumer<CategoryBloc, CategoriesBaseState>(
                 listener: (context, state) {
                    if (state is FilterFetchState) {
                        _filterData = state.filterModel;
                        _categoryBloc?.add(FetchSubCategoryEvent(_filters, _page));
                    }
                    if (state is FetchSubCategoryState) {
                        if (state.status == CategoriesStatus.success) {
                          setState(() {
                            _isLoading = false;
                            if (_page == 1) {
                              _productsData = state.categoriesData;
                            } else {
                              _productsData?.data?.addAll(state.categoriesData?.data ?? []);
                            }
                          });
                        } else if (state.status == CategoriesStatus.fail) {
                           setState(() => _isLoading = false);
                        }
                    }
                    if (state is AddToCartSubCategoriesState) {
                       if (state.status == CategoriesStatus.success) {
                           context.read<CartScreenBloc>().add(FetchCartDataEvent());
                           GlobalData.cartUpdateStream.add(null);
                           ShowMessage.successNotification(state.successMsg ?? "Added", context);
                       }
                    }
                 },
                 builder: (context, state) {
                    if (_isLoading && _page == 1) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFFBDB76B)));
                    }

                    if (_productsData?.data == null || _productsData!.data!.isEmpty) {
                       return Center(child: Text("No products found", style: TextStyle(color: Colors.grey[400])));
                    }

                    return GridView.builder(
                      controller: _listController,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80), // Bottom padding for FAB/Cart
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.58, // Adjusted for vertical card
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _productsData!.data!.length,
                      itemBuilder: (context, index) {
                         return BlinkitProductCard(
                            data: _productsData!.data![index],
                            isLoggedIn: appStoragePref.getCustomerLoggedIn(),
                            subCategoryBloc: _categoryBloc,
                            onAddToCart: (id, qty) {
                               GlobalData.optimisticUpdateCart(id, qty);
                               _categoryBloc?.add(AddToCartSubCategoryEvent(id, qty));
                            },
                            onAddToWishlist: (id, isIn, prod) { /* Optional implement */ },
                         );
                      },
                    );
                 },
               ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index) {
    final cat = widget.subCategories[index];
    final bool isSelected = _selectedSidebarIndex == index;
    final String name = _getName(cat);
    final String imgUrl = _getImage(cat);

    return GestureDetector(
      onTap: () => _onSidebarItemSelected(index),
      child: Container(
        // Full width container
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          border: isSelected 
             ? const Border(left: BorderSide(color: Color(0xFF27C16B), width: 4))
             : const Border(left: BorderSide(color: Colors.transparent, width: 4)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            // Image Circle
            Container(
              height: 50, width: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[200]!),
                image: imgUrl.isNotEmpty 
                   ? DecorationImage(image: NetworkImage(imgUrl), fit: BoxFit.cover) 
                   : null,
              ),
              child: imgUrl.isEmpty 
                 ? Icon(_categoryIconFor(name), size: 24, color: Colors.grey[400]) 
                 : null,
            ),
            const SizedBox(height: 8),
            // Text
            Text(
              name, 
              textAlign: TextAlign.center, 
              maxLines: 2, 
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11, 
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.black : Colors.grey[700],
                height: 1.2
              )
            ),
          ],
        ),
      ),
    );
  }
}
