# Monitorizacion local

## Objetivo

Detectar errores y degradacion de la aplicacion mediante un log local sencillo,
sin guardar datos sensibles.

## Ubicacion

La aplicacion escribe el log en:

```text
logs\application.log
```

La ruta es relativa al directorio del ejecutable.

## Formato

Cada linea usa este formato:

```text
timestamp level event durationMs message
```

Ejemplos:

```text
2026-07-23T10:24:01 INFO App.Start Application started
2026-07-23T10:24:01 TIMING Auth.Login durationMs=16 result=ok username=admin
```

## Eventos iniciales

- `App.Start`: arranque de la aplicacion.
- `App.Stop`: cierre de la aplicacion.
- `App.UnhandledException`: excepcion no controlada en VCL.
- `Auth.Login`: intento de login con duracion.

## Privacidad

El logger sanea valores con claves sensibles antes de escribir:

- `password=`
- `pwd=`
- `token=`
- `secret=`
- `connectionstring=`

No se debe registrar nunca una contrasena en claro ni cadenas de conexion completas.

## Verificacion

El E2E comprueba que se genera `logs\application.log` y que contiene:

- `INFO App.Start`
- `TIMING Auth.Login`

Las operaciones de tareas se validan en el E2E mediante persistencia en `tasks.json`.
