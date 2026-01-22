import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagisto_app_demo/screens/categories_screen/utils/index.dart';
import 'package:bagisto_app_demo/utils/app_global_data.dart';
import 'package:bagisto_app_demo/utils/app_constants.dart';
import 'package:bagisto_app_demo/utils/shared_preference_helper.dart';
import 'package:bagisto_app_demo/widgets/image_view.dart';
import 'widget/blinkit_product_card.dart'; 
import 'package:bagisto_app_demo/widgets/show_message.dart';

// 🟢 FIX: All necessary Cart imports
import 'package:bagisto_app_demo/screens/cart_screen/bloc/cart_screen_bloc.dart';
import 'package:bagisto_app_demo/screens/cart_screen/bloc/cart_screen_event.dart';
import 'package:bagisto_app_demo/screens/cart_screen/bloc/cart_screen_state.dart';
import 'package:bagisto_app_demo/screens/cart_screen/utils/cart_index.dart'; // For CartStatus

class SidebarCategoryScreen extends StatefulWidget {
  const SidebarCategoryScreen({Key? key}) : super(key: key);

  @override
  State<SidebarCategoryScreen> createState() => _SidebarCategoryScreenState();
}

class _SidebarCategoryScreenState extends State<SidebarCategoryScreen> {
  // Data
  List<dynamic> _categories = [];
  List<dynamic> _subCategories = []; 
  int _selectedSidebarIndex = 0;
  int _selectedSubCatIndex = -1; 
  
  // Logic
  CategoryBloc? _categoryBloc;
  NewProductsModel? _productsData;
  GetFilterAttribute? _filterData; 
  String _currentSlug = "";        
  
  bool _isLoading = false;
  final ScrollController _listController = ScrollController();
  int _page = 1;
  List<Map<String, dynamic>> _filters = [];

  // Auto-Retry Timer
  Timer? _retryTimer;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _categoryBloc = context.read<CategoryBloc>();
    
    _loadCategories();

    if (_categories.isEmpty) {
      _startAutoRetry();
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

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _startAutoRetry() {
    _retryTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _retryCount++;
      _loadCategories();
      
      if (_categories.isNotEmpty || _retryCount > 10) {
        timer.cancel();
      }
    });
  }

  void _loadCategories() {
    if (GlobalData.categoriesDrawerData != null) {
      final list = GlobalData.categoriesDrawerData!.data ?? [];
      if (list.isNotEmpty) {
        if (mounted) {
          setState(() {
            _categories = list;
            _onSidebarItemSelected(0); 
          });
        }
        return;
      }
    }

    var offlineData = appStoragePref.getDrawerCategories();
    if (offlineData != null) {
      GlobalData.categoriesDrawerData = offlineData;
      final list = offlineData.data ?? [];
      if (list.isNotEmpty) {
        if (mounted) {
          setState(() {
            _categories = list;
            _onSidebarItemSelected(0);
          });
        }
      }
    }
  }

  void _onSidebarItemSelected(int index) {
    if (_categories.isEmpty || index >= _categories.length) return;

    setState(() {
      _selectedSidebarIndex = index;
      final cat = _categories[index];
      
      try {
        _subCategories = ((cat as dynamic).children as List?) ?? [];
      } catch (e) {
        _subCategories = [];
      }
      
      _selectedSubCatIndex = -1; 
      
      _fetchProducts(_getId(cat), _getSlug(cat));
    });
  }

  void _onSubCategorySelected(int index) {
    setState(() {
      _selectedSubCatIndex = index;
      String idToFetch;
      String slugToFetch;
      
      if (index == -1) {
        final cat = _categories[_selectedSidebarIndex];
        idToFetch = _getId(cat);
        slugToFetch = _getSlug(cat);
      } else {
        final subCat = _subCategories[index];
        idToFetch = _getId(subCat);
        slugToFetch = _getSlug(subCat);
      }
      
      _fetchProducts(idToFetch, slugToFetch);
    });
  }

  void _fetchProducts(String id, String slug) {
    setState(() {
      _isLoading = true;
      _productsData = null;
      _page = 1;
      _currentSlug = slug;
      _filters = [{"key": "\"category_id\"", "value": "\"$id\""}];
    });
    _categoryBloc?.add(FilterFetchEvent(slug));
  }

  /// SAFE HELPERS
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

  /// ICON MAPPER
  IconData _categoryIconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('event') || n.contains('party') || n.contains('wedding')) return Icons.event_outlined;
    if (n.contains('dairy') || n.contains('bread') || n.contains('breakfast') || n.contains('bakery')) return Icons.breakfast_dining_outlined; 
    if (n.contains('grain') || n.contains('cereal') || n.contains('oat') || n.contains('pulse') || n.contains('rice') || n.contains('atta')) return Icons.grass_outlined; 
    if (n.contains('fruit')) return Icons.apple_outlined;
    if (n.contains('vegetable') || n.contains('farm')) return Icons.eco_outlined;
    if (n.contains('meat') || n.contains('fish') || n.contains('chicken') || n.contains('non veg')) return Icons.set_meal_outlined;
    if (n.contains('egg')) return Icons.egg_outlined; 
    if (n.contains('grocery') || n.contains('staple')) return Icons.shopping_bag_outlined;
    if (n.contains('oil') || n.contains('ghee')) return Icons.opacity_outlined;
    if (n.contains('spice') || n.contains('masala')) return Icons.whatshot_outlined;
    if (n.contains('snack') || n.contains('chip') || n.contains('biscuit') || n.contains('namkeen')) return Icons.fastfood_outlined;
    if (n.contains('beverage') || n.contains('drink') || n.contains('juice') || n.contains('tea') || n.contains('coffee')) return Icons.local_cafe_outlined;
    if (n.contains('sweet') || n.contains('chocolate') || n.contains('ice cream')) return Icons.icecream_outlined;
    if (n.contains('personal') || n.contains('beauty') || n.contains('skin') || n.contains('hair') || n.contains('face')) return Icons.face_retouching_natural_outlined;
    if (n.contains('home') || n.contains('clean') || n.contains('detergent') || n.contains('wash')) return Icons.cleaning_services_outlined;
    if (n.contains('baby') || n.contains('diaper')) return Icons.child_care_outlined;
    if (n.contains('pet') || n.contains('dog') || n.contains('cat')) return Icons.pets_outlined;
    if (n.contains('kitchen')) return Icons.kitchen_outlined;
    if (n.contains('pharmacy') || n.contains('medicin') || n.contains('health')) return Icons.medication_outlined;
    if (n.contains('book') || n.contains('stationery') || n.contains('office')) return Icons.menu_book_outlined;
    if (n.contains('electr') || n.contains('mobile') || n.contains('phone')) return Icons.devices_outlined;
    if (n.contains('fashion') || n.contains('cloth')) return Icons.checkroom_outlined;
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    if (_categories.isEmpty && GlobalData.categoriesDrawerData != null) {
      _loadCategories();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Categories", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false, 
      ),
      body: _categories.isEmpty
          ? _buildEmptyState()
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT: SIDEBAR
                Container(
                  width: 64, 
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF9CCC65), Color(0xFFDCEDC8)],
                    ),
                  ),
                  child: ListView.builder(
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      return _buildSidebarItem(index);
                    },
                  ),
                ),

                // RIGHT: CONTENT
                Expanded(
                  child: Column(
                    children: [
                      // 1. SUB-CATEGORIES
                      if (_subCategories.isNotEmpty)
                        Container(
                          height: 50,
                          color: Colors.white,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            itemCount: _subCategories.length + 1, 
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              bool isAll = index == 0;
                              int realIndex = index - 1;
                              bool isSelected = _selectedSubCatIndex == realIndex;
                              String label = isAll ? "All" : _getName(_subCategories[realIndex]);

                              return GestureDetector(
                                onTap: () => _onSubCategorySelected(realIndex),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? const Color(0xFF2E7D32) : Colors.black87,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      const Divider(height: 1, thickness: 1),

                      // 2. FILTER & SORT
                      Container(
                        height: 40,
                        color: Colors.white,
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _openSortSheet(),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.swap_vert, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    const Text("Sort", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                            Container(width: 1, height: 20, color: Colors.grey[300]), 
                            Expanded(
                              child: InkWell(
                                onTap: () => _openFilterScreen(),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.tune, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    const Text("Filters", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, thickness: 1),

                      // 3. PRODUCT LIST WITH LISTENERS
                      Expanded(
                        child: BlocListener<CartScreenBloc, CartScreenBaseState>(
                          listener: (context, state) {
                            // 🟢 FIX 1: Split Checks to Fix Type Promotion Errors
                            
                            if (state is UpdateCartState) {
                               if (state.status == CartStatus.success) {
                                  context.read<CartScreenBloc>().add(FetchCartDataEvent());
                                  ShowMessage.successNotification("Cart Updated", context);
                               } else if (state.status == CartStatus.fail) {
                                  ShowMessage.errorNotification("Failed to update", context);
                               }
                            }
                            
                            if (state is RemoveCartItemState) {
                               if (state.status == CartStatus.success) {
                                  context.read<CartScreenBloc>().add(FetchCartDataEvent());
                                  ShowMessage.successNotification("Item Removed", context);
                               } else if (state.status == CartStatus.fail) {
                                  ShowMessage.errorNotification("Failed to remove", context);
                               }
                            }

                            if (state is FetchCartDataState) {
                               if (state.status == CartStatus.success) {
                                   GlobalData.cartCountController.sink.add(state.cartDetailsModel?.itemsQty ?? 0);
                               }
                            }
                          },
                          // Keep existing CategoryBloc consumer
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
                                   // Refresh Cart on initial ADD
                                   context.read<CartScreenBloc>().add(FetchCartDataEvent());
                                   GlobalData.cartUpdateStream.add(null); // 🟢 Notify Cart Screen
                                   GlobalData.cartCountController.sink.add(state.response?.cart?.itemsQty ?? 0);
                                   ShowMessage.successNotification(state.successMsg ?? "Added", context);
                                 } else if (state.status == CategoriesStatus.fail) {
                                   ShowMessage.errorNotification(state.error ?? "Failed", context);
                                 }
                               }
                               // ... (Keep other listeners for Wishlist/Compare)
                            },
                            builder: (context, state) {
                              if (_isLoading && _page == 1) {
                                return const Center(child: CircularProgressIndicator(color: Color(0xFFBDB76B)));
                              }
                              
                              if (_productsData?.data == null || _productsData!.data!.isEmpty) {
                                return Center(child: Text("No products found", style: TextStyle(color: Colors.grey[400])));
                              }

                              return Container(
                                color: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: ListView.builder(
                                  controller: _listController,
                                  padding: const EdgeInsets.only(top: 12, bottom: 80),
                                  itemCount: _productsData!.data!.length,
                                  itemBuilder: (context, index) {
                                    return BlinkitProductCard(
                                      data: _productsData!.data![index],
                                      isLoggedIn: appStoragePref.getCustomerLoggedIn(),
                                      subCategoryBloc: _categoryBloc,
                                      
                                      onAddToCart: (int productId, int quantity) {
                                          _categoryBloc?.add(AddToCartSubCategoryEvent(productId, quantity));
                                      },

                                      onAddToWishlist: (String id, bool isInWishlist, dynamic product) {
                                         bool isLogged = appStoragePref.getCustomerLoggedIn();
                                         if (isLogged) {
                                            setState(() {
                                              (product as NewProducts).isInWishlist = !isInWishlist;
                                            });
                                            if (isInWishlist) {
                                              _categoryBloc?.add(FetchDeleteItemEvent(id, product));
                                            } else {
                                              _categoryBloc?.add(FetchDeleteAddItemCategoryEvent(id, product));
                                            }
                                         } else {
                                            ShowMessage.warningNotification("Please login", context);
                                         }
                                      },
                                    );
                                  },
                                ),
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
    );
  }

  void _openFilterScreen() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context)=>
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.category_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("Loading Categories...", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCategories,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBDB76B)),
            child: const Text("Retry", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index) {
    final cat = _categories[index];
    final bool isSelected = _selectedSidebarIndex == index;
    final String name = _getName(cat);
    final String imgUrl = _getImage(cat);
    const Color activeColor = Color(0xFF2E7D32); 

    return GestureDetector(
      onTap: () => _onSidebarItemSelected(index),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          border: isSelected 
              ? const Border(left: BorderSide(color: activeColor, width: 4))
              : const Border(bottom: BorderSide(color: Colors.white30, width: 1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 40, width: 40, 
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE8F5E9) : Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: imgUrl.isNotEmpty 
                    ? ImageView(url: imgUrl, fit: BoxFit.cover) 
                    : Icon(
                        _categoryIconFor(name), 
                        color: isSelected ? activeColor : Colors.black54, 
                        size: 20
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9, 
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}