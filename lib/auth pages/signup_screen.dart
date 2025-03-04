import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService authService = AuthService();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();

  String? _selectedUserType;
  bool _isLoading = false; // Changed from final to mutable

  void _signup() async {
    String username = _usernameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();
    String mobileNumber = _mobileNumberController.text.trim();
    String? userType = _selectedUserType;

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        mobileNumber.isEmpty ||
        userType == null) {
      Fluttertoast.showToast(msg: "Please fill all fields");
      return;
    }
    if (password != confirmPassword) {
      Fluttertoast.showToast(msg: "Passwords do not match");
      return;
    }

    setState(() => _isLoading = true);

    var response = await authService.signup(
      username,
      email,
      password,
      confirmPassword,
      mobileNumber,
      userType,
    );

    setState(() => _isLoading = false);

    if (response.containsKey("error")) {
      Fluttertoast.showToast(msg: response["error"]);
    } else {
      Fluttertoast.showToast(msg: "Signup successful! Please login.");
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/plainyellow.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "Sign Up",
                    style: GoogleFonts.poppins(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[900],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(Icons.person, "Username", _usernameController),
                const SizedBox(height: 10),
                _buildTextField(Icons.email, "Email", _emailController),
                const SizedBox(height: 10),
                _buildTextField(Icons.lock, "Password", _passwordController,
                    isPassword: true),
                const SizedBox(height: 10),
                _buildTextField(
                    Icons.lock, "Confirm Password", _confirmPasswordController,
                    isPassword: true),
                const SizedBox(height: 10),
                _buildTextField(
                    Icons.phone, "Mobile Number", _mobileNumberController),
                const SizedBox(height: 10),
                _buildDropdownField(Icons.person, "Select User Type"),
                const SizedBox(height: 20),
                Center(
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.teal[900])
                      : _buildButton("Sign Up", Colors.teal[900]!, _signup),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      IconData icon, String hint, TextEditingController controller,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.teal[900]),
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDropdownField(IconData icon, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedUserType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.teal[900]),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.85)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        dropdownColor: Colors.white,
        style: TextStyle(color: Colors.black),
        items: const [
          DropdownMenuItem(value: 'USER', child: Text('Regular User')),
          DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
          DropdownMenuItem(value: 'VOLUNTEER', child: Text('Volunteer')),
        ],
        onChanged: (value) {
          setState(() {
            _selectedUserType = value;
          });
        },
      ),
    );
  }

  Widget _buildButton(String text, Color color, void Function() signup) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 50),
      ),
      onPressed: signup,
      child: Text(text,
          style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
    );
  }
}
