import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:wesalvator/Admin/admin_dashboard.dart';
import 'package:wesalvator/Volunteer/volunteer_dashboard.dart';
import 'package:wesalvator/auth%20pages/forgot_password_screen.dart';
import 'package:wesalvator/auth%20pages/signup_screen.dart';
import 'package:wesalvator/provider/user_provider.dart';
import 'package:wesalvator/user/user_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  bool _obscurePassword = true;
  String? _selectedUserType;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Check if user is already logged in
  Future<void> _checkLoginStatus() async {
    String? token = await _secureStorage.read(key: "TOKEN");
    String? userType = await _secureStorage.read(key: "USER_TYPE");

    if (userType != null) {
      Provider.of<UserProvider>(context, listen: false).setUser(
        await _secureStorage.read(key: "USERNAME") ?? "",
        userType,
        token!,
      );

      _navigateToDashboard(userType);
    }
  }

  Future<String?> getBaseUrl() async {
    return await _secureStorage.read(key: "BASE_URL");
  }

  // Function to login
  void _login(BuildContext context) async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty || _selectedUserType == null) {
      Fluttertoast.showToast(
          msg: "Please fill all fields and select user type");
      return;
    }

    final String? baseUrl = await getBaseUrl();
    if (baseUrl == null) {
      Fluttertoast.showToast(msg: "Error: Base URL not found");
      return;
    }

    final Uri loginUrl = Uri.parse("$baseUrl/login/");
    try {
      final response = await http.post(
        loginUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
          "user_type": _selectedUserType
        }),
      );

      if (response.body.isEmpty) {
        Fluttertoast.showToast(msg: "Error: Empty response from server.");
        return;
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData.containsKey("token")) {
        String token = responseData["token"];
        String userType = responseData["user_type"];

        // Store login details securely
        await _secureStorage.write(key: "TOKEN", value: token);
        await _secureStorage.write(key: "USER_TYPE", value: userType);
        await _secureStorage.write(key: "USERNAME", value: username);

        Provider.of<UserProvider>(context, listen: false)
            .setUser(username, userType, token);

        Fluttertoast.showToast(msg: "Login successful!");

        _navigateToDashboard(userType);
      } else {
        Fluttertoast.showToast(
            msg: responseData["error"] ?? "Invalid login credentials");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: ${e.toString()}");
    }
  }

  // Navigate to correct dashboard
  void _navigateToDashboard(String userType) {
    Widget dashboard;
    if (userType == "ADMIN") {
      dashboard = AdminDashboard();
    } else if (userType == "USER") {
      dashboard = UserDashBoardScreen();
    } else {
      dashboard = VolunteerDashboard();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => dashboard),
    );
  }

  // Logout function
  Future<void> logout() async {
    await _secureStorage.deleteAll();
    Fluttertoast.showToast(msg: "Logged out successfully");
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/backgroundimg.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.08,
                  vertical: screenHeight * 0.08),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Welcome to Rescue Animals",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.08,
                      fontWeight: FontWeight.w900,
                      color: Colors.teal[900],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05),
                  _buildTextField(
                      Icons.person, "Username", _usernameController),
                  SizedBox(height: screenHeight * 0.02),
                  _buildTextField(Icons.lock, "Password", _passwordController,
                      isPassword: true),
                  SizedBox(height: screenHeight * 0.02),
                  _buildDropdownField(Icons.person, "Select User Type"),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ForgotPasswordScreen()));
                      },
                      child: Text(
                        "Forgot Password?",
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.teal[900]),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  _buildButton("Login", Colors.teal[900]!,
                      () => _login(context), screenWidth),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SignupScreen()));
                    },
                    child: Text(
                      "Don't have an account? Sign Up",
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[900]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      IconData icon, String hint, TextEditingController controller,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.teal[300]),
        hintText: hint,
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.teal[300]),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
      ),
    );
  }

  Widget _buildDropdownField(IconData icon, String hint) {
    return DropdownButtonFormField<String>(
      value: _selectedUserType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.teal[300]),
        hintText: hint,
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'USER', child: Text('Regular User')),
        DropdownMenuItem(value: 'ADMIN', child: Text('Administrator')),
        DropdownMenuItem(value: 'VOLUNTEER', child: Text('Volunteer')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedUserType = value;
        });
      },
    );
  }

  Widget _buildButton(
      String text, Color color, VoidCallback onPressed, double width) {
    return SizedBox(
      width: width * 0.8,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}
