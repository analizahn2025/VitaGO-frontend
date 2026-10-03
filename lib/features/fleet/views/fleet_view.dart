import 'package:flutter/material.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/features/fleet/views/drivers_view.dart';
import 'package:vitago_app/features/fleet/views/vehicles_view.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';

class FleetView extends StatelessWidget {
  const FleetView({required this.profile, super.key});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final canViewVehicles = profile.can(AppPermissions.viewVehicles);
    final canViewDrivers = profile.can(AppPermissions.viewDrivers);
    if (!canViewVehicles && !canViewDrivers) {
      return const Scaffold(
        body: SafeArea(
          child: AppEmptyView(
            icon: Icons.local_shipping_outlined,
            title: 'Sin acceso a flota',
            message: 'Tu perfil no puede consultar vehículos ni motoristas.',
          ),
        ),
      );
    }

    final tabs = <Tab>[];
    final views = <Widget>[];
    if (canViewVehicles) {
      tabs.add(const Tab(text: 'Vehículos', icon: Icon(Icons.two_wheeler)));
      views.add(VehiclesView(profile: profile));
    }
    if (canViewDrivers) {
      tabs.add(const Tab(text: 'Motoristas', icon: Icon(Icons.badge_outlined)));
      views.add(DriversView(profile: profile));
    }

    if (views.length == 1) {
      return Scaffold(
        appBar: AppBar(title: Text(tabs.single.text ?? 'Flota')),
        body: SafeArea(child: views.single),
      );
    }
    return DefaultTabController(
      length: views.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Flota y motoristas'),
          bottom: TabBar(tabs: tabs),
        ),
        body: SafeArea(child: TabBarView(children: views)),
      ),
    );
  }
}
