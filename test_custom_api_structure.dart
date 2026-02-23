import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  var url = Uri.parse("https://smarttrolley.in/mobikul-vendor-api.php");
  print("🔵 Testing API: $url");
  
  try {
    var response = await http.post(url, body: {"action": "get_categories"});
    print("🔵 Status Code: ${response.statusCode}");
    
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      print("🔵 Success: ${json['success']}");
      
      if (json['success'] == true) {
        List<dynamic> data = json['data'];
        print("🔵 Root Categories Found: ${data.length}");
        
        for (var cat in data) {
           String name = cat['name'] ?? "Unknown";
           List children = cat['children'] ?? [];
           print("   - Root: $name (Children: ${children.length})");
           
           if (children.isNotEmpty) {
             var firstChild = children[0];
             print("     - Example Child: ${firstChild['name']} (Slug: ${firstChild['slug']})");
           }
        }
      } else {
        print("🔴 API returned success: false");
        print("🔴 Message: ${json['message']}");
      }
    } else {
      print("🔴 HTTP Error");
    }
  } catch (e) {
    print("🔴 Exception: $e");
  }
}
