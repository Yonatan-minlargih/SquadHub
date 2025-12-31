import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/widgets/error_banner.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../core/utils/validation.dart';

class CreateSquadDialog extends StatefulWidget {
  const CreateSquadDialog({super.key});

  @override
  State<CreateSquadDialog> createState() => _CreateSquadDialogState();
}

class _CreateSquadDialogState extends State<CreateSquadDialog> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _squadNameError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _squadNameError = ValidationUtils.validateSquadName(_nameController.text);
    });
  }

  bool _isFormValid() {
    _validateForm();
    return _squadNameError == null;
  }

  void _submit() {
    if (_isFormValid()) {
      final squadId = 'squad_${const Uuid().v4().substring(0, 8)}';
      context.read<AuthBloc>().add(
        AuthCreateSquad(
          squadName: ValidationUtils.trimString(_nameController.text),
          squadId: squadId,
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
      title: const Text('Create a New Squad'),
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
                  ErrorBanner(error: state.error),
                  Text(
                    'Set a name for your unique squad. You will get a Squad ID to share with friends.',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Squad Name',
                      hintText: 'e.g., The Avengers',
                      prefixIcon: const Icon(Iconsax.edit_2),
                      errorText: _squadNameError,
                      errorMaxLines: 2,
                    ),
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (_squadNameError != null) {
                        setState(() {
                          _squadNameError = ValidationUtils.validateSquadName(
                            _nameController.text,
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
            if (state.squadId != null) {
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
                  : const Text('Create'),
            );
          },
        ),
      ],
    );
  }
}
