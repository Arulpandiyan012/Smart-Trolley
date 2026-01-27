/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagisto_app_demo/screens/checkout/utils/index.dart';
import '../../data_model/checkout_save_shipping_model.dart';
// Ensure url_launcher is in your pubspec.yaml
import 'package:url_launcher/url_launcher.dart'; 

class CheckoutPaymentView extends StatefulWidget {
  final String? shippingId;
  final Function(String)? callBack;
  final ValueChanged<String>? priceCallback;
  final String? total;
  final PaymentMethods? paymentMethods;

  const CheckoutPaymentView({
    Key? key,
    this.total,
    this.shippingId,
    this.callBack,
    this.priceCallback,
    this.paymentMethods,
  }) : super(key: key);

  @override
  State<CheckoutPaymentView> createState() => _CheckoutPaymentViewState();
}

class _CheckoutPaymentViewState extends State<CheckoutPaymentView> {
  // GPay Settings
  static const String _merchantVpa = 'your-vpa@bank'; 
  static const String _merchantName = 'Store Name';
  
  String? _selectedPaymentCode; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: _paymentBloc(context),
    );
  }

  Widget _paymentBloc(BuildContext context) {
    final checkOutPaymentBloc = context.read<CheckOutPaymentBloc>();
    if ((widget.paymentMethods?.paymentMethods ?? []).isEmpty) {
      checkOutPaymentBloc.add(
        CheckOutPaymentEvent(shippingMethod: widget.shippingId),
      );
    }
    return BlocConsumer<CheckOutPaymentBloc, CheckOutPaymentBaseState>(
      listener: (context, state) {},
      builder: (context, state) {
        return (widget.paymentMethods?.paymentMethods ?? []).isNotEmpty
            ? _buildPaymentList(widget.paymentMethods!)
            : _buildUI(context, state);
      },
    );
  }

  Widget _buildUI(BuildContext context, CheckOutPaymentBaseState state) {
    if (state is CheckOutFetchPaymentState && state.status == CheckOutPaymentStatus.success) {
      return _buildPaymentList(state.checkOutShipping!);
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildPaymentList(PaymentMethods checkOutShipping) {
    if (widget.priceCallback != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
         widget.priceCallback!(checkOutShipping.cart?.formattedPrice?.grandTotal ?? "");
      });
    }

    final methods = checkOutShipping.paymentMethods
        ?.where((element) => availablePaymentMethods.contains(element.method))
        .toList() ?? [];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: methods.length + 1, // +1 for GPay button if selected
      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        if (i == methods.length) {
          // GPay Button (Only if UPI selected)
          if (_selectedPaymentCode != null && (_selectedPaymentCode!.contains('money') || _selectedPaymentCode!.contains('bank'))) {
             return SizedBox(
               height: 50,
               child: ElevatedButton.icon(
                 style: ElevatedButton.styleFrom(
                   backgroundColor: const Color(0xFF0C831F), 
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                 ),
                 icon: const Icon(Icons.payment, color: Colors.white),
                 label: const Text('PAY VIA UPI / GPAY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                 onPressed: () => _payWithGPay(),
               ),
             );
          }
          return const SizedBox();
        }

        var method = methods[i];
        bool isSelected = _selectedPaymentCode == method.method;

        return InkWell(
          onTap: () {
            setState(() => _selectedPaymentCode = method.method);
            if (widget.callBack != null) widget.callBack!(method.method ?? '');
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? const Color(0xFF0C831F) : Colors.transparent, width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? const Color(0xFF0C831F) : Colors.grey),
                const SizedBox(width: 16),
                Text(method.methodTitle ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _payWithGPay() async {
    final uri = Uri.parse('upi://pay?pa=$_merchantVpa&pn=$_merchantName&am=${widget.total?.replaceAll(RegExp(r'[^0-9.]'), '')}&cu=INR');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch UPI app')));
    }
  }
}