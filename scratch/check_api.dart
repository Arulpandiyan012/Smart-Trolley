import 'package:dio/dio.dart';
import 'dart:convert';

void main() async {
  final dio = Dio();
  const graphqlUrl = "https://ecom.thesmartedgetech.com/graphql";
  const vendorUrl = "https://ecom.thesmartedgetech.com/mobikul-vendor-api.php";

  try {
    // 1. Fetch Storefront Count
    print("--- Checking Storefront Product Count ---");
    final countQuery = {
      "query": """
        query {
          allProducts(limit: 1) {
            paginatorInfo {
              total
              count
            }
          }
        }
      """
    };
    final countResp = await dio.post(graphqlUrl, data: countQuery);
    final totalStorefront = countResp.data['data']['allProducts']['paginatorInfo']['total'];
    print("Total Products in Storefront: $totalStorefront");

    // 2. Fetch Sample Storefront Products (First 100)
    print("\n--- Fetching Sample Storefront Products ---");
    final productsQuery = {
      "query": """
        query {
          allProducts(limit: 100) {
            data {
              id
              sku
              name
              urlKey
              priceHtml {
                finalPrice
                formattedFinalPrice
                regularPrice
                formattedRegularPrice
              }
            }
          }
        }
      """
    };
    final prodResp = await dio.post(graphqlUrl, data: productsQuery);
    final storefrontProds = prodResp.data['data']['allProducts']['data'] as List;
    
    print("Found ${storefrontProds.length} storefront items sample.");
    if (storefrontProds.isNotEmpty) {
       print("Sample Storefront Item [0]: ${jsonEncode(storefrontProds[0])}");
    }

    // 3. Check specific problematic items
    final targetNames = [
      "Priya Mango Avakaya Pickle With Garlic,500G",
      "Bhoomi Farms Organic Chilli Green"
    ];

    print("\n--- Searching for problematic items in Storefront ---");
    for (var name in targetNames) {
      final searchQuery = {
        "query": """
          query(\$name: String) {
            allProducts(name: \$name, limit: 10) {
              data {
                id
                name
                sku
                priceHtml {
                  finalPrice
                  formattedFinalPrice
                }
              }
            }
          }
        """,
        "variables": {"name": name}
      };
      
      final searchResp = await dio.post(graphqlUrl, data: searchQuery);
      final results = searchResp.data['data']['allProducts']['data'] as List;
      print("Search for '$name' returned ${results.length} items.");
      for (var r in results) {
        print("  Match: ${jsonEncode(r)}");
      }
    }

    // 4. Check Vendor API
    print("\n--- Checking Vendor API Products ---");
    final vendorResp = await dio.post(vendorUrl, data: {"action": "get_vendor_products"});
    final vendorData = vendorResp.data['data'] as List;
    print("Total Vendor Products: ${vendorData.length}");
    
    // Find sample problematic in vendor
    final sampleVendor = vendorData.firstWhere((p) => (p['name'] ?? "").toString().contains("Priya"), orElse: () => null);
    if (sampleVendor != null) {
      print("Sample problematic Vendor Item: ${jsonEncode(sampleVendor)}");
    }

  } catch (e) {
    print("Error during debug: $e");
  }
}
