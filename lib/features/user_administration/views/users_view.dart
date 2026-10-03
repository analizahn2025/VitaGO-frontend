import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/core/widgets/entity_list_tile.dart';
import 'package:vitago_app/core/widgets/pagination_footer.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/user_administration/controllers/users_controller.dart';
import 'package:vitago_app/features/user_administration/models/managed_user.dart';
import 'package:vitago_app/features/user_administration/views/create_user_view.dart';
import 'package:vitago_app/features/user_administration/views/user_detail_view.dart';

class UsersView extends ConsumerStatefulWidget {
  const UsersView({required this.profile, super.key});

  final UserProfile profile;

  @override
  ConsumerState<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends ConsumerState<UsersView> {
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final canViewUsers = widget.profile.can(AppPermissions.viewUsers);
    if (!canViewUsers) {
      return const AppEmptyView(
        icon: Icons.manage_accounts_outlined,
        title: 'Sin acceso a usuarios',
        message: 'Tu perfil no puede consultar usuarios.',
      );
    }

    final users = ref.watch(usersControllerProvider(_page));
    return users.when(
      loading: () => const AppLoadingView(label: 'Cargando usuarios…'),
      error: (error, stackTrace) => AppErrorView(
        error: error,
        onRetry: () => ref.invalidate(usersControllerProvider(_page)),
      ),
      data: _buildResult,
    );
  }

  Widget _buildResult(PaginatedResult<ManagedUser> result) {
    final empty = result.items.isEmpty;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        key: const PageStorageKey<String>('users-scroll-view'),
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: empty ? 2 : result.items.length + 2,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _UsersHeader(
              canCreate: _canCreate && !empty,
              onCreate: _openCreateUser,
            );
          }
          if (empty) {
            return _EmptyUsers(
              canCreate: _canCreate,
              onCreate: _openCreateUser,
            );
          }
          if (index == result.items.length + 1) {
            return PaginationFooter(
              page: _page,
              totalItems: result.count,
              hasPrevious: result.hasPrevious,
              hasNext: result.hasNext,
              onPrevious: () => setState(() => _page--),
              onNext: () => setState(() => _page++),
            );
          }

          final user = result.items[index - 1];
          final roleNames = user.roles.map((role) => role.name).join(', ');
          return EntityListTile(
            icon: Icons.person_outline,
            title: user.fullName,
            subtitle: roleNames.isEmpty ? user.email : roleNames,
            status: user.status,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => UserDetailView(
                  userId: user.id,
                  profile: widget.profile,
                  usesLocalAuthentication: ref
                      .read(appConfigProvider)
                      .usesLocalAuthentication,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool get _canCreate =>
      widget.profile.can(AppPermissions.manageUsers) &&
      widget.profile.can(AppPermissions.assignRoles);

  Future<void> _refresh() async {
    ref.invalidate(usersControllerProvider(_page));
    await ref.read(usersControllerProvider(_page).future);
  }

  Future<void> _openCreateUser() async {
    final config = ref.read(appConfigProvider);
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => CreateUserView(
          profile: widget.profile,
          usesLocalAuthentication: config.usesLocalAuthentication,
        ),
      ),
    );
    if (created == true) {
      ref.invalidate(usersControllerProvider(_page));
    }
  }
}

class _EmptyUsers extends StatelessWidget {
  const _EmptyUsers({required this.canCreate, required this.onCreate});

  final bool canCreate;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 56, color: colors.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No hay usuarios visibles',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            canCreate
                ? 'Crea el primer usuario dentro de tu alcance.'
                : 'No existen usuarios dentro de tu alcance actual.',
            textAlign: TextAlign.center,
          ),
          if (canCreate) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Crear usuario'),
            ),
          ],
        ],
      ),
    );
  }
}

class _UsersHeader extends StatelessWidget {
  const _UsersHeader({required this.canCreate, required this.onCreate});

  final bool canCreate;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Usuarios', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Personas visibles dentro de tu alcance.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          if (canCreate) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton.tonalIcon(
              onPressed: onCreate,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Crear'),
            ),
          ],
        ],
      ),
    );
  }
}
