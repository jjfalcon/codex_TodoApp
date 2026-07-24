# Updater

## Objetivo

Preparar una comprobacion manual de actualizaciones desde GitHub Releases y aplicar el paquete verificado.

El flujo descarga y valida un paquete candidato antes de programar cualquier reemplazo de archivos.

## Manifest

El updater usa `latest.json` como contrato:

```json
{
  "version": "1.0.0.53",
  "commit": "154d65b",
  "buildDate": "2026-07-24",
  "publishedAt": "2026-07-24",
  "package": "TodoApp-1.0.0.53-154d65b.zip",
  "sha256": "..."
}
```

Campos obligatorios:

- `version`
- `package`
- `sha256`

Si `package` es relativo, se resuelve contra la ubicacion de `latest.json`.

## Script manual

Comprobar una actualizacion:

```bat
scripts\check-update.bat releases\latest.json 1.0.0.52 updates
```

Con una URL publicada:

```bat
scripts\check-update.bat https://example.com/latest.json 1.0.0.52 updates
```

El script:

- Lee el manifest.
- Compara `version` con la version actual.
- Descarga o copia el ZIP candidato.
- Calcula SHA-256.
- Borra el ZIP descargado si el hash no coincide.
- Informa si no hay actualizacion o si hay paquete verificado.

## Configuracion

`app.default.config` incluye la URL estable de GitHub Releases:

```ini
[Updates]
Enabled=true
ManifestUrl=https://github.com/jjfalcon/codex_TodoApp/releases/latest/download/latest.json
DownloadDir=updates
```

Mientras `Enabled=false` o no exista `ManifestUrl`, la aplicacion no consulta actualizaciones.

Si el `app.config` local no contiene seccion `[Updates]`, la comprobacion desde la UI usa `app.default.config` como fallback. Esto permite mantener preferencias locales fuera de la configuracion base sin dejar el boton sin updater.

## Boton en Acerca de

El formulario `Acerca de` incluye el boton `Buscar actualizacion`.

Al pulsarlo, la ventana usa el checker configurado desde `FMain`, lee `[Updates]` en `app.config`, consulta el manifest, descarga el ZIP candidato en `DownloadDir` y valida su SHA-256.

El resultado se muestra en una sola linea dentro del propio formulario.

Cuando hay una version superior y el ZIP pasa la validacion SHA-256, la aplicacion crea un `.bat` temporal que:

- Espera a que termine el proceso actual.
- Extrae el ZIP verificado en una carpeta temporal.
- Copia los archivos extraidos sobre el directorio de instalacion.
- Relanza `WindowsApp.exe`.

Despues de crear el aplicador externo, la aplicacion se cierra para que el ejecutable pueda reemplazarse.

## Publicacion real

La release `v1.0.0.54` se publico en GitHub con:

- `TodoApp-1.0.0.54-0ec2256.zip`
- `TodoApp-1.0.0.54-0ec2256.sha256`
- `TodoApp-1.0.0.54-0ec2256.json`
- `latest.json`

URL:

```text
https://github.com/jjfalcon/codex_TodoApp/releases/tag/v1.0.0.54
```

El updater manual se valido contra:

```text
https://github.com/jjfalcon/codex_TodoApp/releases/download/v1.0.0.54/latest.json
```

La aplicacion queda configurada contra la URL estable:

```text
https://github.com/jjfalcon/codex_TodoApp/releases/latest/download/latest.json
```
