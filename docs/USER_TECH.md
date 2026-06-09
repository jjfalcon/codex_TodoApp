# Documentacion tecnica: Gestion de usuarios

## Resumen

La gestion de usuarios esta implementada con reglas de negocio en `App.Core` y una pantalla VCL fina en `App.Win`.

El nucleo concentra validaciones, roles, bloqueo, eliminacion logica, cambio de contrasena, busqueda y filtros. La pantalla `FUser` se incrusta dentro de `FMain` mediante la opcion `Usuarios`, visible solo para administradores.

La persistencia queda aislada tras `IUserRepository`. La implementacion actual usa memoria, compartida por login y gestion de usuarios durante la ejecucion de la aplicacion.

## Componentes

### `AppCoreUser.pas`

Define el modelo `TUser` y el enum `TUserRole`.

Campos principales:

- `Id`
- `Username`
- `DisplayName`
- `Email`
- `PasswordHash`
- `Salt`
- `Active`
- `Deleted`
- `Role`
- `FailedAttempts`
- `Locked`
- `CreatedAt`
- `LastLoginAt`

Roles disponibles:

- `urAdmin`
- `urNormal`

### `AppCoreUserRepository.pas`

Define `IUserRepository` para aislar la persistencia.

Operaciones:

- `All`
- `FindById`
- `FindByUsername`
- `FindByEmail`
- `Save`

Implementacion actual:

- `TInMemoryUserRepository`

El repositorio en memoria guarda usuarios por referencia y se usa para TDD y para el arranque actual de desarrollo.

### `AppCoreUserService.pas`

Implementa `TUserService`.

Responsabilidades:

- Crear el administrador inicial `admin/admin`.
- Crear usuarios.
- Editar datos principales.
- Activar y desactivar usuarios.
- Bloquear y desbloquear usuarios.
- Eliminar usuarios de forma logica.
- Cambiar contrasenas.
- Validar email con formato tipo `ejemplo@mail.com`.
- Validar contrasenas de mas de 4 caracteres.
- Impedir autogestion administrativa.
- Impedir que no quede ningun administrador activo disponible.
- Listar, buscar y filtrar usuarios.

Excepciones:

- `EUserValidationError`
- `EUserNotFoundError`
- `EUserSelfModificationError`
- `ELastAdminError`
- `EUserDeletedError`
- `EDeleteConfirmationRequiredError`

### `AppCoreAuth.pas`

El login usa el mismo `IUserRepository`.

Integraciones relevantes:

- Rechaza usuarios eliminados con `EDeletedUserError`.
- Actualiza `LastLoginAt` tras login correcto.
- Mantiene un snapshot del rol en `TSessionService` al iniciar sesion.
- Los cambios de rol afectan a partir del siguiente login.
- Los cambios de estado activo, bloqueo y eliminacion logica afectan al siguiente login.
- El cambio de contrasena afecta al siguiente intento de login.

### `UserForm.pas`

Formulario VCL `TFrmUsers`.

Responsabilidades:

- Mostrar el listado de usuarios.
- Buscar por texto.
- Mostrar usuarios eliminados solo al activar `Mostrar eliminados`.
- Crear usuarios.
- Guardar cambios de usuario seleccionado.
- Cambiar contrasena.
- Desbloquear usuarios.
- Eliminar logicamente con confirmacion.
- Mostrar mensajes de validacion procedentes del nucleo.

La pantalla recibe desde `FMain`:

- Repositorio de usuarios.
- Reloj.
- Hasher de contrasenas.
- Id del usuario autenticado.

### `MainForm.pas`

`FMain` carga `TFrmUsers` al seleccionar `Usuarios`.

La opcion `Usuarios` se oculta para usuarios normales y solo se permite a administradores.

### `LoginForm.pas`

Construye los servicios de autenticacion y expone a `FMain`:

- `UserRepository`
- `SessionService`
- `PasswordHasher`
- `LoggedInUserId`
- `LoggedInRole`

En una instalacion de desarrollo crea el administrador inicial con:

- Usuario: `admin`
- Contrasena: `admin`

## Reglas Principales

### Creacion

- Usuario, nombre visible, email y contrasena son obligatorios.
- El email debe tener formato valido.
- La contrasena debe tener mas de 4 caracteres.
- Usuario y email no pueden duplicarse.
- El usuario nuevo queda activo, no bloqueado, no eliminado y sin fallos.
- `CreatedAt` se obtiene desde `IClock`.
- `LastLoginAt` queda vacio hasta el primer login correcto.

### Edicion

- Se pueden modificar nombre de usuario, nombre visible, email, estado activo, rol y bloqueo.
- No se puede modificar el usuario autenticado desde `FUser`.
- No se puede editar, activar, desbloquear ni cambiar contrasena de un usuario eliminado.
- No se modifica `CreatedAt`.

### Eliminacion Logica

- La accion `Eliminar` pide confirmacion.
- El usuario se marca como eliminado.
- No se borra fisicamente del repositorio.
- No aparece en el listado por defecto.
- Solo aparece al activar el filtro `Mostrar eliminados`.
- No puede volver a activarse.
- No puede iniciar sesion.

### Sesiones Existentes

Si un administrador cambia estado activo, bloqueo, eliminacion logica o rol de un usuario con sesion activa, la sesion ya creada no se cierra por ese cambio.

El efecto se aplica a partir del siguiente login.

## Tests

Archivo:

- `tests/App.Core.Tests/AppCoreUserServiceTests.pas`

Escenarios principales cubiertos:

- Creacion de administrador inicial.
- Creacion de usuario activo, no bloqueado y no eliminado.
- Validacion de email.
- Validacion de contrasena corta.
- Rechazo de usuario duplicado.
- Rechazo de email duplicado.
- Rechazo de autogestion administrativa.
- Cambio de contrasena.
- Eliminacion logica.
- Confirmacion requerida para eliminar.
- Login rechazado para usuario eliminado.
- Rechazo de reactivacion de usuario eliminado.
- La eliminacion no cierra la sesion actual.
- Cambio de rol aplicado en siguiente login.
- Busqueda por usuario, nombre visible o email.
- Usuarios eliminados ocultos por defecto.
- Filtro especifico de usuarios eliminados.
- Actualizacion de `LastLoginAt`.

## Comandos de Verificacion

```bat
cd tests\App.Core.Tests
dcc32 "-U..\..\src\App.Core" AppCoreTests.dpr
AppCoreTests.exe

cd ..\..\src\App.Win
dcc32 "-U..\App.Core" WindowsApp.dpr
```

## Decisiones Tecnicas

- La UI no contiene reglas de negocio.
- La persistencia queda detras de `IUserRepository`.
- Login y gestion de usuarios comparten el mismo repositorio logico.
- La contrasena se gestiona mediante `IPasswordHasher`.
- El hasher actual es una implementacion de desarrollo; para produccion debe sustituirse por un hash seguro con salt.
- La sesion guarda el rol en el momento del login para que los cambios de rol no alteren sesiones ya abiertas.
- No se registra auditoria de cambios administrativos en esta version.

## Limitaciones Actuales

- La persistencia de usuarios es en memoria.
- Los usuarios creados desde `FUser` no sobreviven al cierre de la aplicacion.
- No existe base de datos real.
- No hay auditoria administrativa.
- No hay doble factor ni recuperacion de contrasena.
- No hay logout visual desde `FMain`.
- La UI de `FUser` es funcional y basica.

## Evolucion Recomendada

- Implementar un repositorio persistente de usuarios.
- Sustituir `TBasicPasswordHasher` por un algoritmo seguro de produccion.
- Anadir auditoria administrativa si el producto lo requiere.
- Anadir recuperacion de contrasena usando el email.
- Mejorar filtros visuales por activo, inactivo y bloqueado.
- Gestionar reapertura de login ante expiracion de sesion durante interacciones VCL.
