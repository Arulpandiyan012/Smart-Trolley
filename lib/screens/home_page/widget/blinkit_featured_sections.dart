import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:bagisto_app_demo/utils/server_configuration.dart';
import 'package:bagisto_app_demo/screens/home_page/data_model/new_product_data.dart';
import 'package:bagisto_app_demo/screens/home_page/widget/new_product_view.dart';
import 'package:bagisto_app_demo/utils/app_global_data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagisto_app_demo/screens/home_page/bloc/home_page_event.dart';
import 'package:bagisto_app_demo/screens/home_page/bloc/home_page_bloc.dart';
import 'package:bagisto_app_demo/screens/cart_screen/bloc/cart_screen_bloc.dart';
import 'package:bagisto_app_demo/screens/cart_screen/bloc/cart_screen_event.dart';
import 'package:bagisto_app_demo/screens/categories_screen/sidebar_category_screen.dart';
import 'package:bagisto_app_demo/screens/categories_screen/bloc/categories_bloc.dart';
import 'package:bagisto_app_demo/screens/categories_screen/bloc/categories_repository.dart';
import 'package:bagisto_app_demo/screens/home_page/widget/featured_section_sidebar_screen.dart';
import 'package:bagisto_app_demo/screens/home_page/widget/featured_category_screen.dart';
import 'package:bagisto_app_demo/screens/home_page/bloc/home_page_repository.dart';

class BlinkitFeaturedSections extends StatefulWidget {
  final bool isLogin;
  final HomePageBloc? homePageBloc;

  const BlinkitFeaturedSections({
    Key? key,
    required this.isLogin,
    this.homePageBloc,
  }) : super(key: key);

  @override
  BlinkitFeaturedSectionsState createState() => BlinkitFeaturedSectionsState();
}

class BlinkitFeaturedSectionsState extends State<BlinkitFeaturedSections> {
  List<Map<String, dynamic>> _sections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFeaturedSections();
  }

  Future<void> fetchFeaturedSections() async {
    try {
      final url = Uri.parse("$baseDomain/mobikul-vendor-api.php");
      final response = await http.post(
        url,
        body: {"action": "get_home_featured"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> rawSections = data['data'] ?? [];
          final List<Map<String, dynamic>> parsedSections = [];

          for (var s in rawSections) {
            List<NewProducts> products = [];
            for (var p in s['products'] ?? []) {
              try {
                products.add(NewProducts.fromJson(p));
              } catch (e) {
                debugPrint("Parse err: $e");
              }
            }
            if (products.isNotEmpty) {
              parsedSections.add({
                'title': s['title'],
                'products': products,
              });
            }
          }

          if (mounted) {
            setState(() {
              _sections = parsedSections;
              _isLoading = false;
            });
          }
        } else {
            if (mounted) setState(() => _isLoading = false);
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🟢 Resolve a category slug from a section title
  // First: try static mapping for known titles. Then: fuzzy-match from GlobalData.
  String? _resolveSlugForTitle(String title) {
    final t = title.toLowerCase().trim();

    // Static slug map for well-known home section titles
    const Map<String, String> _staticSlugMap = {
      // ── Sweet Tooth / Chocolates ──────────────────────────────────────────
      // Backend: "Sweets & Chocolates" → slug: sweets-chocolates (under Snacks & Drinks)
      'flash sale 🔥': 'flash-sales',
      'flash sale': 'flash-sales',
      'sweet tooth': 'sweets-chocolates',
      'sweets': 'sweets-chocolates',
      'sweets & chocolates': 'sweets-chocolates',
      'chocolates': 'sweets-chocolates',
      'candies': 'sweets-chocolates',

      // ── Dry Fruit, Masala & Oil ───────────────────────────────────────────
      // Backend: "Oil, Ghee & Masala" → slug: oil-ghee-masala (under Grocery & Kitchen)
      //          "Dry Fruits & Cereals" → slug: dry-fruits-cereals (under Grocery & Kitchen)
      'dry fruit, masala & oil': 'oil-ghee-masala',
      'dry fruit, masala and oil': 'oil-ghee-masala',
      'dry fruits, masala & oil': 'oil-ghee-masala',
      'masala and oil': 'oil-ghee-masala',
      'masala & oil': 'oil-ghee-masala',
      'oil, ghee & masala': 'oil-ghee-masala',
      'oil ghee masala': 'oil-ghee-masala',
      'dry fruits': 'dry-fruits-cereals',
      'dry fruits & cereals': 'dry-fruits-cereals',

      // ── Snacks & Drinks ───────────────────────────────────────────────────
      'snacks': 'snacks-drinks',
      'snacks & drinks': 'snacks-drinks',
      'chips & namkeen': 'chips-namkeen',
      'instant foods': 'instant-foods',
      'sauces & spreads': 'sauces-spreads',

      // ── Ice Creams ────────────────────────────────────────────────────────
      'ice creams': 'ice-creams-more-',
      'ice cream': 'ice-creams-more-',
      'ice creams & more': 'ice-creams-more-',

      // ── Grocery ───────────────────────────────────────────────────────────
      'grocery': 'grocery-kitchen',
      'grocery & kitchen': 'grocery-kitchen',
      'atta, rice & dal': 'atta-rice-dal',
      'bakery & biscuits': 'bakery-biscuits-',

      // ── Dairy ─────────────────────────────────────────────────────────────
      'dairy': 'dairy-bread-eggs',
      'dairy, bread & eggs': 'dairy-bread-eggs',
      'dairy & breakfast': 'dairy-bread-eggs',

      // ── Beverages ─────────────────────────────────────────────────────────
      'drinks & juices': 'drinks-juices',
      'beverages': 'drinks-juices',
      'tea, coffee & milk drinks': 'tea-coffee-milk-drinks',

      // ── Beauty ────────────────────────────────────────────────────────────
      'beauty & personal care': 'beauty-personal-care',
      'beauty': 'beauty-personal-care',
      'baby care': 'baby-care',

      // ── Household ─────────────────────────────────────────────────────────
      'household essentials': 'household-essentials',
    };

    if (_staticSlugMap.containsKey(t)) return _staticSlugMap[t];

    // Fuzzy search: look in GlobalData categories tree
    try {
      final allCats = GlobalData.categoriesDrawerData?.data ?? [];
      String? found;

      void searchRecursive(List<dynamic> cats) {
        for (var cat in cats) {
          final catName = (cat.name?.toString() ?? cat['name']?.toString() ?? '').toLowerCase();
          final catSlug = cat.slug?.toString() ?? cat['slug']?.toString() ?? '';
          if (catName.isNotEmpty && (catName.contains(t) || t.contains(catName))) {
            found = catSlug;
            return;
          }
          final children = (cat.children as List?) ?? (cat['children'] as List?) ?? [];
          if (children.isNotEmpty) searchRecursive(children);
          if (found != null) return;
        }
      }

      searchRecursive(allCats);
      if (found != null && found!.isNotEmpty) return found;
    } catch (_) {}

    return null;
  }

  void _navigateToCategory(BuildContext context, String title, List<NewProducts> products) {
    // 🟢 Priority 1: Custom FeaturedSectionSidebarScreen (hand-picked categories in sidebar)
    if (FeaturedSectionConfig.hasConfig(title)) {
      final entries = FeaturedSectionConfig.forTitle(title)!;
      debugPrint("🟢 BlinkitFeaturedSections: Opening custom FeaturedSectionSidebarScreen for '$title'");
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => BlocProvider(
            create: (_) => CategoryBloc(CategoriesRepo()),
            child: FeaturedSectionSidebarScreen(
              title: title,
              sidebarEntries: entries,
            ),
          ),
        ),
      );
      return;
    }

    // 🟡 Priority 2: Generic FeaturedCategoryScreen (original grid layout)
    debugPrint("🟢 BlinkitFeaturedSections: See All '$title' → FeaturedCategoryScreen");
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => BlocProvider(
          create: (_) => HomePageBloc(HomePageRepositoryImp()),
          child: FeaturedCategoryScreen(
            title: title,
            products: products,
            isLogin: widget.isLogin,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    if (_sections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _sections.map((section) {
        final title = section['title'] as String;
        final products = section['products'] as List<NewProducts>;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Padding(
                 padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Expanded(
                       child: Text(
                         title,
                         style: TextStyle(
                           fontSize: 18,
                           fontWeight: FontWeight.w800,
                           fontFamily: 'Roboto',
                           color: Theme.of(context).textTheme.titleLarge?.color,
                           letterSpacing: -0.4,
                         ),
                       ),
                     ),
                   ],
                 ),
               ),
               // Product Cards Grid
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 12.0),
                 child: NewProductView(
                   model: products,
                   title: "",
                   isLogin: widget.isLogin,
                   useGrid: true,
                   onAddToCart: (id) {
                      if (id > 0) {
                        GlobalData.optimisticUpdateCart(id, 1);
                        widget.homePageBloc?.add(AddToCartEvent(id, 1, "Added"));
                      } else {
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
                       }
                   },
                 ),
               ),
               // 🟢 "See all products" button → Opens SidebarCategoryScreen
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                 child: InkWell(
                   borderRadius: BorderRadius.circular(8),
                   onTap: () => _navigateToCategory(context, title, products),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "See all products",
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark 
                                ? const Color(0xFF66BB6A) 
                                : const Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_right_rounded, 
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? const Color(0xFF66BB6A) 
                                : const Color(0xFF2E7D32)
                          ),
                        ],
                      ),
                    ),
                 ),
               ),
             ],
          ),
        );
      }).toList(),
    );
  }
}
