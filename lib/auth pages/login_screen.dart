import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../Admin/admin_dashboard.dart';
import '../Volunteer/volunteer_dashboard.dart';
import '../auth pages/forgot_password_screen.dart';
import '../auth pages/signup_screen.dart';
import '../provider/user_provider.dart';
import '../user/user_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Use late initialization for controllers to improve performance
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  // Create constant for secure storage to avoid multiple instantiations
  static const _secureStorage = FlutterSecureStorage();

  // Use constant for user types to prevent repeated string literals
  static const Map<String, String> _userTypes = {
    'USER': 'Regular User',
    'ADMIN': 'Administrator',
    'VOLUNTEER': 'Volunteer',
  };

  bool _obscurePassword = true;
  String? _selectedUserType;

  @override
  void initState() {
    super.initState();
    // Initialize controllers in initState
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();

    // Use Future.microtask to avoid blocking UI during initialization
    Future.microtask(_checkLoginStatus);
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Refactored to use more robust error handling
  Future<void> _checkLoginStatus() async {
    try {
      final token = await _secureStorage.read(key: "TOKEN");
      final userType = await _secureStorage.read(key: "USER_TYPE");
      final username = await _secureStorage.read(key: "USERNAME");

      if (token != null && userType != null && username != null) {
        Provider.of<UserProvider>(
          context,
          listen: false,
        ).setUser(username, userType, token);
        _navigateToDashboard(userType);
      }
    } catch (e) {
      // Log error or handle gracefully
      print('Login status check failed: $e');
    }
  }

  // Simplified URL retrieval
  Future<String> _getBaseUrl() async {
    final url = await _secureStorage.read(key: "BASE_URL");
    if (url == null) {
      throw Exception("Base URL not configured");
    }
    return url;
  }

  // Enhanced login method with better error handling
  void _login(BuildContext context) async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    // Comprehensive input validation
    if (username.isEmpty || password.isEmpty || _selectedUserType == null) {
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
          "user_type": _selectedUserType,
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

  // Extracted method for login success logic
  Future<void> _handleSuccessfulLogin(
    BuildContext context,
    String token,
    String userType,
    String username,
  ) async {
    // Store login details securely
    await _secureStorage.write(key: "TOKEN", value: token);
    await _secureStorage.write(key: "USER_TYPE", value: userType);
    await _secureStorage.write(key: "USERNAME", value: username);

    // Update user provider
    Provider.of<UserProvider>(
      context,
      listen: false,
    ).setUser(username, userType, token);

    _showSuccessToast("Login successful!");
    _navigateToDashboard(userType);
  }

  // Google Sign-In method with improved error handling
  Future<void> _loginWithGoogle(BuildContext context) async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final user = userCredential.user;
      if (user != null) {
        await _handleGoogleLoginSuccess(context, user);
      }
    } catch (e) {
      print(" google errr $e");
      _showErrorToast("Google Sign-In failed: $e");
    }
  }

  // Extracted method for Google login success
  Future<void> _handleGoogleLoginSuccess(
    BuildContext context,
    User user,
  ) async {
    final token = await user.getIdToken();

    await _secureStorage.write(key: "TOKEN", value: token);
    await _secureStorage.write(key: "USER_TYPE", value: "USER");
    await _secureStorage.write(
      key: "USERNAME",
      value: user.displayName ?? "Google User",
    );

    Provider.of<UserProvider>(
      context,
      listen: false,
    ).setUser(user.displayName ?? "Google User", "USER", token!);

    _showSuccessToast("Google Login successful!");
    _navigateToDashboard("USER");
  }

  // Simplified dashboard navigation
  void _navigateToDashboard(String userType) {
    final dashboardMap = {
      "ADMIN": AdminDashboard(),
      "USER": UserDashBoardScreen(),
      "VOLUNTEER": VolunteerDashboard(),
    };

    final dashboard = dashboardMap[userType] ?? UserDashBoardScreen();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => dashboard),
    );
  }

  // Utility methods for toast messages
  void _showErrorToast(String message) {
    Fluttertoast.showToast(msg: message, backgroundColor: Colors.red);
  }

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(msg: message, backgroundColor: Colors.green);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackgroundImage(),
          _buildLoginContent(screenHeight, screenWidth),
        ],
      ),
    );
  }

  // Separated background image widget
  Widget _buildBackgroundImage() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/backgroundimg.jpg"),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // Extracted login content widget
  Widget _buildLoginContent(double screenHeight, double screenWidth) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.08,
          vertical: screenHeight * 0.08,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTitleText(screenWidth),
            SizedBox(height: screenHeight * 0.05),
            _buildUsernameField(),
            SizedBox(height: screenHeight * 0.02),
            _buildPasswordField(),
            SizedBox(height: screenHeight * 0.02),
            _buildUserTypeDropdown(),
            _buildForgotPasswordLink(),
            SizedBox(height: screenHeight * 0.02),
            _buildLoginButton(screenWidth),
            _buildSignUpLink(),
            _buildGoogleLoginButton(screenWidth),
          ],
        ),
      ),
    );
  }

  // Extracted individual widget builders
  Widget _buildTitleText(double screenWidth) {
    return Text(
      "Welcome to Rescue Animals",
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: screenWidth * 0.08,
        fontWeight: FontWeight.w900,
        color: Colors.teal[900],
      ),
    );
  }

  Widget _buildUsernameField() {
    return _buildTextField(Icons.person, "Username", _usernameController);
  }

  Widget _buildPasswordField() {
    return _buildTextField(
      Icons.lock,
      "Password",
      _passwordController,
      isPassword: true,
    );
  }

  Widget _buildUserTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedUserType,
      decoration: _buildInputDecoration(Icons.person, "Select User Type"),
      items:
          _userTypes.entries
              .map(
                (entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                ),
              )
              .toList(),
      onChanged: (value) => setState(() => _selectedUserType = value),
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed:
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
            ),
        child: Text(
          "Forgot Password?",
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.teal[900]),
        ),
      ),
    );
  }

  Widget _buildLoginButton(double screenWidth) {
    return _buildButton(
      "Login",
      Colors.teal[900]!,
      Colors.white,
      () => _login(context),
      screenWidth,
    );
  }

  Widget _buildSignUpLink() {
    return TextButton(
      onPressed:
          () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SignupScreen()),
          ),
      child: Text(
        "Don't have an account? Sign Up",
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.teal[900],
        ),
      ),
    );
  }

  Widget _buildGoogleLoginButton(double screenWidth) {
    return _buildButton(
      "Login with Google",
      Colors.white,
      Colors.teal[900]!,
      () => _loginWithGoogle(context),
      screenWidth,
    );
  }

  // Reusable input decoration
  InputDecoration _buildInputDecoration(IconData icon, String hint) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.teal[300]),
      hintText: hint,
      filled: true,
      fillColor: Colors.white.withOpacity(0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  // Enhanced text field with improved password visibility
  Widget _buildTextField(
    IconData icon,
    String hint,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      decoration: _buildInputDecoration(icon, hint).copyWith(
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.teal[300],
                  ),
                  onPressed:
                      () => setState(() {
                        _obscurePassword = !_obscurePassword;
                      }),
                )
                : null,
      ),
    );
  }

  // Generic button builder
  Widget _buildButton(
    String text,
    Color backgroundColor,
    Color fontColor,
    VoidCallback onPressed,
    double width,
  ) {
    return SizedBox(
      width: width * 0.8,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: fontColor,
          ),
        ),
      ),
    );
  }
}
