import '../utils/cart_index.dart';

class CartActionsView extends StatelessWidget {
  final CartScreenBloc? cartScreenBloc;

  const CartActionsView({super.key, this.cartScreenBloc});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. CONTINUE SHOPPING (Green Outline Button)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, home);
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF0C831F)), // Blinkit Green
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.white,
            ),
            child: Text(
              StringConstants.continueShopping.localized().toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF0C831F),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),

        // 2. EMPTY CART (Subtle Red Button)
        InkWell(
          onTap: () => _onPressAllRemove(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  StringConstants.emptyCart.localized().toUpperCase(),
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Confirmation Dialog for Empty Cart
  Future<dynamic> _onPressAllRemove(BuildContext context) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            StringConstants.deleteAllItemWarning.localized(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: const Text("Are you sure you want to remove all items?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: Text(
                StringConstants.no.localized(),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  cartScreenBloc?.add(RemoveAllCartItemEvent());
                },
                child: Text(
                  StringConstants.yes.localized(),
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ))
          ],
        );
      },
    );
  }
}