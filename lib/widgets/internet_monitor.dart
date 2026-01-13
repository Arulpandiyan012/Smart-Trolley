import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class InternetMonitor extends StatefulWidget {
  final Widget child;
  const InternetMonitor({Key? key, required this.child}) : super(key: key);

  @override
  State<InternetMonitor> createState() => _InternetMonitorState();
}

class _InternetMonitorState extends State<InternetMonitor> {
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    // Listen to network changes
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // Check if any result indicates a connection
      bool hasConnection = results.any((result) => 
        result == ConnectivityResult.mobile || 
        result == ConnectivityResult.wifi || 
        result == ConnectivityResult.ethernet);

      if (mounted) {
        setState(() {
          _isOffline = !hasConnection;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: widget.child),
        
        // The Error Message Bar
        if (_isOffline)
          Container(
            width: double.infinity,
            color: Colors.red,
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.wifi_off, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  "No Internet Connection",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
      ],
    );
  }
}