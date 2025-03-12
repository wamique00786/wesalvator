// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:wesalvator/services/auth_service.dart';

import '../auth pages/forgot_password_screen.dart';
import '../auth pages/signup_screen.dart';
import '../provider/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  static const _secureStorage = FlutterSecureStorage();

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

    Future.microtask(_checkLoginStatus);
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  //checkes login here
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
        AuthService().navigateToDashboard(userType, context);
      }
    } catch (e) {
      // Log error or handle gracefully
      print('Login status check failed: $e');
    }
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
      () => AuthService().login(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        userType: _selectedUserType as String,
        context: context,
      ),
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
      () => AuthService().loginWithGoogle(context),
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
