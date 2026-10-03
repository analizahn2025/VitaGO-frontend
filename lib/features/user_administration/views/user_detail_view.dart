import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/user_administration/controllers/users_controller.dart';
import 'package:vitago_app/features/user_administration/models/managed_user.dart';
import 'package:vitago_app/features/user_administration/policies/user_management_policy.dart';
import 'package:vitago_app/features/user_administration/views/edit_user_view.dart';
import 'package:vitago_app/features/user_administration/views/reset_user_password_view.dart';
import 'package:vitago_app/features/user_administration/views/user_roles_view.dart';

class UserDetailView extends ConsumerWidget {
  const UserDetailView({
    required this.userId,
    required this.profile,
    required this.usesLocalAuthentication,
    super.key,
  });

  final String userId;
  final UserProfile profile;
  final bool usesLocalAuthentication;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userDetailControllerProvider(userId));
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de usuario')),
      body: SafeArea(
        child: user.when(
          loading: () => const AppLoadingView(label: 'Cargando usuario…'),
          error: (error, stackTrace) => AppErrorView(
            error: error,
            onRetry: () => ref.invalidate(userDetailControllerProvider(userId)),
          ),
          data: (value) => _UserDetailContent(
            user: value,
            profile: profile,
            usesLocalAuthentication: usesLocalAuthentication,
            onChanged: () {
              ref.invalidate(userDetailControllerProvider(userId));
              ref.invalidate(usersControllerProvider);
            },
          ),
        ),
      ),
    );
  }
}

class _UserDetailContent extends StatelessWidget {
  const _UserDetailContent({
    required this.user,
    required this.profile,
    required this.usesLocalAuthentication,
    required this.onChanged,
  });

  final ManagedUser user;
  final UserProfile profile;
  final bool usesLocalAuthentication;
  final VoidCallback onChanged;

  bool get _canManage => UserManagementPolicy.canManage(profile, user);

  bool get _canManageRoles =>
      UserManagementPolicy.canManageRoles(profile, user);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        Container(
          color: colors.primary,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: colors.onPrimary.withValues(alpha: 0.14),
                foregroundColor: colors.onPrimary,
                child: Text(
                  _initials(user),
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(color: colors.onPrimary),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: colors.onPrimary),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: colors.onPrimary.withValues(alpha: 0.86),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'Información de acceso',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  _StatusChip(status: user.status),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailRow(
                icon: Icons.phone_outlined,
                label: 'Teléfono',
                value: user.phone ?? 'No registrado',
              ),
              if (user.createdAt case final value?)
                _DetailRow(
                  icon: Icons.event_outlined,
                  label: 'Creado',
                  value: _date(value),
                ),
              const SizedBox(height: AppSpacing.lg),
              InkWell(
                borderRadius: BorderRadius.circular(AppRadii.control),
                onTap: () => _openRoles(context),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadii.control),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.badge_outlined, color: colors.primary),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Roles y alcances'),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              user.roles.isEmpty
                                  ? 'Sin roles activos'
                                  : '${user.roles.length} asignación${user.roles.length == 1 ? '' : 'es'} activa${user.roles.length == 1 ? '' : 's'}',
                              style: TextStyle(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
              if (_canManage) ...[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Administración',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => _openEdit(context),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar usuario'),
                ),
                if (_canManageRoles) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () => _openRoles(context),
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: const Text('Administrar roles'),
                  ),
                ],
                if (usesLocalAuthentication) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => ResetUserPasswordView(user: user),
                      ),
                    ),
                    icon: const Icon(Icons.lock_reset_outlined),
                    label: const Text('Restablecer contraseña'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openEdit(BuildContext context) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) =>
            EditUserView(user: user, isCurrentUser: profile.user.id == user.id),
      ),
    );
    if (changed == true) onChanged();
  }

  Future<void> _openRoles(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => UserRolesView(user: user, profile: profile),
      ),
    );
    onChanged();
  }

  String _initials(ManagedUser value) {
    final first = value.firstNames.isEmpty ? '' : value.firstNames[0];
    final last = value.lastNames.isEmpty ? '' : value.lastNames[0];
    return '$first$last'.toUpperCase();
  }

  String _date(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: TextStyle(
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final active = status == 'ACTIVO';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: active ? colors.primaryContainer : colors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadii.round),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: active ? colors.onPrimaryContainer : colors.onErrorContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
