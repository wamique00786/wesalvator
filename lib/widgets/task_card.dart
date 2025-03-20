import 'package:flutter/material.dart';
import 'package:wesalvator/screen/Volunteer/task_details%20pages.dart';

class TaskCard extends StatefulWidget {
  final String title;
  final String description;

  const TaskCard({super.key, required this.title, required this.description});

  @override
  TaskCardState createState() => TaskCardState();
}

class TaskCardState extends State<TaskCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title of the task
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            SizedBox(height: 10),

            // Description of the task
            Text(
              widget.description,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            SizedBox(height: 16),

            // Action buttons for the task
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => (TaskDetailsPages()),
                      ),
                    );
                  },
                  child: Text("view details"),
                ),
                ElevatedButton(onPressed: () {}, child: Text("completed")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
