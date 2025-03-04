import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserProvider with ChangeNotifier {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  String? _username;
  String? _userType;
  String? _authToken;
  String? _profileImagePath;

  String? get username => _username;
  String? get userType => _userType;
  String? get authToken => _authToken;
  String? get profileImagePath =>
      _profileImagePath ?? "assets/user.png"; // Default image

  UserProvider() {
    _loadUserData(); // Load stored user data on initialization
  }

  Future<void> _loadUserData() async {
    _username = await _secureStorage.read(key: "USERNAME");
    _userType = await _secureStorage.read(key: "USER_TYPE");
    _authToken = await _secureStorage.read(key: "TOKEN");
    _profileImagePath = await _secureStorage.read(key: "PROFILE_IMAGE");

    notifyListeners();
  }

  Future<void> setUser(
      String username, String userType, String authToken) async {
    _username = username;
    _userType = userType;
    _authToken = authToken;

    await _secureStorage.write(key: "USERNAME", value: username);
    await _secureStorage.write(key: "USER_TYPE", value: userType);
    await _secureStorage.write(key: "TOKEN", value: authToken);

    notifyListeners();
  }

  Future<void> setProfileImage(String imagePath) async {
    _profileImagePath = imagePath;
    await _secureStorage.write(key: "PROFILE_IMAGE", value: imagePath);
    notifyListeners();
  }

  Future<void> logout() async {
    _username = null;
    _userType = null;
    _authToken = null;
    _profileImagePath = null;

    await _secureStorage.delete(
      key: "TOKEN",
    ); // Clears all stored credentials
    await _secureStorage.delete(
      key: "USER_TYPE",
    );
    await _secureStorage.delete(
      key: "USERNAME",
    );
    notifyListeners();
  }
}
