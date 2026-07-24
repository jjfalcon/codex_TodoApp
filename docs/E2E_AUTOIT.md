# E2E con AutoIt

## Objetivo

Validar flujos basicos de la aplicacion VCL desde fuera del proceso, usando AutoIt para automatizar ventanas y controles.

Dentro de la taxonomia de `docs\TESTING.md`, este nivel se llama `e2eTest`.

## Instalacion local

Se usa AutoIt portable, extraido en:

```text
.tools\autoit\install\
```

La carpeta `.tools\autoit\` esta versionada para que el smoke test pueda ejecutarse sin instalacion global. Si se quiere actualizar AutoIt, descargar la version portable oficial y reemplazar el contenido dejando disponible:

```text
.tools\autoit\install\AutoIt3.exe
```

## Smoke test de login y tareas

Ejecutar:

```bat
cd tests\App.Win.E2E
run-smoke-login.bat
```

El runner:

- Compila `src\App.Win\WindowsApp.dpr`.
- Crea `tests\App.Win.E2E\runtime\`.
- Copia `WindowsApp.exe`, `app.default.config` como `app.config`, `languages.csv` y `sqlite3.dll` al runtime.
- Ejecuta `smoke_login.au3` con AutoIt.
- Usa credenciales `admin` / `admin`.
- Verifica que aparece la ventana principal.
- Abre `Tareas`, implementada mediante el CRUD generico `TSK`.
- Crea una tarea con titulo unico desde el formulario de detalle.
- Verifica que la tarea se guarda en el backend configurado en `app.config`.
- Marca la tarea como completada desde el detalle.
- Verifica que el backend configurado conserva el estado `completed`.
- Exporta el grid de `Tareas` a CSV desde el boton `CSV`.
- Verifica que el CSV contiene la tarea creada y usa separador `;`.
- Emite diagnosticos con listado de ventanas, clases y controles si falla.
- Guarda una captura de pantalla en `tests\App.Win.E2E\runtime\diagnostics\failure.png` si falla.

El test devuelve `0` si pasa y un codigo distinto de cero si falla.

## Smoke test contra release

Despues de generar un ZIP con `scripts\release-windows.bat`, se puede validar el paquete:

```bat
cd tests\App.Win.E2E
run-release-smoke.bat
```

El runner descomprime el ultimo ZIP de `releases\` en `runtime-release`, valida que contiene `WindowsApp.exe`, `app.config`, `languages.csv` y `sqlite3.dll`, y ejecuta el mismo smoke contra el ejecutable empaquetado.

## Notas

- El runtime esta ignorado por Git.
- `runtime-release` esta ignorado por Git.
- El ZIP de descarga `autoit-v3.zip` esta ignorado por Git.
- El login crea el administrador por defecto si no existen usuarios en el backend configurado.
- El test usa un runtime aislado para que los datos locales y `app.config` no contaminen el entorno de desarrollo.
