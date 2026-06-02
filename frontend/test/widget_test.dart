import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_portal/app.dart';

void main() {
  testWidgets('app boots on the onboarding screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TutorPortalApp()));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('onboarding_get_started_button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('onboarding_sign_in_button')),
      findsOneWidget,
    );
    expect(find.text('Find Your Perfect Tutor'), findsOneWidget);
  });

  testWidgets('tapping "I Already Have an Account" shows the email login',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TutorPortalApp()));
    await tester.pump();

    final signIn = find.byKey(const ValueKey('onboarding_sign_in_button'));
    await tester.ensureVisible(signIn);
    await tester.pumpAndSettle();
    await tester.tap(signIn);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('login_email_field')), findsOneWidget);
    expect(find.byKey(const ValueKey('login_password_field')), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
