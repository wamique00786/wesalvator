import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';

class RecentAnimalsScreen extends StatefulWidget {
  const RecentAnimalsScreen({super.key});

  @override
  State<RecentAnimalsScreen> createState() => _RecentAnimalsScreenState();
}

class _RecentAnimalsScreenState extends State<RecentAnimalsScreen> {
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  List<dynamic> reportList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAnimalReports();
  }

  Future<void> fetchAnimalReports() async {
    const String url = 'https://wesalvator.com/api/animal_reports/';

    try {
      String? token = await secureStorage.read(key: "TOKEN");

      final request =
          http.Request('GET', Uri.parse(url))
            ..headers['Authorization'] = 'Token $token'
            ..headers['Accept'] = 'application/json';

      final response = await http.Client().send(request);
      final responseBody = await response.stream.bytesToString();

      print('Response Code: ${response.statusCode}');
      print('Response Body: $responseBody');

      if (response.statusCode == 200) {
        var jsonData = json.decode(responseBody);
        print(jsonData.toString());
        if (jsonData is List) {
          setState(() {
            reportList = jsonData;
            isLoading = false;
          });
        } else {
          print('Unexpected JSON format');
          setState(() => isLoading = false);
        }
      } else {
        print('Failed to load animal reports: ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching animal reports: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> getAddressFromCurrentLocation() async {
    try {
      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      );

      print("Latitude: ${position.latitude}, Longitude: ${position.longitude}");

      // Convert to address using geocoding
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address =
            "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";

        print("Address: $address");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  // Future<String> getAddress(){

  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recent Animal Reports',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : reportList.isEmpty
              ? const Center(child: Text('No reports available'))
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  itemCount: reportList.length,
                  itemBuilder: (context, index) {
                    var animal = reportList[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          if (animal['photo'] != null)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: Image.network(
                                animal['photo'],
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ListTile(
                            title: Text(
                              animal['description'] ?? 'No Description',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Priority: ${animal['priority'] ?? 'Unknown'}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  'Reported by: ${animal['user'] ?? 'Unknown'}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  'Assigned to: ${animal['assigned_to'] ?? 'Unassigned'}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  'Date: ${animal['timestamp'] ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal[900],
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('View'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
