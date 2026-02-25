import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  var url = Uri.parse('https://ecom.thesmartedgetech.com/graphql');
  var query = '''
    query allProducts {
      allProducts(input: [{key: "category_id", value: "49"}]) {
        data {
            id
            name
            type
        }
      }
    }
  ''';

  var response = await HttpClient().postUrl(url);
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode({'query': query}));
  
  var resp = await response.close();
  var body = await resp.transform(utf8.decoder).join();
  print('Atta 49: ' + body);
  
  var query2 = '''
    query allProducts {
      allProducts(input: [{key: "category_id", value: "54"}]) {
        data {
            id
            name
            type
        }
      }
    }
  ''';

  var response2 = await HttpClient().postUrl(url);
  response2.headers.contentType = ContentType.json;
  response2.write(jsonEncode({'query': query2}));
  
  var resp2 = await response2.close();
  var body2 = await resp2.transform(utf8.decoder).join();
  print('Millets 54: ' + body2);
  
  exit(0);
}
