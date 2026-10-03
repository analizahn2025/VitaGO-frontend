import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/organizations/models/branch.dart';
import 'package:vitago_app/features/organizations/models/company.dart';

abstract interface class OrganizationsRepository {
  Future<PaginatedResult<Company>> getCompanies({
    required int page,
    int pageSize,
  });

  Future<Company> getCompany(String companyId);

  Future<PaginatedResult<Branch>> getBranches({
    required String companyId,
    required int page,
    int pageSize,
  });

  Future<Branch> getBranch(String branchId);

  Future<Branch> createBranch({
    required String companyId,
    required CreateBranchInput input,
  });
}
