import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth pages/login_screen.dart';
import 'package:wesalvator/provider/user_provider.dart';
import 'package:wesalvator/views/career_page.dart';
import 'package:wesalvator/views/contact_us_page.dart';
import 'package:wesalvator/views/organization_page.dart';
import 'package:wesalvator/views/premium_page.dart';
import 'package:wesalvator/views/donation_page.dart';
import 'package:wesalvator/views/adoption_page.dart';
import 'package:wesalvator/views/setting_screen.dart';
import 'package:wesalvator/views/team_page.dart';

class NavBar extends StatelessWidget {
  final padding = const EdgeInsets.symmetric(horizontal: 20);

  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final name = Provider.of<UserProvider>(context).username ?? "Guest";
    final userType = Provider.of<UserProvider>(context).userType ?? "Unknown";
    final imageUrl =
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=634&q=80';

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: ListView(
          children: <Widget>[
            buildHeader(
              context,
              urlImage: imageUrl,
              name: name,
              userType: userType,
              onClicked: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade300, thickness: 1),
            buildMenuSection(context, "Main", [
              buildMenuItem(
                context,
                text: 'Donation',
                icon: Icons.attach_money,
                route: DonationListPage(),
              ),
              buildMenuItem(
                context,
                text: 'Adoption',
                icon: Icons.pets,
                route: AdoptionPage(),
              ),
              buildMenuItem(
                context,
                text: 'Organizations',
                icon: Icons.business,
                route: OrganizationPage(),
              ),
              buildMenuItem(
                context,
                text: 'Premium',
                icon: Icons.workspace_premium,
                route: SubscriptionPlans(),
              ),
            ]),
            Divider(color: Colors.grey.shade300, thickness: 1),
            buildMenuSection(context, "More", [
              buildMenuItem(
                context,
                text: 'Team',
                icon: Icons.people,
                route: TeamPage(),
              ),
              buildMenuItem(
                context,
                text: 'Careers',
                icon: Icons.work,
                route: CareerPage(),
              ),
              buildMenuItem(
                context,
                text: 'Contact Us',
                icon: Icons.contact_mail,
                route: ContactUsPage(),
              ),
              buildMenuItem(
                context,
                text: 'Settings',
                icon: Icons.settings,
                route: SettingsPage(),
              ),
            ]),
            Divider(color: Colors.grey.shade300, thickness: 1),
            buildMenuItem(
              context,
              text: 'Logout',
              icon: Icons.exit_to_app,
              onClicked: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
                Provider.of<UserProvider>(context, listen: false).logout();

                // Navigator.pushReplacement(
                //   context,
                //   MaterialPageRoute(builder: (context) => LoginScreen()),
                // );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHeader(
    BuildContext context, {
    required String urlImage,
    required String name,
    required String userType,
    required VoidCallback onClicked,
  }) {
    final userProvider = Provider.of<UserProvider>(context);
    final profileImagePath = userProvider.profileImagePath;

    return InkWell(
      onTap: onClicked,
      child: Container(
        padding: padding.add(const EdgeInsets.symmetric(vertical: 30)),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            CircleAvatar(
              radius: 35,
              backgroundImage: _getProfileImage(profileImagePath),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userType,
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
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

  Widget buildMenuSection(
    BuildContext context,
    String title,
    List<Widget> items,
  ) {
    return Padding(
      padding: padding.add(const EdgeInsets.symmetric(vertical: 10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ...items,
        ],
      ),
    );
  }

  Widget buildMenuItem(
    BuildContext context, {
    required String text,
    required IconData icon,
    Widget? route,
    VoidCallback? onClicked,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap:
          onClicked ??
          () {
            if (route != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => route),
              );
            }
          },
    );
  }
}
