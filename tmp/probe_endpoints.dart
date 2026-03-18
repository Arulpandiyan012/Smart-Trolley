import 'package:http/http.dart' as http;
import 'dart:io';

void main() async {
  final base = "https://ecom.thesmartedgetech.com";
  final endpoints = [
    "/mobikul-delete-review.php",
    "/mobikul-remove-review.php",
    "/mobikul-delete-review-api.php",
    "/mobikul-remove-review-api.php"
  ];

  for (var endpoint in endpoints) {
    print("Probing $endpoint...");
    try {
      final response = await http.get(Uri.parse("$base$endpoint"));
      print("  Status: ${response.statusCode}");
      if (response.statusCode != 404) {
        print("  Body Snippet: ${response.body.isNotEmpty ? response.body.substring(0, response.body.length > 50 ? 50 : response.body.length) : 'empty'}");
      }
    } catch (e) {
      print("  Error: $e");
    }
  }
}
