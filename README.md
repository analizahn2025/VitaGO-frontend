# VitaGo Mobile

Aplicación Flutter compartida por **VitaGo Corporate** y **VitaGo Network**.

## Arquitectura

El código se organiza por funcionalidades con una separación MVC extendida:

```text
lib/
├── app/                         # Arranque, configuración, rutas y tema
├── core/                        # Red, errores y almacenamiento transversal
├── features/
│   └── authentication/
│       ├── controllers/         # Estado y acciones de la interfaz
│       ├── models/              # Modelos tipados
│       ├── providers/           # Inyección de dependencias
│       ├── repositories/        # Coordinación y reglas de datos
│       ├── services/            # API y almacenamiento de sesión
│       └── views/               # Pantallas
└── main_*.dart                  # Entradas por producto
```

Las vistas no consumen HTTP ni almacenamiento directamente. El flujo esperado
es vista → controlador → repositorio → servicio.

## Configuración

`API_BASE_URL` es obligatoria y debe incluir la ruta `/api/v1/` final.

### VitaGo Network

```powershell
flutter run --flavor network -t lib/main_external.dart --dart-define=API_BASE_URL=https://api.example.com/api/v1/
```

Identificador Android: `com.vitago.network`.

### VitaGo Corporate

```powershell
flutter run --flavor corporate -t lib/main_corporate.dart --dart-define=API_BASE_URL=https://corporate-api.example.com/api/v1/
```

Identificador Android: `com.vitago.corporate`.

La integración corporativa no solicita credenciales locales. Su proveedor SSO
se conectará cuando se defina el mecanismo para obtener el JWT corporativo.

También existe `lib/main.dart` para herramientas que necesiten elegir el modo
mediante `--dart-define=APP_MODE=CORPORATE|EXTERNAL`.

## Validación

```powershell
dart format lib test
flutter analyze
flutter test
```

No se deben registrar tokens, contraseñas ni respuestas sensibles en logs.

## Funciones integradas

El frontend consume las funciones publicadas en
`VITAGO_API_FRONTEND.md` versión 0.6.0:

- inicio, renovación y cierre de sesiones locales;
- perfil, empresa, sucursal, roles y permisos;
- empresas y sucursales paginadas;
- creación de sucursales mediante ubicaciones aprobadas;
- usuarios paginados, roles asignables y creación de usuarios;
- tipos de ubicación, lugares por empresa, registro manual y aprobación;
- comprobación pública del proceso HTTP mediante `salud/`.

Los módulos nuevos conservan la separación por funcionalidad:

```text
features/
├── profile/
├── home/
├── organizations/
├── user_administration/
├── locations/
└── service_health/
```

La navegación y las acciones se muestran mediante permisos, pero el backend
continúa siendo la autoridad final. Los recursos fuera del alcance se tratan
como no disponibles y no se revela su existencia.

La búsqueda con Google Maps, solicitudes, riders, tracking, evidencias y
recuperación de contraseña no se muestran todavía porque sus contratos HTTP no
están publicados.
