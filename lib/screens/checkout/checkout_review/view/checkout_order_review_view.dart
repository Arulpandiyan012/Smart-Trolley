/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagisto_app_demo/screens/checkout/utils/index.dart';
import 'package:bagisto_app_demo/screens/checkout/data_model/save_payment_model.dart';
import 'package:bagisto_app_demo/screens/cart_screen/utils/cart_extensions.dart'; // 🟢 FIXED: Package import


//ignore: must_be_immutable
class CheckoutOrderReviewView extends StatefulWidget {
  final String? paymentId;
  final Function(String)? callBack;
  final CartScreenBloc? cartScreenBloc;
  CartModel? cartDetailsModel;
  final String? displayAddress; 
  final VoidCallback? onAddressChange; // 🟢 NEW

  CheckoutOrderReviewView({
    Key? key,
    this.paymentId,
    this.callBack,
    this.cartDetailsModel,
    this.cartScreenBloc,
    this.displayAddress, 
    this.onAddressChange,
  }) : super(key: key);

  @override
  State<CheckoutOrderReviewView> createState() => _CheckoutOrderReviewViewState();
}

class _CheckoutOrderReviewViewState extends State<CheckoutOrderReviewView> {
  CheckOutReviewBloc? checkOutReviewBloc;

  @override
  void initState() {
    checkOutReviewBloc = context.read<CheckOutReviewBloc>();
    checkOutReviewBloc?.add(CheckOutReviewSavePaymentEvent(paymentMethod: widget.paymentId));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CheckOutReviewBloc, CheckOutReviewBaseState>(
      listener: (context, state) {},
      builder: (context, state) {
        if (state is CheckOutReviewSavePaymentState) {
          if (state.status == CheckOutReviewStatus.success) {
            if (widget.callBack != null) {
              var cart = state.savePaymentModel?.cart;
              
              // 🟢 RE-SIMULATE FIRST25 (Backend doesn't know about it)
              if (GlobalData.appliedCouponCode == "FIRST25" && cart != null) {
                 double discountRes = cart.subTotalValue * 0.25;
                 double adjusted = cart.subTotalValue + cart.taxValue + cart.deliveryFeeValue - discountRes;
                 
                 cart.couponCode = "FIRST25";
                 cart.formattedPrice?.discountAmount = "-${GlobalData.currencyCode ?? "₹"} ${discountRes.toStringAsFixed(2)}";
                 cart.formattedPrice?.grandTotal = "${GlobalData.currencyCode ?? "₹"} ${adjusted.toStringAsFixed(2)}";
              }
              
              widget.cartDetailsModel = cart;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.callBack!(cart?.formattedPrice?.grandTotal.toString() ?? "");
              });
            }
            return _reviewOrder(state.savePaymentModel!);
          }
          if (state.status == CheckOutReviewStatus.fail) {
            return Center(child: ErrorMessage.errorMsg(StringConstants.somethingWrong.localized()));
          }
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _reviewOrder(SavePayment savePaymentModel) {
    var cart = savePaymentModel.cart;
    if (cart == null) return const SizedBox();

    // 🟢 UNIFIED CALCULATIONS (Via Extension)
    double sub = cart.subTotalValue;
    double tax = cart.taxValue;
    double discount = cart.discountValue;
    double deliveryFee = cart.deliveryFeeValue;
    double adjustedGrand = cart.adjustedGrandTotal;


    String currency = GlobalData.currencyCode ?? "₹";
    
    // 🟢 FIX: Prioritize passed address.
    String finalAddress = widget.displayAddress ?? "";
    
    // Fallback to extraction if empty
    if (finalAddress.isEmpty || finalAddress.trim() == ",") {
        String safeAddress = cart.shippingAddress?.address1?.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '') ?? "";
        String safeCity = cart.shippingAddress?.city ?? "";
        String safeZip = cart.shippingAddress?.postcode ?? "";
        if (safeAddress.isNotEmpty) {
           finalAddress = "$safeAddress, $safeCity - $safeZip";
        } else {
           finalAddress = "Delivery Address (View Details)"; 
        }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ITEMS SECTION
          const Text("Items in Order", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cart.items?.length ?? 0,
            separatorBuilder: (ctx, i) => const Divider(),
            itemBuilder: (ctx, i) {
              var item = cart.items![i];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 50, width: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ImageView(
                        url: _productImage(item.product),
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name ?? "", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text("Qty: ${item.quantity}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(_formatPrice(item.formattedPrice?.price ?? ""), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),

          // 2. DELIVERY ADDRESS CARD
          _buildInfoCard(
            title: "Delivering to",
            icon: Icons.location_on,
            content: finalAddress, 
            showEdit: true, 
          ),

          const SizedBox(height: 16),

          // 3. PAYMENT METHOD CARD
          _buildInfoCard(
            title: "Payment Method",
            icon: Icons.payment,
            content: cart.payment?.methodTitle ?? cart.payment?.method ?? "N/A",
          ),

          const SizedBox(height: 24),

          // 4. BILL SUMMARY
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Bill Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Divider(height: 24),
                _buildRow("Item Total", "$currency ${sub.toStringAsFixed(2)}"),
                
                // Taxes
                if (tax > 0) _buildRow("Taxes", "$currency ${tax.toStringAsFixed(2)}"),

                // Discount
                if (discount > 0)
                   _buildRow("Discount", "- $currency ${discount.toStringAsFixed(2)}", isGreen: true),
                
                // Delivery Charges
                _buildRow(
                  "Delivery Fees", 
                  deliveryFee == 0 ? "FREE" : "$currency ${deliveryFee.toStringAsFixed(2)}", 
                  isGreen: deliveryFee == 0
                ),
                
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("To Pay", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(
                      "$currency ${adjustedGrand.toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ],
                )
              ],
            ),
          ),

          
          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required String content, bool showEdit = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[800])),
                ],
              ),
              if (showEdit && widget.onAddressChange != null)
                GestureDetector(
                  onTap: widget.onAddressChange,
                  child: Text(
                    "EDIT",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isGreen = false}) {
    String cleanValue = _formatPrice(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          Text(cleanValue, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isGreen ? const Color(0xFF27C16B) : Colors.black87)),
        ],
      ),
    );
  }

  String _formatPrice(String price) {
    if (price.isEmpty) return price;
    return price.replaceAllMapped(RegExp(r'(\.\d{2})\d+'), (match) => match.group(1)!);
  }

  reload(){
    checkOutReviewBloc?.add(CheckOutReviewSavePaymentEvent(paymentMethod: widget.paymentId));
  }

  String? _productImage(dynamic p) {
    if (p == null) return null;
    try {
      final imgs = (p as dynamic).images;
      if (imgs is List && imgs.isNotEmpty) {
        for (var i in imgs) {
          final u = _imageFromAny(i);
          if (u != null && u.isNotEmpty) return u;
        }
      }
    } catch (_) {}
    return null;
  }

  String? _imageFromAny(dynamic img) {
    if (img == null) return null;
    try { if (img.url is String && img.url.isNotEmpty) return img.url; } catch (_) {}
    try { if (img.path is String && img.path.isNotEmpty) return img.path; } catch (_) {}
    return null;
  }
}
