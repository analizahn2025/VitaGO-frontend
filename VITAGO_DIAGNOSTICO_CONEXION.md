# Diagnóstico de conexión de VitaGo

## 1. Objetivo

Este documento permite diagnosticar errores de conexión entre la aplicación
Flutter de VitaGo y el backend antes de modificar código.

Aplica a:

- VitaGo Corporate;
- VitaGo Network;
- teléfonos Android físicos;
- conexiones por Wi-Fi;
- conexiones de desarrollo mediante USB.

El frontend no debe modificar el backend. Si el diagnóstico demuestra que el
problema ocurre dentro del servidor, se debe entregar la evidencia al
responsable del backend.

## 2. Error `Connection reset by peer`

Ejemplo registrado por Flutter:

```text
[VitaGo] login: dio=unknown status=none cause=HttpException causeMessage=Connection reset by peer contentType=none contentLength=none
```

Significado:

- `dio=unknown`: Dio no pudo clasificar el fallo como una respuesta HTTP
  normal.
- `status=none`: Flutter no recibió un código HTTP como `200`, `400`, `401` o
  `500`.
- `Connection reset by peer`: el servidor, el sistema operativo, el router o
  algún equipo intermedio cerró bruscamente la conexión TCP.
- `contentType=none` y `contentLength=none`: no se recibieron encabezados ni
  cuerpo de respuesta.

Este error ocurre antes de interpretar el JSON, guardar tokens o validar la
estructura de la respuesta.

## 3. Evidencia del caso del 30 de septiembre de 2026

Configuración observada:

| Elemento | Valor |
|---|---|
| Computadora | `192.168.20.171/24` |
| Teléfono | `192.168.10.233/24` |
| Backend Corporate | `0.0.0.0:8001` |
| URL Corporate por Wi-Fi | `http://192.168.20.171:8001/api/v1/` |
| Paquete Android | `com.vitago.corporate` |

Comprobaciones realizadas:

1. Windows tenía un proceso escuchando en `0.0.0.0:8001`.
2. Desde la computadora, `/api/v1/salud/` respondió `200`.
3. El teléfono pudo hacer ping a `192.168.20.171`.
4. Desde el propio teléfono, `/api/v1/salud/` respondió `200`.
5. Desde el teléfono, un POST vacío al endpoint de inicio de sesión respondió
   `400`, como corresponde por faltar correo y contraseña.
6. El binario Flutter generado contenía la URL
   `http://192.168.20.171:8001/api/v1/`.
7. El inicio de sesión real falló aproximadamente 21 segundos después de
   enviarse.

Conclusión del caso:

- La IP, el puerto, la ruta, el permiso de Internet y el uso de HTTP estaban
  correctos.
- El teléfono y la computadora estaban en subredes distintas.
- Las solicitudes rápidas funcionaban.
- La conexión del inicio de sesión se reiniciaba mientras esperaba una
  operación más lenta.
- La causa más probable era un reinicio de la conexión en la ruta entre
  subredes o un cierre desde el servidor durante el procesamiento del login.

## 4. Cómo interpretar los errores

| Registro o respuesta | Interpretación |
|---|---|
| `status=400` | Los datos enviados son inválidos o incompletos. |
| `status=401` | Las credenciales o la sesión no son válidas. |
| `status=403` | El usuario no tiene permiso. |
| `status=404` | La ruta no existe o el recurso no está disponible. |
| `status=500` | El backend produjo un error interno. |
| `status=none` + `Connection refused` | No hay un servidor escuchando en esa IP y puerto. |
| `status=none` + `Connection timed out` | El teléfono no pudo alcanzar el servidor a tiempo. |
| `status=none` + `Connection reset by peer` | La conexión se cerró antes de recibir una respuesta HTTP. |
| `200` seguido de `FormatException` | El backend respondió, pero el frontend no pudo interpretar el JSON. |
| Error de almacenamiento seguro después de `200` | El login fue válido, pero falló el guardado local de la sesión. |

## 5. Diagnóstico paso a paso

### Paso 1: confirmar la IP de la computadora

En PowerShell:

```powershell
ipconfig
```

Usar la dirección IPv4 del adaptador Wi-Fi activo. Las IP locales pueden
cambiar al reconectarse al router.

### Paso 2: confirmar que el backend escucha externamente

Para Corporate debe escuchar en:

```text
0.0.0.0:8001
```

Comprobación en Windows:

```powershell
netstat -ano | findstr ":8001"
```

Debe aparecer `LISTENING` en `0.0.0.0:8001`.

### Paso 3: probar salud desde la computadora

```powershell
Invoke-WebRequest -UseBasicParsing http://IP_DE_LA_COMPUTADORA:8001/api/v1/salud/
```

Debe responder `200` y `VitaGo Corporate`.

### Paso 4: probar desde el navegador del teléfono

```text
http://IP_DE_LA_COMPUTADORA:8001/api/v1/salud/
```

Si no abre:

- verificar que ambos equipos estén en la misma Wi-Fi;
- evitar redes de invitados;
- revisar que no exista aislamiento entre clientes;
- desactivar temporalmente los datos móviles;
- comprobar que teléfono y computadora no tengan la misma IP.

Si abre, la conectividad básica funciona.

### Paso 5: observar la terminal de Django

Al intentar iniciar sesión:

- si no aparece el POST, la solicitud no llegó al backend;
- si aparece `POST ... 200`, el backend procesó el login y el corte ocurrió al
  devolver o recibir la respuesta;
- si aparece `POST ... 400` o `401`, revisar los datos enviados;
- si aparece `POST ... 500`, entregar el error al responsable del backend;
- si el POST tarda alrededor de 20 segundos o más, revisar la duración de la
  autenticación y los límites de la red.

### Paso 6: confirmar la URL usada por Flutter

Corporate por Wi-Fi:

```powershell
flutter run --flavor corporate -t lib/main_corporate.dart --dart-define=API_BASE_URL=http://IP_DE_LA_COMPUTADORA:8001/api/v1/
```

La URL debe:

- comenzar con `http://` durante el desarrollo con Django `runserver`;
- incluir el puerto `8001` para Corporate;
- terminar en `/api/v1/`;
- no repetir `/api/v1/`;
- no incluir corchetes, enlaces Markdown ni una barra invertida final.

`API_BASE_URL` se define al compilar. Un hot reload no la actualiza. Cuando la
IP cambie, se debe detener Flutter con `q` o `Ctrl+C` y ejecutar nuevamente el
comando completo.

## 6. Desarrollo estable mediante USB

Cuando teléfono y computadora están en subredes distintas, se recomienda usar
`adb reverse`:

```powershell
C:\Android\Sdk\platform-tools\adb.exe reverse tcp:8001 tcp:8001
```

Después iniciar Corporate con:

```powershell
flutter run --flavor corporate -t lib/main_corporate.dart --dart-define=API_BASE_URL=http://127.0.0.1:8001/api/v1/
```

Flujo resultante:

```text
Aplicación Android -> USB -> computadora:8001 -> Django Corporate
```

Esto evita el router y las diferencias entre subredes.

Importante:

- `127.0.0.1` normalmente representa al propio teléfono;
- funciona contra la computadora solamente mientras `adb reverse` esté
  activo;
- el túnel puede perderse al desconectar o reiniciar el teléfono;
- no es una configuración de producción.

Para Network se utiliza el mismo procedimiento cambiando el puerto a `8000`:

```powershell
C:\Android\Sdk\platform-tools\adb.exe reverse tcp:8000 tcp:8000
```

## 7. Qué no se debe asumir

- Un `Connection reset by peer` no demuestra que la contraseña sea incorrecta.
- Un endpoint de salud correcto no demuestra que el login completo responda a
  tiempo.
- Un `200` registrado por Django no demuestra por sí solo que Flutter recibió
  correctamente toda la respuesta.
- Reinstalar la aplicación no corrige una IP equivocada ni una ruta de red
  inestable.
- Hot reload no cambia valores proporcionados mediante `--dart-define`.

## 8. Información que debe recopilarse al reportar el problema

Guardar siempre:

1. fecha y hora exactas del intento;
2. registro completo de Flutter;
3. línea correspondiente en la terminal de Django;
4. IP de la computadora;
5. IP Wi-Fi del teléfono;
6. URL usada en `API_BASE_URL`;
7. resultado de `/api/v1/salud/` desde el teléfono;
8. tiempo transcurrido antes de mostrar el error;
9. si se utilizó Wi-Fi o `adb reverse`.

Con esos datos se puede ubicar el fallo en frontend, backend o red sin realizar
cambios innecesarios.
