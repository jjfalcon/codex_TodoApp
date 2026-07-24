# Especificacion funcional: Preferencias de usuario

## Objetivo

Recordar preferencias locales de uso para mejorar el arranque de la aplicacion sin mezclar reglas con la UI VCL.

## Alcance actual

- Recordar el ultimo usuario escrito en el login.
- Recordar el idioma activo.
- Recordar la ultima opcion activa de `FMain`.
- Permitir ver y editar preferencias desde un formulario embebido en `FMain`.

## Fuera de alcance actual

- Sincronizar preferencias entre equipos.
- Guardar contrasenas o secretos.
- Preferencias por usuario autenticado en base de datos.
- Preferencias por usuario autenticado diferenciadas del fichero local.

## Persistencia

Las preferencias se guardan en `app.config`, junto al ejecutable, mediante `TFileLoginPreferencesRepository`.
El fichero `src\App.Win\app.default.config` contiene los valores base versionados para release y E2E; `app.config` puede acumular preferencias locales durante la ejecucion.

Formato actual:

```ini
[Login]
LastUsername=admin

[Localization]
Language=es

[Main]
LastOption=TSK
```

Valores definidos:

- `Login.LastUsername`: ultimo nombre de usuario no vacio usado en un intento de login.
- `Localization.Language`: idioma activo, por ejemplo `es` o `en`.
- `Main.LastOption`: ultima opcion principal abierta. Valores internos: `Dashboard`, `TSK`, `USR`.

## Aplicacion

- `LastUsername` se aplica al abrir `FrmLogin` para precargar el campo usuario.
- `Language` se aplica al crear el servicio de localizacion durante el arranque.
- Si `Language` se cambia desde `FrmPreferences`, la aplicacion reaplica la localizacion inmediatamente en `FMain` y en el formulario embebido actual.
- `LastOption` se aplica al configurar `FrmMain`; si la opcion guardada no es valida o no esta permitida para el rol actual, se abre `Dashboard`.

## Pantalla de preferencias

`FrmPreferences` se abre embebido desde la barra lateral de `FMain`.

Campos visibles:

- Ultimo usuario: solo lectura.
- Idioma: editable mediante combo con valores `es` y `en`.
- Pantalla de inicio: editable mediante combo con valores internos `Dashboard`, `TSK` y `USR`.

Al guardar, la UI llama a `TPreferencesService`; las validaciones permanecen en `src\App.Core`.

## Reglas

- La contrasena nunca se guarda como preferencia.
- Una actualizacion de preferencia no debe borrar las demas claves existentes.
- Si el fichero no existe, las preferencias devuelven cadena vacia.
- La UI solo lee o escribe preferencias a traves de la interfaz del nucleo.
- Solo se aceptan idiomas `es` y `en` desde la pantalla de preferencias.
- Solo se aceptan opciones iniciales `Dashboard`, `TSK` y `USR`.

## Componentes

- `src\App.Core\AppCorePreferences.pas`: interfaz `ILoginPreferencesRepository` e implementacion en memoria para tests.
- `src\App.Core\AppCorePreferences.pas`: `TPreferencesService` valida y guarda preferencias editables.
- `src\App.Core\AppCorePreferencesFileRepository.pas`: implementacion local sobre `app.config`.
- `src\App.Win\PreferencesForm.pas`: formulario VCL embebible de preferencias.
- `tests\App.Core.Tests\AppCorePreferencesFileRepositoryTests.pas`: pruebas de persistencia.
- `tests\App.Core.Tests\AppCorePreferencesServiceTests.pas`: pruebas de validacion y guardado.
- `tests\App.Win.Tests\PreferencesFormTests.pas`: pruebas unitarias del formulario VCL.
