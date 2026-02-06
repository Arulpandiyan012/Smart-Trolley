/*
 *   Webkul Software.
 *   @package Mobikul Application Code.
 *   @Category Mobikul
 *   @author Webkul <support@webkul.com>
 *   @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 *   @license https://store.webkul.com/license.html
 *   @link https://store.webkul.com/license.html
 */

import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../utils/app_global_data.dart';
import '../utils/server_configuration.dart';
import '../utils/shared_preference_helper.dart';

String appDocPath = "";

/*
 * GraphQlApiCalling class is used to call graphql api and return graphql client object to call api
 */
class GraphQlApiCalling {
  final loggerLink = LoggerLink();
  final authLink = AuthLink(
    getToken: () async {
      String? token = appStoragePref.getCustomerToken();
      debugPrint("🟢 AuthLink Token: ${token.isNotEmpty ? token.substring(0, 5) + "..." : "EMPTY"}");
      if (token == "fake_token_bypass") return null; // 🟢 SANITIZE
      return (token != null && token.isNotEmpty) ? "Bearer $token" : null;
    },
  );

  GraphQLClient clientToQuery() {
    String? token = appStoragePref.getCustomerToken();
    String? cookie = appStoragePref.getCookieGet();
    
    Map<String, String> headers = {
      "x-currency": GlobalData.currencyCode ?? "INR",
      "x-locale": GlobalData.locale ?? "en"
    };

    if (cookie.isNotEmpty) {
      headers["Cookie"] = cookie;
    }

    // 🟢 DEBUGGING: Log if token is missing (Neutral for guest)
    if (token.isEmpty) {
      debugPrint("ℹ️ Guest Access: GraphQL call initialization");
    } else {
      headers['token'] = token; 
    }

    final httpLink = HttpLink(baseUrl, defaultHeaders: headers);

    debugPrint("🛡️ OUTGOING HEADERS: { ... }"); // 🟢 Redacted for log cleanliness
    debugPrint("🛡️ BASE URL: $baseUrl");

    return GraphQLClient(
      cache: GraphQLCache(store: HiveStore()),
      queryRequestTimeout: const Duration(seconds: 40),
      link: loggerLink.concat(authLink.concat(httpLink)),
    );
  }
}

/// LoggerLink class is used to log the graphql api request and response
class LoggerLink extends Link {
  @override
  Stream<Response> request(Request request, [NextLink? forward]) {
    String? opName = request.operation.operationName;
    
    // 🟢 Attempt to extract name from document if explicit name is missing
    if (opName == null) {
      final doc = request.operation.document;
      // Very basic extraction of 'query Name {' or 'mutation Name {'
      final content = doc.toString();
      final match = RegExp(r'(query|mutation)\s+([a-zA-Z0-9_]+)', multiLine: true).firstMatch(content);
      if (match != null && match.groupCount >= 2) {
        opName = match.group(2);
      }
    }

    debugPrint("🚀 GRAPHQL OPERATION: ${opName ?? "UNNAMED"}");
    return forward!(request);
  }
}
