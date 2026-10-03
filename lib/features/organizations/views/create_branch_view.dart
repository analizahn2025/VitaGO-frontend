import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/features/locations/controllers/locations_controller.dart';
import 'package:vitago_app/features/locations/models/location.dart';
import 'package:vitago_app/features/organizations/controllers/organizations_controller.dart';
import 'package:vitago_app/features/organizations/models/branch.dart';

class CreateBranchView extends ConsumerStatefulWidget {
  const CreateBranchView({
    required this.companyId,
    required this.companyName,
    super.key,
  });

  final String companyId;
  final String companyName;

  @override
  ConsumerState<CreateBranchView> createState() => _CreateBranchViewState();
}

class _CreateBranchViewState extends ConsumerState<CreateBranchView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String? _locationId;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = (companyId: widget.companyId, page: 1, pageSize: 100);
    final locations = ref.watch(locationsControllerProvider(query));

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva sucursal')),
      body: SafeArea(
        child: locations.when(
          loading: () =>
              const AppLoadingView(label: 'Buscando ubicaciones aprobadas…'),
          error: (error, stackTrace) => AppErrorView(
            error: error,
            onRetry: () => ref.invalidate(locationsControllerProvider(query)),
          ),
          data: (result) {
            final approved = result.items
                .where((item) => item.isApproved)
                .toList(growable: false);
            if (approved.isEmpty) {
              return const AppEmptyView(
                icon: Icons.add_location_alt_outlined,
                title: 'Primero registra una ubicación',
                message:
                    'Una sucursal necesita una ubicación activa y aprobada '
                    'para esta empresa.',
              );
            }
            return _buildForm(approved);
          },
        ),
      ),
    );
  }

  Widget _buildForm(List<CompanyLocation> approvedLocations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.companyName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text('La ubicación debe estar aprobada para esta empresa.'),
            if (_error case final error?) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _nameController,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: _required,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _codeController,
              enabled: !_saving,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Código',
                hintText: 'TGU-01',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _locationId,
              decoration: const InputDecoration(labelText: 'Ubicación'),
              items: approvedLocations
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.location.id,
                      child: Text(
                        item.location.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _locationId = value),
              validator: (value) =>
                  value == null ? 'Selecciona una ubicación aprobada.' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _phoneController,
              enabled: !_saving,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _emailController,
              enabled: !_saving,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo'),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isNotEmpty && !text.contains('@')) {
                  return 'Ingresa un correo válido.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_business_outlined),
              label: const Text('Crear sucursal'),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty
        ? 'Este campo es obligatorio.'
        : null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(organizationActionsControllerProvider)
          .createBranch(
            companyId: widget.companyId,
            input: CreateBranchInput(
              name: _nameController.text,
              code: _codeController.text,
              locationId: _locationId!,
              phone: _phoneController.text,
              email: _emailController.text,
            ),
          );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on AppFailure catch (failure) {
      if (mounted) {
        setState(() => _error = failure.message);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
