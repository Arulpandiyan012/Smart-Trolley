import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Request permissions and get the current position with timeout protection
  static Future<loc.LocationData?> getCurrentPosition() async {
    final location = loc.Location();
    
    try {
      // Check if service is enabled
      bool serviceEnabled = await location.serviceEnabled()
          .timeout(const Duration(seconds: 3));
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService()
            .timeout(const Duration(seconds: 5));
        if (!serviceEnabled) {
          throw Exception('Location services are disabled.');
        }
      }

      // Check permission
      loc.PermissionStatus permission = await location.hasPermission()
          .timeout(const Duration(seconds: 3));
      if (permission == loc.PermissionStatus.denied) {
        permission = await location.requestPermission()
            .timeout(const Duration(seconds: 5));
        if (permission != loc.PermissionStatus.granted) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == loc.PermissionStatus.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get position with timeout
      return await location.getLocation()
          .timeout(const Duration(seconds: 10));
      
    } catch (e) {
      // Catch any errors including Play Services issues
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
