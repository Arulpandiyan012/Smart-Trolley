import 'package:bagisto_app_demo/screens/search_screen/utils/index.dart';
import '../../../../widgets/blinkit_vertical_product_card.dart';
import 'package:bagisto_app_demo/screens/home_page/utils/index.dart';
import 'package:bagisto_app_demo/screens/cart_screen/utils/cart_index.dart';

class ProductList extends StatelessWidget {
  final NewProductsModel? model;
  const ProductList({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = model?.data ?? [];
    if (items.isEmpty) return const SizedBox();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.58,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final product = items[index];
        return BlinkitVerticalProductCard(
          data: product,
          isLoggedIn: appStoragePref.getCustomerLoggedIn(),
          onAddToCart: (id) {
            if (id > 0) {
              context.read<HomePageBloc>().add(AddToCartEvent(id, 1, "Added"));
            }
          },
        );
      },
    );
  }
}
