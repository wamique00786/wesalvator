import 'package:flutter/material.dart';

class ContactUsPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();

  ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Contact Us",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      SizedBox(height: 15),

                      // Name Field
                      TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.person,
                              color: Theme.of(context).colorScheme.primary),
                          labelText: "Your Name",
                          labelStyle: Theme.of(context).textTheme.bodyLarge,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "Please enter your name" : null,
                      ),
                      SizedBox(height: 15),

                      // Email Field
                      TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.email,
                              color: Theme.of(context).colorScheme.primary),
                          labelText: "Email",
                          labelStyle: Theme.of(context).textTheme.bodyLarge,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) =>
                            value!.isEmpty || !value.contains("@")
                                ? "Enter a valid email"
                                : null,
                      ),
                      SizedBox(height: 15),

                      // Message Field
                      TextFormField(
                        maxLines: 4,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.message,
                              color: Theme.of(context).colorScheme.primary),
                          labelText: "Your Message",
                          labelStyle: Theme.of(context).textTheme.bodyLarge,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "Message cannot be empty" : null,
                      ),
                      SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Message Sent Successfully!"),
                                ),
                              );
                            }
                          },
                          child: Text(
                            "Send Message",
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Contact Details
                      Column(
                        children: [
                          ContactInfo(
                            icon: Icons.phone,
                            text: "+123 456 7890",
                          ),
                          ContactInfo(
                            icon: Icons.email,
                            text: "support@example.com",
                          ),
                          ContactInfo(
                            icon: Icons.location_on,
                            text: "123 Street, City, Country",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Reusable Contact Info Row
class ContactInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const ContactInfo({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          SizedBox(width: 10),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
