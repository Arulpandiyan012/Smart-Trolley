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
import 'package:bagisto_app_demo/screens/filter_screen/utils/index.dart' hide FilterFetchState;

class SubCategorySidebarScreen extends StatefulWidget {
  final String title;
  final String parentId;
  final String parentSlug; // 🟢 NEW
  final List<dynamic> subCategories; // These are L3 Categories
  final int initialSelectedIndex;

  const SubCategorySidebarScreen({
    Key? key, 
    required this.title,
    required this.parentId,
    required this.parentSlug, // 🟢 NEW
    required this.subCategories,
    this.initialSelectedIndex = 0,
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
    
    // Initial Load - Select specific L3 Category if available
    if (widget.subCategories.isNotEmpty) {
      _selectedSidebarIndex = (widget.initialSelectedIndex >= 0 && widget.initialSelectedIndex < widget.subCategories.length) 
          ? widget.initialSelectedIndex 
          : 0;
      debugPrint("🟢 AUTO-SELECT Index: $_selectedSidebarIndex (Total Subcats: ${widget.subCategories.length})");
      
      // 🟢 DELAY: Ensure BlocConsumer is mounted before adding event
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onSidebarItemSelected(_selectedSidebarIndex);
      });
    } else {
       // Fallback: Load products for Parent itself if no children
       debugPrint("🟡 No Sub-Categories. Loading products for Parent: ${widget.title} (ID: ${widget.parentId})");
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted) _fetchProducts(widget.parentId, widget.parentSlug);
       });
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
        
        // 🟢 AUTO-SELECT L3 logic
        final children = (cat as dynamic).children as List?;
        
        if (children != null && children.isNotEmpty) {
           final firstL3 = children[0];
           debugPrint("🟢 Auto-selecting first L3: ${_getName(firstL3)} (Slug: ${_getSlug(firstL3)})");
           _fetchProducts(_getId(firstL3), _getSlug(firstL3));
        } else {
           debugPrint("🟡 No L3 found. Fetching L2: ${_getName(cat)}");
           _fetchProducts(_getId(cat), _getSlug(cat));
        }
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
    // 🟢 FIX: Handle Empty Subcategories (L3)
    // If no L3 categories exist, we should just show the L2 Products (Parent)
    // instead of returning an empty SizedBox (which causes a BLACK SCREEN).
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.subCategories.isEmpty) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(widget.title, style: TextStyle(color: theme.textTheme.titleLarge?.color, fontWeight: FontWeight.bold, fontSize: 16)),
            backgroundColor: theme.appBarTheme.backgroundColor,
            elevation: 0.5,
            iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
          ),
          body: BlocConsumer<CategoryBloc, CategoriesBaseState>(
             listener: (context, state) {
                if (state is FilterFetchState) {
                    _filterData = state.filterModel;
                    // 🟢 ALWAYS try to fetch products even if filters fail/error
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
                    } else {
                       // 🔴 ERROR Handle
                       debugPrint("❌ FetchSubCategoryState Failed: ${state.error}");
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
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF27C16B)));
                }

                if (_productsData?.data == null || _productsData!.data!.isEmpty) {
                   return Center(child: Text("No products found", style: TextStyle(color: Colors.grey[400])));
                }

                return GridView.builder(
                  controller: _listController,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 80), 
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.58, 
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
                        onAddToWishlist: (id, isIn, prod) {},
                     );
                  },
                );
             },
           ),
        );
    }
    
    // Get Selected L2
    // Get Selected Sidebar Item (Child of the passed Root)
    if (_selectedSidebarIndex >= widget.subCategories.length) _selectedSidebarIndex = 0;
    final selectedSidebarItem = widget.subCategories[_selectedSidebarIndex];
    
    // Check for deeper children (L4?)
    final List<dynamic> deeperChildren = ((selectedSidebarItem as dynamic).children as List?) ?? [];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.title, style: TextStyle(color: theme.textTheme.titleLarge?.color, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0.5,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SIDEBAR (Level 2 Categories)
          Container(
            width: 70, 
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5), 
              border: Border(right: BorderSide(color: theme.dividerColor)),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 100), // 🟢 Added padding to avoid system navigation overlap
              itemCount: widget.subCategories.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 0),
              itemBuilder: (context, index) {
                return _buildSidebarItem(index);
              },
            ),
          ),

          // RIGHT: L3 + PRODUCTS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🟢 Sort & Filter Bar
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _openSortSheet(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.swap_vert, size: 18, color: Theme.of(context).textTheme.bodySmall?.color),
                              const SizedBox(width: 6),
                              Text("Sort", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Theme.of(context).textTheme.titleSmall?.color)),
                            ],
                          ),
                        ),
                      ),
                      Container(width: 1, height: 24, color: Theme.of(context).dividerColor),
                      Expanded(
                        child: InkWell(
                          onTap: () => _openFilterScreen(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.tune, size: 18, color: Theme.of(context).textTheme.bodySmall?.color),
                              const SizedBox(width: 6),
                              Text("Filters", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Theme.of(context).textTheme.titleSmall?.color)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 🟢 NEW: L3 Categories Horizontal List (if available)
                if (deeperChildren.isNotEmpty)
                  Container(
                    height: 40,
                    margin: const EdgeInsets.only(bottom: 8, top: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: deeperChildren.length,
                      itemBuilder: (context, index) {
                         final l3 = deeperChildren[index];
                         final isSelected = _currentSlug == _getSlug(l3);
                         return GestureDetector(
                           onTap: () {
                              final id = _getId(l3);
                              final slug = _getSlug(l3);
                              debugPrint("🟢 Selected L3: ${_getName(l3)} (ID: $id)");
                              _fetchProducts(id, slug);
                           },
                           child: Container(
                             margin: const EdgeInsets.only(right: 8),
                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                             decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF27C16B) : (isDark ? const Color(0xFF2A2A2A) : Theme.of(context).cardColor),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? Colors.transparent : (isDark ? Colors.white24 : Colors.grey[300]!)
                              ),
                             ),
                             alignment: Alignment.center,
                             child: Text(
                               _getName(l3),
                               style: TextStyle(
                                 fontSize: 12,
                                 fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                 color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                               ),
                             ),
                           ),
                         );
                      },
                    ),
                  ),

                // PRODUCT LIST
                Expanded(
                  child: BlocListener<CartScreenBloc, CartScreenBaseState>(
                     listener: (context, state) {
                        if (state is UpdateCartState && state.status == CartStatus.success) {
                              context.read<CartScreenBloc>().add(FetchCartDataEvent());
                              ShowMessage.successNotification("Cart Updated", context);
                        }
                        if (state is FetchCartDataState && state.status == CartStatus.success) {
                            GlobalData.updateCartState(state.cartDetailsModel);
                        }
                     },
                     child: BlocConsumer<CategoryBloc, CategoriesBaseState>(
                       listener: (context, state) {
                          if (state is FilterFetchState) {
                              _filterData = state.filterModel;
                              // 🟢 ALWAYS try to fetch products even if filters fail
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
                              } else {
                                 debugPrint("❌ FetchSubCategoryState Failed: ${state.error}");
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
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80), 
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.58, 
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
          ),
        ],
      ),
    ),
   );
  }

  Widget _buildSidebarItem(int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cat = widget.subCategories[index];
    final bool isSelected = _selectedSidebarIndex == index;
    final String name = _getName(cat);
    final String imgUrl = _getImage(cat);

    return GestureDetector(
      onTap: () => _onSidebarItemSelected(index),
      child: Container(
        // Full width container
        decoration: BoxDecoration(
          color: isSelected 
             ? (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8F5E9)) 
             : Colors.transparent,
          border: isSelected 
             ? const Border(left: BorderSide(color: Color(0xFF27C16B), width: 4))
             : const Border(left: BorderSide(color: Colors.transparent, width: 4)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          children: [
            // Image Circle
            Container(
              height: 46, width: 46,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: theme.dividerColor),
              ),
              child: ClipOval(
                  child: imgUrl.isNotEmpty 
                     ? Image.network(imgUrl, fit: BoxFit.contain, errorBuilder: (c, e, s) => Icon(_categoryIconFor(name), size: 22, color: Colors.grey[400]))
                     : Icon(_categoryIconFor(name), size: 22, color: Colors.grey[400])
              )
            ),
            const SizedBox(height: 6),
            // Text
            Text(
              name, 
              textAlign: TextAlign.center, 
              maxLines: 2, 
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11, 
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? theme.textTheme.bodyLarge?.color : theme.textTheme.bodySmall?.color,
                height: 1.2
              )
            ),
          ],
        ),
      ),
    );
  }

  void _openFilterScreen() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) =>
        SubCategoriesFilterScreen(
          categorySlug: _currentSlug,
          subCategoryBloc: _categoryBloc,
          page: _page,
          data: _filterData,
          filters: _filters,
        ),
    ));
  }

  void _openSortSheet() {
    showModalBottomSheet(
      backgroundColor: Theme.of(context).cardColor,
      context: context,
      builder: (ctx) => BlocProvider(
        create: (context) => FilterBloc(FilterRepositoryImp()),
        child: SortBottomSheet(
          categorySlug: _currentSlug,
          page: _page,
          filters: _filters,
          subCategoryBloc: _categoryBloc,
        ),
      )
    );
  }
}
