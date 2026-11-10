
import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome, Ministry Member!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF294737),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Register for liturgical activities and manage '
          'your participation in parish celebrations.',
          style: TextStyle(
            fontSize: 15,
            color: Colors.black54,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
