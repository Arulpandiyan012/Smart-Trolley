import 'dart:async';
import 'dart:math' show cos, sqrt, asin, sin, pi;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';

class LiveTrackingMapScreen extends StatefulWidget {
  final String orderId;

  const LiveTrackingMapScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<LiveTrackingMapScreen> createState() => _LiveTrackingMapScreenState();
}

class _LiveTrackingMapScreenState extends State<LiveTrackingMapScreen>
    with TickerProviderStateMixin {
  final Completer<GoogleMapController> _controller = Completer();

  Set<Marker> _markers = {};
  LatLng? _driverLocation;
  LatLng? _myLocation;
  Timer? _pollingTimer;
  bool _isLoading = true;
  bool _isLive = false;
  String _etaText = "Calculating ETA...";
  String _distanceText = "";

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _getMyLocation();
    _fetchDriverLocation();
    _startPolling();
  }

  Future<void> _getMyLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _myLocation = LatLng(pos.latitude, pos.longitude);
      });
      _updateEta();
    } catch (_) {}
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchDriverLocation();
    });
  }

  Future<void> _fetchDriverLocation() async {
    try {
      final dio = Dio();
      final response = await dio.post(
        'https://ecom.thesmartedgetech.com/tracking-api.php',
        data: {
          'action': 'get_location',
          'order_id': widget.orderId.replaceAll('#', ''),
        },
      );

      if (response.data != null && response.data['success'] == true) {
        double lat = (response.data['latitude'] as num).toDouble();
        double lng = (response.data['longitude'] as num).toDouble();
        bool isLive = response.data['is_live'] ?? false;
        String? startTimeStr = response.data['start_time'];

        setState(() {
          _driverLocation = LatLng(lat, lng);
          _isLive = isLive;
          _isLoading = false;
          if (startTimeStr != null) {
            _startTime = DateTime.tryParse(startTimeStr);
          }
        });

        _updateMarkers();
        _updateEta();
        _moveCameraToDriver();
      } else {
        setState(() {
          _isLoading = false;
          _etaText = "Waiting for driver to start the trip...";
          _distanceText = "";
        });
      }
    } catch (e) {
      debugPrint("Tracking Ping Failed: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  DateTime? _startTime;

  void _updateEta() {
    if (_driverLocation == null || _myLocation == null) return;
    double distKm = _haversineDistance(_driverLocation!, _myLocation!);
    int etaMin = (distKm / 30 * 60).ceil(); // ~30 km/h average delivery speed
    
    String tripDuration = "";
    if (_startTime != null) {
      final diff = DateTime.now().difference(_startTime!);
      tripDuration = "\nStarted ${diff.inMinutes} mins ago";
    }

    setState(() {
      _distanceText = "${distKm.toStringAsFixed(1)} km away";
      _etaText = etaMin <= 1 ? "Arriving soon!$tripDuration" : "ETA: ~$etaMin mins$tripDuration";
    });
  }

  double _haversineDistance(LatLng a, LatLng b) {
    const R = 6371.0; // Earth radius km
    double dLat = _deg2rad(b.latitude - a.latitude);
    double dLon = _deg2rad(b.longitude - a.longitude);
    double ha = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(a.latitude)) *
            cos(_deg2rad(b.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return R * 2 * asin(sqrt(ha));
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  void _updateMarkers() {
    if (_driverLocation == null) return;
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: '🛵 Delivery Partner',
            snippet: _isLive ? 'Moving towards you' : 'Stationary',
          ),
        ),
      };
    });
  }

  Future<void> _moveCameraToDriver() async {
    if (_driverLocation == null) return;
    try {
      final controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _driverLocation!, zoom: 15.5),
        ),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track Order ${widget.orderId}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.green),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchDriverLocation();
            },
            tooltip: 'Refresh location',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : (_driverLocation == null
              ? _buildWaitingView()
              : _buildMapView()),
    );
  }

  Widget _buildWaitingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: const Icon(Icons.local_shipping_outlined, size: 80, color: Colors.orange),
          ),
          const SizedBox(height: 24),
          const Text(
            "Driver hasn't started yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _etaText,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchDriverLocation();
            },
            icon: const Icon(Icons.refresh),
            label: const Text("Refresh"),
          )
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
            target: _driverLocation!,
            zoom: 15.5,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          onMapCreated: (controller) => _controller.complete(controller),
        ),

        // ── Status card at the bottom ──────────────────────────────────────
        Positioned(
          bottom: 30,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ScaleTransition(
                      scale: _isLive ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                      child: Icon(
                        _isLive ? Icons.local_shipping : Icons.pause_circle_filled,
                        color: _isLive ? Colors.green : Colors.orange,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isLive ? "Driver is on the way! 🚚" : "Driver is stationary",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _etaText,
                            style: TextStyle(
                              color: _isLive ? Colors.green : Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_distanceText.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          _distanceText,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
                const Divider(height: 20),
                const Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.grey),
                    SizedBox(width: 6),
                    Text(
                      "Live location updates every 10 seconds",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
