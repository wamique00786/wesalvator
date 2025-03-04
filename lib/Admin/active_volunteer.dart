import 'package:flutter/material.dart';

class ActiveVolunteersScreen extends StatefulWidget {
  const ActiveVolunteersScreen({super.key});

  @override
  ActiveVolunteersScreenState createState() => ActiveVolunteersScreenState();
}

class ActiveVolunteersScreenState extends State<ActiveVolunteersScreen> {
  final List<Map<String, String>> volunteers = [
    {
      "username": "Volunteer1",
      "email": "volunteer1@gmail.com",
      "location": "Not Specified"
    },
    {
      "username": "Volunteer2",
      "email": "volunteer2@gmail.com",
      "location": "Not Specified"
    },
    {
      "username": "Volunteer3",
      "email": "volunteer3@gmail.com",
      "location": "Not Specified"
    },
    {
      "username": "Volunteer4",
      "email": "volunteer4@gmail.com",
      "location": "Not Specified"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wesalvatore', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Volunteers',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  border: TableBorder.all(color: Colors.grey),
                  columns: const [
                    DataColumn(label: Text('Username')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Location')),
                    DataColumn(label: Text('Action')),
                  ],
                  rows: volunteers
                      .map((volunteer) => DataRow(cells: [
                            DataCell(Text(volunteer["username"]!)),
                            DataCell(Text(volunteer["email"]!)),
                            DataCell(Text(volunteer["location"]!)),
                            DataCell(
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal[700],
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {},
                                child: const Text('View'),
                              ),
                            ),
                          ]))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
