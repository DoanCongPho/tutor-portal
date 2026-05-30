import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(authControllerProvider.notifier);
    await controller.startLogin(_phoneController.text.trim());
    if (!mounted) return;
    final state = ref.read(authControllerProvider);
    if (state.otpSent && state.errorMessage == null) {
      context.go(AppRoutes.verify);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    ref.listen(authControllerProvider.select((s) => s.errorMessage), (_, msg) {
      if (msg == null) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      ref.read(authControllerProvider.notifier).clearError();
    });

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final hPadding = constraints.maxWidth >= 600 ? 40.0 : 24.0;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: hPadding,
                    vertical: 24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        const _BrandHeader(),
                        const SizedBox(height: 40),
                        Text(
                          'Welcome',
                          style: text.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                            height: 1.05,
                          ),
                        ),
                        Text(
                          'back.',
                          style: text.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.primary,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Sign in with your phone number to continue.',
                          style: text.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          key: const ValueKey('login_phone_field'),
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          style: text.bodyLarge,
                          decoration: InputDecoration(
                            labelText: 'Phone number',
                            hintText: '0901234567',
                            prefixIcon: Icon(
                              Icons.phone_iphone_rounded,
                              color: scheme.primary,
                            ),
                            // Auth-screen input variant per docs/design-system.md §5.3 —
                            // brand-tinted fill so the warm cast carries.
                            fillColor: scheme.primaryContainer.withValues(alpha: 0.35),
                          ),
                          validator: _validatePhone,
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          key: const ValueKey('login_submit_button'),
                          onPressed: state.isLoading ? null : _submit,
                          child: state.isLoading
                              ? SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: scheme.onPrimary,
                                  ),
                                )
                              : const Text('Send code'),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'New here?',
                              style: text.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            TextButton(
                              onPressed: state.isLoading
                                  ? null
                                  : () => context.go(AppRoutes.register),
                              child: const Text('Create an account'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.school_rounded,
            color: scheme.onPrimary,
            size: 32,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Tutor Portal',
          style: text.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

String? _validatePhone(String? value) {
  if (value == null || value.trim().isEmpty) return 'Phone is required';
  if (value.trim().length < 8) return 'Phone looks too short';
  return null;
}
