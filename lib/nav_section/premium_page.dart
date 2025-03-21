import 'package:flutter/material.dart';

class SubscriptionPlans extends StatefulWidget {
  const SubscriptionPlans({super.key});

  @override
  SubscriptionPlansState createState() => SubscriptionPlansState();
}

class SubscriptionPlansState extends State<SubscriptionPlans> {
  bool isAnnual = true;

  final List<Map<String, dynamic>> annualPlans = [
    {
      'name': 'Bronze Plan',
      'price': '₹5000.00',
      'facilities': ['Basic consultation', 'Emergency assistance'],
      'buttonText': 'Buy Bronze',
      'color': Colors.brown[300],
    },
    {
      'name': 'Silver Plan',
      'price': '₹10000.00',
      'facilities': ['Basic consultation', 'Emergency assistance'],
      'buttonText': 'Buy Silver',
      'color': Colors.grey[400],
    },
    {
      'name': 'Gold Plan',
      'price': '₹15000.00',
      'facilities': [
        'Basic consultation',
        'Emergency assistance',
        'Priority support',
        'Exclusive discounts'
      ],
      'buttonText': 'Buy Gold',
      'color': Colors.amber[700],
      'isPopular': true,
    },
  ];

  final List<Map<String, dynamic>> monthlyPlans = [
    {
      'name': 'Bronze Plan',
      'price': '₹500.00',
      'facilities': ['Basic consultation', 'Emergency assistance'],
      'buttonText': 'Buy Bronze',
      'color': Colors.brown[300],
    },
    {
      'name': 'Silver Plan',
      'price': '₹1000.00',
      'facilities': ['Basic consultation', 'Emergency assistance'],
      'buttonText': 'Buy Silver',
      'color': Colors.grey[400],
    },
    {
      'name': 'Gold Plan',
      'price': '₹1500.00',
      'facilities': [
        'Basic consultation',
        'Emergency assistance',
        'Priority support',
        'Exclusive discounts'
      ],
      'buttonText': 'Buy Gold',
      'color': Colors.amber[700],
      'isPopular': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> currentPlans =
        isAnnual ? annualPlans : monthlyPlans;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        backgroundColor: const Color.fromARGB(255, 204, 231, 225),
        automaticallyImplyLeading: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ToggleButtons(
                isSelected: [!isAnnual, isAnnual],
                selectedColor: Colors.white,
                fillColor: Colors.teal[600],
                borderRadius: BorderRadius.circular(8),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Monthly'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Annually'),
                  ),
                ],
                onPressed: (index) {
                  setState(() {
                    isAnnual = index == 1;
                  });
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: currentPlans.length,
                  itemBuilder: (context, index) {
                    final plan = currentPlans[index];

                    Color buttonColor;
                    switch (plan['name']) {
                      case 'Bronze Plan':
                        buttonColor = Colors.brown[800]!;
                        break;
                      case 'Silver Plan':
                        buttonColor = Colors.grey[600]!;
                        break;
                      case 'Gold Plan':
                        buttonColor = Colors.amber[700]!;
                        break;
                      default:
                        buttonColor = Colors.blue;
                    }

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              plan['color']!.withOpacity(0.8),
                              plan['color']!.withOpacity(0.4),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (plan['isPopular'] == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[800],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Most Popular',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 10),
                              Text(
                                plan['name'],
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${isAnnual ? 'Annually' : 'Monthly'}: ${plan['price']}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...plan['facilities'].map<Widget>((facility) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle,
                                          color: Colors.white, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        facility,
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  plan['buttonText'],
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
