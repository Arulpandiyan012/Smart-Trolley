import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Request permissions and get the current position
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // You can prompt the user to enable GPS with:
      // await Geolocator.openLocationSettings();
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Location permissions are denied');
    }
    if (permission == LocationPermission.deniedForever) {
      // Open app settings to allow permission
      await Geolocator.openAppSettings();
      throw Exception('Location permissions are permanently denied');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Convert lat/lng to a readable address line
  static Future<String> getAddressFromLatLng(double lat, double lng) async {
    final placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isEmpty) return 'Unknown location';

    final p = placemarks.first;
    final parts = [
      p.name,
      p.subLocality,
      p.locality,
      p.administrativeArea,
      p.postalCode,
    ].where((x) => x != null && x.trim().isNotEmpty).map((e) => e!.trim());

    return parts.join(', ');
  }
}
