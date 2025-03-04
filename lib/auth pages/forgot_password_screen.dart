import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // backgroundColor: Color.fromRGBO(196, 155, 6, 0),
        appBar: AppBar(
          title: Text("Forgot Password",
              style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.teal[900],
        ),
        body: Stack(
          children: [
            Positioned.fill(
                child: Image.asset(
              "assets/plainyellow.jpg",
              fit: BoxFit.fill,
            )),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 45,
                  ),
                  Text(
                    "Enter your email to reset password",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 18, color: Colors.teal[900]),
                  ),
                  SizedBox(height: 20),
                  _buildTextField(Icons.email, "Email"),
                  SizedBox(height: 20),
                  _buildButton("Send Reset Link", Colors.teal[900]!),
                ],
              ),
            ),
          ],
        ));
  }

  Widget _buildTextField(IconData icon, String hint) {
    return TextField(
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

  Widget _buildButton(String text, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 50),
      ),
      onPressed: () {},
      child: Text(text,
          style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
    );
  }
}
