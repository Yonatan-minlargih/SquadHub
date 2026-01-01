import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/utils/validation.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/error_banner.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.isAuthenticated) {
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),
                    // Branding Section
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            'S',
                            style: AppTextStyles.h1.copyWith(
                              fontSize: 48,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'SquadHub',
                      style: AppTextStyles.h2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Your squad\'s all-in-one toolkit',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    ErrorBanner(
                      error: state.error,
                      isSuccess:
                          state.error?.toLowerCase().contains('created') ??
                          false,
                    ),

                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: AppTextStyles.bodyMedium,
                        errorText: _emailError,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _emailError != null
                                ? Colors.red
                                : AppColors.textSecondary,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _emailError != null
                                ? Colors.red
                                : AppColors.primary,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.red),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.red),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: AppTextStyles.bodyLarge,
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
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).nextFocus();
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: AppTextStyles.bodyMedium,
                        errorText: _passwordError,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _passwordError != null
                                ? Colors.red
                                : AppColors.textSecondary,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _passwordError != null
                                ? Colors.red
                                : AppColors.primary,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.red),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.red),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: AppTextStyles.bodyLarge,
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
                      onFieldSubmitted: (_) {
                        if (_isFormValid()) {
                          context.read<AuthBloc>().add(
                            AuthLogin(
                              email: ValidationUtils.trimString(
                                _emailController.text,
                              ),
                              password: _passwordController.text,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    PrimaryButton(
                      text: 'Enter Squad',
                      isLoading: state.isLoading,
                      onPressed: () {
                        if (_isFormValid()) {
                          context.read<AuthBloc>().add(
                            AuthLogin(
                              email: ValidationUtils.trimString(
                                _emailController.text,
                              ),
                              password: _passwordController.text,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
