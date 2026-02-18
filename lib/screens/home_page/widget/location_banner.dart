import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
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
      final location = loc.Location();

      // 1) Ensure location services enabled
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          setState(() {
            _error = 'Location services are disabled';
            _loading = false;
          });
          return;
        }
      }

      // 2) Check/request permission
      loc.PermissionStatus permission = await location.hasPermission();
      if (permission == loc.PermissionStatus.denied) {
        permission = await location.requestPermission();
      }
      if (permission != loc.PermissionStatus.granted) {
        setState(() {
          _error = 'Location permission not granted';
          _loading = false;
        });
        return;
      }

      // 3) Get position via your service
      final pos = await LocationService.getCurrentPosition();
      
      if (pos == null || pos.latitude == null || pos.longitude == null) {
        throw Exception('Unable to determine location');
      }

      // 4) Reverse geocode
      final placemarks =
          await placemarkFromCoordinates(pos.latitude!, pos.longitude!);

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
