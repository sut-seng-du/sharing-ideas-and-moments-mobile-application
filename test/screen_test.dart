import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sim/models/message.dart';
import 'package:sim/screens/detail_screen.dart';
import 'package:sim/screens/message_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize FFI for database testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Screen Widget Tests', () {
    final testMessage = Message(
      id: 1,
      title: 'Detail Title',
      content: 'Detail Content',
      createdAt: DateTime.now(),
      isUploaded: true,
    );

    testWidgets('DetailScreen displays message title and content', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: DetailScreen(messageId: 1, initialMessage: testMessage),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Detail Title'), findsOneWidget);
      expect(find.text('Detail Content'), findsOneWidget);
      
      // Verify Uploaded badge is visible since isUploaded is true
      expect(find.text('Uploaded on X'), findsOneWidget);
    });

    testWidgets('MessageScreen displays correct title for new moment', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: MessageScreen(),
      ));

      expect(find.text('New Moments'), findsOneWidget);
    });

    testWidgets('MessageScreen displays correct title for editing moment', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MessageScreen(message: testMessage),
      ));

      expect(find.text('Edit Moments'), findsOneWidget);
    });
  });
}
