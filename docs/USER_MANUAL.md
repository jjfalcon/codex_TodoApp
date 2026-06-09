# Manual de usuario: Usuarios

## Objetivo

La pantalla `Usuarios` permite a un administrador gestionar las cuentas de acceso a la aplicacion.

Desde esta pantalla se pueden crear usuarios, editar sus datos, cambiar contrasenas, activar o desactivar cuentas, desbloquear usuarios y eliminar usuarios de forma logica.

## Acceder a Usuarios

1. Inicie sesion con un usuario administrador.
2. Se abrira la pantalla principal `FMain`.
3. En la barra lateral izquierda, pulse `Usuarios`.
4. La pantalla de gestion de usuarios se mostrara en la zona central.

Los usuarios normales no ven la opcion `Usuarios`.

## Crear un usuario

1. Rellene los campos:
   - `Usuario`
   - `Nombre visible`
   - `Email`
   - `Contrasena`
   - Rol
2. Marque `Activo` si la cuenta debe poder iniciar sesion.
3. Pulse `Crear`.
4. El listado se refrescara y seleccionara el usuario creado.

El usuario nuevo queda no bloqueado y no eliminado.

## Campos obligatorios

Los siguientes campos son obligatorios:

- Usuario.
- Nombre visible.
- Email.
- Contrasena.

El email debe tener un formato similar a:

```text
ejemplo@mail.com
```

La contrasena debe tener mas de 4 caracteres.

## Editar un usuario

1. Seleccione un usuario en la lista.
2. Modifique los campos necesarios.
3. Pulse `Guardar`.

No puede modificarse a si mismo desde esta pantalla. Los cambios sobre un administrador deben realizarlos otros administradores.

## Cambiar contrasena

1. Seleccione un usuario.
2. Escriba la nueva contrasena.
3. Pulse `Cambiar contrasena`.

La nueva contrasena sera valida para el siguiente intento de login.

## Activar o desactivar

Para cambiar el estado de una cuenta:

1. Seleccione el usuario.
2. Marque o desmarque `Activo`.
3. Pulse `Guardar`.

Un usuario inactivo no podra iniciar sesion a partir del siguiente login.

Si el usuario ya tenia una sesion activa, esa sesion no se cierra automaticamente por este cambio.

## Bloquear o desbloquear

Para bloquear un usuario:

1. Seleccione el usuario.
2. Marque `Bloqueado`.
3. Pulse `Guardar`.

Para desbloquearlo:

1. Seleccione el usuario bloqueado.
2. Pulse `Desbloquear`.

Al desbloquear, se reinician los fallos consecutivos de login.

## Eliminar usuario

La eliminacion de usuarios es logica.

Esto significa que el usuario no se borra fisicamente, pero queda marcado como eliminado y ya no podra iniciar sesion ni volver a activarse.

Para eliminar:

1. Seleccione el usuario.
2. Pulse `Eliminar`.
3. Confirme la operacion.

La aplicacion no pide confirmacion para desactivar, bloquear, desbloquear, cambiar rol o cambiar contrasena. Solo pide confirmacion al eliminar.

## Buscar usuarios

1. Escriba un texto en el campo de busqueda.
2. Pulse `Buscar`.

La busqueda compara contra:

- Usuario.
- Nombre visible.
- Email.

La busqueda no distingue entre mayusculas y minusculas.

## Usuarios eliminados

Los usuarios eliminados no aparecen en el listado por defecto.

Para verlos, active `Mostrar eliminados`.

Al activar este filtro, el listado mostrara usuarios eliminados compatibles con la busqueda actual.

## Roles

La aplicacion distingue dos roles:

| Rol | Acceso |
| --- | --- |
| Administrador | Puede acceder a `Usuarios` y gestionar cuentas. |
| Usuario normal | Puede usar funcionalidades generales permitidas, pero no ve `Usuarios`. |

Si cambia el rol de un usuario, el cambio se aplica a partir del siguiente login de ese usuario.

## Administrador inicial

En una instalacion nueva existe un administrador inicial (se crea solo la primera vez que arranca la aplicacion):

| Usuario | Contrasena | Rol |
| --- | --- | --- |
| `admin` | `admin` | Administrador |

Estas credenciales son de desarrollo y deben cambiarse en un entorno real.

## Mensajes habituales

### `El usuario es obligatorio.`

Debe indicar un nombre de usuario.

### `El nombre visible es obligatorio.`

Debe indicar el nombre que se mostrara para la cuenta.

### `El email es obligatorio.`

Debe indicar un email.

### `El email no tiene un formato valido.`

Revise que el email tenga un formato similar a `ejemplo@mail.com`.

### `La contrasena debe tener mas de 4 caracteres.`

Use una contrasena mas larga.

### `Ya existe un usuario con ese nombre.`

El nombre de usuario ya esta en uso.

### `Ya existe un usuario con ese email.`

El email ya esta asignado a otro usuario.

### `No puede modificar su propio usuario desde esta pantalla.`

Debe usar otro administrador para modificar esa cuenta.

### `Debe existir al menos un administrador activo.`

La operacion dejaria la aplicacion sin administradores disponibles.

### `El usuario esta eliminado.`

La cuenta fue eliminada logicamente y no puede reactivarse.

## Limitaciones actuales

En esta version:

- Los usuarios se guardan en `users.json` en el mismo directorio que el ejecutable.
- No hay doble factor.
- No hay recuperacion de contrasena.
- No hay auditoria visible de cambios administrativos.
- No hay envio de emails.

## Recomendaciones

- Cambie la contrasena del administrador inicial en instalaciones reales.
- Mantenga al menos dos administradores activos para evitar bloqueos operativos.
- Use emails reales si se va a implementar recuperacion de contrasena o doble factor.
- Elimine logicamente solo cuentas que no deban volver a usarse.
