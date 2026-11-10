
import 'package:flutter/material.dart';

class MinistryRoleSelector extends StatelessWidget {
  final List<String> roles;
  final String selectedRole;
  final ValueChanged<String> onChanged;

  const MinistryRoleSelector({
    super.key,
    required this.roles,
    required this.selectedRole,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Your Ministry Role',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: selectedRole,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.groups_outlined),
                labelText: 'Ministry Role',
              ),
              items: roles.map((role) {
                return DropdownMenuItem<String>(
                  value: role,
                  child: Text(role),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onChanged(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
