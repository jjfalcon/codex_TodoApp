# Especificacion funcional: Login

## Estado

Completada el 2026-06-02.

Implementacion principal:

- Nucleo: `src/App.Core/AppCoreAuth.pas`, `src/App.Core/AppCoreUser.pas`, `src/App.Core/AppCoreUserRepository.pas`, `src/App.Core/AppCorePreferences.pas`.
- UI VCL: `src/App.Win/LoginForm.pas`, `src/App.Win/LoginForm.dfm`, `src/App.Win/WindowsApp.dpr`.
- Pruebas: `tests/App.Core.Tests/AppCoreAuthServiceTests.pas`.
- Documentacion tecnica: `docs/LOGIN_TECH.md`.

## Objetivo

Incorporar autenticacion de usuarios a la aplicacion Windows para que solo usuarios validos puedan acceder a las funcionalidades principales.

Esta especificacion define el comportamiento esperado. No describe todavia detalles de implementacion ni estructura de codigo.

## Alcance inicial

La primera version del login debe permitir:

- Iniciar sesion con usuario y contraseña.
- Validar campos obligatorios.
- Rechazar credenciales incorrectas.
- Bloquear el login tras 3 fallos consecutivos.
- Mantener una sesion activa mientras no expire por inactividad.
- Expirar la sesion tras un periodo de inactividad.
- Cerrar sesion y volver al estado no autenticado.
- Bloquear el acceso a la pantalla principal cuando no exista sesion activa.
- Diferenciar usuarios con rol administrador y rol usuario normal.
- Recordar el ultimo nombre de usuario usado.

Queda fuera del alcance inicial:

- Registro de nuevos usuarios.
- Recuperacion de contraseña.
- Cambio de contraseña.
- Roles y permisos avanzados mas alla de administrador y usuario normal.
- Autenticacion contra servicios externos.

## Conceptos

### Usuario

Representa una identidad que puede autenticarse en la aplicacion.

Datos minimos:

- Identificador interno.
- Nombre de usuario.
- Nombre visible.
- Estado activo o inactivo.
- Rol.
- Numero de fallos consecutivos de login.
- Indicador de bloqueo por fallos.

### Credenciales

Datos proporcionados por el usuario para autenticarse.

Campos:

- Usuario.
- Contraseña.

### Sesion

Estado temporal que indica que un usuario ha sido autenticado correctamente.

Datos minimos:

- Usuario autenticado.
- Fecha y hora de inicio.
- Fecha y hora de ultima actividad.
- Indicador de sesion activa.

### Rol

Define el nivel de acceso del usuario autenticado.

Roles iniciales:

- Administrador.
- Usuario normal.

### Ultimo usuario usado

Preferencia local de la instalacion que guarda el ultimo nombre de usuario utilizado en un intento de login.

No debe guardar la contraseña.

## Reglas de negocio

### Validacion de campos

- El nombre de usuario es obligatorio.
- La contraseña es obligatoria.
- Los espacios al inicio y al final del nombre de usuario no deben afectar a la autenticacion.
- Una contraseña formada solo por espacios debe considerarse vacia.

### Autenticacion

- Si el usuario no existe, el login debe fallar.
- Si la contraseña no coincide, el login debe fallar.
- Si el usuario existe pero esta inactivo, el login debe fallar.
- Si el usuario esta bloqueado por fallos consecutivos, el login debe fallar aunque la contraseña sea correcta.
- Si las credenciales son validas y el usuario esta activo, el login debe crear una sesion activa.
- Si las credenciales son validas, el contador de fallos consecutivos del usuario debe volver a cero.
- El mensaje de error para usuario inexistente o contraseña incorrecta debe ser generico para no revelar informacion sensible.

### Bloqueo por fallos consecutivos

- Cada intento con contraseña incorrecta para un usuario existente y activo debe incrementar su contador de fallos consecutivos.
- Al llegar a 3 fallos consecutivos, el usuario debe quedar bloqueado.
- Un usuario bloqueado no puede iniciar sesion aunque proporcione credenciales correctas.
- El bloqueo debe aplicarse por usuario, no globalmente a toda la aplicacion.
- Un login correcto antes de llegar al tercer fallo debe reiniciar el contador de fallos a cero.
- Los intentos con usuario inexistente deben fallar, pero no deben crear usuarios ni contadores nuevos.
- Los intentos con campos obligatorios vacios no deben contar como fallo de autenticacion.
- Los intentos contra un usuario inactivo no deben contar como fallo de contraseña.
- En esta primera version, el desbloqueo queda fuera del flujo normal de usuario y se considera una accion administrativa o de mantenimiento.

### Sesion activa

- La aplicacion debe poder consultar si existe una sesion activa.
- La aplicacion debe poder obtener el usuario autenticado.
- La aplicacion debe poder consultar el rol del usuario autenticado.
- Cada actividad protegida debe actualizar la fecha y hora de ultima actividad de la sesion.
- Si el tiempo desde la ultima actividad supera el limite configurado, la sesion debe expirar.
- Una sesion expirada debe considerarse inactiva.
- Al cerrar sesion, la sesion activa debe eliminarse.
- Tras cerrar sesion, el usuario no debe poder acceder a funcionalidades protegidas.

### Expiracion por inactividad

- La sesion debe expirar tras un periodo configurable de inactividad.
- El valor inicial recomendado para pruebas es 15 minutos.
- La expiracion debe basarse en la ultima actividad registrada, no solo en la hora de inicio de sesion.
- Al expirar la sesion, la aplicacion debe volver a solicitar login.
- Tras expirar la sesion, no debe quedar ninguna funcionalidad protegida accesible.
- La expiracion por inactividad debe poder probarse con un reloj inyectable.

### Roles

- Un usuario debe tener exactamente un rol inicial: administrador o usuario normal.
- El rol debe quedar disponible en la sesion tras un login correcto.
- Las funcionalidades protegidas podran declarar si requieren usuario autenticado o administrador.
- Un usuario normal no debe poder acceder a funcionalidades reservadas a administradores.
- Un administrador debe poder acceder a funcionalidades reservadas a administradores.
- La UI no debe decidir reglas de permisos por su cuenta; debe consultar al nucleo.

### Multiples usuarios

- La instalacion debe permitir varios usuarios registrados.
- El login debe autenticar contra el usuario indicado por el nombre de usuario.
- El bloqueo por fallos consecutivos debe aplicarse de forma independiente por usuario.
- La expiracion de sesion afecta solo a la sesion activa actual.
- Solo puede existir una sesion activa en la aplicacion de escritorio en un momento dado.

### Persistencia en base de datos

- Los usuarios, roles, estados, bloqueos y fallos consecutivos deben guardarse en base de datos.
- La aplicacion debe obtener los usuarios desde un repositorio conectado a base de datos.
- La contraseña no debe guardarse en texto claro.
- El nucleo debe depender de una interfaz de repositorio, no de detalles concretos de la base de datos.
- Para TDD se podra seguir usando un repositorio en memoria en las pruebas unitarias.

### Ultimo usuario usado

- La aplicacion debe recordar el ultimo nombre de usuario usado.
- Al abrir la pantalla de login, el campo usuario debe aparecer precargado con ese valor si existe.
- La contraseña nunca debe recordarse.
- El ultimo usuario usado debe actualizarse al intentar iniciar sesion, tanto si el login tiene exito como si falla por credenciales invalidas.
- Los intentos con usuario vacio no deben borrar el ultimo usuario recordado.

### Seguridad inicial

- La contraseña no debe mostrarse en texto claro en la interfaz.
- La contraseña no debe guardarse en logs ni mensajes de error.
- La contraseña no debe guardarse recordada en preferencias locales.
- En base de datos, la contraseña debe almacenarse usando un hash seguro con salt.
- Los errores de autenticacion no deben indicar si fallo el usuario o la contraseña.
- La comparacion de credenciales debe quedar encapsulada fuera de la UI.

## Flujo de usuario

### Inicio de aplicacion

1. La aplicacion arranca sin sesion activa.
2. Se muestra la pantalla de login.
3. La pantalla principal permanece inaccesible hasta autenticar al usuario.

### Login correcto

1. El usuario introduce nombre de usuario y contraseña.
2. El sistema valida que ambos campos tengan contenido.
3. El sistema verifica las credenciales.
4. El sistema crea una sesion activa.
5. El sistema registra la fecha y hora de ultima actividad.
6. La aplicacion muestra la pantalla principal.
7. La pantalla principal puede mostrar el nombre visible y rol del usuario autenticado.

### Login incorrecto

1. El usuario introduce credenciales no validas.
2. El sistema rechaza el intento.
3. Si el usuario existe, esta activo y la contraseña es incorrecta, el sistema incrementa el contador de fallos consecutivos.
4. Si el contador alcanza 3 fallos consecutivos, el usuario queda bloqueado.
5. La aplicacion muestra un mensaje generico de error.
6. La sesion permanece inactiva.
7. La pantalla principal sigue inaccesible.

### Usuario bloqueado

1. El usuario introduce credenciales de una cuenta bloqueada.
2. El sistema rechaza el intento sin validar la contraseña como login correcto.
3. La aplicacion informa que la cuenta esta bloqueada.
4. La sesion permanece inactiva.

### Logout

1. El usuario solicita cerrar sesion.
2. El sistema elimina la sesion activa.
3. La aplicacion vuelve a la pantalla de login.
4. Las funcionalidades protegidas quedan inaccesibles.

### Expiracion de sesion

1. El usuario inicia sesion correctamente.
2. El usuario permanece sin actividad durante mas tiempo que el limite configurado.
3. El sistema marca la sesion como expirada.
4. La aplicacion vuelve a solicitar login.
5. Las funcionalidades protegidas quedan inaccesibles hasta un nuevo login correcto.

## Mensajes esperados

Los textos definitivos pueden ajustarse en la implementacion, pero deben respetar esta intencion:

- Usuario obligatorio: `El usuario es obligatorio.`
- Contraseña obligatoria: `La contraseña es obligatoria.`
- Credenciales invalidas: `Usuario o contraseña incorrectos.`
- Usuario inactivo: `El usuario no esta activo.`
- Usuario bloqueado: `El usuario esta bloqueado por demasiados intentos fallidos.`
- Sesion expirada: `La sesion ha expirado por inactividad.`
- Acceso denegado: `No tiene permisos para acceder a esta funcionalidad.`

## Criterios de aceptacion

- Dado que no hay sesion activa, cuando la aplicacion arranca, entonces debe mostrarse el login.
- Dado un usuario activo con credenciales validas, cuando inicia sesion, entonces se crea una sesion activa.
- Dado un usuario activo con credenciales validas, cuando inicia sesion, entonces la sesion incluye su rol.
- Dado un usuario inexistente, cuando intenta iniciar sesion, entonces se rechaza el acceso.
- Dado una contraseña incorrecta, cuando intenta iniciar sesion, entonces se rechaza el acceso.
- Dado un usuario activo, cuando falla la contraseña una vez, entonces su contador de fallos consecutivos aumenta a 1.
- Dado un usuario activo con 2 fallos consecutivos, cuando falla la contraseña otra vez, entonces el usuario queda bloqueado.
- Dado un usuario bloqueado, cuando intenta iniciar sesion con credenciales correctas, entonces se rechaza el acceso.
- Dado un usuario activo con fallos acumulados menores que 3, cuando inicia sesion correctamente, entonces el contador de fallos vuelve a 0.
- Dado un usuario inactivo, cuando intenta iniciar sesion, entonces se rechaza el acceso.
- Dado un usuario autenticado, cuando cierra sesion, entonces la sesion queda inactiva.
- Dado un usuario autenticado sin actividad durante mas tiempo que el limite configurado, cuando se comprueba la sesion, entonces la sesion queda expirada.
- Dado un usuario autenticado que realiza una actividad protegida antes de expirar, cuando se registra la actividad, entonces se actualiza la ultima actividad de la sesion.
- Dado un usuario normal autenticado, cuando intenta acceder a una funcionalidad de administrador, entonces el acceso se deniega.
- Dado un administrador autenticado, cuando intenta acceder a una funcionalidad de administrador, entonces el acceso se permite.
- Dado que la sesion esta inactiva, cuando se intenta acceder a una funcionalidad protegida, entonces el acceso se bloquea.
- Dado un nombre de usuario con espacios laterales, cuando las credenciales son validas, entonces el login debe funcionar igual que sin esos espacios.
- Dado una contraseña vacia o formada solo por espacios, cuando se intenta iniciar sesion, entonces se informa que la contraseña es obligatoria.
- Dado que existe un ultimo usuario usado, cuando se abre el login, entonces el campo usuario se precarga con ese valor.
- Dado un intento de login con usuario no vacio, cuando termina el intento, entonces se actualiza el ultimo usuario usado.
- Dado un intento de login con usuario vacio, cuando termina la validacion, entonces no se borra el ultimo usuario usado.

## Escenarios TDD propuestos

Los primeros tests deben cubrir el nucleo, sin formularios VCL:

- `Login_rejects_empty_username`
- `Login_rejects_empty_password`
- `Login_rejects_unknown_user`
- `Login_rejects_wrong_password`
- `Login_rejects_inactive_user`
- `Login_increments_failed_attempts_for_wrong_password`
- `Login_locks_user_after_three_consecutive_failures`
- `Login_rejects_locked_user_even_with_valid_password`
- `Login_resets_failed_attempts_after_successful_login`
- `Login_does_not_count_empty_fields_as_failed_attempts`
- `Login_does_not_count_unknown_user_as_failed_attempt`
- `Login_creates_active_session_for_valid_credentials`
- `Login_stores_user_role_in_session`
- `Logout_clears_active_session`
- `Session_reports_authenticated_user`
- `Session_expires_after_inactivity_limit`
- `Session_updates_last_activity_when_user_performs_protected_action`
- `Permission_allows_admin_feature_for_admin`
- `Permission_rejects_admin_feature_for_normal_user`
- `Login_prefills_last_used_username`
- `Login_updates_last_used_username_after_attempt`
- `Login_does_not_clear_last_used_username_when_username_is_empty`
- `Username_is_trimmed_before_authentication`

## Diseno esperado para TDD

La funcionalidad debe poder probarse sin abrir ventanas.

Componentes conceptuales:

- Servicio de autenticacion.
- Repositorio de usuarios.
- Servicio o entidad de sesion.
- Validador de credenciales.
- Politica de fallos consecutivos.
- Politica de expiracion por inactividad.
- Servicio de permisos.
- Repositorio de preferencias locales para el ultimo usuario usado.
- Repositorio de usuarios respaldado por base de datos.
- Reloj inyectable para registrar el inicio de sesion.

La UI solo debe:

- Recoger usuario y contraseña.
- Llamar al servicio de autenticacion.
- Mostrar mensajes de error.
- Navegar a la pantalla principal cuando exista sesion activa.
- Solicitar cierre de sesion.
- Mostrar el ultimo usuario usado en el campo usuario.
- Consultar permisos antes de habilitar o ejecutar funciones restringidas.

## Persistencia inicial sugerida

Aunque la persistencia real sera en base de datos, para la primera version TDD se recomienda usar un repositorio en memoria con usuarios precargados en las pruebas unitarias.

Esto permite probar las reglas de autenticacion sin introducir todavia base de datos, ficheros, cifrado ni instaladores.

La implementacion productiva debera sustituir el repositorio en memoria por una persistencia en base de datos manteniendo los mismos tests de negocio.

## Datos de prueba sugeridos

Usuario activo:

- Usuario: `admin`
- Contraseña: `admin123`
- Nombre visible: `Administrador`
- Estado: activo
- Rol: administrador
- Fallos consecutivos: `0`
- Bloqueado: no

Usuario normal:

- Usuario: `user`
- Contraseña: `user123`
- Nombre visible: `Usuario normal`
- Estado: activo
- Rol: usuario normal
- Fallos consecutivos: `0`
- Bloqueado: no

Usuario inactivo:

- Usuario: `disabled`
- Contraseña: `disabled123`
- Nombre visible: `Usuario inactivo`
- Estado: inactivo
- Rol: usuario normal
- Fallos consecutivos: `0`
- Bloqueado: no

Usuario bloqueado:

- Usuario: `locked`
- Contraseña: `locked123`
- Nombre visible: `Usuario bloqueado`
- Estado: activo
- Rol: usuario normal
- Fallos consecutivos: `3`
- Bloqueado: si

Estos datos son solo para desarrollo y pruebas. No deben considerarse credenciales reales de produccion.

## Decisiones confirmadas

- La sesion expira por tiempo de inactividad.
- La aplicacion tendra roles de administrador y usuario normal.
- Las credenciales se guardaran en base de datos.
- Se permiten multiples usuarios en la misma instalacion.
- Debe recordarse el ultimo usuario usado.

## Preguntas pendientes

- Cuantos minutos exactos debe durar el limite de inactividad en produccion?
- El desbloqueo tras 3 fallos sera manual, temporal o mediante un administrador?
- Si el bloqueo es temporal, cuanto tiempo debe durar?
- Que motor de base de datos se usara?
- Que funcionalidades concretas seran exclusivas de administrador?
