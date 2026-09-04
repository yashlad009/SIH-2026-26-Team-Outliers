import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carelink/app.dart';

void main() {
  testWidgets('CareLink App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CareLinkApp(),
      ),
    );
    expect(find.byType(CareLinkApp), findsOneWidget);
  });
}
