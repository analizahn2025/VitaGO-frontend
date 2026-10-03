import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/features/organizations/controllers/organizations_controller.dart';
import 'package:vitago_app/features/organizations/models/branch.dart';

class BranchDetailView extends ConsumerWidget {
  const BranchDetailView({required this.branchId, super.key});

  final String branchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branch = ref.watch(branchControllerProvider(branchId));
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de sucursal')),
      body: SafeArea(
        child: branch.when(
          loading: () => const AppLoadingView(label: 'Cargando sucursal…'),
          error: (error, stackTrace) => AppErrorView(
            error: error,
            onRetry: () => ref.invalidate(branchControllerProvider(branchId)),
          ),
          data: (value) => _BranchDetails(branch: value),
        ),
      ),
    );
  }
}

class _BranchDetails extends StatelessWidget {
  const _BranchDetails({required this.branch});

  final Branch branch;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(branch.name, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        _DetailRow(label: 'Estado', value: branch.status),
        if (branch.code case final value?)
          _DetailRow(label: 'Código', value: value),
        if (branch.phone case final value?)
          _DetailRow(label: 'Teléfono', value: value),
        if (branch.email case final value?)
          _DetailRow(label: 'Correo', value: value),
        if (branch.location case final location?) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Ubicación', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(label: 'Nombre', value: location.name),
          _DetailRow(label: 'Dirección', value: location.address),
          if (location.typeName case final value?)
            _DetailRow(label: 'Tipo', value: value),
          if (location.latitude case final latitude?)
            _DetailRow(
              label: 'Coordenadas',
              value: '$latitude, ${location.longitude ?? '—'}',
            ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
