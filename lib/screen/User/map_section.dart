import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Mapsection extends StatefulWidget {
  final Position userPosition;

  const Mapsection({super.key, required this.userPosition});

  @override
  State<Mapsection> createState() => _MapsectionState();
}

class _MapsectionState extends State<Mapsection> {
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  final MapController _mapcontroller = MapController();
  List<dynamic> volunteers = [];
  List<dynamic> admins = [];

  @override
  void initState() {
    super.initState();
    fetchVolunteers();
    fetchAdmins();
  }

  /// Function to fetch volunteers data
  Future<void> fetchVolunteers() async {
    try {
      String? baseUrl = await secureStorage.read(key: "BASE_URL");
      if (baseUrl == null) {
        log("BASE_URL not found in secure storage");
        return;
      }

      final response = await http.get(Uri.parse("$baseUrl/volunteers/all/"));

      if (response.statusCode == 200) {
        setState(() {
          volunteers = jsonDecode(response.body);
        });
        log("Fetched volunteers: $volunteers");
      } else {
        log("Failed to fetch volunteer data: ${response.statusCode}");
      }
    } catch (e) {
      log("Error fetching volunteers: ${e.toString()}");
    }
  }

  /// Function to fetch admins data
  Future<void> fetchAdmins() async {
    try {
      String? baseUrl = await secureStorage.read(key: "BASE_URL");
      String? token = await secureStorage.read(key: "TOKEN");

      if (baseUrl == null) {
        log("Base_url not found -- fetchAdmins");
        return;
      }

      final response = await http.get(
        Uri.parse("$baseUrl/admins/"),
        headers: {
          "Authorization": "token $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          admins = jsonDecode(response.body);
        });
        log("Fetched admin: $admins");
      } else {
        log("Failed to fetch admin data: ${response.statusCode}");
      }
    } catch (e) {
      log("Error fetching admins: ${e.toString()}");
    }
  }

  /// Function to recenter map
  void recenterMap() {
    _mapcontroller.move(
      LatLng(widget.userPosition.latitude, widget.userPosition.longitude),
      12,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map Widget
        SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: FlutterMap(
            mapController: _mapcontroller,
            options: MapOptions(
              initialCenter: LatLng(
                widget.userPosition.latitude,
                widget.userPosition.longitude,
              ),
              initialZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              // User's location marker (Red)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                      widget.userPosition.latitude,
                      widget.userPosition.longitude,
                    ),
                    width: 40,
                    height: 40,
                    child: Image.asset("assets/user.png"),
                  ),
                ],
              ),
              // Admin markers (Blue)
              MarkerLayer(
                markers:
                    admins.map((admin) {
                      try {
                        if (admin['location'] != null &&
                            admin['location']['coordinates'] != null) {
                          List<dynamic> coordinates =
                              admin['location']['coordinates'];

                          if (coordinates.length == 2) {
                            double latitude = coordinates[1];
                            double longitude = coordinates[0];

                            return Marker(
                              point: LatLng(latitude, longitude),
                              width: 20,
                              height: 20,
                              child: Image.asset("assets/admin.png"),
                            );
                          }
                        }
                      } catch (e) {
                        log("Error processing admin data: ${e.toString()}");
                      }
                      return Marker(
                        point: LatLng(
                          widget.userPosition.latitude,
                          widget.userPosition.longitude,
                        ),
                        width: 0,
                        height: 0,
                        child: const SizedBox.shrink(),
                      );
                    }).toList(),
              ),
              // Volunteer markers (Green)
              MarkerLayer(
                markers:
                    volunteers.map((volunteer) {
                      try {
                        if (volunteer['location'] != null &&
                            volunteer['location']['coordinates'] != null) {
                          List<dynamic> coordinates =
                              volunteer['location']['coordinates'];

                          if (coordinates.length == 2) {
                            double latitude = coordinates[1];
                            double longitude = coordinates[0];

                            return Marker(
                              point: LatLng(latitude, longitude),
                              width: 20,
                              height: 20,
                              child: Image.asset("assets/volunteer.png"),
                            );
                          }
                        }
                      } catch (e) {
                        log("Error processing volunteer data: ${e.toString()}");
                      }
                      return Marker(
                        point: LatLng(
                          widget.userPosition.latitude,
                          widget.userPosition.longitude,
                        ),
                        width: 0,
                        height: 0,
                        child: const SizedBox.shrink(),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),

        // Floating Action Button (FAB) to recenter the map
        Positioned(
          right: 10, // Adjust horizontal position
          top: MediaQuery.of(context).size.height * 0.4, // Center vertically
          child: FloatingActionButton(
            onPressed: recenterMap,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
