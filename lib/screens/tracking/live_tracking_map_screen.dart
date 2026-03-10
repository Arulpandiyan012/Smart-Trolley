import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';
import 'dart:math' show cos, sqrt, asin, sin, pi;

class LiveTrackingMapScreen extends StatefulWidget {
  final String orderId;

  const LiveTrackingMapScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<LiveTrackingMapScreen> createState() => _LiveTrackingMapScreenState();
}

class _LiveTrackingMapScreenState extends State<LiveTrackingMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  
  Set<Marker> _markers = {};
  LatLng? _driverLocation;
  Timer? _pollingTimer;
  bool _isLoading = true;
  bool _isLive = false;
  String _etaText = "Calculating...";

  @override
  void initState() {
    super.initState();
    _fetchDriverLocation();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
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

        setState(() {
          _driverLocation = LatLng(lat, lng);
          _isLive = isLive;
          _isLoading = false;
          _updateMarker();
        });

        _moveCameraToDriver();
      } else {
        setState(() {
           _isLoading = false;
           _etaText = "Waiting for driver to start trip...";
        });
      }
    } catch (e) {
      debugPrint("Tracking Ping Failed: \$e");
    }
  }

  void _updateMarker() async {
    if (_driverLocation == null) return;
    
    // Optional: Use a custom truck icon instead of default marker
    // BitmapDescriptor truckIcon = await BitmapDescriptor.fromAssetImage(..., 'assets/truck.png');
    
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(title: 'Delivery Partner', snippet: _isLive ? 'Moving' : 'Offline'),
        )
      };
      
      // Basic ETA Calculation (assuming fixed destination for now, or just showing live flag)
      _etaText = _isLive ? "Driver is on the way!" : "Driver is offline/stationary";
    });
  }

  Future<void> _moveCameraToDriver() async {
    if (_driverLocation == null) return;
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: _driverLocation!,
        zoom: 16.0, // Close zoom for live tracking
      ),
    ));
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track Order \${widget.orderId}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : (_driverLocation == null 
            ? Center(child: Text(_etaText, style: const TextStyle(fontSize: 16, color: Colors.grey)))
            : Stack(
                children: [
                  GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: _driverLocation!,
                      zoom: 16.0,
                    ),
                    markers: _markers,
                    myLocationEnabled: true,
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                    },
                  ),
                  Positioned(
                    bottom: 30,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isLive ? Icons.local_shipping : Icons.pause_circle_filled, 
                            color: _isLive ? Colors.green : Colors.orange, 
                            size: 40
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Delivery Status", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                Text(
                                  _etaText,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              )
          ),
    );
  }
}
