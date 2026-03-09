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
import 'package:bagisto_app_demo/screens/home_page/widget/featured_category_screen.dart'; // 🟢 For See All Navigator

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
               // Use NewProductView configured for a grid layout
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 12.0),
                 child: NewProductView(
                   model: products,
                   title: "", // Title handled above
                   isLogin: widget.isLogin,
                   useGrid: true, // Blinkit-like horizontal or standard grid
                   onAddToCart: (id) {
                      if (id > 0) {
                        GlobalData.optimisticUpdateCart(id, 1);
                        widget.homePageBloc?.add(AddToCartEvent(id, 1, "Added"));
                      } else {
                        // Decrement Logic
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
               // See all products button (Blinkit style)
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                 child: InkWell(
                   onTap: () {
                     Navigator.push(
                       context,
                       MaterialPageRoute(
                         builder: (context) => FeaturedCategoryScreen(
                           title: title,
                           products: products,
                           isLogin: widget.isLogin,
                         ),
                       ),
                     );
                   },
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
