import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:bagisto_app_demo/utils/shared_preference_helper.dart';

// Key for storing recent locations in GetStorage
const String _recentLocationsKey = "recentLocations";

class DeliveryLocationPage extends StatefulWidget {
  const DeliveryLocationPage({Key? key}) : super(key: key);

  @override
  State<DeliveryLocationPage> createState() => _DeliveryLocationPageState();
}

class _DeliveryLocationPageState extends State<DeliveryLocationPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  gmap.GoogleMapController? _mapController;
  gmap.LatLng? _currentLatLng;
  gmap.LatLng? _pinLatLng;
  Placemark? _currentPlacemark;

  List<dynamic> _predictions = [];
  Timer? _debounce;

  bool _loading = true;
  bool _mapVisible = false;
  String? _error;
  String? _address;

  // Recently searched locations
  List<Map<String, dynamic>> _recentLocations = [];

  @override
  void initState() {
    super.initState();
    _initCurrentLocation();
    _searchCtrl.addListener(_onSearchChanged);
    _loadRecentLocations();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController?.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _loadRecentLocations() {
    final raw = appStoragePref.configurationStorage.read(_recentLocationsKey);
    if (raw is List) {
      setState(() {
        _recentLocations = List<Map<String, dynamic>>.from(
          raw.map((e) => Map<String, dynamic>.from(e as Map)),
        );
      });
    }
  }

  void _saveRecentLocation(String display, String? sub, Map<String, dynamic> data) {
    final entry = {'display': display, 'sub': sub ?? '', 'data': data};
    final existing = List<Map<String, dynamic>>.from(_recentLocations);
    existing.removeWhere((e) => e['display'] == display);
    final updated = [entry, ...existing].take(5).toList();
    appStoragePref.configurationStorage.write(_recentLocationsKey, updated);
    if (mounted) setState(() => _recentLocations = updated);
  }

  Future<void> _initCurrentLocation() async {
    final location = loc.Location();
    try {
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        setState(() { _error = 'Location services are disabled'; _loading = false; });
        return;
      }
      loc.PermissionStatus permission = await location.hasPermission();
      if (permission == loc.PermissionStatus.denied) {
        permission = await location.requestPermission();
      }
      if (permission != loc.PermissionStatus.granted) {
        setState(() { _error = 'Location permission denied'; _loading = false; });
        return;
      }
      final locData = await location.getLocation();
      if (locData.latitude == null || locData.longitude == null) {
        setState(() { _error = 'Unable to get current position'; _loading = false; });
        return;
      }
      final here = gmap.LatLng(locData.latitude!, locData.longitude!);
      setState(() { _currentLatLng = here; _pinLatLng = here; _loading = false; });
      _reverseGeocode(here);
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _reverseGeocode(gmap.LatLng point) async {
    try {
      final marks = await placemarkFromCoordinates(point.latitude, point.longitude);
      if (marks.isNotEmpty) {
        final p = marks.first;
        _currentPlacemark = p;
        final parts = [p.name, p.subLocality, p.locality, p.administrativeArea, p.postalCode]
            .where((e) => (e ?? '').trim().isNotEmpty).map((e) => e!.trim());
        final text = parts.isNotEmpty ? parts.join(', ') : 'Unknown location';
        setState(() => _address = text);
      }
    } catch (_) {}
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final q = _searchCtrl.text.trim();
      if (q.isEmpty) {
        if (mounted) setState(() => _predictions = []);
        return;
      }
      try {
        final url = Uri.parse(
            "https://nominatim.openstreetmap.org/search?q=$q&format=json&polygon_geojson=1&addressdetails=1");
        final response = await http.get(url, headers: {"User-Agent": "BagistoAppDemo/1.0"});
        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          if (mounted) setState(() => _predictions = data);
        }
      } catch (_) {
        if (mounted) setState(() => _predictions = []);
      }
    });
  }

  Future<void> _useCurrentLocation() async {
    if (_currentLatLng == null) return;
    if (_currentPlacemark == null) await _reverseGeocode(_currentLatLng!);
    _returnLocationData(_currentLatLng!);
  }

  Future<void> _confirmPin() async {
    if (_pinLatLng == null) return;
    await _reverseGeocode(_pinLatLng!);
    _returnLocationData(_pinLatLng!);
  }

  void _returnLocationData(gmap.LatLng latLng) {
    final data = {
      'lat': latLng.latitude,
      'lng': latLng.longitude,
      'address': _address ?? 'Selected location',
      'pincode': _currentPlacemark?.postalCode ?? "",
      'city': _currentPlacemark?.locality ?? _currentPlacemark?.subLocality ?? "",
      'state': _currentPlacemark?.administrativeArea ?? "",
      'country': _currentPlacemark?.isoCountryCode ?? "IN",
    };

    // Save to recent locations
    final displayName = _address ?? 'Selected location';
    final subText = [
      _currentPlacemark?.locality,
      _currentPlacemark?.administrativeArea,
      _currentPlacemark?.country,
    ].where((e) => (e ?? '').isNotEmpty).join(', ');
    _saveRecentLocation(displayName, subText, data);

    Navigator.pop(context, data);
  }

  void _onMapCreated(gmap.GoogleMapController controller) {
    _mapController = controller;
    if (_pinLatLng != null) {
      _mapController!.animateCamera(gmap.CameraUpdate.newLatLngZoom(_pinLatLng!, 16));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF27C16B))),
      );
    }

    if (_mapVisible) {
      return _buildMapView(isDark);
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select delivery location',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search Bar ──
          Container(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                focusNode: _searchFocus,
                controller: _searchCtrl,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search for area, street name...',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 22),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close, color: Colors.grey[400], size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _predictions = []);
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // ── Prediction dropdown ──
          if (_predictions.isNotEmpty)
            Container(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _predictions.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: isDark ? Colors.white12 : Colors.grey[200],
                ),
                itemBuilder: (context, i) {
                  final p = _predictions[i];
                  final name = p['display_name'] ?? '';
                  return InkWell(
                    onTap: () => _onSelectOSMPrediction(p),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF27C16B).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.location_on_outlined, color: Color(0xFF27C16B), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          else ...[
            // ── Action Tiles ──
            const SizedBox(height: 8),
            Container(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Column(
                children: [
                  _buildActionTile(
                    icon: Icons.my_location,
                    iconColor: const Color(0xFF27C16B),
                    title: 'Use current location',
                    isDark: isDark,
                    onTap: _useCurrentLocation,
                  ),
                  Divider(height: 1, indent: 60, color: isDark ? Colors.white12 : Colors.grey[200]),
                  _buildActionTile(
                    icon: Icons.add,
                    iconColor: const Color(0xFF27C16B),
                    title: 'Add new address',
                    isDark: isDark,
                    onTap: () {
                      setState(() => _mapVisible = true);
                    },
                  ),
                ],
              ),
            ),

            // ── Recently Searched Locations ──
            if (_recentLocations.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'Recently searched locations',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Container(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: _recentLocations.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 60,
                    color: isDark ? Colors.white12 : Colors.grey[200],
                  ),
                  itemBuilder: (context, i) {
                    final loc = _recentLocations[i];
                    final display = loc['display'] as String? ?? '';
                    final sub = loc['sub'] as String? ?? '';
                    return InkWell(
                      onTap: () {
                        final data = loc['data'] as Map<String, dynamic>? ?? {};
                        Navigator.pop(context, data);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8E1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.location_on_outlined, color: Color(0xFFFFB300), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    display,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  if (sub.isNotEmpty)
                                    Text(
                                      sub,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                    ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: iconColor,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  // ── Map View (shown after "Add new address" or selecting from search) ──
  Widget _buildMapView(bool isDark) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => setState(() => _mapVisible = false),
        ),
        title: Text(
          'Choose delivery location',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
      body: _error != null ? _buildError() : _buildMapContent(),
    );
  }

  Widget _buildMapContent() {
    if (_pinLatLng == null) return const Center(child: CircularProgressIndicator(color: Color(0xFF27C16B)));

    return Stack(
      children: [
        gmap.GoogleMap(
          initialCameraPosition: gmap.CameraPosition(target: _pinLatLng!, zoom: 16),
          onMapCreated: _onMapCreated,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
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

        // My Location FAB
        Positioned(
          bottom: 100,
          right: 16,
          child: FloatingActionButton.small(
            backgroundColor: Colors.white,
            elevation: 4,
            onPressed: () {
              if (_currentLatLng != null) {
                setState(() => _pinLatLng = _currentLatLng);
                _mapController?.animateCamera(gmap.CameraUpdate.newLatLngZoom(_currentLatLng!, 16));
                _reverseGeocode(_currentLatLng!);
              }
            },
            child: const Icon(Icons.my_location, color: Color(0xFF27C16B)),
          ),
        ),

        // Address chip at top
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: Material(
            elevation: 3,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF27C16B), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _address ?? 'Fetching location...',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Confirm button
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27C16B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: _confirmPin,
            child: const Text(
              'Confirm delivery location',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
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
      await _reverseGeocode(latLng);
    } catch (_) {}
  }
}