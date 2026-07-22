# Documentacion tecnica: Login

## Resumen

El login esta implementado con reglas de negocio en `App.Core` y una pantalla VCL fina en `App.Win`.

La UI recoge usuario y contrasena, invoca el servicio de autenticacion y solo abre `FMain` cuando el nucleo crea una sesion valida. Las reglas de validacion, bloqueo, sesion, roles, permisos y ultimo usuario usado quedan fuera de la UI y estan cubiertas por pruebas de consola.

## Componentes

### `AppCoreUser.pas`

Define el modelo `TUser` y el enum `TUserRole`.

Campos principales:

- `Username`
- `DisplayName`
- `PasswordHash`
- `Salt`
- `Active`
- `Role`
- `FailedAttempts`
- `Locked`

Roles disponibles:

- `urAdmin`
- `urNormal`

### `AppCoreUserRepository.pas`

Define `IUserRepository` para aislar la persistencia de usuarios.

Implementacion actual:

- `TInMemoryUserRepository`

La implementacion en memoria se usa para TDD y para el arranque actual de desarrollo. Una futura base de datos debe implementar `IUserRepository` sin cambiar los servicios de negocio.

### `AppCorePreferences.pas`

Define `ILoginPreferencesRepository` para recordar el ultimo nombre de usuario usado.

Implementacion actual:

- `TInMemoryLoginPreferencesRepository`

La contrasena no se guarda.

### `AppCoreAuth.pas`

Contiene los servicios principales:

- `TAuthService`: valida credenciales, autentica usuarios, incrementa fallos, bloquea usuarios y crea sesion.
- `TSessionService`: mantiene la sesion activa, usuario actual, rol, ultima actividad y expiracion por inactividad.
- `TPermissionService`: centraliza la comprobacion de acceso autenticado o administrador.
- `TBasicPasswordHasher`: encapsula hash y verificacion de contrasena.

Excepciones de dominio:

- `ELoginValidationError`
- `EAuthenticationError`
- `EInactiveUserError`
- `EUserLockedError`
- `ESessionRequiredError`
- `ESessionExpiredError`
- `EAccessDeniedError`

## Flujo de arranque VCL

`WindowsApp.dpr` crea `TFrmLogin` manualmente para evitar que el login sea registrado como `Application.MainForm`.

Flujo:

1. Se crea `TFrmLogin`.
2. Se muestra con `ShowModal`.
3. Si devuelve `mrOk`, se crea `TFrmMain`.
4. Se copia `FrmLogin.LoggedInRole` a `FrmMain.UserRole`.
5. Se libera el login.
6. Se ejecuta `Application.Run`.

Esto garantiza que `FMain` sea el formulario principal real tras autenticacion correcta.

## Pantalla de login

Archivos:

- `src/App.Win/LoginForm.pas`
- `src/App.Win/LoginForm.dfm`

Responsabilidades:

- Mostrar campos `Usuario` y `Contrasena`.
- Ocultar la contrasena mediante `PasswordChar`.
- Crear usuarios de desarrollo en memoria.
- Llamar a `IAuthService.Login`.
- Mostrar mensajes de error procedentes del nucleo.
- Exponer `LoggedInRole` al arranque para configurar `FMain`.

## Localizacion de textos

Los textos visibles del login se cargan desde `src\App.Win\languages.csv`.

Formato:

```csv
key,es,en
FrmLogin.Caption,Login,Login
FrmLogin.LblUsername.Caption,Usuario,Username
FrmLogin.LblPassword.Caption,Contrasena,Password
FrmLogin.BtnLogin.Caption,Entrar,Sign in
FrmLogin.BtnCancel.Caption,Cancelar,Cancel
```

La clave usa la nomenclatura:

```text
FormName.ComponentName.PropertyName
```

Para propiedades del propio formulario:

```text
FormName.PropertyName
```

`AppCoreLocalization.TCsvLocalizationService` lee el CSV, selecciona la columna de idioma configurada y usa `es` como fallback. `AppWinLocalization.ApplyLocalization` no recorre todas las propiedades del formulario: aplica solo las claves del CSV que empiezan por el nombre del form actual.

Configuracion:

```ini
[Localization]
Language=es
File=languages.csv
```

El arranque en `WindowsApp.dpr` crea el servicio de localizacion y lo aplica a `FrmLogin` tras configurar sus servicios.

Usuarios de desarrollo:

- `admin / admin123`: administrador.
- `user / user123`: usuario normal.
- `disabled / disabled123`: usuario inactivo.
- `locked / locked123`: usuario bloqueado.

## Sesion y expiracion

`TSessionService` recibe un `IClock`, por lo que la expiracion es testeable con un reloj fake.

Configuracion actual:

- Timeout: 15 minutos.
- La expiracion se calcula desde `LastActivityAt`.
- `RegisterActivity` actualiza la ultima actividad si la sesion sigue activa.
- Una sesion expirada deja de considerarse activa.

## Permisos

`TPermissionService` soporta dos requisitos:

- `prAuthenticated`: requiere sesion activa.
- `prAdmin`: requiere sesion activa y rol `urAdmin`.

`FMain` usa el rol autenticado para mostrar u ocultar la opcion `Usuarios`.

## Pruebas

Archivo:

- `tests/App.Core.Tests/AppCoreAuthServiceTests.pas`

Escenarios cubiertos:

- Usuario obligatorio.
- Contrasena obligatoria.
- Usuario inexistente.
- Contrasena incorrecta.
- Usuario inactivo.
- Incremento de fallos.
- Bloqueo al tercer fallo.
- Usuario bloqueado rechazado aunque la contrasena sea correcta.
- Reinicio de fallos tras login correcto.
- Campos vacios no cuentan como fallo.
- Usuario desconocido no crea contador.
- Creacion de sesion activa.
- Rol almacenado en sesion.
- Logout.
- Usuario autenticado disponible desde sesion.
- Expiracion por inactividad.
- Actualizacion de ultima actividad.
- Permiso admin concedido a admin.
- Permiso admin denegado a usuario normal.
- Precarga de ultimo usuario.
- Actualizacion de ultimo usuario tras intento.
- Usuario vacio no borra ultimo usuario.
- Trim del nombre de usuario.

Comandos de verificacion:

```bat
cd tests\App.Core.Tests
dcc32 "-U..\..\src\App.Core" AppCoreTests.dpr
AppCoreTests.exe

cd ..\..\src\App.Win
dcc32 "-U..\App.Core" WindowsApp.dpr
```

## Decisiones tecnicas

- La primera version usa repositorios en memoria para mantener el ciclo TDD rapido.
- La persistencia real queda detras de interfaces.
- La UI no compara credenciales ni decide permisos de negocio.
- El hash actual esta encapsulado y sirve como implementacion inicial de desarrollo; para produccion debe sustituirse por un algoritmo seguro con salt manteniendo `IPasswordHasher`.
- La pantalla principal se abre solo despues de un login correcto.

## Pendiente fuera de esta entrega

- Persistencia real en base de datos para usuarios, bloqueos y preferencias.
- Hash de contrasena seguro de produccion.
- Flujo administrativo de desbloqueo.
- Logout visual desde `FMain`.
- Reapertura automatica del login cuando la sesion expire durante interaccion con pantallas VCL.
