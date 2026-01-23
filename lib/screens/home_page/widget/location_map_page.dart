import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'
    show GoogleMap, GoogleMapController, CameraPosition, Marker, MarkerId, LatLng, CameraUpdate, InfoWindow;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationMapPage extends StatefulWidget {
  const LocationMapPage({
    super.key,
    required this.initialLat,
    required this.initialLng,
    this.initialLabel,
  });

  final double initialLat;
  final double initialLng;
  final String? initialLabel;

  @override
  State<LocationMapPage> createState() => _LocationMapPageState();
}

class _LocationMapPageState extends State<LocationMapPage> {
  GoogleMapController? _mapController;
  LatLng? _pinLatLng;
  String? _address;
  bool _loadingAddress = false;

  @override
  void initState() {
    super.initState();
    _pinLatLng = LatLng(widget.initialLat, widget.initialLng);
    _reverseGeocode(_pinLatLng!);
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() => _loadingAddress = true);
    try {
      final marks = await placemarkFromCoordinates(point.latitude, point.longitude);
      if (marks.isNotEmpty) {
        final p = marks.first;
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
        final text = parts.isNotEmpty ? parts.join(', ') : (widget.initialLabel ?? 'Selected location');
        if (!mounted) return;
        setState(() => _address = text);
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_pinLatLng != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_pinLatLng!, 16));
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission not granted')),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final here = LatLng(pos.latitude, pos.longitude);
      setState(() => _pinLatLng = here);
      await _reverseGeocode(here);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(here, 16));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _confirmSelection() async {
    if (_pinLatLng == null) return;
    // ensure latest address
    await _reverseGeocode(_pinLatLng!);
    Navigator.pop(context, {
      'lat': _pinLatLng!.latitude,
      'lng': _pinLatLng!.longitude,
      'address': _address ?? 'Selected location',
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.initialLabel ?? 'Selected pin';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          // Map
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(target: _pinLatLng!, zoom: 16),
                  onMapCreated: _onMapCreated,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  markers: {
                    Marker(
                      markerId: const MarkerId('pin'),
                      position: _pinLatLng!,
                      draggable: true,
                      onDragEnd: (newPos) {
                        setState(() => _pinLatLng = newPos);
                        _reverseGeocode(newPos);
                      },
                      infoWindow: InfoWindow(
                        title: 'Delivery here?',
                        snippet: _address ?? '',
                      ),
                    ),
                  },
                  onTap: (p) {
                    setState(() => _pinLatLng = p);
                    _reverseGeocode(p);
                  },
                ),

                // Address chip
                Positioned(
                  left: 16,
                  right: 16,
                  top: 12,
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.place_outlined),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _loadingAddress
                                  ? 'Finding address…'
                                  : (_address ?? 'Move the pin to refine location…'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Footer actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _useCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Use my current location'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _confirmSelection,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Confirm this location'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
