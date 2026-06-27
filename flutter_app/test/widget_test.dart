import 'package:flutter_test/flutter_test.dart';
import 'package:waste_glass_app/main.dart';

void main() {
  testWidgets('app starts with route screen', (tester) async {
    await tester.pumpWidget(const WasteGlassApp());

    expect(find.text("Today's Route"), findsOneWidget);
  });
}
