import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:escaner_1/presentation/widgets/common/connection_indicator.dart';

void main() {
  group('ConnectionIndicator Widget', () {
    testWidgets('displays connected icon when isConnected is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionIndicator(
              isConnected: true,
              isLoading: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });

    testWidgets('displays disconnected icon when isConnected is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionIndicator(
              isConnected: false,
              isLoading: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('displays loading indicator when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionIndicator(
              isConnected: true,
              isLoading: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('calls onTap when button is pressed', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionIndicator(
              isConnected: true,
              isLoading: false,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('does not call onTap when loading', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionIndicator(
              isConnected: true,
              isLoading: true,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('has tooltip', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionIndicator(
              isConnected: true,
              isLoading: false,
              onTap: () {},
              lastCheck: DateTime(2024, 1, 1, 14, 30),
            ),
          ),
        ),
      );

      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('uses correct colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionIndicator(
              isConnected: true,
              isLoading: false,
              onTap: () {},
            ),
          ),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.cloud_done));
      expect(iconWidget.color, equals(Colors.green));
    });
  });
}