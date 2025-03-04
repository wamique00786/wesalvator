import 'package:flutter/material.dart';

class TeamPage extends StatelessWidget {
  final List<Map<String, String>> teamMembers = [
    {
      "name": "John Doe",
      "role": "Project Manager",
      "image": "assets/profile1.jpg"
    },
    {
      "name": "Jane Smith",
      "role": "Lead Developer",
      "image": "assets/profile2.jpg"
    },
    {
      "name": "Emily Johnson",
      "role": "UI/UX Designer",
      "image": "assets/profile3.jpg"
    },
    {
      "name": "Michael Brown",
      "role": "Backend Developer",
      "image": "assets/profile1.jpg"
    },
    {
      "name": "Sarah Wilson",
      "role": "QA Engineer",
      "image": "assets/profile2.jpg"
    },
  ];

  TeamPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Wesalvatore",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.primary,
        leading: Icon(
          Icons.pets,
          color: Theme.of(context).colorScheme.primary,
        ),
        actions: [
          IconButton(
            icon:
                Icon(Icons.menu, color: Theme.of(context).colorScheme.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.9,
          ),
          itemCount: teamMembers.length,
          itemBuilder: (context, index) {
            final member = teamMembers[index];
            return Card(
              color: Theme.of(context).colorScheme.surface,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundImage: AssetImage(member["image"]!),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    member["name"]!,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    member["role"]!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
