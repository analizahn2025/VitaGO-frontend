import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/organizations/models/branch.dart';
import 'package:vitago_app/features/organizations/models/company.dart';
import 'package:vitago_app/features/organizations/providers/organizations_providers.dart';
import 'package:vitago_app/features/organizations/repositories/organizations_repository.dart';

typedef BranchPageQuery = ({String companyId, int page});

final companiesControllerProvider = FutureProvider.autoDispose
    .family<PaginatedResult<Company>, int>((ref, page) {
      return ref
          .watch(organizationsRepositoryProvider)
          .getCompanies(page: page);
    });

final companySelectionControllerProvider =
    FutureProvider.autoDispose<PaginatedResult<Company>>((ref) {
      return ref
          .watch(organizationsRepositoryProvider)
          .getCompanies(page: 1, pageSize: 100);
    });

final companyControllerProvider = FutureProvider.autoDispose
    .family<Company, String>((ref, companyId) {
      return ref.watch(organizationsRepositoryProvider).getCompany(companyId);
    });

final branchesControllerProvider = FutureProvider.autoDispose
    .family<PaginatedResult<Branch>, BranchPageQuery>((ref, query) {
      return ref
          .watch(organizationsRepositoryProvider)
          .getBranches(companyId: query.companyId, page: query.page);
    });

final branchSelectionControllerProvider = FutureProvider.autoDispose
    .family<PaginatedResult<Branch>, String>((ref, companyId) {
      return ref
          .watch(organizationsRepositoryProvider)
          .getBranches(companyId: companyId, page: 1, pageSize: 100);
    });

final branchControllerProvider = FutureProvider.autoDispose
    .family<Branch, String>((ref, branchId) {
      return ref.watch(organizationsRepositoryProvider).getBranch(branchId);
    });

final organizationActionsControllerProvider =
    Provider<OrganizationActionsController>((ref) {
      return OrganizationActionsController(
        ref.watch(organizationsRepositoryProvider),
      );
    });

class OrganizationActionsController {
  const OrganizationActionsController(this._repository);

  final OrganizationsRepository _repository;

  Future<Branch> createBranch({
    required String companyId,
    required CreateBranchInput input,
  }) => _repository.createBranch(companyId: companyId, input: input);
}
