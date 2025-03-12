import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:wesalvator/Admin/admin_dashboard.dart';
import 'package:wesalvator/Volunteer/volunteer_dashboard.dart';
import 'package:wesalvator/provider/user_provider.dart';
import 'package:wesalvator/services/notification.dart';
import 'package:wesalvator/user/user_dashboard_screen.dart';

class AuthService {
  static const _secureStorage = FlutterSecureStorage();
  static const _tokenKey = "TOKEN";
  static const _userTypeKey = "USER_TYPE";
  static const _usernameKey = "USERNAME";
  static const _authBaseUrlKey = "AUTH_BASE_URL";

  void _showErrorToast(String message) {
    Fluttertoast.showToast(msg: message, backgroundColor: Colors.red);
  }

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(msg: message, backgroundColor: Colors.green);
  }

  Future<String> _getBaseUrl() async {
    final url = await _secureStorage.read(key: _authBaseUrlKey);
    if (url == null) {
      throw Exception("Base URL not configured");
    }
    return url;
  }

  void navigateToDashboard(String userType, BuildContext context) {
    final dashboardMap = {
      "ADMIN": AdminDashboard(),
      "USER": UserDashBoardScreen(),
      "VOLUNTEER": VolunteerDashboard(),
    };

    final dashboard = dashboardMap[userType] ?? UserDashBoardScreen();
    subscribeToNotification(userType);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => dashboard),
    );
  }

  Future<Map<String, dynamic>> signup({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
    required String phone,
    required String userType,
  }) async {
    try {
      final baseUrl = await _getBaseUrl();
      final Uri signupUrl = Uri.parse("$baseUrl/signup/");

      final response = await http.post(
        signupUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "email": email,
          "password": password,
          "password2": confirmPassword,
          "mobile_number": phone,
          "user_type": userType,
        }),
      );

      print("Signup Response Code: ${response.statusCode}");
      print("Signup Response Body: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Signup Error: $e");
      return {"error": "Signup failed. Please try again."};
    }
  }

  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      final baseUrl = await _getBaseUrl();
      final Uri fpwUrl = Uri.parse("$baseUrl/reset-password/");

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

  Future<void> login({
    required String username,
    required String password,
    required String userType,
    required BuildContext context,
  }) async {
    if (username.isEmpty || password.isEmpty) {
      _showErrorToast("Please fill all fields and select user type");
      return;
    }

    try {
      final baseUrl = await _getBaseUrl();
      final loginUrl = Uri.parse("$baseUrl/login/");

      final response = await http.post(
        loginUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
          "user_type": userType,
        }),
      );

      final responseData =
          response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 && responseData.containsKey("token")) {
        await _handleSuccessfulLogin(
          context,
          responseData["token"],
          responseData["user_type"],
          username,
        );
      } else {
        _showErrorToast(responseData["error"] ?? "Invalid login credentials");
      }
    } catch (e) {
      _showErrorToast("Login failed: ${e.toString()}");
    }
  }

  //Login with google happens here
  Future<void> loginWithGoogle(BuildContext context) async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        ),
      );

      final user = userCredential.user;
      if (user != null) {
        _handleGoogleLoginSuccess(context, user);
      }
    } catch (e) {
      print("Google Sign-In error: $e");
      _showErrorToast("Google Sign-In failed: $e");
    }
  }

  Future<void> _handleSuccessfulLogin(
    BuildContext context,
    String token,
    String userType,
    String username,
  ) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    await _secureStorage.write(key: _userTypeKey, value: userType);
    await _secureStorage.write(key: _usernameKey, value: username);

    Provider.of<UserProvider>(
      context,
      listen: false,
    ).setUser(username, userType, token);

    _showSuccessToast("Login successful!");
    navigateToDashboard(userType, context);
  }
}

void _handleGoogleLoginSuccess(BuildContext context, User user) {
  // Define phoneNumber outside if-else block
  String phoneNumber = "+910000000000"; // Default dummy number

  if (user.phoneNumber != null) {
    phoneNumber = "+91${user.phoneNumber}"; // Assign actual phone number
  }

  AuthService().signup(
    username: user.displayName.toString().replaceAll(" ", ""),
    email: user.email.toString(),
    password: user.uid,
    confirmPassword: user.uid,
    phone: phoneNumber,
    userType: "USER",
  );

  print(user.displayName.toString().replaceAll(" ", ""));
  print(phoneNumber);

  AuthService().login(
    username: user.displayName.toString().replaceAll(" ", ""),
    password: user.uid,
    userType: "USER",
    context: context,
  );
}
