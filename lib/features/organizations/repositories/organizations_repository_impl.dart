import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/organizations/models/branch.dart';
import 'package:vitago_app/features/organizations/models/company.dart';
import 'package:vitago_app/features/organizations/repositories/organizations_repository.dart';
import 'package:vitago_app/features/organizations/services/organizations_api_service.dart';

class OrganizationsRepositoryImpl implements OrganizationsRepository {
  const OrganizationsRepositoryImpl(this._apiService);

  final OrganizationsApiService _apiService;

  @override
  Future<PaginatedResult<Company>> getCompanies({
    required int page,
    int pageSize = 20,
  }) => _apiService.getCompanies(page: page, pageSize: pageSize);

  @override
  Future<Company> getCompany(String companyId) =>
      _apiService.getCompany(companyId);

  @override
  Future<PaginatedResult<Branch>> getBranches({
    required String companyId,
    required int page,
    int pageSize = 20,
  }) => _apiService.getBranches(
    companyId: companyId,
    page: page,
    pageSize: pageSize,
  );

  @override
  Future<Branch> getBranch(String branchId) => _apiService.getBranch(branchId);

  @override
  Future<Branch> createBranch({
    required String companyId,
    required CreateBranchInput input,
  }) => _apiService.createBranch(companyId: companyId, input: input);
}
