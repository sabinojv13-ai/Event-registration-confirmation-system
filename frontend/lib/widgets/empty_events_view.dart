
import 'package:flutter/material.dart';

class EmptyEventsView extends StatelessWidget {
  const EmptyEventsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 36,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E6E0)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 52,
            color: Color(0xFF78917E),
          ),
          SizedBox(height: 16),
          Text(
            'No Activities Available Yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF294737),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Upcoming liturgical activities will appear here '
            'when they become available.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
