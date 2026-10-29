import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/formatters/app_date_format.dart';
import 'package:vitago_app/core/permissions/administrative_scope.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/core/widgets/pagination_footer.dart';
import 'package:vitago_app/features/fleet/controllers/driver_reports_controller.dart';
import 'package:vitago_app/features/fleet/models/driver_report.dart';
import 'package:vitago_app/features/fleet/widgets/driver_tube_load.dart';
import 'package:vitago_app/features/organizations/controllers/organizations_controller.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';

class DriverReportsView extends ConsumerStatefulWidget {
  const DriverReportsView({required this.profile, super.key});
  final UserProfile profile;
  @override
  ConsumerState<DriverReportsView> createState() => _DriverReportsViewState();
}

class _DriverReportsViewState extends ConsumerState<DriverReportsView> {
  final _date = TextEditingController();
  final _form = GlobalKey<FormState>();
  String? _selectedDate, _company;
  bool? _active;
  int _page = 1;
  @override
  void initState() {
    super.initState();
    _company = hasGlobalScope(widget.profile)
        ? null
        : widget.profile.company?.id;
  }

  @override
  void dispose() {
    _date.dispose();
    super.dispose();
  }

  DriverReportQuery get _query => DriverReportQuery(
    date: _selectedDate,
    companyId: _company,
    active: _active,
    page: _page,
  );
  void _apply() {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _selectedDate = _date.text.trim().isEmpty ? null : _date.text.trim();
      _page = 1;
    });
    ref.invalidate(driverReportsControllerProvider(_query));
  }

  @override
  Widget build(BuildContext context) {
    final corporate = ref.watch(appConfigProvider).isCorporate;
    final allowed = canViewDriverReports(
      widget.profile,
      corporate: corporate,
      companyId: _company,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes de motoristas')),
      body: SafeArea(
        child: !allowed
            ? const _NoReportAccess()
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(driverReportsControllerProvider(_query));
                  await ref.read(
                    driverReportsControllerProvider(_query).future,
                  );
                },
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Text(
                      'Actividad por motorista',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'El día y la zona horaria los define el servidor para cada motorista.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Form(
                      key: _form,
                      child: TextFormField(
                        controller: _date,
                        keyboardType: TextInputType.datetime,
                        decoration: const InputDecoration(
                          labelText: 'Fecha operativa (opcional)',
                          hintText: 'AAAA-MM-DD',
                          helperText: 'Vacío: hoy según el servidor',
                        ),
                        validator: operationalDateError,
                        onFieldSubmitted: (_) => _apply(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (corporate &&
                        hasGlobalScope(widget.profile) &&
                        widget.profile.can(AppPermissions.viewCompanies))
                      ref
                          .watch(companySelectionControllerProvider)
                          .when(
                            loading: () => const LinearProgressIndicator(),
                            error: (error, stack) => TextButton(
                              onPressed: () => ref.invalidate(
                                companySelectionControllerProvider,
                              ),
                              child: const Text('Reintentar empresas'),
                            ),
                            data: (companies) =>
                                DropdownButtonFormField<String>(
                                  initialValue: _company,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Empresa',
                                  ),
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text(
                                        'Todas las empresas visibles',
                                      ),
                                    ),
                                    ...companies.items.map(
                                      (company) => DropdownMenuItem(
                                        value: company.id,
                                        child: Text(
                                          company.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) => setState(() {
                                    _company = value;
                                    _page = 1;
                                  }),
                                ),
                          ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<bool>(
                      initialValue: _active,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Motoristas',
                      ),
                      items: const [
                        DropdownMenuItem<bool>(
                          value: null,
                          child: Text('Activos e inactivos'),
                        ),
                        DropdownMenuItem(value: true, child: Text('Activos')),
                        DropdownMenuItem(
                          value: false,
                          child: Text('Inactivos'),
                        ),
                      ],
                      onChanged: (value) => setState(() {
                        _active = value;
                        _page = 1;
                      }),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: _apply,
                      icon: const Icon(Icons.search),
                      label: const Text('Consultar reporte'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ref
                        .watch(driverReportsControllerProvider(_query))
                        .when(
                          loading: () => const Padding(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (error, stack) => _ReportError(
                            error: error,
                            onRetry: () => ref.invalidate(
                              driverReportsControllerProvider(_query),
                            ),
                          ),
                          data: (result) => Column(
                            children: [
                              if (result.items.isEmpty)
                                const AppEmptyView(
                                  icon: Icons.assessment_outlined,
                                  title: 'Sin reportes para estos filtros',
                                  message: 'Puedes consultar otra fecha o cambiar los filtros.',
                                ),
                              ...result.items.map(
                                (report) => Card(
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(
                                      AppSpacing.md,
                                    ),
                                    title: Text(report.name),
                                    subtitle: Text(
                                      '${report.companyName ?? 'Network'} · ${report.active ? 'Activo' : 'Inactivo'}\n${report.date} · ${report.zone}\nEntregadas: ${report.delivered} · Recogidas: ${report.pickedUp}\nKm de jornadas cerradas: ${report.measuredKm ?? 'Sin medición'}${report.completeMileage ? '' : ' · Incompleto o pendiente'}',
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () =>
                                        Navigator.of(context).push<void>(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                DriverReportDetailView(
                                                  profile: widget.profile,
                                                  driverId: report.driverId,
                                                  companyId: report.companyId,
                                                  date: report.date,
                                                ),
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                              PaginationFooter(
                                page: _page,
                                totalItems: result.count,
                                hasPrevious: result.hasPrevious,
                                hasNext: result.hasNext,
                                onPrevious: () => setState(() => _page--),
                                onNext: () => setState(() => _page++),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
      ),
    );
  }
}

class DriverReportDetailView extends ConsumerWidget {
  const DriverReportDetailView({
    required this.profile,
    required this.driverId,
    this.companyId,
    this.date,
    super.key,
  });
  final UserProfile profile;
  final String driverId;
  final String? companyId, date;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed = canViewDriverReports(
      profile,
      corporate: ref.watch(appConfigProvider).isCorporate,
      companyId: companyId,
    );
    final query = (id: driverId, date: date);
    return Scaffold(
      appBar: AppBar(title: const Text('Reporte del motorista')),
      body: SafeArea(
        child: !allowed
            ? const _NoReportAccess()
            : ref
                  .watch(driverReportControllerProvider(query))
                  .when(
                    loading: () =>
                        const AppLoadingView(label: 'Cargando reporte…'),
                    error: (error, stack) => _ReportError(
                      error: error,
                      onRetry: () =>
                          ref.invalidate(driverReportControllerProvider(query)),
                    ),
                    data: (report) => RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(driverReportControllerProvider(query));
                        await ref.read(
                          driverReportControllerProvider(query).future,
                        );
                      },
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Text(
                            report.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text('${report.date} · ${report.zone}'),
                          Text(
                            'Desde ${AppDateFormat.dateTime(report.periodStart, timeZone: report.zone)} hasta ${AppDateFormat.dateTime(report.periodEnd, timeZone: report.zone)} (sin incluir el final)',
                          ),
                          _ReportSection(
                            title: 'Actividad del día',
                            children: [
                              Text('Asignadas: ${report.assigned}'),
                              Text('Recogidas: ${report.pickedUp}'),
                              Text('Entregadas: ${report.delivered}'),
                              Text('Fallidas: ${report.failed}'),
                              Text('Canceladas: ${report.cancelled}'),
                              const SizedBox(height: AppSpacing.sm),
                              const Text(
                                'Son hitos independientes; una solicitud puede aparecer en varias etapas.',
                              ),
                            ],
                          ),
                          _ReportSection(
                            title: 'Tubos del día',
                            children: [
                              Text(
                                'Recogidos conocidos: ${report.knownPickedTubes}',
                              ),
                              Text(
                                'Entregados conocidos: ${report.knownDeliveredTubes}',
                              ),
                              Text(
                                'Recolecciones sin cantidad: ${report.pickupsWithoutTubes}',
                              ),
                              Text(
                                'Entregas sin cantidad: ${report.deliveriesWithoutTubes}',
                              ),
                              if (report.pickupsWithoutTubes +
                                      report.deliveriesWithoutTubes >
                                  0)
                                const Text(
                                  'Los conteos conocidos son parciales; no representan toda la carga transportada.',
                                ),
                            ],
                          ),
                          _ReportSection(
                            title: 'Km de jornadas cerradas',
                            children: [
                              Text(
                                'Medidos: ${report.measuredKm == null ? 'Sin medición' : '${report.measuredKm} km'}',
                              ),
                              Text(
                                'Consolidados: ${report.consolidatedKm == null ? 'Sin consolidar' : '${report.consolidatedKm} km'}',
                              ),
                              Text(
                                report.completeMileage
                                    ? 'Medición completa y consolidada'
                                    : 'Medición incompleta o pendiente',
                              ),
                              Text(
                                'Jornadas cerradas: ${report.closedShifts} · Con medición: ${report.measuredShifts} · Consolidadas: ${report.consolidatedShifts}',
                              ),
                              Text(
                                'Sin cierre en el período: ${report.unclosedShifts}',
                              ),
                              const Text(
                                'La distancia pertenece al día de cierre de la jornada; no equivale necesariamente al recorrido de ese día.',
                              ),
                            ],
                          ),
                          _ReportSection(
                            title: 'Temperaturas del día',
                            children: [
                              Text(
                                'Lecturas: ${report.readings} · Con temperatura: ${report.readingsWithTemperature} · Sin lectura: ${report.readingsWithoutTemperature}',
                              ),
                              Text(
                                'Mínima: ${_degrees(report.minC)} · Máxima: ${_degrees(report.maxC)} · Promedio: ${_degrees(report.averageC)}',
                              ),
                              ...report.recentReadings.map(
                                (reading) => _ReadingTile(
                                  reading: reading,
                                  zone: report.zone,
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).push<void>(
                                      MaterialPageRoute(
                                        builder: (_) => DriverTemperaturesView(
                                          profile: profile,
                                          driverId: report.driverId,
                                          companyId: report.companyId,
                                          date: report.date,
                                          zone: report.zone,
                                        ),
                                      ),
                                    ),
                                child: const Text('Ver todas las lecturas'),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Carga actual',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Text(
                            'Estado al consultar; no es la carga histórica del día seleccionado.',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          DriverTubeLoad.snapshot(report.currentLoad),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Generado: ${AppDateFormat.dateTime(report.generatedAt, timeZone: report.zone)}',
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}

class DriverTemperaturesView extends ConsumerStatefulWidget {
  const DriverTemperaturesView({
    required this.profile,
    required this.driverId,
    required this.date,
    required this.zone,
    this.companyId,
    super.key,
  });
  final UserProfile profile;
  final String driverId, date, zone;
  final String? companyId;
  @override
  ConsumerState<DriverTemperaturesView> createState() =>
      _DriverTemperaturesViewState();
}

class _DriverTemperaturesViewState
    extends ConsumerState<DriverTemperaturesView> {
  int _page = 1;
  @override
  Widget build(BuildContext context) {
    final allowed = canViewDriverReports(
      widget.profile,
      corporate: ref.watch(appConfigProvider).isCorporate,
      companyId: widget.companyId,
    );
    final query = (id: widget.driverId, date: widget.date, page: _page);
    return Scaffold(
      appBar: AppBar(title: const Text('Lecturas de temperatura')),
      body: SafeArea(
        child: !allowed
            ? const _NoReportAccess()
            : ref
                  .watch(driverTemperaturesControllerProvider(query))
                  .when(
                    loading: () =>
                        const AppLoadingView(label: 'Cargando lecturas…'),
                    error: (error, stack) => _ReportError(
                      error: error,
                      onRetry: () => ref.invalidate(
                        driverTemperaturesControllerProvider(query),
                      ),
                    ),
                    data: (result) => ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        Text('${widget.date} · ${widget.zone}'),
                        if (result.items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            child: Text('No hay lecturas para esta página.'),
                          ),
                        ...result.items.map(
                          (reading) =>
                              _ReadingTile(reading: reading, zone: widget.zone),
                        ),
                        PaginationFooter(
                          page: _page,
                          totalItems: result.count,
                          hasPrevious: result.hasPrevious,
                          hasNext: result.hasNext,
                          onPrevious: () => setState(() => _page--),
                          onNext: () => setState(() => _page++),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

String _degrees(String? value) => value == null ? 'Sin registrar' : '$value °C';

class _ReadingTile extends StatelessWidget {
  const _ReadingTile({required this.reading, required this.zone});
  final DriverTemperatureReading reading;
  final String zone;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text('${reading.number} · ${_degrees(reading.temperature)}'),
    subtitle: Text(
      '${reading.source == 'MANUAL'
          ? 'Manual'
          : reading.source == 'AUTOMATICA'
          ? 'Automática'
          : 'Sin fuente registrada'} · ${AppDateFormat.dateTime(reading.capturedAt, timeZone: zone)}',
    ),
  );
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: AppSpacing.lg),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    ),
  );
}

class _NoReportAccess extends StatelessWidget {
  const _NoReportAccess();
  @override
  Widget build(BuildContext context) => const AppEmptyView(
    icon: Icons.lock_outline,
    title: 'Sin acceso a reportes',
    message: 'Esta consulta requiere autorización administrativa para el motorista completo.',
  );
}

class _ReportError extends StatelessWidget {
  const _ReportError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final field = error is AppFailure
        ? (error as AppFailure).fieldMessage('fecha_operativa')
        : null;
    return AppErrorView(
      error: field == null ? error : AppFailure(message: field),
      onRetry: onRetry,
    );
  }
}
