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

## Smoke test de login

Ejecutar:

```bat
cd tests\App.Win.E2E
run-smoke-login.bat
```

El runner:

- Compila `src\App.Win\WindowsApp.dpr`.
- Crea `tests\App.Win.E2E\runtime\`.
- Copia `WindowsApp.exe` y `app.config` al runtime.
- Ejecuta `smoke_login.au3` con AutoIt.
- Usa credenciales `admin` / `admin`.
- Verifica que aparece la ventana principal `Delphi TDD App - FMain`.

El test devuelve `0` si pasa y un codigo distinto de cero si falla.

## Notas

- El runtime esta ignorado por Git.
- El ZIP de descarga `autoit-v3.zip` esta ignorado por Git.
- El login crea el administrador por defecto si no existe `users.json`.
- Este primer test es deliberadamente pequeno: sirve como prueba de vida del stack E2E antes de ampliar cobertura funcional.
