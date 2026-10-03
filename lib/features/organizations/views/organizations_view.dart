import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/core/widgets/entity_list_tile.dart';
import 'package:vitago_app/core/widgets/pagination_footer.dart';
import 'package:vitago_app/features/organizations/controllers/organizations_controller.dart';
import 'package:vitago_app/features/organizations/models/company.dart';
import 'package:vitago_app/features/organizations/views/company_detail_view.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';

class OrganizationsView extends ConsumerStatefulWidget {
  const OrganizationsView({required this.profile, super.key});

  final UserProfile profile;

  @override
  ConsumerState<OrganizationsView> createState() => _OrganizationsViewState();
}

class _OrganizationsViewState extends ConsumerState<OrganizationsView> {
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    if (!widget.profile.can(AppPermissions.viewCompanies)) {
      final company = widget.profile.company;
      if (company == null || !widget.profile.can(AppPermissions.viewBranches)) {
        return const AppEmptyView(
          icon: Icons.domain_disabled_outlined,
          title: 'Sin organizaciones disponibles',
          message: 'Tu perfil no tiene acceso a empresas o sucursales.',
        );
      }
      return CompanyDetailView.embedded(
        companyId: company.id,
        companyName: company.name,
        profile: widget.profile,
      );
    }

    final companies = ref.watch(companiesControllerProvider(_page));
    return companies.when(
      loading: () => const AppLoadingView(label: 'Cargando empresas…'),
      error: (error, stackTrace) => AppErrorView(
        error: error,
        onRetry: () => ref.invalidate(companiesControllerProvider(_page)),
      ),
      data: (result) {
        if (result.items.isEmpty) {
          return const AppEmptyView(
            icon: Icons.apartment_outlined,
            title: 'No hay empresas visibles',
            message: 'No existen empresas dentro de tu alcance actual.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(companiesControllerProvider(_page));
            await ref.read(companiesControllerProvider(_page).future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            itemCount: result.items.length + 2,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == 0) {
                return const _OrganizationsHeader();
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

              final company = result.items[index - 1];
              return EntityListTile(
                icon: Icons.apartment_outlined,
                title: company.name,
                subtitle: _companySubtitle(company),
                status: company.status,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => CompanyDetailView(
                      company: company,
                      profile: widget.profile,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _companySubtitle(Company company) {
    final country = company.country?.name;
    final legalName = company.legalName;
    if (legalName != null && country != null) {
      return '$legalName · $country';
    }
    return legalName ?? country ?? 'Empresa registrada';
  }
}

class _OrganizationsHeader extends StatelessWidget {
  const _OrganizationsHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Empresas', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          const Text('Organizaciones disponibles dentro de tu alcance.'),
        ],
      ),
    );
  }
}
