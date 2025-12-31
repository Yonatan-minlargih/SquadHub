import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/widgets/error_banner.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../core/utils/validation.dart';

class SignUpDialog extends StatefulWidget {
  const SignUpDialog({super.key});

  @override
  State<SignUpDialog> createState() => _SignUpDialogState();
}

class _SignUpDialogState extends State<SignUpDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  // final String? _nameError = null;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _emailError = ValidationUtils.validateEmail(_emailController.text);
      _passwordError = ValidationUtils.validatePassword(
        _passwordController.text,
      );
    });
  }

  bool _isFormValid() {
    _validateForm();
    return _emailError == null && _passwordError == null;
  }

  void _submit() {
    if (_isFormValid()) {
      context.read<AuthBloc>().add(
        AuthSignUp(
          name: ValidationUtils.trimString(_nameController.text),
          email: ValidationUtils.trimString(_emailController.text),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: EdgeInsets.zero,
      actionsPadding: const EdgeInsets.all(16),
      title: const Text('Create Account'),
      content: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ErrorBanner(
                    error: state.error,
                    isSuccess:
                        state.error?.toLowerCase().contains('created') ?? false,
                  ),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Your Name',
                      hintText: 'e.g., Tony Stark',
                      prefixIcon: Icon(Iconsax.user),
                    ),
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'your@email.com',
                      prefixIcon: const Icon(Iconsax.sms),
                      errorText: _emailError,
                      errorMaxLines: 2,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_emailError != null) {
                        setState(() {
                          _emailError = ValidationUtils.validateEmail(
                            _emailController.text,
                          );
                        });
                      }
                    },
                    onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Iconsax.lock),
                      errorText: _passwordError,
                      errorMaxLines: 2,
                      helperText: 'Must be at least 8 characters',
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (_passwordError != null) {
                        setState(() {
                          _passwordError = ValidationUtils.validatePassword(
                            _passwordController.text,
                          );
                        });
                      }
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.isAuthenticated) {
              Navigator.of(context).pop();
            }
          },
          builder: (context, state) {
            final theme = Theme.of(context);
            return FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(120, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              onPressed: state.isLoading ? null : _submit,
              child: state.isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : const Text('Sign Up'),
            );
          },
        ),
      ],
    );
  }
}
