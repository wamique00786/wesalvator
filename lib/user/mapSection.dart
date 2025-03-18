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
      print(token);
      if (baseUrl == null) {
        log("Base_url not found -- fetchAdmins");
        return;
      }

      // This should be a different endpoint that returns only admins
      final response = await http.get(
        Uri.parse("$baseUrl/admins/"), // Changed endpoint
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 240,
        width: double.infinity,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(
              widget.userPosition.latitude,
              widget.userPosition.longitude,
            ),
            initialZoom: 8.0,
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
                  width: 60,
                  height: 60,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red, // User is red
                    size: 40,
                  ),
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
                            width: 60,
                            height: 60,
                            child: const Icon(
                              Icons.person_pin_circle,
                              color: Colors.blue, // Admin is blue
                              size: 40,
                            ),
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
                            width: 60,
                            height: 60,
                            child: const Icon(
                              Icons.person_pin_circle,
                              color: Colors.green, // Volunteer is green
                              size: 40,
                            ),
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
    );
  }
}
