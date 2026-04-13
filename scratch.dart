import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void main() async {
  var url = Uri.parse("https://ecom.thesmartedgetech.com/mobikul-vendor-api.php");
  try {
    var response = await http.post(
      url, 
      body: jsonEncode({"action": "get_deliveries"}), 
      headers: {"Content-Type": "application/json"}
    );
    
    var decoded = jsonDecode(response.body);
    var encoder = JsonEncoder.withIndent('  ');
    var formatted = encoder.convert(decoded);
    
    File('scratch.json').writeAsStringSync(formatted);
    print("Wrote to scratch.json");
  } catch (e) {
    print(e);
  }
}
