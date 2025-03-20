import 'package:flutter/material.dart';

class PriorityButtons extends StatelessWidget {
  final String selectedPriority;
  final Function(String) onPrioritySelected;

  const PriorityButtons({
    super.key,
    required this.selectedPriority,
    required this.onPrioritySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _buildPriorityButton('HIGH', Colors.red),
          const SizedBox(width: 8),
          _buildPriorityButton('MEDIUM', Colors.orange),
          const SizedBox(width: 8),
          _buildPriorityButton('LOW', Colors.green),
        ],
      ),
    );
  }

  Widget _buildPriorityButton(String priority, Color color) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () => onPrioritySelected(priority),
        style: OutlinedButton.styleFrom(
          backgroundColor:
              selectedPriority == priority
                  ? color.withOpacity(0.1)
                  : Colors.transparent,
          side: BorderSide(
            color: selectedPriority == priority ? color : Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          priority,
          style: TextStyle(
            color: selectedPriority == priority ? color : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
