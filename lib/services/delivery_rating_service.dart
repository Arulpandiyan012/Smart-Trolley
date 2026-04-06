import 'package:dio/dio.dart';

class DeliveryRatingService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://ecom.thesmartedgetech.com/delivery-api.php';

  Future<bool> submitRating({
    required int orderId,
    required double rating,
    String? comment,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl?action=rate_delivery',
        data: {
          'order_id': orderId,
          'rating': rating.toInt(),
          'comment': comment ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error submitting delivery rating: $e');
      return false;
    }
  }

  Future<bool> checkRatingStatus(int orderId) async {
    try {
      final response = await _dio.get('$_baseUrl?action=check_rating&order_id=$orderId');
      if (response.statusCode == 200) {
        return response.data['is_rated'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking rating status: $e');
      return false;
    }
  }
}
