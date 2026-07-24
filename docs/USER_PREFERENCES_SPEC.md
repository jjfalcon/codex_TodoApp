# Especificacion funcional: Preferencias

## Objetivo

Separar configuracion de aplicacion y preferencias personales sin mezclar reglas con la UI VCL.

## Alcance actual

- Recordar el ultimo usuario escrito en el login como preferencia de aplicacion local.
- Recordar idioma activo del usuario autenticado.
- Recordar ultima opcion activa de `FMain` del usuario autenticado.
- Permitir ver y editar preferencias desde un formulario embebido en `FMain`.

## Persistencia

`app.config` queda para configuracion tecnica y preferencias de aplicacion/dispositivo:

```ini
[Persistence]
Backend=json
DataPath=.

[Localization]
Language=es
File=languages.csv

[Login]
LastUsername=admin

[Updates]
Enabled=true
ManifestUrl=https://github.com/jjfalcon/codex_TodoApp/releases/latest/download/latest.json
DownloadDir=updates
```

El repositorio de usuarios guarda las preferencias personales dentro de cada usuario
en el campo de texto `preferencesText`. El contenido usa formato INI para poder
anadir secciones futuras sin cambiar el contrato JSON:

```json
{
  "id": "user-1",
  "username": "admin",
  "preferencesText": "[User]\r\nActiveLanguage=es\r\nLastMainOption=TSK\r\n\r\n[Grid.TSK]\r\nFilter.title=urgente\r\nSort.Field=title\r\nSort.Ascending=1\r\n"
}
```

No hay migracion desde claves antiguas de `app.config`. Las claves antiguas `Localization.Language` y `Main.LastOption` no se usan como preferencias personales; `Localization.Language` queda como idioma base de arranque antes del login.

## Aplicacion

- `LastUsername` se aplica al abrir `FrmLogin` para precargar el campo usuario.
- Al entrar, `FrmMain` carga `[User] ActiveLanguage` desde `User.PreferencesText` y reaplica la localizacion si existe.
- `FrmMain` abre `[User] LastMainOption`; si no existe, no es valida o no esta permitida por rol, abre `Dashboard`.
- Al navegar por `Dashboard`, `TSK` o `USR`, `FrmMain` guarda la opcion en `[User] LastMainOption`.
- Al guardar desde `FrmPreferences`, `TPreferencesService` valida y guarda idioma/pantalla en el usuario activo.
- Cada `TFrmCrud` guarda filtros, orden y layout de columnas en secciones `[Grid.<clave>]` del usuario activo.

## Pantalla de preferencias

Campos visibles:

- Ultimo usuario: solo lectura, desde preferencias de app.
- Idioma: editable mediante combo con valores `es` y `en`, guardado en el usuario activo.
- Pantalla de inicio: editable mediante combo con valores internos `Dashboard`, `TSK` y `USR`, guardado en el usuario activo.

## Reglas

- La contrasena nunca se guarda como preferencia.
- Las preferencias personales no se guardan en `app.config`.
- Las preferencias de un usuario no se mezclan con las de otro.
- Los filtros, orden, visibilidad, ancho e indice de columnas tampoco se guardan en `app.config`.
- Si un usuario no tiene preferencias, se usan defaults de UI: `es` y `Dashboard`.
- Solo se aceptan idiomas `es` y `en`.
- Solo se aceptan opciones iniciales `Dashboard`, `TSK` y `USR`.

## Secciones INI

- `[User] ActiveLanguage`: idioma personal.
- `[User] LastMainOption`: opcion inicial personal.
- `[Grid.<clave>] Filter.<campo>`: filtro activo por columna.
- `[Grid.<clave>] Sort.Field`: campo de orden.
- `[Grid.<clave>] Sort.Ascending`: `1` ascendente, `0` descendente.
- `[Grid.<clave>] <campo>.Visible`: `1` visible, `0` oculto.
- `[Grid.<clave>] <campo>.Width`: ancho de columna.
- `[Grid.<clave>] <campo>.Index`: orden visual de columna.

## Componentes

- `src\App.Core\AppCoreIniText.pas`: lector/escritor pequeno de texto INI.
- `src\App.Core\AppCoreUser.pas`: campo `TUser.PreferencesText`.
- `src\App.Core\AppCorePreferences.pas`: `IAppPreferencesRepository`, implementacion en memoria y `TPreferencesService`.
- `src\App.Core\AppCorePreferencesFileRepository.pas`: `LastUsername` en `app.config`.
- `src\App.Core\AppCoreUserFileRepository.pas`: persistencia JSON de preferencias personales dentro de usuario.
- `src\App.Core\AppCoreUserPreferencesRepository.pas`: adaptador `ICrudGridLayoutRepository` sobre `User.PreferencesText`.
- `src\App.Win\PreferencesForm.pas`: formulario VCL embebible de preferencias.
