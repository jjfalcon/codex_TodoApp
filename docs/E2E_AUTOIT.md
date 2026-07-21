# E2E con AutoIt

## Objetivo

Validar flujos basicos de la aplicacion VCL desde fuera del proceso, usando AutoIt para automatizar ventanas y controles.

## Instalacion local

Se usa AutoIt portable, extraido en:

```text
.tools\autoit\install\
```

La carpeta `.tools/` esta ignorada por Git. Para una maquina nueva, descargar la version portable oficial de AutoIt y extraerla dejando disponible:

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
- El login crea el administrador por defecto si no existe `users.json`.
- Este primer test es deliberadamente pequeno: sirve como prueba de vida del stack E2E antes de ampliar cobertura funcional.
