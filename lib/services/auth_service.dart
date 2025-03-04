import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  Future<String?> getBaseUrl() async {
    final storage = FlutterSecureStorage();
    return await storage.read(key: "BASE_URL");
  }

  Future<Map<String, dynamic>> signup(
      String username,
      String email,
      String password,
      String confirmPassword,
      String phone,
      String userType) async {
    final String? baseUrl = await getBaseUrl();
    final Uri signupUrl = Uri.parse("$baseUrl/signup/");
    try {
      final response = await http.post(
        signupUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "email": email,
          "password": password,
          "password2": confirmPassword, // API requires this
          "mobile_number": phone, // API expects 'mobile_number', not 'phone'
          "user_type": userType,
        }),
      );

      print("Signup Response Code: ${response.statusCode}");
      print("Signup Response Body: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return jsonDecode(response.body); // API error details
      }
    } catch (e) {
      print("Signup Error: $e");
      return {"error": "Signup failed. Please try again."};
    }
  }

  // Password Reset Function
  Future<Map<String, dynamic>> resetPassword(String email) async {
    final String? baseUrl = await getBaseUrl();
    final Uri fpwUrl = Uri.parse("$baseUrl/signup/");
    try {
      final response = await http.post(
        fpwUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      if (response.statusCode == 200) {
        return {"success": "Password reset link sent"};
      } else {
        return jsonDecode(response.body);
      }
    } catch (e) {
      return {"error": "Error sending reset email"};
    }
  }
}
