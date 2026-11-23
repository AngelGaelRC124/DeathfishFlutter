// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deathfishflutter/main.dart';

void main() {
  testWidgets('guest can enter the terminal app', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const DeathfishApp());
    await tester.pumpAndSettle();

    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    await tester.tap(find.text('ENTRAR COMO INVITADO'));
    await tester.pumpAndSettle();

    expect(find.text('ACCESO INVITADO // LA PECERA RECORDS'), findsOneWidget);
    expect(find.text('> COMUNICADOS RECIENTES'), findsOneWidget);

    await tester.tap(find.text('MERCH'));
    await tester.pumpAndSettle();
    expect(find.text('> MERCH OFICIAL'), findsOneWidget);
    await tester.tap(find.text('AGREGAR').first);
    await tester.pumpAndSettle();
    expect(find.text('CARRITO (1)'), findsOneWidget);
    await tester.tap(find.text('CARRITO (1)'));
    await tester.pumpAndSettle();
    expect(find.text('\$300.00'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('ARCHIVO'));
    await tester.pumpAndSettle();
    expect(find.text('wow&flutter'), findsOneWidget);
    await tester.tap(find.text('wow&flutter'));
    await tester.pumpAndSettle();
    expect(find.textContaining('INICIANDO ARCHIVO DE TEXTO'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('STREAM'));
    await tester.pumpAndSettle();
    expect(find.text('> STREAM / TRANSMISIONES'), findsOneWidget);
    await tester.tap(find.text('CONTACTO'));
    await tester.pumpAndSettle();
    expect(find.text('NOMBRE / ORGANIZACIÓN'), findsOneWidget);
  });
}
