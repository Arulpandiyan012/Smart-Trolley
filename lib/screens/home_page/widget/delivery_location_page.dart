import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart' as places;
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

  // Places
  late final places.FlutterGooglePlacesSdk _places;
  List<places.AutocompletePrediction> _predictions = [];
  Timer? _debounce;

  // State
  bool _loading = true;
  bool _mapVisible = false;
  String? _error;
  String? _address;

  @override
  void initState() {
    super.initState();

    // Initialize Places SDK with your key (billing + Places API (New) must be enabled)
    _places = places.FlutterGooglePlacesSdk(
      "AIzaSyCU6eGlSrl3Pc0P5gRzjtapWRvWcs0e9cw",
    );

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
        setState(() {
          _error = 'Location services are disabled';
          _loading = false;
        });
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        setState(() {
          _error = 'Location permission denied';
          _loading = false;
        });
        return;
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permission permanently denied';
          _loading = false;
        });
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
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ---------- Reverse Geocode ----------
  Future<void> _reverseGeocode(gmap.LatLng point) async {
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
    } catch (_) {/* ignore */}
  }

  void _onSearchChanged() {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 300), () async {
    final q = _searchCtrl.text.trim();

    if (q.isEmpty) {
      if (!mounted) return;
      setState(() => _predictions = []);
      return;
    }

    try {
      final res = await _places.findAutocompletePredictions(q);
      // Debug: see if predictions arrive
      // ignore: avoid_print
      print('Places predictions: ${res.predictions.length} for "$q"');

      if (!mounted) return;
      setState(() => _predictions = res.predictions);
    } catch (e) {
      // ignore: avoid_print
      print('Places API error: $e');
      if (!mounted) return;
      setState(() => _predictions = []);
    }
  });
}


  // ---------- Use Current Location ----------
  Future<void> _useCurrentLocation() async {
    if (_currentLatLng == null) return;
    Navigator.pop(context, {
      'lat': _currentLatLng!.latitude,
      'lng': _currentLatLng!.longitude,
      'address': _address ?? 'Current location',
    });
  }

  // ---------- Confirm Pinned ----------
  Future<void> _confirmPin() async {
    if (_pinLatLng == null) return;
    await _reverseGeocode(_pinLatLng!);
    Navigator.pop(context, {
      'lat': _pinLatLng!.latitude,
      'lng': _pinLatLng!.longitude,
      'address': _address ?? 'Selected location',
    });
  }

  void _onMapCreated(gmap.GoogleMapController controller) {
    _mapController = controller;
    if (_pinLatLng != null) {
      _mapController!.animateCamera(
        gmap.CameraUpdate.newLatLngZoom(_pinLatLng!, 16),
      );
    }
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Select location')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // title
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text('Select a delivery location', style: titleStyle),
                    ),

                  Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        focusNode: _searchFocus,
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search for an address or area',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
      ),
      if (_predictions.isNotEmpty)
        const SizedBox(height: 8),
      if (_predictions.isNotEmpty)
        Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,                 // <-- important
            physics: const ClampingScrollPhysics(),
            itemCount: _predictions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = _predictions[i];
              final primary = p.primaryText ?? p.fullText ?? '';
              final secondary = p.secondaryText ?? '';
              return ListTile(
                dense: true,
                title: Text(primary, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: secondary.isNotEmpty
                    ? Text(secondary, maxLines: 1, overflow: TextOverflow.ellipsis)
                    : null,
                onTap: () => _onSelectPrediction(p),
              );
            },
          ),
        ),
    ],
  ),
),

                    const SizedBox(height: 12),

                    // Map
                    if (_mapVisible) _buildMapSection(),

                    // Footer buttons
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
                                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
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
                                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              onPressed: _confirmPin,
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Confirm this location'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Add more details button over the map
// Example where you added the "Add more details" button
if (_pinLatLng != null && _mapVisible) 
  Positioned(
    bottom: 100,
    left: 16,
    right: 16,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent, // transparent background
        shadowColor: Colors.transparent,     // remove shadow
        foregroundColor: Colors.orange,      // text/icon color
        side: const BorderSide(color: Colors.orange), // outline
      ),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.grey[500], // transparent background behind sheet
          builder: (_) => FractionallySizedBox(
            heightFactor: 0.8,
            child: AddressDetailsSheet(initialArea: _address,                 // 👈 prefill with selected location
      onChangeLocation: () {
        // close sheet is already handled below in the sheet code
        // re-open your location/map flow here if needed
        setState(() {
          _mapVisible = true;                // or navigate back to map/search
        });
      },),
          ),
        );
      },
      child: const Text("Add more details"),
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
    if (_pinLatLng == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Locating map...'),
      );
    }

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
                infoWindow: gmap.InfoWindow(
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

  // ---------- Handle selection ----------
  Future<void> _onSelectPrediction(places.AutocompletePrediction p) async {
    try {
      setState(() => _predictions = []); // hide list

      final details = await _places.fetchPlace(
        p.placeId,
        fields: const [
          places.PlaceField.Location,
          places.PlaceField.Name,
        ],
      );

      final loc = details.place?.latLng;
      if (loc == null) return;

      final latLng = gmap.LatLng(loc.lat, loc.lng);

      setState(() {
        _pinLatLng = latLng;
        _mapVisible = true;
        _searchCtrl.text = details.place?.name ?? p.fullText ?? '';
      });

      _searchFocus.unfocus(); // show map
      await _reverseGeocode(latLng);

      _mapController?.animateCamera(
        gmap.CameraUpdate.newLatLngZoom(latLng, 16),
      );
    } catch (_) {/* ignore */}
  }
}
