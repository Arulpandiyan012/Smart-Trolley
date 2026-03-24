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
import 'package:bagisto_app_demo/widgets/floating_cart_bar.dart'; 

import 'package:bagisto_app_demo/screens/product_screen/utils/index.dart';
import 'package:hive/hive.dart';
import 'package:share_plus/share_plus.dart';

import '../data_model/download_sample_model.dart';
import 'package:bagisto_app_demo/screens/product_screen/view/blinkit_product_body.dart';

class ProductScreen extends StatefulWidget {
  final int? productId;
  final String? title;
  final String? urlKey;

  const ProductScreen({Key? key, this.title, this.productId, this.urlKey})
      : super(key: key);

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
    productScreenBLoc?.add(FetchProductEvent(widget.urlKey ?? "", productId: widget.productId, title: widget.title));
    
    // 🟢 SYNC CART: Ensure +/- buttons have info immediately
    context.read<CartScreenBloc>().add(FetchCartDataEvent());
    
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        
        
        body: Stack(
          children: [
            _setProductData(context),
            const FloatingCartBar(bottomMargin: 16),
          ],
        ),
      ),
    );
  }

  /// Product bloc method
  _setProductData(BuildContext context) {
    return BlocConsumer<ProductScreenBLoc, ProductBaseState>(
      listener: (BuildContext context, ProductBaseState state) {
        if (state is AddToCartProductState) {
          if (state.status == ProductStatus.fail) {
            ShowMessage.errorNotification(state.error ?? "", context);
          } else if (state.status == ProductStatus.success) {
            addToCartModel = state.response;
            ShowMessage.successNotification(state.successMsg ?? "", context);
            
            // 🟢 SYNC
            GlobalData.updateCartState(addToCartModel?.cart);
            if (addToCartModel?.cart != null) {
              appStoragePref.setCartCount(addToCartModel!.cart!.itemsQty ?? 0);
            }
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
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                "Failed to load product",
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27C16B)),
                child: const Text("Go Back", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    }
    
    // Handle loading states
    if (state is AddToCartProductState) isLoading = false;
    if (state is OnClickProductLoaderState) isLoading = state.isReqToShowLoader ?? false;

    // 🟢 FIX: If productData is still null (e.g. BLoC is in an intermediate state from
    // a previous screen), show the loader instead of a blank screen.
    if (productData == null) {
      return const ProductDetailLoader();
    }

    // Return the Blinkit Product Body
    return BlinkitProductBody(
      productData: productData,
      productScreenBLoc: productScreenBLoc,
    );
  }
  
  // (Helper methods like getId, etc. can remain here if used by other parts, 
  // but BlinkitProductBody now handles most logic)
}