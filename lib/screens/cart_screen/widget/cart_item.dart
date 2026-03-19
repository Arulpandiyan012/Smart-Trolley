/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:bagisto_app_demo/utils/extension.dart';
import '../utils/cart_index.dart';

class CartListItem extends StatelessWidget {
  final CartModel cartDetailsModel;
  final CartScreenBloc? cartScreenBloc;

  const CartListItem({
    Key? key,
    required this.cartDetailsModel,
    this.cartScreenBloc,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cartDetailsModel.items?.length ?? 0,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (BuildContext context, int itemIndex) {
        var item = cartDetailsModel.items?[itemIndex];
        
        return InkWell(
          onTap: () {
            Navigator.pushNamed(context, productScreen,
                arguments: PassProductData(
                    title: item?.name ?? '',
                    urlKey: item?.product?.urlKey,
                    productId: int.tryParse(item?.product?.id ?? "") ?? 0));
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              // Subtle shadow for the card
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04), 
                  blurRadius: 4, 
                  offset: const Offset(0, 2)
                )
              ],
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. IMAGE (Left Side)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: ((item?.product?.images ?? []).isNotEmpty)
                      ? ImageView(
                          url: item?.product?.images?[0].url ?? "",
                          height: 60,
                          width: 60,
                          fit: BoxFit.contain,
                        )
                      : ImageView(
                          url: AssetConstants.placeHolder,
                          height: 60,
                          width: 60,
                        ),
                ),
                
                const SizedBox(width: 12),
                
                // 2. MIDDLE SECTION (Name + Save for Later)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      Text(
                        item?.name ?? "",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600, 
                          fontSize: 14,
                          color: Theme.of(context).textTheme.titleLarge?.color
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      // "Save for later" with Dashed Underline
                      InkWell(
                      onTap: () {
                          bool isLogged = appStoragePref.getCustomerLoggedIn();
                          if (isLogged) {
                            // 🟢 FIX: Send "CartItemId:ProductId"
                            String cartItemId = item?.id ?? "0";
                            String productId = item?.product?.id ?? "0";
                            
                            cartScreenBloc?.add(MoveToCartEvent("$cartItemId:$productId"));
                          } else {
                            ShowMessage.warningNotification(StringConstants.pleaseLogin.localized(), context);
                          }
                        },
                        child: Text(
                          "Save for later",
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color, 
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            decorationStyle: TextDecorationStyle.dashed, // Dashed line
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      // Attributes (like Weight/Size)
                      if (getAttributesValueFromAdditional(item?.additional) != null)
                        ...List.generate(
                           getAttributesValueFromAdditional(item?.additional)?.length ?? 0,
                           (index) => Text(
                              "${getAttributeKeyValueFromAdditional(item?.additional, index, 'option_label')}",
                              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12),
                           )
                        ),
                    ],
                  ),
                ),
                
                // 3. RIGHT SIDE (Remove X + Counter + Price)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                     // Top Right 'X' Button
                     InkWell(
                       onTap: () => _onPressRemove(cartDetailsModel, itemIndex, context),
                       child: Icon(Icons.close, size: 20, color: Theme.of(context).hintColor),
                     ),
                     const SizedBox(height: 12),
                     
                     // Green Counter Button
                     Material(
                       color: const Color(0xFF27C16B), // Blinkit Green
                       borderRadius: BorderRadius.circular(6),
                       clipBehavior: Clip.hardEdge,
                       child: SizedBox(
                         height: 32,
                         child: Row(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             // Minus
                             InkWell(
                               onTap: () {
                                 int currentQty = item?.quantity ?? 1;
                                 if (currentQty > 1) {
                                   _updateQty(item, currentQty - 1);
                                 } else {
                                   _onPressRemove(cartDetailsModel, itemIndex, context);
                                 }
                               },
                               child: const Padding(
                                 padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                                 child: Icon(Icons.remove, color: Colors.white, size: 16),
                               ),
                             ),
                             
                             // Qty Text
                             Padding(
                               padding: const EdgeInsets.symmetric(horizontal: 4.0),
                               child: Text(
                                 item?.quantity?.toString() ?? "1",
                                 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                               ),
                             ),
                             
                             // Plus
                             InkWell(
                               onTap: () {
                                 int currentQty = item?.quantity ?? 1;
                                 _updateQty(item, currentQty + 1);
                               },
                               child: const Padding(
                                 padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                                 child: Icon(Icons.add, color: Colors.white, size: 16),
                               ),
                             ),
                           ],
                         ),
                       ),
                     ),
                     
                     const SizedBox(height: 8),
                     
                     // Price (Bottom Right) — shows line total (qty × unit price)
                     Text(
                        _formatPrice(item?.formattedPrice?.total ?? item?.formattedPrice?.price),
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 14,
                          color: Theme.of(context).textTheme.titleLarge?.color
                        ),
                      ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Helper to update quantity immediately ---
  void _updateQty(var item, int newQty) {
    // 🟠 OPTIMISTIC UPDATE
    int pid = int.tryParse(item?.product?.id ?? "0") ?? 0;
    int currentQty = item?.quantity ?? 0;
    GlobalData.optimisticUpdateCart(pid, newQty - currentQty);

    // 1. Create payload
    List<Map<dynamic, String>> updateItem = [{
      "cartItemId": item?.id.toString() ?? "",
      "quantity": newQty.toString()
    }];

    // 2. Trigger Bloc Event Directly
    cartScreenBloc?.add(UpdateCartEvent(updateItem));
  }

  // Helper to format price (2 decimals, handles ₹ prefix and raw numbers)
  String _formatPrice(dynamic price) {
    if (price == null) return "";
    String priceStr = price.toString().trim();
    if (priceStr.isEmpty) return "";

    // If already a formatted string like "₹120.00", enforce 2 decimals
    final prefixMatch = RegExp(r'^([^\d]*)([\d.]+)(.*)$').firstMatch(priceStr);
    if (prefixMatch != null) {
      final prefix = prefixMatch.group(1)!;
      final numStr = prefixMatch.group(2)!;
      final suffix = prefixMatch.group(3)!;
      final value = double.tryParse(numStr);
      if (value != null) {
        return '$prefix${value.toStringAsFixed(2)}$suffix';
      }
    }

    // Fallback: try parse whole string as number
    final value = double.tryParse(priceStr.replaceAll(RegExp(r'[^\d.]'), ''));
    if (value != null) return '₹${value.toStringAsFixed(2)}';

    return priceStr;
  }

  // --- Helper to remove item ---
  _onPressRemove(CartModel cartDetailsModel, int itemIndex, BuildContext context) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            StringConstants.deleteItemWarning.localized(), 
            style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.titleLarge?.color)
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: Text(
                StringConstants.no.localized(), 
                style: TextStyle(color: Theme.of(context).hintColor)
              ),
            ),
            TextButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  
                  // 🟠 OPTIMISTIC REMOVE
                  var item = cartDetailsModel.items?[itemIndex];
                  int pid = int.tryParse(item?.product?.id ?? "0") ?? 0;
                  int qty = item?.quantity ?? 0;
                  GlobalData.optimisticUpdateCart(pid, -qty);

                  cartScreenBloc?.add(RemoveCartItemEvent(
                      cartItemId: int.tryParse(item?.id ?? "") ?? 0));
                },
                child: Text(StringConstants.yes.localized(), style: const TextStyle(color: Colors.red)))
          ],
        );
      },
    );
  }
}