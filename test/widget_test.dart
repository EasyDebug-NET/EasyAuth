import 'package:flutter_test/flutter_test.dart';

import 'package:easyauth/main.dart';
import 'package:easyauth/providers/locale_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final localeProvider = LocaleProvider();
    await localeProvider.loadLocale();

    await tester.pumpWidget(MyApp(localeProvider: localeProvider));
    await tester.pump();

    expect(find.byType(MyApp), findsOneWidget);
  });
}
