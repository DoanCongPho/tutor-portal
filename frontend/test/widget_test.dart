import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_portal/app.dart';

void main() {
  testWidgets('app boots and shows the login screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TutorPortalApp()));
    await tester.pump();
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
