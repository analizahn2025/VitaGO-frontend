import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/app/widgets/product_brand_mark.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/features/authentication/controllers/auth_controller.dart';
import 'package:vitago_app/features/home/models/app_section.dart';
import 'package:vitago_app/features/home/views/home_overview_view.dart';
import 'package:vitago_app/features/locations/views/locations_view.dart';
import 'package:vitago_app/features/operations/views/driver_history_view.dart';
import 'package:vitago_app/features/operations/views/operations_view.dart';
import 'package:vitago_app/features/operations/widgets/driver_alerts_button.dart';
import 'package:vitago_app/features/organizations/views/organizations_view.dart';
import 'package:vitago_app/features/profile/controllers/profile_controller.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/profile/views/profile_view.dart';
import 'package:vitago_app/features/requests/views/requests_view.dart';
import 'package:vitago_app/features/tracking/widgets/driver_automatic_tracking.dart';
import 'package:vitago_app/features/user_administration/views/users_view.dart';

class AuthenticatedHomeView extends ConsumerWidget {
  const AuthenticatedHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    return profile.when(
      loading: () => const Scaffold(
        body: SafeArea(
          child: AppLoadingView(label: 'Preparando tu espacio de trabajo…'),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(
          title: const Text('VitaGo'),
          actions: [
            IconButton(
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).logout(),
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: SafeArea(
          child: AppErrorView(
            error: error,
            title: 'No pudimos cargar tu perfil',
            onRetry: () =>
                ref.read(profileControllerProvider.notifier).refreshProfile(),
          ),
        ),
      ),
      data: (value) => _AuthenticatedShell(profile: value),
    );
  }
}

class _AuthenticatedShell extends ConsumerStatefulWidget {
  const _AuthenticatedShell({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_AuthenticatedShell> createState() =>
      _AuthenticatedShellState();
}

class _AuthenticatedShellState extends ConsumerState<_AuthenticatedShell> {
  AppSection _selected = AppSection.home;
  final Set<AppSection> _loadedSections = <AppSection>{};
  int _operationsActivationToken = 0;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final availableSections = AvailableAppSections.forProfile(widget.profile);
    final navigationSections = _navigationSections(availableSections);
    final selected = navigationSections.contains(_selected)
        ? _selected
        : navigationSections.first;
    final selectedIndex = navigationSections.indexOf(selected);
    _loadedSections.add(selected);
    return DriverAutomaticTracking(
      enabled:
          widget.profile.isDriver &&
          widget.profile.can(AppPermissions.registerDriverLocation),
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: 60,
          leading: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              top: AppSpacing.xs,
              bottom: AppSpacing.xs,
            ),
            child: ProductBrandMark(isCorporate: config.isCorporate, size: 40),
          ),
          title: Text(config.appName),
          actions: [
            if (widget.profile.isDriver)
              const DriverAlertsButton()
            else
              IconButton(
                onPressed: () => ref
                    .read(profileControllerProvider.notifier)
                    .refreshProfile(),
                tooltip: 'Actualizar perfil',
                icon: const Icon(Icons.sync),
              ),
          ],
        ),
        body: SafeArea(
          child: SizedBox.expand(
            child: IndexedStack(
              index: selectedIndex,
              children: [
                for (final section in navigationSections)
                  KeyedSubtree(
                    key: ValueKey<AppSection>(section),
                    child: _loadedSections.contains(section)
                        ? _sectionView(
                            section,
                            config,
                            widget.profile,
                            availableSections,
                            navigationSections,
                          )
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selected = navigationSections[index];
              _loadedSections.add(_selected);
              if (_selected == AppSection.operations) {
                _operationsActivationToken++;
              }
            });
          },
          destinations: navigationSections
              .map(
                (section) => NavigationDestination(
                  icon: Icon(section.icon),
                  selectedIcon: Icon(section.selectedIcon),
                  label: section.label,
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }

  Widget _sectionView(
    AppSection section,
    AppConfig config,
    UserProfile profile,
    List<AppSection> availableSections,
    List<AppSection> navigationSections,
  ) {
    return switch (section) {
      AppSection.home => HomeOverviewView(
        config: config,
        profile: profile,
        availableSections: availableSections,
        onSelectSection: (value) => _openSection(
          value,
          config,
          profile,
          availableSections,
          navigationSections,
        ),
      ),
      AppSection.organizations => OrganizationsView(profile: profile),
      AppSection.users => UsersView(profile: profile),
      AppSection.locations => LocationsView(profile: profile),
      AppSection.requests => RequestsView(profile: profile),
      AppSection.operations => OperationsView(
        profile: profile,
        activationToken: _operationsActivationToken,
      ),
      AppSection.history => DriverHistoryView(profile: profile),
      AppSection.account => ProfileView(profile: profile),
    };
  }

  List<AppSection> _navigationSections(List<AppSection> availableSections) {
    if (widget.profile.isDriver) {
      return const [
        AppSection.operations,
        AppSection.history,
        AppSection.account,
      ];
    }
    const priority = [
      AppSection.requests,
      AppSection.operations,
      AppSection.users,
      AppSection.locations,
      AppSection.organizations,
    ];
    final primary = priority
        .where(availableSections.contains)
        .take(3)
        .toList(growable: false);
    return [AppSection.home, ...primary, AppSection.account];
  }

  void _openSection(
    AppSection section,
    AppConfig config,
    UserProfile profile,
    List<AppSection> availableSections,
    List<AppSection> navigationSections,
  ) {
    if (navigationSections.contains(section)) {
      setState(() {
        _selected = section;
        _loadedSections.add(section);
        if (section == AppSection.operations) {
          _operationsActivationToken++;
        }
      });
      return;
    }

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(section.label)),
          body: SafeArea(
            child: _sectionView(
              section,
              config,
              profile,
              availableSections,
              navigationSections,
            ),
          ),
        ),
      ),
    );
  }
}
