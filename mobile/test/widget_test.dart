import 'package:flutter_test/flutter_test.dart';
import 'package:navgo_mobile/app/app.dart';
import 'package:navgo_mobile/app/routes.dart';
import 'package:navgo_mobile/data/session_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Splash shows NavGo brand then routes to onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final session = SessionRepository(prefs);
    final router = NavGoRoutes.createRouter(session);

    await tester.pumpWidget(App(router: router));
    expect(find.text('NavGo'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('Devam'), findsOneWidget);
  });
}
