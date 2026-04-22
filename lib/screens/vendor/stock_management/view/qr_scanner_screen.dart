import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:dio/dio.dart';

class VendorQRScannerScreen extends StatefulWidget {
  final Function(String)? onScan;
  const VendorQRScannerScreen({Key? key, this.onScan}) : super(key: key);

  @override
  State<VendorQRScannerScreen> createState() => _VendorQRScannerScreenState();
}

class _VendorQRScannerScreenState extends State<VendorQRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool isProcessing = false;
  final String _apiUrl = "https://ecom.thesmartedgetech.com/mobikul-vendor-api.php";

  void _onDetect(BarcodeCapture capture) async {
    if (isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String code = barcodes.first.rawValue ?? "";
      if (code.isNotEmpty) {
        if (widget.onScan != null) {
          widget.onScan!(code);
          Navigator.pop(context);
          return;
        }
        setState(() => isProcessing = true);
        _lookupAndShowProduct(code);
      }
    }
  }

  Future<void> _lookupAndShowProduct(String sku) async {
    try {
      final response = await Dio().post(
        _apiUrl,
        data: {"action": "get_vendor_products"},
      );

      if (response.data['success'] == true) {
        final products = response.data['data'] as List;
        final product = products.firstWhere(
          (p) => p['sku'].toString() == sku || p['id'].toString() == sku,
          orElse: () => null,
        );

        if (product != null) {
          _showProductBottomSheet(product);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Product not found: $sku")),
          );
          setState(() => isProcessing = false);
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isProcessing = false);
    }
  }

  void _showProductBottomSheet(dynamic product) {
    final TextEditingController stockCtrl = TextEditingController(text: product['stock'].toString());
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(product['image'] ?? "", width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.inventory, size: 40)),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product['name'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("SKU: ${product['sku']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            TextField(
              controller: stockCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: "Update Stock Quantity",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _updateStock(product['id'].toString(), int.parse(stockCtrl.text)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27C16B), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ).then((_) {
      if (mounted) setState(() => isProcessing = false);
    });
  }

  Future<void> _updateStock(String id, int qty) async {
    Navigator.pop(context);
    try {
      await Dio().post(_apiUrl, data: {"action": "update_stock", "product_id": id, "qty": qty});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Stock Updated ✅"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update stock")));
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Product Code", style: TextStyle(color: Color(0xFF27C16B), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF27C16B), width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          if (isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Color(0xFF27C16B))),
            ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  isProcessing ? "Fetching Details..." : "Align QR/Barcode within the frame",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
