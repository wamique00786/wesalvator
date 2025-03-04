import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class ConfirmRescue extends StatelessWidget {
  final Position currentPosition;

  // Constructor to accept the current position
  const ConfirmRescue({super.key, required this.currentPosition});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Confirm Rescue"),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Rescue Task Details",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // Display the current location
            Text(
              "Starting Position:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Latitude: ${currentPosition.latitude}",
              style: TextStyle(fontSize: 16),
            ),
            Text(
              "Longitude: ${currentPosition.longitude}",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),

            // Confirm button or further steps
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Implement further rescue confirmation or actions
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                ),
                child: Text("Confirm Rescue Start"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
