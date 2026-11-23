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
    expect(find.byTooltip('Panel de administrador'), findsNothing);

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

    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'adminfish');
    await tester.enterText(find.byType(TextFormField).at(1), 'administrafish');
    await tester.tap(find.text('INICIAR SESIÓN'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Panel de administrador'), findsOneWidget);
    await tester.tap(find.byTooltip('Panel de administrador'));
    await tester.pumpAndSettle();
    expect(find.text('> COMUNICADOS DEL TABLÓN'), findsOneWidget);
    expect(find.text('> CANCIONES Y ENLACES DE VIDEO'), findsNothing);
    await tester.tap(find.text('NUEVO COMUNICADO'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '2026-11-23');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'AVISO ADMIN TEST',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'LA PECERA');
    await tester.enterText(
      find.byType(TextFormField).at(4),
      'Mensaje de prueba',
    );
    await tester.tap(find.text('GUARDAR'));
    await tester.pumpAndSettle();
    expect(find.text('AVISO ADMIN TEST'), findsOneWidget);

    await tester.tap(find.text('CANCIONES / VIDEOS'));
    await tester.pumpAndSettle();
    expect(find.text('> CANCIONES Y ENLACES DE VIDEO'), findsOneWidget);
  });
}
