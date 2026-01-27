/*
 * Webkul Software.
 * @package Mobikul Application Code.
 */
import 'package:bagisto_app_demo/screens/cart_screen/widget/guest_checkout_view.dart';
import '../utils/cart_index.dart';

class ProceedView extends StatelessWidget {
  final CartModel cartDetailsModel;
  final CartScreenBloc? cartScreenBloc;

  const ProceedView({
    super.key,
    required this.cartDetailsModel,
    this.cartScreenBloc,
  });

  @override
  Widget build(BuildContext context) {
    bool isUser = appStoragePref.getCustomerLoggedIn();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () async {
          // --- PURE PROCEED LOGIC ---
          if (isUser) {
            if(context.mounted) {
              Navigator.pushNamed(context, checkoutScreen,
                arguments: CartNavigationData(
                    total: cartDetailsModel.formattedPrice?.grandTotal.toString() ?? "0",
                    cartDetailsModel: cartDetailsModel,
                    cartScreenBloc: cartScreenBloc,
                    isDownloadable: checkVirtualDownloadable(cartDetailsModel.items)));
            }
          } else {
            if(context.mounted){
              showModalBottomSheet(
                  backgroundColor: Colors.transparent,
                  context: context,
                  builder: (ctx) => GuestCheckoutView(
                    cartDetailsModel: cartDetailsModel,
                    cartScreenBloc: cartScreenBloc,
                  ));
            }
          }
        },
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF0C831F), // Blinkit Green
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // LEFT: Total
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartDetailsModel.formattedPrice?.grandTotal.toString() ?? "",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "TOTAL",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              // RIGHT: Button
              Row(
                children: [
                  Text(
                    StringConstants.proceed.localized().toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white, 
                    size: 18
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}