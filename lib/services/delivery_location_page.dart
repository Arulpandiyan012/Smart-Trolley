import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';

class DeliveryLocationPage extends StatefulWidget {
  const DeliveryLocationPage({Key? key}) : super(key: key);

  @override
  State<DeliveryLocationPage> createState() => _DeliveryLocationPageState();
}

class _DeliveryLocationPageState extends State<DeliveryLocationPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  GoogleMapController? _mapController;
  LatLng? _currentLatLng;
  LatLng? _pinLatLng;

  bool _loading = true;
  bool _mapVisible = false; // shown after dropdown selection
  String? _error;
  String? _address; // reverse-geocoded text for the pin
// 🔹 Add this
  late final FlutterGooglePlacesSdk _places;

  @override
  void initState() {
    super.initState();

    // 🔹 Initialize the Places SDK with your API key
    _places = FlutterGooglePlacesSdk("YOUR_GOOGLE_PLACES_API_KEY");

    _initCurrentLocation();
  String? _dropdownValue; // controls the dropdown
  final List<String> _dropdownItems = const [
    'Open map',
  ];

  @override
  void initState() {
    super.initState();
    _initCurrentLocation();
  }

  Future<void> _initCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Location services are disabled';
          _loading = false;
        });
        return;
      }

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

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final here = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentLatLng = here;
        _pinLatLng = here;
        _loading = false;
      });

      // Preload address for current location
      _reverseGeocode(here);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _reverseGeocode(LatLng point) async {
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
        ].where((e) => (e ?? '').trim().isNotEmpty).map((e) => e!.trim());
        final text = parts.isNotEmpty ? parts.join(', ') : 'Unknown location';
        setState(() => _address = text);
      }
    } catch (_) {
      // ignore geocode errors quietly
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_currentLatLng == null) return;
    Navigator.pop(context, {
      'lat': _currentLatLng!.latitude,
      'lng': _currentLatLng!.longitude,
      'address': _address ?? 'Current location',
    });
  }

  Future<void> _confirmPin() async {
    if (_pinLatLng == null) return;
    // make sure we have the latest address for the pin
    await _reverseGeocode(_pinLatLng!);
    Navigator.pop(context, {
      'lat': _pinLatLng!.latitude,
      'lng': _pinLatLng!.longitude,
      'address': _address ?? 'Selected location',
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_pinLatLng != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_pinLatLng!, 16),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select location'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off, size: 36, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initCurrentLocation,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Bold title
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Select a delivery location',
                        style: titleStyle,
                      ),
                    ),

                    // Search field (free text; wire to Places later if needed)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search for an address or area',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                        ),
                        onSubmitted: (value) async {
                          // Optionally: you can geocode text here (forward geocoding)
                          // And move the map to that position if found.
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Dropdown that reveals the map when selected
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonFormField<String>(
                        value: _dropdownValue,
                        items: _dropdownItems
                            .map((it) => DropdownMenuItem(
                                  value: it,
                                  child: Text(it),
                                ))
                            .toList(),
                        decoration: InputDecoration(
                          labelText: 'Actions',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _dropdownValue = val;
                            // When user selects "Open map", show the map area
                            _mapVisible = val == 'Open map';
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Map area (revealed after dropdown)
                    if (_mapVisible) _buildMapSection(),

                    // Footer buttons (always visible)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _useCurrentLocation,
                              icon: const Icon(Icons.my_location),
                              label: const Text('Use current location'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _confirmPin,
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

  Widget _buildMapSection() {
    if (_pinLatLng == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Locating map...'),
      );
    }

    return Expanded(
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
            onTap: (pos) {
              setState(() => _pinLatLng = pos);
              _reverseGeocode(pos);
            },
          ),

          // Address chip overlay
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
                child: Text(
                  _address ?? 'Move the pin to refine location…',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
