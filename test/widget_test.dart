import 'package:flutter_test/flutter_test.dart';
import 'package:bloodcamp/main.dart';

void main() {
  testWidgets('Blood Camp app loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      const AlkhidmatBloodCampApp(),
    );

    expect(
      find.byType(AlkhidmatBloodCampApp),
      findsOneWidget,
    );
  });
}