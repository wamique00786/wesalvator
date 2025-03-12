// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

class OrganizationPage extends StatelessWidget {
  final List<Map<String, String>> organizations = [
    {
      "name": "Animal Welfare Society",
      "description": "Dedicated to the rescue and rehabilitation of animals.",
      "website": "https://example.com",
    },
    {
      "name": "Save the Animals",
      "description": "Working towards the protection of endangered species.",
      "website": "https://example.com",
    },
    {
      "name": "Pet Rescue Foundation",
      "description":
          "A non-profit organization focused on rescuing pets in need.",
      "website": "https://example.com",
    },
    {
      "name": "Wildlife Conservation Society",
      "description": "Committed to conserving wildlife and wild places.",
      "website": "https://example.com",
    },
    {
      "name": "Humane Society International",
      "description": "Working for the welfare of animals worldwide.",
      "website": "https://example.com",
    },
  ];

  OrganizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(context),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: organizations.length,
          itemBuilder: (context, index) {
            return _organizationCard(context, organizations[index]);
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(
        "Organizations",
        style: Theme.of(context).textTheme.titleLarge,
      ),
      centerTitle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
    );
  }

  Widget _organizationCard(BuildContext context, Map<String, String> org) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(org["name"]!, style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 5),
            Text(
              org["description"]!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => _launchURL(org["website"]!),
                  icon: Icon(
                    Icons.public,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: Text(
                    "Visit Website",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => _showDonationPopup(context, org["name"]!),
                  child: Text("Donate"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      debugPrint("Could not launch $url");
    }
  }

  void _showDonationPopup(BuildContext context, String organizationName) {
    TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Donate to $organizationName",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Enter Amount",
                  labelStyle: Theme.of(context).textTheme.bodyLarge,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Donated \$${amountController.text} to $organizationName",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Text("Donate"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
