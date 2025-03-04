import 'package:flutter/material.dart';

class RecentAnimalsScreen extends StatelessWidget {
  final List<Map<String, String>> animals = [
    {"name": "Parrot", "species": "Bird", "status": "RESCUED"},
    {"name": "Dog", "species": "Dog", "status": "RESCUED"},
    {"name": "Hen", "species": "Bird", "status": "RESCUED"},
    {"name": "Cat", "species": "Cat", "status": "RESCUED"},
  ];

  RecentAnimalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Wesalvatore',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Animals',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  border: TableBorder.all(color: Colors.grey),
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Species')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Action')),
                  ],
                  rows: animals
                      .map(
                        (animal) => DataRow(cells: [
                          DataCell(Text(animal["name"]!)),
                          DataCell(Text(animal["species"]!)),
                          DataCell(
                            Text(
                              animal["status"]!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ),
                          DataCell(
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal[900],
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('View'),
                            ),
                          ),
                        ]),
                      )
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
