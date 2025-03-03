import 'package:flutter/material.dart';
import 'package:wesalvator/Admin/recent_animals.dart';
import 'package:wesalvator/Admin/active_volunteer.dart';
import 'package:wesalvator/views/navbar.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  AdminDashboardState createState() => AdminDashboardState();
}

class AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 2,
        centerTitle: true,
        title: Text(
          'Admin Dashboard',
          style: theme.textTheme.headlineSmall!
              .copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.menu, color: colorScheme.primary),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const NavBar()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDashboardHeader(theme),
            const SizedBox(height: 20),
            Expanded(child: _buildDashboardGrid(theme)),
            const SizedBox(height: 20),
            _buildActionButtons(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHeader(ThemeData theme) {
    return Column(
      children: [
        Text(
          "Overview",
          style:
              theme.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Divider(
            color: theme.colorScheme.primary,
            thickness: 2,
            indent: 50,
            endIndent: 50),
      ],
    );
  }

  Widget _buildDashboardGrid(ThemeData theme) {
    List<Map<String, dynamic>> data = [
      {'title': 'Total Animals', 'value': '12', 'icon': Icons.pets},
      {'title': 'Under Treatment', 'value': '5', 'icon': Icons.healing},
      {'title': 'Recovered', 'value': '7', 'icon': Icons.favorite},
      {'title': 'Total Volunteers', 'value': '3', 'icon': Icons.group},
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: data.length,
      itemBuilder: (context, index) {
        return _buildDashboardCard(
          title: data[index]['title'],
          value: data[index]['value'],
          icon: data[index]['icon'],
          theme: theme,
        );
      },
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String value,
    required IconData icon,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.primary),
            const SizedBox(height: 10),
            Text(
              title,
              style: theme.textTheme.bodyMedium!
                  .copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildButton(context, 'Recent Animals', () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => RecentAnimalsScreen()));
        }, theme),
        _buildButton(context, 'Active Volunteers', () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ActiveVolunteersScreen()));
        }, theme),
      ],
    );
  }

  Widget _buildButton(
      BuildContext context, String label, VoidCallback onTap, ThemeData theme) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      onPressed: onTap,
      child: Text(
        label,
        style: theme.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
