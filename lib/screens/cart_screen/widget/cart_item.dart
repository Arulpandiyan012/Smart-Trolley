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
                    productId: int.parse(item?.product?.id ?? "")));
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              // Subtle shadow for the card
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04), 
                  blurRadius: 4, 
                  offset: const Offset(0, 2)
                )
              ],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. IMAGE (Left Side)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
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
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
                            color: Colors.grey[600], 
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
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                       child: const Icon(Icons.close, size: 20, color: Colors.grey),
                     ),
                     const SizedBox(height: 12),
                     
                     // Green Counter Button
                     Container(
                       height: 32,
                       decoration: BoxDecoration(
                         color: const Color(0xFF0C831F), // Blinkit Green
                         borderRadius: BorderRadius.circular(6),
                       ),
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
                     
                     const SizedBox(height: 8),
                     
                     // Price (Bottom Right)
                     Text(
                        _formatPrice(item?.formattedPrice?.price),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
    // 1. Create payload
    List<Map<dynamic, String>> updateItem = [{
      "cartItemId": item?.id.toString() ?? "",
      "quantity": newQty.toString()
    }];

    // 2. Trigger Bloc Event Directly
    cartScreenBloc?.add(UpdateCartEvent(updateItem));
  }

  // Helper to format price (1 decimal)
  String _formatPrice(dynamic price) {
    if (price == null) return "";
    String priceStr = price.toString();
    if (priceStr.contains('.')) {
      int dotIndex = priceStr.indexOf('.');
      if (dotIndex + 2 <= priceStr.length) {
        return priceStr.substring(0, dotIndex + 2); 
      }
    }
    return priceStr;
  }

  // --- Helper to remove item ---
  _onPressRemove(CartModel cartDetailsModel, int itemIndex, BuildContext context) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(StringConstants.deleteItemWarning.localized(), style: const TextStyle(fontSize: 16)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: Text(StringConstants.no.localized(), style: const TextStyle(color: Colors.grey)),
            ),
            TextButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  cartScreenBloc?.add(RemoveCartItemEvent(
                      cartItemId: int.parse(cartDetailsModel.items?[itemIndex].id ?? "")));
                },
                child: Text(StringConstants.yes.localized(), style: const TextStyle(color: Colors.red)))
          ],
        );
      },
    );
  }
}