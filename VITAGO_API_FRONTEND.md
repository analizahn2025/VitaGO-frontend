# Contrato de API para el frontend de VitaGo

## 1. Propósito

Este documento registra el contrato HTTP que el frontend puede consumir del
backend de VitaGo. Debe actualizarse cuando se agregue o cambie cualquiera de
estos elementos:

- endpoint;
- método HTTP;
- autenticación o permiso;
- campo de entrada o salida;
- código HTTP;
- estado o catálogo;
- regla que afecte la experiencia del usuario.

El código del backend sigue siendo la fuente técnica definitiva. Este archivo
es la referencia de integración para el frontend y solo presenta como
**disponibles** las funciones que ya están implementadas.

Última actualización: **2026-10-28**.

Actualización **0.42.0**: jornada diaria hasta las 22:00 y almuerzo del motorista.
La versión 0.41.0 incorporó cupos compartidos por empresa en Corporate o por toda
la red en Network, aplicados individualmente a cada motorista. Se retira la
edición de límites por perfil. Reportes administrativos0.40.0 por fecha/zona del
servidor, con carga actual separada, kilómetros por cierre y lecturas paginadas.
Render conserva su URL; publicación y migración externa pendientes del backend.

Actualización **0.39.0**: cantidad_tubos obligatoria por solicitud; límite/carga
de tubos por motorista y filtrado de disponibles por cantidad. FOTO_RECOLECCION
requiere temperatura_contenedor_c manual en el mismo multipart. Históricos
conservan null; se añade regularización administrativa, sin alterar el plan
automático 0.38.0 ni habilitar la creación pública Network. Ver sección final.

Actualización **0.38.0**: el backend ordena por paradas cercanas y puede intercalar
recolecciones/entregas de distintos envíos. Una foto de recolección201 puede
dejar PICKED_UP o IN_TRANSIT; seguir siempre flujo_actual y el orden de paradas.
Sin DTO nuevos ni cálculos automáticos Google. Ver sección final e integración.

Actualización **0.37.0**: ENTRE_SUCURSALES de Corporate permite distintas ciudades
y municipios del mismo país/departamento y empresa, sin límite adicional de km.
Listado y alta comparten el comparador; falta de departamento no se infiere por
ciudad. Corporate solo usa flota de su empresa; candidatos Network son globales
para sus empresas clientes. Misma estructura HTTP/JSON. Ver sección final.

Carga de datos **0.36.1**: 34 sucursales y cuentas de Analiza Corporate dadas
de alta; cada cuenta es SOLICITANTE_CORPORATIVO con alcance SUCURSAL. Ubicaciones
aprobadas como origen/destino, con coordenadas normalizadas y aún no verificadas
en campo. Dos sucursales de prueba conservadas:36 totales. No cambia ningún
endpoint/JSON. En aquella carga regía misma ciudad;0.37.0 la sustituye por
país/departamento. Informe local:VITAGO_SUCURSALES_ANALIZA.md.

Actualización **0.36.0**: flujo del motorista automático, sin aceptar servicios
ni elegir recolección/entrega. `mi-ruta` añade `flujo_actual`. Foto válida de
recolección avanza hasta `IN_TRANSIT`; foto de entrega finaliza `DELIVERED`,
en la misma transacción. Evidencias añaden `estado_solicitud`. Solo el siguiente
servicio se activa con jornada/GPS válidos. Sustituye los selectores y las
confirmaciones adicionales anteriores. Ver contrato y entrega a Flutter al final.

Integración de este frontend (0.36.0): se consume `flujo_actual` para abrir
mapa/foto/finalización especial o volver a espera, sin seleccionar etapas.
Una foto operativa201 nunca envía otra transición: refresca estado y ruta.
Ante respuesta perdida se verifica detalle/ruta/evidencias antes de habilitar
un reenvío manual. Los manifiestos especiales se conservan por servidor y
motorista para confirmarlos al cerrar el movimiento y recuperar conexión.

Actualización **0.35.0**: orden estable por cercanía GPS aproximada en el backend,
por servicios completos. `orden_tipo=CERCANIA_GPS`; no cambiar el orden en Flutter.
Respeta servicio iniciado y exclusividad. Se planifica al agregar/retirar servicios,
no en cada GPS/GET. Sin GPS válido conserva lo guardado y anexa nuevos por antigüedad.
Sin nuevas APIs Google, migraciones ni cambios de conexión. Ver sección final.

Integración de este frontend (0.35.0): acepta `CERCANIA_GPS` y el histórico
`ASIGNACION`, conserva el orden recibido y la selección por IDs. La tarjeta
describe «el orden de tu ruta», sin afirmar antigüedad, optimización vial o ETA.
La estrategia configurada no garantiza que hubiera GPS al planificar.

Actualización **0.34.0**: cálculo inicial con geometría separada por envío y
parada. `ruta_vial` añade `tramos`, `tramo_actual_id` y disponibilidad del
desglose para dibujar una sola línea. Cambiar la selección es visual, no cambia
el orden ni dispara cálculos. El trazado global se conserva solo por compatibilidad.
Ver «Un envío y un tramo a la vez» al final, con contrato y entrega a Flutter.

Integración de este frontend (0.34.0, actualizada por 0.36.0): una sola polilínea
del tramo indicado por el flujo, sin selectores y sin recuperar la línea global.
La caché anterior sin desglose conserva actualización manual con confirmación,
versión vigente y `reintentar=true`; no se calcula automáticamente por GPS o etapa.

Actualización **0.33.0**: avisos diarios por la zona operativa del servidor
(`TIME_ZONE`, localmente `America/Tegucigalpa`). Desde las 00:00, listado y
conteo excluyen días anteriores incluso si se retrasa el archivado. Tareas
independientes Corporate/Network archivan sin borrar historial, con recuperación.
Los endpoints y JSON no cambian. Ver «Avisos diarios y archivado recuperable».

Integración de este frontend (0.33.0): la campana consulta listado y conteo
al abrirse, reanudar y recuperar sincronización GPS tras un fallo. En primer
plano consulta cada minuto para recoger el corte del servidor, sin calcular
vigencia con la fecha del teléfono. El panel se actualiza en vivo, reemplaza
los datos anteriores y retira IDs con `404` sin reintentarlos ni navegar a ellos.
Las alertas locales sobre problemas operativos vigentes se conservan.

Presentación de campana: el número representa avisos **nuevos no vistos** en
este dispositivo, no todas las notificaciones pendientes de lectura del API.
Abrir la campana quita el número y conserva los avisos, incluidos los leídos.
La marca local se persiste por cuenta y servidor usando IDs y fechas recibidas
del servidor; no se inventa una fecha del teléfono ni se marca cada aviso leído.
`conteo_no_leidas` mantiene su significado HTTP original. Esta marca local no
se sincroniza con otros dispositivos y no cambia la política diaria del backend.

Actualización **0.32.0**: llegada automática por GPS a la próxima parada,
sin consultas Google. `POST seguimiento/registros/` añade `llegadas_detectadas`;
`GET rutas/mi-ruta/` añade `llegada_actual` para recuperar la pantalla tras
reanudar. Las llegadas manuales con coordenadas dejan de ser acciones Flutter.
Desde 0.36.0 enviar la foto válida es la confirmación de recolección/entrega;
Flutter no debe enviar una segunda transición después.

Integración de este frontend (0.32.0): se consumen los eventos y se recupera
`llegada_actual` al iniciar, reanudar o recuperar conexión. La confirmación usa
los formularios existentes sobre la pantalla actual, sin cerrar el mapa ni
interrumpir otro formulario. El historial de `evento_id` mostrado se persiste
por cuenta y servidor. Solo se presenta la próxima parada y asignación vigentes;
los destinos especiales sin coordenadas conservan llegada manual. No se detectan
geocercas en el teléfono ni se llama a Google para las llegadas.

Actualización **0.31.0**: resumen de entregas del día por `entregada_en`, fecha
operativa en Tegucigalpa y entregas recientes diarias, sin cambiar los acumulados.
Errores técnicos sin secretos; clave JWT Corporate renovada (volver a iniciar
sesión). Pérdida de rol operativo recupera servicios; disponibilidad exige rol
vigente. Corte diario aplicado también al cierre manual tardío y cálculo vial.
GPS añade diagnóstico de captura y recomienda 15 segundos detenido, manteniendo
5 en movimiento, envío 20 y umbral de medición 30. Ver detalles al final.

Integración de este frontend: Inicio de administrador y solicitante muestra
«Resumen de envíos»: Pendientes usa `pendientes`, En progreso usa `activas`
y Entregadas hoy usa `entregadas_del_dia`. Solo las entregas están limitadas
al día; pendientes y en progreso reflejan la carga visible en esos estados.
La sección diaria usa también `entregas_recientes_del_dia`,
`fecha_operativa` y `zona_horaria_operativa`. Los acumulados no se muestran
como datos diarios. Se consulta el día del servidor al volver a Inicio,
reanudar la app y cada minuto mientras Inicio está activo. Las entregas
recientes muestran `entregada_en` en la zona recibida; «Ver solicitudes»
conserva el acceso al listado general. Captura GPS aplica la configuración
5/15 segundos y admite el diagnóstico opcional, conservando cola persistente
y reloj monotónico. La continuidad física con pantalla apagada requiere
validación en el dispositivo.

Estado operativo **0.30.4, 2026-10-22**: Routes API habilitada únicamente en
Corporate, después de instalar la limpieza horaria y al iniciar sesión.
Corporate reiniciado; salud local 200. La prueba real anterior entre sucursales
respondió 200 y polilínea válida; no se guardó el resultado ni se hicieron nuevas
consultas a Google en esta activación. Falta probar el itinerario real con
jornada, solicitudes y GPS vigentes. Contrato HTTP sin cambios; Network intacto.

Corrección **0.30.3**: resuelto bloqueo mutuo PostgreSQL al reasignar o cancelar
servicios simultáneamente mientras se guardan versiones de ruta. Conserva
contrato, límite de cinco, permisos y notificaciones. Catorce pruebas nuevas
de concurrencia y suite completa PostgreSQL: **393 aprobadas**. Sin cambios
requeridos en Flutter; detalles en sección final.

Verificación **0.30.2**: límite de login probado con concurrencia real en
PostgreSQL, conexiones independientes y dos procesos de aplicación. Sin
cambios de API ni frontend. Base temporal retirada; resultados en sección final.

Seguridad **0.30.1**: únicamente el login LOCAL limita a diez fallos por
correo/IP en 15 minutos. Los intentos posteriores devuelven `429` con
`Retry-After` y `segundos_espera`. No suspende cuentas ni limita renovación,
GPS u operación. Migración aditiva aplicada en ambas bases; ver sección final.

Contrato **0.30.0**: la hora oficial de evidencias y reportes de incidencias
la asigna el servidor. `capturada_en`/`reportada_en` dejan de ser entradas
obligatorias: se ignora cualquier valor del cliente y se conservan en respuesta.
Configuración GPS añade `hora_servidor` y `zona_horaria_operativa` para anclaje
monotónico del móvil. La integración correspondiente ya está implementada en
este frontend. Ver sección «Reloj oficial».

Corrección **0.29.4**: el resumen de jornada cuenta la entrega que coincide
exactamente con el cierre exitoso de su asignación. No cambia el contrato
HTTP ni requiere adaptar Flutter. No se recalculan jornadas históricas.

Refactorización interna **0.29.3**: cierre manual y automático de jornadas
reutilizan los pasos de persistencia, GPS, desconexión y cierre de ruta.
Sin cambios de contrato, validaciones, política diaria, conexión o tarea.
No requiere modificaciones en Flutter. Ver sección de cierre compartido.

Refactorización interna **0.29.2**: estado, capacidad e historial del motorista
usan una persistencia común en repartidores. No cambia ningún endpoint,
JSON, permiso ni regla Corporate/Network; el frontend no necesita adaptarse.

Activación local **0.29.1** (2026-10-17): registrada y habilitada la tarea
`VitaGo-Corporate-CierreDiario`, cada minuto y al iniciar sesión en Windows.
La primera ejecución automática recuperó una solicitud y una jornada vencidas.
Se corrigió la escritura de stdout al correr con `pythonw.exe` sin consola;
los resultados se guardan en el log. Sin cambios de API, conexión o migraciones.
Verificada ejecución automática posterior con código 0, sin forzar otro cierre
manual. La tarea queda habilitada para las siguientes ejecuciones.

Reglas Corporate **0.29.0**: suspender/desactivar un usuario motorista retira
y reasigna sus servicios; lo ya recogido continúa hacia destino, con traspaso
físico coordinado fuera de la app. Sin candidato queda marcado para reintento.
El día civil termina a medianoche según el país de la empresa; los servicios
abiertos vencidos se cierran como recolección/entrega fallida. Ver la sección
«Contingencias y cierre diario corporativo (0.29.0)», incluidos los campos
nuevos y la tarea local de Windows, registrada el 2026-10-17.

Correcciones **0.28.2**: cerrar una solicitud conserva `PAUSED`, `OFFLINE`
y `OUT_OF_SERVICE`. Un especial con sincronización verificada sella todo
el prefijo GPS de su jornada hasta su cierre: solo admite repeticiones
idénticas de esos puntos, sin impedir registros posteriores. Ver la sección
«Disponibilidad e inmutabilidad del GPS especial (0.28.2)».

Validaciones vigentes desde **0.28.1**: las cuentas de superadministración
están protegidas frente a administradores de empresa; toda transición
operativa del motorista exige jornada activa; las imágenes se verifican y
decodifican antes de aceptarse. Ver «Correcciones de integridad operativa
(0.28.1)». No se añaden endpoints, campos de entrada ni migraciones.

Regla vigente: la sección «Control de GPS y consolidación de kilometraje
(0.26.0)» sustituye las descripciones anteriores de asignación sin GPS y
congelación inmediata del kilometraje de cierres nuevos.

La sección «Ruta inicial para el mapa integrado (0.28.0)» sustituye las
descripciones anteriores que indican que `mi-ruta/` no ofrece un trazado
o que `ruta_calculada` siempre es `false`. Se retiró el campo `navegacion`
de 0.27.0 y su generador de enlaces externos. VitaGo no debe abrir otra app:
ahora devuelve `mapa` y conserva `ruta_vial` para dibujar dentro de la app.
Este cambio requiere actualizar el parseo del frontend. No activa Google
ni cambia conexiones; el mapa móvil y su clave SDK corresponden al frontend.

## 2. Historial de cambios

| Versión | Fecha | Cambio |
| 0.42.0 | 2026-10-29 | Una jornada por día, corte operativo a las 22:00, almuerzo del motorista y filtro administrativo. Código/migración/programador externos pendientes en Render. |
|---|---|---|
| 0.41.0 | 2026-10-28 | Cupos por empresa Corporate o generales Network, manteniendo cupo individual y retirando PATCH de límites por motorista. Configuración auditada, con permisos de alcance completo. 741 pruebas backend aprobadas y24 PostgreSQL omitidas; migración local aplicada y externa pendiente. |
| 0.40.2 | 2026-10-27 | CORS por origen web explícito para API v1; dominio Render y origen Vercel configurados, JWT/móvil conservados. 723 pruebas backend aprobadas y22 PostgreSQL omitidas; publicación pendiente según reporte del backend. |
| 0.40.1 | 2026-10-27 | Corporate de pruebas en Render con autenticación LOCAL mediante ENTORNO=PRUEBAS. Se conserva HTTPS y contrato HTTP. Diagnóstico de500 y corrección de base externa documentados por backend, sin cambios de URL móvil. |
| 0.40.0 | 2026-10-27 | Reportes administrativos por motorista: resumen diario listado/detalle y temperaturas paginadas, con alcances estrictos, fechas del servidor y kilómetros por cierre. 704 pruebas backend aprobadas y22 PostgreSQL omitidas. |
| 0.39.0 | 2026-10-27 | Cantidad de tubos obligatoria; reserva y cupo por motorista, límite administrativo, regularización histórica y temperatura manual con foto de recolección. Ambos modos, manteniendo cinco solicitudes y el flujo 0.38.0. 670 pruebas backend aprobadas y 22 PostgreSQL omitidas; migraciones aplicadas por backend. |
| 0.38.0 | 2026-10-26 | Plan por paradas cercanas, intercalando solicitudes normales con precedencia de recolección. Foto201 puede devolver PICKED_UP o IN_TRANSIT; la siguiente parada se activa en backend. Prioritario y especial conservan sus reglas. 644 pruebas backend aprobadas y 21 PostgreSQL omitidas; sin migraciones ni cambios de conexión. |
| 0.37.0 | 2026-10-26 | Corporate ENTRE_SUCURSALES por misma empresa/país/departamento, admitiendo otras ciudades/municipios y viajes largos. Flota Corporate exclusiva por empresa; candidatos Network globales entre clientes, sin mezclar visibilidad. 25 regresiones;624 aprobadas/21 PG omitidas. Sin migraciones/red/datos alterados. |
| 0.36.1 | 2026-10-26 | Solo carga de datos: 34 sucursales/ubicaciones y 34 cuentas limitadas a su sucursal en Analiza Corporate; coordenadas normalizadas no verificadas. Se conservan dos sucursales de prueba. Sin cambios HTTP/lógica/red; 34 credenciales y 34 opciones de creación comprobadas. |
| 0.36.0 | 2026-10-26 | Flujo automático: activa solo el vigente, GPS acredita llegada, foto válida completa etapa y activa siguiente. Mi-ruta añade flujo_actual; evidencia añade estado_solicitud. Sin aceptación/selección de etapa; especial sin destino conserva señal manual. Sin migraciones/Google. 599 pruebas backend aprobadas y 21 PostgreSQL omitidas. |
| 0.35.0 | 2026-10-23 | Orden CERCANIA_GPS calculado en el backend y guardado por servicio completo; mantiene servicio en curso, prioritarios/especiales y respaldo sin GPS. GET/GPS no reorganizan ni llaman a Google. 26 pruebas backend nuevas; 568 aprobadas y 21 PostgreSQL omitidas. Sin migraciones. |
| 0.34.0 | 2026-10-23 | Polilíneas por envío/parada en una única consulta inicial; tramos pendientes, tramo actual y selección visual sin alterar orden. Cálculo anterior sin desglose solo se actualiza explícitamente y con presupuesto. Geometrías comparten TTL/limpieza; rutas.0003 aplicada en ambas bases por backend. 542 pruebas backend aprobadas y 21 PG omitidas. |
| 0.33.0 | 2026-10-23 | Avisos del día del servidor: listado/conteo excluyen días anteriores desde medianoche sin depender de tarea ni teléfono. Archivado recuperable sin borrar historial ni tocar operación. Migración notificaciones.0003 aplicada en ambas bases; tareas nuevas independientes. 520 pruebas backend aprobadas y 21 PG omitidas. |
| 0.32.0 | 2026-10-23 | Llegada automática por GPS a la próxima parada, auditada y sin completar el servicio. Nuevos campos `llegadas_detectadas`/`llegada_actual` y configuración de geocerca. Llegadas manuales con coordenadas rechazadas; destino especial sin coordenadas conserva confirmación manual. Reemplazo de motorista que ya llegó continúa IN_TRANSIT y acredita su propia llegada. Sin migraciones ni consultas Google. |
| 0.31.0 | 2026-10-22 | Resumen diario de entregas con fecha operativa; diagnóstico GPS; errores seguros; pérdida de rol recupera servicios y excluye disponibilidad; corte diario reforzado en jornada/ruta. Clave Corporate renovada y depuración desactivada. 445 pruebas aprobadas y 21 omitidas por requerir PostgreSQL. Sin migraciones ni cambios de conexión. |
| 0.30.4 | 2026-10-22 | Routes habilitada solo en Corporate con limpieza Windows horaria y al iniciar sesión, registro propio y protección de entorno. Ocho pruebas nuevas; suite SQLite: 380 aprobadas y 21 omitidas por requerir PostgreSQL. Sin cambios HTTP ni migraciones; sin nuevas consultas Google. |
| 0.30.3 | 2026-10-21 | Corregido deadlock por referencias de paradas a solicitudes bloqueadas: FOR NO KEY UPDATE en servicios de solicitud, conservando bloqueo de motorista. Catorce escenarios concurrentes nuevos; 393 pruebas aprobadas en PostgreSQL. Sin cambios HTTP, migraciones o conexión. |
| 0.30.2 | 2026-10-21 | Verificación PostgreSQL: 44 pruebas de autenticación aprobadas, siete escenarios nuevos de concurrencia repetidos con otros órdenes. Grupos de 24 conexiones y dos procesos independientes. Sin cambios de lógica/API; base temporal exclusiva eliminada al terminar. |
| 0.30.1 | 2026-10-21 | Solo login: 10 fallos por correo/IP en ventana fija de 15 minutos del servidor; luego 429 con espera. Contador HMAC transaccional en PostgreSQL; no suspensión ni límite de renovación. autenticacion.0002 aplicada en ambas bases. 372 pruebas aisladas aprobadas. |
| 0.30.0 | 2026-10-20 | Hora oficial de evidencias/incidencias desde servidor; entradas capturada_en/reportada_en ignoradas y opcionales. Configuración GPS publica hora y zona para sincronización móvil, sin alterar capturas/cola. Compensación de archivo nuevo compartida y preservación del error original. 353 pruebas aisladas; sin migraciones. |
| 0.29.4 | 2026-10-20 | Corregido conteo de entregas al coincidir entregada_en y el cierre de su asignación FINALIZADA. Conserva atribución por motorista y excluye por igualdad asignaciones canceladas/reasignadas. Sin cambios de API, migraciones ni recálculo histórico. 344 pruebas aisladas aprobadas. |
| 0.29.3 | 2026-10-17 | Segunda refactorización interna: cierre de jornada compartido, conservando validaciones manuales, corte automático a medianoche, GPS y auditoría. Sin cambios de API, esquema, conexión o tarea. 342 pruebas aisladas aprobadas. |
| 0.29.2 | 2026-10-17 | Primera refactorización interna: se centraliza el guardado y auditoría de estado/capacidad del motorista, eliminando cuatro implementaciones repetidas. Sin cambios de contrato, esquema, conexión ni tarea programada. 333 pruebas aprobadas. |
| 0.29.1 | 2026-10-17 | Tarea local Corporate registrada tras autorización; primera recuperación automática de una solicitud y una jornada. Corregida salida sin consola en pythonw, conservando registro y errores operativos. Sin cambios de contrato ni esquema. |
| 0.29.0 | 2026-10-16 | Corporate: reasignación por suspensión, conservación de fase tras recolección y cola de contingencias; tramos especiales por motorista; cierre diario a medianoche con fallos auditados, recuperación local y campos compatibles de cierre. Tres migraciones aplicadas en ambas bases; tarea de Windows preparada, no registrada. |
| 0.28.2 | 2026-10-16 | Cierre de solicitudes sin levantar pausa, desconexión o fuera de servicio; rechazo atómico e indexado de puntos nuevos que contradigan el prefijo GPS de un especial verificado, conservando reintentos idénticos y continuación de jornada. |
| 0.28.1 | 2026-10-16 | Se protege la administración de cuentas de plataforma, se exige jornada activa al operar solicitudes, se corrige el bloqueo PostgreSQL de sincronización GPS de especiales y se rechazan imágenes corruptas mediante Pillow, con límites de tamaño y píxeles. |
| 0.28.0 | 2026-10-14 | Mapa integrado como único flujo: se elimina `navegacion` y el generador de enlaces externos, se añade `mapa` con visibilidad de mapa/trazado y prohibición de navegación externa. Se mantienen rutas, GPS, límites y envíos especiales sin mapa; no hay migraciones ni cambios de conexión. |
| 0.27.0 | 2026-10-13 | Navegación externa a próxima parada sin clave; POST explícito de ruta inicial para motocicleta, GPS vigente, reutilización al completar paradas, presupuesto transaccional y reintentos acotados. Proveedor Google preparado y desactivado; geometría temporal y métricas no persistidas. |
| 0.26.0 | 2026-10-13 | Asignación con GPS vigente por defecto; sesión/secuencia GPS; filtros de huecos y deriva; cierre operativo independiente de consolidación; calidad, minutos operativos y revisiones auditables; exclusividad del prioritario recogido validada al operar. |
| 0.25.2 | 2026-10-06 | Se añadieron consultas paginadas de rutas y versiones históricas, más el detalle de paradas congeladas por versión, con acceso del motorista propietario o de supervisión autorizada. |
| 0.25.1 | 2026-10-06 | `mi-ruta/` añade `ruta_id` y `version_actual`; el backend conserva versiones inmutables del orden de paradas, sin calcular navegación vial. |
| 0.25.0 | 2026-10-06 | Se añadió `GET /api/v1/rutas/mi-ruta/`: paradas operativas pendientes y próxima parada para el motorista propietario, con orden provisional por asignación, prioridad recogida primero y envío especial sin mapa. |
| 0.24.0 | 2026-10-05 | Se corrigió la visibilidad global de solicitudes; el listado y detalle identifican creador y sucursal, admiten filtro por solicitante y ofrecen agrupaciones administrativas paginadas. |
| 0.23.0 | 2026-10-05 | El cierre de jornada calcula y congela kilómetros operativos con GPS válido durante asignaciones; suma envíos especiales ya cerrados y expone `kilometraje_disponible`. |
| 0.22.1 | 2026-10-02 | `opciones-creacion/` informa con `mensaje_disponibilidad` cuando no hay sucursales de origen o destino, conservando respuesta `200` y listas vacías. |
| 0.22.0 | 2026-10-01 | Corporate asigna al motorista elegible más cercano según GPS al crear; se corrigió el listado de disponibles y la consulta inicial entre sucursales. |
| 0.21.0 | 2026-10-01 | Solo motocicletas nuevas; cinco solicitudes activas calculadas por motorista; notificaciones persistentes; errores de artículos con índice y campo. |
| 0.20.1 | 2026-09-30 | Se preparó un escenario ficticio local de Analiza para probar las pantallas de solicitante y motorista; no cambia el contrato HTTP. |
| 0.20.0 | 2026-09-29 | Se agregó la consulta del perfil propio del motorista, con estado, capacidad y vehículo, sin ampliar el acceso a otros perfiles. |
| 0.19.1 | 2026-09-29 | Se agregó una guía de integración para las pantallas del motorista y se aclararon las limitaciones actuales de perfil propio, rutas y kilometraje. |
| 0.19.0 | 2026-09-29 | Se agregaron opciones de creación filtradas por modalidad y el resumen de solicitudes visibles para construir las pantallas del solicitante. |
| 0.18.0 | 2026-09-29 | Se unificó la supervisión corporativa en `GERENTE_OPERACIONES`, que ahora administra usuarios y roles operativos. |
| 0.17.0 | 2026-09-28 | Se agregaron las modalidades exclusivas de Analiza, el rol gerente de operaciones y el kilometraje GPS congelado de envíos especiales. |
| 0.16.0 | 2026-09-28 | Se documentaron los JSON completos de solicitudes, vehículos, motoristas, asignaciones y transiciones, junto con los permisos operativos exactos. |
| 0.15.0 | 2026-09-26 | Se agregaron reporte, consulta, revisión auditada y evidencias privadas de incidencias operativas. |
| 0.14.0 | 2026-09-26 | Se agregaron recepción GPS por lotes, reintentos idempotentes, clasificación operativa y seguimiento contextual de solicitudes activas. |
| 0.13.0 | 2026-09-26 | Se agregaron inicio, consulta, historial y finalización de jornadas de motoristas con resumen operativo congelado. |
| 0.12.0 | 2026-09-26 | Se agregaron transiciones operativas controladas, evidencias privadas de recolección/entrega/incidencia y cierre automático de asignaciones. |
| 0.11.0 | 2026-09-25 | Ubicaciones expone `departamento`, `municipio`, `ciudad` y `colonia`; se retiraron los nombres públicos genéricos de niveles administrativos. |
| 0.10.0 | 2026-09-25 | Se agregaron vehículos, motoristas, disponibilidad operativa y asignación/reasignación manual de solicitudes con historial. |
| 0.9.0 | 2026-09-24 | Se agregó el catálogo de tipos de servicio y la creación, listado y detalle de solicitudes con visibilidad por responsabilidad. |
| 0.8.0 | 2026-09-24 | Se agregó la consulta, asignación y revocación auditada de roles de usuarios. |
| 0.7.0 | 2026-09-24 | Se agregó el detalle, actualización de perfil/estado y restablecimiento administrativo de contraseña de usuarios. |
| 0.6.0 | 2026-09-24 | Se agregaron las API administrativas para usuarios, roles asignables, ubicaciones autorizadas y creación de sucursales. |
| 0.5.0 | 2026-09-24 | Se agregó el catálogo inicial y la consulta protegida de tipos de ubicación. |
| 0.4.0 | 2026-09-24 | Se agregaron consultas paginadas de empresas y sucursales con autorización por permiso y alcance. |
| 0.3.0 | 2026-09-22 | Se separó el modo de aplicación del proveedor de autenticación; Corporate puede usar autenticación local únicamente durante el desarrollo. |
| 0.2.0 | 2026-09-22 | Se agregó la consulta protegida del perfil local, contexto organizacional, roles y permisos vigentes. |
| 0.1.2 | 2026-09-22 | Se agregó medición de rendimiento mediante `Server-Timing` sin modificar los cuerpos JSON. |
| 0.1.1 | 2026-09-21 | Inicio de sesión reducido a correo y contraseña; renovación reducida al refresh token; errores de autenticación pública normalizados a 401. |
| 0.1.0 | 2026-09-21 | Documento inicial con salud y autenticación corporativa/externa. |

## 3. Convenciones generales

### Ruta base

Todas las rutas actuales comienzan con:

```text
/api/v1/
```

El dominio depende del entorno. El frontend debe recibirlo mediante su propia
configuración y no debe fijarlo dentro del código.

Ejemplo conceptual:

```text
https://api.ejemplo.com/api/v1/
```

### Formato

- Solicitudes y respuestas: `application/json`, salvo la carga de evidencias,
  que utiliza `multipart/form-data`.
- Identificadores: UUID representados como texto.
- Fechas: ISO 8601 con zona horaria, normalmente UTC.
- Nombres controlados por VitaGo: español en `snake_case`.
- Autorización: `Authorization: Bearer <token>`.
- Una respuesta `204 No Content` no contiene JSON.
- Las respuestas de la API pueden incluir `Server-Timing` con el tiempo interno
  de procesamiento del backend expresado en milisegundos.

Ejemplo:

```http
Server-Timing: aplicacion;dur=150.11
```

Este valor es diagnóstico y no forma parte de las decisiones funcionales del
frontend.

El frontend no debe calcular la vigencia de los tokens con duraciones
hardcodeadas. Debe usar `expira_token_acceso_en` y
`expira_token_refresco_en` recibidos del backend.

## 4. Modos de despliegue

El mismo backend se ejecuta en dos modos separados.

### CORPORATIVO

- El proveedor definitivo es el sistema corporativo central mediante JWT.
- Durante el desarrollo local puede configurarse temporalmente el proveedor
  `LOCAL`, con el mismo flujo de correo y contraseña utilizado por Network.
- En producción, VitaGo Corporate rechaza el proveedor local.
- Al activar `JWT_CORPORATIVO`, el frontend obtiene el JWT del proveedor
  corporativo y VitaGo no recibe ni almacena la contraseña corporativa.

El JWT corporativo debe contener la identidad acordada con el proveedor. El
nombre predeterminado del claim es `sub`, aunque es configurable por despliegue.

### EXTERNO

- VitaGo valida correo y contraseña.
- VitaGo devuelve access token y refresh token.
- El access token se envía en los endpoints protegidos.
- El refresh token se utiliza únicamente para renovar la sesión.
- Cada renovación reemplaza tanto el access token como el refresh token.

## 5. Resumen de endpoints disponibles

| Método | Ruta | Modo | Autenticación | Respuesta correcta |
|---|---|---|---|---|
| `GET` | `/api/v1/salud/` | Ambos | Pública | `200` |
| `POST` | `/api/v1/autenticacion/iniciar-sesion/` | Proveedor `LOCAL` | Pública | `200` |
| `POST` | `/api/v1/autenticacion/renovar/` | Proveedor `LOCAL` | Refresh token en JSON | `200` |
| `POST` | `/api/v1/autenticacion/cerrar-sesion/` | Proveedor `LOCAL` | Access token | `204` |
| `POST` | `/api/v1/autenticacion/cerrar-todas-las-sesiones/` | Proveedor `LOCAL` | Access token | `204` |
| `GET` | `/api/v1/usuarios/mi-perfil/` | Ambos | Access token de VitaGo o JWT corporativo | `200` |
| `GET` | `/api/v1/usuarios/` | Ambos | Bearer + `usuario.ver` | `200` |
| `POST` | `/api/v1/usuarios/` | Ambos | Bearer + `usuario.administrar` y `rol.asignar` | `201` |
| `GET` | `/api/v1/usuarios/roles-asignables/` | Ambos | Bearer + administración de usuarios en alcance | `200` |
| `GET` | `/api/v1/usuarios/{usuario_id}/` | Ambos | Bearer + `usuario.ver` en alcance | `200` |
| `PATCH` | `/api/v1/usuarios/{usuario_id}/` | Ambos | Bearer + `usuario.administrar` en alcance | `200` |
| `POST` | `/api/v1/usuarios/{usuario_id}/restablecer-contrasena/` | Proveedor `LOCAL` | Bearer + `usuario.administrar` en alcance | `204` |
| `GET` | `/api/v1/usuarios/{usuario_id}/roles/` | Ambos | Bearer + `usuario.ver` en alcance | `200` |
| `POST` | `/api/v1/usuarios/{usuario_id}/roles/` | Ambos | Bearer + `usuario.administrar` y `rol.asignar` en alcance | `201` |
| `DELETE` | `/api/v1/usuarios/{usuario_id}/roles/{asignacion_id}/` | Ambos | Bearer + `usuario.administrar` y `rol.asignar` en alcance | `204` |
| `GET` | `/api/v1/organizaciones/empresas/` | Ambos | Bearer + `empresa.ver` | `200` |
| `GET` | `/api/v1/organizaciones/empresas/{empresa_id}/` | Ambos | Bearer + `empresa.ver` en alcance | `200` |
| `GET` | `/api/v1/organizaciones/empresas/{empresa_id}/limites-motoristas/` | Ambos | Bearer + `empresa.ver` en alcance | `200` |
| `PATCH` | `/api/v1/organizaciones/empresas/{empresa_id}/limites-motoristas/` | Corporate | `empresa.administrar` con alcance completo de empresa/global | `200` |
| `GET` | `/api/v1/organizaciones/configuracion/limites-motoristas/` | Network | Bearer | `200` |
| `PATCH` | `/api/v1/organizaciones/configuracion/limites-motoristas/` | Network | `configuracion.administrar` global | `200` |
| `GET` | `/api/v1/organizaciones/empresas/{empresa_id}/sucursales/` | Ambos | Bearer + `sucursal.ver` en alcance | `200` |
| `POST` | `/api/v1/organizaciones/empresas/{empresa_id}/sucursales/` | Ambos | Bearer + `sucursal.administrar` en alcance | `201` |
| `GET` | `/api/v1/organizaciones/sucursales/{sucursal_id}/` | Ambos | Bearer + `sucursal.ver` en alcance | `200` |
| `GET` | `/api/v1/ubicaciones/` | Ambos | Bearer + `ubicacion.ver` en alcance | `200` |
| `POST` | `/api/v1/ubicaciones/` | Ambos | Bearer + `ubicacion.crear` en alcance | `201` |
| `GET` | `/api/v1/ubicaciones/tipos/` | Ambos | Bearer + `ubicacion.ver` | `200` |
| `GET` | `/api/v1/ubicaciones/{ubicacion_id}/` | Ambos | Bearer + `ubicacion.ver` en alcance | `200` |
| `PATCH` | `/api/v1/ubicaciones/{ubicacion_id}/autorizacion-empresa/{empresa_id}/` | Ambos | Bearer + `ubicacion.aprobar` en alcance | `200` |
| `GET` | `/api/v1/solicitudes/tipos-servicio/` | Ambos | Bearer + permiso relacionado con solicitudes | `200` |
| `GET` | `/api/v1/solicitudes/opciones-creacion/` | Corporate | Bearer + `solicitud.crear` en alcance | `200` |
| `GET` | `/api/v1/solicitudes/resumen-solicitante/` | Ambos | Bearer + visibilidad de solicitudes | `200` |
| `GET` | `/api/v1/solicitudes/` | Ambos | Bearer + visibilidad de solicitudes | `200` |
| `GET` | `/api/v1/solicitudes/agrupaciones/` | Ambos | Bearer + `solicitud.ver` en alcance administrativo | `200` |
| `POST` | `/api/v1/solicitudes/` | Corporate | Bearer + `solicitud.crear`; especiales requieren además `solicitud.crear_envio_especial` con alcance de empresa | `201` |
| `GET` | `/api/v1/solicitudes/{solicitud_id}/` | Ambos | Bearer + visibilidad de la solicitud | `200` |
| `POST` | `/api/v1/solicitudes/{solicitud_id}/asignaciones/` | Ambos | Bearer + `solicitud.asignar` o `solicitud.reasignar` | `201` |
| `POST` | `/api/v1/solicitudes/{solicitud_id}/transiciones/` | Ambos | Motorista asignado + `solicitud.actualizar_estado`, o `solicitud.cancelar` para cancelar | `200` |
| `GET` | `/api/v1/solicitudes/{solicitud_id}/evidencias/` | Ambos | Bearer + visibilidad de solicitud + `evidencia.ver` | `200` |
| `POST` | `/api/v1/solicitudes/{solicitud_id}/evidencias/` | Ambos | Motorista asignado + `evidencia.crear` | `201` |
| `GET` | `/api/v1/solicitudes/{solicitud_id}/evidencias/{evidencia_id}/archivo/` | Ambos | Bearer + visibilidad de solicitud + `evidencia.ver` | `200` |
| `GET` | `/api/v1/vehiculos/` | Ambos | Bearer + `vehiculo.ver` | `200` |
| `POST` | `/api/v1/vehiculos/` | Ambos | Bearer + `vehiculo.administrar` | `201` |
| `GET` | `/api/v1/vehiculos/{vehiculo_id}/` | Ambos | Bearer + `vehiculo.ver` en alcance | `200` |
| `GET` | `/api/v1/repartidores/` | Ambos | Bearer + `repartidor.ver` | `200` |
| `GET` | `/api/v1/repartidores/resumenes/` | Ambos | Cinco permisos administrativos y alcance completo del motorista; ver0.40.0 | `200` |
| `GET` | `/api/v1/repartidores/{repartidor_id}/resumen/` | Ambos | Cinco permisos administrativos y alcance completo del motorista; ver0.40.0 | `200` |
| `GET` | `/api/v1/repartidores/{repartidor_id}/temperaturas/` | Ambos | Cinco permisos administrativos y alcance completo del motorista; ver0.40.0 | `200` |
| `POST` | `/api/v1/repartidores/` | Ambos | Bearer + `repartidor.administrar` | `201` |
| `GET` | `/api/v1/repartidores/disponibles/` | Ambos | Bearer + `repartidor.ver` | `200` |
| `GET` | `/api/v1/repartidores/mi-perfil/` | Ambos | Motorista autenticado con perfil activo | `200` |
| `GET` | `/api/v1/repartidores/{repartidor_id}/` | Ambos | Bearer + `repartidor.ver` en alcance | `200` |
| `PATCH` | `/api/v1/repartidores/{repartidor_id}/operacion/` | Ambos | Motorista propio o `repartidor.administrar` | `200` |
| `GET` | `/api/v1/notificaciones/` | Ambos | Bearer; solo las propias | `200` |
| `GET` | `/api/v1/notificaciones/conteo-no-leidas/` | Ambos | Bearer; solo las propias | `200` |
| `POST` | `/api/v1/notificaciones/{notificacion_id}/marcar-leida/` | Ambos | Bearer; solo la propia | `200` |
| `POST` | `/api/v1/jornadas/iniciar/` | Ambos | Motorista propio + `jornada.iniciar` | `201` |
| `GET` | `/api/v1/jornadas/activa/` | Ambos | Motorista propio + `jornada.ver` | `200` |
| `GET` | `/api/v1/jornadas/` | Ambos | Bearer + `jornada.ver` | `200` |
| `GET` | `/api/v1/jornadas/{jornada_id}/` | Ambos | Bearer + `jornada.ver` en alcance | `200` |
| `POST` | `/api/v1/jornadas/{jornada_id}/finalizar/` | Ambos | Motorista propietario + `jornada.finalizar` | `200` |
| `GET` | `/api/v1/rutas/mi-ruta/` | Ambos | Motorista propio + `solicitud.ver_asignadas` | `200` |
| `POST` | `/api/v1/rutas/mi-ruta/calcular/` | Ambos | Motorista propio + `solicitud.ver_asignadas` + `ruta.calcular` | `200` |
| `GET` | `/api/v1/rutas/` | Ambos | Propietario + `ruta.ver`, o administración autorizada | `200` |
| `GET` | `/api/v1/rutas/{ruta_id}/versiones/` | Ambos | Misma visibilidad de la ruta | `200` |
| `GET` | `/api/v1/rutas/{ruta_id}/versiones/{numero}/` | Ambos | Misma visibilidad de la ruta | `200` |
| `POST` | `/api/v1/seguimiento/registros/` | Ambos | Motorista propio + `repartidor.registrar_ubicacion` | `201` |
| `GET` | `/api/v1/solicitudes/{solicitud_id}/seguimiento/` | Ambos | Visibilidad de solicitud + `solicitud.ver_seguimiento` | `200` |
| `GET` | `/api/v1/incidencias/` | Ambos | Motorista propio o `incidencia.revisar` en alcance | `200` |
| `POST` | `/api/v1/incidencias/` | Ambos | Motorista propio + `incidencia.crear` | `201` |
| `GET` | `/api/v1/incidencias/{incidencia_id}/` | Ambos | Motorista propietario o `incidencia.revisar` en alcance | `200` |
| `POST` | `/api/v1/incidencias/{incidencia_id}/revision/` | Ambos | Bearer + `incidencia.revisar` en alcance | `200` |
| `GET` | `/api/v1/incidencias/{incidencia_id}/evidencias/` | Ambos | Visibilidad de incidencia | `200` |
| `POST` | `/api/v1/incidencias/{incidencia_id}/evidencias/` | Ambos | Motorista propietario + `evidencia.crear` | `201` |
| `GET` | `/api/v1/incidencias/{incidencia_id}/evidencias/{evidencia_id}/archivo/` | Ambos | Visibilidad de incidencia | `200` |

## 6. Respuestas de error

### Error general

Los errores de autenticación o disponibilidad normalmente tienen esta forma:

```json
{
  "detail": "Descripción del error."
}
```

### Error de validación

Los campos inválidos se devuelven por nombre:

```json
{
  "correo": [
    "Introduzca una dirección de correo electrónico válida."
  ],
  "contrasena": [
    "Este campo es requerido."
  ]
}
```

### Códigos actuales

| Código | Significado para el frontend |
|---|---|
| `400` | Faltan campos o el formato enviado no es válido. |
| `401` | Las credenciales o el token son inválidos, expiraron o corresponden a una sesión revocada. |
| `429` | El login alcanzó diez fallos en la ventana de 15 minutos. Respetar `Retry-After`; no tratar como error de conexión. |
| `403` | El usuario está autenticado, pero no posee el permiso requerido en ningún alcance. |
| `404` | El endpoint no está disponible con el proveedor de autenticación actual. |
| `409` | La operación entra en conflicto con una regla vigente; actualmente se usa para impedir solicitudes Network sin cotización. |
| `500` | Error interno no esperado; no debe mostrarse el detalle técnico al usuario. |

Los mensajes sirven para informar al usuario, pero el flujo del frontend debe
decidirse principalmente por el código HTTP.

## 7. Salud del servicio

### `GET /api/v1/salud/`

Comprueba que el proceso HTTP de VitaGo responde.

Autenticación: no requerida.

Respuesta `200 OK`:

```json
{
  "estado": "correcto",
  "servicio": "VitaGo"
}
```

`servicio` identifica la instancia configurada. En el entorno local de
Corporate su valor es `VitaGo Corporate`; en Network es `VitaGo`.

Este endpoint no confirma por sí solo que PostgreSQL o servicios externos estén
disponibles.

## 8. Inicio de sesión local

### `POST /api/v1/autenticacion/iniciar-sesion/`

Disponible cuando `PROVEEDOR_AUTENTICACION=LOCAL`, tanto en Network como en el
entorno local temporal de Corporate.

Autenticación: no requerida.

Solicitud:

```json
{
  "correo": "usuario@empresa.com",
  "contrasena": "valor-secreto"
}
```

Campos:

| Campo | Tipo | Obligatorio | Regla |
|---|---|---|---|
| `correo` | texto | Sí | Correo válido, máximo 254 caracteres. |
| `contrasena` | texto | Sí | Máximo 128 caracteres. |

El backend obtiene automáticamente la dirección IP y el agente de usuario que
estén disponibles en la solicitud; el frontend no envía datos del dispositivo
en este contrato.

Respuesta `200 OK`:

```json
{
  "token_acceso": "eyJ...",
  "token_refresco": "eyJ...",
  "tipo_token": "Bearer",
  "expira_token_acceso_en": "2026-09-21T20:00:00Z",
  "expira_token_refresco_en": "2026-09-28T19:45:00Z",
  "sesion_id": "0b6be16f-4695-46ec-8d75-dbf2566e49e2",
  "usuario": {
    "id": "40bc6f06-8634-4103-93d9-aeebda6b19e0",
    "correo": "usuario@empresa.com",
    "nombres": "Nombre",
    "apellidos": "Apellido"
  }
}
```

Errores relevantes:

- `400`: campos inválidos o ausentes.
- `401`: credenciales inválidas o usuario inactivo.
- `404`: proveedor `JWT_CORPORATIVO`; Corporate con proveedor `LOCAL` sí permite login.
- `429`: combinación de correo/IP con diez fallos en su ventana de 15 minutos.

El backend utiliza un mensaje genérico para no revelar si un correo está
registrado. Los diez primeros fallos reciben `401`; el siguiente intento recibe
`429`, incluso si ahora incluye la contraseña correcta. Un éxito anterior al
límite reinicia los fallos. La espera vence 15 minutos después del primer fallo,
no 15 minutos después de cada petición bloqueada. Ver contrato completo 0.30.1.

## 9. Renovación de sesión externa

### `POST /api/v1/autenticacion/renovar/`

Disponible únicamente cuando `PROVEEDOR_AUTENTICACION=LOCAL`.

Autenticación: el refresh token se envía en el cuerpo; no requiere access token.

Solicitud:

```json
{
  "token_refresco": "eyJ..."
}
```

Campos:

| Campo | Tipo | Obligatorio | Regla |
|---|---|---|---|
| `token_refresco` | texto | Sí | Máximo 4096 caracteres. |

Respuesta `200 OK`:

```json
{
  "token_acceso": "eyJ...",
  "token_refresco": "eyJ...",
  "tipo_token": "Bearer",
  "expira_token_acceso_en": "2026-09-21T20:15:00Z",
  "expira_token_refresco_en": "2026-09-28T20:00:00Z",
  "sesion_id": "91991cc7-5764-47cf-946c-7f464665d7b8"
}
```

Reglas para el frontend:

1. Reemplazar de forma conjunta los dos tokens anteriores.
2. No intentar reutilizar el refresh token anterior.
3. Evitar renovaciones paralelas de la misma sesión.
4. Si la renovación falla, eliminar las credenciales locales y solicitar un
   nuevo inicio de sesión.

Errores relevantes:

- `400`: entrada inválida.
- `401`: token inválido, expirado, revocado o reutilizado.
- `404`: proveedor `JWT_CORPORATIVO`; con proveedor `LOCAL` permanece disponible.

La reutilización de un refresh token revocado puede invalidar la familia de
sesiones activa como medida de seguridad.

## 10. Cierre de la sesión actual

### `POST /api/v1/autenticacion/cerrar-sesion/`

Disponible únicamente cuando `PROVEEDOR_AUTENTICACION=LOCAL`.

Encabezado obligatorio:

```http
Authorization: Bearer <token_acceso>
```

Cuerpo: no requerido.

Respuesta correcta:

```text
204 No Content
```

Después de recibir `204`, el frontend debe eliminar localmente el access token,
el refresh token y los datos privados asociados a la sesión.

Errores relevantes:

- `401`: access token ausente, inválido o sesión no vigente.
- `404`: endpoint no disponible con el proveedor de autenticación actual.

## 11. Cierre de todas las sesiones

### `POST /api/v1/autenticacion/cerrar-todas-las-sesiones/`

Disponible únicamente cuando `PROVEEDOR_AUTENTICACION=LOCAL`.

Encabezado obligatorio:

```http
Authorization: Bearer <token_acceso>
```

Cuerpo: no requerido.

Respuesta correcta:

```text
204 No Content
```

Revoca todas las sesiones activas del usuario, incluida la sesión que realiza la
solicitud. El frontend debe eliminar todas las credenciales locales al recibir
la respuesta.

Errores relevantes:

- `401`: access token ausente, inválido o sesión no vigente.
- `404`: endpoint no disponible con el proveedor de autenticación actual.

## 12. Perfil del usuario autenticado

### `GET /api/v1/usuarios/mi-perfil/`

Disponible en los modos `CORPORATIVO` y `EXTERNO`.

Encabezado obligatorio:

```http
Authorization: Bearer <token_acceso>
```

Con el proveedor `LOCAL` se utiliza el access token emitido por VitaGo. Con el
proveedor `JWT_CORPORATIVO` se utiliza el JWT emitido por el sistema central.

Cuerpo: no requerido.

Respuesta `200 OK`:

```json
{
  "usuario": {
    "id": "40bc6f06-8634-4103-93d9-aeebda6b19e0",
    "correo": "usuario@empresa.com",
    "nombres": "Nombre",
    "apellidos": "Apellido",
    "telefono": "+50499999999",
    "estado": "ACTIVO"
  },
  "empresa": {
    "id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96",
    "nombre": "Empresa de ejemplo"
  },
  "sucursal": null,
  "roles": [
    {
      "codigo": "SOLICITANTE_EXTERNO",
      "nombre": "Solicitante externo",
      "tipo_alcance": "EMPRESA",
      "empresa_id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96",
      "sucursal_id": null
    }
  ],
  "permisos": [
    "solicitud.crear",
    "solicitud.ver"
  ]
}
```

Reglas del contrato:

- `empresa` y `sucursal` pueden ser `null`.
- `telefono` puede ser `null` o texto vacío.
- `roles` contiene solamente asignaciones activas cuyos roles están activos.
- `tipo_alcance` puede ser `GLOBAL`, `EMPRESA` o `SUCURSAL`.
- `empresa_id` y `sucursal_id` identifican el alcance concreto del rol y
  pueden ser `null` según `tipo_alcance`.
- `permisos` contiene la unión ordenada, sin duplicados, de los permisos
  activos otorgados por los roles vigentes.
- Un superusuario recibe el catálogo completo de permisos activos.
- Un usuario sin roles recibe `roles: []` y `permisos: []`.

Los permisos recibidos sirven para construir la interfaz, pero no autorizan por
sí mismos ninguna operación. El backend vuelve a comprobar el permiso y su
alcance al atender cada endpoint protegido.

Errores relevantes:

- `401`: token ausente, inválido, expirado, revocado o perteneciente a un
  usuario inactivo.

Este endpoint es aditivo y no modifica la respuesta del inicio de sesión.

## 13. Uso del JWT corporativo

VitaGo no expone un endpoint local para iniciar sesión corporativa. El frontend
debe obtener el JWT del sistema central y enviarlo en cada endpoint protegido:

```http
Authorization: Bearer <jwt_corporativo>
```

El backend valida:

- firma RSA;
- expiración;
- issuer;
- audience;
- identificador corporativo;
- existencia y estado del usuario local.

Una respuesta `401` indica que el frontend debe solicitar al proveedor
corporativo un token válido o cerrar la sesión local. Nunca debe pedir ni enviar
la contraseña corporativa a VitaGo.

## 14. Almacenamiento y manejo de tokens

El frontend debe:

- utilizar almacenamiento seguro proporcionado por el sistema operativo;
- evitar guardar tokens en registros, analítica o mensajes de error;
- enviar el access token solamente a la API configurada de VitaGo;
- reemplazar inmediatamente el par completo después de renovar;
- limpiar tokens y datos privados al cerrar sesión;
- tratar `401` como sesión no autorizada;
- impedir que múltiples solicitudes intenten renovar simultáneamente.

El frontend no debe interpretar los claims del JWT como autorización definitiva.
Los permisos siempre los decide el backend.

## 15. Consulta de organizaciones

Todos los endpoints de esta sección requieren:

```http
Authorization: Bearer <token>
```

Las listas aceptan:

| Parámetro | Tipo | Predeterminado | Límite |
|---|---|---:|---:|
| `pagina` | entero | `1` | — |
| `tamano_pagina` | entero | `20` | `100` |

Respuesta paginada:

```json
{
  "conteo": 1,
  "pagina_siguiente": null,
  "pagina_anterior": null,
  "resultados": []
}
```

### `GET /api/v1/organizaciones/empresas/`

Devuelve únicamente las empresas visibles mediante un rol activo con el
permiso `empresa.ver`.

Respuesta `200 OK`:

```json
{
  "conteo": 1,
  "pagina_siguiente": null,
  "pagina_anterior": null,
  "resultados": [
    {
      "id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96",
      "nombre": "Analiza",
      "razon_social": null,
      "identificacion_fiscal": null,
      "telefono": null,
      "correo": null,
      "pais": {
        "id": "551f8cff-af35-480f-a803-25129d6aab03",
        "iso2": "HN",
        "nombre": "Honduras",
        "codigo_moneda": "HNL",
        "zona_horaria_predeterminada": "America/Tegucigalpa"
      },
      "estado": "ACTIVO"
    }
  ]
}
```

### `GET /api/v1/organizaciones/empresas/{empresa_id}/`

Devuelve el mismo objeto de empresa sin envoltorio de paginación. Si la empresa
existe pero está fuera del alcance del usuario, responde `404`.

### `GET /api/v1/organizaciones/empresas/{empresa_id}/sucursales/`

Devuelve las sucursales permitidas dentro de la empresa indicada. Requiere
`sucursal.ver`.

Ejemplo de elemento en `resultados`:

```json
{
  "id": "65fd8794-21a3-4a68-bc70-495355947494",
  "empresa_id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96",
  "nombre": "Principal",
  "codigo": "SPS-01",
  "telefono": null,
  "correo": null,
  "estado": "ACTIVO",
  "ubicacion": {
    "id": "2de2d88f-65b5-4e3e-951f-0f6faf8002e3",
    "nombre": "Sede principal",
    "tipo_ubicacion": {
      "id": "14f574d2-2e84-41d2-a02e-5c233f6d7685",
      "codigo": "SUCURSAL",
      "nombre": "Sucursal"
    },
    "direccion": "Dirección registrada",
    "latitud": "14.072300",
    "longitud": "-87.192100",
    "estado": "ACTIVO"
  }
}
```

### `GET /api/v1/organizaciones/sucursales/{sucursal_id}/`

Devuelve un único objeto de sucursal con la misma estructura anterior. Una
sucursal fuera del alcance responde `404`.

Reglas de autorización:

- alcance `GLOBAL`: permite todas las organizaciones correspondientes;
- alcance `EMPRESA`: permite esa empresa y todas sus sucursales;
- alcance `SUCURSAL`: permite la empresa como contexto, pero solamente las
  sucursales asignadas;
- sin el permiso requerido: `403`;
- identificador inexistente o fuera del alcance: `404`.

Las empresas continúan siendo de consulta. La creación de sucursales está
disponible para administradores y se documenta en la sección 18; todavía no se
permite editar empresas o sucursales existentes.

## 16. Tipos de ubicación

### `GET /api/v1/ubicaciones/tipos/`

Devuelve el catálogo activo de tipos de ubicación. Requiere token Bearer y el
permiso `ubicacion.ver` en al menos un alcance vigente.

Respuesta `200 OK`:

```json
{
  "resultados": [
    {
      "id": "5f5763a1-9b81-4aec-ae87-a992f3f14039",
      "codigo": "HOSPITAL",
      "nombre": "Hospital"
    }
  ]
}
```

Catálogo inicial:

| Código | Nombre |
|---|---|
| `HOSPITAL` | Hospital |
| `CLINICA` | Clínica |
| `LABORATORIO_CLINICO` | Laboratorio clínico |
| `CONSULTORIO` | Consultorio |
| `FARMACIA` | Farmacia |
| `BANCO_SANGRE` | Banco de sangre |
| `CENTRO_IMAGENES` | Centro de imágenes |
| `CENTRO_MEDICO` | Centro médico |
| `SUCURSAL` | Sucursal |
| `RESIDENCIA` | Residencia |
| `EMPRESA` | Empresa |
| `EMPRESA_TRANSPORTE` | Empresa de transporte |
| `OTRO` | Otro |

El catálogo no utiliza paginación. Solo devuelve registros activos y se ordena
por nombre. Una respuesta `403` indica que el usuario no posee
`ubicacion.ver`.

## 17. Administración de usuarios

No existe registro público. Estas rutas están destinadas al panel
administrativo y siempre vuelven a validar permisos y alcance en el backend.

### `GET /api/v1/usuarios/`

Devuelve una lista paginada. Requiere `usuario.ver`. Un alcance de empresa ve
los usuarios de esa empresa; un alcance de sucursal ve únicamente esa sucursal;
un alcance global puede ver todos.

Cada elemento incluye:

```json
{
  "id": "40bc6f06-8634-4103-93d9-aeebda6b19e0",
  "correo": "usuario@empresa.com",
  "nombres": "Nombre",
  "apellidos": "Apellido",
  "telefono": null,
  "empresa_id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96",
  "sucursal_id": null,
  "estado": "ACTIVO",
  "roles": [
    {
      "codigo": "SOLICITANTE_EXTERNO",
      "nombre": "Solicitante externo",
      "tipo_alcance": "EMPRESA",
      "empresa_id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96",
      "sucursal_id": null
    }
  ],
  "creado_en": "2026-09-24T16:00:00Z"
}
```

### `GET /api/v1/usuarios/roles-asignables/`

Parámetros obligatorios según el alcance que se desea asignar:

| Campo | Regla |
|---|---|
| `tipo_alcance` | `GLOBAL`, `EMPRESA` o `SUCURSAL`. |
| `empresa_id` | Obligatorio para `EMPRESA` y `SUCURSAL`. |
| `sucursal_id` | Obligatorio solamente para `SUCURSAL`. |

Devuelve únicamente roles compatibles con Corporate o Network incluidos en la
matriz de delegación del administrador. Un administrador corporativo puede
crear administradores, gerentes de operaciones, solicitantes y repartidores
corporativos, pero no superadministradores. Un gerente de operaciones puede
crear usuarios y asignar solamente `SOLICITANTE_CORPORATIVO` o
`REPARTIDOR_CORPORATIVO` dentro de su empresa. No puede crear administradores
ni otros gerentes, ni modificar, suspender o restablecer las credenciales de
administradores u otros gerentes. Un administrador de empresa externa puede crear
administradores o solicitantes de su propia empresa.

### `POST /api/v1/usuarios/`

Con el proveedor `LOCAL`:

```json
{
  "correo": "usuario@empresa.com",
  "nombres": "Nombre",
  "apellidos": "Apellido",
  "telefono": "+50499999999",
  "contrasena_temporal": "valor-secreto",
  "rol_codigo": "SOLICITANTE_EXTERNO",
  "tipo_alcance": "EMPRESA",
  "empresa_id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96"
}
```

Con `JWT_CORPORATIVO`, no se admite `contrasena_temporal` y se exige
`identificador_autenticacion_externa`. La contraseña nunca se devuelve. El
usuario y su primer rol se crean en una sola transacción.

Errores relevantes:

- `400`: datos inválidos, correo duplicado o contraseña débil;
- `403`: faltan permisos, el alcance no está permitido o el rol produciría una
  escalación de privilegios;
- `404`: empresa o sucursal inexistente, inactiva o fuera del alcance.

### `GET /api/v1/usuarios/{usuario_id}/`

Devuelve el mismo objeto documentado en el listado. Requiere `usuario.ver` en
un alcance que incluya al usuario solicitado. Un usuario existente fuera del
alcance responde `404` para no revelar información.

### `PATCH /api/v1/usuarios/{usuario_id}/`

Permite actualizar uno o más de estos campos:

```json
{
  "nombres": "Nombre actualizado",
  "apellidos": "Apellido actualizado",
  "telefono": "+50499999999",
  "estado": "SUSPENDIDO"
}
```

Los estados admitidos son `ACTIVO`, `INACTIVO` y `SUSPENDIDO`. El correo, la
empresa, la sucursal y los roles no se modifican mediante esta ruta. Cambiar un
usuario a `INACTIVO` o `SUSPENDIDO` revoca inmediatamente todas sus sesiones
activas. Un administrador no puede inactivar ni suspender su propia cuenta.

Respuesta correcta: `200 OK` con el objeto actualizado.

Errores relevantes:

- `400`: no se envió ningún campo, un valor es inválido o el administrador
  intentó inactivar/suspender su propia cuenta;
- `403`: falta `usuario.administrar`;
- `404`: el usuario no existe o está fuera del alcance permitido.

No existe eliminación física de usuarios; deben conservarse y cambiarse de
estado para mantener la trazabilidad.

### `POST /api/v1/usuarios/{usuario_id}/restablecer-contrasena/`

Disponible únicamente cuando el proveedor configurado es `LOCAL`.

```json
{
  "contrasena_temporal": "Nueva-Clave-Temporal-2026!"
}
```

La contraseña se valida con las políticas de Django, se almacena mediante el
hasher configurado y nunca se devuelve. El cambio revoca todas las sesiones
activas del usuario, por lo que deberá iniciar sesión de nuevo.

Respuesta correcta: `204 No Content`.

Errores relevantes:

- `400`: la contraseña no cumple la política configurada;
- `403`: falta `usuario.administrar` en el alcance del usuario;
- `404`: usuario inexistente/fuera de alcance o proveedor
  `JWT_CORPORATIVO`, donde la contraseña pertenece al sistema central.

### `GET /api/v1/usuarios/{usuario_id}/roles/`

Devuelve el historial de asignaciones de rol que el administrador puede ver
según `usuario.ver` y su alcance. Incluye asignaciones activas y revocadas:

```json
{
  "resultados": [
    {
      "id": "bed1b535-6775-4e42-aec7-e3b4273f6424",
      "rol": {
        "codigo": "SOLICITANTE_EXTERNO",
        "nombre": "Solicitante externo",
        "descripcion": "Solicitudes de una empresa externa.",
        "permite_alcance_global": false,
        "permite_alcance_empresa": true,
        "permite_alcance_sucursal": true
      },
      "tipo_alcance": "EMPRESA",
      "empresa_id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96",
      "sucursal_id": null,
      "activo": true,
      "asignado_por_id": "756ecf12-b8ae-42ce-af5e-3e88518c2896",
      "asignado_en": "2026-09-24T18:00:00Z",
      "revocado_por_id": null,
      "revocado_en": null
    }
  ]
}
```

La lista no se pagina porque el historial de roles por usuario debe ser
pequeño. Las asignaciones activas aparecen primero.

### `POST /api/v1/usuarios/{usuario_id}/roles/`

Solicitud:

```json
{
  "rol_codigo": "SOLICITANTE_EXTERNO",
  "tipo_alcance": "EMPRESA",
  "empresa_id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96",
  "sucursal_id": null
}
```

`empresa_id` es obligatorio para los alcances `EMPRESA` y `SUCURSAL`;
`sucursal_id` es obligatorio únicamente para `SUCURSAL`. El rol debe obtenerse
previamente desde `roles-asignables` para el mismo alcance. La respuesta
`201 Created` contiene la asignación creada con el formato anterior.

El backend impide:

- asignaciones activas duplicadas;
- roles incompatibles con Corporate o Network;
- roles fuera de la matriz de delegación del administrador;
- alcances de otra empresa o sucursal del usuario;
- escalación de privilegios.

Una asignación revocada no se reactiva ni se sobrescribe: si se concede de
nuevo, se crea otra asignación para conservar el historial.

### `DELETE /api/v1/usuarios/{usuario_id}/roles/{asignacion_id}/`

Revoca la asignación sin eliminarla físicamente. Registra el administrador y
la fecha de revocación, y cierra todas las sesiones locales activas del usuario
para que los cambios de autorización tengan efecto inmediato.

Respuesta correcta: `204 No Content`.

Protecciones:

- un administrador no puede quitarse su último rol administrativo en el
  alcance;
- no se puede dejar un alcance sin al menos otro administrador vigente;
- solamente se puede revocar un rol que el administrador también podría
  asignar;
- una asignación ya revocada responde como no encontrada.

Errores relevantes para asignar o revocar:

- `400`: asignación duplicada o protección del último administrador;
- `403`: faltan permisos, el rol no es delegable o produciría escalación;
- `404`: usuario/asignación inexistente, revocada o fuera del alcance.

## 18. Administración de ubicaciones y sucursales

### `GET /api/v1/ubicaciones/?empresa_id={empresa_id}`

`empresa_id` es obligatorio. Devuelve las relaciones de ubicaciones visibles
para la empresa indicada con paginación estándar:

```json
{
  "id": "9843ca95-dc25-4a36-a55c-764b04e900f7",
  "empresa_id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96",
  "permite_origen": true,
  "permite_destino": true,
  "estado": "APROBADO",
  "ubicacion": {
    "id": "2de2d88f-65b5-4e3e-951f-0f6faf8002e3",
    "nombre": "Clínica Central",
    "origen": "REGISTRADA_USUARIO",
    "direccion": "Dirección registrada",
    "latitud": "14.072300",
    "longitud": "-87.192100",
    "verificada": false,
    "estado": "ACTIVO"
  }
}
```

El objeto `ubicacion` también incluye tipo, país, departamento, municipio,
ciudad, colonia, contacto, horario, instrucciones y marcas de tiempo.

### `POST /api/v1/ubicaciones/`

Ejemplo de registro manual:

```json
{
  "empresa_id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96",
  "nombre": "Clínica Central",
  "tipo_ubicacion_id": "14f574d2-2e84-41d2-a02e-5c233f6d7685",
  "origen": "REGISTRADA_USUARIO",
  "pais_id": "551f8cff-af35-480f-a803-25129d6aab03",
  "departamento": "Francisco Morazán",
  "municipio": "Distrito Central",
  "ciudad": "Tegucigalpa",
  "colonia": "Colonia Palmira",
  "direccion": "Avenida República de Panamá, edificio 123",
  "latitud": "14.072300",
  "longitud": "-87.192100",
  "telefono": null,
  "nombre_contacto": null,
  "horario_atencion": null,
  "instrucciones": "Entregar en recepción",
  "permite_origen": true,
  "permite_destino": true
}
```

`departamento`, `municipio`, `ciudad` y `colonia` son opcionales porque no
todas las direcciones manuales o respuestas de Google contienen los cuatro
niveles. `direccion`, `latitud` y `longitud` continúan siendo obligatorios.

La API ya no expone `nivel_administrativo_1`, `nivel_administrativo_2` ni
`localidad`. El frontend debe utilizar los nombres de negocio anteriores.

Para `origen: "GOOGLE"` se exige `identificador_lugar_google`. Para
`REGISTRADA_USUARIO` ese campo no debe enviarse. La ubicación queda aprobada
automáticamente solamente si el creador también posee `ubicacion.aprobar`; de
lo contrario queda `PENDIENTE`.

### `GET /api/v1/ubicaciones/{ubicacion_id}/`

Devuelve el detalle si la ubicación pertenece a una empresa visible. Los
recursos fuera del alcance responden `404`.

### `PATCH /api/v1/ubicaciones/{ubicacion_id}/autorizacion-empresa/{empresa_id}/`

Acepta uno o más campos:

```json
{
  "permite_origen": true,
  "permite_destino": false,
  "estado": "APROBADO"
}
```

Una relación `APROBADO` debe permitir origen, destino o ambos.

### `POST /api/v1/organizaciones/empresas/{empresa_id}/sucursales/`

```json
{
  "nombre": "Principal",
  "codigo": "TGU-01",
  "ubicacion_id": "2de2d88f-65b5-4e3e-951f-0f6faf8002e3",
  "telefono": null,
  "correo": "principal@empresa.com"
}
```

La ubicación debe estar activa y `APROBADO` para la misma empresa. El código
se normaliza a mayúsculas y no puede repetirse dentro de la empresa.

La API ya acepta Google Place ID, pero todavía no realiza búsquedas ni llamadas
a Google Maps. Esa integración se activará cuando exista una clave restringida
por entorno.

## 19. Solicitudes

### Permisos de visibilidad

El perfil puede devolver tres permisos diferentes:

- `solicitud.ver`: consulta todas las solicitudes dentro del alcance permitido;
- `solicitud.ver_propias`: consulta únicamente las solicitudes creadas por el
  usuario dentro de su alcance;
- `solicitud.ver_asignadas`: consulta las solicitudes asignadas al perfil del
  motorista autenticado.

Los solicitantes ya no reciben `solicitud.ver`; reciben
`solicitud.ver_propias`. Los repartidores reciben
`solicitud.ver_asignadas`. El frontend debe construir la navegación usando
estos permisos nuevos.

### `GET /api/v1/solicitudes/tipos-servicio/`

Devuelve nueve tipos activos sin paginación:

```json
{
  "resultados": [
    {
      "id": "8814652b-d743-4385-9cd9-32e66a9c2d5d",
      "codigo": "MUESTRA_BIOLOGICA",
      "nombre": "Muestra biológica",
      "descripcion": "Traslado controlado de muestras biológicas."
    }
  ]
}
```

Códigos iniciales: `MUESTRA_BIOLOGICA`, `MEDICAMENTO`, `REACTIVO`,
`INSUMO_MEDICO`, `DOCUMENTO`, `RESULTADO`, `EQUIPO`, `PAQUETE` y `OTRO`.

### `GET /api/v1/solicitudes/opciones-creacion/`

Devuelve solamente las modalidades, orígenes y destinos que el usuario puede
utilizar al crear una solicitud corporativa. `empresa_id` es obligatorio.
`sucursal_id` es opcional y limita el origen. Al elegir
`ENTRE_SUCURSALES` sin origen, responde `200` con las sucursales de origen y
`destinos: []`; el frontend consulta de nuevo tras elegir el origen.
`origen_id` normalmente debe ser `origenes[].ubicacion.id`. Por compatibilidad
también se acepta `origenes[].sucursal_id` en ese parámetro, o enviar solo
`sucursal_id` para fijar el origen y obtener destinos del mismo país/departamento.

Ejemplo:

```http
GET /api/v1/solicitudes/opciones-creacion/?empresa_id=3b0407a3-bc31-4d31-9619-7a3f01ac0b96&modalidad=ENTRE_SUCURSALES&origen_id=2de2d88f-65b5-4e3e-951f-0f6faf8002e3
```

Respuesta `200`:

```json
{
  "empresa_id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96",
  "sucursal_id": null,
  "modalidad_seleccionada": "ENTRE_SUCURSALES",
  "mensaje_disponibilidad": null,
  "puede_crear_envio_especial": false,
  "modalidades": [
    {
      "codigo": "ENTRE_SUCURSALES",
      "nombre": "Entre sucursales",
      "requiere_destino_registrado": true,
      "presentacion_ruta": "MAPA"
    },
    {
      "codigo": "EMPRESA_TRANSPORTE",
      "nombre": "Empresa de transporte",
      "requiere_destino_registrado": true,
      "presentacion_ruta": "MAPA"
    }
  ],
  "origenes": [
    {
      "sucursal_id": "d2c7775a-8223-4cf7-b23b-e11caf453120",
      "sucursal_nombre": "Sucursal Centro",
      "ubicacion": {
        "id": "2de2d88f-65b5-4e3e-951f-0f6faf8002e3",
        "nombre": "Sucursal Centro",
        "tipo_codigo": "SUCURSAL",
        "departamento": "Francisco Morazán",
        "municipio": "Distrito Central",
        "ciudad": "Tegucigalpa",
        "colonia": "Centro",
        "direccion": "Avenida principal",
        "latitud": "14.101200",
        "longitud": "-87.193100"
      }
    }
  ],
  "destinos": [
    {
      "sucursal_id": "bb54ddfa-a0bc-44d7-8845-6078db1ca201",
      "sucursal_nombre": "Sucursal Norte",
      "ubicacion": {
        "id": "3c18fa32-7bc2-4743-9744-f22453730413",
        "nombre": "Sucursal Norte",
        "tipo_codigo": "SUCURSAL",
        "departamento": "Francisco Morazán",
        "municipio": "Distrito Central",
        "ciudad": "Tegucigalpa",
        "colonia": "El Hato",
        "direccion": "Bulevar del Norte",
        "latitud": "14.120000",
        "longitud": "-87.180000"
      }
    }
  ]
}
```

Reglas para el frontend:

- si no se envía `modalidad`, `destinos` se devuelve como `[]`;
- con `modalidad=ENTRE_SUCURSALES` pero sin origen seleccionado, se devuelven
  los `origenes` autorizados y `destinos: []`, sin error;
- `mensaje_disponibilidad` es `null` cuando hay opciones o aún falta elegir
  un origen. Si `origenes` está vacío en `ENTRE_SUCURSALES`, responde `200`
  con `mensaje_disponibilidad: "No hay sucursales disponibles para crear
  solicitudes."`. Si ya se eligió un origen válido pero `destinos` está vacío,
  responde `200` con `mensaje_disponibilidad: "No hay sucursales de destino
  disponibles en el mismo departamento."`. Si el origen carece de departamento,
  responde200 con mensaje para solicitar su actualización al administrador.
  Mostrar estos mensajes como estado vacío, no como error de conexión;
- `ESPECIAL` solo aparece para `GERENTE_OPERACIONES` y devuelve destinos
  vacíos porque utiliza `destino_especial`;
- para `EMPRESA_TRANSPORTE`, `sucursal_id` y `sucursal_nombre` de cada destino
  son `null`;
- una empresa, sucursal u origen fuera del alcance responde `404`;
- solicitar `ESPECIAL` sin permiso responde `403`;
- Network responde `409` mientras la creación dependa de ruta y cotización.

### `GET /api/v1/solicitudes/resumen-solicitante/`

Acepta opcionalmente `empresa_id`, `sucursal_id` y `fecha_operativa=AAAA-MM-DD`.
Sin fecha, usa hoy según reloj del servidor en **America/Tegucigalpa**, no
el calendario del teléfono. Los conteos se calculan
exclusivamente sobre las solicitudes visibles: un solicitante cuenta solo las
propias, un motorista solo las asignadas y un gerente las de su alcance.
El administrador conserva la visibilidad de sus permisos; no se limita a lo que
él mismo creó. Los filtros de empresa/sucursal nunca amplían visibilidad.

Ejemplo: `/api/v1/solicitudes/resumen-solicitante/?fecha_operativa=2026-10-22`.

Respuesta `200` completa sin actividad:

```json
{
  "total": 0,
  "pendientes": 0,
  "activas": 0,
  "entregadas": 0,
  "fallidas": 0,
  "canceladas": 0,
  "recientes": [],
  "fecha_operativa": "2026-10-22",
  "zona_horaria_operativa": "America/Tegucigalpa",
  "entregadas_del_dia": 0,
  "entregas_recientes_del_dia": []
}
```

Los campos anteriores (`total`, categorías y `recientes`) **siguen siendo
acumulados**, incluso si se envía fecha. Para la tarjeta de entregas de hoy
usar **`entregadas_del_dia`**, no `total` ni `entregadas`.

`entregadas_del_dia` cuenta solo `estado=DELIVERED` y `entregada_en` dentro de
`[medianoche local, medianoche siguiente)`. No usa `creado_en`: una solicitud
creada ayer y entregada hoy cuenta hoy; creada hoy y entregada ayer no cuenta hoy.
Un registro histórico sin `entregada_en` permanece en el acumulado, no en el día.
El 22 de octubre de 2026 corresponde al intervalo UTC
`[2026-10-22T06:00:00Z, 2026-10-23T06:00:00Z)`.

`entregas_recientes_del_dia` contiene máximo cinco objetos con **todos los
campos del resumen de solicitud** y además `entregada_en` (fecha/hora ISO 8601).
Orden: `entregada_en` descendente, después `id` descendente. Fecha sin entregas:
conteo cero y lista vacía. No mezclar esta lista con los recientes acumulados.
Fecha vacía, imposible o fuera del formato devuelve `400` bajo `fecha_operativa`;
`9999-12-31` se rechaza porque no permite calcular el inicio del día siguiente.
La zona se centraliza en `ZONA_HORARIA_RESUMEN_SOLICITANTE`, cuyo valor local
efectivo es `America/Tegucigalpa`.

`recientes` contiene como máximo cinco objetos con el mismo contrato completo
del resumen de `GET /api/v1/solicitudes/`, ordenados del más nuevo al más
antiguo. Las categorías son:

- `pendientes`: `PENDING` y `ASSIGNED`;
- `activas`: desde `GOING_TO_PICKUP` hasta `AT_DESTINATION`;
- `entregadas`: `DELIVERED`;
- `fallidas`: `PICKUP_FAILED` y `DELIVERY_FAILED`;
- `canceladas`: `CANCELLED`.

### `GET /api/v1/solicitudes/`

Lista paginada y limitada por los permisos anteriores. Filtros opcionales:

| Parámetro | Valores |
|---|---|
| `empresa_id` | UUID de empresa. |
| `sucursal_id` | UUID de sucursal. |
| `sin_sucursal` | `true` para solicitudes sin sucursal; no combinar con `sucursal_id`. |
| `solicitada_por_id` | UUID del usuario que creó la solicitud. |
| `prioridad` | `NORMAL` o `PRIORITY`. |
| `estado` | Uno de los estados oficiales de solicitud. |
| `modalidad` | `ENTRE_SUCURSALES`, `EMPRESA_TRANSPORTE` o `ESPECIAL` en Corporate. |

Respuesta `200` completa de ejemplo:

```json
{
  "conteo": 1,
  "pagina_siguiente": null,
  "pagina_anterior": null,
  "resultados": [
    {
      "id": "bf9490a0-aeb4-4df5-8bd1-8c1341ddfeac",
      "numero": "SOL-20260928-BF9490A0",
      "empresa_id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96",
      "sucursal_id": "d2c7775a-8223-4cf7-b23b-e11caf453120",
      "sucursal": {
        "id": "d2c7775a-8223-4cf7-b23b-e11caf453120",
        "nombre": "Sucursal Centro"
      },
      "solicitada_por_id": "8429ba3a-d32f-4696-bb70-d3b48ef47f30",
      "solicitante": {
        "id": "8429ba3a-d32f-4696-bb70-d3b48ef47f30",
        "nombres": "Ana",
        "apellidos": "López"
      },
      "repartidor_asignado_id": "a465f3ae-a12b-4972-ae27-8076480f3773",
      "prioridad": "PRIORITY",
      "modalidad": "ENTRE_SUCURSALES",
      "tipo_servicio": {
        "id": "8814652b-d743-4385-9cd9-32e66a9c2d5d",
        "codigo": "MUESTRA_BIOLOGICA",
        "nombre": "Muestra biológica",
        "descripcion": "Traslado controlado de muestras biológicas."
      },
      "origen": {
        "id": "2de2d88f-65b5-4e3e-951f-0f6faf8002e3",
        "nombre": "Laboratorio Central",
        "direccion": "Colonia Palmira, Tegucigalpa",
        "latitud": "14.101200",
        "longitud": "-87.193100"
      },
      "destino": {
        "id": "3c18fa32-7bc2-4743-9744-f22453730413",
        "nombre": "Hospital Principal",
        "direccion": "Bulevar Suyapa, Tegucigalpa",
        "latitud": "14.085600",
        "longitud": "-87.165400"
      },
      "destino_especial": null,
      "presentacion_ruta": "MAPA",
      "kilometros_envio_especial": null,
      "estado": "AT_PICKUP",
      "creado_en": "2026-09-28T14:00:00Z"
    }
  ]
}
```

El listado no incluye `notas`, `articulos`, `eventos`, `asignaciones` ni las
fechas operativas. Para esos campos debe consultarse el detalle. Cuando la
solicitud aún no posee motorista, `repartidor_asignado_id` es `null`; cuando no
pertenece a una sucursal concreta, `sucursal_id` es `null`.
En ese caso `sucursal` también es `null`. `solicitante` identifica al
usuario creador sin exponer su correo. El filtro por solicitante o sucursal
**nunca** amplía el alcance autorizado; un administrador de empresa solo
recibe solicitudes de su empresa. El listado sin filtros conserva su contrato
paginado anterior para compatibilidad.

### `GET /api/v1/solicitudes/agrupaciones/`

Consulta exclusiva para usuarios con `solicitud.ver` en alcance administrativo.
El parámetro obligatorio `por` admite `sucursal` o `solicitante`; `empresa_id`
es opcional. La respuesta usa la paginación estándar (`pagina`,
`tamano_pagina`, máximo 100). Los grupos se calculan **solo** con solicitudes
visibles para ese administrador. Un solicitante común o un motorista sin
`solicitud.ver` recibe `403`; un valor de `por` inválido devuelve `400`.

```http
GET /api/v1/solicitudes/agrupaciones/?por=sucursal&empresa_id=3b0407a3-bc31-4d31-9619-7a3f01ac0b96
```

```json
{
  "conteo": 2,
  "pagina_siguiente": null,
  "pagina_anterior": null,
  "resultados": [
    {
      "empresa_id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96",
      "sucursal_id": "d2c7775a-8223-4cf7-b23b-e11caf453120",
      "empresa_nombre": "Analiza",
      "sucursal_nombre": "Sucursal Centro",
      "total": 6
    },
    {
      "empresa_id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96",
      "sucursal_id": "af34a836-63dd-4658-bf3d-51af60e8c5a0",
      "empresa_nombre": "Analiza",
      "sucursal_nombre": "Sucursal Norte",
      "total": 1
    }
  ]
}
```

Con `por=solicitante`, la respuesta tiene la misma envoltura paginada:

```json
{
  "conteo": 1,
  "pagina_siguiente": null,
  "pagina_anterior": null,
  "resultados": [
    {
      "empresa_id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96",
      "solicitada_por_id": "8429ba3a-d32f-4696-bb70-d3b48ef47f30",
      "empresa_nombre": "Analiza",
      "solicitante_nombres": "Ana",
      "solicitante_apellidos": "López",
      "total": 2
    }
  ]
}
```

El frontend debe mostrar primero el selector de sucursal o solicitante y,
al elegir un grupo, consultar `GET /api/v1/solicitudes/` con `empresa_id`
junto con `sucursal_id` o `solicitada_por_id`. Para el grupo «Sin sucursal»,
`sucursal_id` y `sucursal_nombre` son `null`; consultar el listado con
`sin_sucursal=true`. Hay que recorrer las páginas de grupos y solicitudes
cuando `pagina_siguiente` no es `null`.

### `POST /api/v1/solicitudes/`

Disponible actualmente en Corporate. Ejemplo:

```json
{
  "empresa_id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96",
  "sucursal_id": null,
  "prioridad": "PRIORITY",
  "modalidad": "ENTRE_SUCURSALES",
  "tipo_servicio_id": "8814652b-d743-4385-9cd9-32e66a9c2d5d",
  "origen_id": "2de2d88f-65b5-4e3e-951f-0f6faf8002e3",
  "destino_id": "3c18fa32-7bc2-4743-9744-f22453730413",
  "notas": "Entregar directamente en recepción.",
  "cantidad_tubos": 2,
  "articulos": [
    {
      "tipo_articulo": "Muestra de laboratorio",
      "descripcion": "Contenedor sellado",
      "cantidad": "2.00",
      "codigo_referencia": "LAB-2026-001",
      "condicion_transporte": "Temperatura controlada",
      "notas": null
    }
  ]
}
```

Modalidades de Corporate/Analiza:

| Código | Origen y destino | Presentación |
|---|---|---|
| `ENTRE_SUCURSALES` | Sucursal activa hacia otra sucursal activa de la misma empresa, país y departamento; ciudades/municipios pueden diferir. | `MAPA` |
| `EMPRESA_TRANSPORTE` | Sucursal activa hacia una ubicación aprobada cuyo tipo sea `EMPRESA_TRANSPORTE`. | `MAPA` |
| `ESPECIAL` | Sucursal activa hacia una descripción libre; no utiliza `destino_id`. | `SOLO_KILOMETROS` |

`ABIERTO` queda reservado para VitaGo Network y Corporate lo rechaza. Estas
reglas no restringen el modelo futuro de Network.

Ejemplo de creación especial:

```json
{
  "empresa_id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96",
  "sucursal_id": "d2c7775a-8223-4cf7-b23b-e11caf453120",
  "prioridad": "NORMAL",
  "modalidad": "ESPECIAL",
  "tipo_servicio_id": "8814652b-d743-4385-9cd9-32e66a9c2d5d",
  "origen_id": "2de2d88f-65b5-4e3e-951f-0f6faf8002e3",
  "destino_id": null,
  "destino_especial": "Entregar documentos en oficinas centrales del proveedor",
  "cantidad_tubos": 1,
  "notas": null,
  "articulos": [
    {
      "tipo_articulo": "Documentos",
      "cantidad": "1.00"
    }
  ]
}
```

Reglas:

- desde0.39.0 requiere cantidad_tubos entera positiva (1 a 2147483647),
  independiente de articulos[].cantidad; no habilita creación pública Network;
- requiere al menos un artículo y cada cantidad debe ser mayor que cero;
- la empresa y sucursal deben estar activas y dentro de
  `solicitud.crear`;
- el origen debe estar activo, aprobado y habilitado como origen para la
  empresa; en Corporate también debe corresponder a una sucursal activa;
- el destino debe estar activo, aprobado y habilitado como destino para la
  misma empresa;
- el tipo de servicio debe estar activo;
- el backend genera el número y crea la solicitud inicialmente `PENDING`;
  si encuentra un motorista elegible, la asigna en la misma operación y la
  respuesta `201` ya trae `estado: "ASSIGNED"` y `repartidor_asignado_id`;
- solicitud, artículos, eventos, asignación y notificación se guardan
  atómicamente;
- `ESPECIAL` exige los permisos `solicitud.crear` y
  `solicitud.crear_envio_especial`; el segundo se entrega al rol
  `GERENTE_OPERACIONES` exclusivamente con alcance `EMPRESA`;
- un supervisor o gerente de sucursal no puede crear un envío especial;
  el superusuario técnico de Django conserva su excepción administrativa.

Prioridades vigentes: `NORMAL` y `PRIORITY`.

Network responde `409 Conflict` mientras no exista cálculo de ruta y tarifa en
el backend. El frontend no debe intentar enviar precios o distancias para
evitar esta protección.

### `GET /api/v1/solicitudes/{solicitud_id}/`

Devuelve el resumen más notas, artículos, eventos y fechas operativas. Una
solicitud inexistente o fuera del alcance responde `404`.

Respuesta `200` completa de ejemplo:

```json
{
  "id": "bf9490a0-aeb4-4df5-8bd1-8c1341ddfeac",
  "numero": "SOL-20260928-BF9490A0",
  "empresa_id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96",
  "sucursal_id": "d2c7775a-8223-4cf7-b23b-e11caf453120",
  "sucursal": {
    "id": "d2c7775a-8223-4cf7-b23b-e11caf453120",
    "nombre": "Sucursal Centro"
  },
  "solicitada_por_id": "8429ba3a-d32f-4696-bb70-d3b48ef47f30",
  "solicitante": {
    "id": "8429ba3a-d32f-4696-bb70-d3b48ef47f30",
    "nombres": "Ana",
    "apellidos": "López"
  },
  "repartidor_asignado_id": "a465f3ae-a12b-4972-ae27-8076480f3773",
  "prioridad": "PRIORITY",
  "modalidad": "ENTRE_SUCURSALES",
  "tipo_servicio": {
    "id": "8814652b-d743-4385-9cd9-32e66a9c2d5d",
    "codigo": "MUESTRA_BIOLOGICA",
    "nombre": "Muestra biológica",
    "descripcion": "Traslado controlado de muestras biológicas."
  },
  "origen": {
    "id": "2de2d88f-65b5-4e3e-951f-0f6faf8002e3",
    "nombre": "Laboratorio Central",
    "direccion": "Colonia Palmira, Tegucigalpa",
    "latitud": "14.101200",
    "longitud": "-87.193100"
  },
  "destino": {
    "id": "3c18fa32-7bc2-4743-9744-f22453730413",
    "nombre": "Hospital Principal",
    "direccion": "Bulevar Suyapa, Tegucigalpa",
    "latitud": "14.085600",
    "longitud": "-87.165400"
  },
  "destino_especial": null,
  "presentacion_ruta": "MAPA",
  "kilometros_envio_especial": null,
  "estado": "AT_PICKUP",
  "creado_en": "2026-09-28T14:00:00Z",
  "notas": "Entregar directamente en recepción.",
  "articulos": [
    {
      "id": "9067300c-8cb8-44e6-9fe5-145fcb5adef1",
      "tipo_articulo": "Muestra de laboratorio",
      "descripcion": "Contenedor sellado",
      "cantidad": "2.00",
      "codigo_referencia": "LAB-2026-001",
      "condicion_transporte": "Temperatura controlada",
      "notas": null
    }
  ],
  "eventos": [
    {
      "id": "e00d0860-fad8-4fc0-aa43-4197cc084bd9",
      "tipo": "CREADA",
      "realizado_por_id": "8429ba3a-d32f-4696-bb70-d3b48ef47f30",
      "repartidor_id": null,
      "latitud": null,
      "longitud": null,
      "metadatos": {
        "estado": "PENDING",
        "prioridad": "PRIORITY"
      },
      "creado_en": "2026-09-28T14:00:00Z"
    },
    {
      "id": "e891e47f-46bd-4560-9e7b-6b888bd147de",
      "tipo": "ASIGNADA",
      "realizado_por_id": "11932565-95fa-424c-a287-f937978c88cb",
      "repartidor_id": "a465f3ae-a12b-4972-ae27-8076480f3773",
      "latitud": null,
      "longitud": null,
      "metadatos": {
        "repartidor_id": "a465f3ae-a12b-4972-ae27-8076480f3773",
        "repartidor_anterior_id": null,
        "tipo_asignacion": "MANUAL"
      },
      "creado_en": "2026-09-28T14:05:00Z"
    },
    {
      "id": "e6318c92-60ec-4a0d-9718-e84795b2b249",
      "tipo": "HACIA_RECOLECCION",
      "realizado_por_id": "ef19583b-459c-491e-becf-8e2f3f407673",
      "repartidor_id": "a465f3ae-a12b-4972-ae27-8076480f3773",
      "latitud": "14.090100",
      "longitud": "-87.181500",
      "metadatos": {
        "estado_anterior": "ASSIGNED",
        "estado_nuevo": "GOING_TO_PICKUP"
      },
      "creado_en": "2026-09-28T14:10:00Z"
    },
    {
      "id": "e2748f86-c313-4101-82bd-77066df85268",
      "tipo": "LLEGADA_RECOLECCION",
      "realizado_por_id": "ef19583b-459c-491e-becf-8e2f3f407673",
      "repartidor_id": "a465f3ae-a12b-4972-ae27-8076480f3773",
      "latitud": "14.101200",
      "longitud": "-87.193100",
      "metadatos": {
        "estado_anterior": "GOING_TO_PICKUP",
        "estado_nuevo": "AT_PICKUP"
      },
      "creado_en": "2026-09-28T14:20:00Z"
    }
  ],
  "asignaciones": [
    {
      "id": "f00e36fb-3ef5-481a-b7e8-73e43579c165",
      "repartidor_id": "a465f3ae-a12b-4972-ae27-8076480f3773",
      "asignada_por_id": "11932565-95fa-424c-a287-f937978c88cb",
      "tipo": "MANUAL",
      "estado": "ACTIVA",
      "asignada_en": "2026-09-28T14:05:00Z",
      "aceptada_en": "2026-09-28T14:10:00Z",
      "finalizada_en": null,
      "motivo": "Asignación del encargado de turno"
    }
  ],
  "movimiento_especial": null,
  "asignada_en": "2026-09-28T14:05:00Z",
  "llegada_recoleccion_en": "2026-09-28T14:20:00Z",
  "recolectada_en": null,
  "llegada_destino_en": null,
  "entregada_en": null,
  "cancelada_en": null,
  "actualizado_en": "2026-09-28T14:20:00Z"
}
```

Los arreglos se devuelven como `[]` cuando no contienen registros. Los campos
opcionales o las fechas que todavía no aplican se devuelven como `null`; no se
deben interpretar como campos omitidos.

En un envío `ESPECIAL`, `destino` es `null`, `destino_especial` contiene el
texto visible y `presentacion_ruta` vale `SOLO_KILOMETROS`. Mientras está en
curso, `kilometros_envio_especial` es `null`. Al cerrarlo contiene el decimal
con tres posiciones y `movimiento_especial` presenta el detalle congelado:

```json
{
  "id": "97c817eb-cb2d-4370-a02a-a0f47b08f2c4",
  "repartidor_id": "a465f3ae-a12b-4972-ae27-8076480f3773",
  "jornada_id": "9f106ce2-050c-4ef7-ab94-446207b8499e",
  "estado": "FINALIZADO",
  "iniciada_en": "2026-09-28T14:30:00Z",
  "finalizada_en": "2026-09-28T15:15:00Z",
  "latitud_inicio": "14.101200",
  "longitud_inicio": "-87.193100",
  "latitud_fin": "14.092100",
  "longitud_fin": "-87.184200",
  "kilometros_recorridos": "8.426",
  "registros_considerados": 84,
  "registros_descartados": 3
}
```

Estados reconocidos por el esquema:

- `PENDING`
- `ASSIGNED`
- `GOING_TO_PICKUP`
- `AT_PICKUP`
- `PICKED_UP`
- `IN_TRANSIT`
- `AT_DESTINATION`
- `DELIVERED`
- `CANCELLED`
- `PICKUP_FAILED`
- `DELIVERY_FAILED`

La creación responde `ASSIGNED` si encontró motorista elegible; si no,
permanece `PENDING` para asignación posterior. La asignación manual también
cambia `PENDING` a `ASSIGNED`; el resto del ciclo se controla mediante el
endpoint de transiciones descrito a continuación.

## 20. Flota, motoristas y asignaciones

Los códigos técnicos de roles permanecen estables:

- `REPARTIDOR_CORPORATIVO`: motorista de Corporate;
- `REPARTIDOR_RED`: motorista de Network;
- `GERENTE_OPERACIONES`: dirección operativa y administración de usuarios
  operativos de Corporate, con alcance exclusivo de empresa;
- `OPERADOR_RED`: encargado operativo de Network.

`SUPERVISOR_CORPORATIVO` fue retirado del catálogo activo. Sus funciones se
integraron en `GERENTE_OPERACIONES` y ya no aparece en roles asignables.

### Vehículos

`GET /api/v1/vehiculos/` acepta los filtros opcionales `empresa_id`, `estado`
y `tipo`. La respuesta usa la paginación estándar.

Respuesta `200` completa del listado:

```json
{
  "conteo": 1,
  "pagina_siguiente": null,
  "pagina_anterior": null,
  "resultados": [
    {
      "id": "9f1c7da2-e2a4-4a86-8bdb-6ddde60a6354",
      "empresa_id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96",
      "placa": "HBA-1234",
      "tipo": "MOTOCICLETA",
      "marca": "Honda",
      "modelo": "XR150",
      "anio": 2026,
      "capacidad_carga_kg": null,
      "estado": "ACTIVO",
      "notas": null,
      "creado_en": "2026-09-28T13:00:00Z",
      "actualizado_en": "2026-09-28T13:00:00Z"
    }
  ]
}
```

`POST /api/v1/vehiculos/` recibe:

```json
{
  "empresa_id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96",
  "placa": "HBA-1234",
  "tipo": "MOTOCICLETA",
  "marca": "Honda",
  "modelo": "XR150",
  "anio": 2026,
  "estado": "ACTIVO",
  "notas": null
}
```

En Corporate, `empresa_id` es obligatorio. En Network debe omitirse porque la
flota operativa tiene alcance global. La placa se normaliza a mayúsculas y es
única dentro de cada despliegue.

En creación, `tipo` solo admite `MOTOCICLETA`. Los tipos anteriores
(`AUTOMOVIL`, `PANEL`, `ESPECIAL`, `OTRO`) permanecen consultables en registros
históricos, pero no se pueden crear ni asignar a un motorista operativo.
`capacidad_carga_kg` no se envía en `POST`: es obsoleto, no editable y no
obligatorio. En respuestas puede seguir como `null` o conservar el valor
histórico de vehículos antiguos.

Estados: `ACTIVO`, `MANTENIMIENTO`, `FUERA_SERVICIO`, `INACTIVO`.

`POST /api/v1/vehiculos/` responde `201` y
`GET /api/v1/vehiculos/{vehiculo_id}/` responde `200` con el mismo objeto
completo:

```json
{
  "id": "9f1c7da2-e2a4-4a86-8bdb-6ddde60a6354",
  "empresa_id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96",
  "placa": "HBA-1234",
  "tipo": "MOTOCICLETA",
  "marca": "Honda",
  "modelo": "XR150",
  "anio": 2026,
  "capacidad_carga_kg": null,
  "estado": "ACTIVO",
  "notas": null,
  "creado_en": "2026-09-28T13:00:00Z",
  "actualizado_en": "2026-09-28T13:00:00Z"
}
```

En Network, `empresa_id` se devuelve como `null`. `marca`, `modelo`, `anio`,
`capacidad_carga_kg` (obsoleto) y `notas` también pueden ser `null`. Los
decimales históricos se representan como texto.

### Motoristas

`POST /api/v1/repartidores/` crea el perfil operativo de un usuario existente:

```json
{
  "usuario_id": "ef19583b-459c-491e-becf-8e2f3f407673",
  "empresa_id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96",
  "vehiculo_id": "9f1c7da2-e2a4-4a86-8bdb-6ddde60a6354"
}
```

El usuario debe estar activo y poseer previamente el rol técnico de motorista.
En Corporate el rol y el vehículo deben pertenecer a la misma empresa. En
Network tanto el rol como el perfil tienen alcance global.

El perfil nace con:

```json
{
  "estado_operativo": "OFFLINE",
  "capacidad": "EMPTY",
  "activo": true
}
```

`GET /api/v1/repartidores/` acepta `empresa_id`, `estado_operativo`,
`capacidad` (calculada) y `activo`. `GET /api/v1/repartidores/disponibles/`
devuelve motoristas activos, con usuario y motocicleta activos, estado
`AVAILABLE` o `ON_ROUTE` con al menos una solicitud activa, menos de cinco
solicitudes activas y sin una solicitud prioritaria activa ni un envío
especial exclusivo en curso.

Ambos listados usan el mismo sobre paginado y el mismo objeto de motorista.
Ejemplo `200`:

```json
{
  "conteo": 1,
  "pagina_siguiente": null,
  "pagina_anterior": null,
  "resultados": [
    {
      "id": "a465f3ae-a12b-4972-ae27-8076480f3773",
      "usuario": {
        "id": "ef19583b-459c-491e-becf-8e2f3f407673",
        "correo": "motorista@analiza.com",
        "nombres": "Carlos",
        "apellidos": "Mendoza",
        "telefono": "+50499990000",
        "estado": "ACTIVO"
      },
      "empresa_id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96",
      "vehiculo": {
        "id": "9f1c7da2-e2a4-4a86-8bdb-6ddde60a6354",
        "empresa_id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96",
        "placa": "HBA-1234",
        "tipo": "MOTOCICLETA",
        "marca": "Honda",
        "modelo": "XR150",
        "anio": 2026,
        "capacidad_carga_kg": null,
        "estado": "ACTIVO",
        "notas": null,
        "creado_en": "2026-09-28T13:00:00Z",
        "actualizado_en": "2026-09-28T13:00:00Z"
      },
      "estado_operativo": "AVAILABLE",
      "capacidad": "EMPTY",
      "solicitudes_activas": 0,
      "limite_solicitudes": 5,
      "puede_recibir_solicitudes": true,
      "activo": true,
      "creado_en": "2026-09-28T13:15:00Z",
      "actualizado_en": "2026-09-28T13:20:00Z"
    }
  ]
}
```

`POST /api/v1/repartidores/` responde `201`, mientras
`GET /api/v1/repartidores/{repartidor_id}/` y el `PATCH` operativo responden
`200`. Los tres devuelven el mismo objeto completo, sin sobre de paginación:

```json
{
  "id": "a465f3ae-a12b-4972-ae27-8076480f3773",
  "usuario": {
    "id": "ef19583b-459c-491e-becf-8e2f3f407673",
    "correo": "motorista@analiza.com",
    "nombres": "Carlos",
    "apellidos": "Mendoza",
    "telefono": "+50499990000",
    "estado": "ACTIVO"
  },
  "empresa_id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96",
  "vehiculo": {
    "id": "9f1c7da2-e2a4-4a86-8bdb-6ddde60a6354",
    "empresa_id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96",
    "placa": "HBA-1234",
    "tipo": "MOTOCICLETA",
    "marca": "Honda",
    "modelo": "XR150",
    "anio": 2026,
    "capacidad_carga_kg": null,
    "estado": "ACTIVO",
    "notas": null,
    "creado_en": "2026-09-28T13:00:00Z",
    "actualizado_en": "2026-09-28T13:00:00Z"
  },
  "estado_operativo": "AVAILABLE",
  "capacidad": "EMPTY",
  "solicitudes_activas": 0,
  "limite_solicitudes": 5,
  "puede_recibir_solicitudes": true,
  "activo": true,
  "creado_en": "2026-09-28T13:15:00Z",
  "actualizado_en": "2026-09-28T13:20:00Z"
}
```

`vehiculo` es `null` si todavía no fue asignado. En Network,
`empresa_id` es `null` tanto en el motorista como en su vehículo. El campo
`telefono` del usuario también puede ser `null` o texto vacío.

El motorista consulta sus propios datos sin conocer previamente su UUID:

```http
GET /api/v1/repartidores/mi-perfil/
Authorization: Bearer <token>
```

Devuelve `200` con el mismo objeto completo de motorista mostrado arriba:
`id`, `usuario`, `empresa_id`, `vehiculo`, `estado_operativo`, `capacidad`,
`solicitudes_activas`, `limite_solicitudes`, `puede_recibir_solicitudes`,
`activo` y marcas de tiempo. Solo busca el perfil asociado al usuario
autenticado; no requiere `repartidor.ver` ni permite consultar otros perfiles.
Si el usuario no tiene un perfil activo de motorista, responde `404`. Esta
ruta no cambia `GET /api/v1/usuarios/mi-perfil/`.

Estados operativos: `OFFLINE`, `AVAILABLE`, `ON_ROUTE`, `PAUSED`,
`OUT_OF_SERVICE`.

Capacidades: `EMPTY`, `AVAILABLE_SPACE`, `FULL`.

Para modificar el estado operativo:

```http
PATCH /api/v1/repartidores/{repartidor_id}/operacion/
```

```json
{
  "estado_operativo": "AVAILABLE",
  "motivo": "Inicio de operación"
}
```

Permisos exactos del `PATCH`:

| Objetivo | Campos enviados | Permiso obligatorio |
|---|---|---|
| Perfil propio | `estado_operativo` | `repartidor.actualizar_estado` |
| Otro motorista | `estado_operativo` | `repartidor.administrar` dentro del alcance del motorista |

Los roles `REPARTIDOR_CORPORATIVO` y `REPARTIDOR_RED` reciben el permiso de
actualización del estado propio. `SUPERADMINISTRADOR`,
`ADMINISTRADOR_CORPORATIVO`, `GERENTE_OPERACIONES` y `OPERADOR_RED` incluyen
`repartidor.administrar`, sujeto al alcance de su asignación de rol.

Si un usuario modifica su propio perfil, el backend exige el permiso específico
de estado aunque también tenga un rol administrativo. Debe enviar
`estado_operativo`; `motivo` es opcional. Enviar `capacidad` produce `400`:
la capacidad manual y el permiso `repartidor.actualizar_capacidad` son
obsoletos. `EMPTY` significa cero solicitudes activas,
`AVAILABLE_SPACE` entre una y cuatro, y `FULL` cinco. El backend recalcula
estos valores al asignar, reasignar, cancelar, fallar o finalizar una solicitud.
Los estados activos son `ASSIGNED`, `GOING_TO_PICKUP`, `AT_PICKUP`,
`PICKED_UP`, `IN_TRANSIT` y `AT_DESTINATION`; `PENDING` y los terminales no
cuentan. No se acepta un cambio operativo sin efecto. Para quedar `AVAILABLE`
se requiere motocicleta activa. Todo cambio efectivo queda en historial.

### Asignación automática en Corporate

`POST /api/v1/solicitudes/` intenta asignar inmediatamente la solicitud al
motorista elegible más cercano al origen. Usa la distancia GPS en línea recta
entre el último punto registrado del motorista y el origen; **no** es
distancia vial, ETA ni una llamada a Google Maps. Solo considera perfiles
activos de la misma empresa, con usuario y motocicleta activos, estado
`AVAILABLE` o `ON_ROUTE` con carga activa, menos de cinco solicitudes, sin
prioritario activo ni envío especial exclusivo. Las cuentas de prueba siguen
las mismas reglas.

Los motoristas sin GPS registrado quedan después de quienes sí tienen punto;
entre empates se usa un orden estable. Antes de asignar, el backend bloquea
la fila del motorista y vuelve a validar todas las restricciones. Si un
candidato dejó de estar disponible, continúa con el siguiente. La asignación
se registra como `AUTOMATICA`, actualiza el cupo y genera una notificación
persistente **solo para el motorista finalmente asignado**. No existe
aceptación, rechazo ni temporizador del motorista.
En una asignación automática, `asignada_por_id` conserva al usuario que creó
la solicitud y `tipo: "AUTOMATICA"` deja claro que la elección del motorista
la hizo el backend.

Si nadie es elegible, la creación sigue respondiendo `201` con
`estado: "PENDING"` y `repartidor_asignado_id: null`; no se crea una
notificación. Las solicitudes pendientes anteriores a este cambio no se
reasignan retroactivamente. Para que el aviso aparezca en el teléfono, el
frontend debe consultar `/api/v1/notificaciones/` o integrar push en una fase
posterior.

### Asignación manual

```http
POST /api/v1/solicitudes/{solicitud_id}/asignaciones/
```

```json
{
  "repartidor_id": "a465f3ae-a12b-4972-ae27-8076480f3773",
  "motivo": "Asignación del encargado de turno"
}
```

`repartidor_id` es el `id` del perfil devuelto por
`GET /api/v1/repartidores/disponibles/`, **no** `usuario.id`. El listado ya no
interpreta la ausencia del filtro opcional `activo` como `false`.

Reglas:

- la primera asignación requiere `solicitud.asignar`;
- cambiar de motorista requiere `solicitud.reasignar`;
- la solicitud debe estar `PENDING` o `ASSIGNED`;
- el motorista debe estar activo, con motocicleta activa y estado `AVAILABLE`,
  o `ON_ROUTE` si ya atiende solicitudes y aún puede recibir otra;
- el máximo es cinco solicitudes activas, controlado exclusivamente en el
  backend; al intentar una sexta se responde `409` con
  `{"repartidor_id":["El motorista ya tiene cinco solicitudes activas."]}`;
- Corporate exige la misma empresa; Network exige un motorista global;
- un motorista con una solicitud `PRIORITY` activa no recibe otra;
- la operación bloquea las filas involucradas y se ejecuta atómicamente;
- una reasignación cierra la asignación anterior y conserva todo el historial;
- se crea el evento `ASIGNADA` o `REASIGNADA`;
- la respuesta `201` contiene el detalle actualizado de la solicitud.

Los resúmenes de solicitud incluyen `repartidor_asignado_id`. El detalle
incluye además `asignaciones`, con su estado, responsable, fechas y motivo. Un
motorista con `solicitud.ver_asignadas` solo obtiene solicitudes cuyo
`repartidor_asignado_id` sigue apuntando a su perfil, incluidas las terminadas
sin reasignación. Si se reasigna una solicitud, el motorista anterior deja de
verla aunque figure en el historial de asignaciones.

Respuesta `201` completa de una primera asignación:

```json
{
  "id": "bf9490a0-aeb4-4df5-8bd1-8c1341ddfeac",
  "numero": "SOL-20260928-BF9490A0",
  "empresa_id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96",
  "sucursal_id": "d2c7775a-8223-4cf7-b23b-e11caf453120",
  "sucursal": {
    "id": "d2c7775a-8223-4cf7-b23b-e11caf453120",
    "nombre": "Sucursal Centro"
  },
  "solicitada_por_id": "8429ba3a-d32f-4696-bb70-d3b48ef47f30",
  "solicitante": {
    "id": "8429ba3a-d32f-4696-bb70-d3b48ef47f30",
    "nombres": "Ana",
    "apellidos": "López"
  },
  "repartidor_asignado_id": "a465f3ae-a12b-4972-ae27-8076480f3773",
  "prioridad": "PRIORITY",
  "tipo_servicio": {
    "id": "8814652b-d743-4385-9cd9-32e66a9c2d5d",
    "codigo": "MUESTRA_BIOLOGICA",
    "nombre": "Muestra biológica",
    "descripcion": "Traslado controlado de muestras biológicas."
  },
  "origen": {
    "id": "2de2d88f-65b5-4e3e-951f-0f6faf8002e3",
    "nombre": "Laboratorio Central",
    "direccion": "Colonia Palmira, Tegucigalpa",
    "latitud": "14.101200",
    "longitud": "-87.193100"
  },
  "destino": {
    "id": "3c18fa32-7bc2-4743-9744-f22453730413",
    "nombre": "Hospital Principal",
    "direccion": "Bulevar Suyapa, Tegucigalpa",
    "latitud": "14.085600",
    "longitud": "-87.165400"
  },
  "estado": "ASSIGNED",
  "creado_en": "2026-09-28T14:00:00Z",
  "notas": "Entregar directamente en recepción.",
  "articulos": [
    {
      "id": "9067300c-8cb8-44e6-9fe5-145fcb5adef1",
      "tipo_articulo": "Muestra de laboratorio",
      "descripcion": "Contenedor sellado",
      "cantidad": "2.00",
      "codigo_referencia": "LAB-2026-001",
      "condicion_transporte": "Temperatura controlada",
      "notas": null
    }
  ],
  "eventos": [
    {
      "id": "e00d0860-fad8-4fc0-aa43-4197cc084bd9",
      "tipo": "CREADA",
      "realizado_por_id": "8429ba3a-d32f-4696-bb70-d3b48ef47f30",
      "repartidor_id": null,
      "latitud": null,
      "longitud": null,
      "metadatos": {
        "estado": "PENDING",
        "prioridad": "PRIORITY"
      },
      "creado_en": "2026-09-28T14:00:00Z"
    },
    {
      "id": "e891e47f-46bd-4560-9e7b-6b888bd147de",
      "tipo": "ASIGNADA",
      "realizado_por_id": "11932565-95fa-424c-a287-f937978c88cb",
      "repartidor_id": "a465f3ae-a12b-4972-ae27-8076480f3773",
      "latitud": null,
      "longitud": null,
      "metadatos": {
        "repartidor_id": "a465f3ae-a12b-4972-ae27-8076480f3773",
        "repartidor_anterior_id": null,
        "tipo_asignacion": "MANUAL"
      },
      "creado_en": "2026-09-28T14:05:00Z"
    }
  ],
  "asignaciones": [
    {
      "id": "f00e36fb-3ef5-481a-b7e8-73e43579c165",
      "repartidor_id": "a465f3ae-a12b-4972-ae27-8076480f3773",
      "asignada_por_id": "11932565-95fa-424c-a287-f937978c88cb",
      "tipo": "MANUAL",
      "estado": "ACTIVA",
      "asignada_en": "2026-09-28T14:05:00Z",
      "aceptada_en": null,
      "finalizada_en": null,
      "motivo": "Asignación del encargado de turno"
    }
  ],
  "asignada_en": "2026-09-28T14:05:00Z",
  "llegada_recoleccion_en": null,
  "recolectada_en": null,
  "llegada_destino_en": null,
  "entregada_en": null,
  "cancelada_en": null,
  "actualizado_en": "2026-09-28T14:05:00Z"
}
```

Estados de una asignación:

| Estado | Cuándo se utiliza |
|---|---|
| `ACTIVA` | Es la asignación vigente de la solicitud. |
| `REASIGNADA` | Fue reemplazada por otra asignación; conserva `finalizada_en`. |
| `FINALIZADA` | La solicitud terminó como `DELIVERED`. |
| `CANCELADA` | La solicitud terminó como `CANCELLED`, `PICKUP_FAILED` o `DELIVERY_FAILED`. |

El tipo devuelto actualmente por el endpoint manual es `MANUAL`.
`AUTOMATICA` está reservado en el esquema para un asignador futuro. La
primera transición a `GOING_TO_PICKUP` establece `aceptada_en`; cerrar,
fallar, cancelar o reasignar establece `finalizada_en`.

## 21. Operación y evidencias

### Transiciones de solicitud

```http
POST /api/v1/solicitudes/{solicitud_id}/transiciones/
Content-Type: application/json
```

Ejemplo:

```json
{
  "estado_destino": "GOING_TO_PICKUP",
  "latitud": "14.072300",
  "longitud": "-87.192100",
  "motivo": null
}
```

`latitud` y `longitud` son opcionales, pero deben enviarse juntas. `motivo` es
obligatorio para `CANCELLED`, `PICKUP_FAILED` y `DELIVERY_FAILED`.

Secuencia normal permitida:

```text
ASSIGNED -> GOING_TO_PICKUP -> AT_PICKUP -> PICKED_UP
         -> IN_TRANSIT -> AT_DESTINATION -> DELIVERED
```

Matriz exacta aceptada por el backend:

Desde **0.36.0** esta matriz describe también las transiciones **internas** del
flujo automático. Flutter ya no debe enviar `GOING_TO_PICKUP`, `PICKED_UP`,
`IN_TRANSIT` ni `DELIVERED` para confirmar un servicio normal. La foto válida
realiza el avance correspondiente; enviar otra transición puede responder400
porque ya avanzó. Cancelación/fallo autorizados y finalización especial conservan
este endpoint. Los inicios compatibles tampoco permiten saltarse el vigente.

Desde 0.32.0, las flechas hacia `AT_PICKUP` y `AT_DESTINATION` son transiciones
del detector GPS interno, no acciones manuales del frontend. Única excepción:
`AT_DESTINATION` de un envío `ESPECIAL` sin coordenadas de destino.

| Estado actual | Estados destino permitidos |
|---|---|
| `PENDING` | `CANCELLED` |
| `ASSIGNED` | `GOING_TO_PICKUP`, `CANCELLED` |
| `GOING_TO_PICKUP` | `AT_PICKUP`, `CANCELLED`, `PICKUP_FAILED` |
| `AT_PICKUP` | `PICKED_UP`, `CANCELLED`, `PICKUP_FAILED` |
| `PICKED_UP` | `IN_TRANSIT`, `DELIVERY_FAILED` |
| `IN_TRANSIT` | `AT_DESTINATION`, `DELIVERY_FAILED` |
| `AT_DESTINATION` | `DELIVERED`, `DELIVERY_FAILED` |
| `DELIVERED` | Ninguno; estado terminal. |
| `CANCELLED` | Ninguno; estado terminal. |
| `PICKUP_FAILED` | Ninguno; estado terminal. |
| `DELIVERY_FAILED` | Ninguno; estado terminal. |

Reglas adicionales:

- solo el motorista actualmente asignado puede realizar transiciones
  operativas;
- `PICKED_UP` requiere una evidencia `FOTO_RECOLECCION` de ese motorista;
- `DELIVERED` requiere una evidencia `FOTO_ENTREGA` de ese motorista;
- `PICKUP_FAILED` se admite desde `GOING_TO_PICKUP` o `AT_PICKUP`;
- `DELIVERY_FAILED` se admite desde `PICKED_UP`, `IN_TRANSIT` o
  `AT_DESTINATION`;
- `CANCELLED` requiere `solicitud.cancelar` y solo se admite antes de que el
  contenido haya sido recolectado;
- las transiciones inválidas responden `400`;
- iniciar el desplazamiento cambia al motorista a `ON_ROUTE`;
- un estado terminal cierra la asignación. Si no quedan otras asignaciones
  activas, el motorista vuelve a `AVAILABLE` con capacidad `EMPTY`, excepto si
  ya estaba en pausa, desconectado o fuera de servicio;
- cada cambio genera un evento auditable con estado anterior, estado nuevo,
  responsable y GPS cuando fue enviado.
- para `ESPECIAL`, la transición a `PICKED_UP` exige `latitud` y `longitud`,
  una jornada activa y ausencia de otras asignaciones activas; en ese momento
  abre el movimiento y deja al motorista `ON_ROUTE`. `FULL` solo significa
  cinco solicitudes activas, incluso para un envío especial;
- mientras ese movimiento está activo no se pueden asignar otras solicitudes
  al motorista;
- para `ESPECIAL`, `DELIVERED` y `DELIVERY_FAILED` también exigen coordenadas;
  cierran el movimiento y congelan el kilometraje calculado con los puntos GPS;
- antes de cerrar, el dispositivo debe enviar su lote GPS pendiente. Los
  puntos retrasados se conservan, pero no alteran un kilometraje ya congelado.

Permisos exactos:

- toda transición distinta de `CANCELLED` exige que el usuario sea el
  motorista actualmente asignado y tenga `solicitud.actualizar_estado` dentro
  del alcance de la solicitud;
- `CANCELLED` no exige ser el motorista, pero sí requiere
  `solicitud.cancelar` dentro del alcance de la solicitud;
- poseer `solicitud.actualizar_estado` no permite operar una solicitud
  asignada a otro motorista;
- poseer `solicitud.cancelar` no permite saltarse la matriz de estados.

La respuesta `200` contiene el detalle actualizado completo de la solicitud.
Todos los endpoints que devuelven detalle incluyen también `modalidad`,
`destino_especial`, `presentacion_ruta`, `kilometros_envio_especial` y
`movimiento_especial`, aunque los ejemplos operativos generales muestren una
solicitud no especial.
Ejemplo después de avanzar a `AT_PICKUP`:

```json
{
  "id": "bf9490a0-aeb4-4df5-8bd1-8c1341ddfeac",
  "numero": "SOL-20260928-BF9490A0",
  "empresa_id": "3b0407a3-bc31-4d31-9619-7a3f01ac0b96",
  "sucursal_id": "d2c7775a-8223-4cf7-b23b-e11caf453120",
  "sucursal": {
    "id": "d2c7775a-8223-4cf7-b23b-e11caf453120",
    "nombre": "Sucursal Centro"
  },
  "solicitada_por_id": "8429ba3a-d32f-4696-bb70-d3b48ef47f30",
  "solicitante": {
    "id": "8429ba3a-d32f-4696-bb70-d3b48ef47f30",
    "nombres": "Ana",
    "apellidos": "López"
  },
  "repartidor_asignado_id": "a465f3ae-a12b-4972-ae27-8076480f3773",
  "prioridad": "PRIORITY",
  "tipo_servicio": {
    "id": "8814652b-d743-4385-9cd9-32e66a9c2d5d",
    "codigo": "MUESTRA_BIOLOGICA",
    "nombre": "Muestra biológica",
    "descripcion": "Traslado controlado de muestras biológicas."
  },
  "origen": {
    "id": "2de2d88f-65b5-4e3e-951f-0f6faf8002e3",
    "nombre": "Laboratorio Central",
    "direccion": "Colonia Palmira, Tegucigalpa",
    "latitud": "14.101200",
    "longitud": "-87.193100"
  },
  "destino": {
    "id": "3c18fa32-7bc2-4743-9744-f22453730413",
    "nombre": "Hospital Principal",
    "direccion": "Bulevar Suyapa, Tegucigalpa",
    "latitud": "14.085600",
    "longitud": "-87.165400"
  },
  "estado": "AT_PICKUP",
  "creado_en": "2026-09-28T14:00:00Z",
  "notas": "Entregar directamente en recepción.",
  "articulos": [
    {
      "id": "9067300c-8cb8-44e6-9fe5-145fcb5adef1",
      "tipo_articulo": "Muestra de laboratorio",
      "descripcion": "Contenedor sellado",
      "cantidad": "2.00",
      "codigo_referencia": "LAB-2026-001",
      "condicion_transporte": "Temperatura controlada",
      "notas": null
    }
  ],
  "eventos": [
    {
      "id": "e00d0860-fad8-4fc0-aa43-4197cc084bd9",
      "tipo": "CREADA",
      "realizado_por_id": "8429ba3a-d32f-4696-bb70-d3b48ef47f30",
      "repartidor_id": null,
      "latitud": null,
      "longitud": null,
      "metadatos": {
        "estado": "PENDING",
        "prioridad": "PRIORITY"
      },
      "creado_en": "2026-09-28T14:00:00Z"
    },
    {
      "id": "e891e47f-46bd-4560-9e7b-6b888bd147de",
      "tipo": "ASIGNADA",
      "realizado_por_id": "11932565-95fa-424c-a287-f937978c88cb",
      "repartidor_id": "a465f3ae-a12b-4972-ae27-8076480f3773",
      "latitud": null,
      "longitud": null,
      "metadatos": {
        "repartidor_id": "a465f3ae-a12b-4972-ae27-8076480f3773",
        "repartidor_anterior_id": null,
        "tipo_asignacion": "MANUAL"
      },
      "creado_en": "2026-09-28T14:05:00Z"
    },
    {
      "id": "e6318c92-60ec-4a0d-9718-e84795b2b249",
      "tipo": "HACIA_RECOLECCION",
      "realizado_por_id": "ef19583b-459c-491e-becf-8e2f3f407673",
      "repartidor_id": "a465f3ae-a12b-4972-ae27-8076480f3773",
      "latitud": "14.090100",
      "longitud": "-87.181500",
      "metadatos": {
        "estado_anterior": "ASSIGNED",
        "estado_nuevo": "GOING_TO_PICKUP"
      },
      "creado_en": "2026-09-28T14:10:00Z"
    },
    {
      "id": "e2748f86-c313-4101-82bd-77066df85268",
      "tipo": "LLEGADA_RECOLECCION",
      "realizado_por_id": "ef19583b-459c-491e-becf-8e2f3f407673",
      "repartidor_id": "a465f3ae-a12b-4972-ae27-8076480f3773",
      "latitud": "14.101200",
      "longitud": "-87.193100",
      "metadatos": {
        "estado_anterior": "GOING_TO_PICKUP",
        "estado_nuevo": "AT_PICKUP"
      },
      "creado_en": "2026-09-28T14:20:00Z"
    }
  ],
  "asignaciones": [
    {
      "id": "f00e36fb-3ef5-481a-b7e8-73e43579c165",
      "repartidor_id": "a465f3ae-a12b-4972-ae27-8076480f3773",
      "asignada_por_id": "11932565-95fa-424c-a287-f937978c88cb",
      "tipo": "MANUAL",
      "estado": "ACTIVA",
      "asignada_en": "2026-09-28T14:05:00Z",
      "aceptada_en": "2026-09-28T14:10:00Z",
      "finalizada_en": null,
      "motivo": "Asignación del encargado de turno"
    }
  ],
  "asignada_en": "2026-09-28T14:05:00Z",
  "llegada_recoleccion_en": "2026-09-28T14:20:00Z",
  "recolectada_en": null,
  "llegada_destino_en": null,
  "entregada_en": null,
  "cancelada_en": null,
  "actualizado_en": "2026-09-28T14:20:00Z"
}
```

### Registrar evidencia

```http
POST /api/v1/solicitudes/{solicitud_id}/evidencias/
Content-Type: multipart/form-data
```

Campos:

| Campo | Tipo | Obligatorio | Descripción |
|---|---|---|---|
| `tipo` | texto | Sí | `FOTO_RECOLECCION`, `FOTO_ENTREGA` o `FOTO_INCIDENCIA`. |
| `temperatura_contenedor_c` | decimal en °C | Solo FOTO_RECOLECCION desde0.39.0 | Máximo dos decimales, formato ±9999.99; no se admite en entrega/incidencia. |
| `fuente_temperatura` | texto | Solo lectura | La determina el servidor; Flutter nunca la envía. Históricos pueden devolver null. |
| `archivo` | archivo | Sí | Imagen JPEG, PNG o WebP, máximo 10 MB por configuración local. |
| `latitud` | decimal | Sí | Coordenada de captura entre -90 y 90. |
| `longitud` | decimal | Sí | Coordenada de captura entre -180 y 180. |
| `capturada_en` | fecha ISO 8601 | No; solo lectura | Hora oficial de registro asignada por el servidor. Cualquier valor enviado se ignora. |
| `notas` | texto | No | Observaciones operativas. |

La foto de recolección solo se acepta en `AT_PICKUP`; la foto de entrega solo
se acepta en `AT_DESTINATION`. Una foto de incidencia se acepta mientras exista
una operación asignada y no terminal. El backend comprueba que el tipo declarado
coincida con la firma básica del archivo.

Desde0.36.0 las dos fotos operativas solo corresponden al **servicio vigente**:
guardar `FOTO_RECOLECCION` confirma la recolección; desde0.38.0 puede quedar en
`PICKED_UP` si corresponde otra parada o avanzar automáticamente a `IN_TRANSIT`;
`FOTO_ENTREGA` completa `DELIVERED`. La foto y sus cambios de estado se confirman
juntos o se revierten juntos. La respuesta conserva201 y campos anteriores,
añadiendo `estado_solicitud`. NO enviar después otro POST de confirmación.
`FOTO_INCIDENCIA` no hace avanzar el servicio.

Respuesta `201`:

```json
{
  "id": "6c85b340-0e6f-4c0e-9708-f83ffdf2f35a",
  "solicitud_id": "bf9490a0-aeb4-4df5-8bd1-8c1341ddfeac",
  "repartidor_id": "a465f3ae-a12b-4972-ae27-8076480f3773",
  "tipo": "FOTO_RECOLECCION",
  "tipo_contenido": "image/jpeg",
  "tamano_bytes": 248731,
  "latitud": "14.072300",
  "longitud": "-87.192100",
  "capturada_en": "2026-09-26T14:15:00Z",
  "notas": null,
  "archivo_disponible": true,
  "creado_en": "2026-09-26T14:15:03Z"
}
```

La respuesta no expone la clave interna ni una URL pública.

### Consultar evidencias

```http
GET /api/v1/solicitudes/{solicitud_id}/evidencias/
```

Devuelve el sobre paginado estándar con objetos del formato anterior. Requiere
visibilidad de la solicitud y `evidencia.ver` en su alcance.

Para mostrar una imagen:

```http
GET /api/v1/solicitudes/{solicitud_id}/evidencias/{evidencia_id}/archivo/
```

El frontend debe enviar el Bearer token y consumir el cuerpo binario usando el
`Content-Type` de la respuesta. El archivo usa caché privada deshabilitada y no
debe tratarse como una URL pública permanente.

## 22. Jornadas de motoristas

### Iniciar jornada

```http
POST /api/v1/jornadas/iniciar/
```

Las coordenadas son opcionales. Si están disponibles deben enviarse juntas:

```json
{
  "latitud": "14.072300",
  "longitud": "-87.192100"
}
```

También se permite un objeto vacío. El motorista necesita perfil, usuario y
vehículo activos, además de `jornada.iniciar`. Su estado debe ser `OFFLINE` o
`AVAILABLE`. Solo puede existir una jornada activa por motorista.

La respuesta `201` contiene:

```json
{
  "id": "9f106ce2-050c-4ef7-ab94-446207b8499e",
  "repartidor_id": "a465f3ae-a12b-4972-ae27-8076480f3773",
  "estado": "ACTIVA",
  "iniciada_en": "2026-09-26T14:30:00Z",
  "finalizada_en": null,
  "latitud_inicio": "14.072300",
  "longitud_inicio": "-87.192100",
  "latitud_fin": null,
  "longitud_fin": null,
  "kilometros_operativos": "0.000",
  "kilometraje_disponible": false,
  "servicios_completados": 0,
  "recolecciones_completadas": 0,
  "entregas_completadas": 0,
  "servicios_normales": 0,
  "servicios_prioritarios": 0,
  "minutos_activos": 0,
  "incidencias_reportadas": 0,
  "incidencias_disponibles": true,
  "creado_en": "2026-09-26T14:30:00Z",
  "actualizado_en": "2026-09-26T14:30:00Z"
}
```

El inicio cambia al motorista a `AVAILABLE` y registra el cambio en su
historial operativo.

### Consultar jornada activa

```http
GET /api/v1/jornadas/activa/
```

Para un motorista autenticado con perfil activo y `jornada.ver` responde
`200`. Sin ese permiso responde `403`; sin perfil activo, `404`. Cuando existe
una jornada devuelve:

```json
{
  "jornada": {
    "id": "9f106ce2-050c-4ef7-ab94-446207b8499e",
    "estado": "ACTIVA"
  }
}
```

El objeto real contiene todos los campos del ejemplo anterior. Si no existe:

```json
{
  "jornada": null
}
```

### Historial y detalle

```http
GET /api/v1/jornadas/
GET /api/v1/jornadas/{jornada_id}/
```

El listado utiliza la paginación estándar y acepta:

| Parámetro | Descripción |
|---|---|
| `repartidor_id` | UUID del motorista. |
| `estado` | `ACTIVA` o `FINALIZADA`. |
| `desde` | Fecha y hora ISO 8601 mínima de inicio. |
| `hasta` | Fecha y hora ISO 8601 máxima de inicio. |

Un motorista solo recibe sus jornadas. Encargados y administradores con
`repartidor.administrar` y `jornada.ver` pueden consultar las jornadas dentro
de su alcance.

### Finalizar jornada

```http
POST /api/v1/jornadas/{jornada_id}/finalizar/
```

Acepta las coordenadas finales opcionales con el mismo formato del inicio.
Solo el motorista propietario puede finalizarla y no debe conservar ninguna
asignación `ACTIVA`.

Al finalizar, el backend:

- cambia la jornada a `FINALIZADA`;
- calcula y congela servicios, recolecciones, entregas, normales,
  prioritarios, minutos activos y kilómetros operativos;
- cambia al motorista a `OFFLINE` con capacidad `EMPTY`;
- conserva el historial y no permite eliminar la jornada.

`kilometros_operativos` es una cadena decimal con tres decimales. El backend
la calcula a partir de puntos GPS operativos válidos entre aceptación y fin de
asignaciones, sin unir intervalos separados. Descarta puntos de baja precisión,
velocidades anómalas y saltos imposibles. El recorrido de cada envío
`ESPECIAL` terminado se agrega una sola vez desde su kilometraje congelado.
Es una estimación entre coordenadas GPS, **no** distancia vial de Google Maps.
No incluye desplazamientos personales ni posteriores al último servicio.

`kilometraje_disponible=true` significa que hubo al menos un par de puntos
normales válidos o un envío especial finalizado. Si no hay datos suficientes,
vale `false` y `kilometros_operativos="0.000"`; el frontend debe mostrar
«Kilometraje no disponible», no interpretar el cero como distancia recorrida.
Durante una jornada activa el resumen aún no se ha calculado y el indicador
permanece en `false`. En cierres nuevos consultar `calidad_kilometraje`: un
cierre con manifiesto GPS incompleto queda pendiente y se consolida al recibir
sus puntos. Sin manifiesto el resultado es `SIN_VERIFICAR`; puede confirmarse
mediante `sincronizacion-gps/`. Los cierres históricos no se recalculan.
Las jornadas históricas conservan `kilometraje_disponible=false` sin recálculo.
Las incidencias se calculan desde su módulo y
`incidencias_disponibles=true`.

### Mi ruta operativa del motorista

```http
GET /api/v1/rutas/mi-ruta/
```

Requiere Bearer token, perfil activo de motorista propio y
`solicitud.ver_asignadas`. Devuelve `401` sin sesión, `404` sin perfil activo y
`403` sin el permiso. No acepta un `repartidor_id` ajeno.

Respuesta `200` de ejemplo con una solicitud ya recogida:

```json
{
  "repartidor_id": "a465f3ae-a12b-4972-ae27-8076480f3773",
  "jornada_id": "9f106ce2-050c-4ef7-ab94-446207b8499e",
  "ruta_id": "e08d2320-7645-448e-b247-b999fba999dd",
  "version_actual": 2,
  "orden_tipo": "CERCANIA_GPS",
  "ruta_calculada": false,
  "llegada_actual": null,
  "proxima_parada": {
    "orden": 1,
    "solicitud_id": "bf9490a0-aeb4-4df5-8bd1-8c1341ddfeac",
    "numero_solicitud": "SOL-20260928-BF9490A0",
    "prioridad": "NORMAL",
    "modalidad": "ENTRE_SUCURSALES",
    "estado_solicitud": "PICKED_UP",
    "tipo": "ENTREGA",
    "ubicacion": {
      "id": "3c18fa32-7bc2-4743-9744-f22453730413",
      "nombre": "Sucursal Norte",
      "direccion": "Bulevar Suyapa, Tegucigalpa",
      "latitud": "14.085600",
      "longitud": "-87.165400"
    },
    "destino_especial": null,
    "presentacion_ruta": "MAPA"
  },
  "paradas": [
    {
      "orden": 1,
      "solicitud_id": "bf9490a0-aeb4-4df5-8bd1-8c1341ddfeac",
      "numero_solicitud": "SOL-20260928-BF9490A0",
      "prioridad": "NORMAL",
      "modalidad": "ENTRE_SUCURSALES",
      "estado_solicitud": "PICKED_UP",
      "tipo": "ENTREGA",
      "ubicacion": {
        "id": "3c18fa32-7bc2-4743-9744-f22453730413",
        "nombre": "Sucursal Norte",
        "direccion": "Bulevar Suyapa, Tegucigalpa",
        "latitud": "14.085600",
        "longitud": "-87.165400"
      },
      "destino_especial": null,
      "presentacion_ruta": "MAPA"
    }
  ]
}
```

`proxima_parada` es el primer elemento de `paradas`. Sin servicios activos,
`paradas=[]` y `proxima_parada=null`. `jornada_id` puede ser `null` si el
motorista aún no inició jornada. `ruta_id` y `version_actual` pueden ser
`null` si todavía no se ha creado una ruta persistida, incluso para
asignaciones anteriores a esta actualización. El frontend puede ignorar estos
dos campos sin alterar su flujo. La vista incluye solamente solicitudes
actualmente asignadas y activas; una cancelación, reasignación, entrega o
recolección se refleja en la siguiente consulta, sin esperar sincronización
de una ruta persistida. El historial se guarda cuando una operación cambia la
secuencia de paradas; consultar este `GET` no crea versiones. Antes de recoger
una solicitud aparecen
`RECOLECCION` y `ENTREGA`; después, solo la entrega.

Desde 0.35.0 el criterio es `CERCANIA_GPS`: ordena servicios completos por
cercanía geográfica aproximada, conserva el servicio iniciado y guarda el orden.
Sin GPS válido mantiene lo guardado y añade nuevos por antigüedad. No optimiza
calles ni tráfico; ver contrato detallado al final. Un prioritario ya recogido aparece primero para
ir directamente a su destino. Un envío `ESPECIAL` ya recogido también toma
precedencia y usa `tipo=ENVIO_ESPECIAL`, `ubicacion=null`, la descripción en
`destino_especial` y `presentacion_ruta=SOLO_KILOMETROS`. Para su recolección
sí se informa la ubicación de origen, pero no se dibuja ruta seleccionada.
`ruta_calculada=false` significa que no hay un trazado vigente compatible.
La integración disponible desde 0.30 y el desglose por tramos de 0.34 están
documentados más adelante; el orden geográfico no equivale a una ruta vial.

### Historial de rutas y versiones

```http
GET /api/v1/rutas/?repartidor_id={uuid}&estado=FINALIZADA&pagina=1&tamano_pagina=20
GET /api/v1/rutas/{ruta_id}/versiones/?pagina=1&tamano_pagina=20
GET /api/v1/rutas/{ruta_id}/versiones/{numero}/
```

Todos requieren Bearer token. El motorista con `ruta.ver` consulta solo sus
rutas. Para consultar rutas de otros motoristas se requieren `ruta.ver` y
`repartidor.ver_ubicacion` con alcance compatible. Un historial que contenga
paradas de otra empresa no se expone a administradores de alcance empresarial.
El superadministrador global puede consultarlo. No se publican rutas a
solicitantes ni se aceptan operaciones de escritura en estos endpoints.

El listado de rutas acepta `repartidor_id` UUID y `estado` (`ACTIVA` o
`FINALIZADA`) como filtros opcionales. Responde con el sobre paginado estándar
(`conteo`, `pagina_siguiente`, `pagina_anterior`, `resultados`), ordenado de la
más reciente a la más antigua. `tamano_pagina` tiene máximo 100:

```json
{
  "conteo": 1,
  "pagina_siguiente": null,
  "pagina_anterior": null,
  "resultados": [
    {
      "id": "e08d2320-7645-448e-b247-b999fba999dd",
      "repartidor_id": "a465f3ae-a12b-4972-ae27-8076480f3773",
      "jornada_id": "9f106ce2-050c-4ef7-ab94-446207b8499e",
      "estado": "ACTIVA",
      "iniciada_en": "2026-10-06T09:00:00-06:00",
      "finalizada_en": null,
      "cantidad_versiones": 2
    }
  ]
}
```

Las versiones se listan por `numero` descendente. Su respuesta tiene el
mismo sobre paginado y cada resultado contiene `id`, `ruta_id`, `numero`,
`motivo`, `creada_en` y `cantidad_paradas`. El detalle de una versión añade
`paradas` en orden ascendente:

```json
{
  "id": "465f6eb1-2991-4ce1-89f5-1ba31c09560a",
  "ruta_id": "e08d2320-7645-448e-b247-b999fba999dd",
  "numero": 2,
  "motivo": "CAMBIO_ESTADO",
  "creada_en": "2026-10-06T09:15:00-06:00",
  "cantidad_paradas": 1,
  "paradas": [
    {
      "orden": 1,
      "solicitud_id": "bf9490a0-aeb4-4df5-8bd1-8c1341ddfeac",
      "numero_solicitud": "SOL-20260928-BF9490A0",
      "prioridad": "NORMAL",
      "modalidad": "ENTRE_SUCURSALES",
      "estado_solicitud": "PICKED_UP",
      "tipo": "ENTREGA",
      "ubicacion": {
        "id": "3c18fa32-7bc2-4743-9744-f22453730413",
        "nombre": "Sucursal Norte",
        "direccion": "Bulevar Suyapa, Tegucigalpa",
        "latitud": "14.085600",
        "longitud": "-87.165400"
      },
      "destino_especial": null,
      "presentacion_ruta": "MAPA"
    }
  ]
}
```

La ubicación en este detalle es la copia histórica: cambios posteriores al
catálogo de lugares no alteran la versión. Para un envío especial,
`ubicacion=null`, `destino_especial` conserva el texto y
`presentacion_ruta=SOLO_KILOMETROS`. Una versión sin paradas devuelve
`cantidad_paradas=0` y `paradas=[]`. Los motivos disponibles son `INICIAL`,
`ASIGNACION`, `REASIGNACION`, `CAMBIO_ESTADO`, `CANCELACION`,
`INICIO_JORNADA` y `CIERRE_JORNADA`.

Sin sesión se responde `401`; sin `ruta.ver`, `403`; una ruta o versión
inexistente o fuera del alcance devuelve `404`. Un filtro inválido devuelve
`400` asociado a `repartidor_id` o `estado`. Las rutas asignadas antes de
activar este historial no se reconstruyen retrospectivamente. Estas consultas
no crean versiones ni contienen polilínea, ETA o cálculo vial.

## 23. Seguimiento GPS

Esta primera fase no llama a Google Maps. El dispositivo obtiene las
coordenadas mediante su sistema operativo y las envía a VitaGo. El backend
conserva los puntos, determina si pertenecen a una operación y limita su
consulta al contexto de una solicitud autorizada.

### Registrar ubicaciones

```http
POST /api/v1/seguimiento/registros/
Content-Type: application/json
```

Solo puede utilizarlo el motorista autenticado con el permiso
`repartidor.registrar_ubicacion`. La jornada debe pertenecerle. Se aceptan
puntos retrasados siempre que `registrada_en` se encuentre dentro del intervalo
de la jornada. Cada lote admite entre 1 y 200 registros.

```json
{
  "jornada_id": "9f106ce2-050c-4ef7-ab94-446207b8499e",
  "registros": [
    {
      "id_cliente": "bd1a0f90-c321-44c4-a3a8-8aa9ca80dc51",
      "latitud": "14.072300",
      "longitud": "-87.192100",
      "precision_metros": "8.50",
      "velocidad_metros_segundo": "4.250",
      "rumbo_grados": "180.00",
      "registrada_en": "2026-09-26T15:10:00Z"
    }
  ]
}
```

| Campo | Tipo | Obligatorio | Regla |
|---|---|---|---|
| `id_cliente` | UUID | Sí | Identificador estable generado por el dispositivo para reintentos. |
| `latitud` | decimal | Sí | Entre -90 y 90. |
| `longitud` | decimal | Sí | Entre -180 y 180. |
| `precision_metros` | decimal | No | Mayor o igual que cero. |
| `velocidad_metros_segundo` | decimal | No | Mayor o igual que cero. |
| `rumbo_grados` | decimal | No | Desde 0 hasta 359.99. |
| `registrada_en` | fecha ISO 8601 | Sí | Hora de captura del punto. Anclarla a `hora_servidor` más tiempo monotónico; no usar el reloj manual ni la recepción común del lote. |

La combinación de motorista e `id_cliente` es única. Repetir exactamente el
mismo registro no crea otra fila. Reutilizar el identificador con valores
distintos responde `400`.

Respuesta `201`:

```json
{
  "recibidos": 1,
  "creados": 1,
  "repetidos": 0,
  "llegadas_detectadas": [],
  "registros": [
    {
      "id": "377618eb-38b6-4247-8a90-89cd0f497f55",
      "id_cliente": "bd1a0f90-c321-44c4-a3a8-8aa9ca80dc51",
      "jornada_id": "9f106ce2-050c-4ef7-ab94-446207b8499e",
      "repartidor_id": "a465f3ae-a12b-4972-ae27-8076480f3773",
      "latitud": "14.072300",
      "longitud": "-87.192100",
      "precision_metros": "8.50",
      "velocidad_metros_segundo": "4.250",
      "rumbo_grados": "180.00",
      "registrada_en": "2026-09-26T15:10:00Z",
      "es_operativo": true,
      "movimiento_envio_especial_id": null,
      "creado_en": "2026-09-26T15:10:03Z"
    }
  ]
}
```

`es_operativo` lo calcula exclusivamente el backend. Es verdadero cuando el
momento del punto cae dentro de una asignación aceptada y aún no finalizada del
motorista. El frontend no debe enviarlo ni calcularlo.

Para tolerar pérdidas de red, la aplicación puede guardar localmente los puntos
pendientes y reenviar el mismo `id_cliente`. Debe retirar de su cola los
registros incluidos en una respuesta correcta.

Durante un envío especial, `movimiento_envio_especial_id` contiene el UUID del
movimiento. El backend descarta del cálculo los puntos cuya precisión supere
`PRECISION_GPS_MAXIMA_METROS` o que impliquen una velocidad superior a
`VELOCIDAD_GPS_MAXIMA_METROS_SEGUNDO`. Los valores predeterminados locales son
100 metros y 55 metros por segundo. Google Maps no participa en este cálculo.

### Consultar seguimiento de una solicitud

```http
GET /api/v1/solicitudes/{solicitud_id}/seguimiento/
```

La consulta exige visibilidad sobre la solicitud y el permiso
`solicitud.ver_seguimiento` dentro de su alcance. No existe un endpoint abierto
para consultar directamente la ubicación de un motorista.

Respuesta `200` durante una solicitud activa:

```json
{
  "solicitud_id": "bf9490a0-aeb4-4df5-8bd1-8c1341ddfeac",
  "estado": "IN_TRANSIT",
  "seguimiento_disponible": true,
  "ubicacion": {
    "id": "377618eb-38b6-4247-8a90-89cd0f497f55",
    "id_cliente": "bd1a0f90-c321-44c4-a3a8-8aa9ca80dc51",
    "jornada_id": "9f106ce2-050c-4ef7-ab94-446207b8499e",
    "repartidor_id": "a465f3ae-a12b-4972-ae27-8076480f3773",
    "latitud": "14.072300",
    "longitud": "-87.192100",
    "precision_metros": "8.50",
    "velocidad_metros_segundo": "4.250",
    "rumbo_grados": "180.00",
    "registrada_en": "2026-09-26T15:10:00Z",
    "es_operativo": true,
    "movimiento_envio_especial_id": null,
    "creado_en": "2026-09-26T15:10:03Z"
  }
}
```

Si todavía no existe un punto operativo, `ubicacion` es `null`. Cuando la
solicitud termina, se cancela o falla, el backend responde
`seguimiento_disponible=false` y `ubicacion=null`, aunque el usuario conserve
acceso al detalle histórico de la solicitud.

La primera integración puede consultar este endpoint periódicamente. Aún no se
usan WebSockets, Redis, Google Routes ni Google Roads. Los puntos GPS válidos
contribuyen al kilometraje operativo al cerrar la jornada; los movimientos
`ESPECIAL` calculan y congelan su kilometraje al terminar cada envío.

## 24. Incidencias operativas

### Reportar una incidencia

```http
POST /api/v1/incidencias/
Content-Type: application/json
```

Solo el motorista autenticado con `incidencia.crear` puede reportar durante su
jornada activa. La solicitud es opcional; cuando se proporciona, el backend
comprueba que esté asignada al motorista en la hora oficial de registro,
no en una fecha elegida por el cliente.

```json
{
  "solicitud_id": "bf9490a0-aeb4-4df5-8bd1-8c1341ddfeac",
  "descripcion": "La calle de acceso está cerrada por trabajos.",
  "latitud": "14.072300",
  "longitud": "-87.192100"
}
```

`solicitud_id`, `latitud` y `longitud` son opcionales. Las coordenadas deben
enviarse juntas. `descripcion` es obligatoria. `reportada_en` es de solo lectura:
el servidor fija la hora del reporte y descarta el valor del teléfono. La hora
oficial debe pertenecer a la jornada activa y, en Corporate, a su día operativo.
Retroceder el reloj no permite reportar con una asignación ya terminada.

Respuesta `201`:

```json
{
  "id": "79763994-ef14-453c-b80e-987b3e11d95f",
  "jornada_id": "9f106ce2-050c-4ef7-ab94-446207b8499e",
  "repartidor_id": "a465f3ae-a12b-4972-ae27-8076480f3773",
  "solicitud_id": "bf9490a0-aeb4-4df5-8bd1-8c1341ddfeac",
  "estado": "ABIERTA",
  "descripcion": "La calle de acceso está cerrada por trabajos.",
  "latitud": "14.072300",
  "longitud": "-87.192100",
  "reportada_en": "2026-09-26T16:10:00Z",
  "revisada_por_id": null,
  "revisada_en": null,
  "cerrada_en": null,
  "eventos": [
    {
      "tipo": "REPORTADA",
      "estado_anterior": null,
      "estado_nuevo": "ABIERTA"
    }
  ]
}
```

El objeto real de cada evento también contiene `id`, `realizado_por_id`,
`notas`, `metadatos` y `creado_en`.

### Consultar incidencias

```http
GET /api/v1/incidencias/
GET /api/v1/incidencias/{incidencia_id}/
```

El listado usa el sobre paginado estándar y acepta `estado`, `jornada_id`,
`solicitud_id` y `repartidor_id`. Un motorista solo puede consultar sus propias
incidencias. Gerentes de operaciones y administradores con `incidencia.revisar` consultan
únicamente el alcance organizacional permitido.

Estados disponibles:

- `ABIERTA`;
- `EN_REVISION`;
- `CERRADA`.

### Revisar o cerrar una incidencia

```http
POST /api/v1/incidencias/{incidencia_id}/revision/
Content-Type: application/json
```

Requiere `incidencia.revisar` dentro del alcance del motorista.

```json
{
  "estado": "EN_REVISION",
  "notas": "El supervisor está verificando el cierre de la calle."
}
```

Transiciones permitidas:

```text
ABIERTA -> EN_REVISION -> CERRADA
ABIERTA ----------------> CERRADA
```

Cada transición conserva responsable, fecha, estado anterior, estado nuevo y
notas. Una incidencia cerrada no se reabre ni se elimina.

### Evidencias de incidencia

```http
GET  /api/v1/incidencias/{incidencia_id}/evidencias/
POST /api/v1/incidencias/{incidencia_id}/evidencias/
GET  /api/v1/incidencias/{incidencia_id}/evidencias/{evidencia_id}/archivo/
```

El registro utiliza `multipart/form-data` con:

| Campo | Tipo | Obligatorio |
|---|---|---|
| `archivo` | JPEG, PNG o WebP | Sí |
| `latitud` | decimal entre -90 y 90 | Sí |
| `longitud` | decimal entre -180 y 180 | Sí |
| `capturada_en` | fecha ISO 8601 del servidor; entrada ignorada | No; solo lectura |
| `notas` | texto | No |

Solo el motorista que reportó la incidencia puede agregar evidencia y no puede
hacerlo después del cierre de la **incidencia**. Una incidencia abierta conserva
esa posibilidad después del cierre de jornada; se registra la hora actual del
servidor, sin atribuir esa hora a una captura pasada. La imagen respeta el tamaño máximo configurado para
evidencias. Los archivos son privados, requieren Bearer token para descargarse
y nunca exponen su clave interna de almacenamiento.

Al finalizar una jornada, `incidencias_reportadas` se calcula contando las
incidencias relacionadas directamente con ella y queda congelado en el resumen.

## 25. Guía de integración para las pantallas del motorista

Esta guía aplica a `REPARTIDOR_CORPORATIVO` (Analiza) y `REPARTIDOR_RED`.
Los endpoints y ejemplos completos están en las secciones 19 a 24. La app
debe usar el host de su despliegue: Corporate y Network no comparten datos ni
sesiones.

| Pantalla o acción | API disponible | Dato o regla para la interfaz |
|---|---|---|
| Acceso e inicio | Autenticación local durante desarrollo; `GET /api/v1/usuarios/mi-perfil/`; `GET /api/v1/repartidores/mi-perfil/` | Usar `roles` y `permisos` para la navegación; consultar el perfil de motorista para obtener `id`, estado, capacidad y vehículo antes de iniciar jornada. |
| Jornada actual | `GET /api/v1/jornadas/activa/`; `POST /api/v1/jornadas/iniciar/` | `jornada: null` significa que aún no comenzó. El inicio devuelve `id` de jornada y `repartidor_id`; conservar ambos. |
| Servicios asignados y paradas | `GET /api/v1/solicitudes/`; `GET /api/v1/solicitudes/{solicitud_id}/`; `GET /api/v1/rutas/mi-ruta/` | El listado paginado se limita al motorista autenticado. `mi-ruta/` entrega las paradas operativas pendientes y la próxima parada, sin navegación ni ETA. |
| Recolección, traslado y entrega | `POST /api/v1/solicitudes/{solicitud_id}/transiciones/` | Mostrar solo la transición siguiente de la matriz de la sección 21; usar el detalle devuelto como estado actualizado. |
| Fotos | `POST /api/v1/solicitudes/{solicitud_id}/evidencias/`; `GET` de evidencias y archivo | Registrar `FOTO_RECOLECCION` en `AT_PICKUP` antes de `PICKED_UP`, y `FOTO_ENTREGA` en `AT_DESTINATION` antes de `DELIVERED`. El archivo requiere Bearer token. |
| Ubicación e incidencias | `POST /api/v1/seguimiento/registros/`; `POST /api/v1/incidencias/` | Enviar GPS con `jornada_id` e `id_cliente` estable; las incidencias pertenecen a una jornada activa. |
| Cierre y resumen | `POST /api/v1/jornadas/{jornada_id}/finalizar/`; `GET /api/v1/jornadas/` | No se puede cerrar con asignaciones activas. Mostrar `kilometros_operativos` solo si `kilometraje_disponible=true`; vaciar la cola GPS antes de cerrar. |

`GET /api/v1/solicitudes/` acepta `estado`, `prioridad` y `modalidad` como
filtros, pero solo un valor de `estado` por petición. Para una vista de
servicios en curso se pueden separar localmente los estados no terminales del
listado paginado, recorriendo todas sus páginas. Para el historial, los
estados terminales son `DELIVERED`, `CANCELLED`, `PICKUP_FAILED` y
`DELIVERY_FAILED`. Una solicitud reasignada deja de ser visible para el
motorista anterior; por ahora no existe un historial propio independiente de
las solicitudes visibles. Para las paradas pendientes y la próxima acción se
usa `GET /api/v1/rutas/mi-ruta/`, con orden estable por cercanía GPS desde 0.35.0.

En Analiza, `modalidad` distingue `ENTRE_SUCURSALES`,
`EMPRESA_TRANSPORTE` y `ESPECIAL`. En las dos primeras, `origen` y `destino`
incluyen coordenadas registradas. `presentacion_ruta: "MAPA"` expresa la
presentación prevista, pero **no** significa que la respuesta ya incluya
polilínea, ruta calculada, distancia de Google, ETA ni redirección al tomar
otra calle. En `ESPECIAL`, `destino` es `null`, se muestra el texto
`destino_especial` y `presentacion_ruta: "SOLO_KILOMETROS"`: no debe dibujarse
una ruta seleccionada. Sus kilómetros GPS aparecen en
`kilometros_envio_especial` solo al cerrar el movimiento. Network mantiene su
operación abierta y no usa estas restricciones corporativas.

Para un envío `ESPECIAL`, antes de pasar a `PICKED_UP` debe existir jornada
activa y foto de recolección con coordenadas; desde 0.36.0 no se envía otra
transición para recoger o entregar después de esa foto. Al finalizar o
fallar la entrega se requieren también las coordenadas finales y, para
`DELIVERED`, la foto de entrega. Enviar primero los puntos GPS pendientes:
el kilometraje especial se congela al cerrar y los puntos tardíos no lo
recalculan.

Ante una respuesta perdida, volver a consultar jornada y detalle de solicitud
antes de repetir una transición, cierre o carga de foto: esas operaciones no
tienen clave de idempotencia pública. La excepción son los registros GPS,
que sí admiten reenvío idéntico con el mismo `id_cliente`. Las notificaciones
persistentes se consultan por API; todavía no hay entrega push ni eventos en
tiempo real. Actualizar listados y detalles por consulta periódica o al volver
a la pantalla.

### Datos que todavía faltan para completar la interfaz del motorista

- `GET /api/v1/rutas/mi-ruta/` ofrece orden estable por cercanía GPS y trazado
  inicial opcional de Google, con tramos por envío/parada. No incluye ETA en
  vivo, navegación giro a giro ni optimización por calles/tráfico.
- El resumen de jornada sí incluye kilómetros operativos medidos por GPS.
  No equivale a ruta vial calculada, ETA ni distancia de cada servicio.

## 26. Panel administrativo

El backend no expone Django Admin. El frontend debe construir el panel usando
estas API y los permisos recibidos en `mi-perfil`. Ocultar botones en la UI no
reemplaza las validaciones del backend.

## 27. Endpoints futuros

La recuperación de contraseña por correo está prevista para una fase posterior
y utilizará la API de Brevo cuando el proveedor sea `LOCAL`. No aplicará al
proveedor `JWT_CORPORATIVO`, cuya recuperación dependerá del sistema central.
Todavía no existe un endpoint disponible, no se ha instalado una dependencia
para Brevo y no se requieren credenciales de ese proveedor en la configuración
actual.

Cuando se implemente una API nueva deberá agregarse primero a la tabla de
endpoints, documentar su contrato completo y registrar el cambio en el
historial.

## 28. Lista de verificación para actualizar este documento

Por cada cambio de API:

1. Actualizar la fecha y el historial.
2. Actualizar la tabla general de endpoints.
3. Documentar método, ruta, modo y autenticación.
4. Documentar todos los campos y su obligatoriedad.
5. Añadir ejemplos JSON válidos.
6. Documentar códigos HTTP y reglas del frontend.
7. Marcar explícitamente cualquier cambio incompatible.
8. Confirmar que el comportamiento documentado tiene pruebas en el backend.

## 29. Datos locales de prueba para Corporate

En `vitago_corporativo` local existe un escenario ficticio de Analiza para
integración visual. No añade endpoints ni cambia ningún JSON:

- `GET /api/v1/solicitudes/opciones-creacion/` ofrece dos sucursales de origen;
  con `modalidad=ENTRE_SUCURSALES` y el origen «Prueba - Sucursal Centro»,
  devuelve «Prueba - Sucursal Norte» como destino. Con
  `modalidad=EMPRESA_TRANSPORTE`, devuelve «Prueba - Empresa de transporte».
- El comando de datos de prueba prepara, si aún faltan, una solicitud entre
  sucursales y otra hacia empresa de transporte. Las nuevas se asignan
  automáticamente si hay un motorista elegible; las creadas antes de este
  cambio pueden seguir `PENDING`. El listado real puede incluir más pruebas
  realizadas desde la app: no asumir una cantidad ni estado fijos.
- Los UUID y números de solicitud se generan en la base local; el frontend
  debe obtenerlos de la API y nunca fijarlos en el código.

Las coordenadas y direcciones del escenario son ficticias; no sirven para
probar rutas ni kilometraje de Google Maps. Si un usuario cambia el estado de
las solicitudes durante las pruebas, repetir el comando no las restablece.
La preparación y sus requisitos están descritos en
`VITAGO_EJECUCION_LOCAL.md`.

## 30. Notificaciones persistentes y validaciones

Estas rutas están disponibles en Corporate y Network, requieren Bearer token
y solo muestran o modifican notificaciones del usuario autenticado. La
vigencia desde 0.33.0 es **solo el día operativo del servidor**: los avisos
anteriores no aparecen ni cuentan como no leídos, aunque la tarea se retrase.
No es una duración de 24 horas desde la creación. Los avisos se archivan sin
borrar registros ni convertirlos artificialmente en leídos. La
asignación crea una notificación para el motorista nuevo; la reasignación
notifica también al anterior. Una solicitud `PRIORITY` produce para el nuevo
motorista una única notificación de tipo `SOLICITUD_PRIORITARIA` en lugar de
duplicar el aviso de asignación. Se guardan dentro de la misma transacción.

```http
GET /api/v1/notificaciones/?pagina=1&tamano_pagina=20
GET /api/v1/notificaciones/conteo-no-leidas/
POST /api/v1/notificaciones/{notificacion_id}/marcar-leida/
```

El listado responde `200` con el sobre paginado estándar, ordenado de la más
reciente a la más antigua:

```json
{
  "conteo": 1,
  "pagina_siguiente": null,
  "pagina_anterior": null,
  "resultados": [
    {
      "id": "92566b94-d543-4b61-bc17-bf63a8aa3b58",
      "tipo": "SOLICITUD_ASIGNADA",
      "titulo": "Nuevo servicio asignado",
      "mensaje": "Tienes asignada la solicitud SOL-001.",
      "solicitud_id": "c1901dbb-f48b-4ec7-836e-a69f9e47abca",
      "ruta": "/solicitudes/c1901dbb-f48b-4ec7-836e-a69f9e47abca",
      "enlace_profundo": "vitago-corporate:///solicitudes/c1901dbb-f48b-4ec7-836e-a69f9e47abca",
      "leida": false,
      "leida_en": null,
      "creado_en": "2026-10-23T12:00:00Z"
    }
  ]
}
```

En Network, `enlace_profundo` usa el esquema
`vitago-network:///solicitudes/{solicitud_id}`. `ruta` siempre es
`/solicitudes/{solicitud_id}`. Los tipos posibles son `SOLICITUD_ASIGNADA`,
`SOLICITUD_REASIGNADA`, `SOLICITUD_RETIRADA` y
`SOLICITUD_PRIORITARIA`. No implica que Android ya tenga registrado el
esquema; esa configuración corresponde a la app. Por ahora consultar el
conteo al abrir la pantalla o periódicamente; no existe push.

El conteo responde `200` con `{"conteo_no_leidas": 1}`. Marcar leída no
requiere cuerpo; responde `200` con el mismo objeto de notificación,
`leida: true` y `leida_en` con fecha. Repetir la operación es seguro. Una
notificación ajena o inexistente responde `404`.
Desde 0.33.0, un aviso de un día anterior o ya archivado también devuelve `404`
al intentar marcarlo leído; no se recupera ni reaparece por usar un ID guardado.

Los errores de validación `400` mantienen claves de campo estables, por
ejemplo `correo`, `placa`, `empresa_id`, `sucursal_id`, `rol_codigo`,
`origen_id` y `destino_id`; los errores generales pueden usar `detail`.
Para artículos, cada error identifica explícitamente el índice cero-basado
y el campo:

```json
{
  "articulos": [
    {"indice": 1, "campo": "cantidad", "mensaje": "Debe ser positiva."}
  ]
}
```

Un `400` o `409` recibido con JSON es una respuesta del backend y no debe
mostrarse como error genérico de conexión.

## Control de GPS y consolidación de kilometraje (0.26.0)

### Configuración del dispositivo

```http
GET /api/v1/seguimiento/configuracion/
Authorization: Bearer <access_token>
```

Solo motorista propietario con perfil activo y
`repartidor.registrar_ubicacion`. `401` sin sesión, `404` sin perfil, `403`
sin permiso. Respuesta `200` con los valores efectivos del despliegue:

```json
{
  "hora_servidor": "2026-10-20T18:00:00+00:00",
  "zona_horaria_operativa": "America/Tegucigalpa",
  "intervalo_captura_movimiento_segundos": 5,
  "intervalo_captura_detenido_segundos": 15,
  "intervalo_envio_segundos": 20,
  "tamano_maximo_lote": 200,
  "antiguedad_maxima_asignacion_segundos": 120,
  "precision_maxima_asignacion_metros": 50.0,
  "asignacion_requiere_gps_vigente": true,
  "intervalo_maximo_medicion_segundos": 30,
  "cobertura_minima_porcentaje": 90.0,
  "diagnostico_captura": {
    "muestra_puntos": 0,
    "intervalos_evaluados": 0,
    "intervalos_fuera_umbral": 0,
    "intervalo_maximo_observado_segundos": null,
    "requiere_ajuste_captura": false,
    "mensaje": null,
    "umbral_segundos": 30
  },
  "llegada_automatica": {
    "habilitada": true,
    "radio_metros": 50.0,
    "permanencia_minima_segundos": 10,
    "minimo_puntos": 3,
    "precision_maxima_metros": 20.0,
    "antiguedad_maxima_segundos": 30,
    "solo_proxima_parada": true,
    "destino_especial_sin_coordenadas_manual": true
  }
}
```

`diagnostico_captura` analiza únicamente los últimos 60 puntos de la jornada
activa propia y sus fechas de **captura**; no el intervalo entre peticiones.
No expone coordenadas, identificadores de puntos ni datos de otros motoristas.
Intervalos positivos mayores al umbral activan `requiere_ajuste_captura` y un
mensaje informativo. Sin jornada/datos, devuelve ceros y máximo/mensaje nulos.
Un lote enviado cada 40 segundos puede ser correcto si contiene capturas cada
5 segundos; capturar solo cada 40 segundos deja huecos que no se pueden recuperar.
El nuevo valor detenido de 15 segundos deja margen frente al límite de 30;
no se amplía el umbral ni se recalculan históricos. Flutter debe aplicar estos
valores y mantener la captura real en Android, también en segundo plano.

Captura y envío son independientes. Persistir la cola local, incluso sin
internet; enviar además al iniciar/finalizar operaciones. La app móvil debe
mantener el servicio de ubicación correctamente cuando está en segundo plano
o abre otro navegador. Estas capacidades no se implementan desde Django.
Los intervalos son valores iniciales configurables, sujetos a pruebas de
batería/precisión en teléfonos físicos.

La asignación automática Corporate exige por defecto una posición de jornada
`ACTIVA`, capturada hace como máximo 120 segundos, no futura, con precisión
conocida de hasta 50 metros. Si no hay candidato permanece `PENDING`. Recibir
un lote GPS vigente reintenta pendientes tras el commit, hasta cinco por
evento. Para que el primer servicio se asigne, iniciar jornada y enviar GPS:
las coordenadas del inicio de jornada por sí solas no sustituyen un registro
de ubicación con precisión. Motoristas de prueba siguen las mismas reglas.
El fallback sin GPS solo existe si se configura expresamente
`ASIGNACION_REQUIERE_GPS_VIGENTE=false`; no es el valor recomendado.
La asignación manual autorizada permite decidir ante falta de GPS.

### Sesiones y secuencias para verificar sincronización

`POST /api/v1/seguimiento/registros/` conserva el contrato anterior y acepta
dos campos adicionales por punto, siempre juntos:

```json
{
  "jornada_id": "fa714070-b19e-4d63-8463-e4eea308a050",
  "registros": [
    {
      "id_cliente": "3c645b08-905d-412a-a7b8-dfdde1621f1f",
      "sesion_gps": "119d601d-d835-46fd-81dd-7e2cd71f3e6e",
      "secuencia": 1,
      "latitud": "14.000000",
      "longitud": "-87.000000",
      "precision_metros": "8.00",
      "velocidad_metros_segundo": "4.250",
      "rumbo_grados": "180.00",
      "registrada_en": "2026-10-13T16:00:00Z"
    }
  ]
}
```

La respuesta `201` conserva `recibidos`, `creados`, `repetidos`, `registros`;
cada registro añade `sesion_gps` y `secuencia` (ambos `null` para clientes
antiguos). Generar un UUID de sesión de captura y una secuencia desde 1;
persistir sesión, próximo número, UUID de punto y contenido antes de enviar.
Reintentar exactamente el mismo punto, sin cambiar UUID, hora ni secuencia.
La sesión no puede reutilizarse en otra jornada. Si se inicia otra sesión,
declarar también las anteriores al cerrar; máximo 50 sesiones por manifiesto.
La recepción puede desordenarse: el cálculo usa la hora de captura.

`400` si se reutiliza una secuencia con otro UUID, se cambia el contenido de
un UUID existente, falta uno de los campos o el timestamp no pertenece a la
jornada. Un cierre ya verificado solo admite reintentos idénticos de sus
puntos; sus secuencias y manifiesto son inmutables.

### Cierre y confirmación

`POST /api/v1/jornadas/{jornada_id}/finalizar/` añade un manifiesto opcional:

```json
{
  "latitud": "14.000200",
  "longitud": "-87.000000",
  "sesiones_gps": [
    {
      "sesion_gps": "119d601d-d835-46fd-81dd-7e2cd71f3e6e",
      "ultima_secuencia": 3
    }
  ]
}
```

Declarar el último número **generado** de cada sesión, incluyendo los puntos
pendientes en el teléfono y los no operativos. El servidor verifica todos los
números `1..ultima_secuencia`, no solo la presencia del último. `[]` solo
confirma ausencia de datos si efectivamente no existen registros; no convierte
la falta de GPS en una distancia cero válida. Los puntos antiguos sin sesión
impiden verificar el manifiesto: adoptar el protocolo desde una jornada nueva.

La jornada se cierra operativamente y libera al motorista aunque la medición
quede pendiente; sin asignaciones activas sigue siendo un requisito. La
respuesta completa sigue el JSON de jornada documentado previamente y añade
`minutos_operativos` (entero o `null`) y `calidad_kilometraje` (objeto).
Ejemplo del objeto nuevo con un punto pendiente:

```json
{
  "estado": "PENDIENTE_SINCRONIZACION",
  "metodo": "GPS_FILTRADO",
  "sincronizacion_verificada": false,
  "puntos_pendientes": 1,
  "sesiones_gps": [
    {"sesion_gps": "119d601d-d835-46fd-81dd-7e2cd71f3e6e", "ultima_secuencia": 3}
  ],
  "puntos_considerados": 2,
  "puntos_descartados": 0,
  "puntos_sin_precision": 0,
  "segmentos_validos": 1,
  "huecos_detectados": 0,
  "segundos_cubiertos": 10.0,
  "segundos_operativos": 10.0,
  "especiales_sin_calidad": 0,
  "movimientos_pendientes": 0,
  "cobertura_porcentaje": 100.0,
  "revision": 1,
  "actualizada_en": "2026-10-13T16:00:12Z"
}
```

Los contadores son una instantánea de esa revisión, no un contador continuo
de la cola. El envío del último lote pendiente provoca la consolidación
automática. Un reintento idéntico no genera otra revisión.

Para confirmar posteriormente un cierre nuevo que se hizo sin manifiesto,
o corregir un manifiesto pendiente:

```http
POST /api/v1/jornadas/{jornada_id}/sincronizacion-gps/
```

Cuerpo: `{"sesiones_gps": [...]}` con el formato anterior. Devuelve `200`
con la jornada completa. Requiere propietario y `jornada.finalizar`; `404`
si es ajena, inexistente o no finalizada; `400` si intenta cambiar un cierre
verificado o recalcular uno histórico.

### Estados de la medición y presentación

| `calidad_kilometraje.estado` | Presentación |
|---|---|
| `SIN_VERIFICAR` | Estimación sin confirmación de sincronización. |
| `PENDIENTE_SINCRONIZACION` | Kilometraje pendiente; puede cambiar al llegar la cola GPS. |
| `SIN_DATOS` | Sin segmentos utilizables; no afirmar que recorrió cero. |
| `INCOMPLETO` | Sincronización completa, pero cobertura/precisión insuficiente o especiales históricos sin calidad. |
| `CONSOLIDADO` | Medición GPS consolidada bajo los filtros; sigue siendo una estimación. |

`calidad_kilometraje={}` indica ausencia de evaluación nueva (jornada activa
o cierre histórico, según su estado). No recalcular históricos.
La cobertura mide qué parte del tiempo operativo tiene pares de puntos
utilizables, no demuestra qué calle recorrió ni un porcentaje de exactitud.
`kilometraje_disponible` conserva compatibilidad: indica segmentos utilizables
o un especial histórico disponible; no implica calidad suficiente. Mostrar
la calidad junto al valor. Si estaba detenido con señal suficiente, un
kilometraje `0.000` puede ser válido.

`minutos_activos` conserva su significado anterior: duración total de la
jornada. `minutos_operativos` mide la unión de intervalos de trabajo y
especiales sin duplicar solicitudes simultáneas; incluye esperas en operación,
no significa tiempo exclusivamente conduciendo.

El cálculo corta pares separados más de `INTERVALO_GPS_MAXIMO_SEGUNDOS`,
filtra precisión y velocidad anómala, conserva un ancla espacial contra
oscilaciones pequeñas y no rellena huecos mediante rutas imaginadas.
Estos filtros también se aplican a envíos especiales. No consulta Google.

### Envíos especiales y prioridad

En `POST /api/v1/solicitudes/{solicitud_id}/transiciones/`, el cierre de
`ESPECIAL` mediante `DELIVERED` o `DELIVERY_FAILED` admite `sesiones_gps`.
Se refiere a las sesiones generadas en la jornada hasta ese cierre; no incluir
secuencias capturadas posteriormente. Conserva el cierre con coordenadas,
evidencia y `presentacion_ruta=SOLO_KILOMETROS`. El JSON completo de
`movimiento_especial` añade `calidad_kilometraje`; los extremos operativos
sin precisión conocida se reflejan en la calidad, sin inventar precisión GPS.

```http
POST /api/v1/solicitudes/{solicitud_id}/sincronizacion-gps/
```

Cuerpo `{"sesiones_gps": [...]}`. Solo el motorista propietario con
`solicitud.actualizar_estado`, sobre un movimiento especial finalizado nuevo.
Respuesta `200`: objeto completo `movimiento_especial` con los campos
documentados en su detalle y `calidad_kilometraje`. `404` sin ese movimiento;
`403` si no es el propietario; `400` para histórico o manifiesto consolidado
diferente. Una jornada ya consolidada no permite revisar un especial y
cambiar retrospectivamente su total. Confirmar primero los especiales y
después la jornada. Al confirmar toda la jornada, el backend confirma también
los prefijos pendientes de sus movimientos especiales nuevos.

Mientras lleva un prioritario `PICKED_UP`, `IN_TRANSIT` o `AT_DESTINATION`,
el backend rechaza con `400` y campo `estado_destino` la operación de otra
solicitud ya asignada. La cancelación administrativa conserva sus permisos.
Esto complementa el bloqueo de nuevas asignaciones.

### Auditoría

```http
GET /api/v1/jornadas/{jornada_id}/kilometraje/revisiones/
```

Requiere `jornada.ver` y alcance compatible, igual que el detalle de jornada.
Respuesta paginada `200`: `conteo`, `pagina_siguiente`, `pagina_anterior`, `resultados`.
Cada resultado tiene exactamente `id`, `jornada_id`,
`movimiento_especial_id` (UUID o `null`), `numero`, `motivo`, `kilometros`
(cadena decimal), `calidad` (objeto) y `creado_en` (ISO 8601).
Motivos actuales: `CIERRE`, `GPS_TARDIO`, `CONFIRMACION_GPS`.
El número es por jornada o por movimiento; dos movimientos distintos pueden
tener revisión 1. No hay endpoint de edición/borrado de revisiones.

### Alcance de esta fase

GPS, calidad y consolidación están implementados en ambos despliegues.
La asignación automática continúa siendo Corporate y usa proximidad
geográfica, no ETA vial. La presentación de `mi-ruta/` y el trazado inicial
se actualizan en 0.28.0, descrita a continuación, con mapa integrado y sin
enlaces externos. Siguen pendientes compatibilidad/optimización vial y ETA
en vivo. Los cambios de GPS no habilitan Google ni generan recálculos pagados.

## Ruta inicial para el mapa integrado (0.28.0)

Implementado en ambos despliegues, sin cambios en conexión, puertos, sesiones
o reglas exclusivas de Analiza. No usa Waitress, Redis, tareas externas ni
servidores adicionales. La integración requiere activación explícita del
proveedor de rutas y configuración del SDK del mapa en la app. Las pruebas son
simuladas: no demuestran un tiempo de viaje real ni hacen consultas a Google.

### Lectura de la ruta propia

`GET /api/v1/rutas/mi-ruta/` conserva todos los campos existentes y añade
`mapa` y `ruta_vial`. El campo antiguo `navegacion` ya no existe. Nunca llama a Google, cambia versiones ni consume
presupuesto. Requiere motorista propio activo y `solicitud.ver_asignadas`.
Desde 0.35.0 las paradas siguen el orden estable por cercanía GPS del backend;
**no hay optimización vial ni selección de motorista por ETA de Google**.

Ejemplo completo sin Google configurado, con las coordenadas de las
ubicaciones ficticias de las pruebas del backend:

```json
{
  "repartidor_id": "10000000-0000-0000-0000-000000000001",
  "jornada_id": "20000000-0000-0000-0000-000000000001",
  "ruta_id": "30000000-0000-0000-0000-000000000001",
  "version_actual": 1,
  "orden_tipo": "CERCANIA_GPS",
  "ruta_calculada": false,
  "llegada_actual": null,
  "proxima_parada": {
    "orden": 1,
    "solicitud_id": "40000000-0000-0000-0000-000000000001",
    "numero_solicitud": "SOL-VIAL-1",
    "prioridad": "NORMAL",
    "modalidad": "ENTRE_SUCURSALES",
    "estado_solicitud": "ASSIGNED",
    "tipo": "RECOLECCION",
    "ubicacion": {
      "id": "50000000-0000-0000-0000-000000000001",
      "nombre": "Sucursal Centro",
      "direccion": "Centro",
      "latitud": "14.072300",
      "longitud": "-87.192100"
    },
    "destino_especial": null,
    "presentacion_ruta": "MAPA"
  },
  "paradas": [
    {
      "orden": 1,
      "solicitud_id": "40000000-0000-0000-0000-000000000001",
      "numero_solicitud": "SOL-VIAL-1",
      "prioridad": "NORMAL",
      "modalidad": "ENTRE_SUCURSALES",
      "estado_solicitud": "ASSIGNED",
      "tipo": "RECOLECCION",
      "ubicacion": {
        "id": "50000000-0000-0000-0000-000000000001",
        "nombre": "Sucursal Centro",
        "direccion": "Centro",
        "latitud": "14.072300",
        "longitud": "-87.192100"
      },
      "destino_especial": null,
      "presentacion_ruta": "MAPA"
    },
    {
      "orden": 2,
      "solicitud_id": "40000000-0000-0000-0000-000000000001",
      "numero_solicitud": "SOL-VIAL-1",
      "prioridad": "NORMAL",
      "modalidad": "ENTRE_SUCURSALES",
      "estado_solicitud": "ASSIGNED",
      "tipo": "ENTREGA",
      "ubicacion": {
        "id": "50000000-0000-0000-0000-000000000002",
        "nombre": "Sucursal Norte",
        "direccion": "Norte",
        "latitud": "14.082300",
        "longitud": "-87.182100"
      },
      "destino_especial": null,
      "presentacion_ruta": "MAPA"
    }
  ],
  "mapa": {
    "modo": "INTEGRADO",
    "proveedor": "GOOGLE_MAPS",
    "mostrar_mapa": true,
    "mostrar_trazado": false,
    "permite_navegacion_externa": false
  },
  "ruta_vial": {
    "estado": "NO_CONFIGURADA",
    "proveedor": "GOOGLE_MAPS",
    "atribucion": null,
    "aviso_motocicleta": "Las rutas para motocicletas están en beta y pueden omitir aceras, senderos peatonales o ciclovías. Verifica que la vía sea apta y respeta las señales.",
    "version_actual": 1,
    "version_calculada": null,
    "polilinea_codificada": null,
    "incluye_tramos_completados": false,
    "calculada_en": null,
    "expira_en": null,
    "origen_gps": null,
    "codigo_error": null,
    "reintento_desde": null,
    "metricas_en_respuesta": false,
    "distancia_estimada_metros": null,
    "duracion_estimada_segundos": null,
    "modo_visualizacion": "UN_TRAMO",
    "desglose_disponible": false,
    "requiere_actualizar_desglose": false,
    "tramo_actual_id": null,
    "tramos": []
  }
}
```

`mapa` siempre es un objeto con esos cinco campos. `modo=INTEGRADO`,
`proveedor=GOOGLE_MAPS` y `permite_navegacion_externa=false` son constantes
de esta fase; no son indicadores de que el SDK móvil ya esté configurado.
`mostrar_mapa=true` si la próxima parada tiene ubicación y presentación
`MAPA`. `mostrar_trazado=true` solamente cuando además hay un cálculo
`CALCULADA` vigente. Desde 0.34.0 el frontend nuevo dibuja solo la geometría del
tramo seleccionado en `ruta_vial.tramos`, si está disponible. La
`ruta_vial.polilinea_codificada` global permanece obsoleta por compatibilidad:
no dibujar todo el recorrido junto ni usarla como fallback sin desglose.

Si no hay paradas o la próxima es especial (`SOLO_KILOMETROS`, incluso su
recolección), ambos indicadores son `false`. Las paradas y el control de
kilometraje se conservan. Si Google no está configurado, el mapa puede
mostrar los marcadores de las ubicaciones propias una vez configurado su
SDK, pero **no hay trazado vial**: no unir los marcadores en línea recta y
presentarlo como una ruta calculada. La clave del SDK y su disponibilidad
en el dispositivo son independientes de la configuración de Routes API.

Frontend debe reemplazar el botón que abría otra app por una pantalla interna
de VitaGo. Usar las ubicaciones ya incluidas en `paradas`, destacar
`proxima_parada`, dibujar la polilínea solo cuando `mostrar_trazado=true` y
actualizar la posición del motorista con el GPS del teléfono. Eliminar el
consumo del campo retirado y cualquier lanzamiento de Google Maps externo,
incluidos accesos de navegación que pueda mostrar el propio SDK.
No usar la ausencia de mapa/trazado como motivo para salir de la app.

Mostrar el mapa **no** inicia, recoge, entrega ni finaliza solicitudes:
esas operaciones conservan sus transiciones, evidencia y confirmación.
Continúan la captura, cola persistente y envío GPS; no se recalcula la ruta
por cada punto, por mover la cámara ni por entrar de nuevo a la pantalla.
El backend no puede impedir que una versión antigua de Flutter abra un
enlace que tenga guardado: el frontend también debe actualizarse.

Esto es mapa con ruta inicial y ubicación GPS, **no Navigation SDK**:
no incluye instrucciones de voz/giro a giro, ETA en vivo ni redirección
automática. No añadir Navigation SDK ni su facturación en esta fase.

### Cálculo inicial explícito

```http
POST /api/v1/rutas/mi-ruta/calcular/
Authorization: Bearer <token_acceso>
Content-Type: application/json
```

```json
{"version_actual": 1, "reintentar": false}
```

`version_actual` es obligatorio, entero positivo tomado de `mi-ruta/`;
`reintentar` es opcional, por defecto `false`. No admite campos adicionales,
origen arbitrario, clave API, empresa o motorista enviado por Flutter. El
propietario requiere además `ruta.calcular`, concedido a los dos roles de
motorista mediante migración. No ofrece cálculo de rutas ajenas al administrador.
Desde 0.34.0, `reintentar=true` también permite actualizar explícitamente un
cálculo vigente antiguo que no contenga desglose. No se actualiza automáticamente;
respeta GPS vigente, permiso, presupuesto y máximo de intentos. Si ya contiene
tramos, repetirlo reutiliza la caché, incluso con `reintentar=true`.

Origen: GPS vigente y preciso recibido por el backend en jornada activa,
igual que los filtros de asignación. Destinos: hasta diez paradas propias,
en el orden operativo existente. Agrupa coordenadas consecutivas idénticas
para la consulta, sin borrar las paradas operativas. Al encontrar un especial
detiene el trazado: calcula solo el prefijo con mapa anterior, si existe.
Un prioritario detiene el trazado tras su entrega; si ya está recogido, va
directamente a esa entrega. Nunca ubica un destino especial en el mapa.

Usa Routes API `Compute Routes`, `TWO_WHEELER`, `TRAFFIC_AWARE`, sin rutas
alternativas ni optimización de paradas; máscara limitada a distancia,
duración y geometría. Google admite rutas de dos ruedas en
[Honduras](https://developers.google.com/maps/documentation/routes/coverage-two-wheeled?utm_campaign=gmp_git_agentskills_v1).
Si el proveedor no puede trazar, devuelve un error explícito; no sustituye
silenciosamente por una ruta para automóvil.

Respuesta `200`: **el objeto `ruta_vial`**, no el objeto completo de `mi-ruta/`:

El ejemplo siguiente conserva el núcleo compatible anterior; desde 0.34.0
también se incluyen los cinco campos de desglose definidos en la sección final.

```json
{
  "estado": "CALCULADA",
  "proveedor": "GOOGLE_MAPS",
  "atribucion": "Google Maps",
  "aviso_motocicleta": "Las rutas para motocicletas están en beta y pueden omitir aceras, senderos peatonales o ciclovías. Verifica que la vía sea apta y respeta las señales.",
  "version_actual": 1,
  "version_calculada": 1,
  "polilinea_codificada": "_p~iF~ps|U_ulLnnqC_mqNvxq`@",
  "incluye_tramos_completados": false,
  "calculada_en": "2026-10-13T15:00:00Z",
  "expira_en": "2026-10-14T15:00:00Z",
  "origen_gps": {
    "latitud": "14.072000",
    "longitud": "-87.192000",
    "registrada_en": "2026-10-13T14:59:55+00:00",
    "precision_metros": "5.00"
  },
  "codigo_error": "",
  "reintento_desde": null,
  "metricas_en_respuesta": true,
  "distancia_estimada_metros": 1800,
  "duracion_estimada_segundos": 250.5
}
```

Polilínea y métricas de este ejemplo son la **respuesta simulada del test**,
no una ruta real entre las ubicaciones ficticias. El frontend debe dibujar
geometría de Google únicamente sobre un mapa de Google, mostrar atribución
«Google Maps» junto a sus resultados y el aviso beta. Las cifras son
estimaciones de todo el trazado inicial, **no kilómetros realizados ni una
ETA en vivo a la próxima parada**. No restar tramos GPS de esa duración
para inventar una ETA; no utilizarla para informes históricos de recorrido.

### Reutilización y consumo

Repetir el POST devuelve el trazado vigente sin otra llamada. Completar
paradas reutiliza el cálculo cuando las restantes son un sufijo del itinerario
original: `version_calculada` puede ser menor que `version_actual`, y
`incluye_tramos_completados=true` advierte que la línea conserva tramos ya
terminados. El frontend no debe presentarla como posición GPS en vivo.

Agregar, reordenar, editar coordenadas o cancelar una parada intermedia puede
invalidar la reutilización: requiere otro POST **explícito** con versión vigente.
No hay cálculos automáticos al consultar, asignar, completar una parada,
desviarse de la ruta, recibir GPS o cerrar jornada. Si termina todo el
itinerario, `SIN_PARADAS`; no se consulta Google para calcular el kilometraje final.

Se reserva un intento por versión, máximo dos por defecto con reintento
explícito. Bloquea al motorista durante reserva y publicación, pero no durante
HTTP; un cálculo en curso evita duplicados concurrentes de ese motorista.
Si cambió el itinerario mientras Google respondía, descarta la respuesta.
Los límites por base/despliegue son 50 intentos diarios y 500 mensuales:
incluyen fallos/timeouts y se reservan transaccionalmente, sin devolver cuotas
cuando no sabemos si el proveedor facturó. El cambio de día/mes utiliza la
zona horaria del backend. **No equivalen a una garantía de costo cero**:
otras apps/bases pueden compartir el proyecto de Cloud. Configurar también
cuotas del proveedor; una alerta de presupuesto de Cloud no corta el gasto.

### Persistencia y caducidad

El backend no guarda distancia/duración de Google ni cuerpos crudos.
`metricas_en_respuesta=true` solo en la respuesta de un cálculo nuevo exitoso;
en GET o POST reutilizado será `false` y ambas métricas serán `null`.
Mostrar estimaciones solo mientras se usa esa respuesta, sin caché persistente
de métricas en la app. No repetir POST para intentar recuperar las métricas.

Desde 0.34.0 también guarda temporalmente las polilíneas individuales de los
legs, sin sus métricas. Comparten la caducidad del cálculo; la tarea existente
borra la línea global y todas las líneas por tramo al vencer, incluso si la
global ya estaba vacía. La auditoría y los contadores no se eliminan.

Guarda temporalmente solo coordenadas de la línea codificada, con caducidad
de visualización de 24 horas (configurable de 1 a 24). Interpretamos esa
geometría como coordenadas latitud/longitud bajo la excepción de caché
[Routes API, sección 19.3](https://cloud.google.com/maps-platform/terms/maps-service-terms?utm_campaign=gmp_git_agentskills_v1);
no extiende esa excepción a otros campos. Revalidar los términos de la cuenta
antes de activar, especialmente si su dirección de facturación es europea.
El cálculo vencido no se devuelve ni se recalcula en la misma versión.
El historial propio de paradas, GPS de origen y contadores de intentos permanece.

Antes de habilitar Google, programar al menos diariamente (preferible cada
hora) en **cada despliegue**:

```powershell
.\.venv\Scripts\python.exe manage.py limpiar_rutas_google_vencidas
```

El comando manual carga el entorno de su servidor. Elimina solo geometría
vencida, conservando auditoría y datos propios; no borra solicitudes ni GPS.
El POST también limpia geometría vencida. Desde **2026-10-22**, Corporate local
tiene instalada `VitaGo-Corporate-LimpiezaGoogle`, cada hora y al iniciar sesión,
con configuración aislada de Corporate y registro propio. Requiere computadora
encendida y sesión iniciada; recupera limpieza al volver. Network no se habilitó
ni recibió tareas nuevas. Otros despliegues requieren su propia programación.
Respaldos/exportaciones no deben conservar contenido de Google fuera del plazo
permitido; excluir esas geometrías o controlar su caducidad.

### Estados y errores exactos

`ruta_vial.estado`: `SIN_PARADAS`, `SOLO_KILOMETROS`, `NO_CONFIGURADA`,
`PENDIENTE`, `CALCULANDO`, `CALCULADA`, `FALLIDA`, `VENCIDA`,
`ITINERARIO_CAMBIO`. Un intento interrumpido durante más de 60 segundos se
presenta como `FALLIDA`, `codigo_error=INTENTO_INTERRUPPIDO` sin escrituras
en GET. Recuperarlo consume otro intento y requiere `reintentar=true`.

Errores de entrada `400` conservan nombres `version_actual`, `reintentar` o
el campo desconocido. Errores operativos del POST:

```json
{"codigo": "GPS_NO_VIGENTE", "detail": "Inicia la jornada y envía una posición GPS reciente y precisa antes de calcular."}
```

| HTTP | `codigo` | Acción del frontend |
|---|---|---|
| 409 | `VERSION_DESACTUALIZADA` / `ITINERARIO_CAMBIO` | Actualizar GET; no reintentar de forma automática. |
| 409 | `GPS_NO_VIGENTE` | Iniciar jornada y enviar GPS reciente/preciso. |
| 409 | `DIA_OPERATIVO_FINALIZADO` | No calcular/reutilizar rutas del día anterior. Actualizar operación y esperar su cierre; iniciar la nueva jornada cuando corresponda. No retry automático. |
| 409 | `SIN_PARADAS_CARTOGRAFIABLES` | Sin mapa; continuar flujo operativo o especial. |
| 409 | `CALCULO_EN_CURSO` | Consultar GET; no duplicar POST. |
| 409 | `REINTENTO_EXPLICITO_REQUERIDO` | Consultar `reintento_desde` y ofrecer reintento explícito. |
| 409 | `LIMITE_INTENTOS` / `FALLA_NO_REINTENTABLE` / `RUTA_VENCIDA` | No seguir intentando la misma versión; mantener mapa interno con marcadores propios, sin trazado vencido ni salida a otra app. |
| 409 | `INTENTO_REEMPLAZADO` | Consultar estado actual. |
| 429 | `LIMITE_CONSUMO` / `ESPERAR_REINTENTO` | No repetir hasta nuevo período o fecha permitida. |
| 503 | `GOOGLE_NO_CONFIGURADO` | No llamar de nuevo; informar que el trazado no está disponible y conservar el flujo dentro de VitaGo. |
| 503 | `CONEXION_GOOGLE` / `CUOTA_GOOGLE` / `FALLA_GOOGLE` | GET para consultar si hay fecha de reintento; no retry automático. |
| 503 | `CONFIGURACION_GOOGLE` / `SIN_RUTA` / `RESPUESTA_INVALIDA` / `COORDENADAS_INVALIDAS` / `PARADAS_INVALIDAS` | No retry automático; revisar configuración/itinerario. |

`401` sin sesión; `403` sin permiso; `404` sin motorista propio activo.
Solo fallos transitorios (`CONEXION_GOOGLE`, `CUOTA_GOOGLE` o error HTTP 5xx)
habilitan reintento tras 30 segundos en el primer fallo, o 60 en el segundo.
El límite de intentos se verifica igualmente. No devolver mensajes upstream,
claves API ni coordenadas en logs. Un fallo de proveedor no debe convertirse
en «no se pudo conectar con VitaGo» si Django sí respondió HTTP.

### Configuración y tareas del frontend

Variables en las plantillas `.env.example` y `.env.corporativo.example`:
`CLAVE_API_GOOGLE_MAPS`, `HABILITAR_RUTAS_GOOGLE=false`,
`RUTAS_GOOGLE_TIMEOUT_SEGUNDOS=5` (timeout de red, máximo 10),
`RUTAS_GOOGLE_LIMITE_DIARIO=50`, `RUTAS_GOOGLE_LIMITE_MENSUAL=500`,
`RUTAS_GOOGLE_INTENTOS_POR_VERSION=2`, `RUTAS_GOOGLE_CACHE_HORAS=24`.
El máximo de intentos por versión admite solamente 1 o 2.
La clave y bandera de Corporate deben sobrescribirse en `.env.corporativo`
para no heredarlas accidentalmente de Network. No compartir claves en chat
ni incluirlas en Flutter, respuestas o Git. Activar solo Routes API con
una clave de backend restringida por API e IP pública de salida; una clave
móvil para el mapa integrado será distinta y restringida por paquete/firma.
Para Android habilitar Maps SDK for Android en el proyecto correspondiente;
si se habilita iOS, Maps SDK for iOS con otra restricción por identificador
de paquete. Usar el paquete Google Maps para Flutter en la pantalla interna,
no un enlace ni una página de Maps incrustada como sustituto del SDK.
La configuración del SDK, sus avisos legales y controles pertenece al frontend;
este cambio no modifica archivos móviles ni entrega la clave del servidor.
Revisar el costo del mapa por separado del presupuesto de Routes API: los
contadores del backend no contabilizan cargas del SDK móvil.

Antes del piloto, la app debe obtener consentimiento explícito y revocable
para ubicación/segundo plano, mostrar su uso y actualizar sus términos y
privacidad para integrar Google Maps. Google recibe solo coordenadas:
no enviar pacientes, nombres de usuario, artículos, documentos, evidencias
ni datos clínicos. Esta función es logística normal, no navegación de
emergencias ni un sistema crítico. Revisar requisitos de la cuenta/región
antes de activación: la revisión técnica no sustituye asesoría legal.

La [Maps Demo Key](https://mapsplatform.google.com/maps-demo-key?utm_campaign=gmp_git_agentskills_v1)
permite prototipos sin proyecto/facturación propios: iniciar sesión con Google,
aceptar términos del proyecto demo y generar clave. Guardarla localmente en
la variable indicada; tiene límites diarios, no sirve para producción ni
garantiza acceso a todos los parámetros. Para producción revisar facturación,
cuotas, [restricciones de claves](https://docs.cloud.google.com/api-keys/docs/add-restrictions-api-keys)
y [términos](https://cloud.google.com/maps-platform/terms?utm_campaign=gmp_git_agentskills_v1).

Frontend debe consumir `mapa` y `ruta_vial`, mostrar la pantalla interna,
estado/atribución/aviso beta, iniciar cálculo solo cuando se habilite y se
solicite explícitamente, y mantener GPS/cola al apagar pantalla.
No se modificó código frontend. El contrato del mapa integrado está listo;
ETA en vivo, compatibilidad vial en asignación, optimización de orden,
Navigation SDK, Roads API y recálculos automáticos siguen fuera de esta fase.

### Verificación y retiro del flujo anterior

Se eliminó `apps/rutas/navegacion.py`, su importación, el campo público y
las instrucciones operativas de enlaces externos. El retiro es deliberado:
un cliente que requiera `navegacion` debe actualizarse al contrato 0.28.0.
Las entradas de 0.27.0 en el historial documentan la evolución; no son una
instrucción vigente para abrir otra app. Los enlaces de notificaciones a
`/solicitudes/{id}` pertenecen a VitaGo y se conservan.

Sin cambios de esquema, credenciales, puertos, firewall o autenticación.
Sin activación ni consultas pagadas de Google. Pruebas: respuesta normal,
sin paradas, especial, trazado vigente/vencido, Corporate/Network y ausencia
de URLs externas. Queda pendiente la implementación y prueba visual móvil.

## Correcciones de integridad operativa (0.28.1)

### Protección del superadministrador

Los administradores de empresa ya no pueden administrar una cuenta que tenga
`es_superusuario=true` o un rol `SUPERADMINISTRADOR` activo, aunque pertenezca
a su misma empresa. Solo un superusuario o superadministrador autorizado en
ese contexto puede hacerlo. Se conserva el control de alcance y las reglas
existentes del gerente de operaciones.

La protección se aplica a actualización de perfil/estado, restablecimiento
de contraseña y asignación/revocación de roles. Un intento no permitido
responde `403` con `detail`, sin cambiar contraseña, datos ni sesiones del
usuario objetivo. Los administradores mantienen la gestión de sus usuarios
operativos dentro del alcance autorizado.

### Jornada obligatoria para operar

`POST /api/v1/solicitudes/{solicitud_id}/transiciones/` requiere una jornada
`ACTIVA` del motorista para todas las transiciones operativas: desplazamiento,
llegada, recolección, tránsito, entrega y fallos. Se aplica en ambos despliegues,
a normales, prioritarios y especiales; una jornada finalizada no habilita
operación. Requiere además los permisos, propiedad, evidencias y demás reglas
ya documentadas. El backend bloquea al motorista y la jornada durante la
validación/transición para coordinarlo con el cierre de jornada.

Si falta jornada activa, responde `400`:

```json
{"jornada": "Debe iniciar una jornada antes de operar la solicitud."}
```

No se cambia el estado de solicitud, asignación o motorista ni se registra
un evento parcial. El frontend debe ofrecer iniciar jornada y después
permitir reintentar la acción; no interpretar este `400` como fallo de conexión.
La asignación manual antes de iniciar jornada sigue permitida: lo que no
puede comenzar es la operación. La cancelación administrativa conserva su
permiso y no exige una jornada al administrador ni al motorista.

**Excepción importante:** confirmar GPS tardío mediante los endpoints
`/jornadas/{id}/sincronizacion-gps/` y
`/solicitudes/{id}/sincronizacion-gps/` sigue permitido después del cierre
operativo de la jornada. No son transiciones nuevas de entrega; conservan
sus permisos, propiedad, idempotencia e inmutabilidad de cierres consolidados.
No se crean jornadas retrospectivas ni se recalculan históricos.

Para datos antiguos con servicios iniciados sin jornada, revisar el estado
del motorista e iniciar una jornada válida antes de continuar. Si figura
`ON_ROUTE` sin jornada, regularizar primero su disponibilidad con el flujo
operativo autorizado. No simular fechas de inicio ni alterar evidencias.

### Confirmación GPS de envíos especiales en PostgreSQL

Se corrigió el alcance del bloqueo de la solicitud al consultar una sucursal
nullable: se bloquea únicamente la solicitud, no el lado nullable del JOIN.
La consulta ya no provoca el error PostgreSQL `FOR UPDATE no puede ser
aplicado al lado nulable de un outer join`. El contrato no cambia:
`POST /api/v1/solicitudes/{solicitud_id}/sincronizacion-gps/` devuelve el
movimiento especial con su calidad, y acepta una confirmación idéntica sin
crear revisiones duplicadas. Otro usuario no puede confirmar ese movimiento.

### Validación real de fotografías

Se conserva el formato multipart y los campos existentes de evidencias de
solicitud e incidencias. JPEG, PNG y WebP deben ser fotografías estáticas
legibles: el backend comprueba formato real, estructura y decodificación
completa. No basta la cabecera ni la extensión. El tipo MIME declarado debe
coincidir con el formato detectado.

Se rechazan archivos corruptos, truncados, animaciones y dimensiones excesivas.
El límite de archivo sigue siendo `TAMANO_MAXIMO_EVIDENCIA_MB` (10 MB por
defecto). Se añade `PIXELES_MAXIMOS_EVIDENCIA=40000000` (40 megapíxeles),
configurable por despliegue y documentado en ambas plantillas de entorno.
Se mantienen también las protecciones de descompresión de Pillow.

Un rechazo responde `400` asociado a `archivo`, por ejemplo:

```json
{"archivo": "La imagen está dañada, incompleta o no es una fotografía válida."}
```

Frontend debe mostrar ese mensaje y permitir volver a capturar la foto o
reducir su resolución si supera el límite. No repetir indefinidamente el
mismo archivo inválido. Un rechazo no registra evidencia y no satisface el
requisito de foto para recoger/entregar. Los originales válidos se conservan
sin recodificarlos ni modificarlos. No se revisan, borran ni reemplazan
automáticamente evidencias históricas.

### Despliegue y verificación

Nueva dependencia de backend: `Pillow==12.3.0`, incluida en
`requirements/base.txt` e instalada en el entorno virtual local. En otro
entorno instalar las dependencias antes de iniciar/reiniciar el backend:

```powershell
.\.venv\Scripts\python.exe -m pip install -r requirements/base.txt
```

Sin migraciones nuevas, cambios de conexión, credenciales, puertos ni código
frontend. Suite aislada: 287 pruebas aprobadas. Se comprobó con `EXPLAIN`
en PostgreSQL local que el bloqueo corregido es válido, sin ejecutar la
operación ni alterar registros reales. La suite usa SQLite temporal; esto
no equivale a una prueba de concurrencia completa bajo carga en PostgreSQL.

## Disponibilidad e inmutabilidad del GPS especial (0.28.2)

### Cierre de solicitudes y estado del motorista

Al cancelar, fallar la recolección, fallar la entrega o completar una entrega,
se cierra la asignación y se recalcula la capacidad, pero nunca se levanta
automáticamente `PAUSED`, `OFFLINE` ni `OUT_OF_SERVICE`, aunque queden otras
solicitudes activas. Esos estados continúan excluidos de nuevas asignaciones.
Para reanudar se utiliza el flujo autorizado de cambio de estado operativo.
El cierre no cambia los permisos, evidencias ni la exigencia de jornada activa.

Para motoristas que estaban `AVAILABLE` u `ON_ROUTE`, se conserva el flujo
automático: `ON_ROUTE` si mantienen asignaciones activas; `AVAILABLE` si ya
no tienen ninguna. La capacidad se recalcula también en motoristas pausados
o desconectados: disponibilidad y cupo siguen siendo conceptos distintos.

No cambia el JSON de `/solicitudes/{id}/transiciones/` ni de repartidores.
Aplica al servicio compartido por Corporate y Network.

### GPS después de confirmar un envío especial

`calidad_kilometraje.sincronizacion_verificada=true` confirma el manifiesto
de TODOS los puntos de la jornada hasta `finalizada_en` del especial,
incluidos los anteriores al inicio del movimiento. Desde entonces:

- Se permiten reintentos idénticos: mismo `id_cliente` y mismos datos.
- No se permiten puntos nuevos con `registrada_en` anterior o igual a ese
  cierre. Se conserva la medición, manifiesto y revisión ya confirmados.
- Los puntos posteriores se aceptan normalmente; pueden continuar la misma
  sesión con la siguiente secuencia o iniciar otra sesión GPS.
- Sincronizaciones pendientes siguen aceptando los puntos faltantes; cuando
  se verifican automáticamente, se aplica la misma protección.
- Una calidad `INCOMPLETO` o `SIN_DATOS` también es inmutable si su
  sincronización está verificada. Calidad de señal no equivale a recepción
  pendiente. Los históricos con calidad vacía no se recalculan.

`POST /api/v1/seguimiento/registros/` responde `400` ante un punto nuevo que
contradiga ese prefijo, indicando índice (desde cero) y campo. Por ejemplo,
si el segundo elemento del lote es el conflictivo:

```json
{
  "registros": {
    "1": {
      "registrada_en": "La fecha pertenece al prefijo GPS de un envío especial ya consolidado; solo admite reintentos idénticos."
    }
  }
}
```

El lote se rechaza completo: no se guardan parcialmente sus otros puntos.
No presentar este error como conexión fallida ni reintentar indefinidamente
el mismo lote. Revisar la discrepancia de cola/manifiesto sin modificar el
GPS original ni dar puntos no aceptados por sincronizados. El frontend debe
declarar al cerrar la última secuencia GENERADA, no solo la última enviada,
y confirmar cuando el backend haya recibido los puntos correspondientes.
Los lotes válidos mantienen su respuesta `201` y los contadores existentes.

Sin endpoints, dependencias ni migraciones nuevas. No se modifica código
frontend, conexiones, puertos, credenciales ni datos históricos. Suite
aislada: 293 pruebas aprobadas, incluidas 40 combinaciones de cierre/estado/
otras asignaciones y validaciones GPS de límites, reintentos y atomicidad.
Las pruebas usan SQLite temporal; no sustituyen una prueba concurrente de
carga en PostgreSQL ni pruebas de campo desde el teléfono.

## Contingencias y cierre diario corporativo (0.29.0)

### Alcance y autorización

Estas reglas pertenecen exclusivamente a **Corporate/Analiza**. Network
mantiene su política operativa; comparte el esquema de las migraciones, no
los datos ni esta automatización. No cambia login, permisos administrativos,
credenciales, IP, puertos, Google ni código frontend.

`PATCH /api/v1/usuarios/{usuario_id}/` conserva su contrato. Si cambia al
motorista de activo a `SUSPENDIDO` o `INACTIVO`, revoca sesiones y, después
del commit, procesa sus solicitudes activas. Si la transacción se revierte,
no se retiran servicios. Un fallo posterior queda registrado y la tarea local
puede recuperar los servicios aún ligados a usuarios suspendidos/inactivos.
No confundir suspender una **cuenta** con poner al motorista en `PAUSED` o
`OUT_OF_SERVICE`: cambiar disponibilidad no transfiere automáticamente paquetes.

### Reasignación por suspensión

Se cierra la asignación anterior como `REASIGNADA`, conservando motorista,
fechas, evidencias, eventos y GPS. El perfil retirado queda `OUT_OF_SERVICE`
y su cupo se recalcula. Se buscan reemplazos de la misma empresa por GPS
vigente, estado operativo, motocicleta, rol, prioridad y límite de cinco.
La selección y asignación conservan transacciones y bloqueo del motorista.

- Si no se había recogido: vuelve a `PENDING` mientras se busca reemplazo y
  pasa a `ASSIGNED` cuando se encuentra; el nuevo motorista recoge normalmente.
- Si estaba `PICKED_UP`, `IN_TRANSIT` o `AT_DESTINATION`: conserva esa fase,
  `recolectada_en` y las evidencias originales. La nueva asignación comienza
  un intervalo operativo propio y su ruta incluye entrega, **no recolección**.
  Se requiere jornada activa del reemplazo para continuar una entrega.
- El traspaso físico se coordina fuera de VitaGo por decisión operativa;
  la reasignación digital no certifica que el paquete cambió de manos. Se
  registra `traspaso_fisico_fuera_app=true` en los metadatos del evento.
- La foto de entrega debe pertenecer al nuevo motorista; no basta reutilizar
  una evidencia de otro. El resto de validaciones de transición sigue vigente.

Si no hay candidato, `repartidor_asignado_id=null` y
`reasignacion_pendiente=true`. La fase recogida **no se degrada a PENDING**.
Se notifica al solicitante, administrador que suspendió y motorista retirado
(sin duplicar si coinciden). Al encontrar reemplazo se le notifica solo a él;
no se envía una oferta para aceptar/rechazar a todos los motoristas.

Los reintentos ocurren con los eventos de disponibilidad/GPS/cupo ya existentes.
Examinan hasta 50 pendientes por evento y asignan como máximo cinco. Dan
precedencia a contingencias y mantienen antigüedad dentro de cada grupo;
una contingencia sin candidato no bloquea las siguientes dentro de ese lote.
También se admite seleccionar manualmente un reemplazo mediante
`POST /api/v1/solicitudes/{id}/asignaciones/`, con los permisos existentes.
Cancelar una contingencia anterior a la recolección elimina su marca pendiente:
nunca se reactiva un servicio cancelado por un reintento posterior.

### Campos nuevos de solicitud

Listado, resumen y detalle añaden campos compatibles:

```json
{
  "id": "70000000-0000-4000-8000-000000000001",
  "estado": "PICKED_UP",
  "repartidor_asignado_id": null,
  "reasignacion_pendiente": true,
  "cerrada_en": null,
  "motivo_cierre": ""
}
```

Este JSON es un fragmento de los campos afectados, no una respuesta completa.
El frontend debe permitir motorista nulo incluso en una fase recogida y mostrar
«Pendiente de reasignación», conservando el estado real. Una suspensión no
cierra la solicitud: `cerrada_en` continúa nulo. Los terminales generados desde
esta versión registran `cerrada_en`; los históricos pueden conservarlo nulo.
`motivo_cierre=FIN_DIA` identifica el vencimiento automático; vacío mantiene
el flujo normal. No añadir por cuenta propia un estado HTTP `NO_ENTREGADO`.

### Especiales: tramos y kilómetros por motorista

La solicitud puede tener varios movimientos especiales, con como máximo un
tramo activo. Cada tramo conserva motorista, jornada, inicio, fin, kilómetros,
calidad y revisiones propios. El tramo anterior se finaliza con
`motivo_cierre=SUSPENSION`; el siguiente empieza con la ubicación GPS vigente
del reemplazo y requiere dedicación exclusiva (sin otras solicitudes activas).
No se copia la ubicación del anterior ni se inventa una ubicación de cierre.
El tramo automático puede tener `latitud_fin` y `longitud_fin` nulos.

El detalle conserva `movimiento_especial` para compatibilidad: ahora es el
**último tramo**, o null. Añade `movimientos_especiales`, lista de tramos con
el mismo formato de `SerializadorMovimientoEnvioEspecial`, ordenada por inicio
descendente. Cada elemento añade `motivo_cierre` (vacío, `SUSPENSION` o
`FIN_DIA`). `kilometros_envio_especial` es nulo mientras haya un tramo activo;
cuando todos finalizaron, es la suma de sus kilómetros, sin duplicarlos.
La calidad puede seguir pendiente: revisar todos los tramos, no solo el último.

La jornada de cada motorista suma exclusivamente sus tramos e intervalos.
Las recolecciones/entregas se atribuyen al responsable en el momento del evento,
no al último motorista asignado. Una reasignación no transfiere kilómetros ni
recolecciones históricas a la jornada del reemplazo.

`POST /api/v1/solicitudes/{id}/sincronizacion-gps/` añade un campo opcional:

```json
{
  "movimiento_id": "80000000-0000-4000-8000-000000000001",
  "sesiones_gps": []
}
```

El cuerpo continúa admitiendo el formato anterior si el usuario tiene un solo
tramo finalizado de esa solicitud. Si tiene varios, `400` asociado a
`movimiento_id` exige elegir uno. Un motorista activo autorizado puede confirmar
su tramo anterior aunque ya no sea el asignado actual; nunca puede confirmar
el tramo de otro. Una cuenta suspendida sigue sin acceso hasta su reactivación.
Conservar el UUID del tramo en la cola móvil. Los cierres verificados siguen
siendo inmutables y admiten únicamente reintentos idénticos de su prefijo GPS.

### Cierre a medianoche

Se usa `empresa.pais.zona_horaria_predeterminada` (Analiza: Honduras), no la
fecha UTC ni el reloj del teléfono. El vencimiento de una solicitud es la
medianoche siguiente a su fecha de creación local. Una jornada termina en
la medianoche siguiente a su inicio local. No se extienden al día siguiente.

Al corte, las solicitudes que no se completaron pasan a:

| Situación | Estado API | Etiqueta sugerida |
|---|---|---|
| PENDING/ASSIGNED/GOING_TO_PICKUP/AT_PICKUP | PICKUP_FAILED | Recolección no realizada |
| PICKED_UP/IN_TRANSIT/AT_DESTINATION | DELIVERY_FAILED | No entregado |

Se registra `motivo_cierre=FIN_DIA`, `cerrada_en` con la medianoche efectiva y
un evento `CIERRE_AUTOMATICO`. El evento distingue hora efectiva de cierre y
hora real de ejecución. Se cierran asignaciones y tramos especiales, se libera
cupo y se cierran jornada/ruta vencidas cuando no quedan asignaciones activas.
El motorista queda `OFFLINE` y deberá iniciar una jornada nueva para operar.
No se simulan una entrega, evidencia, destinatario ni coordenadas finales.

Desde el corte ya no se permite asignar, operar o adjuntar nuevas evidencias
a una solicitud vencida, aunque la tarea todavía no haya corrido: responde
`400` con campo `solicitud`. El GPS tampoco puede cruzar el límite de la jornada;
el error identifica `registros`, índice y `registrada_en`. La cola GPS capturada
antes del corte puede sincronizarse después según sus permisos y manifiestos.
Un cierre sin manifiesto queda `SIN_VERIFICAR`, no falsamente consolidado.

Los terminales anteriores no se reabren ni recalculan. La tarea es idempotente:
ejecutarla nuevamente no duplica eventos, notificaciones, asignaciones ni cierres.
Si un registro falla, continúa con los demás, deja el error en el log y devuelve
salida de error para que se revise; lo pendiente se recupera en otro intento.
Las tareas del día vigente no se bloquean innecesariamente para el cierre.

### Notificaciones y presentación móvil

Se conservan los endpoints, paginación y payload de notificaciones existentes.
El catálogo añade `REASIGNACION_PENDIENTE` y `SERVICIO_NO_ENTREGADO`; la
reasignación efectiva utiliza `SOLICITUD_REASIGNADA` o `SOLICITUD_PRIORITARIA`.
Los enlaces siguen apuntando a `/solicitudes/{id}` y al esquema Corporate.
No hay notificación push en esta fase. El frontend debe tolerar tipos nuevos,
mostrar el motivo de fin del día y actualizar la ruta tras la reasignación.
Los eventos nuevos son `REASIGNACION_PENDIENTE` y `CIERRE_AUTOMATICO`.
Los cambios operativos del sistema pueden mostrar `realizado_por_id=null`.

### Migraciones, tarea local y verificación

Migraciones aplicadas de forma independiente en las dos bases locales:

- `repartidores.0003_contingencias_y_cierre_diario`: autor nullable en historial
  para operaciones del sistema, sin atribuirlas falsamente a una persona.
- `solicitudes.0007_contingencias_y_cierre_diario`: marca de reasignación,
  fecha/motivo de cierre, eventos, varios tramos por solicitud y unicidad del
  tramo activo. GPS final nulo solo se admite para interrupciones autorizadas.
- `notificaciones.0002_contingencias_y_cierre_diario`: catálogo ampliado.

Se conservan filas, UUID, evidencias, GPS e historial. No es seguro volver a
0.28.x después de crear varios tramos sin planificar la compatibilidad: la
versión anterior suponía uno solo. No ejecutar una reversión destructiva.

Comando manual que **sí modifica operaciones vencidas**:

```powershell
.\.venv\Scripts\python.exe manage.py cerrar_operaciones_vencidas --settings=config.settings.tarea_corporativa --confirmar-corporativo
```

Devuelve conteos `solicitudes_cerradas`, `servicios_retirados` y
`jornadas_cerradas`; si hubo fallos añade `errores` y termina con error.
La configuración de tarea carga `.env.corporativo`, exige entorno local y
Corporate y registra resultados en `logs/contingencias_corporativo.log`, con
rotación. No cambia los archivos `.env` ni arranque de los servidores.

`scripts/registrar_cierre_corporativo.ps1` fue ejecutado con autorización el
**2026-10-17**: la tarea de Windows ya está registrada y habilitada. No volver
a registrarla ni sobrescribirla. Para otras instalaciones, su registro requiere
autorización porque cambia el Programador de tareas. El comando es:

```powershell
.\scripts\registrar_cierre_corporativo.ps1 -Confirmar
```

La tarea se llama `VitaGo-Corporate-CierreDiario`, corre cada minuto
y al iniciar sesión en Windows, sin ventana, con el usuario local y sin servidor
adicional ni contraseña guardada por este script. No sobrescribe otra tarea
existente. La hora efectiva siempre es medianoche; la ejecución puede ocurrir
hasta aproximadamente un minuto después. Si la PC está apagada, dormida o
sin sesión, no puede correr: recupera los cierres al volver a iniciar sesión.
Para producción o ejecución sin sesión se requiere otra configuración operativa.

Verificación: **321 pruebas aisladas aprobadas**, 28 casos nuevos de contingencia,
sin cambios de modelos pendientes ni dependencias nuevas. Migraciones exitosas
en ambos PostgreSQL locales; sintaxis y configuración de tarea verificadas.
El 2026-10-17, tras autorizar el registro, la primera ejecución automática
cerró una solicitud y una jornada vencidas (no eliminó registros). Su salida
inicial falló por stdout inexistente en pythonw: se corrigió sin cambiar la
operación, con dos pruebas nuevas para ejecución sin consola y fallos reales.
Suite actual: **323 pruebas aprobadas**. No se forzó otra pasada manual ni
se hizo simulación concurrente de carga o cambios de conexión/frontend.
En esta fase quedaron pendientes los hallazgos sobre fecha futura de fotos y
limitación de intentos; se atendieron después en 0.30.0 y 0.30.1 respectivamente.

## Reutilización de operación del motorista (0.29.2)

Primera fase de limpieza interna, sin modificaciones requeridas en Flutter.
`apps/repartidores/operacion.py` centraliza el guardado de estado/capacidad
y la creación de `HistorialEstadoRepartidor`, reutilizados por jornadas,
solicitudes, contingencias y actualización operativa de repartidores.

- La capacidad sigue derivándose exclusivamente de las solicitudes activas.
- La función de sincronización de capacidad conserva su nombre, firma y retorno
  de cantidad; ahora delega en el servicio común y no levanta una pausa.
- La API de actualización conserva permisos, validación de motocicleta,
  prohibición de capacidad manual y error de cambios no efectivos.
- Se mantienen autor (incluido sistema con autor nulo), motivos y orden de
  registros de auditoría. No se fusionan eventos de operaciones diferentes.
- Sin cambios efectivos no se guarda ni actualiza fecha ni duplica historial;
  con cambios solo se actualizan las columnas afectadas y `actualizado_en`.
- Cada llamador conserva la transacción y bloqueo del motorista; el servicio
  común exige transacción y no concede permisos ni decide reasignaciones.
- No se modifica el cierre diario, la tarea de Windows, las políticas por
  despliegue, el formato de errores ni las respuestas de la API.

Verificación: **333 pruebas aisladas aprobadas**, incluidas 10 nuevas sobre
guardado común, conteo de carga, auditoría, pausa, autor del sistema, rollback,
ausencia de cambios, campos actualizados y contrato transaccional. Sin modelos
o migraciones nuevas. No se ejecutaron operaciones de prueba en datos reales.
Esta primera fase no refactorizó los cierres; ese bloque se centraliza en
0.29.3. Almacenamiento de evidencias y notificaciones siguen pendientes de
su propia revisión.

## Reutilización del cierre de jornadas (0.29.3)

Segunda fase interna, **sin cambios requeridos en el frontend**.
`registrar_cierre_jornada`, en `apps/jornadas/servicios.py`, centraliza:

- guardado del resumen y estado final de la jornada;
- consolidación GPS y su revisión auditable;
- desconexión y capacidad derivada del motorista con historial;
- cierre de la ruta vigente.

Los casos de uso conservan sus permisos, propiedad, validaciones, transacción
y bloqueos de motorista/jornada. El servicio común exige una transacción;
no decide si un cierre está autorizado ni elimina las comprobaciones previas.

El cierre manual conserva coordenadas opcionales, autor motorista y motivo
`CIERRE`. Omitir `sesiones_gps` sigue dejando la sincronización sin verificar;
enviar `[]` declara que no se capturaron sesiones, con su validación existente.
El automático sigue siendo exclusivo de Corporate: usa medianoche local,
`FIN_DIA`, autor nulo y fecha efectiva de corte para jornada y ruta, sin
fabricar coordenadas ni manifiestos. No cierra mientras existan asignaciones
activas ni duplica el cierre de una jornada ya finalizada.

Un fallo tardío al cerrar la ruta revierte también jornada, revisión e historial
en ambos flujos. No cambia ningún endpoint, JSON, permiso ni código HTTP;
tampoco modelos, migraciones, conexiones o programación de la tarea Windows.
No se forzaron cierres manuales sobre las bases de desarrollo.

Verificación: **342 pruebas aisladas aprobadas**, en orden normal y mezclado
(semilla 2917), incluidas nueve nuevas para este bloque. Se corrigió únicamente
el montaje de un escenario de prueba de cercanía GPS que podía depender de
fechas coincidentes y UUID aleatorios; no cambió la lógica GPS de producción.
La suite usa SQLite temporal; no se simuló concurrencia real en PostgreSQL.

## Conteo de entregas al cerrar jornadas (0.29.4)

El flujo normal de entrega registra `entregada_en` de la solicitud y
`finalizada_en` de la asignación con el mismo instante. El resumen anterior
exigía que la asignación terminara después de la entrega y podía informar
cero entregas pese a un servicio terminado correctamente.

La consulta incluye ahora esa igualdad **solo para la entrega y una asignación
`FINALIZADA`**. No cambia el límite de atribución de recolecciones y no otorga
por igualdad la entrega a una asignación `CANCELADA` o `REASIGNADA`. Se conserva
la atribución al motorista que realizó cada evento y el respaldo para registros
históricos sin asignaciones. No se duplican solicitudes al sumar el historial.

Los cierres nuevos, tanto manuales como automáticos, usan el resumen corregido:
`servicios_completados`, `entregas_completadas`, `servicios_normales` y
`servicios_prioritarios`. No cambia ningún endpoint, JSON, permiso, estado ni
código HTTP. No requiere cambios en Flutter, migraciones, cambios de conexión
ni tareas nuevas. **No se recalculan los resúmenes históricos ya guardados.**

Verificación: **344 pruebas aisladas aprobadas** (semilla 2920), con dos pruebas
nuevas de coincidencia exacta y atribución, y ampliación del flujo existente de
recolección/fotos/entrega para comprobar también el resumen final. Las tres
regresiones fallaban antes del ajuste y pasan después.
Además se ejecutó una prueba HTTP temporal de principio a fin: GPS, asignación
automática, ambas fotos obligatorias, entrega, cupo libre, ruta sin paradas y
cierre con manifiesto GPS. Los puntos fuera del intervalo operativo no suman
kilómetros; se usan datos sintéticos, base SQLite y almacenamiento temporales.
No equivale a una prueba de recorrido físico ni de concurrencia PostgreSQL.

## Reloj oficial y compensación de evidencias (0.30.0)

### Fechas oficiales: el servidor es la autoridad

Inicio/cierre de jornada, duración de trabajo, asignaciones, transiciones,
entregas y vencimiento de día operativo usan el reloj del servidor. No se
acepta que el teléfono elija esas fechas. Las pruebas verifican también que
enviar `iniciada_en`/`finalizada_en` manipuladas no altera las fechas de jornada.

Ahora se aplica esa autoridad también a:

- `POST /solicitudes/{id}/evidencias/`: `capturada_en` se fija en el servidor.
- `POST /incidencias/`: `reportada_en` se fija en el servidor.
- `POST /incidencias/{id}/evidencias/`: `capturada_en` se fija en el servidor.

Las rutas son relativas a `/api/v1/`. Esos campos son **solo lectura**: dejar
de enviarlos. Si un cliente anterior los incluye, incluso con fecha futura,
antigua o inválida, se ignoran. No se rechaza por el reloj del teléfono ni se
guarda su fecha. La protección está también en servicios, no solo serializers.
Las respuestas conservan los mismos nombres y formato ISO 8601 con zona.

Por compatibilidad se mantiene el nombre `capturada_en`, pero en registros
nuevos significa **hora de registro/aceptación en el servidor**, no hora física
verificada de la fotografía. Mostrar «Registrada»; si llegó sin conexión, la
hora oficial será la del envío aceptado, no la que declare el móvil. No cambia
el estado permitido para subir una foto ni elimina comprobaciones de autor,
empresa, solicitud, vencimiento o cierre de incidencia. El historial no se
reescribe. Desde0.36.0 una foto operativa válida sí completa su etapa de forma
atómica, sin otra confirmación; las fotos de incidencias no lo hacen.

El reporte de incidencia se atribuye a la asignación válida al registrarlo.
No se permite elegir una fecha antigua para asociarlo a una asignación ya
terminada ni usar una jornada Corporate cuyo día operativo venció. Network
no adquiere el cierre diario corporativo. Una incidencia abierta puede recibir
fotos después de cerrar la jornada; no se permite después de cerrar la incidencia.

### GPS: referencia del servidor sin destruir las capturas offline

`GET /seguimiento/configuracion/` conserva autenticación y permiso existentes
y añade estos campos, calculados por el servidor:

```json
{
  "hora_servidor": "2026-10-20T18:00:00+00:00",
  "zona_horaria_operativa": "America/Tegucigalpa"
}
```

Este fragmento muestra solo los campos nuevos; la respuesta conserva todos
los intervalos y límites anteriores. La zona procede del país de la empresa;
si el motorista no tiene empresa se usa `TIME_ZONE` del despliegue.

Para el frontend:

1. Consultar la referencia y anclarla al reloj **monotónico** del dispositivo
   (tiempo transcurrido), no a la fecha/hora manual del sistema.
2. Estimar la fecha UTC de cada captura desde ese anclaje y guardar el punto
   completo antes de enviarlo. Mostrar fechas en `zona_horaria_operativa`, no
   cambiar el día operativo usando la zona manual del teléfono.
3. Mantener UUID/sesión/secuencia y timestamps originales en la cola. Un
   reintento debe repetirlos exactamente, sin recalcular fechas ni poner a
   todos los puntos la hora de llegada del lote.
4. Renovar la referencia al reconectar y si se pierde la continuidad del reloj
   monotónico, sin reescribir puntos ya capturados. No fabricar una hora
   supuestamente oficial desde el reloj manual cuando no existe un anclaje válido.

**Este cambio móvil no está implementado desde el backend.** Publicar la hora
no sincroniza automáticamente la app. `registrada_en` conserva la semántica de
captura para medir trayectos y recibir GPS tardío; `creado_en` registra recepción
en el servidor. Se mantienen límites de futuro, intervalo de jornada, corte
Corporate y manifiestos sellados. El backend no puede certificar una captura
offline auténtica solo con un timestamp enviado por un dispositivo: no debe
presentarse esta referencia como protección absoluta frente a una app alterada.

### Limpieza segura ante fallos

Solicitudes e incidencias reutilizan `limpiar_archivo_nuevo`. Tras fallar la
persistencia, la transacción revierte filas y se intenta eliminar exclusivamente
la clave del archivo recién guardado. No se borran archivos históricos.
Si también falla la eliminación, se registra el fallo y se propaga el error
original. Con almacenamiento caído el archivo puede quedar huérfano para
atención posterior; no se promete una eliminación que no pudo completarse.

Verificación: **353 pruebas aisladas aprobadas**, incluidas nueve nuevas y
ampliación del contrato de configuración GPS. Cubren fecha futura/pasada/inválida
u omitida, servicio directo, hora de jornada, propiedad al reportar, corte por
modo, fotos con incidencia abierta/cerrada y rollback/compensación en ambos
flujos. Sin migraciones, conexiones, datos históricos ni tareas modificadas.

## Límite de intentos de inicio de sesión (0.30.1)

Aplica **solo** a `POST /api/v1/autenticacion/iniciar-sesion/` cuando el proveedor
es `LOCAL`: Network y Corporate local. Con `JWT_CORPORATIVO` este endpoint
continúa respondiendo `404`; el sistema corporativo gestiona su autenticación.
No se añadieron límites a renovación, cierre de sesión, GPS ni otras API.

### Diez fallos por correo/IP en quince minutos

- La identidad del contador es la combinación de correo normalizado y dirección
  IP obtenida por el servidor (`REMOTE_ADDR`), nunca un campo enviado en JSON.
  Mayúsculas y espacios de correo no crean otro contador. `X-Forwarded-For` no
  se confía directamente; un despliegue futuro con proxy requiere revisión de
  proxies confiables, no habilitar ese encabezado desde clientes.
- La ventana fija dura **15 minutos** desde el primer intento fallido de ese
  grupo. Usa exclusivamente la hora del servidor y se reinicia al vencer.
- Se permiten evaluar diez intentos fallidos; los diez devuelven `401` con el
  mensaje genérico de credenciales. A partir del siguiente intento devuelve
  `429`, sin verificar contraseña ni crear sesión, hasta terminar la ventana.
- Un acceso correcto **antes** de agotar los diez fallos pone el contador en
  cero. Una contraseña correcta no permite saltarse una ventana ya bloqueada.
- Peticiones bloqueadas no extienden el tiempo de espera. Entrada inválida
  (`400`) y errores internos no se suman como contraseñas equivocadas.
- Usuario inexistente, inactivo o sin contraseña usable recibe la misma
  política genérica; no se revela existencia del correo ni fallos restantes.
- No cambia `estado` del usuario ni contraseña y no revoca sesiones vigentes.
  Cada despliegue usa su base; no se comparten contadores Corporate/Network.

Respuesta de bloqueo, ejemplo con ventana completa pendiente:

```http
HTTP/1.1 429 Too Many Requests
Retry-After: 900
Content-Type: application/json
```

```json
{
  "detail": "Se alcanzó el límite de intentos de inicio de sesión. Intente más tarde.",
  "segundos_espera": 900
}
```

La espera real es un entero positivo, redondeado hacia arriba, con los segundos
restantes de la ventana; normalmente será menor que 900. La entrada del login
y sus respuestas correctas `200`, errores de formato `400` y credenciales `401`
mantienen sus nombres y contrato. La renovación de tokens no adopta este límite.

### Para el frontend

Ante `429`, mostrar `detail` y deshabilitar temporalmente nuevos intentos según
`Retry-After` o `segundos_espera`. Medir la espera con tiempo monotónico, no con
la hora manual del teléfono. No clasificarlo como desconexión, no activar
renovación de tokens por ese estado y no reintentar el login automáticamente.
El servidor decide siempre si puede volver a intentarse; cambiar el reloj del
teléfono o reinstalar la app no reinicia el contador de esa combinación.

### Persistencia, despliegue y alcance

`autenticacion.0002_control_intentos_inicio_sesion` crea exclusivamente
`controles_intentos_inicio_sesion`: UUID, marcas de tiempo, huella HMAC única,
conteo de fallos 0..10 e inicio de ventana. No almacena correo/IP en claro ni
contraseñas y no modifica tablas de usuarios o sesiones. Se aplicó en ambas
bases locales, `vitago_corporativo` y `vitago`, verificando sus destinos.

El control adquiere bloqueo de fila en una transacción antes de verificar la
contraseña y confirma el fallo antes de elevar el error. PostgreSQL comparte
el contador entre procesos; no se depende de memoria/caché privada. El login
excluye `ATOMIC_REQUESTS` para no perder el contador al responder `401`; la
creación de sesiones conserva su propia transacción. No se añade otro servidor,
dependencia, cambio de .env/conexión o tarea Windows.

Esto no es un límite global por cuenta o IP ni protección completa contra
ataques distribuidos o denegación de servicio: otra combinación correo/IP tiene
su propio contador. La IP de una red compartida no bloquea correos diferentes.
Si no se obtiene una IP válida se usa un grupo sin IP para ese correo. No existe
un endpoint público para borrar contadores. Una fila se reutiliza al vencer
la ventana o reiniciar fallos; no hay limpieza automática de combinaciones
antiguas. Definir retención y defensa de borde antes de uso público prolongado.

Verificación: **372 pruebas aisladas aprobadas** (semilla 3121), con 19 pruebas
nuevas de límite, expiración exacta, normalización, privacidad, tipos de fallo,
reutilización de sesión/renovación sin límite, proveedor y hora oficial.
En esta fase no se agotaron intentos de cuentas reales ni se ejecutó concurrencia
PostgreSQL; esa verificación se realizó después en 0.30.2. Las pruebas de 0.30.1
usan SQLite y un hasher rápido solo en su fixture; los hashers reales del backend
no se modificaron.

## Verificación concurrente del login en PostgreSQL (0.30.2)

**Sin cambios de contrato, lógica de negocio ni acciones nuevas para Flutter.**
Se añadieron siete escenarios permanentes en
`apps/autenticacion/tests/test_concurrencia_inicio_sesion.py` y se ejecutó toda
la suite de autenticación en PostgreSQL: **44 pruebas aprobadas**.
Los siete escenarios se repitieron con semillas 3122 y 3124; las tres pasadas
fueron exitosas. Los resultados comprueban sincronización, no rendimiento de
producción: el fixture usa un hasher rápido, sin modificar el hasher del backend.

| Escenario | Solicitudes de la prueba | Resultado |
|---|---|---|
| Contador nuevo, mismo correo/IP | 24 simultáneas, variando X-Forwarded-For | Diez 401, catorce 429 y un contador con diez fallos |
| Ya existen nueve fallos | 24 simultáneas | Solo un 401 adicional; veintitrés 429 |
| Ventana con diez fallos ya vencida | 24 simultáneas | Reinicio único: diez 401 y catorce 429 |
| Mismo correo, dos IP distintas | Doce simultáneas por cada IP | Diez 401 y dos 429 por cada grupo |
| Contraseña correcta antes de agotar la ventana | 24 simultáneas tras nueve fallos | Veinticuatro 200 y contador en cero |
| Dos procesos de aplicación separados | Ocho solicitudes por proceso | En total diez 401 y seis 429; contador compartido |
| Configuración ATOMIC_REQUESTS activa | Diez fallos y otro intento | El contador persiste; siguiente intento recibe 429 |

Cada grupo de 24 abrió 24 conexiones PostgreSQL diferentes, comprobadas por
sus procesos de backend. El caso multiproceso arrancó Django en dos procesos
Python separados: no comparten caché ni locks del intérprete. No hubo errores
500, incrementos perdidos ni un undécimo fallo evaluado.

### Aislamiento y retirada de la base temporal

El usuario autorizó preparar y eliminar una base exclusiva. Como vitago no
tiene CREATEDB, la creó el usuario con OWNER vitago y TEMPLATE template0.
Se verificó que `vitago_pruebas_concurrencia_20261021` estuviera vacía y tuviera
el propietario esperado. El runner fijó TEST.NAME y usó keepdb; el destino
real se comprobó antes de las pruebas. Las migraciones y los fixtures no se
ejecutaron en las bases de Corporate o Network.

Al terminar se verificaron nombre exacto, propietario y cero conexiones activas;
se eliminó solo esa base temporal, sin forzar el cierre de conexiones. Sus datos
eran sintéticos y pueden regenerarse. No hay cambios de datos, contraseñas,
conexiones, modelos o migraciones de los despliegues reales por esta fase.

La suite habitual con SQLite detecta **379 casos**: **372 aprobados y siete
omitidos**, porque estas pruebas requieren PostgreSQL. Los siete omitidos
sí se ejecutaron y aprobaron por separado en la base PostgreSQL temporal.
Para repetirlas se requiere otra base de pruebas autorizada; --keepdb no
reemplaza la comprobación explícita de TEST.NAME y del destino real.

## Concurrencia de asignaciones y referencias de ruta (0.30.3)

**No requiere cambios de endpoints, JSON ni frontend.** No se añade aceptación
o rechazo del motorista, capacidad manual ni reintentos HTTP del cliente.

### Fallo reproducido y corrección

Se reprodujo un deadlock real con dos reasignaciones cruzadas y también con
dos cancelaciones del mismo motorista. Cada transacción bloqueaba su solicitud
con FOR UPDATE; una obtenía el motorista y creaba versiones de ruta cuyas
paradas referenciaban la otra solicitud. La validación de esas llaves foráneas
esperaba al bloqueo de la otra transacción, que a su vez esperaba al motorista.
PostgreSQL abortaba una operación: no era un error de red ni un problema de IP.

Los servicios ahora bloquean Solicitud mediante
`select_for_update(of=("self",), no_key=True)` (FOR NO KEY UPDATE). Sigue
impidiendo escrituras simultáneas en la misma solicitud, pero permite crear
filas que la referencian sin cambiar su UUID. Se mantiene en asignación manual,
reintentos automáticos, transiciones, suspensión/cierre diario, evidencia y
confirmación GPS especial, para no reintroducir el mismo ciclo por otro flujo.
Los bloqueos de motorista y su orden no cambian; el conteo y la revalidación
de cupo continúan dentro de la transacción. Sin modelos/migraciones nuevos.

Fundamento técnico: [Django: select_for_update, no_key](https://docs.djangoproject.com/en/5.2/ref/models/querysets/#select-for-update)
y [PostgreSQL: bloqueos de fila](https://www.postgresql.org/docs/17/explicit-locking.html#LOCKING-ROWS).

### Pruebas permanentes y resultados

Nuevo archivo: `apps/solicitudes/tests/test_concurrencia_asignaciones.py`.
Usa conexiones PostgreSQL independientes, comprobadas por pg_backend_pid,
barreras/eventos y límites de espera; no sustituye los bloqueos con mocks.
Los casos de deadlock sincronizan ambas solicitudes antes de competir por el
motorista. También se comprueban cupo derivado, asignación activa única,
historial, notificaciones y correspondencia de las últimas paradas persistidas.

| Escenario | Resultado comprobado |
|---|---|
| Ocho asignaciones manuales a un motorista vacío | Cinco 201 y tres 409 con repartidor_id; FULL y excluido de disponibles |
| Ocho asignaciones cuando ya tiene cuatro | Un 201 y siete 409 |
| Ocho intentos sobre la misma solicitud y motorista | Un 201, siete 400; sin duplicar asignación ni aviso |
| Ocho creaciones automáticas y un motorista elegible | Máximo cinco activas; tras revisar pendientes, cinco asignadas y tres pendientes |
| Ocho reintentos automáticos sobre una pendiente | Una asignación activa y un aviso al elegido |
| Prioritario en proceso de asignación al más cercano | Creación concurrente escala al otro motorista |
| Pausa concurrente del más cercano | No recibe la nueva solicitud; se utiliza el otro candidato |
| GPS vencido del más cercano y cinco creaciones | Solo recibe servicios el candidato con GPS vigente |
| Cancelación y nueva creación con cinco servicios | Se libera/reutiliza un cupo, sin superar cinco |
| Entrega con evidencia y creación con cinco servicios | Se libera/reutiliza un cupo y se conserva la entrega |
| Reasignaciones cruzadas | Ambas terminan; se conservan asignaciones anteriores y avisos de retirada |
| Dos cancelaciones del mismo motorista | Ambas terminan, rutas e historial consistentes |
| Dos cierres diarios del mismo motorista | Ambos terminan como PICKUP_FAILED con FIN_DIA |
| Dos retiros por suspensión | Ambos terminan y se reasignan al motorista elegible |

SKIP LOCKED continúa omitiendo motoristas ocupados por otras transacciones:
una creación puede quedar PENDING aunque luego se libere cupo. Los eventos
operativos existentes vuelven a revisar pendientes; la prueba invoca ese mismo
servicio para comprobar el resultado final. No se promete asignación inmediata
de todas las solicitudes durante contención ni se agrega otro servidor.

Los catorce escenarios pasaron en ejecución específica, dentro de la suite
completa (semilla 3033) y nuevamente con orden mezclado (semilla 3035).
**Suite PostgreSQL completa: 393 aprobadas, ninguna omitida.** Suite SQLite
con semillas 3031/3034: **372 aprobadas y 21 omitidas por requerir PostgreSQL**.
Sin diferencias de modelos en makemigrations --check --dry-run.

Para ejecutar toda la suite en PostgreSQL también se corrigieron dos pruebas
de descarga: consumen streaming_content y verifican PNG/cierre, en vez de
cerrar directamente la respuesta y la conexión transaccional del TestCase.
No se cambió el comportamiento real de descarga ni la conexión del backend.

### Aislamiento de esta fase

El usuario volvió a crear y autorizó eliminar
`vitago_pruebas_concurrencia_20261021`. Se comprobó vacía y propiedad de vitago;
runner con NAME/TEST.NAME explícitos y keepdb, migraciones solo en esa base y
storage temporal. Se reconstruyó exclusivamente su esquema public regenerable
para restaurar catálogos antes de ejecutar la suite completa. Nunca se usaron
datos operativos para pruebas o cierres.

Al terminar se eliminó únicamente esa base, validando nombre exacto, propietario
y cero conexiones, sin terminaciones forzadas. Corporate/Network permanecen
intactos: sin cambios de datos, conexión, puertos, .env, secretos o tarea Windows.

## Activación local del trazado en Corporate (0.30.4)

Routes está habilitada en Corporate mediante `HABILITAR_RUTAS_GOOGLE=true`.
La clave permanece privada en `.env.corporativo`; no se comparte con Flutter.
No se cambió la configuración de Network ni el contrato de rutas.

Integración existente para el motorista propietario:

1. `GET /api/v1/rutas/mi-ruta/` obtiene `version_actual`, paradas y mapa.
2. Para calcular explícitamente, enviar
   `POST /api/v1/rutas/mi-ruta/calcular/` con
   `{"version_actual": <version_actual recibida>}`.
3. La respuesta 200 es **solo el objeto `ruta_vial`**, no el objeto completo de
   `mi-ruta/`. Decodificar `polilinea_codificada` y dibujar en Google Maps dentro
   de la app; respetar atribución y aviso de rutas para motocicleta del contrato.

Se necesita jornada abierta, servicios asignados y GPS vigente. No inventar GPS
ni usar la prueba del proveedor como ruta operativa. El orden sigue siendo por
asignación, recogida antes de la entrega propia y prioridad recogida primero;
Google no optimiza el orden. Los especiales mantienen solo kilometraje.

GET y recepción de GPS no llaman a Google. No agregar recálculo continuo ni
reintentos HTTP automáticos. Se conservan límites por base de 50 intentos/día,
500/mes y dos intentos por versión. La ruta inicial puede reutilizarse al
completar paradas según los indicadores existentes; no garantiza giro a giro.

Mantenimiento: `VitaGo-Corporate-LimpiezaGoogle` elimina solo la polilínea
vencida, sin borrar filas, auditoría, paradas, solicitudes o contadores. No
consulta a Google. Primera ejecución automática correcta (resultado 0), sin
geometrías vencidas. La tarea de cierre diario se conservó sin modificaciones.

Verificación: ocho pruebas nuevas de limpieza; suite común de 401 casos,
**380 aprobadas y 21 omitidas por requerir PostgreSQL**, con acceso real a Google
bloqueado durante pruebas. `check`, comprobación de migraciones y script
PowerShell correctos. Esta fase no repite la suite PostgreSQL ni realiza nuevas
consultas facturables. Falta verificar visualmente el trazado en el teléfono.

## Reparaciones integrales y resumen diario (0.31.0)

### Seguridad y sesiones

Los errores técnicos HTTP ya no muestran pila, variables ni configuración,
incluso si alguien activa DEBUG localmente. API devuelve JSON genérico para
errores técnicos 400/404 HTML y para 500; los errores de validación con nombres
de campo, 401/Bearer y 429/Retry-After conservan su contrato. Logs privados
mantienen excepción/pila; no compartirlos públicamente. Los informes internos
de Django censuran secretos españoles, cuerpos POST y variables locales.

Se renovó únicamente la clave de firma JWT de Corporate y se desactivó su
depuración. Los tokens anteriores dejan de ser válidos: iniciar sesión otra vez.
No se cambiaron contraseñas, IP, hosts, puertos, bases, firewall ni claves Network.

### Pérdida de habilitación operativa

Revocar el rol REPARTIDOR_CORPORATIVO programa una revalidación después del
commit. Si perdió su rol efectivo, se retiran/reasignan sus servicios mediante
la contingencia existente; si conserva otro alcance válido o recuperó el rol,
no se retiran. La tarea actual recupera también callbacks interrumpidos y roles
inactivados en catálogo, sin modificar su programación.

Sin paquete, vuelve a pendiente/asignada. Con paquete, conserva la fase de
entrega y el nuevo motorista continúa hacia destino: traspaso físico fuera de
la app. Sin sustituto, queda `reasignacion_pendiente=true`, sin inventar entrega.
Listados disponibles, bandera y validaciones comparten condición de rol vigente
según modo, empresa y alcance. Se mantiene límite cinco/prioridad/vehículo.
Network no recibe la política corporativa de reasignación por contingencia.

Compatibilidad de auditoría: se conservan `motivo=SUSPENSION` y
`contingencia_suspension`; el evento añade
`causa=ROL_OPERATIVO_NO_VIGENTE` o `USUARIO_NO_ACTIVO`. No crear nuevos estados
en Flutter por esta diferencia.

### Corte diario aunque la tarea se retrase

El cierre manual Corporate después de medianoche usa el corte exacto del día
de la jornada, igual que el automático: `FIN_DIA`, sin coordenadas del teléfono
tomadas después del corte ni confirmación GPS inventada. La sincronización GPS
se confirma luego por los endpoints existentes. Con asignaciones activas el
cierre manual continúa rechazado. No se altera el cierre manual de Network.

El POST vial valida día de jornada y solicitudes antes de reservar consumo,
antes de devolver caché y al publicar. Si la respuesta del proveedor cruza
medianoche, guarda el intento fallido sin polilínea y devuelve
`DIA_OPERATIVO_FINALIZADO`; conserva el consumo porque la llamada sí se inició.
Si ya estaba vencido antes de calcular, no invoca Google ni reserva presupuesto.
No cambia orden de paradas, proveedor, caducidad ni política de recálculo.

### Verificación y entrega al frontend

Suite completa aislada: 466 casos, **445 aprobados y 21 omitidos por requerir
PostgreSQL**; 65 regresiones nuevas. Google real bloqueado durante pruebas.
`check`, migraciones en dry-run y dependencias correctos, sin migraciones nuevas.
No se repitieron pruebas concurrentes PG contra bases operativas.

Corporate reiniciado en la misma URL `http://192.168.10.145:8001/api/v1/`.
Salud 200 por localhost/IP; error de host no autorizado 400 JSON sin secretos.
Resumen diario y configuración GPS comprobados sobre datos locales en modo
solo lectura. No se modificó el frontend ni se hicieron consultas Google desde
la verificación. Flutter debe consumir los campos diarios y aplicar captura
GPS 5/15 segundos; el backend no puede forzar la frecuencia física del teléfono.

## Llegada automática a la próxima parada (0.32.0)

### Regla operativa

En Corporate y Network se evalúa únicamente `proxima_parada` en el orden vigente
de `GET /api/v1/rutas/mi-ruta/`; no se salta a otra sucursal cercana ni se cambia
el orden por distancia. Un prioritario/especial recogido conserva su exclusividad.

- Desde0.36.0 el backend inicia automáticamente el desplazamiento del servicio
  vigente: `GOING_TO_PICKUP` o `IN_TRANSIT`; no hay botón de aceptación/inicio.
- El servidor detecta `GOING_TO_PICKUP -> AT_PICKUP` o
  `IN_TRANSIT -> AT_DESTINATION` con puntos propios de la jornada activa,
  asignación y rol vigentes, y día operativo válido cuando corresponde.
- Se detecta estando `AVAILABLE` u `ON_ROUTE`, incluso tras reanudar una pausa
  con un traslado ya iniciado. `PAUSED`, `OFFLINE` y `OUT_OF_SERVICE` no generan
  llegadas automáticas. Detectar una llegada no cambia la disponibilidad.
- Valores iniciales: radio **50 m**, precisión conocida **<=20 m**, al menos
  **3 capturas distintas** y permanencia mínima **10 s** tanto entre capturas
  como entre recepciones del servidor. Una sola carga de puntos no prueba espera.
- La última captura debe tener como máximo **30 s**. Puntos viejos, futuros,
  anteriores al desplazamiento/asignación o recibidos con más de 30 s de retraso
  no acreditan llegada. Un punto fuera del radio, impreciso o un hueco excesivo
  interrumpe la permanencia; no se descartan para unir artificialmente la racha.
- Los valores son configurables, se consultan en configuración GPS. La ventana
  y cantidad de puntos examinados están acotadas; no se recorren todos los GPS.
- La llegada se audita con evento, evidencia GPS de detección y hora del
  **servidor**. Reintentar el lote no duplica eventos ni cambia la fecha de llegada.
- **Llegar no recolecta ni entrega**: sigue siendo obligatoria la foto.
  Desde0.36.0 guardarla correctamente ejecuta automáticamente las transiciones
  de su etapa, sin una segunda confirmación del motorista.
- El origen registrado de un especial sí usa GPS. Su destino `ENVIO_ESPECIAL`
  sin coordenadas conserva la llegada manual; no se inventa geocerca ni mapa.
- En un traspaso por contingencia, si el anterior ya estaba `AT_DESTINATION`,
  el reemplazo continúa `IN_TRANSIT` y `llegada_destino_en=null` hasta acreditar
  su propia llegada. No repite la recolección. El evento del motorista anterior
  se conserva, y el evento de reasignación incluye estado anterior/nuevo.

No son diez segundos garantizados de respuesta: con captura detenido cada 15 s,
tres puntos requieren normalmente al menos 30 s y el envío por lotes agrega
espera. Flutter puede usar captura más frecuente cerca de la próxima parada,
manteniendo los puntos reales y la cola idempotente; no enviar fechas simuladas.
La detección necesita GPS enviado y conectividad. No es un push ni una garantía
de localización física: la aplicación y el sistema operativo siguen siendo
responsables de obtener coordenadas reales y permisos de ubicación.

### Respuesta del lote GPS

`POST /api/v1/seguimiento/registros/` conserva `201`, contadores y `registros`,
y añade `llegadas_detectadas` (lista vacía si no hubo una transición nueva):

```json
{
  "recibidos": 3,
  "creados": 3,
  "repetidos": 0,
  "llegadas_detectadas": [
    {
      "evento_id": "e7b36e0d-e218-4b82-9dbb-f98092a68abb",
      "solicitud_id": "c393deec-e3b5-4316-8f7f-f30d1e57b76c",
      "estado": "AT_PICKUP",
      "tipo_parada": "RECOLECCION",
      "detectada_en": "2026-10-22T18:00:00Z",
      "fuente": "GPS",
      "pantalla": "RECOLECCION",
      "ruta": "/solicitudes/c393deec-e3b5-4316-8f7f-f30d1e57b76c"
    }
  ],
  "registros": []
}
```

En este ejemplo se abrevia únicamente `registros`; su contenido real conserva
los tres objetos del contrato habitual. `ENTREGA` usa `AT_DESTINATION` y
`pantalla=ENTREGA`. El evento se procesa después del commit GPS: si una detección
falla transitoriamente, el lote confirmado no se convierte en un error genérico;
el siguiente envío/reintento vuelve a evaluar. No realiza consultas Google.

### Recuperación y configuración

`GET /api/v1/rutas/mi-ruta/` añade `llegada_actual`: objeto con el mismo contrato
o `null`. Solo corresponde a la próxima parada ya en `AT_PICKUP`/`AT_DESTINATION`
y a su asignación vigente. Permite recuperar una respuesta GPS perdida o volver
a la app sin crear otro evento. Las lecturas no detectan llegadas ni cambian
estados. El destino especial confirmado manualmente indica `fuente=MANUAL`.

`GET /api/v1/seguimiento/configuracion/` añade:

```json
{
  "llegada_automatica": {
    "habilitada": true,
    "radio_metros": 50.0,
    "permanencia_minima_segundos": 10,
    "minimo_puntos": 3,
    "precision_maxima_metros": 20.0,
    "antiguedad_maxima_segundos": 30,
    "solo_proxima_parada": true,
    "destino_especial_sin_coordenadas_manual": true
  }
}
```

La configuración mantiene su URL existente; no se crea otro endpoint de llegada.

### Integración en este frontend

1. Ocultar los botones de llegada manual cuando la parada tiene coordenadas;
   desde 0.36.0 retirar también iniciar/confirmar y selectores de etapa. Conservar
   tomar/enviar foto, incidencias y finalización especial sin destino GPS.
2. Consumir `llegadas_detectadas` al sincronizar GPS y abrir dentro de la app
   la pantalla `RECOLECCION` o `ENTREGA`, con `solicitud_id` y estado actualizado.
3. Conservar `evento_id` ya mostrado para no reabrir repetidamente la pantalla.
   Al reanudar o recuperar red, consultar `mi-ruta` y revisar `llegada_actual`.
4. Si está en segundo plano, sincronizar/actualizar al reanudar; este contrato
   no habilita Firebase ni fuerza abrir pantallas desde el servidor.
5. Mostrar espera por GPS válido y los errores de campo. Intentar manualmente
   una llegada controlada responde `400` con `estado_destino`; un booleano GPS
   enviado por el cliente no habilita la transición.

La navegación descrita ya está integrada en este frontend. Se conserva el
contrato del backend, las conexiones y los servicios Google. La verificación
automatizada no sustituye la prueba de llegada con GPS real en un teléfono.

### Verificación de 0.32.0

50 regresiones nuevas: Corporate/Network, proximidad/permanencia y recepción
del servidor, hora futura/cola vieja, continuidad, permisos, orden, especiales,
evidencias, recuperación, traspasos y reanudación de pausa. Dos pruebas HTTP con commit real
validan el evento serializado y la recuperación tras fallo transitorio.
Suite completa aislada: **516 casos, 495 aprobados y 21 omitidos por requerir
PostgreSQL**, semilla 3206; Google real bloqueado. `check`, dry-run de migraciones
y dependencias correctos. Sin migraciones nuevas ni escrituras de verificación
en las bases operativas. Salud de Corporate local: 200, misma conexión.

## Avisos diarios y archivado recuperable (0.33.0)

### Política de vigencia

La zona se obtiene de `TIME_ZONE` del despliegue, configurada mediante
`ZONA_HORARIA_PREDETERMINADA`; localmente ambos usan `America/Tegucigalpa`.
No utiliza la fecha del teléfono, una zona activada por el cliente ni la fecha
de la solicitud. Se usa `creado_en` del aviso, registrado por el servidor.

A las **00:00 del servidor** dejan de ser visibles todos los avisos anteriores,
tanto leídos como no leídos. Un aviso de las 23:59 vence al minuto siguiente,
no 24 horas después. El rango de consulta es `[medianoche de hoy, medianoche
siguiente)` y además exige `archivada_en=null`. También excluye fechas futuras.
Los límites respetan cambios de fecha y días de distinta duración según zona.

Esta regla está en las consultas de listado, conteo y acceso propio, no en
Flutter: sigue funcionando aunque el teléfono esté apagado y aunque la tarea
no haya corrido. Marcar leído revalida la vigencia dentro del bloqueo de fila,
incluyendo una espera que cruce medianoche.

### API y trabajo del frontend

No cambian las rutas, permisos, paginación ni campos del JSON:

```http
GET /api/v1/notificaciones/?pagina=1&tamano_pagina=20
GET /api/v1/notificaciones/conteo-no-leidas/
POST /api/v1/notificaciones/{notificacion_id}/marcar-leida/
```

- El listado devuelve exclusivamente los avisos propios vigentes.
- El conteo suma únicamente avisos vigentes con `leida_en=null`.
- Un aviso vencido/archivado/ajeno/inexistente responde `404` al marcarlo leído.
- Marcar un aviso vigente conserva su comportamiento idempotente.
- `archivada_en` es interno y no se agrega al payload móvil.
- Al reanudar la app, recuperar red o abrir la campana, volver a consultar
  listado y conteo; reemplazar la caché anterior y el contador con la respuesta,
  no conservar avisos antiguos mediante una mezcla acumulativa.
- Si un ID guardado devuelve `404`, retirarlo de la caché y actualizar la lista.
  No presentarlo como fallo de conexión ni reintentar el aviso caducado.

El servidor no puede modificar una pantalla desconectada ni su caché física
mientras el teléfono está apagado. La información correcta se obtiene al
reconectar. No se añade Firebase/push. El refresco correspondiente ya está
integrado en este frontend, sin modificar las rutas ni los payloads existentes.

### Archivado y recuperación del servidor

`notificaciones.0003_archivado_diario_avisos` añade `archivada_en` nullable y un
índice parcial de `creado_en` para filas sin archivar. Se aplicó separadamente
en `vitago_corporativo` y `vitago`. Los registros históricos permanecen.

El mantenimiento hace únicamente un `UPDATE` de `notificaciones_usuario`:
archiva todas las filas con `creado_en < medianoche de hoy` y sin archivo previo.
Mantiene `leida_en`, UUID, solicitud, evento y contenido; repetirlo no duplica
ni cambia la fecha original de archivo. Si se omitieron varios días, recupera
todos, no solo ayer. No cierra ni borra solicitudes, GPS, evidencias o eventos.

Tareas instaladas y separadas de las tareas operativas existentes:

- `VitaGo-Corporate-LimpiezaAvisos`: configuración y base Corporate.
- `VitaGo-Network-LimpiezaAvisos`: configuración y base Network.

Cada una usa Python sin ventana, medianoche con desplazamiento del servidor,
recuperación cada 15 minutos, al iniciar sesión y ejecución pendiente cuando
esté disponible; tres reintentos ante error y sin instancias simultáneas de
la misma tarea. El comando revalida el modo esperado antes de escribir.
Si cambia la zona operativa configurada, revisar también la programación diaria.
Las consultas siempre calculan el día con la zona vigente del servidor.

En este entorno local se requiere PC encendida y sesión de Windows iniciada
(también puede estar bloqueada). Con la PC apagada/dormida/sin sesión se recupera
al volver. No depende del estado del teléfono ni necesita un servidor adicional.

Primera recuperación automática: **23 avisos archivados en Corporate, 0 en
Network; ambas tareas con resultado 0**. No se ejecutó manualmente la tarea de
cierre operativo ni se modificaron sus disparadores.

### Verificación de 0.33.0

25 pruebas nuevas: límites exactos de medianoche, recuperación de varios días,
lectura/propiedad, idempotencia, simulación sin escritura, IDs caducados,
espera de bloqueo que cruza el corte, zonas del servidor frente a zona activada
por usuario, días de 23/25 horas, modos Corporate/Network y comando sin stdout.
Se verifica que el mantenimiento emite exclusivamente un UPDATE de avisos y
mantiene solicitudes, eventos, GPS y evidencias intactos.

Suite completa aislada: **541 casos, 520 aprobados y 21 omitidos por requerir
PostgreSQL**, semilla 3303. Google real bloqueado. `check`, dry-run de migraciones,
dependencias y sintaxis PowerShell correctos. Salud Corporate: 200.
Comprobación adicional en PostgreSQL con transacción READ ONLY: listado y
conteo devuelven 200; se conservan avisos no leídos del día y las 23 filas
archivadas. Simulación posterior: cero avisos anteriores pendientes en ambas bases.

## Un envío y un tramo a la vez (0.34.0)

### Flujo previsto

Desde0.36.0 el mapa muestra automáticamente solo el tramo de la próxima parada
operativa, indicado por `flujo_actual.tramo_id`. Se retiran los selectores de
envío/recolección/entrega del flujo operativo. Las geometrías restantes se
conservan por compatibilidad, pero no autorizan saltar a otra etapa o servicio.

Al registrar `PICKED_UP`, el tramo actual pasa a la entrega; tras `DELIVERED`,
pasa al siguiente envío. La llegada por GPS por sí sola no completa esas etapas:
se mantiene la foto y desde0.36.0 guardarla correctamente completa su etapa sin
otra confirmación. El detector siempre usa la próxima parada real.

No agrega navegación giro a giro, recálculos automáticos, ETA en vivo ni cambios
en la captura GPS. Para mover el marcador se usa el GPS del teléfono, no volver
a calcular la línea.

### Endpoints y campos adicionales

Se conservan:

```http
GET /api/v1/rutas/mi-ruta/
POST /api/v1/rutas/mi-ruta/calcular/
```

El POST recibe el mismo `{ "version_actual": 1, "reintentar": false }` y
devuelve `ruta_vial` directamente. En GET, estos campos van en `ruta_vial`.
No hay endpoint para seleccionar un envío. Desde 0.36.0 Flutter tampoco ofrece
selección operativa: sigue únicamente `flujo_actual.tramo_id`.

| Campo nuevo | Tipo | Regla |
|---|---|---|
| `modo_visualizacion` | string | `UN_TRAMO`: dibujar como máximo una línea. |
| `desglose_disponible` | boolean | Hay geometrías de legs válidas y vigentes para el itinerario. |
| `requiere_actualizar_desglose` | boolean | Existe cálculo reutilizable antiguo/incompleto sin el desglose necesario. No es permiso de recálculo automático. |
| `tramo_actual_id` | string o null | ID del tramo correspondiente a la próxima parada; no se elige por distancia. |
| `tramos` | lista | Solo los tramos de paradas pendientes incluidos en el prefijo cartografiable. |

Cada objeto de `tramos` incluye exactamente:

| Campo | Tipo / significado |
|---|---|
| `tramo_id` | string estable `solicitud_id:RECOLECCION` o `solicitud_id:ENTREGA`; usar como clave de selección. |
| `solicitud_id` | UUID string del envío propio. |
| `numero_solicitud` | Número legible de la solicitud. |
| `orden_envio` | Posición del envío en el cálculo original reutilizado, desde 1; puede tener saltos al completar envíos. No es un ID permanente. |
| `orden_parada` | Orden actual de la parada pendiente, desde 1. |
| `tipo_parada` | `RECOLECCION` o `ENTREGA`. |
| `estado_solicitud` | Estado actual de la solicitud. |
| `es_proximo` | Si es la próxima parada operativa, independientemente de la selección visual. |
| `origen` | `{tipo: GPS/PARADA, ubicacion_id: UUID/null, latitud: decimal-string, longitud: decimal-string}`. |
| `destino` | `{ubicacion_id: UUID, latitud: decimal-string, longitud: decimal-string}`. |
| `polilinea_codificada` | string del tramo, o null si no requiere desplazamiento. Decodificar en Flutter. |
| `sin_desplazamiento` | boolean: dos acciones consecutivas en el mismo punto; mostrar ubicación, no repetir una línea anterior. |

`origen` es el punto inicial **previsto en el cálculo**, no GPS en vivo. Para
un envío posterior puede ser el destino del envío anterior; verlo no calcula
un viaje directo desde la posición actual del teléfono.

### Ejemplo completo de los campos nuevos: dos envíos

El siguiente objeto contiene solo la ampliación de `ruta_vial`; sus campos
anteriores (`estado`, atribución, caducidad, etc.) se mantienen. Coordenadas y
polilíneas son **fixtures sintéticos**, no trayectos reales ni datos para hardcodear
en Flutter. Usar siempre las geometrías de la respuesta efectiva de la API.

```json
{
  "modo_visualizacion": "UN_TRAMO",
  "desglose_disponible": true,
  "requiere_actualizar_desglose": false,
  "tramo_actual_id": "40000000-0000-0000-0000-000000000001:RECOLECCION",
  "tramos": [
    {
      "tramo_id": "40000000-0000-0000-0000-000000000001:RECOLECCION",
      "solicitud_id": "40000000-0000-0000-0000-000000000001",
      "numero_solicitud": "SOL-TRAMOS-1",
      "orden_envio": 1,
      "orden_parada": 1,
      "tipo_parada": "RECOLECCION",
      "estado_solicitud": "ASSIGNED",
      "es_proximo": true,
      "origen": {"tipo": "GPS", "ubicacion_id": null, "latitud": "14.072000", "longitud": "-87.192000"},
      "destino": {"ubicacion_id": "50000000-0000-0000-0000-000000000001", "latitud": "14.072300", "longitud": "-87.192100"},
      "polilinea_codificada": "????",
      "sin_desplazamiento": false
    },
    {
      "tramo_id": "40000000-0000-0000-0000-000000000001:ENTREGA",
      "solicitud_id": "40000000-0000-0000-0000-000000000001",
      "numero_solicitud": "SOL-TRAMOS-1",
      "orden_envio": 1,
      "orden_parada": 2,
      "tipo_parada": "ENTREGA",
      "estado_solicitud": "ASSIGNED",
      "es_proximo": false,
      "origen": {"tipo": "PARADA", "ubicacion_id": "50000000-0000-0000-0000-000000000001", "latitud": "14.072300", "longitud": "-87.192100"},
      "destino": {"ubicacion_id": "50000000-0000-0000-0000-000000000002", "latitud": "14.082300", "longitud": "-87.182100"},
      "polilinea_codificada": "??????",
      "sin_desplazamiento": false
    },
    {
      "tramo_id": "40000000-0000-0000-0000-000000000002:RECOLECCION",
      "solicitud_id": "40000000-0000-0000-0000-000000000002",
      "numero_solicitud": "SOL-TRAMOS-2",
      "orden_envio": 2,
      "orden_parada": 3,
      "tipo_parada": "RECOLECCION",
      "estado_solicitud": "ASSIGNED",
      "es_proximo": false,
      "origen": {"tipo": "PARADA", "ubicacion_id": "50000000-0000-0000-0000-000000000002", "latitud": "14.082300", "longitud": "-87.182100"},
      "destino": {"ubicacion_id": "50000000-0000-0000-0000-000000000001", "latitud": "14.072300", "longitud": "-87.192100"},
      "polilinea_codificada": "????????",
      "sin_desplazamiento": false
    },
    {
      "tramo_id": "40000000-0000-0000-0000-000000000002:ENTREGA",
      "solicitud_id": "40000000-0000-0000-0000-000000000002",
      "numero_solicitud": "SOL-TRAMOS-2",
      "orden_envio": 2,
      "orden_parada": 4,
      "tipo_parada": "ENTREGA",
      "estado_solicitud": "ASSIGNED",
      "es_proximo": false,
      "origen": {"tipo": "PARADA", "ubicacion_id": "50000000-0000-0000-0000-000000000001", "latitud": "14.072300", "longitud": "-87.192100"},
      "destino": {"ubicacion_id": "50000000-0000-0000-0000-000000000002", "latitud": "14.082300", "longitud": "-87.182100"},
      "polilinea_codificada": "??????????",
      "sin_desplazamiento": false
    }
  ]
}
```

Ejemplo de avance usando el mismo cálculo: tras completar la recolección del
primer envío, `tramo_actual_id` termina en `:ENTREGA` y `tramos` contiene las
paradas 2, 3 y 4 anteriores, renumeradas como pendientes 1, 2 y 3. Tras entregar
el primero, quedan solo los dos tramos del envío 2, con sus mismos `tramo_id`
y `orden_envio=2`. Usar IDs, no posiciones de la lista, para conservar selección.

### Paradas coincidentes, prioritarios y especiales

La consulta agrupa coordenadas consecutivas iguales, pero **no elimina acciones**.
Si recolección y entrega son en el mismo punto, la entrega conserva su tramo
con `sin_desplazamiento=true` y `polilinea_codificada=null`. No dibujar de nuevo
el trayecto de recolección. La foto sigue siendo necesaria y desde0.36.0
guardarla correctamente sustituye la confirmación adicional.

Se conservan el corte ante especiales y la exclusividad del prioritario recogido.
Un especial no tiene líneas inventadas; consultar su descripción/kilometraje.
Los envíos posteriores a un corte pueden aparecer en `paradas` pero no en
`tramos`: mostrar «Tramo no incluido en el cálculo actual», sin solicitar Google
por seleccionarlos ni sustituirlo por una recta. La selección visual no cambia
el detector GPS ni permite adelantar acciones de esos envíos.

### Caché anterior sin desglose

Los cálculos existentes conservan su línea global y caducidad; la migración
no inventa segmentos ni consulta Google. Si existe una caché reutilizable sin
los nuevos datos, responde:

```json
{
  "modo_visualizacion": "UN_TRAMO",
  "desglose_disponible": false,
  "requiere_actualizar_desglose": true,
  "tramo_actual_id": null,
  "tramos": []
}
```

Flutter debe mostrar puntos/aviso y ofrecer una actualización **manual**, no
volver automáticamente al trazado global ni recortarlo por cercanía. Si el
usuario confirma, usar el POST existente con versión vigente y `reintentar=true`.
Consume un intento normal y respeta GPS, permisos, límites y caducidad. Si ya
se agotaron los intentos, `LIMITE_INTENTOS`; no crear versiones falsas para
evitarlo. Una ruta vencida sigue devolviendo `RUTA_VENCIDA` para la misma versión.
Repetir el POST cuando ya existe desglose devuelve caché, sin otra consulta.

La `polilinea_codificada` global sigue disponible solo por compatibilidad.
`incluye_tramos_completados` describe esa línea global: **los objetos nuevos de
`tramos` ya excluyen las paradas completadas**. No dibujar ambos formatos juntos.

### Entrega exacta al frontend

1. Construir los envíos agrupando `paradas` por `solicitud_id`; usar los IDs
   reales como claves y los números solo como etiquetas.
2. Desde0.36.0 seguir automáticamente `flujo_actual.tramo_id`, sin selector de
   envío ni de `RECOLECCION`/`ENTREGA`.
3. Mantener como máximo una polilínea en el mapa: limpiar la anterior y dibujar
   únicamente `tramos[flujo_actual.tramo_id].polilinea_codificada`, decodificada.
4. Si no hay línea o `sin_desplazamiento=true`, mostrar el punto y el mensaje
   correspondiente, sin rescatar una línea vieja ni hacer otro POST.
5. Después de completar una etapa o recibir una asignación, refrescar `mi-ruta`.
   Seguir siempre el nuevo `flujo_actual`, sin conservar una etapa elegida por
   el usuario ni adelantar acciones de otro servicio.
6. Seguir actualizando el marcador mediante GPS y enviando puntos al backend;
   conservar el manejo de `llegadas_detectadas`/`llegada_actual`.
7. Mantener atribución «Google Maps», aviso de motocicleta y geometría solo en
   el mapa Google integrado. No sumar estas líneas como kilómetros realizados.

### Persistencia, consumo y verificación

Se amplía la máscara de la misma petición con
`routes.legs.polyline.encodedPolyline`; no se hacen peticiones por envío.
[Documentación oficial de polilíneas por leg](https://developers.google.com/maps/documentation/routes/traffic_on_polylines?utm_campaign=gmp_git_agentskills_v1).
El proveedor valida cantidad y formato de legs antes de publicar la respuesta.
No se solicitan ni persisten métricas individuales, instrucciones ni cuerpos crudos.
La nueva geometría no se obtiene recortando la línea global ni se mezcla con
una ruta generada por otro proveedor.

Migración `rutas.0003_polilineas_por_tramo` aplicada por separado en ambas bases:
solo añade una lista JSON de geometrías temporales. No cambia solicitudes,
asignaciones, GPS, sesiones, permisos ni historial de paradas. Las líneas nuevas
comparten la caducidad de 24h (configuración existente) y la limpieza existente;
esta también recupera líneas por tramo si la global ya estaba vacía.
No se crean ni modifican tareas Windows para este cambio.

22 pruebas nuevas y suite completa: **563 casos, 542 aprobados, 21 omitidos
por requerir PostgreSQL**, semilla 3403. check, dry-run de migraciones y
dependencias correctos. Sin consultas Google reales, sin cambios de claves,
IP, hosts, puertos o frontend durante el ajuste del backend. La integración
Flutter se registra por separado al final de esta sección.
Comprobación real en Corporate, con transacción PostgreSQL READ ONLY y proveedor
bloqueado: GET mi-ruta200. Su cálculo vigente anterior informa
requiere_actualizar_desglose=true (un intento previo); no se actualizó ni se
consumió otra consulta para rellenarlo. Salud Corporate200. Solo se imprimieron
contadores/flags, no coordenadas, polilíneas ni secretos.

Revisión de cumplimiento Google Maps Platform aplicada: geometría temporal
sin métricas persistidas, sin entrenamiento IA, atribución conservada y
sin nuevos productos ni SDKs. Contexto operativo Honduras; revisar condiciones
regionales si la facturación fuera EEA. Implementación propia: no se copiaron
fragmentos de código de Google. El cálculo real puede generar costos; para
prototipos existe [Maps Demo Key](https://mapsplatform.google.com/maps-demo-key?utm_campaign=gmp_git_agentskills_v1), no destinada a producción.
Mantener la clave del backend privada y restringida a Routes API/servidor,
separada de la clave Android. No enviar una clave privada a Flutter.
El uso está sujeto a los [términos Google Maps Platform](https://cloud.google.com/maps-platform/terms?utm_campaign=gmp_git_agentskills_v1).
Los fragmentos de código de origen Google, si se utilizan, se ofrecen tal cual
bajo [Apache2.0](https://www.apache.org/licenses/LICENSE-2.0); esa licencia cubre
solo esos fragmentos, no todo VitaGo. El propietario debe revisar y probar
seguridad y cumplimiento de las condiciones aplicables. Restricciones de claves:
[documentación oficial](https://docs.cloud.google.com/api-keys/docs/add-restrictions-api-keys?utm_campaign=gmp_git_agentskills_v1).

### Integración de este frontend (2026-10-23)

Se consumen todos los campos de desglose. Desde 0.36.0 el mapa sigue únicamente
`flujo_actual.tramo_id`, sin selectores de envío ni de etapa.
Conserva geometrías reutilizadas de versiones calculadas anteriores cuando
el backend informa que siguen vigentes; no suma su longitud como GPS real.
Sin desglose o sin tramo no utiliza la línea global como alternativa.

Las paradas futuras no ofrecen acciones; la próxima parada operativa
depende del backend. Tras una foto exitosa se refresca
el servicio y se muestra el tramo actual. Sin servicios se vuelve a espera. La actualización
de caché anterior requiere confirmación explícita y usa `reintentar=true`.
No hay nuevos endpoints, recálculos automáticos ni cambios de GPS o conexión.

Se conserva la atribución y el aviso suministrado por el servidor está
disponible bajo «Información del mapa», sin restituir un aviso permanente.
El panel automático se verifica en móvil angosto, paisaje, tema oscuro y texto
ampliado. Las pruebas usan geometrías sintéticas, no consultas Google reales;
queda pendiente comprobar el renderizado nativo con una ruta real en el teléfono.

## Orden estable por cercanía GPS (0.35.0, 2026-10-23)

### Endpoint y compatibilidad

`GET /api/v1/rutas/mi-ruta/` conserva permisos, campos, estados HTTP y estructura
de `paradas`, `proxima_parada`, `llegada_actual` y `ruta_vial.tramos`. Ahora devuelve
`"orden_tipo": "CERCANIA_GPS"`. Es la **estrategia configurada**, no una afirmación
de que todos los servicios se hayan ordenado usando GPS: puede existir respaldo
sin GPS, precedencia operativa u orden anterior conservado. `ASIGNACION` queda
como valor histórico compatible; Flutter debe aceptar el valor nuevo.

No hay endpoint ni parámetros nuevos para ordenar; Flutter no envía posiciones,
orden, distancia o prioridad a este GET. La posición usada es un registro GPS
propio ya validado por el backend, no la ubicación de otro motorista.

### Reglas de planificación

1. Se trabaja sobre solicitudes/asignaciones **activas del motorista**. No cambia
   quién recibe la asignación, el máximo cinco ni sus bloqueos de concurrencia.
2. Para el primer servicio elegible se compara distancia Haversine desde el GPS
   al origen si aún falta recoger; al destino si el paquete ya está recogido.
   Los siguientes se eligen desde el destino del servicio anterior, no siempre
   desde el GPS inicial. Empates: fecha de asignación/creación e identificador.
3. Cada servicio mantiene juntas sus etapas pendientes: recolección y después
   entrega. No se mezclan paradas de otros servicios entre ambas en el plan.
4. Se fija delante el servicio iniciado (`GOING_TO_PICKUP`, `AT_PICKUP`,
   `PICKED_UP`, `IN_TRANSIT` o `AT_DESTINATION`). Si datos previos contienen varios
   iniciados, se conserva primero el que preceda en el orden guardado; sin orden,
   antigüedad. Los demás siguen las reglas del plan restante.
5. Un `PRIORITY` o `ESPECIAL` recogido conserva precedencia exclusiva incluso
   frente a un normal iniciado. No se cambia una prioridad por estar más cerca.
6. Un especial sin destino cartografiable no recibe coordenadas inventadas.
   Si aún está pendiente, puede ordenarse por su origen; después de su tramo
   desconocido los demás conservan el orden de respaldo. Recogido, conserva
   `SOLO_KILOMETROS` y no muestra trazado seleccionado.
7. Es una heurística de cercanía en **línea recta**. No representa kilómetros
   por calles, tiempo con tráfico ni garantiza el recorrido total mínimo.

### Estabilidad, GPS y versiones

El sincronizador existente, dentro de la transacción y con el motorista ya
bloqueado por el caso de uso, planifica cuando se crea la ruta o cambia el
conjunto de servicios: asignación, reasignación, cancelación, fallo o entrega.
La secuencia se guarda en las versiones existentes solamente si cambia.
Recoger o llegar sin agregar/retirar servicios conserva el orden pendiente;
no vuelve a comparar distancias por esa sola transición.

GPS válido: jornada `ACTIVA`, captura no futura, antigüedad hasta
`ANTIGUEDAD_GPS_ASIGNACION_SEGUNDOS` (local:120), precisión conocida hasta
`PRECISION_GPS_ASIGNACION_METROS` (local:50). Reutiliza estos filtros existentes,
sin nuevas variables de configuración. Sin GPS válido se respeta la secuencia
anterior y se añaden los servicios nuevos por antigüedad; si no hay secuencia,
todo usa antigüedad. Las precedencias operativas se conservan en ambos casos.

GET, movimiento GPS, selección visual de Ruta1/Ruta2 y repetir un cálculo sin
cambios de servicios **no reordenan**. Un GPS que produce una asignación nueva
sí puede provocar una nueva planificación por esa asignación, no por el punto
en sí. Versiones/rutas anteriores no se modifican ni se migran en bloque:
conservan su orden hasta el próximo cambio operativo correspondiente.

### Trazado y entrega exacta al frontend

- Usar `paradas` en el orden recibido y `proxima_parada` para la acción vigente;
  no ordenar localmente por distancia, fecha o índice de una lista antigua.
- Aceptar `orden_tipo=CERCANIA_GPS`; no usarlo para mostrar ETA o kilómetros.
- Agrupar por `solicitud_id`; desde0.36.0 seguir `flujo_actual.tramo_id` y dibujar
  únicamente ese tramo, sin selector para operar otra etapa/envío fuera de orden.
- Tras asignación, reasignación o transición, refrescar mi-ruta y reconciliar
  IDs/orden. No conservar «Ruta1» asociada permanentemente al índice anterior;
  `orden_envio` de una caché reutilizada sigue describiendo aquel cálculo.
- Si cambia el itinerario y la geometría previa no coincide con las paradas
  actuales ni su sufijo, no se publica la línea antigua ni sus tramos. Mostrar
  marcadores/sin trazado y usar el flujo **explícito** de cálculo existente si
  se desea una línea nueva, con versión y presupuestos actuales.
- GPS, GET, asignar y ordenar no consultan Google. Dibujar un trazado distinto
  puede requerir otro cálculo autorizado; este cambio no elimina ese consumo.
- Llegadas GPS siguen evaluando solamente la próxima parada del orden guardado;
  la foto sigue obligatoria y desde0.36.0 completa su etapa sin otro botón.

Implementado en el backend compartido Corporate/Network, conservando aislamiento,
reglas propias, permisos y conexiones. Sin cambios en Flutter, .env, claves,
modelos, migraciones, tareas Windows ni datos operativos de desarrollo.

### Verificación

26 regresiones nuevas: cercanía frente a antigüedad, encadenamiento desde destino,
servicio en curso, etapas juntas, respaldo GPS, empates, exclusividad, privacidad,
reasignación, versión inmutable/rollback, diez paradas en dos SELECT, descarte de
trazado incompatible y llegada automática al primero del plan.

Suite completa aislada: **589 casos, 568 aprobados, 21 omitidos por requerir
PostgreSQL**, semilla3504. Google real bloqueado. `check`, migraciones
`--check --dry-run` y revisión de espacios correctos. Consulta Corporate real
en transacción PostgreSQL `READ ONLY`: mi-ruta200, `orden_tipo=CERCANIA_GPS`;
salud local8001:200. Sin reordenar ni modificar datos reales para la prueba.

Guía Google Maps Platform/compliance revisada: no nuevos productos ni llamadas
de optimización; se conserva la política existente de caducidad, atribución y
compatibilidad de geometrías. Código propio, sin fragmentos copiados de Google.

## Flujo automático del motorista (0.36.0, 2026-10-26)

### Comportamiento vigente

No hay oferta para aceptar/rechazar, selección de etapa ni confirmación extra
después de la foto. Corporate conserva su asignación automática y Network su
mecanismo de asignación. Una vez asignado, ambos utilizan este flujo, sin
mezclar sus bases, sesiones, configuración ni alcances:

1. Solo el **primer servicio** se activa: `ASSIGNED→GOING_TO_PICKUP`. Los demás
   permanecen en cola, no se inician los cinco juntos.
2. GPS acredita llegada a `AT_PICKUP`; la app muestra foto de recolección.
3. Foto válida guarda evidencia, audita `PICKED_UP` y avanza a `IN_TRANSIT`
   en una transacción. El mapa pasa automáticamente a su entrega.
4. GPS acredita llegada a `AT_DESTINATION`; la app muestra foto de entrega.
5. Foto válida guarda evidencia y cambia a `DELIVERED`, cierra la asignación,
   libera cupo y programa la activación del siguiente servicio.

Inicio/cierre de jornada y disponibilidad siguen como antes: no se inician
jornadas ni se levanta una pausa por iniciar sesión o abrir el mapa. Durante
un servicio normal, el motorista solo toma/envía las fotos; el backend no puede
tomarlas por él. GPS acredita llegada, no transferencia física del paquete.
Enviar la foto es ahora la acción de confirmar la etapa y debe rotularse así.

### Activación, seguridad y recuperación

Se programa después del commit al asignar/reasignar, cerrar un servicio, iniciar
jornada, volver a AVAILABLE y recibir/reintentar GPS. Respeta bloqueos en orden
solicitud→motorista→jornada y vuelve a verificar el primer servicio. Solo ejecuta
`ASSIGNED→GOING_TO_PICKUP` o recupera `PICKED_UP→IN_TRANSIT`; repetirla no duplica
eventos. `aceptada_en` existente representa esta activación, no aceptar una oferta.

Exige usuario/perfil/rol operativos, motocicleta activa, estado AVAILABLE/ON_ROUTE,
jornada activa y GPS propio vigente de esa jornada, con los filtros existentes.
Sin GPS o con pausa/offline/fuera de servicio espera, sin aceptación manual.
Corporate conserva su corte diario del servidor. El próximo GPS válido recupera
activaciones pendientes/fallidas. GET mi-ruta sigue siendo **solo lectura**.

Capturas anteriores al inicio automático no acreditan una llegada retroactiva;
se mantiene la prueba de permanencia y sus tiempos del servidor. Se conservan
orden por cercanía, prioridad/exclusividad, máximo cinco y bloqueo de cupo.
Los inicios manuales compatibles tampoco pueden saltarse el servicio vigente.

Fotos operativas requieren autor/asignación correctos, etapa permitida, permisos
de evidencia **y transición**, jornada/día válidos y archivo verificado. No hay
booleano JSON para evitar controles: `automatismo` es interno, no se toma del
cliente. Los eventos añaden `automatismo.fuente=ACTIVACION_SERVICIO` al iniciar;
por foto usan fuente EVIDENCIA y su `evidencia_id`. Fechas oficiales del servidor.

Si falla archivo, permiso, transición o auditoría, se revierten etapa, evidencia
y eventos nuevos y se compensa solo su archivo. No se borran históricos.
`FOTO_INCIDENCIA` no recoge/entrega. Entregar no levanta pausa/offline/fuera de
servicio: el siguiente espera a que el motorista esté habilitado. Un especial
pausado no puede iniciar su movimiento mediante una foto.

### GET mi-ruta: nuevo campo flujo_actual

Los campos anteriores se conservan. Este objeto funciona aunque Google no esté
configurado o falte polilínea; no usar el estado del trazado para inferir etapa.
Ejemplo ficticio del objeto `flujo_actual` tras llegar a recolección:

```json
{
  "modo": "AUTOMATICO",
  "requiere_aceptacion": false,
  "permite_elegir_etapa": false,
  "solicitud_id": "40000000-0000-0000-0000-000000000001",
  "tipo_parada": "RECOLECCION",
  "estado": "AT_PICKUP",
  "tramo_id": "40000000-0000-0000-0000-000000000001:RECOLECCION",
  "pantalla": "RECOLECCION",
  "evidencia_requerida": "FOTO_RECOLECCION",
  "requiere_finalizacion_especial": false
}
```

| Situación | pantalla | evidencia_requerida |
|---|---|---|
| Sin servicios | SIN_SERVICIOS | null |
| ASSIGNED / GOING_TO_PICKUP | MAPA | null |
| AT_PICKUP | RECOLECCION | FOTO_RECOLECCION |
| PICKED_UP pendiente de recuperación / IN_TRANSIT normal | MAPA | null |
| IN_TRANSIT especial sin destino GPS | FINALIZAR_ESPECIAL | null |
| AT_DESTINATION | ENTREGA | FOTO_ENTREGA |

Sin servicios, `solicitud_id`, `tipo_parada`, `estado` y `tramo_id` son null;
banderas false. `tipo_parada` es RECOLECCION, ENTREGA o ENVIO_ESPECIAL.
La etapa corresponde a la próxima parada real, no a una selección del motorista.

### POST evidencias: avance incluido

Misma URL multipart/form-data, permisos y formato de imagen. Respuesta201 y
lecturas de evidencia añaden `estado_solicitud`: estado **actual** al consultar,
no estado histórico al tomar la fotografía. Ejemplo ficticio completo:

```json
{
  "id": "60000000-0000-0000-0000-000000000001",
  "solicitud_id": "40000000-0000-0000-0000-000000000001",
  "estado_solicitud": "IN_TRANSIT",
  "repartidor_id": "10000000-0000-0000-0000-000000000001",
  "tipo": "FOTO_RECOLECCION",
  "tipo_contenido": "image/png",
  "tamano_bytes": 1024,
  "latitud": "14.000000",
  "longitud": "-87.000000",
  "capturada_en": "2026-10-26T15:00:00Z",
  "notas": null,
  "archivo_disponible": true,
  "creado_en": "2026-10-26T15:00:00Z"
}
```

Foto entrega devuelve `estado_solicitud=DELIVERED`. Tras201 consultar mi-ruta
para recuperar siguiente pantalla/servicio y actualizar detalle/listados.
NO enviar después `PICKED_UP`, `IN_TRANSIT` o `DELIVERED` desde Flutter.

No hay clave pública de idempotencia de fotos. Ante respuesta perdida, consultar
detalle/mi-ruta/evidencias antes de reenviar. Reenviar cuando la etapa ya avanzó
responde400 bajo `tipo`, sin duplicar evidencia ni transiciones; no es conexión.
Error de orden:400 `estado_destino`; permisos:403. Archivo400 y demás controles
de propiedad/validación se conservan. No hacer reintentos ciegos de estos POST.

### Excepción de los envíos especiales

Recolección especial sí usa GPS/foto. La foto abre movimiento exclusivo y sigue
a IN_TRANSIT. Al no existir coordenadas de destino, GPS no puede saber que terminó.
Con `requiere_finalizacion_especial=true`, conservar solo «Finalizar encargo»:
POST transiciones a AT_DESTINATION desde IN_TRANSIT. Después se envía FOTO_ENTREGA
y el backend finaliza automáticamente, cerrando su movimiento.

Enviar previamente la cola GPS y conservar el protocolo de confirmación de
sesiones/medición especial existente. No se inventan kilómetros ni un destino.

### Mensaje exacto para implementar en Flutter

1. Eliminar aceptar/rechazar, botones normales de inicio/confirmación y selectores
   de envío/recolección/entrega. No son pasos del motorista.
2. Consumir `mi-ruta.flujo_actual` y abrir su pantalla. MAPA sigue únicamente
   `flujo_actual.tramo_id`; sin geometría compatible mostrar ubicación sin
   rescatar líneas anteriores. No ofrecer elegir otro tramo.
3. Mantener captura/envío GPS y `llegadas_detectadas`/`llegada_actual`; consultar
   mi-ruta al reanudar, tras llegada, asignación y foto. No es push.
4. RECOLECCION/ENTREGA muestran tomar/enviar la foto indicada. Tras201 refrescar
   mi-ruta: la foto ya confirmó la etapa. No llamar otra transición.
5. FINALIZAR_ESPECIAL mantiene la señal manual sin destino GPS y luego foto.
   Conservar acciones autorizadas de incidencia/fallo.
6. SIN_SERVICIOS vuelve a principal/espera. Mantener claves UUID, errores de campo,
   renovación JWT y recuperación consultando estado tras respuesta perdida.

`ruta_vial.tramos` conserva geometrías restantes por compatibilidad; el flujo
nuevo solo dibuja la vigente. No modifica proveedor, navegación giro a giro ni
cálculo explícito: automatizar etapas NO autoriza consultas/recálculos Google
automáticos ni cambia presupuestos. El reporte original corresponde al backend;
la integración móvil vigente se registra a continuación.

### Alcance y verificación

Sin modelos/migraciones, .env, puertos, IP, firewall, tareas Windows, Google ni
código Flutter modificados por este cambio. No se crearon datos de prueba en
las bases reales. 31 pruebas nuevas incluyen HTTP con commit real, recuperación,
un solo servicio activo, fotos atómicas, permisos, rollback, especiales y Network.
Suite completa:620casos, **599 aprobados y 21 omitidos por requerir PostgreSQL**,
semilla3605. Google real bloqueado. check y migraciones --check --dry-run correctos.

Comprobación adicional sobre Corporate/PostgreSQL en READ ONLY con APIClient:
mi-ruta200, flujoAUTOMATICO, pantallaSIN_SERVICIOS y banderas aceptación/selección
false. No había ruta activa ni se crearon datos para forzarla. Esta comprobación
valida Django/DB directamente, no el servidor HTTP:127.0.0.1:8001 no respondió
al revisar salud; no se inició/reinició proceso ni se cambió la conexión.

### Integración de este frontend (2026-10-26)

- `DriverRouteFlow` interpreta `flujo_actual`; sin metadatos válidos no presenta
  inicios normales ni elige una etapa por el estado de Google.
- El coordinador de navegación abre mapa/foto/finalización especial en primer
  plano, sin interrumpir otro formulario. Sin servicios regresa a espera.
  Conserva deduplicación de llegadas por cuenta/servidor y refresca al reanudar,
  recibir llegadas, avisos nuevos o GPS que recupera una activación pendiente.
- El mapa solo dibuja el ID vigente del flujo. Se retiró el componente de
  selectores y la selección por marcador; no se rescata la geometría global.
- La pantalla de foto usa una acción «Enviar foto y confirmar…». Tras201 solo
  consulta detalle/ruta/listados; nunca envía PICKED_UP, IN_TRANSIT o DELIVERED.
  Ante respuesta ambigua verifica detalle/ruta/evidencias. Si no se registró,
  requiere otra pulsación explícita para reenviar; si avanzó, solo actualiza.
- Incidencias/fallos autorizados siguen disponibles. El especial conserva
  Finalizar encargo→AT_DESTINATION y después FOTO_ENTREGA, sin otro DELIVERED.
  Sus manifiestos GPS se guardan antes de la foto en almacenamiento seguro,
  aislados por API/motorista, y se confirman al cerrar/recuperar conexión sin
  borrar su cola original ni reintentar fotografías en segundo plano.
- No se modificaron backend, puertos, claves, autenticación, presupuestos Google
  ni frecuencia de captura GPS. Las pruebas simulan servicios, fotos y ubicación;
  la comprobación física de la cámara/GPS/mapa en el teléfono sigue pendiente.

Los cambios de modelos requieren hot restart (`R` mayúscula) o reinicio completo;
un hot reload puede conservar instancias anteriores sin los campos nuevos.

Verificación automatizada del frontend: **252 pruebas aprobadas**. Incluye
entrada automática al mapa, vuelta a espera tras última entrega, foto sin otro
POST de transición, recuperación de respuesta perdida, GPS apagado, finalización
especial, ubicación lenta/dobles pulsaciones y persistencia/aislamiento de
manifiestos. No son pruebas contra el
backend ni Google reales y no sustituyen la validación en el teléfono.

## Cobertura departamental y alcance de flotas (0.37.0, 2026-10-26)

### Corporate / Analiza

Para ENTRE_SUCURSALES se exige:

- Origen y destino distintos, en sucursales activas de la **misma empresa**.
- Ubicaciones activas y aprobadas para la empresa, con usos origen/destino
  autorizados; el usuario solo puede escoger un origen dentro de su alcance.
- Mismo país y departamento registrado en ambas ubicaciones.

Ciudad, municipio y colonia se conservan: no se renombran para forzar cobertura.
Pueden diferir ciudad/municipio. No se impone un radio, un máximo de km ni un
límite de duración del viaje por este cambio. La distancia GPS sigue sirviendo
para ordenar candidatos/servicios, no para prohibir traslados largos autorizados.
El límite de cinco solicitudes, prioridad, disponibilidad, jornada y cierre diario
se mantienen: permitir viajes largos no los exime de terminar dentro del día.

Ejemplos con sucursales registradas: Tegucigalpa/Comayagüela/El Zamorano se
comunican dentro de Francisco Morazán; San Pedro Sula/Choloma/La Lima dentro
de Cortés; Choluteca/San Marcos de Colón dentro de Choluteca; Danlí/El Paraíso
dentro de El Paraíso. Un departamento distinto continúa rechazado aunque
coincida el texto de ciudad. Igual nombre departamental en otro país no basta.

El comparador compartido normaliza espacios, mayúsculas y formas Unicode
canónicamente equivalentes. No adivina departamentos por ciudad/GPS ni asigna
un departamento a datos vacíos. No hace búsquedas o consultas a Google.

### Endpoints y errores

No cambian URLs, parámetros, permisos, estados de éxito ni estructura JSON:

```http
GET /api/v1/solicitudes/opciones-creacion/?empresa_id={uuid}&modalidad=ENTRE_SUCURSALES&origen_id={uuid}
POST /api/v1/solicitudes/
```

El GET devuelve los destinos del mismo país/departamento. El POST utiliza el
mismo comparador y rechaza un destino no permitido aunque se envíe directamente
su UUID desde Flutter. Las consultas SQL restringen primero empresa, país,
estado/autorización; el comparador común evita diferencias por campos de texto.

- Sin otro destino: HTTP200, `destinos: []`, `mensaje_disponibilidad`:
  `No hay sucursales de destino disponibles en el mismo departamento.`
- Sin departamento de origen: HTTP200, `destinos: []`, mensaje:
  `La sucursal de origen no tiene departamento registrado. Solicite su actualización al administrador.`
- POST sin departamento en origen: HTTP400 bajo `origen_id`.
- POST con destino sin departamento, en otro departamento/país o igual al origen:
  HTTP400 bajo `destino_id`. Autorización ausente conserva los errores existentes.
- Elegir modalidad antes de origen sigue devolviendo200, sin destinos hasta
  seleccionar un origen autorizado; no es un fallo de conexión.

EMPRESA_TRANSPORTE y ESPECIAL conservan sus reglas: no se les añade este filtro.
El especial continúa reservado a gerencia de operaciones y sin destino GPS fijo.

### Motoristas Corporate y Network

- **Corporate:** la selección y la asignación solo admiten un motorista de la
  empresa de la solicitud, con usuario/rol corporativos coherentes. En Analiza,
  los motoristas son de Analiza; no atienden empresas Network ni otras empresas.
- **Network:** los perfiles y sus usuarios tienen `empresa_id=null` y rol
  REPARTIDOR_RED de alcance GLOBAL. La selección de candidatos utiliza estos
  perfiles globales, no filtra por la empresa cliente de la solicitud. Un mismo
  motorista puede atender solicitudes de distintos clientes Network.
- El cupo Network es máximo cinco activas **en total**, no cinco por cliente.
  Prioridad, GPS y disponibilidad se conservan. No acepta motoristas vinculados
  a una empresa como si fueran globales; Corporate tampoco admite un global.
- Compartir motorista no comparte datos: cada cliente solo ve sus solicitudes
  según sus permisos. No se exponen ubicaciones o solicitudes de otros clientes.
- Las bases, sesiones, claves y permisos siguen separados. No se crea una flota
  compartida entre los dos despliegues. Tampoco se añade afiliación departamental
  de motorista ni geocercas: la pertenencia corporativa continúa siendo la empresa.

La corrección de candidatos Network no habilita todavía su creación/cotización
pública ni cambia los impedimentos existentes de ese flujo. Conserva su operación
abierta, sin aplicarle el catálogo departamental de Corporate.

### Entrega al frontend

Refrescar opciones tras escoger origen y mostrar todos los destinos devueltos.
Eliminar filtros locales por ciudad/municipio y textos que impongan misma ciudad
o un máximo de distancia. Si hay agrupación visual, puede usar los campos de
dirección existentes sin descartar destinos válidos. Mostrar el mensaje del backend
cuando falte departamento o destino. No cambian los DTO, autenticación, fotos,
flujo automático ni cálculo Google; no solicitar recálculos por esta política.

### Verificación y datos reales

25 pruebas nuevas: ciudades/municipios distintos permitidos, país/departamento
distintos rechazados, campos vacíos, normalización, distancias sintéticas largas,
estado/autorización, alcance de sucursal, independencia de las otras modalidades
y aislamiento de ambas flotas/clientes. Suite aislada: **645 casos,624 aprobados
y21 omitidos por requerir PostgreSQL**, semilla3704; proveedor Google bloqueado.
check y migraciones --check --dry-run correctos. Sin modelos/migraciones ni cambios
de IP/hosts/puertos/firewall/.env/tareas, sin escrituras de prueba en bases reales.

Comprobación Corporate con APIClient/PostgreSQL READ ONLY:34 cuentas,34HTTP200,
origen propio y destinos dentro del país/departamento. Kennedy:21 destinos
(incluye dos sucursales de prueba conservadas); La Lima:5; Danlí:1; San Marcos
de Colón:2. Solo SL-001 San Lorenzo no tiene otro destino en Valle. No se
crearon solicitudes, sesiones, GPS ni viajes para esta comprobación.

### Integración de este frontend (0.37.0)

- El formulario explica la cobertura por empresa, país y departamento, admitiendo
  otras ciudades y municipios. Se retiraron los textos que exigían misma ciudad.
- El selector ya consulta opciones al cambiar el origen usando ubicacion.id;
  conserva todos los destinos del API, sin comparar ciudad/municipio ni distancia.
  Cambiar origen borra el destino seleccionado y sus errores anteriores.
- Los mensajes de disponibilidad del servidor se muestran como información y
  mantienen deshabilitada la creación sin destino. Los errores400 de origen_id
  y destino_id se conservan junto a sus respectivos campos.
- Se revisó la asignación existente: Corporate limita candidatos a su empresa;
  Network no envía un filtro de empresa cliente. La disponibilidad y el cupo total
  los determina el backend. La creación pública Network continúa bloqueada.
- Se agregaron seis pruebas de interfaz con repositorio simulado: cambio de
  origen/ubicacion.id, destinos entre ciudades, mensajes vacíos/departamento,
  errores por campo y bloqueo Network. Todas aprobadas; no consultan bases reales.

## Datos locales: retirada de sucursales de prueba (2026-10-26)

PRUEBA-CENTRO y PRUEBA-NORTE de Analiza Corporate quedaron INACTIVO, junto con
sus ubicaciones exclusivas y autorizaciones de uso. Quedan **34 sucursales reales
activas**. Se conservan las filas e históricos; no se borraron solicitudes, GPS,
evidencias ni cuentas. Sin cambios de endpoints, DTO o permisos.

Refrescar catálogos y `GET /api/v1/solicitudes/opciones-creacion/`. Las opciones
operativas excluyen ambos puntos retirados; las 34 cuentas reales se comprobaron
en PostgreSQL READ ONLY con HTTP 200. Kennedy tiene ahora **19 destinos**, frente
a los 21 de la comprobación anterior que incluía dos puntos de prueba.

El listado administrativo puede incluir sucursales INACTIVO para trazabilidad;
respetar su estado y usar las opciones del backend al crear solicitudes.
Auditoría detallada en el documento local VITAGO_SUCURSALES_ANALIZA.md.

## Diagnóstico: envíos en la pantalla administrativa (2026-10-26)

Se reprodujo en Corporate PostgreSQL READ ONLY, con la cuenta administradora
indicada por el usuario, la petición registrada a las 15:28:

```http
GET /api/v1/solicitudes/resumen-solicitante/?empresa_id=395be863-81e1-4196-a668-b698af836653
```

Resultado: HTTP 200 y 7167 bytes, coincidentes con el registro aportado. En esa
comprobación, `total=19` y `recientes` contiene cinco solicitudes, todas creadas
por otras cuentas, incluidas tres aún activas. `entregadas_del_dia=0` y
`entregas_recientes_del_dia=[]` significan que no hay entregas terminadas ese día;
no significan que no existan solicitudes pendientes o en curso.

La cuenta conserva `solicitud.ver` con alcance global. El resumen respeta ese
alcance y limita `recientes` a cinco por diseño. No se encontró un bloqueo del
backend hacia las solicitudes de otros usuarios. El 401 seguido de renovación
200 y repetición GET 200 muestra recuperación correcta de la autenticación.

Para el listado completo de administración, usar:

```http
GET /api/v1/solicitudes/?empresa_id=395be863-81e1-4196-a668-b698af836653
```

Leer `resultados`, `conteo` y `pagina_siguiente`; recorrer las páginas necesarias.
En la comprobación devolvió las 19 solicitudes, 18 de otros usuarios. Reservar
`resumen-solicitante/` para contadores y tarjetas recientes. No imponer
`solicitada_por_id` de la sesión ni descartar resultados por creador en la vista
administrativa general; ese filtro solo corresponde a una selección explícita.
Las agrupaciones por sucursal y solicitante incluyen las 19 solicitudes.
No descartar solicitudes históricas porque su sucursal esté INACTIVO.

Pendiente contrastar el consumo/renderizado de esa pantalla en el frontend;
esta revisión no modificó su código. Pasaron las 17 pruebas de listado
administrativo y resumen diario, con Google bloqueado y sin escrituras en
PostgreSQL. No se cambiaron código del backend, permisos, datos ni contrato JSON.

## Orden automático por paradas cercanas (0.38.0, 2026-10-26)

Esta sección sustituye el orden por servicios completos de 0.35.0/0.36.0.
El backend puede intercalar recolecciones y entregas de distintas solicitudes
normales. No exige terminar un envío antes de recoger el siguiente. Cada entrega
se planifica después de la recolección de su propio paquete.

Ejemplo con coordenadas sintéticas: A recoge cerca del GPS y entrega lejos;
B recoge cerca del origen de A y entrega cerca de su propia recolección.
La secuencia puede ser **recoger A → recoger B → entregar B → entregar A**.
Una entrega de un paquete todavía no recogido nunca es la próxima operación
real: su lugar en el plan supone haber completado antes su recolección.

### Criterio y estabilidad

- El cálculo local elige la parada elegible más cercana y compara después desde
  esa parada. Usa distancia geográfica Haversine, no distancia vial, ETA ni tráfico.
  Es una aproximación por proximidad; no promete el mínimo global de tiempo/km.
- Los empates favorecen antigüedad de asignación/creación y UUID estable. Esta
  política no introduce un plazo máximo de espera ni un umbral de antigüedad.
- Conserva la parada que ya está en curso o esperando evidencia. Una asignación
  nueva puede reorganizar las paradas posteriores, sin cambiar constantemente la
  dirección que ya está siguiendo el motorista. Se libera esa parada al completarla.
- Replanifica al asignar/retirar servicios y al completar una parada, incluida una
  foto de recolección. Llegar, recibir GPS, consultar o calcular geometría no
  reordenan por sí solos. Sin GPS vigente conserva los pares solicitud/tipo del
  plan anterior; inicialmente utiliza antigüedad. Solo crea versión si cambia
  la secuencia. Las versiones anteriores permanecen inmutables.
- Un prioritario recogido sigue yendo directo a su entrega. Su recolección y
  entrega se mantienen juntas en el plan. Un especial conserva su exclusividad,
  destino textual, finalización y seguimiento de kilómetros; no inventa GPS.
- Máximo cinco solicitudes activas por motorista, pertenencia de flotas,
  permisos, departamentos Corporate y aislamiento Network permanecen vigentes.
  PICKED_UP sigue contando como solicitud activa; no libera cupo por esperar.

### Foto de recolección y activación automática

`POST /api/v1/solicitudes/{solicitud_id}/evidencias/`, con FOTO_RECOLECCION,
conserva el HTTP **201**. La foto y la transición PICKED_UP se guardan en la misma
transacción. Después, el backend evalúa la próxima parada:

- Si corresponde entregar ese paquete, avanza a IN_TRANSIT automáticamente.
- Si corresponde otra parada, la respuesta informa `estado_solicitud=PICKED_UP`.
  Significa paquete recogido y esperando su entrega, **no error ni foto pendiente**.
  La siguiente parada se activa automáticamente después del commit.
- Cuando una entrega en espera pasa a ser la próxima, PICKED_UP → IN_TRANSIT se
  activa automáticamente con las comprobaciones operativas y GPS vigentes.
- Un fallo posterior del activador se recupera con el próximo GPS. Un fallo
  dentro de la transacción revierte estado/versión/eventos y compensa el archivo
  nuevo. No modifica evidencias históricas ni duplica etapas al repetir activación.
- FOTO_ENTREGA mantiene DELIVERED y libera cupo. Fotos válidas, jornada, estado,
  permisos y llegada por GPS siguen siendo obligatorios según la etapa.

El motorista no acepta servicios ni elige recolección/entrega. El backend valida
la **solicitud y el tipo de la próxima parada** para impedir operar otra etapa,
incluso si comparte solicitud o una transición de llegada intenta saltar el orden.

### Instrucciones exactas para el frontend

1. Usar el orden de `paradas` y `proxima_parada` de `GET /api/v1/rutas/mi-ruta/`.
   No reagrupar las dos etapas de un envío ni ordenar por número de solicitud,
   asignación o `orden_envio`. Un `solicitud_id` puede reaparecer más adelante.
2. `orden_tipo=CERCANIA_GPS` se conserva; ahora la unidad de planificación es la
   parada. Los DTO y endpoints son los existentes, sin campos nuevos obligatorios.
3. Usar `flujo_actual` como única operación actual: `permite_elegir_etapa=false`,
   `requiere_aceptacion=false`. No mostrar elección/aceptación/inicio manual.
4. Tras una foto 201, refrescar mi-ruta y seguir su nuevo `flujo_actual`. Aceptar
   PICKED_UP o IN_TRANSIT tras recolección; no forzar IN_TRANSIT, reenviar foto ni
   mantener la pantalla anterior suponiendo que todavía falta recoger el paquete.
5. Dibujar únicamente el tramo que corresponde a `flujo_actual.tramo_id` cuando
   exista geometría compatible. Identificarlo por solicitud/tipo, no por índice.
   `orden_envio` solo identifica el envío dentro del cálculo, no la secuencia de
   visita; puede verse 1,2,2,1 o 1,2,1,2. `orden_parada` expresa la secuencia real.
6. Reutilizar geometría solo si el backend la publica. Si el nuevo plan deja de
   ser compatible con el cálculo anterior, no se muestran líneas antiguas. El
   cálculo explícito y sus límites existentes siguen aplicándose; esta mejora no
   agrega llamadas automáticas Google. GET/selección/GPS no consumen rutas.
7. Mantener el GPS y las llegadas automáticas. Solo la parada actual acredita
   llegada; se requieren sus fotos. Especial conserva su excepción de finalización.

### Validación

20 regresiones nuevas y actualización de expectativas anteriores por servicio.
Incluyen flujo completo con detector GPS real sobre puntos sintéticos y cuatro
fotos: recoger A, recoger B, entregar B, entregar A; precedencias, cinco servicios,
ambos modos, prioritario/especial, GPS ausente, versiones, rollback, recuperación,
repetición y asociación correcta de tramos intercalados/geometría incompatible.
La lectura de cinco servicios sigue usando dos consultas, sin N+1.

Suite aislada: **665 casos, 644 aprobados y 21 omitidos por requerir PostgreSQL**,
semilla 3802, proveedor Google bloqueado. `check` correcto y
`makemigrations --check --dry-run`: sin cambios. Sin modelos/migraciones ni cambios
de IP, hosts, puertos, firewall, .env, claves o tareas. No se modificó el frontend
ni se crearon viajes, solicitudes, GPS o evidencias de prueba en bases reales.

### Integración de este frontend (0.38.0, 2026-10-26)

- Una recolección201 con estado_solicitud PICKED_UP o IN_TRANSIT se reconoce como
  completada. Se consulta detalle/mi-ruta y se sigue la operación del nuevo flujo;
  no se fuerza IN_TRANSIT ni se vuelve a enviar foto o transición.
- La recuperación de respuesta perdida también acepta PICKED_UP: solo realiza
  lecturas si la recolección ya se registró. Un fallo al refrescar conserva la
  fotografía confirmada y vuelve a consultar, sin duplicarla.
- El modelo y el mapa existentes conservan el orden de paradas y las identifican
  por solicitud/tipo. Las pruebas verifican A-recolección, B-recolección,
  B-entrega, A-entrega, con llegada GPS simulada, cuatro fotos y cero cálculos.
  Las pruebas de geometría mantienen el rechazo de líneas incompatibles, sin
  reagrupar envíos ni recuperar una polilínea global como alternativa.
- Se incorporan los reportes del backend sobre sucursales de prueba inactivas y
  visibilidad administrativa. El formulario usa sus opciones autorizadas;
  solicitudes históricas no se descartan por estado de sucursal. El listado
  completo usa solicitudes/ y conserva paginación, empresa y permisos del API.
- Inicio mantiene Resumen de envíos (Pendientes, En progreso y Entregadas hoy),
  ya confirmado en el teléfono por el usuario. No presenta el acumulado como
  entregas diarias ni restringe el resumen a la sucursal de un rol global/empresa.
- Suite completa del frontend: **270 pruebas aprobadas**; análisis estático sin
  errores. Las pruebas usan servicios, cámara y GPS simulados. Falta comprobar
  la secuencia intercalada con solicitudes reales y GPS físico en el teléfono.

## Cantidad de tubos y temperatura de recolección (0.39.0, 2026-10-27)

**Edición individual sustituida por0.41.0:** los límites se configuran por empresa
Corporate o para toda la red Network. Los párrafos que describen PATCH por
motorista son históricos; las cantidades, temperaturas y evidencias siguen vigentes.

Aplica a **Corporate y Network**, confirmado por el usuario. Etiqueta del
formulario: **Cantidad de tubos**. El administrador configura un límite para
cada motorista, inicialmente **20**. Se mantiene además el límite de **cinco
solicitudes activas**. Ambos controles deben cumplirse; Flutter no decide el cupo.

### Creación de solicitudes

`POST /api/v1/solicitudes/` requiere `cantidad_tubos`: entero entre 1 y 2147483647.
Omitirlo, enviar null, cero, negativos o fracciones devuelve 400 asociado a ese
campo. El resto del contrato permanece: empresa, sucursal, modalidad, tipo de
servicio, ubicaciones y artículos. Ejemplo completo de entrada Corporate, con
UUID ilustrativos que deben reemplazarse por IDs reales de los catálogos:

```json
{
  "empresa_id": "395be863-81e1-4196-a668-b698af836653",
  "sucursal_id": "11111111-1111-4111-8111-111111111111",
  "prioridad": "NORMAL",
  "modalidad": "ENTRE_SUCURSALES",
  "tipo_servicio_id": "22222222-2222-4222-8222-222222222222",
  "origen_id": "33333333-3333-4333-8333-333333333333",
  "destino_id": "44444444-4444-4444-8444-444444444444",
  "cantidad_tubos": 3,
  "articulos": [{"tipo_articulo": "Tubos", "cantidad": "3.00"}]
}
```

`cantidad_tubos` es el contador operativo. `articulos[].cantidad` conserva su
significado descriptivo; no se suma por segunda vez ni se convierte a tubos.
Listado, detalle, resumen y cada parada de mi-ruta exponen `cantidad_tubos`.
Las solicitudes históricas pueden devolver null: mostrar «Sin declarar».
Este cambio no habilita la creación pública/cotización Network todavía pendiente;
su impedimento existente continúa. Su operación, motoristas y evidencias sí
quedan sujetos al mismo control de tubos y temperatura.

### Reserva, selección automática y ocupación

Los tubos se reservan desde ASSIGNED, para que dos pedidos todavía no recogidos
no consuman el mismo espacio. Cuentan ASSIGNED, GOING_TO_PICKUP, AT_PICKUP,
PICKED_UP, IN_TRANSIT y AT_DESTINATION. PENDING y estados terminales no cuentan.

- Con 18/20 comprometidos, un pedido de 2 cabe y uno de 3 no. El automático
  excluye al motorista sin cupo y busca el siguiente elegible en el orden GPS
  existente. Si ninguno puede, la solicitud permanece pendiente; no sobrecarga.
- La validación final y la reserva se ejecutan bajo la transacción y el bloqueo
  del motorista existentes. La asignación manual sin cupo devuelve **409**:
  `{"repartidor_id":["El motorista dispone de 2 tubos de cupo; la solicitud requiere 3."]}`.
  Una carrera de asignación automática vuelve a probar otro candidato.
- FULL se calcula al llegar al límite de tubos o a cinco solicitudes; no cambia
  por sí solo el estado operativo a PAUSED/OUT_OF_SERVICE. Con 18/20 sigue
  habiendo espacio para pedidos pequeños. El motorista no puede editar FULL.
- Al cancelar, fallar, entregar o reasignar, se recalcula la carga de los
  motoristas afectados. Recoger convierte reserva en carga transportada sin
  duplicar ni liberar tubos. PICKED_UP en espera sigue ocupando cupo.
- Network utiliza el cupo total del motorista entre todos sus clientes, no un
  límite por empresa. Corporate conserva flota por empresa y cobertura actual.
  Prioritarios, especiales, GPS, disponibilidad y orden por paradas se mantienen.

### Datos de carga en el perfil y catálogos de motoristas

GET repartidores, detalle, mi-perfil y disponibles añaden los siguientes campos.
Fragmento de carga de un motorista con un pedido reservado de 18 tubos:

```json
{
  "estado_operativo": "ON_ROUTE",
  "capacidad": "AVAILABLE_SPACE",
  "solicitudes_activas": 1,
  "limite_solicitudes": 5,
  "limite_tubos": 20,
  "tubos_comprometidos": 18,
  "tubos_en_transporte": 0,
  "tubos_reservados": 18,
  "tubos_disponibles": 2,
  "solicitudes_sin_cantidad_tubos": 0,
  "puede_recibir_solicitudes": true
}
```

`tubos_comprometidos` suma todas las cantidades conocidas de solicitudes activas;
`tubos_en_transporte` suma PICKED_UP/IN_TRANSIT/AT_DESTINATION; `tubos_reservados`
es la diferencia. Si hay cantidades desconocidas, esas sumas son parciales:
`solicitudes_sin_cantidad_tubos>0`, `tubos_disponibles=0`, FULL y no admite nuevas
asignaciones hasta regularizar. No presentar esas sumas parciales como carga exacta.

`GET /api/v1/repartidores/disponibles/?cantidad_tubos=3` solo devuelve perfiles
que admiten ese tamaño y cumplen las reglas habituales. El parámetro opcional
es entero positivo; sin él, busca cupo para al menos un tubo. La asignación
siempre revalida en backend, independientemente de lo mostrado en este listado.

### Configuración administrativa por motorista

```http
PATCH /api/v1/repartidores/{repartidor_id}/
Content-Type: application/json
```

```json
{"limite_tubos": 30, "motivo": "Contenedor de mayor capacidad"}
```

Requiere `repartidor.administrar` en el alcance del perfil; Network global exige
alcance global. Un motorista sin ese permiso no puede cambiar su límite.
Devuelve 200 con el perfil completo y campos de carga. El límite no puede ser
menor que los tubos ya comprometidos: 400 `limite_tubos`. Se auditan actor,
fecha y valores anterior/nuevo en el historial operativo. Aumentarlo programa
el reintento de pendientes. PATCH operativo continúa sin admitir capacidad manual.

### Corrección de cantidades y datos anteriores

```http
PATCH /api/v1/solicitudes/{solicitud_id}/cantidad-tubos/
Content-Type: application/json
```

```json
{"cantidad_tubos": 18, "motivo": "Conteo confirmado por la sucursal"}
```

Requiere `solicitud.asignar` en el alcance de la solicitud y motivo no vacío.
Devuelve 200 con detalle completo. Bloquea solicitud y motorista y registra
CARGA_ACTUALIZADA con valores anterior/nuevo y motivo. Una cantidad conocida
puede corregirse antes de recoger, sin superar el cupo; después de recoger o
terminar se rechaza con 400 `cantidad_tubos`. Respeta el día operativo vigente.

Excepción de regularización: una cantidad histórica null de una solicitud
activa todavía vigente puede completarse incluso si ya fue recogida. Se registra
la cantidad real sin inventar datos. Si revela exceso de carga, se muestra FULL
y cero disponibles; no se reduce la cifra real para hacerla caber. Las terminales
permanecen inmutables. Pendientes sin cantidad no bloquean los reintentos de
otras solicitudes conocidas. Los datos antiguos no se rellenaron con uno/cero.

### Temperatura obligatoria con la foto de recolección

`POST /api/v1/solicitudes/{solicitud_id}/evidencias/` mantiene multipart/form-data.
Para FOTO_RECOLECCION se requiere además `temperatura_contenedor_c`, número
decimal en °C con máximo dos decimales. Ejemplo de todos los campos obligatorios:

```text
tipo: FOTO_RECOLECCION
archivo: <fotografía JPEG, PNG o WebP>
latitud: 14.072300
longitud: -87.192100
temperatura_contenedor_c: 4.50
```

`notas` es opcional. No enviar `fuente_temperatura`: la establece el servidor
como MANUAL y rechaza que el cliente simule AUTOMATICA. La temperatura es un
registro por recolección, no un ajuste del perfil ni un dato reutilizable para
todas las paradas. No se exige ni admite en fotos de entrega/incidencia.

Ejemplo completo de respuesta 201, con IDs, imagen y horario ilustrativos:

```json
{
  "id": "55555555-5555-4555-8555-555555555555",
  "solicitud_id": "66666666-6666-4666-8666-666666666666",
  "estado_solicitud": "PICKED_UP",
  "repartidor_id": "77777777-7777-4777-8777-777777777777",
  "tipo": "FOTO_RECOLECCION",
  "temperatura_contenedor_c": "4.50",
  "fuente_temperatura": "MANUAL",
  "tipo_contenido": "image/jpeg",
  "tamano_bytes": 123456,
  "latitud": "14.072300",
  "longitud": "-87.192100",
  "capturada_en": "2026-10-27T08:00:00-06:00",
  "notas": null,
  "archivo_disponible": true,
  "creado_en": "2026-10-27T08:00:00-06:00"
}
```

La temperatura y su fuente también se devuelven al consultar evidencias; en
históricos sin lectura son null. Hora y actor los determina el backend. Foto,
temperatura, evento y cambio de estado son atómicos: si falla una parte no se
completa la recolección. La transición común exige foto con temperatura válida
del motorista actual y capturada después de su asignación activa. Mantiene las
llegadas GPS y el flujo automático 0.38.0: tras 201 refrescar mi-ruta, sin forzar
IN_TRANSIT si el paquete queda PICKED_UP esperando otra parada.

No se definió un rango clínico aceptable: se registra el valor manual, sin
rechazar el traslado por frío/calor ni simular alarmas sanitarias. Se rechazan
texto, NaN/infinito, exceso de decimales y valores fuera del formato decimal
±9999.99. Una lectura futura podrá tener fuente AUTOMATICA desde un adaptador
confiable del servidor; no se integró todavía ningún producto/API ni se aceptan
lecturas automáticas declaradas por Flutter.

### Migraciones y validación

Aplicadas en las dos bases locales, por separado: repartidores.0004,
solicitudes.0008 y evidencias.0002, todas carga_tubos_y_temperatura. Perfiles
existentes con límite20; cantidades/temperaturas históricas null. Se conservaron
los conteos y estados de solicitudes al migrar, evidencias, eventos, asignaciones
y GPS. Sin cambios de conexión, claves, firewall, tareas ni llamadas Google.

Suite aislada con proveedor Google bloqueado: **692 casos, 670 aprobados y 22
omitidos por requerir PostgreSQL**, semilla3903. Incluye 27 regresiones nuevas,
una de concurrencia real reservada para PostgreSQL. El usuario de conexión local
no posee CREATEDB; no se alteraron permisos para ejecutar esa prueba. check y
makemigrations --check --dry-run correctos. Lecturas reales posteriores con
APIClient/PostgreSQL READ ONLY: motoristas, disponibles, solicitudes y mi-ruta 200.
No se insertaron pedidos, GPS ni evidencias ficticias en las bases operativas.

### Entrega exacta al frontend

Agregar Cantidad de tubos a nueva solicitud; mostrar límite/carga y permitir
editar `limite_tubos` únicamente desde administración. Mostrar FULL como ocupado,
pero no bloquear pedidos de2 cuando hay2 disponibles. Consultar disponibles con
el tamaño del pedido y mostrar los errores por campo/409 sin llamarlos conexión.
Mostrar cantidades históricas desconocidas y su regularización administrativa.
En recolección pedir Temperatura del contenedor (°C) junto a la foto y enviarla
en el mismo multipart; conservarla si el POST devuelve400 para poder corregir.
Aceptar campos de temperatura null en históricos y PICKED_UP tras foto201.
Seguir el plan automático; no agregar botones para aceptar o elegir etapa.

### Integración de este frontend (0.39.0, 2026-10-27)

- Nueva solicitud pide Cantidad de tubos y envía un entero independiente de los
  artículos. Valida campo obligatorio, formato entero y rango; no convierte
  silenciosamente fracciones/negativos pegados en cantidades positivas.
- Los modelos de solicitud/parada admiten cantidades null y se muestran como
  Sin declarar en lista, detalle y operación. Las evidencias admiten temperatura
  y fuente null; su consulta muestra Sin registrar para lecturas históricas.
- Administración puede declarar/corregir cantidades desde el detalle, con
  solicitud.asignar y motivo obligatorio. No ofrece cambios de una cantidad
  conocida ya recogida ni de solicitudes terminales; la regularización histórica
  sigue validándose en el servidor, incluida su vigencia diaria.
- Flota y motoristas → Motoristas → Detalle muestra carga y límites efectivos.
  Desde0.41.0 la edición se realiza en la empresa o en configuración general de
  Network, con sus permisos propios. Ya no se envía PATCH de límites por motorista.
- El panel del motorista muestra límite/carga/ocupación de solo lectura. Si hay
  cantidades desconocidas, identifica las sumas como parciales y la regularización
  pendiente. Un perfil sin campos nuevos no recibe una carga o límite inventados.
- La asignación consulta disponibles con cantidad_tubos. Corporate conserva el
  filtro de empresa y Network los perfiles globales. No se calcula cupo en Flutter;
  se admite un candidato devuelto con exactamente el espacio necesario. El409
  conserva repartidor_id y refresca candidatos sin dejar una selección inválida.
- Recolección solicita Temperatura del contenedor (°C), con hasta dos decimales y
  normalización coma/punto, en el mismo multipart de foto/GPS. Nunca envía fuente
  ni temperatura en entrega/incidencia. Un400 del campo permite corregir sin
  perder la imagen ni la lectura; errores ambiguos conservan la verificación previa.
  Cada nueva recolección inicia su propio campo vacío, sin rango clínico ni alarmas.
- Tras201 se sigue flujo_actual, aceptando PICKED_UP/IN_TRANSIT y sin otro POST
  de transición. Se refresca también el perfil de carga tras la acción operativa.
  Se mantienen el plan por paradas, el GPS persistente, los permisos y el bloqueo
  de creación pública Network. No se modificaron backend, red o servicios Google.
- Verificación del frontend: **284 pruebas aprobadas** y análisis estático sin
  errores. Incluye multipart, cupo exacto/409 en ambos modos, permisos, null
  históricos, conservación tras400, validación numérica y pantallas pequeñas.
  Se usaron respuestas, cámara y GPS simulados; queda pendiente la prueba física
  de creación, recolección y edición administrativa con el backend real.

## Resúmenes administrativos por motorista (0.40.0, 2026-10-27)

Tres endpoints nuevos de **solo lectura**, disponibles en Corporate y Network:

| Método y ruta | Uso |
|---|---|
| `GET /api/v1/repartidores/resumenes/` | Lista paginada de resúmenes diarios por motorista. |
| `GET /api/v1/repartidores/{repartidor_id}/resumen/` | Resumen completo de un motorista. |
| `GET /api/v1/repartidores/{repartidor_id}/temperaturas/` | Lecturas de recolección del día, paginadas. |

### Permisos y alcance

Requieren conjuntamente `repartidor.ver`, `reporte.ver`, `solicitud.ver`,
`jornada.ver` y `evidencia.ver`, con alcance global o de empresa suficiente para
el perfil completo. Son reportes administrativos; no se conceden al solicitante
o motorista por ser dueños de una solicitud. Falta de permiso:403. Motorista
inexistente o fuera del alcance permitido:404. Anónimo:401.

Un alcance de sucursal no se transforma en acceso a todas las operaciones del
motorista. La lista solo contiene perfiles cuya empresa esté autorizada en todos
los permisos; los de otra empresa quedan fuera. En Network, un motorista global
`empresa_id=null` exige alcance global en esos permisos. Un administrador de una
empresa cliente no recibe un resumen que mezcle clientes ni kilómetros ajenos.
El superadministrador global sí puede consultarlo. No se exponen puntos GPS,
correos ni claves/URLs privadas de archivos.

### Filtros y fecha operativa

| Parámetro | Regla |
|---|---|
| `fecha_operativa` | Opcional, `AAAA-MM-DD`. Sin él, hoy según el servidor en la zona del motorista. |
| `empresa_id` | UUID opcional; restringe perfiles sin ampliar permisos. |
| `repartidor_id` | UUID opcional para filtrar la lista. |
| `activo` | Opcional `true`/`false`; sin él se incluyen perfiles activos e inactivos, preservando históricos. |
| `pagina`, `tamano_pagina` | Paginación estándar:20 por defecto, máximo100. |

Corporate usa la zona IANA del país de la empresa del motorista. Network usa
`TIME_ZONE` del servidor. Cada objeto informa fecha, zona y límites exactos.
Sin fecha explícita, una lista con distintas zonas puede tener fechas locales
distintas; para comparar un mismo día seleccionado, enviar `fecha_operativa`.
Se respetan cambios de horario estacional; no se toman fechas del teléfono.
Fecha inválida, formato distinto o `9999-12-31`:400 `fecha_operativa`.
Filtros desconocidos devuelven400 por campo, incluyendo `solicitada_por_id`:
este reporte es por motorista, no debe filtrarse por el usuario conectado.

Ejemplo de petición:

```http
GET /api/v1/repartidores/resumenes/?empresa_id=395be863-81e1-4196-a668-b698af836653&fecha_operativa=2026-10-27&tamano_pagina=20
```

Ejemplo **completo** de respuesta paginada. Los IDs y valores son ilustrativos:

```json
{
  "conteo": 1,
  "pagina_siguiente": null,
  "pagina_anterior": null,
  "resultados": [
    {
      "repartidor": {
        "id": "11111111-1111-4111-8111-111111111111",
        "nombres": "Motorista",
        "apellidos": "De prueba",
        "activo": true,
        "empresa_id": "395be863-81e1-4196-a668-b698af836653",
        "empresa_nombre": "Analiza"
      },
      "fecha_operativa": "2026-10-27",
      "zona_horaria_operativa": "America/Tegucigalpa",
      "periodo": {
        "desde": "2026-10-27T00:00:00-06:00",
        "hasta_exclusivo": "2026-10-28T00:00:00-06:00"
      },
      "generado_en": "2026-10-27T18:00:00Z",
      "solicitudes": {
        "asignadas": 2,
        "recolectadas": 2,
        "entregadas": 2,
        "fallidas": 0,
        "canceladas": 0
      },
      "tubos": {
        "recogidos_conocidos": 6,
        "entregados_conocidos": 6,
        "recolecciones_sin_cantidad": 0,
        "entregas_sin_cantidad": 0
      },
      "kilometraje": {
        "criterio": "CIERRE_JORNADA",
        "jornadas_cerradas": 1,
        "jornadas_con_medicion": 1,
        "jornadas_consolidadas": 1,
        "jornadas_sin_cierre_en_periodo": 0,
        "kilometros_medidos": "12.345",
        "kilometros_consolidados": "12.345",
        "completo": true
      },
      "temperaturas": {
        "lecturas_registradas": 2,
        "lecturas_con_temperatura": 2,
        "lecturas_sin_temperatura": 0,
        "minima_c": "3.50",
        "maxima_c": "4.50",
        "promedio_c": "4.00",
        "ultimas_lecturas": [
          {
            "id": "22222222-2222-4222-8222-222222222222",
            "solicitud_id": "33333333-3333-4333-8333-333333333333",
            "numero_solicitud": "SOL-PRUEBA-2",
            "temperatura_contenedor_c": "3.50",
            "fuente_temperatura": "MANUAL",
            "capturada_en": "2026-10-27T16:00:00Z"
          },
          {
            "id": "44444444-4444-4444-8444-444444444444",
            "solicitud_id": "55555555-5555-4555-8555-555555555555",
            "numero_solicitud": "SOL-PRUEBA-1",
            "temperatura_contenedor_c": "4.50",
            "fuente_temperatura": "MANUAL",
            "capturada_en": "2026-10-27T14:00:00Z"
          }
        ]
      },
      "carga_actual": {
        "tubos_comprometidos": 0,
        "tubos_en_transporte": 0,
        "solicitudes_sin_cantidad_tubos": 0,
        "solicitudes_activas": 0,
        "limite_tubos": 20,
        "limite_solicitudes": 5,
        "tubos_reservados": 0,
        "tubos_disponibles": 20,
        "capacidad": "EMPTY",
        "estado_operativo": "OFFLINE",
        "puede_recibir_solicitudes": false
      }
    }
  ]
}
```

El detalle `/repartidores/{id}/resumen/` devuelve directamente un objeto con
la estructura de un elemento de `resultados`, sin envoltura paginada. Lista
vacía:200 con `conteo=0`, ambos enlaces null y `resultados=[]`, no un error.

### Cómo interpretar los contadores

- `asignadas`: solicitudes distintas asignadas a ese motorista durante el día;
  varias asignaciones de la misma solicitud al mismo motorista cuentan una vez.
- `recolectadas` y `entregadas`: según `recolectada_en` y `entregada_en`, dentro
  del periodo, atribuidas al responsable de esa etapa en el historial. El que
  recoge puede diferir del que entrega tras una reasignación. La entrega exige
  estado DELIVERED. No se usa la fecha de creación ni solo el motorista actual.
- `fallidas` y `canceladas`: por `cerrada_en` y responsable del cierre. Un cierre
  automático FIN_DIA a medianoche pertenece al día operativo que terminó, aunque
  la tarea se ejecute después; no se desplaza al siguiente día por el retraso.
- Los contadores son hitos independientes: no sumarlos para fabricar un total
  de solicitudes únicas. Un mismo pedido puede asignarse, recogerse y entregarse
  ese día, o completar sus etapas en fechas distintas.
- Con historial existente se utiliza su responsable válido en ese instante.
  Solo los históricos sin ninguna asignación pueden usar el motorista asignado
  conocido como respaldo. No se atribuye una etapa a un nuevo motorista por
  sobrescribir el dueño actual después de haber ocurrido.
- Tubos: sumas de cantidades conocidas de los pedidos recogidos/entregados ese
  día. Los desconocidos se cuentan por separado; cero conocido con faltantes
  no significa que el transporte real estuviera vacío.
- `carga_actual` es la situación al consultar, incluso cuando el filtro es de
  una fecha pasada. No es una reconstrucción de la carga o del límite histórico.

### Kilometraje y datos pendientes

Se reutilizan mediciones persistidas de jornadas cerradas. **No se suman km por
solicitud**, evitando duplicar recorridos compartidos. Tampoco se consultan
Google, rutas viales ni miles de puntos GPS cada vez que se abre el reporte.

El criterio es CIERRE_JORNADA: la distancia íntegra se atribuye al periodo en que
cierra la jornada. Si una jornada Network atraviesa varios días, no representa
solo el desplazamiento GPS de ese último día; mostrar «Km de jornadas cerradas».
Un cierre exactamente a la medianoche final pertenece al día que termina y no
se cuenta otra vez al siguiente. Las jornadas aún abiertas al corte o que siguen
otro día se informan en `jornadas_sin_cierre_en_periodo`.

`kilometros_medidos` suma jornadas con medición disponible, aunque su calidad no
esté consolidada. `kilometros_consolidados` suma únicamente calidad CONSOLIDADO.
Sin medición, el valor es null; cero medido es `"0.000"`. `completo=true` solo
cuando hay jornadas cerradas, todas consolidadas y ninguna sin cierre en el
periodo. No convertir pendientes, históricos sin calidad o huecos GPS en km
confirmados. Consultar `/jornadas/` para el detalle de calidad existente.

### Temperaturas y consulta paginada

Los agregados utilizan FOTO_RECOLECCION y `capturada_en`, por motorista y día.
Mínimo, máximo y promedio se devuelven como string decimal con dos posiciones;
sin valores son null. Cero grados se conserva como `"0.00"`. No se diagnostican
rangos clínicos ni se emiten alarmas por el promedio. Se conserva la fuente de
cada lectura. Los históricos sin temperatura cuentan como faltantes.

`ultimas_lecturas` contiene como máximo cinco, ordenadas por captura descendente
y UUID descendente para empates. Para recorrer todas:

```http
GET /api/v1/repartidores/11111111-1111-4111-8111-111111111111/temperaturas/?fecha_operativa=2026-10-27&tamano_pagina=20
```

Ejemplo completo paginado, con una lectura histórica sin temperatura:

```json
{
  "conteo": 1,
  "pagina_siguiente": null,
  "pagina_anterior": null,
  "resultados": [
    {
      "id": "22222222-2222-4222-8222-222222222222",
      "solicitud_id": "33333333-3333-4333-8333-333333333333",
      "numero_solicitud": "SOL-HISTORICA-1",
      "temperatura_contenedor_c": null,
      "fuente_temperatura": null,
      "capturada_en": "2026-10-27T14:00:00Z"
    }
  ]
}
```

### Entrega al frontend y verificación

Mostrar una fila/tarjeta por motorista y permitir seleccionar fecha. Usar el
endpoint de lista para tabla, el de resumen para detalle y el de temperaturas
para todas las lecturas. Respetar las páginas y los valores null. Separar las
tarjetas «Actividad del día» y «Carga actual»; etiquetar el kilometraje por cierre
y mostrar su estado incompleto. No agregar datos de otras empresas en Flutter ni
inventar totales a partir de varios hitos. Mostrar avisos de permiso/vacío/400
sin convertirlos en errores de conexión. No hay cambios en el código del frontend.

34 pruebas nuevas sobre límites locales, cambio horario, reasignaciones, sumas,
datos desconocidos, medianoche/FIN_DIA, kilómetros medidos/consolidados, lectura
paginada, permisos parciales, empresa y Network global. Sin escrituras en GET,
sin consultas GPS/Google y sin N+1 al aumentar los motoristas de una misma zona.
Se corrigió además una expectativa antigua de una prueba de asignación: con
desempate de hora/UUID, el reintento puede activar cualquiera de dos pedidos del
mismo origen; se comprueba que solo uno quede GOING_TO_PICKUP.

Suite aislada: **726 casos,704 aprobados y22 omitidos por requerir PostgreSQL**,
semilla4003, proveedor Google bloqueado. check y makemigrations --check --dry-run
correctos. Comprobación real con APIClient/PostgreSQL READ ONLY: los tres nuevos
GET200, conservando datos. Sin modelos, migraciones, escrituras operativas,
cambios de conexión/.env/servidores/tareas ni consultas externas.

## Corporate de pruebas en Render (0.40.1, 2026-10-27)

Diagnóstico de integración posterior (2026-10-27): los POST móviles de16:22:16
y16:22:25 -0600 llegan y devuelven500; el log aportado no contiene traceback.
La primera comprobación se hizo en db_prueba porque así figuraba en el archivo
de entorno; esa no era la base de VitaGo. El usuario identifica vitago_corporativo
como destino correcto: verificación externa READ ONLY confirma37usuarios,
tablas de autenticación presentes e historial consistente con0migraciones pendientes.
No hace falta crear otra base ni aplicar migraciones para este ajuste.
URL_BASE_DATOS y NOMBRE_BASE_DATOS ya corregidos en .env.render.corporativo;
pendiente copiar variables a Render y reiniciar. Mantener URL pública/JSON/origen
Vercel y configuración móvil. Sin escrituras de datos ni login real durante la revisión.

### Actualización de dominios y CORS (0.40.2)

La base para la web y el móvil es `https://vitago.onrender.com/api/v1/`.
En el entorno del backend:

```env
SERVIDORES_PERMITIDOS=vitago.onrender.com
ORIGENES_WEB_PERMITIDOS=https://frontend-web-eight-self.vercel.app
```

El primero identifica al servidor de API; el segundo autoriza el origen web
completo, con HTTPS y sin barra final. CORS solo se aplica a `/api/v1/`, mediante
django-cors-headers4.9.0. Por defecto no autoriza sitios; no permite wildcard,
previews ni todos los subdominios de Vercel. Agregar varios orígenes explícitos
separados por comas si son necesarios en ese despliegue.

Web: enviar `Authorization: Bearer <token>`, sin cookies/withCredentials. Los
preflight OPTIONS admiten authorization/content-type y los métodos de API.
Las respuestas reales conservan autenticación y validación: una web autorizada
sin token sigue recibiendo401. Retry-After y Server-Timing quedan expuestos al
navegador. Clientes móviles nativos sin Origin continúan igual. CORS no es un
permiso para leer solicitudes de otras empresas ni sustituye el alcance del rol.

Sin cambios en JSON/endpoints ni migraciones.8 pruebas nuevas CORS y11 de
arranque:745casos,723 aprobados/22PGomitidos,semilla4002; check/dry-run correctos.
Archivo privado real comprobado WSGI/preflight/salud200 sin SQL/Google. Código
pendiente de publicación: importar solo env no añade CORS al servidor anterior.

Configuración privada del backend lista en `.env.render.corporativo`: copiar en
Environment de Render y completar la contraseña PostgreSQL en URL_BASE_DATOS.
No distribuir al frontend ni subir a Git. Incluye secretos nuevos de ese despliegue
y la configuración actual de Google; no modifica los entornos locales. Validada
sin conectar a PostgreSQL ni llamar Google. El código aún requiere publicación.

El módulo `config.settings.production` permite el login propio de Corporate con
`ENTORNO=PRUEBAS`, `MODO_APLICACION=CORPORATIVO` y
`PROVEEDOR_AUTENTICACION=LOCAL`. Conserva `DEBUG=False`, HTTPS, secretos de firma
y refresco independientes, roles y permisos. Corporate LOCAL con otro ENTORNO
en ese módulo se rechaza. El desarrollo local y Network conservan su comportamiento.

No cambian JSON ni rutas de iniciar-sesion, renovar o cerrar-sesion. El móvil y
la web deben usar `https://<servicio>.onrender.com/api/v1/` cuando esté desplegado;
el nombre real del servicio aún debe confirmarse. No llevan claves de Django,
JWT, Google servidor ni la URL de PostgreSQL en el cliente.

Build: `pip install -r requirements/render.txt`. Start:
`python -m gunicorn config.wsgi:application --bind 0.0.0.0:$PORT`.
Root Directory vacío si manage.py está en la raíz del repositorio. Variables y
claves requeridas en README, sección Corporate en Render para pruebas. Render
aporta su hostname exacto autorizado y el proxy HTTPS; no se usa wildcard.

La base externa db_prueba será exclusiva de Corporate, según confirmó el usuario.
No se conectó ni se aplicaron tablas/copiaron cuentas. No hay migraciones en
Build/Start; la preparación de esa base es posterior. Salud200 acredita solo
el proceso. Este cambio local aún requiere publicación en GitHub; no se realizó
commit/push ni se modificaron .env, servidores o tareas locales.

11 regresiones nuevas verifican opt-in, secretos, aislamiento de configuración
local y arranque WSGI/salud200 sin SQL ni bucles HTTPS. Suite737 casos:715 aprobados,
22 omitidos por requerir PostgreSQL,semilla4001. check y dry-run sin cambios.

## Límites compartidos de motoristas (0.41.0, 2026-10-28)

### Regla y alcance

La configuración se hace una sola vez; cada motorista tiene su propio cupo.
Si el límite de tubos es20, dos motoristas pueden llevar20 cada uno. No comparten
un fondo de20 entre ambos. Valores iniciales:20 tubos y5 solicitudes activas.

- **Corporate:** una configuración por empresa, común a toda su flota.
- **Network:** una única configuración para toda la red y todas las empresas
  clientes. Un motorista suma su carga de todos los clientes al mismo cupo.
  Los límites particulares de una empresa cliente no cambian ese cupo.

Las solicitudes activas siguen siendo ASSIGNED,GOING_TO_PICKUP,AT_PICKUP,
PICKED_UP,IN_TRANSIT y AT_DESTINATION. PENDING y terminales no cuentan. Los tubos
se reservan desde la asignación. Se conservan GPS/cercanía, prioridad, especiales,
estados operativos y demás condiciones de elegibilidad.

### Corporate: consultar o configurar una empresa

```http
GET /api/v1/organizaciones/empresas/{empresa_id}/limites-motoristas/
PATCH /api/v1/organizaciones/empresas/{empresa_id}/limites-motoristas/
Authorization: Bearer <token>
Content-Type: application/json
```

GET exige empresa.ver en su alcance. PATCH exige empresa.administrar con alcance
global o completo de esa empresa; un permiso limitado a sucursal no basta.

Ejemplo de PATCH (puede enviar uno o ambos límites):

```json
{
  "limite_tubos": 25,
  "limite_solicitudes": 3,
  "motivo": "Configuración general de los contenedores"
}
```

Respuesta200:

```json
{
  "empresa_id": "395be863-81e1-4196-a668-b698af836653",
  "alcance": "EMPRESA",
  "limite_tubos": 25,
  "limite_solicitudes": 3
}
```

El cambio aplica a todos los motoristas de esa empresa. Otra empresa conserva
su configuración. GET de una empresa en Network devuelve alcanceRED y los límites
generales; su PATCH responde400 e indica la ruta de configuración general.

### Network: consultar o configurar la red

```http
GET /api/v1/organizaciones/configuracion/limites-motoristas/
PATCH /api/v1/organizaciones/configuracion/limites-motoristas/
Authorization: Bearer <token>
```

GET requiere sesión. PATCH exige configuracion.administrar con alcanceGLOBAL;
el administrador de una empresa cliente no modifica la capacidad de toda la red.
El cuerpo de PATCH es el mismo del ejemplo anterior. Respuesta200:

```json
{
  "alcance": "RED",
  "limite_tubos": 25,
  "limite_solicitudes": 3
}
```

Este endpoint devuelve404 en Corporate. Un GET no crea ni modifica configuración.

### Validación, compatibilidad y disponibilidad

limite_tubos es un entero positivo (máximo2147483647). limite_solicitudes admite
1 a5: se conserva el máximo operativo de cinco; el administrador puede reducirlo.
motivo es opcional, máximo1000 caracteres. Debe enviarse al menos un límite;
campos desconocidos, booleanos, fracciones y valores fuera de rango producen400.
Los errores conservan limite_tubos o limite_solicitudes como claves cuando aplica.

No se permite reducir un límite por debajo de la carga comprometida de ningún
motorista afectado. Para bajar tubos con cantidades activas desconocidas se pide
regularizarlas primero. La validación no devuelve identidades/cargas de otros
clientes. Se auditan actor, fecha de servidor, alcance, valores anteriores/nuevos
y motivo. Repetir los mismos valores devuelve200 sin duplicar el historial.

GET organizaciones/empresas/ y empresas/{id}/ añaden:

```json
{
  "limites_motoristas": {
    "alcance": "EMPRESA",
    "limite_tubos": 25,
    "limite_solicitudes": 3
  }
}
```

En Network alcance esRED. Los perfiles/listados de repartidores y carga_actual
de los resúmenes conservan limite_tubos y limite_solicitudes; ahora informan los
valores compartidos vigentes. tubos_disponibles, capacidad y puede_recibir_solicitudes
se calculan con esos valores. FULL resulta de alcanzar cualquiera de los cupos
o de tener cantidades activas desconocidas. disponibles/?cantidad_tubos=N y las
asignaciones usan la misma configuración. El servidor continúa siendo la autoridad.

PATCH /api/v1/repartidores/{id}/ ya no configura límites: devuelve400 por campo
para un motorista autorizado. El dato individual antiguo permanece en la base
por compatibilidad histórica, sin gobernar cupos ni permitir edición desde API.
Su historial operativo previo se conserva. Los cálculos de carga continúan
respetando las seis etapas activas, las reasignaciones y los cierres.

Asignar/corregir carga bloquea solicitud→motorista y lee la configuración con
bloqueo compartido. Cambiar configuración toma un bloqueo de escritura compatible
con las referencias FK, sin invertir el orden con el motorista. Dos asignaciones
a motoristas distintos pueden validar límites simultáneamente; un cambio de límite
espera las validaciones en curso y vuelve a comprobar la carga ya confirmada.
Al ampliar cupo Corporate se reintentan pendientes después del commit, con las
reglas actuales. No cambia la fase de cotización/creación disponible en Network.

### Entrega al frontend y despliegue

Mover el formulario del límite desde cada motorista a configuración de la empresa
en Corporate. Para Network, mostrar una sola configuración general de red a quien
tenga el permiso global. Usar alcance y los permisos del backend para escoger
el formulario. El móvil muestra los valores efectivos que recibe; no los guarda
como configuración individual ni envía capacidad manual. Refrescar empresa,
motoristas y disponibles después de guardar. Mostrar400/403/409 con sus campos,
sin convertirlos en errores de conexión.

Migración organizaciones.0003_limites_motoristas_compartidos: dos columnas en
Empresa y tablas limites_motoristas_red/historial_limites_motoristas. Inicializa
la configuración20/5, conserva columnas y datos anteriores. Aplicada en ambas
bases locales con conteos operativos conservados. La base externa vitago_corporativo
todavía requiere esta migración antes de desplegar el código0.41.0; el prechequeo
confirma un único paso pendiente y permisos de esquema. No se aplicó DDL externo.

Verificación:18 regresiones funcionales nuevas y2 pruebas PostgreSQL específicas;
suite765 casos,741 aprobados/24 omitidos por PostgreSQL,semilla4100,Google bloqueado.
check y dry-run correctos. Además, nueve GET200 en PostgreSQL local con transacciones
READ ONLY y una comprobación real de lectores/escritor en ambos modos mediante
SELECT/bloqueos/rollback, conservando valores. Sin cambios de frontend, .env, IP,
servidores o tareas. No se realizó commit/push ni publicación de secretos.

### Integración de este frontend (0.40.0/0.41.0, 2026-10-28)

- Reportes accesibles desde Flota y motoristas y desde el detalle del motorista.
  Lista, resumen y lecturas usan sus GET dedicados, respetan páginas/inactivos y
  no envían el usuario conectado como filtro. Se exige la combinación completa de
  permisos y un alcance de empresa/global suficiente antes de consultar.
- La fecha inicial se deja vacía para usar el reloj del servidor; al abrir detalle
  o temperaturas se conserva la fecha y la zona recibidas. El usuario puede elegir
  fecha, empresa autorizada y estado activo/inactivo. Los errores de fecha no se
  presentan como conexión. Los hitos no se suman como un total de pedidos únicos.
- Se separan Actividad del día, Tubos del día, Km de jornadas cerradas,
  Temperaturas del día y Carga actual. Null no se convierte en cero, los tubos
  desconocidos se marcan como parciales y el kilometraje muestra consolidación y
  jornadas sin cierre. Las lecturas mantienen la fuente y no generan alarmas clínicas.
- Corporate: Empresas → empresa → Cupos de motoristas. Network: Inicio → Cupos
  de Network para el permiso global correspondiente. La consulta de una empresa
  Network es de solo lectura; la edición general utiliza la ruta de red.
- El formulario muestra alcance/valores recibidos, valida tubos positivos y
  solicitudes1–5, acepta motivo opcional hasta1000 y envía solo límites modificados.
  Guardar actualiza empresa, motoristas, disponibles, solicitudes, resumen y ruta.
  Los errores400/403/409 conservan campos y valores propuestos para corregir.
- Se retiraron la vista y todos los métodos de edición individual de límites por
  motorista. La carga efectiva del perfil continúa como lectura. Cantidad de
  tubos, temperatura, evidencias, GPS y flujo automático de paradas se conservan.
- Se conserva config/corporate.render.json y la URL pública. El frontend no cambia
  variables privadas, bases, servidores ni migraciones. Según el reporte del
  backend, antes de probar0.41.0 en Render se debe publicar el código y aplicar
  organizaciones.0003_limites_motoristas_compartidos en vitago_corporativo externa.
- Verificación: **310 pruebas frontend aprobadas**; análisis estático sin errores.
  Se incluyen permisos, endpoints, paginación, fechas, null/cero, campos de error,
  cupos por alcance y reportes en móvil angosto/paisaje, texto ampliado y tema oscuro.
  Las pruebas usan respuestas simuladas; no acreditan despliegue ni migración remotos.
  Requiere hot restart/reinicio completo para cargar los nuevos modelos y pantallas.

## 0.42.0 — Jornada diaria y almuerzo (2026-10-29)

Corporate y Network usan la fecha y hora operativa del servidor. Solo se permite
una jornada por motorista y fecha operativa, incluso si termina temprano. Desde
las 22:00 no se puede iniciar ni retomar la jornada, asignar servicios u operar
rutas vencidas. El cierre del servidor marca los servicios pendientes como
`PICKUP_FAILED` o `DELIVERY_FAILED` con `motivo_cierre=FIN_DIA`.

`GET /api/v1/jornadas/activa/` conserva `jornada` (objeto o null) y añade
`hora_servidor`, `fecha_operativa`, `zona_horaria_operativa`,
`cierre_programado_en`, `jornada_iniciada_hoy`, `puede_iniciar_jornada` y
`cierre_pendiente`. La aplicación respeta esos indicadores; una jornada vencida
pendiente de mantenimiento puede seguir presente con `puede_operar=false`.
El reloj del teléfono no determina el corte operativo.

Los objetos de jornada añaden `fecha_operativa` y `cierre_programado_en`
(nullable en registros antiguos), `puede_operar`, `en_almuerzo` y `almuerzos`.
Cada intervalo contiene `id`, `iniciada_en`, `finalizada_en` (nullable),
`finalizada_por_id` (nullable) y `motivo_cierre`. `puede_operar=false` durante
almuerzo o jornada vencida; el estado real de la jornada sigue siendo necesario
para saber si está finalizada.

| Método | Ruta | Cuerpo | Respuesta |
|---|---|---|---|
| POST | `/api/v1/jornadas/{jornada_id}/almuerzo/iniciar/` | `{}` | 200, jornada actualizada |
| POST | `/api/v1/jornadas/{jornada_id}/almuerzo/finalizar/` | `{}` | 200, jornada actualizada |

Bearer y `repartidor.actualizar_estado`; solo el dueño de la jornada. Para
iniciar debe estar `AVAILABLE`, sin trabajos pendientes ni asignaciones o
movimientos especiales activos. El backend lo pone `PAUSED` y lo excluye de
asignaciones. El regreso manual antes de las 22:00 lo pone `AVAILABLE` y puede
activar asignaciones pendientes. No simular regreso con PATCH de estado ni
abrir otra jornada. Cierre de jornada o cambio autorizado a `OFFLINE` /
`OUT_OF_SERVICE` cierran el intervalo con su motivo.

Validaciones 400 llegan por campo `almuerzo`, `jornada` o `estado_operativo`;
también hay 403 sin permiso y 404 para jornada ajena/inexistente. No enviar
fechas ni parámetros adicionales en estas acciones. Tras cada POST correcto,
refrescar jornada, perfil, solicitudes y ruta.

`GET /api/v1/repartidores/?en_almuerzo=true|false` admite la paginación y
filtros existentes. El listado, detalle y perfil propio añaden
`en_almuerzo: bool` y `almuerzo_iniciado_en: timestamp|null`. El valor `PAUSED`
por sí solo no significa almuerzo. Administradores pueden consultarlo, pero no
iniciar/finalizar almuerzos ajenos.

El cliente conserva la cola GPS histórica previa al corte. En Render todavía
faltan publicar el backend 0.42.0, aplicar con autorización la migración
`jornadas.0004_horario_diario_almuerzos` y configurar por modo el comando
periódico `cerrar_operaciones_vencidas` cada minuto. El frontend mantiene
compatibilidad de lectura con respuestas anteriores hasta ese despliegue.
