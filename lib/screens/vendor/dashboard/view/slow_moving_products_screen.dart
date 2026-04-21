import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:bagisto_app_demo/utils/index.dart';
import 'package:bagisto_app_demo/screens/home_page/data_model/new_product_data.dart';
import 'package:collection/collection.dart';

class SlowMovingProductsScreen extends StatefulWidget {
  const SlowMovingProductsScreen({Key? key}) : super(key: key);

  @override
  State<SlowMovingProductsScreen> createState() => _SlowMovingProductsScreenState();
}

class _SlowMovingProductsScreenState extends State<SlowMovingProductsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _slowMovingProducts = [];
  int _totalDormant = 0;
  final String _apiUrl = "https://ecom.thesmartedgetech.com/mobikul-vendor-api.php";

  @override
  void initState() {
    super.initState();
    _analyzeStockVelocity();
  }

  Future<void> _analyzeStockVelocity() async {
    setState(() => _isLoading = true);
    try {
      // 🟢 Improved: Fetch ALL storefront products by looping through pages
      // The server currently caps results at 12 per page, so we must iterate.
      final List<NewProducts> allStorefrontData = [];
      int currentPage = 1;
      int totalItems = 0;
      
      // Safety cap of 50 pages to prevent infinite loops (401 items / 12 ~ 34 pages)
      while (currentPage < 50) {
        final pageResp = await ApiClient().getAllProducts(limit: 100, page: currentPage);
        if (pageResp == null || pageResp.data == null || pageResp.data!.isEmpty) break;
        
        allStorefrontData.addAll(pageResp.data!);
        totalItems = pageResp.paginatorInfo?.total ?? 0;
        
        debugPrint("📄 Fetched Storefront Page $currentPage: ${allStorefrontData.length} / $totalItems");
        
        if (allStorefrontData.length >= totalItems) break;
        currentPage++;
      }

      final responses = await Future.wait([
        Dio().post(_apiUrl, data: {"action": "get_vendor_products"}),
        Dio().post(_apiUrl, data: {"action": "get_deliveries"}),
      ]);

      final vendorProductsResp = responses[0] as Response;
      final vendorDeliveriesResp = responses[1] as Response;
      
      if (vendorProductsResp.data['success'] == true && vendorDeliveriesResp.data['success'] == true) {
        final products = vendorProductsResp.data['data'] as List;
        final orders = vendorDeliveriesResp.data['data'] as List;
        
        // 1. Build Multi-Index Storefront Maps
        final Map<String, dynamic> storefrontIdMap = {};
        final Map<String, dynamic> storefrontNameMap = {};
        final Map<String, dynamic> storefrontUrlMap = {};
        
        for (var sp in allStorefrontData) {
          final json = sp.toJson();
          // Manually add priceHtml object to the map because toJson() might not serialize it recursively
          json['priceHtmlObject'] = sp.priceHtml; 
          
          final sid = sp.id?.toString();
          final sname = (sp.name ?? "").toLowerCase().trim();
          final surl = (sp.urlKey ?? "").toLowerCase().trim();
          
          if (sid != null) storefrontIdMap[sid] = json;
          if (sname.isNotEmpty) storefrontNameMap[sname] = json;
          if (surl.isNotEmpty) storefrontUrlMap[surl] = json;
        }

        final Map<String, int> salesMap = {};
        for (var order in orders) {
          String items = (order['items'] ?? "").toString().toLowerCase();
          for (var p in products) {
            String pName = (p['name'] ?? "").toString().toLowerCase();
            if (pName.isNotEmpty && items.contains(pName)) {
              salesMap[pName] = (salesMap[pName] ?? 0) + 1;
            }
          }
        }

        // Normalization helper for matching - removes everything except Alphanumeric
        String normalize(String input) {
           return input.toLowerCase()
                .replaceAll(RegExp(r'&[a-z0-9]+;'), '') // removes HTML entities
                .replaceAll(RegExp(r'[^a-z0-9]'), '') 
                .trim();
        }

        List<Map<String, dynamic>> analyzed = [];
        int dormant = 0;

        for (var p in products) {
          String rawName = (p['name'] ?? "").toString();
          String normalizedName = rawName.toLowerCase().trim();
          String superNormalizedName = normalize(rawName);
          final stock = int.tryParse(p['stock'].toString()) ?? 0;
          final sales = salesMap[normalizedName] ?? 0;

          // Quad-Match Engine Execution
          Map<String, dynamic>? match;
          final vendorId = p['id']?.toString() ?? "";
          final vendorProductId = p['product_id']?.toString() ?? "";
          final vendorUrl = (p['url_key'] ?? "").toString().toLowerCase().trim();
          final vendorSku = (p['sku'] ?? "").toString().toLowerCase().trim();
          
          // Tier 1: ID Match (Most solid)
          if (vendorId.isNotEmpty && storefrontIdMap.containsKey(vendorId)) {
            match = storefrontIdMap[vendorId];
          } else if (vendorProductId.isNotEmpty && storefrontIdMap.containsKey(vendorProductId)) {
            match = storefrontIdMap[vendorProductId];
          } 
          // Tier 1.5: URL Key Match (Very solid)
          else if (vendorUrl.isNotEmpty && storefrontUrlMap.containsKey(vendorUrl)) {
            match = storefrontUrlMap[vendorUrl];
          }
          // Tier 1.7: SKU Match (Solid if available)
          else if (vendorSku.isNotEmpty) {
             final skuMatch = allStorefrontData.firstWhereOrNull((sp) => sp.sku?.toLowerCase() == vendorSku);
             if (skuMatch != null) {
               match = skuMatch.toJson();
               match['priceHtmlObject'] = skuMatch.priceHtml;
             }
          }
          // Tier 2: Exact Name Match
          else if (storefrontNameMap.containsKey(normalizedName)) {
            match = storefrontNameMap[normalizedName];
          }
          // Tier 3: Super Normalized Name Match
          else {
            for (var entry in storefrontNameMap.entries) {
              if (normalize(entry.key) == superNormalizedName) {
                match = entry.value;
                break;
              }
            }
          }

          // Tier 4: Fuzzy / Contains Match (Last resort)
          if (match == null) {
            for (var entry in storefrontNameMap.entries) {
              if (normalizedName.length > 3 && (normalizedName.contains(entry.key) || entry.key.contains(normalizedName))) {
                match = entry.value;
                break;
              }
            }
          }

          Map<String, dynamic> augmentedProduct = Map<String, dynamic>.from(p);
          // 🚀 CRITICAL: Preserve the original numeric vendor-side ID
          augmentedProduct['vendor_id'] = p['id']?.toString();
          
          // Save fresh pricing from Vendor API to avoid being overwritten by stale Storefront cache
          final vendorPrice = p['price'];
          final vendorSpecialPrice = p['specialPrice'] ?? p['special_price'];
          final vendorPriceHtml = p['priceHtml'];

          if (match != null) {
             augmentedProduct.addAll(match);
             
             // 🚀 Restore fresh prices from Vendor API
             if (vendorPrice != null) augmentedProduct['price'] = vendorPrice;
             if (vendorSpecialPrice != null) {
                augmentedProduct['specialPrice'] = vendorSpecialPrice;
                augmentedProduct['special_price'] = vendorSpecialPrice;
             }
             if (vendorPriceHtml != null) augmentedProduct['priceHtml'] = vendorPriceHtml;
             
             double pValue = _parsePrice(augmentedProduct);
             debugPrint("✅ Match Success: $rawName -> Price: ₹$pValue");
          } else {
             debugPrint("❌ Match Failed: $rawName (ID: $vendorId, SKU: $vendorSku)");
          }

          // Velocity Score Calculation
          if (stock > 0) {
            double velocity = sales / (stock * 0.1); 
            if (stock > 10 && sales < 3) {
              if (sales == 0) dormant++;
              
              analyzed.add({
                ...augmentedProduct,
                'recent_sales': sales,
                'velocity_score': velocity,
                'is_dormant': sales == 0,
              });
            }
          }
        }

        // Sort by worst performance (Highest Stock, Lowest Sales)
        analyzed.sort((a, b) {
           int stockA = int.tryParse(a['stock'].toString()) ?? 0;
           int stockB = int.tryParse(b['stock'].toString()) ?? 0;
           int salesA = a['recent_sales'] as int;
           int salesB = b['recent_sales'] as int;
           
           if (salesA != salesB) return salesA.compareTo(salesB);
           return stockB.compareTo(stockA);
        });

        if (mounted) {
          setState(() {
            _slowMovingProducts = analyzed;
            _totalDormant = dormant;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Analysis Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF27C16B);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FBF9),
      appBar: AppBar(
        title: const Text(
          "Stock Planning",
          style: TextStyle(color: Color(0xFF27C16B), fontWeight: FontWeight.w800, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF27C16B)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF27C16B)))
          : Column(
              children: [
                _buildSummaryHeader(isDark),
                Expanded(
                  child: _slowMovingProducts.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _slowMovingProducts.length,
                          itemBuilder: (context, index) => _buildAnalysisCard(_slowMovingProducts[index], isDark),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF27C16B),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF27C16B).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Expanded(child: _buildSummaryStat("Low Velocity", "${_slowMovingProducts.length}")),
          Container(width: 1, height: 30, color: Colors.white24),
          Expanded(child: _buildSummaryStat("Dormant Items", "$_totalDormant")),
          Container(width: 1, height: 30, color: Colors.white24),
          Expanded(child: _buildSummaryStat("Potential Offers", "${_slowMovingProducts.length}")),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Future<void> _performApiAction(Map<String, dynamic> product, String action, dynamic value) async {
    final snackBar = ScaffoldMessenger.of(context);
    // Use vendor_id if available, fallback to id (which might be an encoded storefront ID)
    final productId = (product['vendor_id'] ?? product['id']).toString();
    try {
      final field = action == "update_price" ? "price" : "special_price";
      final response = await Dio().post(
        _apiUrl,
        data: {
          "action": action,
          "product_id": productId,
          field: value,
        },
      );

      if (response.data['success'] == true) {
        snackBar.showSnackBar(
          SnackBar(content: Text("${action.replaceAll('_', ' ').toUpperCase()} successful! ✅"), backgroundColor: const Color(0xFF27C16B))
        );
        
        // 🚀 NEW: Trigger Push Notification to All Users
        _triggerOfferNotification(product, value, action == "create_offer");
      } else {
        throw response.data['message'] ?? "Action failed";
      }
    } catch (e) {
      snackBar.showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      _analyzeStockVelocity(); 
    }
  }

  /// Helper to send a broadcast notification trigger to the server
  Future<void> _triggerOfferNotification(Map<String, dynamic> product, dynamic newPrice, bool isSpecialOffer) async {
    try {
      final name = product['name'] ?? "A product";
      final title = isSpecialOffer ? "New Hot Offer! 🔥" : "Price Update Alert! 🏷️";
      final body = isSpecialOffer 
          ? "$name is now at a special price of ₹$newPrice! Grab it now!" 
          : "Fresh pricing for $name: Now only ₹$newPrice!";

      debugPrint("🚀 Broadcasting Notification Trigger: $name...");
      
      await Dio().post(
        _apiUrl,
        data: {
          "action": "send_push_notification",
          "topic": "Bagisto_mobikul", // The default topic all users subscribe to
          "title": title,
          "body": body,
          "product_id": product['id']?.toString(),
          "image": product['image'],
          "click_action": "FLUTTER_NOTIFICATION_CLICK"
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      
      debugPrint("✅ Broadcast Notification Request Sent to Server.");
    } catch (e) {
      debugPrint("⚠️ Push Notification Trigger Failed: $e");
      // We don't show a snackbar for notification failure to avoid confusing the vendor 
      // if the price update itself succeeded.
    }
  }

  /// Robust Price Parser mirror the storefront's logic
  double _parsePrice(dynamic product, {bool isSpecial = false}) {
    if (product == null) return 0.0;
    
    // Convert to map if it's a NewProducts object
    Map<String, dynamic> data = {};
    if (product is NewProducts) {
       data = product.toJson();
    } else if (product is Map) {
       data = Map<String, dynamic>.from(product);
    } else {
       return 0.0;
    }

    // 1. Check priceHtml source (Map or Object)
    var ph = data['priceHtmlObject'] ?? data['priceHtml'] ?? data['price_html'];
    if (ph != null) {
      dynamic val;
      if (ph is PriceHtml) {
        val = isSpecial ? ph.special : (ph.finalPrice ?? ph.regularPrice ?? ph.regular);
      } else if (ph is Map) {
        if (isSpecial) {
          val = ph['special'] ?? ph['finalPrice'] ?? ph['formattedFinalPrice'] ?? ph['final_price'] ?? ph['formated_special_price'] ?? ph['special_price'] ?? ph['formatedSpecialPrice'];
        } else {
          val = ph['regular'] ?? ph['regularPrice'] ?? ph['formattedRegularPrice'] ?? ph['priceWithoutHtml'] ?? ph['regular_price'] ?? ph['formated_regular_price'] ?? ph['formatedRegularPrice'];
        }
      }
      
      double p = _cleanAndParse(val);
      if (p > 0) return p;
    }

    // 2. Check Top-Level Keys (Fallback)
    dynamic topVal;
    if (isSpecial) {
       topVal = data['specialPrice'] ?? data['special_price'] ?? data['special'] ?? data['formatedSpecialPrice'] ?? data['special_price_formated'];
    } else {
       topVal = data['price'] ?? data['regularPrice'] ?? data['regular_price'] ?? data['formatedPrice'] ?? data['price_formated'] ?? data['regularPriceFormated'];
    }
    
    double topP = _cleanAndParse(topVal);
    if (topP > 0) return topP;

    // 3. Recursive Deep Scan
    return _scanMapForPrice(data, isSpecial);
  }

  double _scanMapForPrice(Map<dynamic, dynamic> map, bool isSpecial) {
    double discovered = 0.0;
    map.forEach((key, value) {
      final k = key.toString().toLowerCase();
      // Expanded keyword list
      if (k.contains('price') || k.contains('cost') || k.contains('mrp') || k.contains('amount') || k.contains('value')) {
        // Skip keys that are clearly IDs or unrelated
        if (k.contains('id') || k.contains('family') || k.contains('stock') || k.contains('qty')) return;
        
        // Skip 'special' if we want regular, etc.
        if (isSpecial && !k.contains('special') && !k.contains('offer')) return;
        if (!isSpecial && (k.contains('special') || k.contains('offer'))) return;

        double parsed = _cleanAndParse(value);
        if (parsed > 0 && parsed != discovered) {
          discovered = parsed;
        }
      }
    });
    return discovered;
  }

  double _cleanAndParse(dynamic value) {
    if (value == null) return 0.0;
    String s = value.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(s) ?? 0.0;
  }

  Widget _buildAnalysisCard(Map<String, dynamic> product, bool isDark) {
    final stock = int.tryParse(product['stock'].toString()) ?? 0;
    final sales = product['recent_sales'] as int;
    final isDormant = product['is_dormant'] as bool;
    
    final price = _parsePrice(product);
    final specialPrice = _parsePrice(product, isSpecial: true);
    final hasOffer = specialPrice > 0 && specialPrice < price;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hasOffer ? const Color(0xFF27C16B).withOpacity(0.3) : (isDormant ? Colors.orange.withOpacity(0.3) : Colors.transparent)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                      child: product['image'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(product['image'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined)),
                            )
                          : const Icon(Icons.inventory_2_outlined),
                    ),
                    if (hasOffer)
                      Positioned(
                        top: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: const BoxDecoration(color: Color(0xFF27C16B), borderRadius: BorderRadius.only(topRight: Radius.circular(12), bottomLeft: Radius.circular(8))),
                          child: const Text("SALE", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product['name'] ?? "Unknown Product", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (hasOffer) ...[
                            Text("₹${specialPrice.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF27C16B), fontSize: 16)),
                            const SizedBox(width: 6),
                            Text("₹${price.toStringAsFixed(0)}", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 11)),
                          ] else
                            Text("₹${price.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          
                          const Spacer(),
                          _buildMiniBadge("Stock: $stock", Colors.blueGrey),
                          const SizedBox(width: 6),
                          _buildMiniBadge("Sales: $sales", isDormant ? Colors.redAccent : Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.02) : Colors.grey[50],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    hasOffer ? "Active Offer: Save ₹${(price - specialPrice).toStringAsFixed(0)}" : "Planning Tip: Create a 15% Off Offer", 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: hasOffer ? const Color(0xFF27C16B) : Colors.blueGrey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Row(
                  children: [
                    SizedBox(
                      height: 32,
                      child: TextButton(
                        onPressed: () => _updatePrice(product),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text("Edit Price", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF27C16B))),
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      height: 30,
                      child: ElevatedButton(
                        onPressed: () => _showOfferDialog(product),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDormant ? Colors.orange : (hasOffer ? Colors.blueGrey : const Color(0xFF27C16B)),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                        ),
                        child: Text(hasOffer ? "Edit Offer" : "Create Offer", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.2))),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.auto_graph, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text("Inventory looks healthy!", style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
          Text("All items have good sales velocity.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _updatePrice(Map<String, dynamic> product) {
    final currentPriceValue = _parsePrice(product);
    final controller = TextEditingController(text: currentPriceValue.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Base Price", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(prefixText: "₹ ", labelText: "Regular Price"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final newPrice = controller.text;
              if (newPrice.isNotEmpty) {
                setState(() => product['price'] = newPrice);
                Navigator.pop(context);
                _performApiAction(product, "update_price", newPrice);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showOfferDialog(Map<String, dynamic> product) {
    final currentPrice = _parsePrice(product);
    final currentSpecialPrice = _parsePrice(product, isSpecial: true);
    
    // Default to a 15% discount if no special price exists
    final initialOfferValue = currentSpecialPrice > 0 
        ? currentSpecialPrice.toStringAsFixed(0) 
        : (currentPrice * 0.85).toStringAsFixed(0);
        
    final controller = TextEditingController(text: initialOfferValue);
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final offerPrice = _cleanAndParse(controller.text);
            final discount = currentPrice > 0 ? ((currentPrice - offerPrice) / currentPrice * 100).toStringAsFixed(0) : "0";

            return AlertDialog(
              title: const Text("Create Special Offer", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Current Price: ₹${currentPrice.toStringAsFixed(0)}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      prefixText: "₹ ",
                      labelText: "Offer Price (Special Price)",
                      helperText: "Customers will save $discount%",
                      helperStyle: const TextStyle(color: Color(0xFF27C16B), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    final newSpecial = controller.text;
                    setState(() => product['special_price'] = newSpecial);
                    Navigator.pop(context);
                    _performApiAction(product, "create_offer", newSpecial);
                  },
                  child: const Text("Apply Offer"),
                ),
              ],
            );
          }
        );
      }
    );
  }
}
