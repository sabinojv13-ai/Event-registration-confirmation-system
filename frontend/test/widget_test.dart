
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('Liturgical Ministry dashboard loads',
      (WidgetTester tester) async {
    await tester.pumpWidget(const LiturgicalMinistryApp());

    // Verify the main dashboard.
    expect(find.text('Liturgical Ministry'), findsOneWidget);
    expect(find.text('Welcome, Ministry Member!'), findsOneWidget);
    expect(find.text('Select Your Ministry Role'), findsOneWidget);
    expect(find.text('Upcoming Activities'), findsOneWidget);
    expect(find.text('No Activities Available Yet'), findsOneWidget);

    // Open the dropdown to display all available ministry roles.
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    expect(find.text('Choir'), findsWidgets);
    expect(find.text('Lectors'), findsOneWidget);
    expect(find.text('Commentators'), findsOneWidget);
    expect(find.text('Altar Servers'), findsOneWidget);
  });
}