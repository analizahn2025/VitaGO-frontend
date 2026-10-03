import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/core/widgets/entity_list_tile.dart';
import 'package:vitago_app/core/widgets/pagination_footer.dart';
import 'package:vitago_app/features/organizations/controllers/organizations_controller.dart';
import 'package:vitago_app/features/organizations/models/company.dart';
import 'package:vitago_app/features/organizations/views/branch_detail_view.dart';
import 'package:vitago_app/features/organizations/views/create_branch_view.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';

class CompanyDetailView extends ConsumerStatefulWidget {
  CompanyDetailView({
    required Company company,
    required this.profile,
    super.key,
  }) : company = company,
       companyId = company.id,
       companyName = company.name,
       embedded = false;

  const CompanyDetailView.embedded({
    required this.companyId,
    required this.companyName,
    required this.profile,
    super.key,
  }) : company = null,
       embedded = true;

  final Company? company;
  final String companyId;
  final String companyName;
  final UserProfile profile;
  final bool embedded;

  @override
  ConsumerState<CompanyDetailView> createState() => _CompanyDetailViewState();
}

class _CompanyDetailViewState extends ConsumerState<CompanyDetailView> {
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (widget.embedded) {
      return body;
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.companyName)),
      body: SafeArea(child: body),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (!widget.profile.can(AppPermissions.viewBranches)) {
      return const AppEmptyView(
        icon: Icons.store_mall_directory_outlined,
        title: 'Sin acceso a sucursales',
        message: 'Tu perfil no puede consultar las sucursales de esta empresa.',
      );
    }

    if (!widget.embedded && widget.profile.can(AppPermissions.viewCompanies)) {
      final company = ref.watch(companyControllerProvider(widget.companyId));
      return company.when(
        loading: () => const AppLoadingView(label: 'Cargando empresa…'),
        error: (error, stackTrace) => AppErrorView(
          error: error,
          onRetry: () =>
              ref.invalidate(companyControllerProvider(widget.companyId)),
        ),
        data: (value) => _buildBranches(context, value),
      );
    }

    return _buildBranches(context, widget.company);
  }

  Widget _buildBranches(BuildContext context, Company? company) {
    final query = (companyId: widget.companyId, page: _page);
    final branches = ref.watch(branchesControllerProvider(query));
    return branches.when(
      loading: () => const AppLoadingView(label: 'Cargando sucursales…'),
      error: (error, stackTrace) => AppErrorView(
        error: error,
        onRetry: () => ref.invalidate(branchesControllerProvider(query)),
      ),
      data: (result) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(branchesControllerProvider(query));
            await ref.read(branchesControllerProvider(query).future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            itemCount: result.items.length + 2,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _CompanyHeader(
                  company: company,
                  companyName: widget.companyName,
                  canCreate: widget.profile.can(AppPermissions.manageBranches),
                  onCreate: _openCreateBranch,
                );
              }
              if (index == result.items.length + 1) {
                if (result.items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      'Esta empresa todavía no tiene sucursales visibles.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return PaginationFooter(
                  page: _page,
                  totalItems: result.count,
                  hasPrevious: result.hasPrevious,
                  hasNext: result.hasNext,
                  onPrevious: () => setState(() => _page--),
                  onNext: () => setState(() => _page++),
                );
              }

              final branch = result.items[index - 1];
              return EntityListTile(
                icon: Icons.storefront_outlined,
                title: branch.name,
                subtitle:
                    branch.code ??
                    branch.location?.address ??
                    'Sucursal registrada',
                status: branch.status,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => BranchDetailView(branchId: branch.id),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openCreateBranch() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => CreateBranchView(
          companyId: widget.companyId,
          companyName: widget.companyName,
        ),
      ),
    );
    if (created == true) {
      final query = (companyId: widget.companyId, page: _page);
      ref.invalidate(branchesControllerProvider(query));
    }
  }
}

class _CompanyHeader extends StatelessWidget {
  const _CompanyHeader({
    required this.company,
    required this.companyName,
    required this.canCreate,
    required this.onCreate,
  });

  final Company? company;
  final String companyName;
  final bool canCreate;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(companyName, style: Theme.of(context).textTheme.headlineMedium),
          if (company?.country case final country?) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('${country.name} · ${country.currencyCode}'),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sucursales',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (canCreate)
                FilledButton.tonalIcon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add_business_outlined),
                  label: const Text('Crear'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
