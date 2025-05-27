// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pigeon_nutrition_apk/main.dart';
import 'package:pigeon_nutrition_apk/models/aliment.dart';
import 'package:pigeon_nutrition_apk/models/unite_base.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });

  test('Test du modèle Aliment', () {
    final aliment = Aliment(
      id: '1',
      nom: 'Maïs',
      unite: UniteBase.gramme,
      prixUnitaire: 1.5,
      devise: 'EUR',
      gestionStock: true,
      quantiteStock: 1000,
      quantiteAchatParDefaut: 1000,
      calories: 365,
      proteines: 9.4,
      lipides: 4.7,
      glucides: 74,
    );

    expect(aliment.nom, 'Maïs');
    expect(aliment.unite.symbole, 'g');
    expect(aliment.quantiteStock, 1000);

    // Test de l'ajustement du stock
    aliment.ajusterStock(-100);
    expect(aliment.quantiteStock, 900);

    // Test de la conversion en Map
    final map = aliment.toMap();
    expect(map['nom'], 'Maïs');
    expect(map['unite'], 'g');
    expect(map['quantiteStock'], 900);

    // Test de la création depuis une Map
    final aliment2 = Aliment.fromMap(map);
    expect(aliment2.nom, 'Maïs');
    expect(aliment2.unite.symbole, 'g');
    expect(aliment2.quantiteStock, 900);
  });
}
