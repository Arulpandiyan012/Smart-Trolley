import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
// adjust if your service path differs:
import 'package:bagisto_app_demo/services/location_service.dart';
import 'package:bagisto_app_demo/screens/home_page/widget/delivery_location_page.dart';


class LocationBanner extends StatefulWidget {
  const LocationBanner({Key? key}) : super(key: key);

  @override
  State<LocationBanner> createState() => _LocationBannerState();
}

class _LocationBannerState extends State<LocationBanner> {
  String? _address;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAddress();
  }

  Future<void> _fetchAddress() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1) Ensure location services enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Location services are disabled';
          _loading = false;
        });
        return;
      }

      // 2) Check/request permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        setState(() {
          _error = 'Location permission denied';
          _loading = false;
        });
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permission permanently denied';
          _loading = false;
        });
        return;
      }

      // 3) Get position via your service
      final pos = await LocationService.getCurrentPosition();

      // 4) Reverse geocode (or call a method from your service if you have one)
      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);

      String addr = 'Unknown location';
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          p.name,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.postalCode,
        ]
            .where((e) => (e ?? '').trim().isNotEmpty)
            .map((e) => e!.trim())
            .toList();
        if (parts.isNotEmpty) addr = parts.join(', ');
      }

      if (!mounted) return;
      setState(() {
        _address = addr;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

@override
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: () async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DeliveryLocationPage()),
      );
      if (result != null && result is Map) {
        setState(() {
          _address = result['address'] as String?;
        });
        // TODO: Save to profile or global state if needed
      }
    },
    child: Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.place, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: _loading
                ? const Text('Detecting your location...')
                : (_error != null
                    ? Text(
                        'Location unavailable: $_error',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.red),
                      )
                    : Text(
                        _address ?? 'Tap to select delivery location',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      )),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_right), // arrow to indicate navigation
        ],
      ),
    ),
  );
}

}
