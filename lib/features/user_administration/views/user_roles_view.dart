import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/user_administration/controllers/users_controller.dart';
import 'package:vitago_app/features/user_administration/models/managed_user.dart';
import 'package:vitago_app/features/user_administration/models/user_role_assignment.dart';
import 'package:vitago_app/features/user_administration/policies/user_management_policy.dart';
import 'package:vitago_app/features/user_administration/views/assign_user_role_view.dart';

class UserRolesView extends ConsumerWidget {
  const UserRolesView({required this.user, required this.profile, super.key});

  final ManagedUser user;
  final UserProfile profile;

  bool get _canManage => UserManagementPolicy.canManageRoles(profile, user);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(userRolesControllerProvider(user.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Roles y alcances')),
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
              onPressed: () => _openAssign(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Asignar rol'),
            )
          : null,
      body: SafeArea(
        child: roles.when(
          loading: () => const AppLoadingView(label: 'Cargando roles…'),
          error: (error, stackTrace) => AppErrorView(
            error: error,
            onRetry: () => ref.invalidate(userRolesControllerProvider(user.id)),
          ),
          data: (items) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userRolesControllerProvider(user.id));
              await ref.read(userRolesControllerProvider(user.id).future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                104,
              ),
              children: [
                Text(
                  user.fullName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Las asignaciones revocadas permanecen visibles para conservar la trazabilidad.',
                ),
                const SizedBox(height: AppSpacing.xl),
                if (items.isEmpty)
                  const AppEmptyView(
                    icon: Icons.badge_outlined,
                    title: 'Sin historial de roles',
                    message:
                        'No existen asignaciones visibles para este usuario.',
                  )
                else
                  ...items.map(
                    (assignment) => _RoleAssignmentTile(
                      assignment: assignment,
                      canRevoke: _canManage && assignment.active,
                      onRevoke: () => _confirmRevoke(context, ref, assignment),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openAssign(BuildContext context, WidgetRef ref) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => AssignUserRoleView(user: user, profile: profile),
      ),
    );
    if (created == true) {
      ref.invalidate(userRolesControllerProvider(user.id));
      ref.invalidate(userDetailControllerProvider(user.id));
      ref.invalidate(usersControllerProvider);
    }
  }

  Future<void> _confirmRevoke(
    BuildContext context,
    WidgetRef ref,
    UserRoleAssignment assignment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revocar rol'),
        content: Text(
          'Se revocará “${assignment.role.name}”. La persona tendrá que iniciar sesión nuevamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Revocar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(userActionsControllerProvider)
          .revokeRole(user.id, assignment.id);
      ref.invalidate(userRolesControllerProvider(user.id));
      ref.invalidate(userDetailControllerProvider(user.id));
      ref.invalidate(usersControllerProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Rol revocado.')));
      }
    } on AppFailure catch (failure) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
      }
    }
  }
}

class _RoleAssignmentTile extends StatelessWidget {
  const _RoleAssignmentTile({
    required this.assignment,
    required this.canRevoke,
    required this.onRevoke,
  });

  final UserRoleAssignment assignment;
  final bool canRevoke;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final active = assignment.active;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: active ? Colors.white : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadii.control),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      assignment.role.name,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  _RoleStateChip(active: active),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('${assignment.scopeType.label} · ${assignment.role.code}'),
              if (assignment.role.description case final description?) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                active
                    ? 'Asignado el ${_formatDate(assignment.assignedAt)}'
                    : assignment.revokedAt == null
                    ? 'Rol revocado'
                    : 'Revocado el ${_formatDate(assignment.revokedAt!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (canRevoke) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onRevoke,
                    icon: const Icon(Icons.remove_circle_outline),
                    label: const Text('Revocar rol'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}

class _RoleStateChip extends StatelessWidget {
  const _RoleStateChip({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: active
            ? colors.primaryContainer
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.round),
      ),
      child: Text(
        active ? 'Activo' : 'Revocado',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: active ? colors.onPrimaryContainer : colors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
