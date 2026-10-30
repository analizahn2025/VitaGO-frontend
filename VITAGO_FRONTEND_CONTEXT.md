@# FRONTEND_CONTEXT.md

## 0. Identidad del producto

### Contrato 0.43.0 y 0.44.0 (2026-10-30)

- Un `503` con `codigo=CIERRE_OPERATIVO_PENDIENTE` y `Retry-After` indica que el
  servidor prepara el cierre operativo. La app muestra la espera y permite
  reintentar después; no lo trata como contraseña incorrecta o fallo de red.
- Corporate crea solicitudes con `cantidad_tubos` y `cantidad_frascos` (enteros
  no negativos, al menos uno positivo); no envía `articulos`. La historia previa
  se lee desde `articulos_historicos` y un frasco `null` es «No registrado».
- Asignación, ruta, flota, límites y reportes manejan cupos independientes.
  Administración corrige la carga mediante `PATCH solicitudes/{id}/carga/`.
- El contrato fuente indica que las migraciones 0.44 solo están aplicadas en
  bases locales. El backend externo necesita migración y publicación coordinada
  antes de probar la creación nueva con este APK.

### Jornada diaria y almuerzo (contrato 0.42.0)

- Jornada activa usa `GET jornadas/activa/` con hora oficial del servidor,
  `puede_iniciar_jornada`, `cierre_pendiente` y `puede_operar`. Desde las 22:00
  se bloquean las acciones visibles y la jornada de hoy no se puede reiniciar.
- Motorista inicia y finaliza almuerzo mediante dos POST `{}` bajo su jornada.
  Después se actualizan jornada, perfil, solicitudes y ruta. La pausa genérica
  `PAUSED` se distingue por `en_almuerzo`.
- Los controles de almuerzo están en Cuenta > Mi jornada, con confirmación
  antes de iniciar o regresar; la pantalla Hoy solo muestra el estado.
- Administración filtra motoristas con `en_almuerzo=true` y ve la hora de inicio.
  El detalle de jornada conserva los intervalos de almuerzo.
- Render todavía requiere despliegue backend 0.42.0, migración `jornadas.0004`
  y tarea de cierre periódico; la app tolera respuestas 0.41.0.

- Nombre del producto: **VitaGo**.
- App interna: **VitaGo Corporate**.
- App externa: **VitaGo Network**.
- Las dos apps salen del mismo proyecto móvil y cambian por flavor/configuración.


## 1. Objetivo

Crear una aplicación móvil VitaGo para logística y delivery del sector salud.

Se generarán dos aplicaciones/despliegues desde el mismo código fuente:

- Corporate
- External

Ambas comparten gran parte de la UI y lógica móvil, pero cambian mediante configuración/flavor/variables de entorno.

La app debe ser rápida, operativa y pensada para trabajo diario en calle.

---

## 2. Versiones

### Corporate

Uso interno de la empresa principal.

Características:

- login corporativo;
- riders propios;
- sucursales propias;
- sin precios;
- mantenimiento de flota;
- operación privada.

### External

Uso para empresas externas del sector salud.

Características:

- login propio;
- empresas externas;
- riders compartidos;
- tarifas por km;
- administración de lugares autorizados;
- tracking de solicitudes.

---

## 3. Configuración por build

Conexión pública Corporate de pruebas: https://vitago.onrender.com/api/v1/.
Se ejecuta con --dart-define-from-file=config/corporate.render.json, flavor
corporate y lib/main_corporate.dart. AUTH_PROVIDER=LOCAL, según el entorno de
pruebas publicado por backend. No se copian secretos de Render/PostgreSQL al
cliente. Cambiar de servidor requiere detener y ejecutar Flutter con los nuevos
argumentos; no se actualiza la URL mediante hot reload/restart. El endpoint
salud solo verifica el proceso HTTP, no usuarios/tablas de la base remota.

Ejemplo conceptual:

```env
APP_MODE=CORPORATE
AUTH_MODE=CORPORATE_SSO
API_BASE_URL=https://corporate-api.example.com
FEATURE_PRICING=false
```

External:

```env
APP_MODE=EXTERNAL
AUTH_MODE=PLATFORM_AUTH
API_BASE_URL=https://external-api.example.com
FEATURE_PRICING=true
```

La app debe conocer su modo desde el inicio.

No esperar respuesta remota para saber si es Corporate o External.

---

## 4. Pantallas por rol

### Solicitante

- Inicio
- Nueva solicitud
- Mis solicitudes
- Detalle de solicitud
- Tracking en tiempo real
- Historial

#### Cupos compartidos y reportes (contratos 0.40.0/0.41.0)

- Corporate: Empresas → empresa → Cupos de motoristas. GET requiere empresa.ver;
  editar exige empresa.administrar y alcance completo de esa empresa/global.
- Network: Inicio → Cupos de Network para configuracion.administrar global.
  Se configura una sola red, no cada cliente. Consulta de empresa puede devolver
  alcance RED y es de solo lectura. El servidor conserva la validación final.
- Cupos compartidos aplicados individualmente: tubos positivos hasta2147483647,
  solicitudes1–5 y motivo opcional de hasta1000 caracteres. Se envían solo campos
  modificados, se conservan errores400/403/409 y no se fabrican valores iniciales.
  Guardar refresca empresa, perfiles, catálogos, disponibles, solicitudes y ruta.
- Se retiraron UpdateDriverTubeLimitView y todos los métodos PATCH por motorista;
  DriverProfile y DriverTubeLoad conservan los valores efectivos como lectura.
- Flota y motoristas → Reportes de motoristas; también desde el detalle de un
  motorista. Requiere repartidor.ver, reporte.ver, solicitud.ver, jornada.ver y
  evidencia.ver con alcance suficiente; una sucursal no habilita un perfil completo.
  Network global no se expone a administradores de empresas clientes.
- Reportes lista/detalle/temperaturas usan sus tres GET dedicados. Sin fecha se
  consulta el día del servidor; abrir detalle/lecturas fija fecha y zona recibidas.
  Se respetan inactivos, páginas, null y ceros. No se agrega filtro por creador.
- Actividad del día y carga actual son secciones distintas. Los hitos no se suman
  como solicitudes únicas; cantidades desconocidas se identifican como parciales.
  Km de jornadas cerradas no suman km por envío ni representan necesariamente
  el movimiento GPS de ese día. Se diferencian medición, consolidación y pendientes.
- Temperaturas muestran fuente, faltantes y cero grados; no generan diagnósticos
  ni alarmas clínicas. No se consultan GPS/Google para estos reportes.
- Render sigue en https://vitago.onrender.com/api/v1/ con config/corporate.render.json.
  Según el contrato, backend debe publicar0.41.0 y aplicar
  organizaciones.0003_limites_motoristas_compartidos en vitago_corporativo externa.
  El frontend no aplica migraciones, cambia bases ni copia secretos de Render.
- Verificación0.41.0:310 pruebas frontend aprobadas y análisis estático sin errores.
  Reportes/cupos probados con API simulada, pantallas pequeñas/paisaje y texto
  ampliado; no se verificó el despliegue remoto autenticado. Usar hot restart R.

#### Tubos y temperatura (contrato 0.39.0, cupos actualizados por0.41.0)

- Nueva solicitud requiere Cantidad de tubos, entero positivo hasta2147483647.
  No se calcula a partir de artículos. Detalle/listado/paradas muestran Sin declarar
  cuando cantidad_tubos es null. Network conserva bloqueada su creación pública.
- DriverProfile conserva límite, comprometidos, transportados, reservados,
  disponibles y solicitudes con cantidad desconocida. Los perfiles antiguos no
  reciben un límite/carga inventados. DriverTubeLoad muestra datos parciales cuando
  hay cantidades desconocidas y no ofrece controles de capacidad al motorista.
- Los límites efectivos del motorista son de solo lectura; se configuran por
  empresa/red según0.41.0. Corrección/regularización: detalle de solicitud → Declarar/Corregir cantidad de
  tubos (solicitud.asignar), con motivo obligatorio y validación final del backend.
- La asignación consulta disponibles con cantidad_tubos del envío. No limita
  candidatos Network por empresa cliente ni deriva cupo localmente. Un409 conserva
  el mensaje por repartidor_id, actualiza candidatos y retira selecciones inválidas.
- La foto operativa de recolección solicita Temperatura del contenedor (°C),
  admite hasta dos decimales y normaliza coma a punto. Se envía junto a foto/GPS
  en el mismo multipart; nunca fuente_temperatura. Cada formulario tiene su propia
  lectura, sin valores por defecto ni rangos/alertas clínicas inventados.
- Entrega/incidencia no envían temperatura. Evidencias históricas null muestran
  Sin registrar. Un400 de temperatura conserva imagen/lectura y permite corregir;
  las respuestas ambiguas siguen verificándose antes de reenviar. El201 continúa
  siguiendo flujo_actual sin imponer IN_TRANSIT ni enviar otra transición.

#### Listado administrativo y resumen diario

- Solicitudes usa GET solicitudes/ con empresa_id del perfil cuando existe;
  interpreta resultados, conteo y enlaces de paginación. No filtra por creador
  ni añade la sucursal del perfil al listado administrativo. El backend aplica
  los permisos y el alcance efectivo; sin empresa no se inventa un filtro.
- El listado se refresca al regresar a su pestaña, reanudar la app, volver del
  detalle o crear una solicitud; conserva empresa, filtros y página vigente.
- Inicio utiliza resumen-solicitante/ para Resumen de envíos: Pendientes usa
  pendientes, En progreso usa activas y Entregadas hoy usa entregadas_del_dia.
  Los dos primeros reflejan la carga visible en esos estados, sin filtro diario;
  solo el tercero corresponde al día operativo del servidor. Los cinco recientes
  y entregas_recientes_del_dia no sustituyen el listado completo.
- El resumen no añade sucursal_id cuando el perfil tiene alcance de empresa o
  global (incluido superadministrador); la sucursal asociada no debe reducir ese
  alcance. La API sigue aplicando permisos. En depuración, resumen-inicio registra
  URL, estado, total, entregadas_del_dia, fecha operativa y cantidad de entregas
  recientes, sin cuerpos, tokens ni credenciales. Un total acumulado positivo
  puede coexistir con cero entregas del día.

#### Cobertura y flotas (contrato 0.37.0)

- Corporate ENTRE_SUCURSALES admite ciudades y municipios diferentes de la misma
  empresa, país y departamento. No se añade un límite local de distancia.
- La API decide los destinos autorizados: se consultan al cambiar el origen y se
  muestran completos, conservando sus mensajes de disponibilidad y errores por campo.
- Corporate selecciona motoristas de la empresa de la solicitud; Network utiliza
  los candidatos globales del backend sin filtrar por empresa cliente. El máximo
  de cinco servicios es total y lo controla el backend.
- La creación pública Network sigue bloqueada hasta disponer de cotización/tarifa.

### Rider

- Inicio
- Estado y capacidad
- Mi ruta
- Detalle de servicio
- Recolección
- Evidencia
- Entrega
- Incidencias
- Historial
- Jornada
- Resumen al finalizar jornada
- Mi vehículo si aplica

#### Flujo automático del motorista (contratos 0.36.0/0.38.0)

- El backend elige servicio/etapa con mi-ruta.flujo_actual. No hay aceptar,
  iniciar, confirmar después de la foto ni selectores operativos.
- DriverArrivalListener recupera el flujo al iniciar/reanudar, recibir llegadas,
  avisos nuevos o GPS que recupera activación pendiente. Presenta mapa/foto o
  finalización especial solo en primer plano y sobre una pantalla segura.
- DriverRequestActions se comparte entre mapa/detalle, con permisos de evidencia
  y transición, jornada y GPS. No habilita operaciones para otro servicio.
- Enviar FOTO_RECOLECCION puede confirmar PICKED_UP o IN_TRANSIT según la siguiente
  parada elegida por el backend; ambos significan recolección completada.
  FOTO_ENTREGA confirma DELIVERED.
  Un 201 no genera otro POST de transición. Se consulta detalle y mi-ruta,
  actualizando el mapa o volviendo a principal/espera cuando no hay servicios.
- Una respuesta perdida obliga a consultar detalle/ruta/evidencias antes de
  permitir otro envío manual. Si la foto ya avanzó, solo se refresca información.
  El fallo de refresco posterior tampoco vuelve a enviar foto ni transición.
- El especial conserva Finalizar encargo a AT_DESTINATION y luego FOTO_ENTREGA.
  Captura/envía GPS previamente y guarda el manifiesto con UUID de movimiento,
  sesiones y secuencias en almacenamiento seguro por API/motorista. Si se corta
  la conexión, confirma medición al recuperar/cerrar; no borra la cola GPS ni
  reenvía fotografías en segundo plano.
- Incidencias y fallos autorizados siguen disponibles. Las fotos de incidencia
  no confirman etapas ni permiten eludir la próxima parada.
- Nuevos modelos requieren R mayúscula/reinicio completo, no solo hot reload.

#### Orden del backend (contratos 0.35.0/0.38.0)

- Se aceptan CERCANIA_GPS y ASIGNACION sin ordenar paradas localmente. El flujo
  y proxima_parada del servidor deciden la acción vigente.
- Desde 0.38.0 la unidad es la parada: puede recoger A, recoger B, entregar B y
  entregar A. Un UUID puede reaparecer: no agrupar etapas ni deduplicar por envío.
  PICKED_UP no obliga a ir inmediatamente a su entrega ni libera cupo.
  El tramo se identifica por solicitud/tipo, no por índice u orden_envio.
- La tarjeta dice «en el orden de tu ruta»: no promete cercanía efectiva si
  se usó respaldo sin GPS ni confunde estrategia con ETA o kilometraje.
- Se conservan UUID, no índices o etiquetas de un cálculo anterior. No se
  calculan distancias en Flutter ni se cambia la planificación del backend.

#### Geometrías por tramo (contratos 0.34.0/0.36.0)

- RoadRoute conserva el desglose y las geometrías temporales restantes, pero
  el mapa solo dibuja flujo_actual.tramo_id; se retiró RouteShipmentSelector.
- Sin geometría compatible o sin desplazamiento se conserva el punto, no una
  línea global/vieja ni rectas inventadas. Origen previsto nunca sustituye GPS.
- La caché anterior sin desglose mantiene actualización manual con confirmación
  y reintentar=true; no hay cálculos por movimiento, etapa o cámara.
- Se conserva atribución y el aviso del servidor bajo Información del mapa.
  Sin mapa para un especial, solo se muestra información/kilometraje.

#### Llegada automática (contrato 0.32.0)

- Marcador personalizado (2026-10-28): el mapa utiliza la gotita en moto original
  de `assets/branding/corporate/app_icon.png` en una insignia circular de 56 dp.
  El contorno y la flecha usan el color primario configurable de cada producto.
  El logo permanece derecho; una flecha independiente indica el rumbo GPS válido
  y se oculta al detenerse (velocidad inferior a 0.5 m/s) o sin rumbo disponible.
  Los PNG se generan y reutilizan según paleta y densidad, no en cada posición.
  No cambia el contrato HTTP ni el seguimiento; no añade voz ni recálculos.
  Revisión de condiciones Google realizada para este cambio visual: se conserva
  la atribución del mapa, no se cachean datos Google ni se copian fragmentos de
  sus ejemplos. Falta verificar el aspecto y movimiento en un teléfono físico.
  Verificación del mapa (2026-10-28): 321 pruebas automatizadas aprobadas y
  análisis Dart sin incidencias, incluyendo cámara y recorte visual del trazado.
- El marcador del motorista consume cada posición del mismo stream GPS de la
  jornada, antes del filtro de cadencia y sin esperar confirmación del backend.
  El stream arranca antes de reenviar la cola y de la lectura inicial puntual;
  una lectura inicial tardía no reemplaza una posición ya recibida en vivo.
- La cámara se centra en el GPS más reciente al abrir y sigue al motorista.
  Arrastrar o ampliar el mapa pausa el seguimiento; el botón de ubicación lo
  retoma. Un toque simple no lo pausa. Las animaciones respetan movimiento reducido.
  El espacio reservado al panel inferior se ajusta a su altura para mantener
  visible la moto y la atribución del mapa.
- La geometría original y las paradas se conservan. Solo se dibuja el tramo
  pendiente: el prefijo recorrido se oculta localmente, sin hacer reaparecerlo
  por ruido GPS. Se rechaza el recorte con precisión peor que 50 m o a más de
  35 m del trazado y se limita el avance para evitar saltos en cruces cercanos.
  Se reinicia el progreso ante otro tramo/geometría. Nunca se unen puntos GPS
  fuera de la carretera para inventar líneas ni se modifica la ubicación real.
- Seguir la moto y recortar el dibujo no calcula rutas, no consulta Google ni
  fabrica llegadas por proximidad. Se mantienen la captura 5/15 s, la cola
  persistente y el envío configurado al backend. No cambia el contrato HTTP.

- El backend inicia el desplazamiento y detecta la llegada a la
  próxima parada con GPS real; Flutter no crea transiciones de llegada ni
  calcula geocercas. El destino especial sin coordenadas conserva llegada manual.
- El acuse GPS se mantiene independiente de la presentación. Sus eventos
  `llegadas_detectadas` solicitan recuperar `llegada_actual` en `mi-ruta`.
- Se comprueban jornada, asignación, parada y estado actuales antes de abrir
  el formulario de foto de recolección o entrega. La foto realiza la transición
  en el backend desde 0.36.0; recibir una llegada nunca completa el servicio.
- Solo se abre en primer plano, con GPS disponible y sin otro formulario o
  diálogo encima. Una llegada pendiente se recupera al volver a una pantalla
  segura, reanudar o recuperar conectividad. No usa push ni abre enlaces externos.
- Los eventos ya mostrados se recuerdan en memoria y almacenamiento seguro,
  separados por cuenta y URL del servidor, para no repetir la apertura.
- El mapa escucha los datos actualizados y selecciona la parada correspondiente;
  una entrega exitosa continúa con la siguiente parada sin cerrar el mapa.
- Verificación del frontend (2026-10-23): 208 pruebas automatizadas aprobadas y
  análisis estático sin incidencias. Pendiente probar llegada física con GPS real
  en un teléfono; las pruebas no hicieron llamadas a Google ni al backend real.

#### Avisos diarios (contrato 0.33.0)

- El backend decide vigencia por su día y zona `TIME_ZONE` y archiva historial.
  Flutter no borra registros, no marca leídos en lote ni filtra por fecha local.
- La campana refresca listado y conteo al abrirse, reanudar y al sincronizar
  GPS tras un fallo. En primer plano consulta cada minuto; al pasar a segundo
  plano cancela el temporizador. La siguiente consulta recoge el corte nocturno.
- El panel observa datos en vivo y reemplaza la respuesta anterior. Mientras
  consulta o falla la red, no presenta avisos remotos antiguos como actuales ni
  muestra una lista vacía falsa; ofrece carga y reintento explícito.
- Antes de navegar se marca leído para verificar vigencia. Un `404` retira el
  ID de la caché visible, actualiza lista/contador y no navega ni reintenta ese ID.
- Siguen visibles las alertas locales de problemas activos. El tablero se
  refresca también para no recrear avisos de servicios que ya cerraron.
- El número de la campana indica avisos nuevos, no tareas pendientes: abrirla
  reconoce los recibidos sin borrarlos ni enviar un POST de lectura por aviso.
  Se conservan también los avisos leídos hasta el archivado diario del servidor.
  Las alertas operativas locales no inflan este contador. La marca de vistos se
  recuerda en el dispositivo por cuenta/API, independiente de `leida` del backend;
  solo nuevos avisos recibidos después vuelven a encender el indicador.
- Verificación del frontend (2026-10-23): 226 pruebas aprobadas, incluidas las de
  refresco diario, expiración, contador de nuevos y persistencia por cuenta;
  análisis sin incidencias.
  Pendiente comprobar el corte real en el teléfono con el backend actualizado.

### Supervisor / Operador

- Dashboard
- Mapa de riders
- Solicitudes
- Asignaciones
- Detalle de rider
- Incidencias
- Rutas
- Reasignaciones

### Administrador

- Empresas
- Sucursales
- Usuarios
- Lugares
- Riders
- Vehículos
- Solicitudes
- Reportes
- Configuración

---

## 5. Flujo de nueva solicitud

El solicitante:

1. selecciona prioridad:
   - Normal
   - Prioritario
2. selecciona origen desde lista autorizada;
3. selecciona destino desde lista autorizada;
4. selecciona tipo de contenido;
5. agrega cantidad/referencia/observaciones;
6. revisa resumen;
7. confirma solicitud.

### Regla crítica

El usuario solicitante NO puede:

- escribir cualquier dirección;
- registrar un nuevo lugar;
- usar una ubicación aleatoria.

Solo administradores autorizados pueden registrar nuevos lugares.

---

## 6. Registro de lugares por administrador

Flujo:

1. buscar lugar con Google;
2. mostrar resultados;
3. seleccionar si existe;
4. si no aparece:
   - botón “¿No encuentras tu lugar?”
   - solicitar permiso GPS
   - obtener ubicación actual
   - mostrar mapa
   - permitir ajustar pin
   - completar datos
   - guardar
5. habilitar el lugar para la empresa.

Datos:

- nombre;
- tipo;
- dirección;
- teléfono;
- contacto;
- horario;
- instrucciones;
- coordenadas;
- Google Place ID si aplica.

---

## 7. Tipos de envío

### Normal

Puede agruparse con otros servicios.

El rider puede recibir nuevas asignaciones si:

- tiene espacio;
- no lleva prioritario;
- la lógica de ruta lo permite.

### Prioritario

Después de pickup:

- entrega directa;
- no puede recibir nuevas asignaciones;
- mostrar claramente que es exclusivo;
- destacar la ruta al destino;
- bloquear acciones incompatibles.

---

## 8. Inicio del rider

Mostrar:

- nombre;
- estado operativo;
- capacidad;
- servicios activos;
- siguiente parada;
- resumen de jornada.

Estados operativos:

- Disponible
- En ruta
- En pausa
- Fuera de servicio
- Desconectado

Capacidad:

- Vacío
- Con espacio
- Lleno

Capacidad debe ser fácil de cambiar.

---

## 9. Mi ruta

Mostrar lista ordenada de paradas.

Ejemplo:

```text
1. Clínica ABC
   Recolección
   Completado

2. Laboratorio Central
   Entrega
   Siguiente

3. Hospital X
   Recolección
   Pendiente
```

También mostrar mapa.

Si cambia la ruta por:
- nueva asignación normal;
- tráfico;
- cierre;
- recálculo;

la UI debe actualizarse.

---

## 10. Recolección

Pantalla debe mostrar:

- solicitud;
- origen;
- instrucciones;
- contenido esperado;
- referencia;
- botón de navegación;
- confirmar llegada;
- tomar fotografía;
- observaciones;
- confirmar recolección.

No permitir confirmar pickup sin evidencia requerida.

La evidencia debe incluir metadata del backend/GPS.

---

## 11. Entrega

Pantalla:

- destino;
- instrucciones;
- contenido;
- persona que recibe;
- fotografía;
- observaciones;
- confirmar entrega.

No permitir confirmar entrega sin fotografía.

Después de entregar, actualizar la solicitud inmediatamente.

---

## 12. Tracking para solicitante

Mientras la solicitud esté activa:

- mapa;
- rider;
- ubicación actual;
- estado;
- ETA si disponible.

Después de completar:

- dejar de mostrar tracking en tiempo real.

No exponer mapa general de riders al solicitante.

---

## 13. Control de ruta

El rider debe ver la ruta actual.

Cuando se detecte desviación:

### Advertencia

Mostrar mensaje claro:

> Te estás alejando de la ruta asignada.

No penalizar inmediatamente.

### Incidencia

Si la desviación supera parámetros configurados:

Mostrar selección de motivo:

- tráfico;
- calle cerrada;
- accidente;
- instrucción de supervisor;
- problema mecánico;
- emergencia;
- otro.

Enviar al backend.

Los umbrales vienen de configuración/API, no deben estar hardcodeados.

---

## 14. Jornada del rider

Debe existir:

- Iniciar jornada
- Finalizar jornada

Al finalizar mostrar resumen:

- servicios realizados;
- recolecciones;
- entregas;
- normales;
- prioritarios;
- km operativos;
- tiempo operativo;
- incidencias.

Regla:

No confundir km GPS total del dispositivo con km operativos.

---

## 15. Evidencias

Usar cámara.

Preferir captura directa en la app.

Evidencias mínimas:

- Pickup
- Delivery

Opcional:

- Incidencia

La UI debe impedir avanzar si falta evidencia obligatoria.

---

## 16. Empresas externas y precios

Solo External muestra tarifas.

Antes de confirmar solicitud, mostrar:

- distancia cotizada;
- tarifa;
- total;
- moneda.

Corporate nunca muestra precios.

No duplicar pantallas; usar configuración.

---

## 17. Login Corporate

La app Corporate inicia directamente con flujo corporativo.

No mostrar:

- registro libre;
- selección de tipo de empresa;
- login externo.

La app sabe desde build que es Corporate.

Después de autenticación:

- guardar token de forma segura;
- cargar perfil local;
- cargar roles/permisos;
- renderizar pantallas permitidas.

---

## 18. Login External

Pantallas:

- Login
- Recuperar acceso si se implementa
- Flujo de invitación/alta según reglas

El backend emite JWT.

Guardar tokens en almacenamiento seguro del dispositivo.

Nunca guardar contraseña.

---

## 19. Navegación por rol

La UI debe construirse según permisos.

No usar únicamente el nombre del rol.

Ejemplo:

Si el usuario tiene `request.assign`, mostrar asignación.

Si no tiene permiso, no mostrar la acción.

Aun así, el backend siempre valida.

---

## 20. Notificaciones

Preparar arquitectura para:

- nueva asignación;
- prioritario;
- reasignación;
- cambio de estado;
- incidencia;
- solicitud entregada;
- alerta de desviación;
- mantenimiento futuro si aplica.

---

## 21. Manejo offline / mala señal

Debe contemplarse desde diseño.

Prioridades:

- no perder evidencia;
- no perder cambios de estado;
- no perder eventos GPS críticos.

Posible estrategia:

- cola local;
- reintentos;
- timestamps;
- sincronización cuando vuelva internet.

No confirmar al usuario como “sincronizado” si el backend no respondió.

---

## 22. Privacidad

El solicitante solo ve tracking de sus solicitudes autorizadas.

El rider solo ve datos necesarios para ejecutar el servicio.

Evitar mostrar información clínica innecesaria.

Preferir códigos/referencias en lugar de diagnósticos o historial del paciente.

---

## 23. UI recomendada

La aplicación debe ser:

- clara;
- rápida;
- con botones grandes para uso en calle;
- con pocos pasos;
- legible bajo luz;
- sin sobrecargar con datos;
- orientada a acciones.

Para rider, priorizar:

- siguiente parada;
- navegación;
- evidencia;
- estado;
- capacidad;
- incidencias.

---

## 24. Reglas que Codex NO debe romper

1. Solicitante común no registra lugares.
2. Corporate no muestra tarifas.
3. External sí puede mostrar cotización.
4. Pickup requiere evidencia.
5. Delivery requiere evidencia.
6. Prioritario bloquea nuevas asignaciones.
7. Rider lleno no recibe servicios.
8. Tracking de cliente termina al cerrar su solicitud.
9. Kilómetros de jornada son solo operativos.
10. Umbrales de desviación son configurables.
11. Corporate y External salen del mismo código.
12. La app conoce su modo desde el build.
13. La UI nunca reemplaza la autorización del backend.
