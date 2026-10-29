import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/core/permissions/scope_type.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';

bool hasGlobalScope(UserProfile profile) =>
    profile.roles.any((role) => role.scopeType == ScopeType.global);
bool hasCompanyScope(UserProfile profile, String companyId) =>
    hasGlobalScope(profile) ||
    profile.roles.any(
      (role) =>
          role.scopeType == ScopeType.company &&
          (role.companyId == companyId ||
              (role.companyId == null && profile.company?.id == companyId)),
    );
bool canEditDriverLimits(
  UserProfile profile, {
  required bool corporate,
  String? companyId,
}) => corporate
    ? companyId != null &&
          profile.can(AppPermissions.manageCompanies) &&
          hasCompanyScope(profile, companyId)
    : companyId == null &&
          profile.can(AppPermissions.manageConfiguration) &&
          hasGlobalScope(profile);
bool canViewDriverReports(
  UserProfile profile, {
  required bool corporate,
  String? companyId,
}) =>
    const [
      AppPermissions.viewDrivers,
      AppPermissions.viewReports,
      AppPermissions.viewRequests,
      AppPermissions.viewShifts,
      AppPermissions.viewEvidence,
    ].every(profile.can) &&
    (corporate
        ? (companyId == null
              ? hasGlobalScope(profile)
              : hasCompanyScope(profile, companyId))
        : hasGlobalScope(profile));
