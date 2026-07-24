# Especificacion funcional: Gestion de usuarios

> Nota: esta especificacion conserva el diseno inicial de `FUser`. La implementacion vigente esta simplificada en `USR` mediante `TFrmCrud` y `TUserCrudProvider`; para el contrato actual, usar `docs\ARCHITECTURE.md`, `docs\USER_TECH.md` y `docs\USER_MANUAL.md`.

## Objetivo

Incorporar una pantalla `FUser` para administrar los usuarios de la aplicacion Windows desde `FMain`.

La gestion de usuarios debe permitir mantener las identidades que utiliza el login, incluyendo estado, rol, bloqueo, contraseña y datos de contacto. El nucleo debe conservar las reglas de negocio y la UI VCL solo debe invocar servicios testeables.

Esta especificacion define el comportamiento esperado. No describe todavia detalles de implementacion ni estructura exacta de codigo.

## Alcance inicial

La primera version de gestion de usuarios debe permitir:

- Acceder a `FUser` desde la opcion `Usuarios` de `FMain`.
- Restringir el acceso a usuarios con rol administrador.
- Ocultar la opcion `Usuarios` a usuarios sin permiso.
- Crear usuarios nuevos.
- Editar los datos de usuarios existentes.
- Activar y desactivar usuarios.
- Bloquear y desbloquear usuarios.
- Eliminar usuarios de forma logica mediante una accion visible distinta de desactivar y bloquear.
- Cambiar la contraseña de un usuario.
- Cambiar el rol entre administrador y usuario normal.
- Listar todos los usuarios existentes.
- Buscar usuarios por nombre de usuario, nombre visible o email.
- Filtrar usuarios por activos, inactivos o bloqueados.
- Crear por defecto un administrador inicial `admin` con contraseña `admin` en una instalacion nueva.
- Persistir los usuarios mediante un repositorio abstracto independiente.
- Compartir el mismo repositorio logico de usuarios con el login.
- Registrar fecha de creacion y fecha de ultimo login.

Queda fuera del alcance inicial:

- Borrar fisicamente usuarios.
- Gestionar roles avanzados distintos de administrador y usuario normal.
- Implementar doble factor.
- Implementar recuperacion de contraseña.
- Enviar emails.
- Auditar historico completo de cambios.
- Gestionar permisos granulares por funcionalidad.
- Definir el motor concreto de base de datos.

## Conceptos

### Usuario

Representa una identidad que puede autenticarse y operar dentro de la aplicacion.

Datos minimos:

- Identificador interno.
- Nombre de usuario.
- Nombre visible.
- Email.
- Estado activo o inactivo.
- Estado eliminado o no eliminado.
- Rol.
- Numero de fallos consecutivos de login.
- Indicador de bloqueo por fallos.
- Fecha de creacion.
- Fecha de ultimo login.
- Hash de contraseña y datos necesarios para validarla de forma segura.

### Rol

Define el nivel de acceso general del usuario.

Roles iniciales:

- Administrador.
- Usuario normal.

En esta version, solo los administradores pueden acceder a `FUser`.

### Repositorio de usuarios

Componente responsable de guardar y recuperar usuarios.

Debe ser independiente de la UI y exponerse mediante una interfaz del nucleo. La gestion de usuarios y el login deben operar contra el mismo contrato para que los cambios administrativos afecten a la autenticacion segun la politica definida para cada tipo de cambio.

La persistencia real se concretara mas adelante. Para TDD se podran usar repositorios en memoria o fakes.

### Servicio de usuarios

Componente de negocio que valida operaciones de administracion y coordina el repositorio.

Debe concentrar las reglas de creacion, edicion, cambios de estado, cambios de rol, bloqueo, desbloqueo, eliminacion logica, cambio de contraseña, busqueda y filtrado.

### Administrador inicial

Usuario administrador creado durante la inicializacion de la aplicacion o del repositorio cuando no existe ningun administrador disponible.

Su objetivo es evitar que la aplicacion quede sin acceso administrativo inicial.

### Pantalla FUser

Formulario VCL incrustado dentro de `FMain` para administrar usuarios.

Debe actuar como una vista fina: muestra datos, recoge entradas del administrador y llama al servicio de usuarios.

## Reglas de negocio

### Acceso

- `FUser` solo debe estar disponible para usuarios administradores.
- Un usuario normal no debe poder abrir ni ejecutar operaciones de `FUser`.
- La opcion `Usuarios` debe ocultarse para usuarios normales.
- La opcion `Usuarios` de `FMain` debe cargar `FUser` incrustado en la zona central.
- La UI no debe decidir permisos por su cuenta; debe consultar al nucleo o al servicio de permisos.
- Si la sesion expira, `FUser` debe quedar inaccesible y la aplicacion debe volver a solicitar login.

### Administrador inicial

- Si el sistema se inicializa sin ningun usuario administrador activo, debe poder crear un administrador inicial.
- En una instalacion nueva, el administrador inicial debe crearse por defecto con usuario `admin` y contraseña `admin`.
- El administrador inicial debe estar activo, no bloqueado y tener rol administrador.
- La creacion del administrador inicial debe ocurrir de forma controlada y testeable.
- El administrador inicial debe cumplir las mismas reglas de usuario y contraseña que el resto de usuarios.

### Creacion de usuarios

- El nombre de usuario es obligatorio.
- El nombre visible es obligatorio.
- El email es obligatorio.
- El email debe tener un formato valido del estilo `ejemplo@mail.com`.
- La contraseña es obligatoria.
- La contraseña debe tener mas de 4 caracteres.
- El rol es obligatorio y debe ser administrador o usuario normal.
- Los espacios al inicio y al final del nombre de usuario, nombre visible y email no deben guardarse.
- No se deben permitir nombres de usuario duplicados.
- No se deben permitir emails duplicados si se usan como dato de contacto unico.
- Todo usuario nuevo debe crearse activo, no bloqueado y con contador de fallos consecutivos a cero.
- Todo usuario nuevo debe crearse como no eliminado.
- Todo usuario nuevo debe registrar fecha de creacion usando un reloj inyectable.
- La fecha de ultimo login de un usuario nuevo debe quedar vacia hasta su primer login correcto.
- La contraseña no debe guardarse en texto claro.

### Edicion de usuarios

- Debe permitirse modificar nombre visible, email, estado activo, rol y bloqueo.
- Debe permitirse cambiar la contraseña mediante una operacion explicita.
- No debe permitirse editar, activar, desbloquear ni cambiar la contraseña de un usuario eliminado.
- No debe permitirse dejar vacios nombre de usuario, nombre visible o email.
- No debe permitirse guardar un email con formato invalido.
- No debe permitirse cambiar a un nombre de usuario ya usado por otro usuario.
- No debe permitirse cambiar a un email ya usado por otro usuario.
- El identificador interno no debe cambiar.
- La fecha de creacion no debe cambiar.
- La fecha de ultimo login no debe modificarse desde la edicion administrativa ordinaria.

### Autogestion administrativa

- Un administrador no puede modificarse a si mismo desde `FUser`.
- La restriccion aplica a cambios de rol, activacion, desactivacion, bloqueo, desbloqueo, contraseña y datos principales.
- Los cambios sobre un administrador deben realizarlos otros administradores.
- El nucleo debe validar esta regla aunque la UI oculte o deshabilite acciones sobre el usuario actual.

### Estado activo

- Un usuario activo puede iniciar sesion si sus credenciales son correctas y no esta bloqueado.
- Un usuario inactivo no puede iniciar sesion.
- Desactivar un usuario debe afectar a partir del siguiente login.
- Si el usuario desactivado tiene una sesion activa, la sesion ya creada no debe cerrarse solo por esa desactivacion.
- Reactivar un usuario permite que vuelva a iniciar sesion si no esta bloqueado y sus credenciales son validas.

### Bloqueo

- Un usuario bloqueado no puede iniciar sesion aunque sus credenciales sean correctas.
- El bloqueo automatico por 3 fallos consecutivos definido en `LOGIN_SPEC` debe seguir siendo compatible.
- Un administrador puede bloquear o desbloquear un usuario desde `FUser`.
- Al desbloquear un usuario, su contador de fallos consecutivos debe volver a cero.
- Bloquear manualmente un usuario no debe borrar sus datos ni su historial basico.
- Bloquear o desbloquear un usuario debe afectar a partir del siguiente login.
- Si el usuario bloqueado o desbloqueado tiene una sesion activa, la sesion ya creada no debe cambiar solo por ese cambio.

### Eliminacion logica

- Debe existir una accion visible de eliminacion logica de usuario.
- La eliminacion logica debe ser distinta de desactivar o bloquear.
- Eliminar logicamente un usuario no debe borrar fisicamente el registro.
- Un usuario eliminado no puede iniciar sesion.
- Un usuario eliminado no puede volver a activarse.
- Un usuario eliminado no puede desbloquearse para recuperar acceso.
- Un usuario eliminado debe conservarse en el repositorio para mantener historial basico.
- Si el usuario eliminado tiene una sesion activa, la sesion ya creada no debe cerrarse solo por esa eliminacion; el cambio aplica a partir del siguiente login.
- La aplicacion debe evitar que la eliminacion logica deje el sistema sin ningun administrador activo disponible.

### Contraseña

- Un administrador puede cambiar la contraseña de otro usuario.
- La nueva contraseña debe tener mas de 4 caracteres.
- Una contraseña vacia o formada solo por espacios debe rechazarse.
- La contraseña no debe mostrarse en texto claro salvo durante la entrada controlada del campo.
- La contraseña no debe guardarse en logs, mensajes de error ni preferencias.
- La contraseña debe persistirse usando hash seguro con salt cuando exista persistencia real.
- Cambiar la contraseña debe afectar inmediatamente al login.

### Roles

- Cada usuario debe tener exactamente un rol.
- Los roles validos iniciales son administrador y usuario normal.
- Cambiar el rol de un usuario debe afectar a sus permisos a partir del siguiente login.
- Si el usuario tiene una sesion activa, el cambio de rol no debe alterar los permisos de esa sesion ya creada.
- La aplicacion debe evitar quedar sin ningun administrador activo disponible.
- Si una operacion dejaria el sistema sin administradores activos, debe rechazarse.

### Confirmaciones y auditoria

- La aplicacion no debe pedir confirmacion antes de desactivar, bloquear, desbloquear, cambiar rol o cambiar contraseña.
- La accion visible de eliminar usuario debe pedir confirmacion antes de ejecutarse.
- La eliminacion de usuario no debe borrar fisicamente el registro; debe tratarse como baja logica para mantener historial.
- Por ahora no se registra auditoria de cambios administrativos.

### Listado, busqueda y filtros

- `FUser` debe poder listar los usuarios existentes.
- La busqueda debe comparar contra nombre de usuario, nombre visible y email.
- La busqueda no debe distinguir mayusculas y minusculas.
- El texto de busqueda debe ignorar espacios laterales.
- Si el texto de busqueda esta vacio, debe devolverse el listado completo compatible con los filtros activos.
- Debe poder filtrarse por usuarios activos.
- Debe poder filtrarse por usuarios inactivos.
- Debe poder filtrarse por usuarios bloqueados.
- Los usuarios eliminados no deben mostrarse en el listado por defecto.
- Debe poder filtrarse por usuarios eliminados mediante un filtro especifico.
- Los filtros deben poder combinarse con la busqueda.

### Compatibilidad con login

- El login debe consultar el mismo repositorio logico de usuarios que usa `FUser`.
- Si `FUser` desactiva un usuario, la sesion activa de ese usuario no cambia y el siguiente login debe fallar por usuario inactivo.
- Si `FUser` bloquea un usuario, la sesion activa de ese usuario no cambia y el siguiente login debe fallar por usuario bloqueado.
- Si `FUser` desbloquea un usuario, el login debe volver a permitir credenciales validas.
- Si `FUser` elimina logicamente un usuario, la sesion activa de ese usuario no cambia y el siguiente login debe fallar por usuario eliminado.
- Si `FUser` cambia una contraseña, el login debe rechazar la contraseña anterior y aceptar la nueva.
- Si `FUser` cambia un rol, el login debe reflejar el rol actualizado en la siguiente sesion creada para ese usuario.
- Tras un login correcto, debe actualizarse la fecha de ultimo login del usuario autenticado.

### Persistencia

- El nucleo debe depender de una interfaz de repositorio de usuarios, no de detalles concretos de base de datos.
- La implementacion productiva podra usar base de datos u otro mecanismo persistente manteniendo el mismo contrato.
- Para TDD se debe poder usar un repositorio en memoria.
- Los usuarios, roles, estados, bloqueos, eliminacion logica, fallos consecutivos, email, fecha de creacion y fecha de ultimo login deben persistirse.
- La contraseña no debe persistirse en texto claro.

## Flujo de usuario

### Abrir gestion de usuarios

1. Un administrador inicia sesion correctamente.
2. La aplicacion abre `FMain`.
3. El administrador selecciona `Usuarios` en la barra lateral.
4. `FMain` comprueba sesion y permisos.
5. `FMain` incrusta `FUser` en la zona central.
6. `FUser` carga y muestra el listado de usuarios.

### Acceso denegado a usuario normal

1. Un usuario normal inicia sesion correctamente.
2. La aplicacion abre `FMain`.
3. La opcion `Usuarios` permanece oculta.
4. Si se intenta abrir `FUser` por una ruta no visual, el nucleo deniega el acceso.

### Crear usuario

1. El administrador abre `FUser`.
2. Introduce nombre de usuario, nombre visible, email, rol y contraseña.
3. La aplicacion valida los campos.
4. Si los datos son validos, crea el usuario activo y no bloqueado.
5. La lista de usuarios se refresca.

### Editar usuario

1. El administrador selecciona un usuario distinto de si mismo.
2. Modifica los datos permitidos.
3. La aplicacion valida las reglas de negocio.
4. Si los datos son validos, guarda los cambios.
5. La lista de usuarios se refresca.

### Cambiar contraseña

1. El administrador selecciona un usuario distinto de si mismo.
2. Solicita cambiar contraseña.
3. Introduce la nueva contraseña.
4. La aplicacion valida que tenga mas de 4 caracteres.
5. La aplicacion guarda la nueva contraseña de forma segura.
6. El login acepta la nueva contraseña en futuros intentos.

### Desactivar usuario

1. El administrador selecciona un usuario distinto de si mismo.
2. Solicita desactivarlo.
3. La aplicacion valida que la operacion no deje el sistema sin administradores activos.
4. El usuario queda inactivo.
5. Si el usuario tenia una sesion activa, esa sesion no se cierra por la desactivacion.
6. El login rechaza futuros intentos de ese usuario.

### Desbloquear usuario

1. El administrador selecciona un usuario bloqueado distinto de si mismo.
2. Solicita desbloquearlo.
3. La aplicacion quita el bloqueo y reinicia los fallos consecutivos.
4. El usuario puede iniciar sesion si esta activo y usa credenciales validas.

### Eliminar usuario

1. El administrador selecciona un usuario distinto de si mismo.
2. Solicita eliminarlo mediante la accion visible de eliminacion logica.
3. La aplicacion pide confirmacion.
4. La aplicacion valida que la operacion no deje el sistema sin administradores activos.
5. El usuario queda marcado como eliminado.
6. Si el usuario tenia una sesion activa, esa sesion no se cierra por la eliminacion logica.
7. El usuario eliminado no puede volver a activarse.
8. El login rechaza futuros intentos de ese usuario.

### Buscar y filtrar

1. El administrador introduce texto de busqueda o selecciona filtros.
2. La aplicacion consulta el servicio de usuarios.
3. La pantalla muestra solo los usuarios que cumplen busqueda y filtros.
4. Al limpiar la busqueda y filtros, vuelve a mostrarse el listado completo.

## Mensajes esperados

Los textos definitivos pueden ajustarse en la implementacion, pero deben respetar esta intencion:

- Usuario obligatorio: `El usuario es obligatorio.`
- Nombre visible obligatorio: `El nombre visible es obligatorio.`
- Email obligatorio: `El email es obligatorio.`
- Email invalido: `El email no tiene un formato valido.`
- Contraseña obligatoria: `La contraseña es obligatoria.`
- Contraseña corta: `La contraseña debe tener mas de 4 caracteres.`
- Usuario duplicado: `Ya existe un usuario con ese nombre.`
- Email duplicado: `Ya existe un usuario con ese email.`
- Usuario no encontrado: `El usuario no existe.`
- Usuario eliminado: `El usuario esta eliminado.`
- Confirmar eliminacion: `Esta seguro de que desea eliminar este usuario?`
- Usuario eliminado correctamente: `Usuario eliminado correctamente.`
- Acceso denegado: `No tiene permisos para acceder a esta funcionalidad.`
- Autogestion no permitida: `No puede modificar su propio usuario desde esta pantalla.`
- Sin administrador disponible: `Debe existir al menos un administrador activo.`
- Usuario creado: `Usuario creado correctamente.`
- Usuario actualizado: `Usuario actualizado correctamente.`
- Contraseña actualizada: `Contraseña actualizada correctamente.`

## Criterios de aceptacion

- Dado un administrador autenticado, cuando abre `FMain`, entonces puede acceder a la opcion `Usuarios`.
- Dado un usuario normal autenticado, cuando intenta acceder a `Usuarios`, entonces se deniega el acceso.
- Dado un usuario normal autenticado, cuando se muestra `FMain`, entonces la opcion `Usuarios` permanece oculta.
- Dado un administrador autenticado, cuando selecciona `Usuarios`, entonces `FMain` incrusta `FUser` en la zona central.
- Dado que es una instalacion nueva, cuando se inicializa el sistema, entonces se crea un administrador inicial `admin` con contraseña `admin`.
- Dado datos validos de usuario, cuando se crea el usuario, entonces queda activo, no bloqueado, no eliminado y con fallos consecutivos a cero.
- Dado un usuario nuevo, cuando se crea, entonces registra fecha de creacion desde el reloj configurado.
- Dado un usuario nuevo, cuando se crea, entonces su fecha de ultimo login queda vacia.
- Dado un nombre de usuario vacio, cuando se crea o edita un usuario, entonces se rechaza la operacion.
- Dado un email con formato invalido, cuando se crea o edita un usuario, entonces se rechaza la operacion.
- Dado una contraseña de 4 caracteres o menos, cuando se crea un usuario o se cambia su contraseña, entonces se rechaza la operacion.
- Dado un nombre de usuario ya usado por otro usuario, cuando se crea o edita un usuario, entonces se rechaza la operacion.
- Dado un email ya usado por otro usuario, cuando se crea o edita un usuario, entonces se rechaza la operacion.
- Dado un administrador, cuando intenta modificarse a si mismo desde `FUser`, entonces la operacion se rechaza.
- Dado un usuario activo, cuando un administrador lo desactiva, entonces no puede iniciar sesion a partir del siguiente login.
- Dado un usuario activo con sesion activa, cuando un administrador lo desactiva, entonces la sesion actual no se cierra solo por ese cambio.
- Dado un usuario inactivo, cuando un administrador lo activa, entonces puede iniciar sesion si sus credenciales son validas y no esta bloqueado.
- Dado un usuario bloqueado, cuando un administrador lo desbloquea, entonces su contador de fallos consecutivos vuelve a cero.
- Dado un usuario activo con sesion activa, cuando un administrador lo bloquea, entonces la sesion actual no se cierra solo por ese cambio.
- Dado un usuario bloqueado, cuando intenta iniciar sesion de nuevo, entonces se rechaza el login.
- Dado un usuario, cuando un administrador cambia su contraseña, entonces el login rechaza la contraseña anterior.
- Dado un usuario, cuando un administrador cambia su contraseña, entonces el login acepta la nueva contraseña.
- Dado un usuario, cuando un administrador cambia su rol, entonces los permisos reflejan el nuevo rol a partir del siguiente login.
- Dado que solo existe un administrador activo, cuando se intenta desactivarlo, bloquearlo o degradarlo a usuario normal, entonces se rechaza la operacion.
- Dado varios usuarios, cuando se busca por nombre de usuario, nombre visible o email, entonces se devuelven las coincidencias.
- Dado una busqueda con mayusculas o minusculas distintas, cuando se ejecuta, entonces devuelve las coincidencias sin distinguir mayusculas y minusculas.
- Dado filtros de activo, inactivo o bloqueado, cuando se aplican, entonces el listado muestra solo usuarios compatibles.
- Dado que existen usuarios eliminados, cuando se abre el listado sin filtro de eliminados, entonces no se muestran.
- Dado que existen usuarios eliminados, cuando se activa el filtro de eliminados, entonces se muestran los usuarios eliminados compatibles con la busqueda.
- Dado un login correcto, cuando se autentica el usuario, entonces se actualiza su fecha de ultimo login.
- Dado una accion de eliminar usuario, cuando se ejecuta desde la UI, entonces se pide confirmacion antes de aplicar la baja logica.
- Dado un usuario eliminado logicamente, cuando intenta iniciar sesion, entonces se rechaza el login.
- Dado un usuario eliminado logicamente, cuando se intenta activarlo, entonces se rechaza la operacion.
- Dado un usuario eliminado logicamente con sesion activa, cuando se aplica la eliminacion, entonces la sesion actual no se cierra solo por ese cambio.
- Dado una accion administrativa distinta de eliminar usuario, cuando se ejecuta desde la UI, entonces no se pide confirmacion previa.
- Dado una accion administrativa, cuando se completa, entonces no se registra auditoria en esta version.

## Escenarios TDD propuestos

Los primeros tests deben cubrir el nucleo, sin formularios VCL:

- `UserManagement_requires_admin_permission`
- `UserManagement_rejects_normal_user`
- `UserManagement_hides_users_option_for_normal_user`
- `UserManagement_creates_default_admin_on_new_installation`
- `CreateUser_stores_active_unblocked_not_deleted_user`
- `CreateUser_rejects_empty_username`
- `CreateUser_rejects_empty_display_name`
- `CreateUser_rejects_empty_email`
- `CreateUser_rejects_invalid_email`
- `CreateUser_rejects_short_password`
- `CreateUser_rejects_duplicate_username`
- `CreateUser_rejects_duplicate_email`
- `CreateUser_sets_created_at_from_clock`
- `CreateUser_leaves_last_login_empty`
- `UpdateUser_changes_display_name_email_status_and_role`
- `UpdateUser_rejects_duplicate_username`
- `UpdateUser_rejects_duplicate_email`
- `UpdateUser_rejects_invalid_email`
- `UpdateUser_rejects_self_modification`
- `DeactivateUser_prevents_future_login`
- `DeactivateUser_does_not_close_current_session`
- `ActivateUser_allows_valid_future_login`
- `BlockUser_prevents_future_login`
- `BlockUser_does_not_close_current_session`
- `UnlockUser_clears_failed_attempts`
- `DeleteUser_marks_user_as_deleted`
- `DeleteUser_prevents_future_login`
- `DeleteUser_rejects_reactivation`
- `DeleteUser_does_not_close_current_session`
- `ChangePassword_rejects_short_password`
- `ChangePassword_replaces_old_credentials`
- `ChangeRole_updates_permissions_on_next_login`
- `UserManagement_prevents_removing_last_active_admin`
- `DeleteUser_requires_confirmation`
- `AdministrativeChanges_do_not_write_audit_log`
- `SearchUsers_matches_username_display_name_and_email`
- `SearchUsers_is_case_insensitive`
- `FilterUsers_returns_active_users`
- `FilterUsers_returns_inactive_users`
- `FilterUsers_returns_blocked_users`
- `ListUsers_excludes_deleted_users_by_default`
- `FilterUsers_returns_deleted_users_when_requested`
- `Login_updates_user_last_login_at`

## Diseno esperado para TDD

La funcionalidad debe poder probarse sin abrir ventanas.

Componentes conceptuales:

- Servicio de usuarios.
- Repositorio de usuarios.
- Servicio de permisos.
- Servicio de autenticacion compatible con el mismo repositorio.
- Politica de contraseña.
- Politica de administrador minimo.
- Politica de autogestion administrativa.
- Politica de eliminacion logica.
- Buscador y filtrador de usuarios.
- Reloj inyectable para fecha de creacion y ultimo login.
- Validador de datos de usuario.

La UI solo debe:

- Consultar si el usuario autenticado puede administrar usuarios.
- Solicitar el listado de usuarios.
- Recoger datos de creacion y edicion.
- Llamar al servicio de usuarios.
- Mostrar mensajes de validacion del nucleo.
- Refrescar la lista visible.
- Incrustarse como `FUser` dentro de `FMain`.

## Datos de prueba sugeridos

Administrador inicial:

- Usuario: `admin`
- Contraseña: `admin`
- Nombre visible: `Administrador`
- Email: `admin@example.local`
- Estado: activo
- Eliminado: no
- Rol: administrador
- Fallos consecutivos: `0`
- Bloqueado: no

Usuario normal:

- Usuario: `user`
- Contraseña: `user123`
- Nombre visible: `Usuario normal`
- Email: `user@example.local`
- Estado: activo
- Eliminado: no
- Rol: usuario normal
- Fallos consecutivos: `0`
- Bloqueado: no

Usuario inactivo:

- Usuario: `disabled`
- Contraseña: `disabled123`
- Nombre visible: `Usuario inactivo`
- Email: `disabled@example.local`
- Estado: inactivo
- Eliminado: no
- Rol: usuario normal
- Fallos consecutivos: `0`
- Bloqueado: no

Usuario bloqueado:

- Usuario: `locked`
- Contraseña: `locked123`
- Nombre visible: `Usuario bloqueado`
- Email: `locked@example.local`
- Estado: activo
- Eliminado: no
- Rol: usuario normal
- Fallos consecutivos: `3`
- Bloqueado: si

Los tests deben usar un reloj fijo con una fecha conocida para comprobar `createdAt` y `lastLoginAt`.

Estos datos son solo para desarrollo y pruebas. No deben considerarse credenciales reales de produccion.

## Decisiones confirmadas

- La pantalla de gestion de usuarios sera `FUser`.
- `FUser` se integrara dentro de `FMain` mediante la opcion `Usuarios`.
- Solo administradores pueden acceder a `FUser`.
- La opcion `Usuarios` se oculta para usuarios normales.
- El alcance incluye crear, editar, activar, desactivar, bloquear, desbloquear, eliminar logicamente y cambiar contraseñas.
- Los usuarios no se borran fisicamente para mantener historial.
- Debe existir una accion visible de eliminacion logica distinta de desactivar o bloquear.
- Un usuario eliminado no puede volver a activarse.
- Un administrador puede cambiar contraseñas de otros usuarios.
- La contraseña debe tener mas de 4 caracteres.
- El email debe validarse con formato del estilo `ejemplo@mail.com`.
- Un administrador no puede modificarse a si mismo desde `FUser`.
- En una instalacion nueva se crea por defecto el administrador inicial `admin` con contraseña `admin`.
- Por ahora solo existen roles administrador y usuario normal.
- El usuario incluye email, fecha de creacion y fecha de ultimo login.
- `FUser` debe permitir busqueda y filtros.
- Los usuarios eliminados no se muestran por defecto; solo aparecen al activar el filtro especifico de eliminados.
- Los cambios de `FUser` deben ser compatibles con `LOGIN_SPEC`: estado activo, bloqueo, eliminacion logica y rol afectan a partir del siguiente login, y contraseña afecta al siguiente intento de login.
- El cambio de rol de un usuario se tiene en cuenta a partir del siguiente login.
- El cambio de estado activo o bloqueado de un usuario con sesion activa solo tiene efecto a partir del siguiente login.
- El repositorio de usuarios se define de forma abstracta.
- Solo se pide confirmacion antes de eliminar usuario.
- Por ahora no se registra auditoria de cambios administrativos.

## Preguntas pendientes

- Ninguna.
