import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bagisto_app_demo/utils/server_configuration.dart';
import 'package:bagisto_app_demo/screens/home_page/data_model/get_categories_drawer_data_model.dart';
import 'package:bagisto_app_demo/screens/home_page/bloc/home_page_repository.dart';
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

// 🟢 FIX: All necessary Cart imports
import 'package:bagisto_app_demo/screens/cart_screen/bloc/cart_screen_bloc.dart';
import 'package:bagisto_app_demo/screens/cart_screen/bloc/cart_screen_event.dart';
import 'package:bagisto_app_demo/screens/cart_screen/bloc/cart_screen_state.dart';
import 'package:bagisto_app_demo/screens/cart_screen/utils/cart_index.dart'; // For CartStatus
import 'package:bagisto_app_demo/screens/categories_screen/sub_category_sidebar_screen.dart';

class SidebarCategoryScreen extends StatefulWidget {
  final String? initialSlug;
  const SidebarCategoryScreen({Key? key, this.initialSlug}) : super(key: key);

  @override
  State<SidebarCategoryScreen> createState() => _SidebarCategoryScreenState();
}

class _SidebarCategoryScreenState extends State<SidebarCategoryScreen> {
  // Data
  List<dynamic> _categories = [];
  List<dynamic> _subCategories = []; 
  int _selectedSidebarIndex = 0;
// ... (code omitted) ...

  int _selectedSubCatIndex = -1; 
  
  // 🟢 NEW: Level 3 Support

  
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
    // Helper to process list
    void processList(List<dynamic> list) {
        if (mounted) {
          setState(() {
            _categories = list;
            int initialIndex = 0;
            if (widget.initialSlug != null) {
               try {
                 int idx = _categories.indexWhere((c) {
                   // Try to match slug
                   String? s;
                   try { s = _getSlug(c); } catch(_) {}
                   if (s == widget.initialSlug) return true;
                   
                   // Fallback to ID match if slug fails (just in case title was passed as ID)
                   // But we should stick to slug.
                   return false;
                 });
                 if (idx != -1) initialIndex = idx;
               } catch (_) {}
            }
            _onSidebarItemSelected(initialIndex); 
          });
        }
    }


    // 🟢 CUSTOM API FETCH (Bypasses GraphQL limit)
    // We use mobikul-vendor-api.php which returns the FULL tree (Levels 1, 2, 3)

    setState(() => _isLoading = true);

    _fetchCategoriesFromCustomApi().then((response) {
        if (mounted) {
            setState(() => _isLoading = false);
            if (response != null && response.data != null) {
                // Update Global & Local
                GlobalData.categoriesDrawerData = response;
                appStoragePref.setDrawerCategories(response);
                processList(response.data!);
            } else {
                // Fallback to cache if API fails
                _loadFromCache(processList);
            }
        }
    }); // No catchError needed as the function handles exceptions
  }

  // 🟢 NEW: Fetch from Custom PHP Endpoint
  Future<GetDrawerCategoriesData?> _fetchCategoriesFromCustomApi() async {
      try {
          var url = Uri.parse("$baseDomain/mobikul-vendor-api.php");
          debugPrint("🔵 CUSTOM API URL: $url");
          
          var response = await http.post(url, body: {"action": "get_categories"});
          debugPrint("🔵 CUSTOM API STATUS: ${response.statusCode}");
          debugPrint("🔵 CUSTOM API BODY (First 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}");

          if (response.statusCode == 200) {
              var json = jsonDecode(response.body);
              if (json['success'] == true) {
                   List<dynamic> rawList = json['data'];
                   debugPrint("🔵 CUSTOM API PARSED: Found ${rawList.length} root categories.");
                   
                   List<HomeCategories> homeCats = rawList.map((c) => _mapToHomeCategory(c)).toList();
                   
                   // Check 'Grocery' children count for debugging
                   var grocery = homeCats.firstWhere((c) => c.name?.contains("Grocery") ?? false, orElse: () => HomeCategories());
                   debugPrint("🔵 CUSTOM API DEBUG: Grocery children count: ${grocery.children?.length ?? 0}");

                   var model = GetDrawerCategoriesData();
                   model.success = "true";
                   model.responseStatus = true;
                   model.data = homeCats;
                   return model;
              } else {
                   debugPrint("🔴 CUSTOM API SUCCESS FALSE: ${json['message']}");
              }
          } else {
               debugPrint("🔴 CUSTOM API HTTP ERROR: ${response.statusCode}");
          }
      } catch (e, stack) {
          debugPrint("🔴 CUSTOM API EXCEPTION: $e");
          debugPrint("🔴 STACK: $stack");
      }
      return null;
  }

  // Helper to Map JSON -> HomeCategories (Recursive)
  HomeCategories _mapToHomeCategory(Map<String, dynamic> json) {
      // Map Children (Recursive)
      List<Children> childrenList = [];
      if (json['children'] != null) {
          json['children'].forEach((v) {
              childrenList.add(_mapToChildren(v));
          });
      }

      var cat = HomeCategories();
      cat.id = json['id'].toString();
      cat.name = json['name'];
      cat.slug = json['slug'];
      cat.bannerUrl = json['bannerUrl'];
      cat.logoUrl = json['logoUrl'];
      cat.children = childrenList;
      return cat;
  }

  // Helper to Map JSON -> Children (Recursive for Level 3)
  Children _mapToChildren(Map<String, dynamic> json) {
       List<Children> subChildren = [];
       if (json['children'] != null) {
           json['children'].forEach((v) {
               subChildren.add(_mapToChildren(v));
           });
       }

       var child = Children();
       child.id = json['id'].toString();
       child.name = json['name'];
       child.slug = json['slug'];
       child.bannerUrl = json['bannerUrl'];
       child.logoUrl = json['logoUrl'];
       child.children = subChildren; // 🟢 CRITICAL: Level 3
       return child;
  }

  void _loadFromCache(Function(List<dynamic>) processList) {
    if (GlobalData.categoriesDrawerData != null) {
      final list = GlobalData.categoriesDrawerData!.data ?? [];
      if (list.isNotEmpty) {
        processList(list);
        return;
      }
    }

    var offlineData = appStoragePref.getDrawerCategories();
    if (offlineData != null) {
      GlobalData.categoriesDrawerData = offlineData;
      final list = offlineData.data ?? [];
      if (list.isNotEmpty) {
        processList(list);
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
      
      _selectedSubCatIndex = -1;  // Select "All" by default
 
      
      _fetchProducts(_getId(cat), _getSlug(cat));
    });
  }

  void _onSubCategorySelected(int index) {
    setState(() {
      _selectedSubCatIndex = index;

      String idToFetch;
      String slugToFetch;
      
      if (index == -1) {
        // "All" selected in Level 2 -> Show Level 1 products
        final cat = _categories[_selectedSidebarIndex];
        idToFetch = _getId(cat);
        slugToFetch = _getSlug(cat);

      } else {
        // Specific Level 2 selected
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
    if (n.contains('grocery') || n.contains('staple')) return Icons.local_grocery_store_outlined;
    if (n.contains('oil') || n.contains('ghee')) return Icons.opacity_outlined;
    if (n.contains('spice') || n.contains('masala')) return Icons.whatshot_outlined;
    if (n.contains('snack') || n.contains('chip') || n.contains('biscuit') || n.contains('namkeen')) return Icons.fastfood_outlined;
    if (n.contains('beverage') || n.contains('drink') || n.contains('juice') || n.contains('tea') || n.contains('coffee')) return Icons.local_cafe_outlined;
    if (n.contains('sweet') || n.contains('chocolate') || n.contains('ice cream')) return Icons.icecream_outlined;
    if (n.contains('personal') || n.contains('beauty') || n.contains('skin') || n.contains('hair') || n.contains('face')) return Icons.face_retouching_natural_outlined;
    if (n.contains('home') || n.contains('clean') || n.contains('detergent') || n.contains('wash')) return Icons.cleaning_services_outlined;
    if (n.contains('baby') || n.contains('diaper')) return Icons.child_care_outlined;
    if (n.contains('pet') || n.contains('dog') || n.contains('cat')) return Icons.pets_outlined;
    if (n.contains('kitchen')) return Icons.flatware_outlined;
    if (n.contains('pharmacy') || n.contains('medicin') || n.contains('health')) return Icons.medication_outlined;
    if (n.contains('book') || n.contains('stationery') || n.contains('office')) return Icons.menu_book_outlined;
    if (n.contains('electr') || n.contains('mobile') || n.contains('phone')) return Icons.devices_outlined;
    if (n.contains('fashion') || n.contains('cloth')) return Icons.checkroom_outlined;
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    // Retry logic
    if (_categories.isEmpty && GlobalData.categoriesDrawerData != null) {
      _loadCategories();
    }

    // 1. LOADING / ERROR STATE
    if (_categories.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text("Categories", style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontWeight: FontWeight.bold)),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0.5,
        ),
        body: _buildEmptyState(),
      );
    }

    // 🟢 CONDITIONAL: Browse Mode vs Direct Mode
    // If NO specific slug was passed, show the GRID of categories (Browse Mode)
    if (widget.initialSlug == null || widget.initialSlug!.isEmpty) {
       return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text("Categories", style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontWeight: FontWeight.bold)),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            elevation: 0.5,
          ),
          body: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, 
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                return _buildRootCategoryItem(index);
              },
            ),
       );
    }

    // 2. DIRECT MODE -> RENDER SUB-CATEGORY SCREEN
    // User requested a specific category (e.g. from Home Page shortcut)
    if (_selectedSidebarIndex >= _categories.length) _selectedSidebarIndex = 0;
    
    final cat = _categories[_selectedSidebarIndex];
    final cartBloc = context.read<CartScreenBloc>();

    return MultiBlocProvider(
       providers: [
         BlocProvider.value(value: _categoryBloc!),
         BlocProvider.value(value: cartBloc),
       ],
       child: SubCategorySidebarScreen(
          title: _getName(cat),
          parentId: _getId(cat),
          subCategories: ((cat as dynamic).children as List?) ?? [],
       ),
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27C16B)),
            child: const Text("Retry", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 🟢 NEW: Helper to build Root Item (Click -> Navigate to L2 Sidebar)
  Widget _buildRootCategoryItem(int index) {
    final cat = _categories[index];
    final String name = _getName(cat);
    final String imgUrl = _getImage(cat);

    return GestureDetector(
      onTap: () {
         // 🟢 NAVIGATION: Go to "SubCategorySidebarScreen"
         // Must pass providers because Navigator.push creates a new context scope
         final cartBloc = context.read<CartScreenBloc>();

         Navigator.push(
           context, 
           MaterialPageRoute(
             builder: (context) => MultiBlocProvider(
               providers: [
                 BlocProvider.value(value: _categoryBloc!),
                 BlocProvider.value(value: cartBloc),
               ],
               child: SubCategorySidebarScreen(
                 title: name,
                 parentId: _getId(cat),
                 subCategories: ((cat as dynamic).children as List?) ?? [],
               ),
             )
           )
         );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 50, width: 50,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                image: imgUrl.isNotEmpty 
                  ? DecorationImage(
                      image: NetworkImage(imgUrl), 
                      fit: BoxFit.cover
                    )
                  : null,
              ),
              child: imgUrl.isEmpty 
                  ? Icon(_categoryIconFor(name), size: 28, color: Theme.of(context).primaryColor) 
                  : null,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11, 
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}