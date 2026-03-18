/*
 *   Webkul Software.
 *   @package Mobikul Application Code.
 *   @Category Mobikul
 *   @author Webkul <support@webkul.com>
 *   @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 *   @license https://store.webkul.com/license.html
 *   @link https://store.webkul.com/license.html
 */

// ignore_for_file: file_names, avoid_print



import 'package:bagisto_app_demo/screens/add_review/utils/index.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bagisto_app_demo/utils/shared_preference_helper.dart';



abstract class AddReviewRepository{
  Future<AddReviewModel> callAddReviewApi(String name,String title,int rating,String comment,int productId, List<Map<String, String>> attachments, {String? reviewId});
}




class AddReviewRepositoryImp implements AddReviewRepository {
  @override
  Future<AddReviewModel> callAddReviewApi(String name, String title, int rating, String comment, int productId, List<Map<String, String>> attachments, {String? reviewId}) async {
    try {
      // 🟢 CUSTOM API: Submit to Live Server (Auto-Approved)
      // URL: https://ecom.thesmartedgetech.com/mobikul-review-api.php
      
      final Uri url = Uri.parse("https://ecom.thesmartedgetech.com/mobikul-review-api.php");
      
      final Map<String, dynamic> body = {
        'action': reviewId != null ? 'update' : 'submit',
        'customer_id': appStoragePref.getCustomerId().toString(),
        'product_id': productId.toString(),
        'name': name.isNotEmpty ? name : (appStoragePref.getCustomerName().isNotEmpty ? appStoragePref.getCustomerName() : "Guest"),
        'title': title,
        'rating': rating.toString(),
        'comment': comment,
      };

      if (reviewId != null) {
        body['review_id'] = reviewId;
      }

      print("Submitting Review to Custom API: $body");

      final response = await http.post(
        url,
        body: body, // http.post handles map as form-urlencoded by default
      );

      print("Custom Review API Response: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
             return AddReviewModel(
               success: true, 
               message: jsonResponse['message'] ?? "Review submitted successfully"
             );
        }
      }
      
      return AddReviewModel(success: false, message: "Failed to submit review via Custom API");

    } catch (error, stacktrace) {
      print("Error --> $error");
      print("StackTrace --> $stacktrace");
      return AddReviewModel(success: false, message: error.toString());
    }
  }
}