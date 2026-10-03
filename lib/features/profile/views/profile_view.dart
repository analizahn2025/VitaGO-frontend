import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/features/authentication/controllers/auth_controller.dart';
import 'package:vitago_app/features/fleet/controllers/fleet_controller.dart';
import 'package:vitago_app/features/fleet/models/fleet_models.dart';
import 'package:vitago_app/features/fleet/views/update_driver_operation_view.dart';
import 'package:vitago_app/features/operations/widgets/driver_profile_card.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({required this.profile, super.key});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider).value;
    final isProcessing = authState?.isProcessing ?? false;
    final driverProfile = profile.isDriver
        ? ref.watch(ownDriverProfileControllerProvider)
        : null;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _ProfileIdentityHeader(profile: profile),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SectionHeading(
                icon: Icons.business_outlined,
                title: 'Información de organización',
              ),
              const SizedBox(height: AppSpacing.sm),
              _OrganizationInformation(profile: profile),
              if (driverProfile != null) ...[
                const SizedBox(height: AppSpacing.xl),
                const _SectionHeading(
                  icon: Icons.two_wheeler_outlined,
                  title: 'Mi motocicleta',
                ),
                const SizedBox(height: AppSpacing.sm),
                driverProfile.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => OutlinedButton.icon(
                    onPressed: () =>
                        ref.invalidate(ownDriverProfileControllerProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar motocicleta'),
                  ),
                  data: (driver) => DriverProfileCard(
                    driver: driver,
                    canUpdate: profile.can(
                      AppPermissions.updateOwnDriverStatus,
                    ),
                    onUpdate: () => _openDriverStatus(context, ref, driver),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              const _SectionHeading(
                icon: Icons.badge_outlined,
                title: 'Roles activos',
              ),
              const SizedBox(height: AppSpacing.sm),
              if (profile.roles.isEmpty)
                const Text(
                  'No tienes roles activos. Un administrador debe revisar tu '
                  'acceso.',
                )
              else
                ...profile.roles.map(
                  (role) =>
                      _RoleRow(name: role.name, scope: role.scopeType.label),
                ),
              if (profile.isMasterAdmin) ...[
                const Divider(height: AppSpacing.xl),
                _MasterPermissions(profile: profile),
              ],
              const Divider(height: AppSpacing.xl),
              const _SectionHeading(
                icon: Icons.shield_outlined,
                title: 'Seguridad de la cuenta',
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Controla dónde permanece abierta tu sesión de VitaGo.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (authState?.message case final message?) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton.tonalIcon(
                onPressed: isProcessing
                    ? null
                    : () => ref.read(authControllerProvider.notifier).logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar esta sesión'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: isProcessing
                    ? null
                    : () => _confirmLogoutAll(context, ref),
                icon: const Icon(Icons.phonelink_erase_outlined),
                label: const Text('Cerrar todas las sesiones'),
              ),
              if (isProcessing) ...[
                const SizedBox(height: AppSpacing.md),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLogoutAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar todas las sesiones'),
        content: const Text(
          'Se cerrará el acceso de VitaGo en todos tus dispositivos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesiones'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logoutAll();
    }
  }

  Future<void> _openDriverStatus(
    BuildContext context,
    WidgetRef ref,
    DriverProfile driver,
  ) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) =>
            UpdateDriverOperationView(driver: driver, canUpdateStatus: true),
      ),
    );
    if (updated == true) {
      ref.invalidate(ownDriverProfileControllerProvider);
    }
  }
}

class _ProfileIdentityHeader extends StatelessWidget {
  const _ProfileIdentityHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final phone = profile.user.phone;

    return Container(
      color: colorScheme.primary,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white,
            foregroundColor: colorScheme.primary,
            child: Text(
              _initials(profile.user),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.user.fullName,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(color: colorScheme.onPrimary),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  profile.user.email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.86),
                  ),
                ),
                if (phone != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    phone,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimary.withValues(alpha: 0.74),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(AppRadii.round),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            ),
            child: Text(
              profile.user.status,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(ProfileUser user) {
    final first = user.firstNames.isEmpty ? '' : user.firstNames[0];
    final last = user.lastNames.isEmpty ? '' : user.lastNames[0];
    return '$first$last'.toUpperCase();
  }
}

class _OrganizationInformation extends StatelessWidget {
  const _OrganizationInformation({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          _InformationRow(
            icon: Icons.apartment_outlined,
            label: 'Empresa',
            value: profile.company?.name ?? 'Sin empresa asignada',
          ),
          Divider(
            height: 1,
            indent: 52,
            color: colorScheme.primary.withValues(alpha: 0.12),
          ),
          _InformationRow(
            icon: Icons.storefront_outlined,
            label: 'Sucursal',
            value: profile.branch?.name ?? 'Sin sucursal asignada',
          ),
        ],
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 22, color: colorScheme.primary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
      ],
    );
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({required this.name, required this.scope});

  final String name;
  final String scope;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadii.small),
            ),
            child: Icon(
              Icons.verified_user_outlined,
              size: 21,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Alcance: $scope',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MasterPermissions extends StatelessWidget {
  const _MasterPermissions({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.admin_panel_settings_outlined,
        color: colorScheme.secondary,
      ),
      title: const Text('Permisos vigentes'),
      subtitle: Text('${profile.permissions.length} permisos administrativos'),
      children: profile.permissions
          .map(
            (permission) => ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: AppSpacing.xs),
              leading: Icon(
                Icons.check_circle_outline,
                size: 20,
                color: colorScheme.primary,
              ),
              title: Text(permission),
            ),
          )
          .toList(growable: false),
    );
  }
}
