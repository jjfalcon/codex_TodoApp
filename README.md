# Delphi Windows App - base TDD

Este repositorio contiene una base para una aplicacion Windows en Delphi siguiendo TDD.
Esta preparada para compilar con Delphi 7, usando un runner de pruebas propio para no depender de paquetes externos.

## Estructura

- `src/App.Core`: reglas de negocio, interfaces y servicios testeables.
- `src/App.Win`: aplicacion VCL Windows, fina y conectada al nucleo.
- `tests/App.Core.Tests`: pruebas del nucleo ejecutables por consola.
- `tests/App.Win.E2E`: smoke tests E2E de la aplicacion VCL.
- `docs/TDD.md`: forma de trabajo recomendada.
- `docs/ARCHITECTURE.md`: arquitectura minima y reglas de ubicacion de codigo.
- `docs/TESTING.md`: niveles de test consensuados del proyecto.
- `docs/MONITORING.md`: monitorizacion local, timings y diagnostico.
- `docs/USER_PREFERENCES_SPEC.md`: preferencias locales de usuario.
- `docs/SESIONES.md`: documentacion técnica de las sesiones.

## Primer flujo TDD

1. Escribir una prueba en `tests/App.Core.Tests`.
2. Ejecutar pruebas y verlas fallar.
3. Implementar lo minimo en `src/App.Core`.
4. Ejecutar pruebas y dejarlas en verde.
5. Refactorizar sin cambiar comportamiento.
6. Conectar la funcionalidad a la UI VCL.

## Abrir en Delphi

1. Abre `tests/App.Core.Tests/AppCoreTests.dpr` para ejecutar las pruebas.
2. Abre `src/App.Win/WindowsApp.dpr` para ejecutar la aplicacion VCL.

Tambien puedes compilar desde consola:

```bat
cd tests\App.Core.Tests
dcc32 "-U..\..\src\App.Core" AppCoreTests.dpr
AppCoreTests.exe

cd ..\..\src\App.Win
dcc32 "-U..\App.Core" WindowsApp.dpr
```

## Niveles de test

La taxonomia de verificacion del proyecto esta documentada en `docs/TESTING.md`:

- `unitTest`: runner propio de consola para `src\App.Core`.
- `coverageTest`: cobertura con DelphiCodeCoverage.
- `mutationTest`: runner propio de mutaciones `M001`-`M017`.
- `e2eTest`: smoke E2E con AutoIt para la app VCL.

La funcionalidad inicial es una lista de tareas sencilla. Es deliberadamente pequena: sirve como patron para CRUD, validaciones, repositorios, servicios, pruebas y conexion con la interfaz.
