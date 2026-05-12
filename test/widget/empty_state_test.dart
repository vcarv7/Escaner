import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:escaner_1/presentation/widgets/common/empty_state.dart';

void main() {
  group('EmptyState Widget', () {
    testWidgets('displays icon with correct size', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'Title',
              subtitle: 'Subtitle',
            ),
          ),
        ),
      );

      final iconFinder = find.byIcon(Icons.inbox);
      expect(iconFinder, findsOneWidget);

      final iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.size, equals(48));
    });

    testWidgets('displays title text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No hay elementos',
              subtitle: 'Subtitle',
            ),
          ),
        ),
      );

      expect(find.text('No hay elementos'), findsOneWidget);
    });

    testWidgets('displays subtitle text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'Title',
              subtitle: 'Escanea algunos códigos',
            ),
          ),
        ),
      );

      expect(find.text('Escanea algunos códigos'), findsOneWidget);
    });

    testWidgets('applies custom icon color', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.search_off,
              title: 'Title',
              subtitle: 'Subtitle',
              iconColor: Colors.red,
            ),
          ),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.search_off));
      expect(iconWidget.color?.value, equals(Colors.red.withAlpha(204).value));
    });

    testWidgets('is centered in parent', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'Title',
              subtitle: 'Subtitle',
            ),
          ),
        ),
      );

      expect(find.byType(Center), findsAtLeastNWidgets(1));
    });

    testWidgets('has correct structure with Column', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'Title',
              subtitle: 'Subtitle',
            ),
          ),
        ),
      );

      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
      expect(find.byType(Text), findsNWidgets(2));
    });
  });
}