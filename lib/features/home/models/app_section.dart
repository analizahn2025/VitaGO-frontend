import 'package:flutter/material.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';

enum AppSection {
  home('Inicio', Icons.home_outlined, Icons.home),
  organizations('Empresas', Icons.apartment_outlined, Icons.apartment),
  users('Usuarios', Icons.people_outline, Icons.people),
  locations('Lugares', Icons.location_on_outlined, Icons.location_on),
  requests('Solicitudes', Icons.inventory_2_outlined, Icons.inventory_2),
  operations('Hoy', Icons.delivery_dining_outlined, Icons.delivery_dining),
  history('Historial', Icons.history_outlined, Icons.history),
  account('Cuenta', Icons.person_outline, Icons.person);

  const AppSection(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

abstract final class AvailableAppSections {
  static List<AppSection> forProfile(UserProfile profile) {
    return [
      AppSection.home,
      if (profile.can(AppPermissions.viewCompanies) ||
          profile.can(AppPermissions.viewBranches))
        AppSection.organizations,
      if (profile.can(AppPermissions.viewUsers)) AppSection.users,
      if (profile.can(AppPermissions.viewLocations)) AppSection.locations,
      if (profile.can(AppPermissions.viewRequests) ||
          profile.can(AppPermissions.viewOwnRequests) ||
          (!profile.isDriver &&
              profile.can(AppPermissions.viewAssignedRequests)))
        AppSection.requests,
      if (profile.isDriver && profile.can(AppPermissions.viewShifts))
        AppSection.operations,
      if (profile.isDriver && profile.can(AppPermissions.viewShifts))
        AppSection.history,
      AppSection.account,
    ];
  }
}
