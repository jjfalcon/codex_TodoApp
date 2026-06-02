# Manual de usuario: Login

## Objetivo

El login permite acceder a la aplicacion solo a usuarios autorizados.

Para entrar, debe indicar su nombre de usuario y contrasena. Si los datos son correctos, la aplicacion abre la pantalla principal.

## Abrir la aplicacion

1. Ejecute la aplicacion.
2. Se mostrara la ventana `Login`.
3. La pantalla principal no estara disponible hasta iniciar sesion correctamente.

## Iniciar sesion

1. Escriba su usuario en el campo `Usuario`.
2. Escriba su contrasena en el campo `Contrasena`.
3. Pulse `Entrar`.

Si las credenciales son validas, se abrira la pantalla principal `FMain`.

## Cancelar el acceso

Pulse `Cancelar` para cerrar el login sin iniciar sesion.

Si cancela el login, la aplicacion no abrira la pantalla principal.

## Mensajes habituales

### `El usuario es obligatorio.`

Debe escribir un nombre de usuario antes de pulsar `Entrar`.

### `La contrasena es obligatoria.`

Debe escribir una contrasena. Una contrasena formada solo por espacios se considera vacia.

### `Usuario o contrasena incorrectos.`

El usuario o la contrasena no coinciden con una cuenta valida.

Por seguridad, la aplicacion no indica cual de los dos datos es incorrecto.

### `El usuario no esta activo.`

La cuenta existe, pero no esta activa. Contacte con el administrador o soporte.

### `El usuario esta bloqueado por demasiados intentos fallidos.`

La cuenta fue bloqueada por varios intentos incorrectos consecutivos. Contacte con el administrador o soporte.

## Bloqueo por intentos fallidos

Si introduce una contrasena incorrecta 3 veces consecutivas para el mismo usuario, la cuenta queda bloqueada.

Una vez bloqueada, la cuenta no podra iniciar sesion aunque luego se escriba la contrasena correcta.

## Ultimo usuario usado

La aplicacion puede recordar el ultimo nombre de usuario utilizado para facilitar el siguiente acceso.

La contrasena nunca se recuerda.

## Roles de usuario

La aplicacion distingue dos tipos de usuario:

- Administrador.
- Usuario normal.

Ambos pueden entrar a la pantalla principal si sus credenciales son correctas.

El administrador puede ver opciones reservadas como `Usuarios`. Un usuario normal no vera ni podra ejecutar esas opciones.

## Usuarios de desarrollo

En esta version de desarrollo existen estos usuarios de prueba:

| Usuario | Contrasena | Rol | Estado |
| --- | --- | --- | --- |
| `admin` | `admin123` | Administrador | Activo |
| `user` | `user123` | Usuario normal | Activo |
| `disabled` | `disabled123` | Usuario normal | Inactivo |
| `locked` | `locked123` | Usuario normal | Bloqueado |

Estos usuarios son solo para pruebas y desarrollo.

## Sesion

Al iniciar sesion correctamente, la aplicacion crea una sesion activa.

La sesion puede expirar por inactividad. En esta version, el tiempo configurado es de 15 minutos.

Cuando la sesion expire, debera volver a iniciar sesion para acceder a funcionalidades protegidas.

## Recomendaciones

- No comparta su contrasena.
- Compruebe que escribe el usuario correcto antes de repetir intentos.
- Si la cuenta queda bloqueada, solicite ayuda al administrador o soporte.
- Cierre la aplicacion si termina de trabajar en un equipo compartido.
