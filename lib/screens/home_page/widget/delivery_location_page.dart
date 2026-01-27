import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'address_details_sheet.dart';

class DeliveryLocationPage extends StatefulWidget {
  const DeliveryLocationPage({Key? key}) : super(key: key);

  @override
  State<DeliveryLocationPage> createState() => _DeliveryLocationPageState();
}

class _DeliveryLocationPageState extends State<DeliveryLocationPage> {
  // UI
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // Google Maps
  gmap.GoogleMapController? _mapController;
  gmap.LatLng? _currentLatLng;
  gmap.LatLng? _pinLatLng;
  
  // 🟢 1. ADD THIS VARIABLE: To store the full details (Pincode, City, State)
  Placemark? _currentPlacemark;

  // Search Results
  List<dynamic> _predictions = [];
  Timer? _debounce;

  // State
  bool _loading = true;
  bool _mapVisible = false;
  String? _error;
  String? _address;

  @override
  void initState() {
    super.initState();
    _initCurrentLocation();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController?.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ---------- Permissions + Current Location ----------
  Future<void> _initCurrentLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() { _error = 'Location services are disabled'; _loading = false; });
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() { _error = 'Location permission denied'; _loading = false; });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final here = gmap.LatLng(pos.latitude, pos.longitude);

      setState(() {
        _currentLatLng = here;
        _pinLatLng = here;
        _loading = false;
      });

      _reverseGeocode(here);
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ---------- Reverse Geocode (Extracts Pincode, City, State) ----------
  Future<void> _reverseGeocode(gmap.LatLng point) async {
    try {
      final marks = await placemarkFromCoordinates(point.latitude, point.longitude);
      if (marks.isNotEmpty) {
        final p = marks.first;
        
        // 🟢 2. STORE PLACEMARK HERE
        // This saves the detailed info (Pincode, City, State) for later use
        _currentPlacemark = p;

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
    } catch (_) {/* ignore */}
  }

  // ---------- Search Logic (OpenStreetMap) ----------
  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final q = _searchCtrl.text.trim();
      if (q.isEmpty) {
        if (!mounted) return;
        setState(() => _predictions = []);
        return;
      }
      try {
        final url = Uri.parse("https://nominatim.openstreetmap.org/search?q=$q&format=json&polygon_geojson=1&addressdetails=1");
        final response = await http.get(url, headers: {"User-Agent": "BagistoAppDemo/1.0"});
        if (response.statusCode == 200) {
           final List data = jsonDecode(response.body);
           if (!mounted) return;
           setState(() => _predictions = data);
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _predictions = []);
      }
    });
  }

  // ---------- Return Data: Use Current Location ----------
  Future<void> _useCurrentLocation() async {
    if (_currentLatLng == null) return;
    
    // Ensure we have the placemark details
    if (_currentPlacemark == null) await _reverseGeocode(_currentLatLng!);

    _returnLocationData(_currentLatLng!);
  }

  // ---------- Return Data: Confirm Pin ----------
  Future<void> _confirmPin() async {
    if (_pinLatLng == null) return;
    
    // Ensure we have the placemark details for the PIN position
    await _reverseGeocode(_pinLatLng!);
    
    _returnLocationData(_pinLatLng!);
  }

  // 🟢 3. HELPER: Sends Data Back to Previous Screen
  // This is where the magic happens. We send the broken-down fields back.
  void _returnLocationData(gmap.LatLng latLng) {
    Navigator.pop(context, {
      'lat': latLng.latitude,
      'lng': latLng.longitude,
      'address': _address ?? 'Selected location',
      
      // 🟢 SEND BROKEN DOWN DETAILS
      'pincode': _currentPlacemark?.postalCode ?? "",
      'city': _currentPlacemark?.locality ?? _currentPlacemark?.subLocality ?? "",
      'state': _currentPlacemark?.administrativeArea ?? "",
      'country': _currentPlacemark?.isoCountryCode ?? "IN",
    });
  }

  void _onMapCreated(gmap.GoogleMapController controller) {
    _mapController = controller;
    if (_pinLatLng != null) {
      _mapController!.animateCamera(gmap.CameraUpdate.newLatLngZoom(_pinLatLng!, 16));
    }
  }

  // ---------- Build UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select location')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : Stack(
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 80),
                        if (_mapVisible) _buildMapSection(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onPressed: _useCurrentLocation,
                                  icon: const Icon(Icons.my_location),
                                  label: const Text('Use Current Location'),
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
                                  onPressed: _confirmPin,
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Confirm Location'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 0, left: 0, right: 0,
                      child: Container(
                        color: Colors.white, 
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          children: [
                            TextField(
                              focusNode: _searchFocus,
                              controller: _searchCtrl,
                              decoration: InputDecoration(
                                hintText: 'Search for an address or area',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            if (_predictions.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                constraints: const BoxConstraints(maxHeight: 250),
                                child: Material(
                                  elevation: 4,
                                  borderRadius: BorderRadius.circular(12),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    itemCount: _predictions.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (context, i) {
                                      final p = _predictions[i];
                                      return ListTile(
                                        title: Text(p['display_name'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                                        leading: const Icon(Icons.location_on_outlined, size: 20),
                                        onTap: () => _onSelectOSMPrediction(p),
                                      );
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, size: 36, color: Colors.red),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _initCurrentLocation, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    if (_pinLatLng == null) return const Padding(padding: EdgeInsets.all(16.0), child: Text('Locating map...'));

    return Expanded(
      child: Stack(
        children: [
          gmap.GoogleMap(
            initialCameraPosition: gmap.CameraPosition(target: _pinLatLng!, zoom: 16),
            onMapCreated: _onMapCreated,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            markers: {
              gmap.Marker(
                markerId: const gmap.MarkerId('pin'),
                position: _pinLatLng!,
                draggable: true,
                onDragEnd: (newPos) {
                  setState(() => _pinLatLng = newPos);
                  _reverseGeocode(newPos);
                },
              ),
            },
            onTap: (pos) {
              setState(() => _pinLatLng = pos);
              _reverseGeocode(pos);
            },
          ),
          Positioned(
            left: 16, right: 16, top: 12,
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                     const Icon(Icons.location_on, color: Colors.orange),
                     const SizedBox(width: 8),
                     Expanded(child: Text(
                      _address ?? 'Move the pin to refine location...',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    )),
                  ],
                ),
              ),
            ),
          ),
          // "Add More Details" Button (Updated to pass details)
          if (_pinLatLng != null) 
            Positioned(
              bottom: 20, left: 16, right: 16,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.grey),
                ),
                onPressed: () {
                   showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => FractionallySizedBox(
                      heightFactor: 0.8,
                      child: AddressDetailsSheet(
                        initialArea: _address, 
                        
                        // 🟢 4. PASS DETAILS IF USER OPENS FORM DIRECTLY
                        initialPincode: _currentPlacemark?.postalCode,
                        initialCity: _currentPlacemark?.locality ?? _currentPlacemark?.subLocality,
                        initialState: _currentPlacemark?.administrativeArea,

                        onChangeLocation: () {
                          setState(() => _mapVisible = true);
                        },
                      ),
                    ),
                  );
                },
                child: const Text("Add More Details (House No, etc.)"),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onSelectOSMPrediction(dynamic p) async {
    try {
      setState(() => _predictions = []); 
      final double lat = double.parse(p['lat']);
      final double lon = double.parse(p['lon']);
      final latLng = gmap.LatLng(lat, lon);
      final displayName = p['display_name'];

      setState(() {
        _pinLatLng = latLng;
        _mapVisible = true;
        _searchCtrl.text = displayName;
        _address = displayName;
      });

      _searchFocus.unfocus();
      _mapController?.animateCamera(gmap.CameraUpdate.newLatLngZoom(latLng, 16));
      
      // 🟢 5. REVERSE GEOCODE TO GET PINCODE/CITY FOR THE SEARCH RESULT
      // (The search result itself is just text, so we ask Google "What are the details for this lat/lng?")
      await _reverseGeocode(latLng);

    } catch (_) {}
  }
}