import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart' as sdk;

class DeliveryLocationPage extends StatefulWidget {
  const DeliveryLocationPage({Key? key}) : super(key: key);

  @override
  State<DeliveryLocationPage> createState() => _DeliveryLocationPageState();
}

class _DeliveryLocationPageState extends State<DeliveryLocationPage> {
  // --- Controllers & State ---
  final TextEditingController _searchCtrl = TextEditingController();
  GoogleMapController? _mapController;
  
  // Locations
  LatLng? _currentLatLng;
  LatLng? _pinLatLng;

  // UI State
  bool _loading = true;
  bool _mapVisible = false; 
  String? _error;
  String? _address; 
  
  // Dropdown
  String? _dropdownValue;
  final List<String> _dropdownItems = const ['Open map'];

  // --- Google Places SDK ---
  late final sdk.FlutterGooglePlacesSdk _places;
  List<sdk.AutocompletePrediction> _predictions = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // 1. Initialize SDK (Replace with your actual API Key)
    _places = sdk.FlutterGooglePlacesSdk("YOUR_GOOGLE_PLACES_API_KEY");

    // 2. Initialize Location
    _initCurrentLocation();

    // 3. Listen to search input
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // --- Location Logic ---

  Future<void> _initCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled';

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) throw 'Location permission denied';

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final here = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentLatLng = here;
        _pinLatLng = here;
        _loading = false;
      });

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
          p.street,
          p.subLocality,
          p.locality,
          p.postalCode,
        ].where((e) => (e ?? '').trim().isNotEmpty).map((e) => e!.trim());
        
        setState(() => _address = parts.join(', '));
      }
    } catch (_) {}
  }

  // --- Places Search Logic ---

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final query = _searchCtrl.text;
      if (query.isEmpty) {
        setState(() => _predictions = []);
        return;
      }

      final result = await _places.findAutocompletePredictions(query);
      setState(() {
        _predictions = result.predictions;
      });
    });
  }

  Future<void> _onPredictionSelected(sdk.AutocompletePrediction prediction) async {
    FocusScope.of(context).unfocus(); // Close keyboard
    
    setState(() {
      _predictions = [];
      _searchCtrl.text = prediction.primaryText;
      _address = prediction.fullText;
    });

    final details = await _places.fetchPlace(
      prediction.placeId, 
      fields: [sdk.PlaceField.Location],
    );

    final latLng = details.place?.latLng;
    
    if (latLng != null) {
      final newPos = LatLng(latLng.lat, latLng.lng);
      
      setState(() {
        _pinLatLng = newPos;
        _mapVisible = true;
        _dropdownValue = 'Open map';
      });
      
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newPos, 16));
    }
  }

  // --- Actions ---

  void _useCurrentLocation() {
    if (_currentLatLng == null) return;
    Navigator.pop(context, {
      'lat': _currentLatLng!.latitude,
      'lng': _currentLatLng!.longitude,
      'address': _address ?? 'Current location',
    });
  }

  void _confirmPin() {
    if (_pinLatLng == null) return;
    Navigator.pop(context, {
      'lat': _pinLatLng!.latitude,
      'lng': _pinLatLng!.longitude,
      'address': _address ?? 'Selected location',
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  // --- UI Construction ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, 
      appBar: AppBar(title: const Text('Select location')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Select a delivery location',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            
                            // SEARCH BAR
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: TextField(
                                controller: _searchCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Search for an address...',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: _searchCtrl.text.isNotEmpty 
                                    ? IconButton(
                                        icon: const Icon(Icons.clear), 
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          setState(() => _predictions = []);
                                        },
                                      )
                                    : null,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  isDense: true,
                                ),
                              ),
                            ),

                            // PREDICTIONS LIST
                            if (_predictions.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _predictions.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final p = _predictions[index];
                                    return ListTile(
                                      title: Text(p.primaryText, style: const TextStyle(fontWeight: FontWeight.w500)),
                                      subtitle: Text(p.secondaryText ?? ''),
                                      onTap: () => _onPredictionSelected(p),
                                    );
                                  },
                                ),
                              ),

                            const SizedBox(height: 12),

                            // DROPDOWN
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: DropdownButtonFormField<String>(
                                value: _dropdownValue,
                                items: _dropdownItems.map((it) => 
                                  DropdownMenuItem(value: it, child: Text(it))
                                ).toList(),
                                decoration: InputDecoration(
                                  labelText: 'Actions',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _dropdownValue = val;
                                    _mapVisible = val == 'Open map';
                                  });
                                },
                              ),
                            ),

                            const SizedBox(height: 12),

                            // MAP SECTION
                            if (_mapVisible) 
                              SizedBox(
                                height: 400, 
                                child: _buildMapSection(),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // FOOTER BUTTONS
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _useCurrentLocation,
                              icon: const Icon(Icons.my_location),
                              label: const Text('Current Loc'),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _confirmPin,
                              icon: const Icon(Icons.check),
                              label: const Text('Confirm'),
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
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
    if (_pinLatLng == null) return const Center(child: Text("Loading map..."));
    
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _pinLatLng!, zoom: 16),
          onMapCreated: _onMapCreated,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          markers: {
            Marker(
              markerId: const MarkerId('pin'),
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
        if (_address != null)
          Positioned(
            top: 10, left: 10, right: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(8), 
                boxShadow: const [BoxShadow(blurRadius: 5, color: Colors.black26)]
              ),
              child: Text(_address!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 10),
          Text(_error!),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _initCurrentLocation, child: const Text("Retry"))
        ],
      ),
    );
  }
}