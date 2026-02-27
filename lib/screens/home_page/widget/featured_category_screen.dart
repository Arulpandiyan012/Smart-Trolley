import 'package:flutter/material.dart';
import 'package:bagisto_app_demo/screens/home_page/data_model/new_product_data.dart';
import 'package:bagisto_app_demo/widgets/blinkit_vertical_product_card.dart';
import 'package:bagisto_app_demo/utils/app_global_data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagisto_app_demo/screens/cart_screen/bloc/cart_screen_bloc.dart';
import 'package:bagisto_app_demo/screens/cart_screen/bloc/cart_screen_event.dart';

class FeaturedCategoryScreen extends StatefulWidget {
  final String title;
  final List<NewProducts> products;
  final bool isLogin;

  const FeaturedCategoryScreen({
    Key? key,
    required this.title,
    required this.products,
    required this.isLogin,
  }) : super(key: key);

  @override
  State<FeaturedCategoryScreen> createState() => _FeaturedCategoryScreenState();
}

class _FeaturedCategoryScreenState extends State<FeaturedCategoryScreen> {
  // Dummy static brands (since they don't exist per-product dynamically yet)
  final List<Map<String, String>> brands = [
    {"name": "Thums Up", "color": "0xFFE31837"},
    {"name": "Sprite", "color": "0xFF008B47"},
    {"name": "7UP", "color": "0xFF00A347"},
    {"name": "Coca-Cola", "color": "0xFFE31837"},
    {"name": "Pepsi", "color": "0xFF004B93"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Row(
              children: const [
                Text(
                  "Delivering to: ",
                  style: TextStyle(color: Color(0xFF008B47), fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Vellore New Bus Station, Thotta...",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey, size: 16),
              ],
            )
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.black87), onPressed: () {}),
          IconButton(icon: const Icon(Icons.file_upload_outlined, color: Colors.black87), onPressed: () {}),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Filter Chips
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip("Filters", Icons.tune),
                  _buildFilterChip("Sort", Icons.swap_vert),
                  _buildFilterChip("Price", Icons.arrow_drop_down),
                  _buildFilterChip("Brand", Icons.arrow_drop_down),
                  _buildFilterChip("Type", Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          
          // Products Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.49,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return BlinkitVerticalProductCard(
                    data: widget.products[index],
                    width: double.infinity,
                    onAddToCart: (id) {
                       if (id > 0) {
                         GlobalData.optimisticUpdateCart(id, 1);
                         setState((){});
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
                                context.read<CartScreenBloc>().add(UpdateCartEvent([{'cartItemId': cartItemId, 'quantity': (currentQty - 1).toString()}]));
                             } else {
                                context.read<CartScreenBloc>().add(RemoveCartItemEvent(cartItemId: int.parse(cartItemId)));
                             }
                           }
                           setState((){});
                         }
                       }
                    },
                  );
                },
                childCount: widget.products.length,
              ),
            ),
          ),

          // Shop by Brands
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFFFCFAEE), // Soft yellow background
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      "Shop by brands",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: brands.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                                  ]
                                ),
                                child: Center(
                                  child: Text(
                                    brands[index]["name"]!.substring(0, 1),
                                    style: TextStyle(
                                      fontSize: 32, 
                                      fontWeight: FontWeight.bold, 
                                      color: Color(int.parse(brands[index]["color"]!))
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(brands[index]["name"]!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        );
                      }
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      )
    );
  }

  Widget _buildFilterChip(String label, IconData? icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          if (icon != null && label == "Filters") ...[
            Icon(icon, size: 16, color: Colors.black54),
            const SizedBox(width: 4),
          ],
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
          if (icon != null && label != "Filters") ...[
            const SizedBox(width: 4),
            Icon(icon, size: 16, color: Colors.black54),
          ],
        ],
      ),
    );
  }
}
