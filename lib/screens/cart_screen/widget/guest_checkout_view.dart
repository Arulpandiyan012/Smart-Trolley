/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */
import '../utils/cart_index.dart';

class GuestCheckoutView extends StatelessWidget {
  final CartModel cartDetailsModel;
  final CartScreenBloc? cartScreenBloc;

  const GuestCheckoutView(
      {Key? key, required this.cartDetailsModel, required this.cartScreenBloc})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if guest checkout is allowed (Only if NO downloadable items)
    bool isGuestAllowed = !checkDownloadable(cartDetailsModel.items);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min, // <--- Correctly placed inside Column
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header
          const Text(
            "Account",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Login to access your saved addresses, track orders, and redeem coupons.",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // 2. LOGIN BUTTON (Primary)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(signIn);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C831F), // Blinkit Green
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                "LOGIN",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),

          // 3. SIGN UP BUTTON (Secondary)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(context, signUp, arguments: false);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0C831F)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "CREATE AN ACCOUNT",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C831F),
                ),
              ),
            ),
          ),

          // 4. GUEST CHECKOUT (Conditional)
          if (isGuestAllowed) ...[
            const SizedBox(height: 24),
            
            // Stylish Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[300])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text("OR", style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Expanded(child: Divider(color: Colors.grey[300])),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Guest Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () {
                  // Keep your exact original logic
                  bool downloadable = checkVirtualDownloadable(cartDetailsModel.items);
                  Navigator.pushNamed(context, checkoutScreen,
                      arguments: CartNavigationData(
                          total: cartDetailsModel.formattedPrice?.grandTotal.toString() ?? "0",
                          cartDetailsModel: cartDetailsModel,
                          cartScreenBloc: cartScreenBloc,
                          isDownloadable: downloadable));
                },
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300)
                  ),
                  backgroundColor: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      "CONTINUE AS GUEST",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18, color: Colors.black87)
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}