/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:bagisto_app_demo/screens/categories_screen/utils/index.dart';
import 'package:bagisto_app_demo/screens/filter_screen/utils/index.dart' hide FilterFetchState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagisto_app_demo/screens/categories_screen/widget/blinkit_product_card.dart';

// 🟢 FIX 1: ADD MISSING CART IMPORTS
import 'package:bagisto_app_demo/screens/cart_screen/bloc/cart_screen_bloc.dart';
import 'package:bagisto_app_demo/screens/cart_screen/bloc/cart_screen_event.dart';
import 'package:bagisto_app_demo/screens/cart_screen/bloc/cart_screen_state.dart';
import 'package:bagisto_app_demo/screens/cart_screen/utils/cart_index.dart'; // For CartStatus

class SubCategoryScreen extends StatefulWidget {
  final String? title;
  final String? image;
  final String? categorySlug;
  final String? id;
  final String? metaDescription;

  const SubCategoryScreen(
      {super.key,
      this.title,
      this.image,
      this.categorySlug,
      this.metaDescription, 
      this.id});

  @override
  State<SubCategoryScreen> createState() => _SubCategoryScreenState();
}

class _SubCategoryScreenState extends State<SubCategoryScreen> {
  bool isLoggedIn = false;
  NewProductsModel? categoriesData;
  AddToCartModel? addToCartModel;
  bool isLoading = false;
  int page = 1;
  List<Map<String, dynamic>> filters = [];
  CategoryBloc? subCategoryBloc;
  ScrollController? _scrollController;
  GetFilterAttribute? data;
  bool isPreCatching = true;

  @override
  void initState() {
    appStoragePref.setSortName("");
    filters.add({"key": '"category_id"', "value": '"${widget.id}"'});
    isLoggedIn = appStoragePref.getCustomerLoggedIn();
    _scrollController = ScrollController();
    _scrollController?.addListener(() => _setItemScrollListener());
    subCategoryBloc = context.read<CategoryBloc>();
    
    subCategoryBloc?.add(FilterFetchEvent(widget.categorySlug));
    super.initState();
  }

  void _setItemScrollListener() {
    if (_scrollController!.hasClients &&
        _scrollController?.position.maxScrollExtent ==
            _scrollController?.offset) {
      if (hasMoreData()) {
        page += 1;
        subCategoryBloc?.add(FetchSubCategoryEvent(filters, page));
      }
    }
  }

  bool hasMoreData() {
    var total = categoriesData?.paginatorInfo?.total ?? 0;
    return (total > (categoriesData?.data?.length ?? 0) && !isLoading);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: CommonAppBar(widget.title ?? ""),
        body: _setSubCategoryData(context));
  }

  BlocListener<CartScreenBloc, CartScreenBaseState> _setSubCategoryData(BuildContext context) {
    // 🟢 FIX 2: WRAP WITH CART LISTENER (Handles +/- Updates)
    return BlocListener<CartScreenBloc, CartScreenBaseState>(
      listener: (context, state) {
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
      child: BlocConsumer<CategoryBloc, CategoriesBaseState>(
        listener: (BuildContext context, CategoriesBaseState state) {
          // Wishlist Listeners
          if (state is FetchDeleteAddItemCategoryState) {
            if (state.status == CategoriesStatus.fail) {
              ShowMessage.errorNotification(state.error ?? "", context);
            } else if (state.status == CategoriesStatus.success) {
              ShowMessage.successNotification(state.successMsg ?? "", context);
              setState(() {}); 
            }
          }
          if (state is RemoveWishlistState) {
            if (state.status == CategoriesStatus.fail) {
              ShowMessage.errorNotification(state.error ?? "", context);
            } else if (state.status == CategoriesStatus.success) {
              ShowMessage.successNotification(state.response?.message ?? "", context);
              setState(() {}); 
            }
          }
          if (state is AddToCompareSubCategoryState) {
            if (state.status == CategoriesStatus.fail) {
              ShowMessage.errorNotification(state.error ?? "", context);
            } else if (state.status == CategoriesStatus.success) {
              ShowMessage.successNotification(state.successMsg ?? "", context);
            }
          }

          // 🟢 FIX 3: REFRESH CART ON ADD SUCCESS
          if (state is AddToCartSubCategoriesState) {
            isPreCatching = false;
            if (state.status == CategoriesStatus.fail) {
              ShowMessage.errorNotification(state.error ?? "", context);
            } else if (state.status == CategoriesStatus.success) {
              // Refresh global cart
              context.read<CartScreenBloc>().add(FetchCartDataEvent());
              
              GlobalData.cartCountController.sink.add(state.response?.cart?.itemsQty ?? 0);
              addToCartModel = state.response;
              ShowMessage.successNotification(state.successMsg ?? "", context);
            }
          }
        },
        builder: (BuildContext context, CategoriesBaseState state) {
          GlobalData.cartCountController.sink.add(appStoragePref.getCartCount());
          return buildContainer(context, state);
        },
      ),
    );
  }

  Widget buildContainer(BuildContext context, CategoriesBaseState state) {
    if (state is ShowLoaderCategoryState) {
      return const SubCategoriesLoader();
    }
    if (state is FetchSubCategoryState) {
      isPreCatching = true;
      if (state.status == CategoriesStatus.success) {
        if (page > 1) {
          categoriesData?.data?.addAll(state.categoriesData?.data ?? []);
        } else {
          categoriesData = state.categoriesData;
          isLoading = false;
        }
      }
      if (state.status == CategoriesStatus.fail) {
        return ErrorMessage.errorMsg(state.error ?? "Error");
      }
    }
    
    if (state is FetchDeleteAddItemCategoryState) isLoading = false;
    if (state is RemoveWishlistState) isLoading = false;
    if (state is AddToCartSubCategoriesState) {
      isLoading = false;
      if (state.status == CategoriesStatus.success) {
        GlobalData.cartCountController.sink.add(addToCartModel?.cart?.itemsQty ?? 0);
      }
    }
    if (state is AddToCompareSubCategoryState) isLoading = false;
    if (state is OnClickSubCategoriesLoaderState) {
      isLoading = state.isReqToShowLoader ?? false;
    }
    
    if (state is FilterFetchState) {
      data = state.filterModel;
      subCategoryBloc?.add(FetchSubCategoryEvent(filters, page));
    }
    
    return buildHomePageUI();
  }

  Widget buildHomePageUI() {
    return _subCategoriesDataUI(isLoading);
  }

  Widget _subCategoriesDataUI(bool isLoading) {
    if (categoriesData?.data == null && isLoading) {
      return const SubCategoriesLoader();
    }
    
    if ((categoriesData?.data ?? []).isEmpty) {
      return const Center(child: Text("No products found"));
    }

    return SafeArea(
      child: Column(
        children: [
          // Sort & Filter Bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _openSortSheet(),
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
                    onTap: () => _openFilterScreen(),
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

          // The Product List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 12, bottom: 20),
              itemCount: (categoriesData?.data?.length ?? 0) + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= (categoriesData?.data?.length ?? 0)) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return BlinkitProductCard(
                  data: categoriesData!.data![index],
                  isLoggedIn: isLoggedIn,
                  subCategoryBloc: subCategoryBloc,

                  // 🟢 FIX 4: CONNECT ADD TO CART BUTTON
                  onAddToCart: (int productId, int quantity) {
                     subCategoryBloc?.add(AddToCartSubCategoryEvent(productId, quantity));
                  },

                  onAddToWishlist: (String id, bool isInWishlist, dynamic product) {
                    if (isLoggedIn) {
                      try {
                         (product as NewProducts).isInWishlist = !isInWishlist;
                      } catch (_) {}
                      setState(() {});

                      if (isInWishlist) {
                        subCategoryBloc?.add(FetchDeleteItemEvent(id, product));
                      } else {
                        subCategoryBloc?.add(FetchDeleteAddItemCategoryEvent(id, product));
                      }
                    } else {
                      ShowMessage.warningNotification("Please login", context);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openFilterScreen() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) =>
        SubCategoriesFilterScreen(
          categorySlug: widget.categorySlug,
          subCategoryBloc: subCategoryBloc,
          page: page,
          data: data,
          filters: filters,
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
          categorySlug: widget.categorySlug,
          page: page,
          filters: filters,
          subCategoryBloc: subCategoryBloc,
        ),
      )
    );
  }
}