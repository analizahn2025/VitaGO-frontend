import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/features/user_administration/controllers/users_controller.dart';
import 'package:vitago_app/features/user_administration/models/managed_user.dart';
import 'package:vitago_app/features/user_administration/models/update_user_input.dart';

class EditUserView extends ConsumerStatefulWidget {
  const EditUserView({
    required this.user,
    required this.isCurrentUser,
    super.key,
  });

  final ManagedUser user;
  final bool isCurrentUser;

  @override
  ConsumerState<EditUserView> createState() => _EditUserViewState();
}

class _EditUserViewState extends ConsumerState<EditUserView> {
  static const _statuses = ['ACTIVO', 'INACTIVO', 'SUSPENDIDO'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNames;
  late final TextEditingController _lastNames;
  late final TextEditingController _phone;
  late String _status;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _firstNames = TextEditingController(text: widget.user.firstNames);
    _lastNames = TextEditingController(text: widget.user.lastNames);
    _phone = TextEditingController(text: widget.user.phone);
    _status = widget.user.status;
  }

  @override
  void dispose() {
    _firstNames.dispose();
    _lastNames.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar usuario')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Información personal',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  widget.user.email,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_error case final error?) ...[
                  const SizedBox(height: AppSpacing.md),
                  _InlineError(message: error),
                ],
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _firstNames,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Nombres'),
                  validator: _required,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _lastNames,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Apellidos'),
                  validator: _required,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _phone,
                  enabled: !_saving,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Acceso', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: _statuses.contains(_status) ? _status : null,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: _statuses
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(_statusLabel(status)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _saving || widget.isCurrentUser
                      ? null
                      : (value) {
                          if (value != null) setState(() => _status = value);
                        },
                ),
                if (widget.isCurrentUser) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'No puedes suspender ni inactivar tu propia cuenta.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ] else ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Suspender o inactivar cerrará todas las sesiones activas de esta persona.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Guardar cambios'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'Este campo es obligatorio.'
      : null;

  String _statusLabel(String status) => switch (status) {
    'ACTIVO' => 'Activo',
    'INACTIVO' => 'Inactivo',
    'SUSPENDIDO' => 'Suspendido',
    _ => status,
  };

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(userActionsControllerProvider)
          .updateUser(
            widget.user.id,
            UpdateUserInput(
              firstNames: _firstNames.text,
              lastNames: _lastNames.text,
              phone: _phone.text,
              status: _status,
            ),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadii.small),
      ),
      child: Text(message, style: TextStyle(color: colors.onErrorContainer)),
    );
  }
}
