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
import 'package:bagisto_app_demo/screens/product_screen/utils/index.dart';
import 'package:hive/hive.dart';
import 'package:share_plus/share_plus.dart';

import '../data_model/download_sample_model.dart';
import 'package:bagisto_app_demo/screens/product_screen/view/blinkit_product_body.dart';

class ProductScreen extends StatefulWidget {
  final int? productId;
  final String? title;
  final String? urlKey;

  const ProductScreen({super.key, this.title, this.productId, this.urlKey});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  bool isLoggedIn = false;
  int qty = 1;
  List downloadLinks = [];
  List groupedParams = [];
  List bundleParams = [];
  List configurableParams = [];
  List selectList = [];
  List selectParam = [];
  int bundleQty = 1;
  dynamic configurableProductId;
  String? price;
  NewProducts? productData;
  CartModel? cart;
  dynamic productFlats;
  AddToCartModel? addToCartModel;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  bool isLoading = false;
  final _scrollController = ScrollController();
  ProductScreenBLoc? productScreenBLoc;
  DownloadSampleModel? downloadSampleModel;

  @override
  void initState() {
    isLoggedIn = appStoragePref.getCustomerLoggedIn();
    
    // Ensure the stream has data, but StreamBuilder might miss this event if it builds too late
    GlobalData.cartCountController.sink.add(appStoragePref.getCartCount());
    
    productScreenBLoc = context.read<ProductScreenBLoc>();
    productScreenBLoc?.add(FetchProductEvent(widget.urlKey ?? "", productId: widget.productId));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5), // Match main theme background
        
        // 🟢 FIX 1: Use FloatingActionButton for the "View Cart" bar
        // This allows it to float OVER the content (using the SizedBox(100) as padding)
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: StreamBuilder(
          // 🟢 FIX 2: Add initialData so it shows up IMMEDIATELY
          initialData: appStoragePref.getCartCount(), 
          stream: GlobalData.cartCountController.stream,
          builder: (context, snapshot) {
            int cartCount = int.tryParse(snapshot.data.toString()) ?? 0;
            
            // Hide if empty
            if (cartCount == 0) return const SizedBox(); 

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF0C831F), // Blinkit Green
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, cartScreen).then((value) {
                   // Refresh product when returning from cart
                   productScreenBLoc?.add(FetchProductEvent(widget.urlKey ?? "", productId: widget.productId));
                }),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$cartCount item${cartCount > 1 ? 's' : ''}", 
                            style: const TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 13
                            )
                          ),
                          const Text(
                            "Total includes taxes",
                            style: TextStyle(
                              color: Colors.white70, 
                              fontSize: 10
                            )
                          ),
                        ],
                      ),
                      const Row(
                        children: [
                          Text(
                            "View Cart", 
                            style: TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 15
                            )
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_right, color: Colors.white),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        
        body: _setProductData(context),
      ),
    );
  }

  /// Product bloc method
  BlocConsumer<ProductScreenBLoc, ProductBaseState> _setProductData(BuildContext context) {
    return BlocConsumer<ProductScreenBLoc, ProductBaseState>(
      listener: (BuildContext context, ProductBaseState state) {
        if (state is AddToCartProductState) {
          if (state.status == ProductStatus.fail) {
            ShowMessage.errorNotification(state.error ?? "", context);
          } else if (state.status == ProductStatus.success) {
            addToCartModel = state.response;
            ShowMessage.successNotification(state.successMsg ?? "", context);
            
            // 🟢 FIX 3: Update Global Cart Count on Success
            GlobalData.cartCountController.sink
                .add(addToCartModel?.cart?.itemsQty ?? 0);
          }
        }
        // ... (Keep existing listeners for Wishlist, Compare, Download) ...
        if (state is AddToCompareListState) {
          if (state.status == ProductStatus.success) {
            ShowMessage.successNotification(state.successMsg ?? "", context);
          }
        }
        if (state is AddToWishListProductState) {
          if (state.status == ProductStatus.success) {
            ShowMessage.successNotification(state.successMsg ?? '', context);
          }
        } 
        if (state is RemoveFromWishlistState) {
          if (state.status == ProductStatus.success) {
            ShowMessage.successNotification(state.successMsg ?? '', context);
          }
        }
      },
      builder: (BuildContext context, ProductBaseState state) {
        return buildContainer(context, state);
      },
    );
  }

  ///build container method
  Widget buildContainer(BuildContext context, ProductBaseState state) {
    if (state is ProductInitialState) {
      return const ProductDetailLoader();
    }
    if (state is FetchProductState) {
      if (state.status == ProductStatus.success) {
        productData = state.productData;
        productFlats = productData?.productFlats
            ?.firstWhereOrNull((e) => e.locale == GlobalData.locale);

        cart = state.productData?.cart;
        
        // Update cart count from fetched data
        GlobalData.cartCountController.sink.add(appStoragePref.getCartCount());
      } else if (state.status == ProductStatus.fail) {
        Future.delayed(Duration.zero).then((value) => const NoInternetError());
        return CommonWidgets().getHeightSpace(0);
      }
    }
    
    // Handle loading states
    if (state is AddToCartProductState) isLoading = false;
    if (state is OnClickProductLoaderState) isLoading = state.isReqToShowLoader ?? false;

    // Return the Blinkit Product Body
    return BlinkitProductBody(
      productData: productData,
      productScreenBLoc: productScreenBLoc,
    );
  }
  
  // (Helper methods like getId, etc. can remain here if used by other parts, 
  // but BlinkitProductBody now handles most logic)
}