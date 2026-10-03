import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/features/locations/controllers/locations_controller.dart';
import 'package:vitago_app/features/locations/models/location.dart';
import 'package:vitago_app/features/locations/models/location_inputs.dart';

class LocationDetailView extends ConsumerWidget {
  const LocationDetailView({
    required this.companyLocation,
    required this.canApprove,
    super.key,
  });

  final CompanyLocation companyLocation;
  final bool canApprove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(
      locationControllerProvider(companyLocation.location.id),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del lugar')),
      body: SafeArea(
        child: detail.when(
          loading: () => const AppLoadingView(label: 'Cargando ubicación…'),
          error: (error, stackTrace) => AppErrorView(
            error: error,
            onRetry: () => ref.invalidate(
              locationControllerProvider(companyLocation.location.id),
            ),
          ),
          data: (location) => _LocationDetails(
            location: location,
            companyLocation: companyLocation,
            canApprove: canApprove,
          ),
        ),
      ),
    );
  }
}

class _LocationDetails extends ConsumerStatefulWidget {
  const _LocationDetails({
    required this.location,
    required this.companyLocation,
    required this.canApprove,
  });

  final Location location;
  final CompanyLocation companyLocation;
  final bool canApprove;

  @override
  ConsumerState<_LocationDetails> createState() => _LocationDetailsState();
}

class _LocationDetailsState extends ConsumerState<_LocationDetails> {
  late bool _allowsOrigin = widget.companyLocation.allowsOrigin;
  late bool _allowsDestination = widget.companyLocation.allowsDestination;
  bool _saving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final location = widget.location;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(location.name, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(location.type?.name ?? 'Ubicación'),
        const SizedBox(height: AppSpacing.lg),
        _DetailRow(label: 'Autorización', value: widget.companyLocation.status),
        _DetailRow(label: 'Dirección', value: location.address),
        if (location.department case final value?)
          _DetailRow(label: 'Departamento', value: value),
        if (location.municipality case final value?)
          _DetailRow(label: 'Municipio', value: value),
        if (location.city case final value?)
          _DetailRow(label: 'Ciudad', value: value),
        if (location.neighborhood case final value?)
          _DetailRow(label: 'Colonia', value: value),
        if (location.countryName case final value?)
          _DetailRow(label: 'País', value: value),
        if (location.latitude case final latitude?)
          _DetailRow(
            label: 'Coordenadas',
            value: '$latitude, ${location.longitude ?? '—'}',
          ),
        if (location.phone case final value?)
          _DetailRow(label: 'Teléfono', value: value),
        if (location.contactName case final value?)
          _DetailRow(label: 'Contacto', value: value),
        if (location.instructions case final value?)
          _DetailRow(label: 'Instrucciones', value: value),
        _DetailRow(
          label: 'Verificación',
          value: location.verified ? 'Verificada' : 'No verificada',
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Usos autorizados', style: Theme.of(context).textTheme.titleLarge),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Origen'),
          value: _allowsOrigin,
          onChanged: widget.canApprove && !_saving
              ? (value) => setState(() => _allowsOrigin = value)
              : null,
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Destino'),
          value: _allowsDestination,
          onChanged: widget.canApprove && !_saving
              ? (value) => setState(() => _allowsDestination = value)
              : null,
        ),
        if (_error case final error?) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            error,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (widget.canApprove) ...[
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _saving ? null : _approve,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.verified_outlined),
            label: const Text('Guardar y aprobar'),
          ),
        ],
      ],
    );
  }

  Future<void> _approve() async {
    if (!_allowsOrigin && !_allowsDestination) {
      setState(() {
        _error = 'Una ubicación aprobada debe permitir origen o destino.';
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(locationActionsControllerProvider)
          .updateAuthorization(
            locationId: widget.location.id,
            companyId: widget.companyLocation.companyId,
            input: LocationAuthorizationInput(
              allowsOrigin: _allowsOrigin,
              allowsDestination: _allowsDestination,
              status: 'APROBADO',
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(value),
        ],
      ),
    );
  }
}
