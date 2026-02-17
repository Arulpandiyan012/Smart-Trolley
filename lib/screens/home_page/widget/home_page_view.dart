/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'dart:async'; 
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; 

import '../data_model/theme_customization.dart' as theme;
import '../utils/index.dart' hide Translations;
import 'package:bagisto_app_demo/screens/home_page/bloc/home_page_event.dart';

import 'package:bagisto_app_demo/screens/home_page/widget/blinkit_category_grid.dart'; // 🟢 NEW IMPORT
import 'package:bagisto_app_demo/screens/categories_screen/sidebar_category_screen.dart'; // 🟢 For See All Nav
import 'package:bagisto_app_demo/screens/categories_screen/bloc/categories_bloc.dart'; // 🟢 For Provider
import 'package:bagisto_app_demo/screens/categories_screen/bloc/categories_repository.dart'; // 🟢 For Repo
import 'new_product_view.dart';
import 'reach_top.dart'; 

import 'package:bagisto_app_demo/screens/drawer_sub_categories/utils/index.dart'
    show drawerSubCategoryScreen, CategoriesArguments, categoryScreen;
import 'package:bagisto_app_demo/screens/cart_screen/utils/cart_index.dart';
import 'package:cached_network_image/cached_network_image.dart'; 

String _catLabel(dynamic cat) {
  try { final v = (cat as dynamic).name;  if (v is String && v.trim().isNotEmpty) return v.trim(); } catch (_) {}
  try { final v = (cat as dynamic).label; if (v is String && v.trim().isNotEmpty) return v.trim(); } catch (_) {}
  try { final v = (cat as dynamic).title; if (v is String && v.trim().isNotEmpty) return v.trim(); } catch (_) {}
  if (cat is Map) {
    for (final k in const ['name','label','title']) {
      final v = cat[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
  }
  return 'Category';
}

String _catSlug(dynamic cat) {
  try { final v = (cat as dynamic).slug; if (v is String && v.trim().isNotEmpty) return v.trim(); } catch (_) {}
  if (cat is Map) {
    final v = cat['slug'];
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  return '';
}

String _catId(dynamic cat) {
  try {
    final v = (cat as dynamic).id;
    if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
  } catch (_) {}
  if (cat is Map) {
    final v = cat['id'];
    if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
  }
  return '';
}

String _catBannerUrl(dynamic cat) {
  try { final v = (cat as dynamic).bannerUrl; if (v is String && v.trim().isNotEmpty) return v.trim(); } catch (_) {}
  if (cat is Map) {
    final v = cat['bannerUrl'];
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  return '';
}

String _catDescription(dynamic cat) {
  try { final v = (cat as dynamic).description; if (v is String && v.trim().isNotEmpty) return v.trim(); } catch (_) {}
  if (cat is Map) {
    final v = cat['description'];
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  return '';
}

List<dynamic> _catChildren(dynamic cat) {
  try { final v = (cat as dynamic).children; if (v is List) return v; } catch (_) {}
  if (cat is Map) {
    final v = cat['children'];
    if (v is List) return v;
  }
  return const [];
}

class _Section {
  final String title;
  final String type; // 🟢 New Field
  final List<dynamic> items; // Can be products OR mock categories
  _Section(this.title, this.type, this.items);
}

IconData _categoryIconFor(String name) {
  final n = name.toLowerCase();
  
  if (n.contains('fruit') || n.contains('seasonal') || n.contains('apple')) return Icons.apple_outlined;
  if (n.contains('veg') || n.contains('farm') || n.contains('spa')) return Icons.spa_outlined;
  if (n.contains('milk') || n.contains('dairy') || n.contains('pancakes')) return Icons.breakfast_dining_outlined;
  if (n.contains('egg') || n.contains('protein')) return Icons.egg_outlined;
  if (n.contains('bread') || n.contains('bakery') || n.contains('pavana')) return Icons.bakery_dining_outlined;
  if (n.contains('snack') || n.contains('munch') || n.contains('chips') || n.contains('biscuit')) return Icons.fastfood_outlined;
  if (n.contains('sweet') || n.contains('chocolate') || n.contains('cake')) return Icons.cake_outlined;
  if (n.contains('beverage') || n.contains('drink') || n.contains('juice') || n.contains('soft drink')) return Icons.local_drink_outlined;
  if (n.contains('tea') || n.contains('coffee')) return Icons.coffee_outlined;
  if (n.contains('meat') || n.contains('fish') || n.contains('chicken') || n.contains('non veg')) return Icons.set_meal_outlined;
  if (n.contains('baby') || n.contains('child') || n.contains('diaper')) return Icons.child_care_outlined;
  if (n.contains('care') || n.contains('beauty') || n.contains('face') || n.contains('personal')) return Icons.face_retouching_natural_outlined;
  if (n.contains('kitchen')) return Icons.flatware_outlined;
  if (n.contains('home') || n.contains('clean') || n.contains('household')) return Icons.cleaning_services_outlined;
  if (n.contains('pet') || n.contains('dog') || n.contains('cat')) return Icons.pets_outlined;
  if (n.contains('oil') || n.contains('ghee')) return Icons.opacity_outlined; 
  if (n.contains('spice') || n.contains('masala') || n.contains('powder')) return Icons.flare_outlined;
  if (n.contains('grocery') || n.contains('staple') || n.contains('dal') || n.contains('atta')) return Icons.local_grocery_store_outlined;

  return Icons.category_outlined;
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  _CategoryHeaderDelegate({
    required this.categories,
    required this.onTap,
    required this.selectedIndex,
  });

  final List<dynamic> categories;
  final int selectedIndex;
  final void Function(int index, dynamic cat) onTap;

  @override
  double get minExtent => 72;
  @override
  double get maxExtent => 72;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white, // Flat white
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000), // Very subtle shadow
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 56,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemCount: categories.length,
          itemBuilder: (context, i) {
            final cat = categories[i];
            final label = _catLabel(cat);
            final selected = i == selectedIndex;

            return GestureDetector(
              onTap: () => onTap(i, cat),
              child: Container(
                width: 60,
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(selected ? 1 : 0.9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? const Color(0xFF2E7D32) : const Color(0xFFE0E0E0),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _categoryIconFor(label),
                      size: 14,
                      color: selected ? const Color(0xFF2E7D32) : Colors.black87,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9.5,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                        color: selected ? const Color(0xFF2E7D32) : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CategoryHeaderDelegate old) {
    return old.categories != categories || old.selectedIndex != selectedIndex;
  }
}

class HomePageView extends StatefulWidget {
  final theme.ThemeCustomDataModel? customHomeData;
  final bool isLoading;
  final GetDrawerCategoriesData? getCategoriesData;
  final bool isLogin;
  final HomePageBloc? homePageBloc;
  final bool callPreCache;

  const HomePageView({
    Key? key,
    required this.customHomeData,
    required this.isLoading,
    this.getCategoriesData,
    this.isLogin = false,
    this.homePageBloc,
    this.callPreCache = false,
  }) : super(key: key);

  @override
  State<HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<HomePageView> {
  int _selectedCatIndex = -1;

  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final atBottom = pos.pixels >= (pos.maxScrollExtent - 120);
    if (atBottom != _showBackToTop) {
      setState(() => _showBackToTop = atBottom);
    }
  }

  void _openCategory(dynamic cat) {
    final children = _catChildren(cat);
    final hasChildren = children.isNotEmpty;

    final slug = _catSlug(cat);
    final title = _catLabel(cat);
    final id = _catId(cat);
    final bannerUrl = _catBannerUrl(cat);
    final desc = _catDescription(cat);

    if (hasChildren) {
      Navigator.pushNamed(
        context,
        drawerSubCategoryScreen,
        arguments: CategoriesArguments(
          categorySlug: slug,
          title: title,
          id: id,
          image: bannerUrl,
          parentId: id,
        ),
      );
    } else {
      Navigator.pushNamed(
        context,
        categoryScreen,
        arguments: CategoriesArguments(
          metaDescription: desc,
          categorySlug: slug,
          title: title,
          id: id,
          image: bannerUrl,
        ),
      );
    }
  }



  String? _imageFromAny(dynamic img) {
    try {
      final v = img.imageUrl;
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}
    try {
      final v = img.path;
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}
    try {
      final v = img.original;
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}
    try {
      final v = img.smallImageUrl;
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}
    try {
      final v = img.url;
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}

    if (img is Map) {
      const keys = ['imageUrl', 'path', 'original', 'smallImageUrl', 'url'];
      for (final k in keys) {
        final v = img[k];
        if (v is String && v.isNotEmpty) return v;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final sections = _buildSectionsFromTheme(widget.customHomeData);
    final cats = widget.getCategoriesData?.data ?? const [];

    return BlocConsumer<HomePageBloc, HomePageBaseState>(
      listener: (context, state) {
        if (state is FetchHomeCustomDataState && state.status == Status.success) {
           GlobalData.allProducts?.clear();
           setState(() {}); 
        }
        
        if (state is FetchHomeCategoriesState && state.status == Status.success) {
           GlobalData.categoriesDrawerData = state.getCategoriesData;
           setState(() {});
        }

        if (state is AddToCartState) {
          if (state.status == Status.success) {
            GlobalData.updateCartState(state.graphQlBaseModel?.cart);
            appStoragePref.setCartCount(state.graphQlBaseModel?.cart?.itemsQty ?? 0);
            ShowMessage.successNotification(state.successMsg ?? "Item added to cart successfully", context);
          } else if (state.status == Status.fail) {
            ShowMessage.errorNotification(state.error ?? "Failed to add to cart", context);
          }
        }

        // 🟢 4. Wishlist ADD Success
        if (state is FetchAddWishlistHomepageState) {
          if (state.status == Status.success) {
            ShowMessage.successNotification(state.successMsg ?? "Added to Wishlist", context);
            // setState() is not strictly needed here if we did the optimistic update,
            // but we call it just in case something else updated.
            setState(() {}); 
          } else if (state.status == Status.fail) {
            ShowMessage.errorNotification(state.error ?? "Failed to add to wishlist", context);
            // If failed, we should probably revert the icon, but for now let's just show error.
          }
        }

        // 🟢 5. Wishlist REMOVE Success
        if (state is RemoveWishlistState) {
          if (state.status == Status.success) {
            ShowMessage.successNotification(state.successMsg ?? "Removed from Wishlist", context);
            setState(() {}); 
          } else if (state.status == Status.fail) {
            ShowMessage.errorNotification(state.error ?? "Failed to remove from wishlist", context);
          }
        }
      },
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return ColoredBox(
          color: isDark ? const Color(0xFF121212) : const Color(0xFFC8E6CA), // Dark mode: dark grey, Light mode: soft mint green 
          child: SafeArea(
            top: false,
            child: Stack(
              children: [
                RefreshIndicator(
                  color: Theme.of(context).primaryColor,
                  onRefresh: () async {
                     widget.homePageBloc?.add(FetchHomeCustomData());
                     widget.homePageBloc?.add(FetchHomePageCategoriesEvent());
                     // Wait a moment for UX
                     await Future.delayed(const Duration(seconds: 2));
                  },
                  child: CustomScrollView(
                  controller: _scrollController, 
                  slivers: [
                    // 🟢 REMOVED: Horizontal Scroll Header (Replaced by Grid below)
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    const SliverToBoxAdapter(child: SizedBox(height: 6)),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildPromoBanner(widget.customHomeData),
                        ),
                      ),
                    ),

                    // 🟢 NEW: Trendy 2-Row Category Grid
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Text(
                              "Shop by Category",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Roboto',
                                color: Theme.of(context).textTheme.titleMedium?.color,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          BlinkitCategoryGrid(
                            categories: cats.map((cat) => {
                              'title': _catLabel(cat),
                              'image': _catBannerUrl(cat).isNotEmpty ? _catBannerUrl(cat) : _catBannerUrl(cat), // Backend mapping
                              'slug': _catSlug(cat),
                              'icon': _categoryIconFor(_catLabel(cat)),
                              'cat': cat // Keep original for navigation
                            }).toList(),
                            onTap: (slug, title) {
                              // Recursive search via _handleSeeAll to support all category depths
                              _handleSeeAll(title);
                            },
                          ),
                        ],
                      ),
                    ),

                    for (final s in sections) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), 
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.title,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Roboto', 
                                    color: Theme.of(context).textTheme.titleMedium?.color,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              // Only show "See all" for Products, not Grids (unless we want to)
                              if (s.type == "product_carousel")
                                TextButton(
                                  onPressed: () => _handleSeeAll(s.title),
                                  child: const Text(
                                    'See all',
                                    style: TextStyle(color: Colors.deepOrange),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: s.type == "blinkit_category_grid" 
                            ? BlinkitCategoryGrid(
                                categories: s.items,
                                onTap: (link, title) {
                                  // Handle Navigation. For now, try to open by Title or Slug
                                  // The 'link' from backend is like 'category_slug_veg'.
                                  // We can map this to real categories if needed, or just open generic.
                                  _handleSeeAll(title); 
                                },
                              )
                            : NewProductView(
                                model: s.items,
                                title: s.title,
                                isLogin: widget.isLogin,
                                isRecentProduct: false,
                                callPreCache: widget.callPreCache,
                                useGrid: true,
                                 onAddToCart: (id) {
                                  if (id > 0) {
                                    GlobalData.optimisticUpdateCart(id, 1);
                                    widget.homePageBloc?.add(AddToCartEvent(id, 1, "Added"));
                                  } else {
                                    // 🟢 Decrement Logic
                                    int pid = -id;
                                    final cartMap = GlobalData.cartItemsController.value;
                                    final info = cartMap[pid.toString()];
                                    if (info != null) {
                                      int currentQty = info['qty'] ?? 0;
                                      String? cartItemId = info['cartItemId']?.toString();
                                      
                                      GlobalData.optimisticUpdateCart(pid, -1);
                                      
                                      if (cartItemId != null) {
                                        if (currentQty > 1) {
                                           context.read<CartScreenBloc>().add(UpdateCartEvent(
                                             [{'cartItemId': cartItemId, 'quantity': (currentQty - 1).toString()}]
                                           ));
                                        } else {
                                           context.read<CartScreenBloc>().add(RemoveCartItemEvent(
                                             cartItemId: int.parse(cartItemId)
                                           ));
                                        }
                                      }
                                    }
                                  }
                                },
                                onAddToWishlist: (String id, bool isInWishlist, dynamic product) async {
                                   if (widget.isLogin) {
                                      try { (product as dynamic).isInWishlist = !isInWishlist; } catch (_) {}
                                      try { if (product is Map) product['in_wishlist'] = !isInWishlist; } catch(_) {}
                                      
                                      if (isInWishlist) {
                                         GlobalData.wishlistProductIds.remove(id);
                                         widget.homePageBloc?.add(RemoveWishlistItemEvent(id, null)); 
                                      } else {
                                         GlobalData.wishlistProductIds.add(id);
                                         widget.homePageBloc?.add(FetchAddWishlistHomepageEvent(id, null));
                                      }
                                      GlobalData.wishlistUpdateStream.add(GlobalData.wishlistProductIds);
                                      setState(() {});
                                   } else {
                                      ShowMessage.warningNotification("Please login to add to wishlist", context);
                                   }
                                },
                              ),
                        ),
                      ),
                    ],

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),

                if (_showBackToTop)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 80, // Moved up to avoid covering cart bar if present
                    child: buildReachBottomView(context, _scrollController),
                  ),

                // 🟢 FLOATING VIEW CART BAR (Blinkit Style)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: StreamBuilder<int>(
                    stream: GlobalData.cartCountController.stream,
                    builder: (context, snapshot) {
                      int count = 0;
                      // Try to get from snapshot, fallback to storage
                      if (snapshot.hasData) {
                         count = snapshot.data ?? 0;
                      } else {
                         // Initial load might be empty stream, check pref
                         count = appStoragePref.getCartCount();
                      }

                      if (count <= 0) return const SizedBox.shrink();

                      return InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, cartScreen).then((_) {
                             setState(() {}); // Refresh home on return
                          });
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ColorFilter.mode(Colors.black.withOpacity(0.01), BlendMode.dstIn), // Optional slight tint
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xE627C16B), // 90% Opacity Blinkit Green
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5), // Trendy glass border
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "$count ${count == 1 ? 'Item' : 'Items'}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12
                                          ),
                                        ),
                                        const Text(
                                          "View Total",
                                          style: TextStyle(
                                            color: Colors.white70, 
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500
                                          ),
                                        )
                                      ],
                                    ),
                                    Row(
                                      children: const [
                                        Text(
                                          "View Cart",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_right, color: Colors.white),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPromoBanner(theme.ThemeCustomDataModel? data) {
    if (data == null || data.themeCustomization == null) return _bannerFallback();
    
    final sliders = data.themeCustomization!;
    final List<String> bannerUrls = [];

    for (final e in sliders) {
      // 🟢 Filter for Banner-like types
      if (e.type != "image_carousel" && e.type != "slider" && e.type != "image_slider") continue;

      // 🟢 Resilient Locale: Try preferred, then fallback to first available
      final trans = e.translations?.firstWhereOrNull((t) => t.localeCode == GlobalData.locale) 
                   ?? e.translations?.firstOrNull;
      
      final imgs = trans?.options?.images;
      
      if (imgs != null && imgs.isNotEmpty) {
        if (imgs is List) {
          for (var img in imgs) {
             final u = _imageFromAny(img);
             if (u != null && u.isNotEmpty) bannerUrls.add(u);
          }
        } else {
           final u = _imageFromAny(imgs);
           if (u != null && u.isNotEmpty) bannerUrls.add(u);
        }
      }
    }

    if (bannerUrls.isEmpty) return _bannerFallback();

    if (bannerUrls.length == 1) {
      return CachedNetworkImage(
        imageUrl: bannerUrls.first,
        height: 160, // 🟢 Increased height for better visibility
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => _bannerFallback(),
        errorWidget: (_, __, ___) => _bannerFallback(),
      );
    }

    return _BannerCarousel(imageUrls: bannerUrls);
  }

  Widget _bannerFallback() {
    return Container(
      height: 160, // 🟢 Match height
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, const Color(0xFFF1F8E9)],
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, color: Colors.green.withOpacity(0.3), size: 32),
          const SizedBox(height: 8),
          Text(
            "Exclusive deals for you",
            style: TextStyle(fontSize: 14, color: Colors.green.shade800, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  List<_Section> _buildSectionsFromTheme(theme.ThemeCustomDataModel? data) {
    // 🟢 DYNAMIC CATEGORY BUILDING
    // Instead of hardcoded titles, we iterate the Theme Customization data.
    // This allows the Backend (Bagisto Admin) to control the Titles and Order.

    final productLists = (GlobalData.allProducts ?? const <dynamic>[]).toList();
    final sections = <_Section>[];





    final themeItems = data?.themeCustomization ?? [];
    int productListIndex = 0;

    for (final element in themeItems) {
       // 🟢 1. CHECK IF IT IS A GRID (Subcategories)
       // The backend sends type="blinkit_category_grid".
       // We now fetch REAL Subcategories from GlobalData.categoriesDrawerData (Actual Backend Data)
       if (element.type == "blinkit_category_grid") {
          String title = element.name ?? "Categories";
          try {
             final trans = element.translations?.firstWhereOrNull((e) => e.localeCode == GlobalData.locale);
             if (trans?.options?.title != null) title = trans!.options!.title!;
          } catch (_) {}

          // 🟢 FEATURE: Fetch Real Subcategories
          // 1. Find the matching Root Category by Name
          List<dynamic> subCategories = [];
          final allRealCats = GlobalData.categoriesDrawerData?.data ?? [];
          
          dynamic foundRootCat;
          // Helper to find category by name (case insensitive)
          for (var cat in allRealCats) {
             if (_catLabel(cat).toLowerCase() == title.toLowerCase()) {
                foundRootCat = cat;
                break;
             }
          }

          if (foundRootCat != null) {
              // 2. Use its children (Real Backend Data)
              final children = _catChildren(foundRootCat);
              subCategories = children.map((child) => {
                  'title': _catLabel(child),
                  'image': _catBannerUrl(child).isNotEmpty ? _catBannerUrl(child) : _catBannerUrl(foundRootCat), // Fallback to parent if child has no image
                  'link': _catSlug(child), // Use slug for navigation
                  'icon': _categoryIconFor(_catLabel(child))
              }).toList();
          } else {
             // 3. Fallback to Mock Data (if Real Category not found)
             try {
                final trans = element.translations?.firstWhereOrNull((e) => e.localeCode == GlobalData.locale);
                if (trans?.options?.images is List) {
                   subCategories = trans!.options!.images!;
                }
             } catch (_) {}
          }

          if (subCategories.isNotEmpty) {
             sections.add(_Section(title, "blinkit_category_grid", subCategories));
          }
       }
       
       // 🟢 2. CHECK IF IT IS A PRODUCT CAROUSEL (Existing Logic)
       else if (element.type == "product_carousel") {
          // 1. Extract Title
          String title = "Products";
          try {
             final trans = element.translations?.firstWhereOrNull(
                (e) => e.localeCode == GlobalData.locale
             );
             if (trans?.options?.title != null && trans!.options!.title!.isNotEmpty) {
                title = trans.options!.title!;
             }
          } catch (_) {}

          // 2. Map to the tagged Product List (Robust Fix for Race Condition)
          // Search for the product list that was tagged with this section title
          var resp = productLists.firstWhereOrNull((p) => (p as dynamic).sectionId == title);
          
          // Fallback to index-based mapping if tag not found (backward compatibility)
          if (resp == null && productListIndex < productLists.length) {
             // Only use fallback if the candidate doesn't have a mismatched sectionIds
             // (i.e., don't use a list tagged for "Vegetables" to fill "Grocery")
             final candidate = productLists[productListIndex];
             if ((candidate as dynamic).sectionId == null) {
                resp = candidate;
                productListIndex++;
             }
          }

          if (resp != null) {
             final products = (resp.data as List?)?.cast<dynamic>() ?? const [];
             
             // Only add section if it has products
             if (products.isNotEmpty) {
                sections.add(_Section(title, "product_carousel", products));
             }
          }
       }
    }

    // 🟢 "All Products" Fallback/Aggregation
    // If we have extra product lists not accounted for, or just to aggregate everything unique
    // The original code did this, but for "Quick Commerce", usually we just want specific sections.
    // I will keep the Unique Aggregation but label it clearly if it wasn't already shown.
    
    // Actually, Blinkit ends with specific sections. Let's just stick to the Theme sections.
    // The previous "All Products" section might duplicate items.
    // I will exclude the "All Products" aggregation unless requested, to keep the UI clean.
    
    return sections;
  }
  void _handleSeeAll(String title) {
    String? slugToPass;
    
    // 🟢 Try to find matching Category by Title
    // This restores functionality for "Farm Fresh Vegetables" etc.
    try {
      final allCats = GlobalData.categoriesDrawerData?.data ?? [];
      for (var c in allCats) {
         if (_catLabel(c).toLowerCase().contains(title.toLowerCase()) || 
             title.toLowerCase().contains(_catLabel(c).toLowerCase())) {
             // Exact or fuzzy match
             slugToPass = _catSlug(c);
             break;
         }
      }
    } catch (_) {}

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => CategoryBloc(CategoriesRepo()), 
          child: SidebarCategoryScreen(initialSlug: slugToPass),
        ),
      ),
    );
  }
}

class _BannerCarousel extends StatefulWidget {
  final List<String> imageUrls;
  const _BannerCarousel({Key? key, required this.imageUrls}) : super(key: key);

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentPage < widget.imageUrls.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (var url in widget.imageUrls) {
      precacheImage(CachedNetworkImageProvider(url), context);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160, 
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (int page) {
              setState(() => _currentPage = page);
            },
            itemBuilder: (context, index) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return CachedNetworkImage(
                imageUrl: widget.imageUrls[index],
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => Container(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[200],
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: isDark ? Colors.white38 : Colors.grey[400],
                    size: 32,
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0), 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.imageUrls.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 6, 
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}