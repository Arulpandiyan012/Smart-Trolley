/*
 *   Webkul Software.
 *   @package Mobikul Application Code.
 *   @Category Mobikul
 *   @author Webkul <support@webkul.com>
 *   @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 *   @license https://store.webkul.com/license.html
 *   @link https://store.webkul.com/license.html
 */




import 'package:bagisto_app_demo/screens/order_detail/utils/index.dart';
import 'package:bagisto_app_demo/screens/search_screen/utils/index.dart';

import '../../../../widgets/blinkit_product_card.dart';
import '../../../../utils/prefetching_helper.dart';
import 'package:bagisto_app_demo/screens/home_page/utils/index.dart';
import 'package:bagisto_app_demo/screens/cart_screen/utils/cart_index.dart';

class ProductList extends StatelessWidget {
  final NewProductsModel? model;
  const ProductList({Key? key,required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: model?.data?.length ?? 0,
        itemBuilder: (BuildContext context, int index) {
          NewProducts? product = model?.data?[index];

          return BlinkitProductCard(
            data: product,
            isLoggedIn: appStoragePref.getCustomerLoggedIn(),
            onAddToCart: (productId, quantity) {
               context.read<HomePageBloc>().add(AddToCartEvent(
                 productId, 1, "Added"
               ));
            },
          );
        });
  }

}
