import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagisto_app_demo/screens/categories_screen/utils/index.dart';
import 'package:bagisto_app_demo/utils/app_global_data.dart';
import 'package:bagisto_app_demo/utils/shared_preference_helper.dart';
import 'package:bagisto_app_demo/widgets/blinkit_product_card.dart';
import 'package:bagisto_app_demo/widgets/show_message.dart';
import 'package:bagisto_app_demo/screens/cart_screen/bloc/cart_screen_bloc.dart';
import 'package:bagisto_app_demo/screens/cart_screen/bloc/cart_screen_event.dart';
import 'package:bagisto_app_demo/screens/cart_screen/bloc/cart_screen_state.dart';
import 'package:bagisto_app_demo/screens/cart_screen/utils/cart_index.dart';
import 'package:bagisto_app_demo/screens/filter_screen/utils/index.dart' hide FilterFetchState;
import 'package:cached_network_image/cached_network_image.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data class representing a top-level sidebar entry (category group)
// ─────────────────────────────────────────────────────────────────────────────
class FeaturedSidebarEntry {
  final String name;
  final String id;
  final String slug;
  final String imageUrl;
  final IconData icon;

  const FeaturedSidebarEntry({
    required this.name,
    required this.id,
    required this.slug,
    this.imageUrl = '',
    required this.icon,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Predefined section configs — maps a section title to sidebar entries
// Add more entries here whenever you need a new featured section.
// ─────────────────────────────────────────────────────────────────────────────
class FeaturedSectionConfig {
  static const Map<String, List<FeaturedSidebarEntry>> _sectionMap = {
    // ── Sweet Tooth ──────────────────────────────────────────────────────────
    'sweet tooth': [
      FeaturedSidebarEntry(
        name: 'Sweets &\nChocolates',
        id: '24',
        slug: 'sweets-chocolates',
        imageUrl: 'https://ecom.thesmartedgetech.com/image_proxy.php?path=category/1772798725_Cadbury_Chocos.png',
        icon: Icons.cake_outlined,
      ),
      FeaturedSidebarEntry(
        name: 'Ice Creams\n& More',
        id: '36',
        slug: 'ice-creams-more-',
        imageUrl: 'https://ecom.thesmartedgetech.com/image_proxy.php?path=category/1772104057_three-ice-cream-.webp',
        icon: Icons.icecream_outlined,
      ),
      FeaturedSidebarEntry(
        name: 'Bakery &\nBiscuits',
        id: '32',
        slug: 'bakery-biscuits-',
        imageUrl: 'https://ecom.thesmartedgetech.com/image_proxy.php?path=category/1772103390_bakery.png',
        icon: Icons.bakery_dining_outlined,
      ),
    ],
    // ── Dry Fruit, Masala & Oil ──────────────────────────────────────────────
    'dry fruit, masala & oil': [
      FeaturedSidebarEntry(
        name: 'Oil, Ghee\n& Masala',
        id: '30',
        slug: 'oil-ghee-masala',
        imageUrl: 'https://ecom.thesmartedgetech.com/image_proxy.php?path=category/1772103122_Oil_ghee_masala.png',
        icon: Icons.opacity_outlined,
      ),
      FeaturedSidebarEntry(
        name: 'Dry Fruits\n& Cereals',
        id: '33',
        slug: 'dry-fruits-cereals',
        imageUrl: 'https://ecom.thesmartedgetech.com/image_proxy.php?path=category/1772103454_DryFruits.png',
        icon: Icons.spa_outlined,
      ),
    ],
    // alias with "and"
    'dry fruit, masala and oil': [
      FeaturedSidebarEntry(
        name: 'Oil, Ghee\n& Masala',
        id: '30',
        slug: 'oil-ghee-masala',
        imageUrl: 'https://ecom.thesmartedgetech.com/image_proxy.php?path=category/1772103122_Oil_ghee_masala.png',
        icon: Icons.opacity_outlined,
      ),
      FeaturedSidebarEntry(
        name: 'Dry Fruits\n& Cereals',
        id: '33',
        slug: 'dry-fruits-cereals',
        imageUrl: 'https://ecom.thesmartedgetech.com/image_proxy.php?path=category/1772103454_DryFruits.png',
        icon: Icons.spa_outlined,
      ),
    ],
    // alias with no comma
    'dry fruit masala & oil': [
      FeaturedSidebarEntry(
        name: 'Oil, Ghee\n& Masala',
        id: '30',
        slug: 'oil-ghee-masala',
        imageUrl: 'https://ecom.thesmartedgetech.com/image_proxy.php?path=category/1772103122_Oil_ghee_masala.png',
        icon: Icons.opacity_outlined,
      ),
      FeaturedSidebarEntry(
        name: 'Dry Fruits\n& Cereals',
        id: '33',
        slug: 'dry-fruits-cereals',
        imageUrl: 'https://ecom.thesmartedgetech.com/image_proxy.php?path=category/1772103454_DryFruits.png',
        icon: Icons.spa_outlined,
      ),
    ],
    'dry fruit masala and oil': [
      FeaturedSidebarEntry(
        name: 'Oil, Ghee\n& Masala',
        id: '30',
        slug: 'oil-ghee-masala',
        imageUrl: 'https://ecom.thesmartedgetech.com/image_proxy.php?path=category/1772103122_Oil_ghee_masala.png',
        icon: Icons.opacity_outlined,
      ),
      FeaturedSidebarEntry(
        name: 'Dry Fruits\n& Cereals',
        id: '33',
        slug: 'dry-fruits-cereals',
        imageUrl: 'https://ecom.thesmartedgetech.com/image_proxy.php?path=category/1772103454_DryFruits.png',
        icon: Icons.spa_outlined,
      ),
    ],
  };

  /// Returns sidebar entries for a section title (case-insensitive).
  static List<FeaturedSidebarEntry>? forTitle(String title) {
    return _sectionMap[title.trim().toLowerCase()];
  }

  /// True when we have a custom config for this section title.
  static bool hasConfig(String title) =>
      _sectionMap.containsKey(title.trim().toLowerCase());
}

// ─────────────────────────────────────────────────────────────────────────────
// The Screen
// ─────────────────────────────────────────────────────────────────────────────
class FeaturedSectionSidebarScreen extends StatefulWidget {
  final String title;
  final List<FeaturedSidebarEntry> sidebarEntries;

  const FeaturedSectionSidebarScreen({
    Key? key,
    required this.title,
    required this.sidebarEntries,
  }) : super(key: key);

  @override
  State<FeaturedSectionSidebarScreen> createState() =>
      _FeaturedSectionSidebarScreenState();
}

class _FeaturedSectionSidebarScreenState
    extends State<FeaturedSectionSidebarScreen> {
  int _selectedIndex = 0;
  List<dynamic> _l3Categories = []; // 🟢 NEW: Stores L3 subcategories

  CategoryBloc? _categoryBloc;
  NewProductsModel? _productsData;
  GetFilterAttribute? _filterData;
  String _currentCatId = '';
  String _currentSlug = '';

  bool _isLoading = false;
  int _page = 1;
  List<Map<String, dynamic>> _filters = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _categoryBloc = context.read<CategoryBloc>();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        final total = _productsData?.paginatorInfo?.total ?? 0;
        final loaded = _productsData?.data?.length ?? 0;
        if (total > loaded) {
          _page++;
          _categoryBloc?.add(FetchSubCategoryEvent(_filters, _page));
        }
      }
    });

    // Select first sidebar item on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.sidebarEntries.isNotEmpty) {
        _selectEntry(0);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _selectEntry(int index) {
    if (index < 0 || index >= widget.sidebarEntries.length) return;
    final entry = widget.sidebarEntries[index];
    
    // 🟢 SEARCH FOR THIS CATEGORY IN GLOBALDATA TO FIND ITS CHILDREN
    dynamic l2Category;
    if (GlobalData.categoriesDrawerData?.data != null) {
      for (var root in GlobalData.categoriesDrawerData!.data!) {
        if (root.children != null) {
          for (var l2 in root.children!) {
            if (l2.id.toString() == entry.id) {
              l2Category = l2;
              break;
            }
          }
        }
        if (l2Category != null) break;
      }
    }

    List<dynamic> l3Cats = [];
    if (l2Category != null && (l2Category as dynamic).children != null) {
       l3Cats = (l2Category as dynamic).children as List<dynamic>;
    }

    String fetchId = entry.id;
    String fetchSlug = entry.slug;

    // 🟢 If it has L3 categories, select the first one to fetch products
    if (l3Cats.isNotEmpty) {
       fetchId = (l3Cats[0] as dynamic).id.toString();
       fetchSlug = (l3Cats[0] as dynamic).slug.toString();
    }

    setState(() {
      _selectedIndex = index;
      _l3Categories = l3Cats;
      _isLoading = true;
      _productsData = null;
      _page = 1;
      _currentCatId = fetchId;
      _currentSlug = fetchSlug;
      _filters = [
        {"key": "\"category_id\"", "value": "\"$fetchId\""}
      ];
    });
    _categoryBloc?.add(FilterFetchEvent(fetchSlug));
  }

  void _selectL3(dynamic l3Cat) {
    final fetchId = (l3Cat as dynamic).id.toString();
    final fetchSlug = (l3Cat as dynamic).slug.toString();
    setState(() {
      _isLoading = true;
      _productsData = null;
      _page = 1;
      _currentCatId = fetchId;
      _currentSlug = fetchSlug;
      _filters = [
        {"key": "\"category_id\"", "value": "\"$fetchId\""}
      ];
    });
    _categoryBloc?.add(FilterFetchEvent(fetchSlug));
  }

  // ── Sidebar Item Widget ──────────────────────────────────────────────────
  Widget _buildSidebarItem(int index) {
    final entry = widget.sidebarEntries[index];
    final selected = index == _selectedIndex;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _selectEntry(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: selected
              ? (isDark
                  ? const Color(0xFF1B3A1F)
                  : const Color(0xFFE8F5E9))
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              width: 3,
              color: selected
                  ? const Color(0xFF27C16B)
                  : Colors.transparent,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Image or Icon ──
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: entry.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: entry.imageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Icon(
                        entry.icon,
                        size: 28,
                        color: selected
                            ? const Color(0xFF27C16B)
                            : theme.textTheme.bodySmall?.color,
                      ),
                      placeholder: (_, __) => Icon(
                        entry.icon,
                        size: 28,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    )
                  : Icon(
                      entry.icon,
                      size: 28,
                      color: selected
                          ? const Color(0xFF27C16B)
                          : theme.textTheme.bodySmall?.color,
                    ),
            ),
            const SizedBox(height: 6),
            // ── Label ──
            Text(
              entry.name,
              maxLines: 3,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                height: 1.2,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? const Color(0xFF27C16B)
                    : theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Product Area ─────────────────────────────────────────────────────────
  Widget _buildProductArea() {
    return BlocListener<CartScreenBloc, CartScreenBaseState>(
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
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF27C16B)),
            );
          }

          final products = _productsData?.data;
          if (products == null || products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 56,
                      color: Colors.grey.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  Text(
                    "No products found",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 80),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.58,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return BlinkitProductCard(
                data: products[index],
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0.5,
        iconTheme:
            IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── LEFT SIDEBAR ─────────────────────────────────────────────────
            Container(
              width: 76,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1A1A1A)
                    : theme.colorScheme.secondaryContainer.withOpacity(0.4),
                border: Border(
                  right: BorderSide(color: theme.dividerColor),
                ),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: widget.sidebarEntries.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: theme.dividerColor.withOpacity(0.5),
                ),
                itemBuilder: (context, index) => _buildSidebarItem(index),
              ),
            ),

            // ── RIGHT: PRODUCTS ───────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🟢 L3 Horizontal Tabs 
                  if (_l3Categories.isNotEmpty)
                    Container(
                      height: 40,
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _l3Categories.length,
                        itemBuilder: (context, idx) {
                          final l3 = _l3Categories[idx];
                          final id = (l3 as dynamic).id.toString();
                          final name = (l3 as dynamic).name ?? (l3 as dynamic).label ?? "";
                          final isSelected = _currentCatId == id;

                          return GestureDetector(
                            onTap: () => _selectL3(l3),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected 
                                   ? const Color(0xFF27C16B) 
                                   : (isDark ? const Color(0xFF2A2A2A) : theme.cardColor),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected 
                                     ? Colors.transparent 
                                     : (isDark ? Colors.white24 : Colors.grey[300]!),
                                ),
                              ),
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  
                  // Product Grid
                  Expanded(child: _buildProductArea()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
