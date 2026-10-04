import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:escaner_1/presentation/widgets/common/empty_state.dart';

void main() {
  group('EmptyState Widget', () {
    testWidgets('muestra título y subtítulo sin icono', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'Title',
              subtitle: 'Subtitle',
            ),
          ),
        ),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Subtitle'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('displays title text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
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
              title: 'Title',
              subtitle: 'Escanea algunos Solapines',
            ),
          ),
        ),
      );

      expect(find.text('Escanea algunos Solapines'), findsOneWidget);
    });

    testWidgets('is centered in parent', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
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
              title: 'Title',
              subtitle: 'Subtitle',
            ),
          ),
        ),
      );

      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
      expect(find.byType(Text), findsNWidgets(2));
    });
  });
}
