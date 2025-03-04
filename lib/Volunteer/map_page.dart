import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class GeolocTrackingWidget extends StatefulWidget {
  final LatLng destination;

  const GeolocTrackingWidget({super.key, required this.destination});

  @override
  State<GeolocTrackingWidget> createState() => _GeolocTrackingWidgetState();
}

class _GeolocTrackingWidgetState extends State<GeolocTrackingWidget> {
  LatLng? currentLocation;
  List<LatLng> polylinePoints = [];
  bool isTracking = false;
  StreamSubscription<Position>? positionSubscription;

  final mapController = MapController();

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: currentLocation == null
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: currentLocation!,
                    initialZoom: 24.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: currentLocation!,
                          width: 60,
                          height: 60,
                          child: const Icon(
                            Icons.person_pin_circle,
                            color: Colors.blue,
                            size: 40,
                          ),
                        ),
                        Marker(
                          point: widget.destination,
                          width: 60,
                          height: 60,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: polylinePoints,
                          strokeWidth: 4.0,
                          color: Colors.blueAccent,
                        ),
                      ],
                    ),
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: isTracking ? _stopTracking : _startTracking,
            child: Text(
              isTracking ? 'Stop Tracking' : 'Start Tracking',
            ),
          ),
        ),
      ],
    );
  }

  void _fetchCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
    });

    await _fetchRoute();
    _fitMapToPolyline();
  }

  Future<void> _fetchRoute() async {
    if (currentLocation == null) return;

    final url =
        'https://router.project-osrm.org/route/v1/driving/${currentLocation!.longitude},${currentLocation!.latitude};${widget.destination.longitude},${widget.destination.latitude}?overview=full&geometries=polyline';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final String polyline = data['routes'][0]['geometry'];

      List<PointLatLng> decodedPoints = PolylinePoints().decodePolyline(
        polyline,
      );

      setState(() {
        polylinePoints =
            decodedPoints.map((p) => LatLng(p.latitude, p.longitude)).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch route from OSRM.')),
      );
    }
  }

  void _startTracking() {
    setState(() {
      isTracking = true;
    });

    positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen((Position position) async {
      final updatedLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        currentLocation = updatedLocation;
      });

      await _fetchRoute(); // Fetch new route based on updated current location
      _fitMapToPolyline();
    });
  }

  void _stopTracking() {
    setState(() {
      isTracking = false;
    });

    positionSubscription?.cancel();
    positionSubscription = null;
  }

  void _fitMapToPolyline() {
    if (polylinePoints.isEmpty) {
      return; // Don't try to fit an empty route
    }

    final bounds = LatLngBounds.fromPoints(polylinePoints);

    mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)),
    );
  }
}
