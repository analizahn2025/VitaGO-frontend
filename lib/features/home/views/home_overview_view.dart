import 'package:flutter/material.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/features/home/models/app_section.dart';
import 'package:vitago_app/features/home/widgets/request_summary_section.dart';
import 'package:vitago_app/features/incidents/views/incidents_view.dart';
import 'package:vitago_app/features/fleet/views/fleet_view.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/shifts/views/shift_history_view.dart';

class HomeOverviewView extends StatelessWidget {
  const HomeOverviewView({
    required this.config,
    required this.profile,
    required this.availableSections,
    required this.onSelectSection,
    super.key,
  });

  final AppConfig config;
  final UserProfile profile;
  final List<AppSection> availableSections;
  final ValueChanged<AppSection> onSelectSection;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final roleSummary = profile.roles.isEmpty
        ? 'Sin roles activos'
        : profile.roles.map((role) => role.name).join(' · ');
    final actions = availableSections
        .where(
          (section) =>
              section != AppSection.home && section != AppSection.account,
        )
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        Container(
          color: colorScheme.primary,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${profile.user.firstNames}',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(color: colorScheme.onPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                profile.company?.name ?? config.appName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimary.withValues(alpha: 0.9),
                ),
              ),
              if (profile.branch case final branch?) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  branch.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.76),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.small),
                ),
                child: Text(
                  roleSummary,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onPrimary),
                ),
              ),
            ],
          ),
        ),
        if (!profile.isDriver &&
            (profile.can(AppPermissions.viewRequests) ||
                profile.can(AppPermissions.viewOwnRequests) ||
                profile.can(AppPermissions.viewAssignedRequests)))
          RequestSummarySection(
            profile: profile,
            onOpenRequests: () => onSelectSection(AppSection.requests),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text(
            'Áreas disponibles',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (actions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Tu sesión está activa. Cuando recibas permisos operativos, '
              'aparecerán aquí las áreas correspondientes.',
            ),
          )
        else
          ...actions.map(
            (section) => ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadii.small),
                ),
                child: Icon(
                  section.icon,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(section.label),
              subtitle: Text(_sectionDescription(section)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onSelectSection(section),
            ),
          ),
        if (profile.can(AppPermissions.viewVehicles) ||
            profile.can(AppPermissions.viewDrivers))
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadii.small),
              ),
              child: Icon(
                Icons.two_wheeler_outlined,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            title: const Text('Flota y motoristas'),
            subtitle: const Text('Vehículos y disponibilidad operativa'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (context) => FleetView(profile: profile),
              ),
            ),
          ),
        if (profile.can(AppPermissions.reviewIncidents))
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(AppRadii.small),
              ),
              child: Icon(
                Icons.report_problem_outlined,
                color: colorScheme.onErrorContainer,
              ),
            ),
            title: const Text('Incidencias'),
            subtitle: const Text('Revisión y cierre de reportes operativos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: const Text('Incidencias')),
                  body: IncidentsView(profile: profile),
                ),
              ),
            ),
          ),
        if (profile.can(AppPermissions.viewShifts) && !profile.isDriver)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadii.small),
              ),
              child: Icon(
                Icons.schedule_outlined,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            title: const Text('Jornadas'),
            subtitle: const Text('Historial operativo de motoristas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (context) => const ShiftHistoryView(),
              ),
            ),
          ),
      ],
    );
  }

  String _sectionDescription(AppSection section) {
    return switch (section) {
      AppSection.organizations => 'Empresas y sucursales autorizadas',
      AppSection.users => 'Usuarios, roles y alcances',
      AppSection.locations => 'Lugares de origen y destino',
      AppSection.requests => 'Traslados, asignaciones y seguimiento',
      AppSection.operations => 'Jornada, servicios asignados y entregas',
      AppSection.history => 'Servicios y jornadas anteriores',
      AppSection.home => 'Resumen de la operación',
      AppSection.account => 'Perfil y seguridad',
    };
  }
}
