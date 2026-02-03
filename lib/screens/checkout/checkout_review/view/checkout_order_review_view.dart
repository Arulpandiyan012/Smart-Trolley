/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagisto_app_demo/screens/checkout/utils/index.dart';
import 'package:bagisto_app_demo/screens/checkout/data_model/save_payment_model.dart';

//ignore: must_be_immutable
class CheckoutOrderReviewView extends StatefulWidget {
  final String? paymentId;
  final Function(String)? callBack;
  final CartScreenBloc? cartScreenBloc;
  CartModel? cartDetailsModel;
  final String? displayAddress; // 🟢 Address from parent

  CheckoutOrderReviewView({
    Key? key,
    this.paymentId,
    this.callBack,
    this.cartDetailsModel,
    this.cartScreenBloc,
    this.displayAddress, 
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
              widget.cartDetailsModel = state.savePaymentModel?.cart;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.callBack!(state.savePaymentModel?.cart?.formattedPrice?.grandTotal.toString() ?? "");
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
    
    // 🟢 FIX: Prioritize passed address.
    String finalAddress = widget.displayAddress ?? "";
    
    // Fallback to extraction if empty
    if (finalAddress.isEmpty || finalAddress.trim() == ",") {
        String safeAddress = cart?.shippingAddress?.address1?.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '') ?? "";
        String safeCity = cart?.shippingAddress?.city ?? "";
        String safeZip = cart?.shippingAddress?.postcode ?? "";
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
            itemCount: cart?.items?.length ?? 0,
            separatorBuilder: (ctx, i) => const Divider(),
            itemBuilder: (ctx, i) {
              var item = cart!.items![i];
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
                      child: (item.product?.images?.isNotEmpty ?? false)
                          ? Image.network(item.product!.images![0].url ?? "", fit: BoxFit.cover)
                          : const Icon(Icons.image, color: Colors.grey),
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
                    Text(item.formattedPrice?.price ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
          ),

          const SizedBox(height: 16),

          // 3. PAYMENT METHOD CARD
          _buildInfoCard(
            title: "Payment Method",
            icon: Icons.payment,
            content: cart?.payment?.methodTitle ?? cart?.payment?.method ?? "N/A",
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
                _buildRow("Item Total", cart?.formattedPrice?.subTotal ?? ""),
                if ((cart?.formattedPrice?.taxAmount ?? "0") != "₹0.00")
                   _buildRow("Taxes", cart?.formattedPrice?.taxAmount ?? ""),
                if ((cart?.formattedPrice?.discountAmount ?? "0") != "₹0.00")
                   _buildRow("Discount", "- ${cart?.formattedPrice?.discountAmount}", isGreen: true),
                
                // 🟢 FIX: Delivery Charges (Robust Calculation)
                Builder(builder: (context) {
                   String ship = cart?.formattedPrice?.shippingAmount ?? "0";
                   
                   // 1. Try direct field
                   if (ship != "₹0.00" && ship != "0" && ship != "") {
                      return _buildRow("Delivery Fees", ship);
                   }

                   // 2. Try selected rate
                   var rate = cart?.selectedShippingRate?.formattedPrice?.price;
                   if (rate != null && rate.toString() != "₹0.00" && rate.toString() != "0") {
                      return _buildRow("Delivery Fees", rate.toString());
                   }

                   // 3. Fallback: Calculate Difference (Grand - (Sub + Tax - Discount))
                   try {
                      double parsePrice(dynamic p) {
                         if (p == null) return 0.0;
                         String s = p.toString().replaceAll(RegExp(r'[^\d.]'), ''); 
                         return double.tryParse(s) ?? 0.0;
                      }

                      double grand = parsePrice(cart?.formattedPrice?.grandTotal);
                      double sub = parsePrice(cart?.formattedPrice?.subTotal);
                      double tax = parsePrice(cart?.formattedPrice?.taxAmount);
                      double discount = parsePrice(cart?.formattedPrice?.discountAmount);

                      double calculatedDiff = grand - (sub + tax - discount);

                      if (calculatedDiff > 0.5) { // Tolerance for rounding
                         return _buildRow("Delivery Fees", "₹${calculatedDiff.toStringAsFixed(2)}");
                      }
                   } catch (e) {
                      debugPrint("Price Calc Error: $e");
                   }

                   return const SizedBox();
                }),
                
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("To Pay", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(cart?.formattedPrice?.grandTotal ?? "", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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

  Widget _buildInfoCard({required String title, required IconData icon, required String content}) {
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
            children: [
              Icon(icon, size: 18, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[800])),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isGreen ? const Color(0xFF27C16B) : Colors.black87)),
        ],
      ),
    );
  }

  reload(){
    checkOutReviewBloc?.add(CheckOutReviewSavePaymentEvent(paymentMethod: widget.paymentId));
  }
}