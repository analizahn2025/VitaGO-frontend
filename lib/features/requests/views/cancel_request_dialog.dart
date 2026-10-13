import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/widgets/form_error_summary.dart';
import 'package:vitago_app/features/requests/controllers/requests_controller.dart';
import 'package:vitago_app/features/requests/models/request_inputs.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';

class CancelRequestDialog extends ConsumerStatefulWidget {
  const CancelRequestDialog({required this.request, super.key});

  final ServiceRequestDetail request;

  @override
  ConsumerState<CancelRequestDialog> createState() =>
      _CancelRequestDialogState();
}

class _CancelRequestDialogState extends ConsumerState<CancelRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  bool _saving = false;
  String? _error;
  String? _reasonError;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        icon: Icon(Icons.cancel_outlined, color: colors.error),
        title: const Text('Cancelar envío'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'La solicitud ${widget.request.number} dejará de estar disponible para la operación. Esta acción debe quedar justificada.',
                  ),
                  if (_error case final error?) ...[
                    const SizedBox(height: AppSpacing.md),
                    FormErrorSummary(message: error),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _reason,
                    enabled: !_saving,
                    autofocus: true,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Motivo de cancelación',
                      hintText: 'Explica por qué se cancela este envío',
                      alignLabelWithHint: true,
                      errorText: _reasonError,
                    ),
                    onChanged: (_) {
                      if (_reasonError == null) return;
                      setState(() => _reasonError = null);
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Escribe el motivo de la cancelación.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Volver'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cancel_outlined),
            label: const Text('Sí, cancelar envío'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
      _reasonError = null;
    });
    try {
      final updated = await ref
          .read(requestActionsControllerProvider)
          .transition(
            widget.request.id,
            RequestTransitionInput(
              targetStatus: 'CANCELLED',
              reason: _reason.text.trim(),
            ),
          );
      if (updated.status.toUpperCase() != 'CANCELLED') {
        throw AppFailure(
          message:
              'El servidor respondió con estado ${updated.status}; se esperaba CANCELLED.',
        );
      }
      if (mounted) Navigator.of(context).pop(updated);
    } on AppFailure catch (failure) {
      if (mounted) {
        setState(() {
          _reasonError = failure.fieldMessage('motivo');
          _error = _reasonError == null ? failure.message : null;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
