// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wesalvator/provider/themeprovider.dart';
import 'package:wesalvator/provider/user_provider.dart';
import 'package:image_picker/image_picker.dart'; // You'll need to add this package
import 'dart:io';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Appearance",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildDarkModeToggle(context, isDarkMode, themeProvider),
            const SizedBox(height: 30),
            const Text(
              "Profile",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildProfileImageOption(context, userProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkModeToggle(
    BuildContext context,
    bool isDarkMode,
    ThemeProvider themeProvider,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Dark Mode",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Switch(
              value: isDarkMode,
              activeColor: Colors.teal,
              onChanged: (value) {
                themeProvider.setTheme(
                  value ? ThemeMode.dark : ThemeMode.light,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImageOption(
    BuildContext context,
    UserProvider userProvider,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Profile Picture",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                CircleAvatar(
                  radius: 25,
                  backgroundImage: _getProfileImage(
                    userProvider.profileImagePath,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageButton(
                  context,
                  "Gallery",
                  Icons.photo_library,
                  () => _pickImage(ImageSource.gallery, userProvider),
                ),
                _buildImageButton(
                  context,
                  "Camera",
                  Icons.camera_alt,
                  () => _pickImage(ImageSource.camera, userProvider),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  ImageProvider _getProfileImage(String? imagePath) {
    if (imagePath == null || imagePath.startsWith('assets/')) {
      return AssetImage(imagePath ?? "assets/user.png");
    } else {
      return FileImage(File(imagePath));
    }
  }

  Future<void> _pickImage(ImageSource source, UserProvider userProvider) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      userProvider.setProfileImage(image.path);
    }
  }
}
