import 'package:flutter/material.dart';

class DonationListPage extends StatefulWidget {
  const DonationListPage({super.key});

  @override
  _DonationListPageState createState() => _DonationListPageState();
}

class _DonationListPageState extends State<DonationListPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  final List<Map<String, String>> donations = [
    {
      'user': 'admin1',
      'amount': '\$50.00',
      'date': '2025-02-11',
      'ngo': 'Animal Welfare',
    },
    {
      'user': 'admin2',
      'amount': '\$50.00',
      'date': '2025-01-11',
      'ngo': 'Animal Welfare',
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(context),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _titleSection(context),
            SizedBox(height: 10),
            _tableHeader(context),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ListView.builder(
                  itemCount: donations.length,
                  itemBuilder: (context, index) {
                    return _donationRow(context, donations[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// **🔹 App Bar - Styled to Match Previous Page**
  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(
        'Donation List',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      centerTitle: true,
      actions: [
        // Add actions if needed
      ],
    );
  }

  /// **🔹 Page Title Section**
  Widget _titleSection(BuildContext context) {
    return Text(
      'Recent Donations',
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  /// **🔹 Table Header**
  Widget _tableHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children:
            ['User', 'Amount', 'Date', 'NGO']
                .map((title) => _tableText(context, title, isHeader: true))
                .toList(),
      ),
    );
  }

  /// **🔹 Donation Row**
  Widget _donationRow(BuildContext context, Map<String, String> donation) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _tableText(context, donation['user']!),
          _tableText(context, donation['amount']!),
          _tableText(context, donation['date']!),
          _tableText(context, donation['ngo']!),
        ],
      ),
    );
  }

  /// **🔹 Table Cell Text Widget (Reusable)**
  Widget _tableText(
    BuildContext context,
    String text, {
    bool isHeader = false,
  }) {
    return Expanded(
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color:
              isHeader
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
