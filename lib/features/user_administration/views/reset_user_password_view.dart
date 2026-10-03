import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/widgets/form_error_summary.dart';
import 'package:vitago_app/features/user_administration/controllers/users_controller.dart';
import 'package:vitago_app/features/user_administration/models/managed_user.dart';

class ResetUserPasswordView extends ConsumerStatefulWidget {
  const ResetUserPasswordView({required this.user, super.key});

  final ManagedUser user;

  @override
  ConsumerState<ResetUserPasswordView> createState() =>
      _ResetUserPasswordViewState();
}

class _ResetUserPasswordViewState extends ConsumerState<ResetUserPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  String? _error;
  String? _passwordError;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Restablecer contraseña')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.password_outlined, size: 48, color: colors.primary),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Nueva contraseña temporal',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'El cambio cerrará todas las sesiones activas de ${widget.user.fullName}.',
                  textAlign: TextAlign.center,
                ),
                if (_error case final error?) ...[
                  const SizedBox(height: AppSpacing.md),
                  FormErrorSummary(message: error),
                ],
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  controller: _password,
                  enabled: !_saving,
                  obscureText: _obscure,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'Contraseña temporal',
                    errorText: _passwordError,
                    suffixIcon: IconButton(
                      onPressed: _saving
                          ? null
                          : () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      tooltip: _obscure
                          ? 'Mostrar contraseña'
                          : 'Ocultar contraseña',
                    ),
                  ),
                  onChanged: (_) {
                    if (_passwordError != null) {
                      setState(() => _passwordError = null);
                    }
                  },
                  validator: _passwordValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _confirmation,
                  enabled: !_saving,
                  obscureText: _obscure,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña',
                  ),
                  validator: (value) => value != _password.text
                      ? 'Las contraseñas no coinciden.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_reset_outlined),
                  label: const Text('Restablecer contraseña'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _passwordValidator(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Este campo es obligatorio.';
    if (text.length > 128) return 'Usa un máximo de 128 caracteres.';
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
      _passwordError = null;
    });
    try {
      await ref
          .read(userActionsControllerProvider)
          .resetPassword(widget.user.id, _password.text);
      if (mounted) Navigator.of(context).pop(true);
    } on AppFailure catch (failure) {
      if (mounted) {
        setState(() {
          _passwordError = failure.fieldMessage('contrasena_temporal');
          _error = _passwordError == null
              ? failure.message
              : 'Revisa la contraseña marcada.';
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
