# Manual de usuario: Acerca de

## Objetivo

La pantalla `Acerca de` muestra informacion basica de la aplicacion, su version, titularidad y datos tecnicos utiles para soporte.

## Abrir Acerca de

1. Inicie sesion en la aplicacion.
2. Se abrira la pantalla principal `FMain`.
3. En la barra lateral izquierda, pulse `Acerca de` (ubicado al final).
4. Se mostrara una ventana con la informacion de la aplicacion.

## Informacion mostrada

La ventana `Acerca de` contiene dos secciones:

### Informacion de la aplicacion

- **Nombre**: `Delphi TDD App`
- **Version**: `1.0.0`
- **Descripcion**: `Aplicacion Windows desarrollada en Delphi siguiendo principios TDD.`
- **Copyright**: `Copyright 2026`

### Informacion tecnica

- Version del ejecutable.
- Sistema operativo.
- Arquitectura.
- Fecha de compilacion.
- Base de datos.

## No disponible

Si un dato tecnico no esta disponible, se mostrara el texto `No disponible`.

Por ejemplo, si la aplicacion aun no tiene conexion a base de datos, el campo correspondiente mostrara `No disponible`.

## Cerrar el formulario

Pulse `Aceptar` para cerrar la ventana `Acerca de`.

Al cerrarla, volvera a la pantalla desde la que la abrio, sin cambios en la sesion ni en los datos de la aplicacion.

## Mensajes habituales

No hay mensajes de error especificos para esta pantalla. La informacion se muestra de forma directa, sin interaccion del usuario.

## Limitaciones actuales

En esta version:

- La version del ejecutable es `1.0.0` fija.
- No se muestra la arquitectura real del sistema.
- No se muestra la fecha de compilacion real.
- No hay conexion a base de datos.
- No se muestra logo de la aplicacion.
- `Acerca de` solo esta disponible despues de iniciar sesion.

## Recomendaciones

- Use esta pantalla para confirmar la version instalada.
- Si necesita soporte, los datos tecnicos visibles pueden ayudar a identificar la instalacion.
- Si algun dato aparece como `No disponible`, no indica necesariamente un fallo; puede tratarse de informacion no implementada aun en la aplicacion.
