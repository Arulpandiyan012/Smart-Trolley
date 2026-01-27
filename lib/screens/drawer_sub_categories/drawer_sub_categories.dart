/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 * @author Webkul <support@webkul.com>
 * @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 * @license https://store.webkul.com/license.html
 * @link https://store.webkul.com/license.html
 */

import 'package:bagisto_app_demo/screens/cart_screen/utils/cart_index.dart';
import 'package:bagisto_app_demo/screens/drawer/utils/index.dart';
import 'package:bagisto_app_demo/screens/drawer_sub_categories/utils/index.dart';
// 🟢 Import for Common App Bar & Widgets
import 'package:bagisto_app_demo/widgets/common_app_bar.dart';
import 'package:bagisto_app_demo/widgets/image_view.dart';
import 'package:bagisto_app_demo/widgets/show_message.dart';
import 'package:bagisto_app_demo/widgets/loader.dart'; // Ensure Loader is available
// 🟢 Import Filter Utils (Hide conflicting state)
import 'package:bagisto_app_demo/screens/filter_screen/utils/index.dart' hide FilterFetchState;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart'; // For firstWhereOrNull
import '../../utils/app_global_data.dart';
import '../../utils/shared_preference_helper.dart';
import '../../utils/string_constants.dart';
import '../../utils/app_constants.dart';
import '../../utils/route_constants.dart';
import '../home_page/data_model/new_product_data.dart';

class DrawerSubCategoryView extends StatefulWidget {
  final String? title;
  final String? id;
  final String? image;
  final String? categorySlug;
  final String? metaDescription;
  final String? parentId;

  const DrawerSubCategoryView(
      {Key? key,
      this.title,
      this.id,
      this.image,
      this.categorySlug,
      this.metaDescription,
      this.parentId})
      : super(key: key);

  @override
  State<DrawerSubCategoryView> createState() => _DrawerSubCategoryViewState();
}

class _DrawerSubCategoryViewState extends State<DrawerSubCategoryView> {
  GetDrawerCategoriesData? categoriesData;
  NewProductsModel? categoriesProductData;
  DrawerSubCategoriesBloc? bloc;
  bool isLoading = false;
  
  // Sort/Filter logic
  int page = 1;
  List<Map<String, dynamic>> filters = [];
  ScrollController? _scrollController;

  @override
  void initState() {
    _scrollController = ScrollController();
    _scrollController?.addListener(_pagination);
    
    bloc = context.read<DrawerSubCategoriesBloc>();
    
    // Initial Fetch
    bloc?.add(FetchDrawerSubCategoryEvent([
      {"key": '"status"', "value": '"1"'},
      {"key": '"locale"', "value": '"${GlobalData.locale}"'},
      {"key": '"parent_id"', "value": '"${widget.parentId}"'}
    ]));
    
    super.initState();
  }
  
  void _pagination() {
    if ((_scrollController?.position.pixels ?? 0) >= (_scrollController?.position.maxScrollExtent ?? 0)) {
       // Add pagination logic here if API supports it
    }
  }

  fetchProducts() {
    bloc?.add(FetchCategoryProductsEvent([
      {"key": '"category_id"', "value": '"${widget.id}"'}
    ], page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(widget.title ?? ""),
      body: _subCategoriesList(),
    );
  }

  _subCategoriesList() {
    return BlocConsumer<DrawerSubCategoriesBloc, DrawerSubCategoriesState>(
      listener: (context, state) {
        if (state is AddToCartState) {
          isLoading = false;
          if (state.status == Status.fail) {
            ShowMessage.errorNotification(
                state.graphQlBaseModel?.graphqlErrors ?? "", context);
          } else if (state.status == Status.success) {
            ShowMessage.successNotification(
                state.graphQlBaseModel?.message ?? "", context);
            appStoragePref
                .setCartCount(state.graphQlBaseModel?.cart?.itemsQty ?? 0);
            GlobalData.cartCountController.sink
                .add(state.graphQlBaseModel?.cart?.itemsQty ?? 0);
          }
        } else if (state is AddWishlistState) {
          fetchProducts();
          isLoading = false;
          if (state.status == Status.fail) {
            ShowMessage.errorNotification(state.message ?? "", context);
          } else if (state.status == Status.success) {
            ShowMessage.successNotification(
                state.response?.message ?? "", context);
          }
        } else if (state is RemoveWishlistState) {
          fetchProducts();
          isLoading = false;
          if (state.status == Status.fail) {
            ShowMessage.errorNotification(state.message ?? "", context);
          } else if (state.status == Status.success) {
            ShowMessage.successNotification(
                state.response?.message ?? "", context);
          }
        }
        if (state is AddToCompareState) {
          isLoading = false;
          if (state.status == Status.fail) {
            ShowMessage.errorNotification(state.successMsg ?? "", context);
          } else if (state.status == Status.success) {
            ShowMessage.successNotification(state.successMsg ?? "", context);
          }
        }
      },
      builder: (context, state) {
        if (state is DrawerSubCategoryInitialState) {
          isLoading = true;
        } else if (state is FetchDrawerSubCategoryState) {
          fetchProducts();
          if (state.status == Status.success) {
            categoriesData = state.getCategoriesData;
          }
        }
        if (state is FetchCategoryProductsState) {
          isLoading = false;
          if (state.status == Status.success) {
            if (page == 1) {
              categoriesProductData = state.categoriesData;
            } else {
              categoriesProductData?.data?.addAll(state.categoriesData?.data ?? []);
            }
          }
        }

        var allParents = categoriesData?.data
            ?.firstWhereOrNull((element) => element.id == widget.id);
            
        final products = categoriesProductData?.data ?? [];
        final hasProducts = products.isNotEmpty;

        // 🟢 Modern Custom Scroll View
        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            // 1. Top Banner Image
            if (widget.image != null && widget.image!.isNotEmpty)
            SliverToBoxAdapter(
              child: ImageView(
                url: widget.image ?? "",
                height: MediaQuery.of(context).size.height / 4,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.cover,
              ),
            ),
            
            // 2. Sub Category Horizontal List
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if((categoriesData?.data ?? []).isNotEmpty || (allParents?.children ?? []).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                      child: Text(StringConstants.subCategories.localized(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                    ),
                  
                  if (widget.parentId != "1")
                    _buildHorizontalSubCats(categoriesData?.data),
                    
                  _buildHorizontalSubCats(allParents?.children),
                ],
              ),
            ),

            // 3. Sort & Filter Bar (Only if products exist)
            if (hasProducts)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                    top: BorderSide(color: Colors.grey[100]!),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                           // Add Sort Logic here if needed
                           // _openSortSheet(); 
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.swap_vert, size: 18, color: Colors.black54),
                            const SizedBox(width: 6),
                            const Text("Sort", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    Container(width: 1, height: 24, color: Colors.grey[300]),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                           // Add Filter Logic here if needed
                           // _openFilterScreen();
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.tune, size: 18, color: Colors.black54),
                            const SizedBox(width: 6),
                            const Text("Filters", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Blinkit Style Product List
            if (hasProducts)
              SliverPadding(
                padding: const EdgeInsets.only(top: 10, bottom: 30),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildDrawerBlinkitCard(products[index]);
                    },
                    childCount: products.length,
                  ),
                ),
              )
            else if (!isLoading)
              const SliverFillRemaining(
                child: Center(child: Text("No products found")),
              ),
              
            // 5. Loading Indicator
            if (isLoading)
              const SliverToBoxAdapter(child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Loader(),
              )),
          ],
        );
      },
    );
  }

  /// Helper to build Horizontal Sub Categories
  Widget _buildHorizontalSubCats(List<dynamic>? list) {
    if (list == null || list.isEmpty) return const SizedBox.shrink();
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list.map((parent) => InkWell(
          onTap: () {
            if ((parent.children ?? []).isNotEmpty) {
              Navigator.pushNamed(
                  context, drawerSubCategoryScreen,
                  arguments: CategoriesArguments(
                      categorySlug: parent.slug,
                      title: parent.name,
                      id: parent.id.toString(),
                      image: parent.bannerUrl,
                      parentId: parent.id.toString()));
            } else {
              Navigator.pushNamed(
                context,
                categoryScreen,
                arguments: CategoriesArguments(
                    metaDescription: parent.description,
                    categorySlug: parent.slug,
                    title: parent.name,
                    id: parent.id.toString(),
                    image: parent.bannerUrl),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[100],
                  foregroundImage: NetworkImage(parent.logoUrl ?? ""),
                  backgroundImage: const AssetImage(AssetConstants.placeHolder),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 70,
                  child: Text(parent.name ?? "",
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }

  /// 🟢 Custom Blinkit Card for Drawer Screen
  /// (Re-implemented locally to ensure it works with DrawerSubCategoriesBloc)
  Widget _buildDrawerBlinkitCard(NewProducts data) {
    // Price Logic
    String price = data.priceHtml?.formattedFinalPrice ?? "";
    if (price.isEmpty) price = "₹${data.price ?? '0'}";
    
    String imageUrl = (data.images?.isNotEmpty ?? false) ? data.images![0].url ?? "" : data.url ?? "";
    bool isSaleable = data.isSaleable ?? false;

    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, productScreen,
            arguments: PassProductData(
                title: data.name ?? "",
                urlKey: data.urlKey,
                productId: int.parse(data.id ?? "0")));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
             BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // IMAGE
            Container(
              width: 88,
              padding: const EdgeInsets.all(6),
              child: Stack(
                children: [
                   SizedBox(
                      height: 70, width: 70,
                      child: ImageView(url: imageUrl, fit: BoxFit.contain),
                   ),
                   if (data.isInSale ?? false)
                     Positioned(
                       child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                         decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(3)),
                         child: const Text("SALE", style: TextStyle(color: Colors.white, fontSize: 8)),
                       ),
                     )
                ],
              ),
            ),
            
            // CONTENT
            Expanded(
               child: Padding(
                 padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     // Timer
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                       decoration: BoxDecoration(color: const Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(3)),
                       child: Row(
                         mainAxisSize: MainAxisSize.min,
                         children: const [
                           Icon(Icons.timer_outlined, size: 9, color: Colors.black54),
                           SizedBox(width: 3),
                           Text("11 MINS", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700)),
                         ],
                       ),
                     ),
                     const SizedBox(height: 4),
                     
                     // Title
                     Text(data.name ?? "",
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, height: 1.2),
                     ),
                     const SizedBox(height: 12),
                     
                     // Price & Button
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text(price, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                         
                         // ADD BUTTON
                         InkWell(
                           onTap: isSaleable ? () {
                              checkInternetConnection().then((value) {
                                if (value) {
                                  if ((data.type == "simple" || data.type == "virtual")) {
                                     // 🟢 Call Drawer Bloc Event
                                     bloc?.add(AddToCartEvent(int.parse(data.id ?? "0"), 1));
                                  } else {
                                     ShowMessage.warningNotification(StringConstants.addOptions.localized(), context);
                                  }
                                } else {
                                   ShowMessage.errorNotification(StringConstants.internetIssue.localized(), context);
                                }
                              });
                           } : null,
                           child: Opacity(
                             opacity: isSaleable ? 1 : 0.5,
                             child: Container(
                               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                               decoration: BoxDecoration(
                                 border: Border.all(color: const Color(0xFF0C831F)),
                                 borderRadius: BorderRadius.circular(6),
                                 color: const Color(0xFFF7FFF9),
                               ),
                               child: const Text("ADD", style: TextStyle(color: Color(0xFF0C831F), fontWeight: FontWeight.w800, fontSize: 11)),
                             ),
                           ),
                         )
                       ],
                     )
                   ],
                 ),
               ),
            ),
          ],
        ),
      ),
    );
  }
}