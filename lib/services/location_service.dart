import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Request permissions and get the current position with timeout protection
  static Future<Position> getCurrentPosition() async {
    try {
      // Add timeout to prevent hanging
      final serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 3));
      
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 3));
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 5));
      }
      
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get position with timeout
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));
      
    } catch (e) {
      // Catch any errors including DeadSystemException
      throw Exception('Failed to get location: ${e.toString()}');
    }
  }

  /// Convert lat/lng to a readable address line with error handling
  static Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng)
          .timeout(const Duration(seconds: 5));
      
      if (placemarks.isEmpty) return 'Unknown location';

      final p = placemarks.first;
      final parts = [
        p.name,
        p.subLocality,
        p.locality,
        p.administrativeArea,
        p.postalCode,
      ].where((x) => x != null && x!.trim().isNotEmpty).map((e) => e!.trim());

      return parts.join(', ');
    } catch (e) {
      return 'Unable to get address';
    }
  }
}
