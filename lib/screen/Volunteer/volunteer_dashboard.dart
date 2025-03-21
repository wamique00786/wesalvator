// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:wesalvator/nav_section/navbar_main.dart';
import 'package:wesalvator/widgets/task_card.dart';

class VolunteerDashboard extends StatefulWidget {
  const VolunteerDashboard({super.key});

  @override
  VolunteerDashboardState createState() => VolunteerDashboardState();
}

class VolunteerDashboardState extends State<VolunteerDashboard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme dynamically

    return Scaffold(
      drawer: const NavBar(),
      appBar: AppBar(
        title: const Text('Volunteer Dashboard'),
        centerTitle: true,
        elevation: 4,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: theme.scaffoldBackgroundColor, // Clean background
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Tasks",
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  TaskCard(
                    title: "Feed the cats at the shelter",
                    description: "Ensure the cats are well-fed and healthy.",
                  ),
                  const SizedBox(height: 12),
                  TaskCard(
                    title: "Walk the dogs in the park",
                    description:
                        "Provide the dogs a safe walk and ensure they stay hydrated.",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
