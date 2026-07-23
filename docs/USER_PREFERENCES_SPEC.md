# Especificacion funcional: Preferencias de usuario

## Objetivo

Recordar preferencias locales de uso para mejorar el arranque de la aplicacion sin mezclar reglas con la UI VCL.

## Alcance actual

- Recordar el ultimo usuario escrito en el login.
- Recordar el idioma activo.
- Recordar la ultima opcion activa de `FMain`.

## Fuera de alcance actual

- Sincronizar preferencias entre equipos.
- Guardar contrasenas o secretos.
- Preferencias por usuario autenticado en base de datos.
- Editor visual de preferencias.

## Persistencia

Las preferencias se guardan en `app.config`, junto al ejecutable, mediante `TFileLoginPreferencesRepository`.

Formato actual:

```ini
[Login]
LastUsername=admin

[Localization]
Language=es

[Main]
LastOption=Tasks
```

Valores definidos:

- `Login.LastUsername`: ultimo nombre de usuario no vacio usado en un intento de login.
- `Localization.Language`: idioma activo, por ejemplo `es` o `en`.
- `Main.LastOption`: ultima opcion principal abierta. Valores internos: `Dashboard`, `Tasks`, `Users`.

## Aplicacion

- `LastUsername` se aplica al abrir `FrmLogin` para precargar el campo usuario.
- `Language` se aplica al crear el servicio de localizacion durante el arranque.
- `LastOption` se aplica al configurar `FrmMain`; si la opcion guardada no es valida o no esta permitida para el rol actual, se abre `Dashboard`.

## Reglas

- La contrasena nunca se guarda como preferencia.
- Una actualizacion de preferencia no debe borrar las demas claves existentes.
- Si el fichero no existe, las preferencias devuelven cadena vacia.
- La UI solo lee o escribe preferencias a traves de la interfaz del nucleo.

## Componentes

- `src\App.Core\AppCorePreferences.pas`: interfaz `ILoginPreferencesRepository` e implementacion en memoria para tests.
- `src\App.Core\AppCorePreferencesFileRepository.pas`: implementacion local sobre `app.config`.
- `tests\App.Core.Tests\AppCorePreferencesFileRepositoryTests.pas`: pruebas de persistencia.
