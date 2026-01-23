/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; 

import '../data_model/theme_customization.dart' as theme;
import '../utils/index.dart' hide Translations;
import 'package:bagisto_app_demo/screens/home_page/bloc/home_page_event.dart';

import 'new_product_view.dart';
import 'reach_top.dart'; 

import 'package:bagisto_app_demo/screens/drawer_sub_categories/utils/index.dart'
    show drawerSubCategoryScreen, CategoriesArguments, categoryScreen;

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
  final List<dynamic> products;
  _Section(this.title, this.products);
}

IconData _categoryIconFor(String name) {
  final n = name.toLowerCase();
  if (n.contains('grocery') || n.contains('kitchen')) return Icons.shopping_cart_outlined;
  if (n.contains('farm') || n.contains('vegetable')) return Icons.spa_outlined;
  if (n.contains('seasonal') || n.contains('exotic')) return Icons.apple_outlined;
  if (n.contains('dairy')) return Icons.icecream_outlined;
  if (n.contains('bakery')) return Icons.cookie_outlined;
  if (n.contains('snack')) return Icons.local_pizza_outlined;
  if (n.contains('beverage') || n.contains('drink')) return Icons.local_drink_outlined;
  if (n.contains('meat') || n.contains('non veg')) return Icons.set_meal_outlined;
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA5D6A7), Color(0xFFC8E6C9)], 
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
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
    super.key,
    required this.customHomeData,
    required this.isLoading,
    this.getCategoriesData,
    this.isLogin = false,
    this.homePageBloc,
    this.callPreCache = false,
  });

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

  void _handleSeeAll(String title) {
    final allCats = widget.getCategoriesData?.data ?? [];
    
    dynamic findCat(List<dynamic> list, String target) {
      for (final c in list) {
        if (_catLabel(c).toLowerCase() == target.toLowerCase()) return c;
        final kids = _catChildren(c);
        if (kids.isNotEmpty) {
          final found = findCat(kids, target);
          if (found != null) return found;
        }
      }
      return null;
    }

    final match = findCat(allCats, title);
    if (match != null) {
      _openCategory(match);
      return;
    }

    debugPrint("Category not found for title: $title");
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
           widget.homePageBloc?.add(FetchCMSDataEvent());
           setState(() {});
        }

        if (state is AddToCartState) {
          if (state.status == Status.success) {
            GlobalData.cartCountController.sink.add(state.graphQlBaseModel?.cart?.itemsQty ?? 0);
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
        return ColoredBox(
          color: const Color(0xFFC8E6C9), 
          child: SafeArea(
            top: false,
            child: Stack(
              children: [
                CustomScrollView(
                  controller: _scrollController, 
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _CategoryHeaderDelegate(
                        categories: cats.isEmpty ? const [{'name': 'Loading…'}] : cats,
                        selectedIndex: _selectedCatIndex,
                        onTap: (i, cat) {
                          if (cats.isEmpty) return;
                          setState(() => _selectedCatIndex = i);
                          _openCategory(cat);
                        },
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 6)),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildPromoBanner(widget.customHomeData),
                        ),
                      ),
                    ),

                    for (final s in sections) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: NewProductView(
                            model: s.products,
                            title: s.title,
                            isLogin: widget.isLogin,
                            isRecentProduct: false,
                            callPreCache: widget.callPreCache,
                            useGrid: true,
                            onAddToCart: (id) =>
                                widget.homePageBloc?.add(AddToCartEvent(id, 1, "Added")),
                            
                            // 🟢 THE FIX IS HERE:
                            onAddToWishlist: (String id, bool isInWishlist, dynamic product) {
                               if (widget.isLogin) {
                                  // 1. Manually update the Model instantly
                                  // This uses "dynamic" access to bypass strict type checking issues.
                                  try {
                                    (product as dynamic).isInWishlist = !isInWishlist;
                                  } catch (_) {
                                    // If product is a Map, try updating map key
                                    try { if (product is Map) product['in_wishlist'] = !isInWishlist; } catch(_) {}
                                  }

                                  // 2. Force Screen Update instantly
                                  setState(() {});

                                  // 3. Send event to server
                                  // We pass NULL for 'datum' so the Bloc doesn't try to toggle it back again!
                                  if (isInWishlist) {
                                     widget.homePageBloc?.add(RemoveWishlistItemEvent(id, null)); 
                                  } else {
                                     widget.homePageBloc?.add(FetchAddWishlistHomepageEvent(id, null));
                                  }
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

                if (_showBackToTop)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 10,
                    child: buildReachBottomView(context, _scrollController),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPromoBanner(theme.ThemeCustomDataModel? data) {
    final sliders = data?.themeCustomization ?? const [];
    final List<String> bannerUrls = [];

    for (final e in sliders) {
      final trans = e.translations?.firstWhereOrNull((t) => t.localeCode == GlobalData.locale);
      final imgs = trans?.options?.images;
      
      if (imgs != null && imgs.isNotEmpty) {
        for (var img in imgs) {
           final u = _imageFromAny(img);
           if (u != null && u.isNotEmpty) bannerUrls.add(u);
        }
            }
    }

    if (bannerUrls.isEmpty) return _bannerFallback();

    if (bannerUrls.length == 1) {
      return Image.network(
        bannerUrls.first,
        height: 80, 
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _bannerFallback(),
      );
    }

    return _BannerCarousel(imageUrls: bannerUrls);
  }

  Widget _bannerFallback() {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
        ),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.all(16),
      child: const Text(
        "Fresh deals near you",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }

  List<_Section> _buildSectionsFromTheme(theme.ThemeCustomDataModel? data) {
    const expectedTitles = <String>[
      'New Products',
      'Featured Products',
      'Grocery & Kitchen',
      'Farm Fresh Vegetables',
      'Seasonal & Exotic Fruits',
    ];

    final productLists = (GlobalData.allProducts ?? const <dynamic>[]).toList();
    final sections = <_Section>[];

    for (var i = 0; i < expectedTitles.length; i++) {
      if (i >= productLists.length) break;
      final resp = productLists[i];
      final products = (resp?.data as List?)?.cast<dynamic>() ?? const [];
      if (products.isNotEmpty) {
        sections.add(_Section(expectedTitles[i], products));
      }
    }

    final merged = <dynamic>[];
    for (final s in sections) {
      merged.addAll(s.products);
    }
    
    for (var i = expectedTitles.length; i < productLists.length; i++) {
       final resp = productLists[i];
       final products = (resp?.data as List?)?.cast<dynamic>() ?? const [];
       merged.addAll(products);
    }

    final seen = <String>{};
    final unique = <dynamic>[];
    for (final p in merged) {
      final id = (p as dynamic).id?.toString() ?? (p as dynamic)['id']?.toString() ?? '';
      if (id.isNotEmpty && seen.add(id)) unique.add(p);
    }

    if (unique.isNotEmpty) {
      sections.add(_Section('All Products', unique));
    }

    return sections;
  }
}

class _BannerCarousel extends StatefulWidget {
  final List<String> imageUrls;
  const _BannerCarousel({super.key, required this.imageUrls});

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
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPage < widget.imageUrls.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
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
      height: 80, 
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
              return Image.network(
                widget.imageUrls[index],
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (c, o, s) => Container(color: Colors.grey[200]),
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