import 'package:flutter_test/flutter_test.dart';
import 'package:echeq_app/main.dart';

void main() {
  testWidgets('La aplicación inicia correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(const EcheqApp());

    expect(find.text('Dashboard'), findsOneWidget);
  });
}