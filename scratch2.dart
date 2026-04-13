import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

Future<void> tryAction(String action) async {
  var url = Uri.parse("https://ecom.thesmartedgetech.com/mobikul-vendor-api.php");
  var response = await http.post(
    url, 
    body: jsonEncode({"action": action, "order_id": 181, "id": 181}), 
    headers: {"Content-Type": "application/json"}
  );
  print("$action: ${response.body}");
}

void main() async {
  await tryAction("get_order");
  await tryAction("view_order");
  await tryAction("view_delivery");
  await tryAction("delivery_details");
  await tryAction("get_delivery");
}
