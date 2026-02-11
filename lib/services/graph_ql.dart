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
      String token = appStoragePref.getCustomerToken().trim();
      bool isLoggedIn = appStoragePref.getCustomerLoggedIn();
      if (token.isEmpty) {
        print("⚠️ AuthLink: Token is EMPTY (Storage Login State: $isLoggedIn)");
        return null;
      }
      print("🔑 AuthLink: Using token ${token.length > 5 ? token.substring(0, 5) : token}... (Length: ${token.length})");
      return "Bearer $token";
    },
  );

  GraphQLClient clientToQuery() {
    String? token = appStoragePref.getCustomerToken();
    String? cookie = appStoragePref.getCookieGet();
    
    Map<String, String> headers = {
      "x-currency": GlobalData.currencyCode ?? "INR",
      "x-locale": GlobalData.locale ?? "en",
      "X-Requested-With": "XMLHttpRequest" // 🟢 Fix for 'Unauthenticated' Guard
    };

    if (cookie.isNotEmpty) {
      headers["Cookie"] = cookie;
    }

    // 🟢 AUTH SYNC: Multiple headers to satisfy different server guards
    if (token.isEmpty) {
      print("ℹ️ Guest Access: GraphQL call initialization");
    } else {
      String cleanToken = token.trim();
      headers['token'] = cleanToken; 
      headers['bagisto-token'] = cleanToken;
      headers['x-bagisto-token'] = cleanToken;
      headers['Authorization'] = "Bearer $cleanToken"; 
      
      // Some server wrappers require token in cookie
      String currentCookie = headers['Cookie'] ?? "";
      if (!currentCookie.contains("customerToken=")) {
        headers['Cookie'] = "$currentCookie${currentCookie.isEmpty ? "" : "; "}customerToken=$cleanToken";
      }
    }

    final httpLink = HttpLink(baseUrl, defaultHeaders: headers);

    print("🛡️ GRAPHQL HEADERS: ${headers.keys.toList()}");
    print("🛡️ BASE URL: $baseUrl");

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
    if (opName != null) {
      print("🚀 GRAPHQL OPERATION: $opName");
    }
    return forward!(request);
  }
}
