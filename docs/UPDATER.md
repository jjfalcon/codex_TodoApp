# Updater

## Objetivo

Preparar una comprobacion manual de actualizaciones desde GitHub Releases sin modificar la instalacion actual.

El flujo actual solo descarga y valida un paquete candidato. No instala, reemplaza ni ejecuta archivos descargados.

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

`app.default.config` incluye valores seguros:

```ini
[Updates]
Enabled=false
ManifestUrl=
DownloadDir=updates
```

Mientras `Enabled=false` o no exista `ManifestUrl`, la aplicacion no debe consultar actualizaciones.
