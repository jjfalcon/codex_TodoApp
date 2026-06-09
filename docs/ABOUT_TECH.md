# Documentacion tecnica: Formulario Acerca de

## Resumen

El formulario `Acerca de` esta implementado con un servicio en `App.Core` y una pantalla VCL modal en `App.Win`.

El nucleo se encarga de devolver la informacion de la aplicacion, marcar como `No disponible` los datos opcionales faltantes y sanitizar informacion sensible. La UI solo muestra los datos recibidos y cierra el formulario al pulsar `Aceptar`.

## Componentes

### `AppCoreAbout.pas`

Define el modelo `TAboutInfo`, el contrato `IAboutService` y la implementacion `TAboutService`.

**`TAboutInfo`** (record):

| Campo | Descripcion |
|---|---|
| `ApplicationName` | Nombre de la aplicacion |
| `Version` | Version de la aplicacion |
| `Description` | Descripcion breve del producto |
| `Copyright` | Informacion de titularidad |
| `ExecutableVersion` | Version del ejecutable |
| `OperatingSystem` | Sistema operativo |
| `Architecture` | Arquitectura o plataforma |
| `BuildDate` | Fecha de compilacion |
| `DatabasePath` | Ruta de base de datos o alias |

**`TAboutService`**:

- `Create` (sin argumentos): construye el servicio con valores reales por defecto para la aplicacion Windows.
- `Create(const AInfo: TAboutInfo)`: construye el servicio con datos inyectados, usado en tests.
- `GetAboutInfo: TAboutInfo`: devuelve la informacion ya procesada.

**Procesamiento interno (`ProcessInfo`)**:

1. Campos vacios se reemplazan por `No disponible`.
2. `DatabasePath` se sanitiza: si contiene marcadores sensibles (`password=`, `pwd=`, `token=`, `secret=`, `connectionstring=`), se reemplaza por `No disponible`.
3. Si `DatabasePath` esta vacio, tambien se reemplaza por `No disponible`.

### `AboutForm.pas`

Formulario VCL `TFrmAbout`.

Responsabilidades:

- Crear `TAboutService` con valores reales al construirse.
- Obtener la informacion mediante `GetAboutInfo`.
- Mostrar nombre de la aplicacion, version, descripcion, copyright y seccion de informacion tecnica.
- Proveer un boton `Aceptar` que cierra el formulario.

La ventana es modal y no modifica el estado de la aplicacion ni la sesion activa.

### `MainForm.pas`

Integra el boton `Acerca de` en la barra lateral izquierda, debajo del resto de opciones de navegacion.

Al pulsarlo se crea `TFrmAbout` y se muestra con `ShowModal`. No requiere permisos especiales: cualquier usuario autenticado puede abrirlo.

## Flujo de apertura

1. El usuario autenticado pulsa `Acerca de` en la barra lateral de `FMain`.
2. `MainForm.pas` crea `TFrmAbout` y lo muestra con `ShowModal`.
3. `TFrmAbout.Create` construye `TAboutService` con valores reales.
4. `TFrmAbout.LoadAboutInfo` llama a `GetAboutInfo` y actualiza los labels del formulario.
5. El usuario visualiza la informacion y pulsa `Aceptar`.
6. `TFrmAbout` cierra con `ModalResult = mrOk`.
7. El formulario se libera y `FMain` permanece en su estado anterior.

## Tests

Archivo:

- `tests/App.Core.Tests/AppCoreAboutServiceTests.pas`

Escenarios cubiertos:

- `AboutInfo_returns_application_name`
- `AboutInfo_returns_application_version`
- `AboutInfo_returns_description`
- `AboutInfo_returns_copyright`
- `AboutInfo_returns_not_available_for_missing_optional_data`
- `AboutInfo_does_not_expose_sensitive_connection_data`
- `AboutInfo_can_be_loaded_without_active_business_changes`

Los tests usan `TAboutService.Create(const AInfo: TAboutInfo)` para inyectar datos controlados sin depender del proveedor por defecto.

## Comandos de verificacion

```bat
cd tests\App.Core.Tests
dcc32 "-U..\..\src\App.Core" AppCoreTests.dpr
AppCoreTests.exe

cd ..\..\src\App.Win
dcc32 "-U..\App.Core" WindowsApp.dpr
```

## Decisiones tecnicas

- La UI no contiene reglas de negocio; solo consume datos del servicio.
- Toda la informacion se obtiene desde un servicio testeable (`IAboutService`).
- El constructor sin argumentos proporciona valores fijos para la version actual; no depende de API del sistema ni del sistema de archivos.
- Los datos opcionales faltantes muestran `No disponible` en lugar de ocultar el campo.
- Los datos sensibles se sanitizan en el nucleo, no en la UI.
- No existe proveedor separado de informacion; el servicio centraliza obtencion y procesamiento.

## Limitaciones actuales

- La version del ejecutable es fija (`1.0.0`); no se lee del binario compilado.
- No se detecta la arquitectura real del sistema.
- No se muestra fecha de compilacion.
- No hay conexion a base de datos, por lo que `DatabasePath` siempre muestra `No disponible`.
- No se muestra logo de la aplicacion.
- El formulario no esta disponible antes del login.

## Evolucion recomendada

- Leer la version desde los recursos del ejecutable si se necesita sincronizacion automatica.
- Detectar arquitectura real (x86/x64) desde el sistema operativo.
- Registrar la fecha de compilacion como constante en el codigo o como recurso.
- Agregar logo si el producto lo requiere.
- Evaluar si el formulario debe estar disponible antes del login.
