import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sim/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize FFI for database testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('Home screen displays SIM title and Add button', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('SIM'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('Home screen displays search components', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(); // Allow first frame to render

    // Verify search bar exists
    expect(find.byType(TextField), findsOneWidget);

    // Verify category list area exists
    expect(find.byType(SizedBox), findsAtLeastNWidgets(1));
  });
}
