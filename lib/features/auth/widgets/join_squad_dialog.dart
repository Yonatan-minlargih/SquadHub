import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/widgets/error_banner.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../core/utils/validation.dart';

class JoinSquadDialog extends StatefulWidget {
  const JoinSquadDialog({super.key});

  @override
  State<JoinSquadDialog> createState() => _JoinSquadDialogState();
}

class _JoinSquadDialogState extends State<JoinSquadDialog> {
  final _squadIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _squadIdError;

  @override
  void dispose() {
    _squadIdController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _squadIdError = ValidationUtils.validateSquadId(_squadIdController.text);
    });
  }

  bool _isFormValid() {
    _validateForm();
    return _squadIdError == null;
  }

  void _submit() {
    if (_isFormValid()) {
      context.read<AuthBloc>().add(
        AuthJoinSquad(ValidationUtils.trimString(_squadIdController.text)),
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
      title: const Text('Join Existing Squad'),
      content: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ErrorBanner(error: state.error),
                  Text(
                    'Enter the unique Squad ID provided by your team leader.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _squadIdController,
                    decoration: InputDecoration(
                      labelText: 'Squad ID',
                      hintText: 'e.g., squad_12345',
                      prefixIcon: const Icon(Iconsax.key),
                      errorText: _squadIdError,
                      errorMaxLines: 2,
                    ),
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (_squadIdError != null) {
                        setState(() {
                          _squadIdError = ValidationUtils.validateSquadId(
                            _squadIdController.text,
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
                  : const Text('Join'),
            );
          },
        ),
      ],
    );
  }
}
