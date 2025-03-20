import 'dart:developer';

import 'package:geocoding/geocoding.dart';

class GetAddress {
  Future<String?> getAddressFromCurrentLocation(double lat, double long) async {
    try {
      // Convert latitude & longitude to address using geocoding
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        //${place.street},
        String address =
            " ${place.locality}, ${place.administrativeArea}, ${place.country}";

        return address;
      } else {
        log("No address found for the given coordinates.");
        return "Unknown Location";
      }
    } catch (e) {
      log("Error converting lat/lon to address: $e");
      return "Error retrieving address";
    }
  }
}
