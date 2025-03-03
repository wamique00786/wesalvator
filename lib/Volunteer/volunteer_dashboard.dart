import 'package:flutter/material.dart';
import 'package:wesalvator/widgets/task_card.dart';

class VolunteerDashboard extends StatefulWidget {
  const VolunteerDashboard({super.key});

  @override
  VolunteerDashboardState createState() => VolunteerDashboardState();
}

class VolunteerDashboardState extends State<VolunteerDashboard> {
  // Function to handle task completion
  // void _completeTask(int taskIndex) {
  //   setState(() {});
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Volunteer Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TaskCard(
              title: "Feed the cats at the shelter",
              description: "Ensure the cats are well-fed and healthy.",
            ),
            SizedBox(height: 16),
            TaskCard(
              title: "Walk the dogs in the park",
              description:
                  "Provide the dogs a safe walk and ensure they stay hydrated.",
            ),
          ],
        ),
      ),
    );
  }
}
