import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wesalvator/services/get_address.dart';

class LocationBar extends StatelessWidget {
  final Position? currentPosition;
  final VoidCallback onCameraPressed;

  const LocationBar({
    super.key,
    required this.currentPosition,
    required this.onCameraPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green,
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rescue Location',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Use FutureBuilder to handle async function
                currentPosition != null
                    ? FutureBuilder<String?>(
                      future: GetAddress().getAddressFromCurrentLocation(
                        currentPosition!.latitude,
                        currentPosition!.longitude,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Text(
                            'Fetching location...',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Text(
                            'Error retrieving address',
                            style: TextStyle(color: Colors.red, fontSize: 14),
                          );
                        } else {
                          return Text(
                            snapshot.data ?? 'Unknown Location',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          );
                        }
                      },
                    )
                    : Text(
                      'Fetching location...',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              onPressed: onCameraPressed,
              icon: const Icon(Icons.camera_alt),
            ),
          ),
        ],
      ),
    );
  }
}
