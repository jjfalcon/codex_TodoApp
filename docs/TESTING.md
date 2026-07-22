# Niveles de test del proyecto

Este proyecto usa cuatro niveles de verificacion. La nomenclatura consensuada es:

- `unitTest`
- `coverageTest`
- `mutationTest`
- `e2eTest`

## unitTest

Pruebas de consola del nucleo, sin frameworks externos.

Ubicacion:

```text
tests\App.Core.Tests\
```

Runner:

```text
tests\App.Core.Tests\AppCoreTests.dpr
```

Que cubre:

- Reglas de negocio de `src\App.Core`.
- Validaciones de entrada.
- Casos de error.
- Cambios de estado.
- Login, sesion y permisos.
- Usuarios, tareas, configuracion, repositorios y preferencias.
- Persistencia mediante repositorios fake o ficheros de prueba.

Ejecucion:

```bat
cd tests\App.Core.Tests
dcc32 "-U..\..\src\App.Core" AppCoreTests.dpr
AppCoreTests.exe
```

Uso esperado:

- Obligatorio en cada cambio de nucleo.
- Primer nivel del ciclo TDD rojo, verde, refactor.

## coverageTest

Medicion de cobertura de lineas del nucleo con DelphiCodeCoverage.

Script:

```text
tests\App.Core.Tests\coverage.bat
```

Que hace:

- Compila `AppCoreTests.dpr` con mapa detallado (`-GD`).
- Ejecuta `AppCoreTests.exe` mediante DelphiCodeCoverage.
- Genera informe HTML/XML en `tests\App.Core.Tests\coverage\`.
- Falla si el runner reporta tests fallidos o no se genera el informe.

Ejecucion:

```bat
cd tests\App.Core.Tests
coverage.bat
```

Uso esperado:

- Medicion periodica de salud de la suite.
- Antes de subir umbrales de cobertura.
- Antes de cerrar deuda de cobertura.

Estado documentado:

- Cobertura global previa: 92%, 799 de 868 lineas cubiertas.
- `AppCoreUserService.pas` quedaba como modulo prioritario por menor cobertura relativa.

## mutationTest

Pruebas de mutacion para comprobar que los tests detectan cambios artificiales en reglas criticas.

Runner:

```text
tests\App.Core.Tests\mutation.bat
```

Mutaciones:

```text
tests\App.Core.Tests\mutations\
```

Que hace:

- Exige arbol Git limpio por defecto.
- Ejecuta una linea base de `unitTest`.
- Aplica cada patch de mutacion con `git apply`.
- Fuerza recompilacion con `dcc32 -B`.
- Ejecuta `AppCoreTests.exe`.
- Marca `Killed` si la compilacion o los tests fallan.
- Marca `Survived` si los tests pasan con la mutacion aplicada.
- Revierte cada patch con `git apply -R`.
- Genera `mutation-report.txt` y logs locales `mutation-*.log`.

Ejecucion:

```bat
cd tests\App.Core.Tests
mutation.bat
```

Uso esperado:

- Validacion fuerte de reglas criticas.
- Convertir mutantes supervivientes en nuevos tests TDD.
- Ampliar con nuevos patches cuando se identifiquen reglas sensibles.

Estado actual:

- 11 mutantes automatizados (`M001` a `M011`).
- 11 mutantes muertos.
- 0 supervivientes conocidos.

## e2eTest

Pruebas end-to-end de la aplicacion VCL desde fuera del proceso, usando AutoIt.

Ubicacion:

```text
tests\App.Win.E2E\
```

Runner actual:

```text
tests\App.Win.E2E\run-smoke-login.bat
```

Que cubre ahora:

- Compila `src\App.Win\WindowsApp.dpr`.
- Prepara un runtime aislado.
- Abre la aplicacion VCL.
- Hace login con `admin` / `admin`.
- Verifica que aparece la ventana principal `Delphi TDD App - FMain`.

Ejecucion:

```bat
cd tests\App.Win.E2E
run-smoke-login.bat
```

Uso esperado:

- Smoke de integracion UI Windows.
- Validar que la app arranca y el flujo basico de login funciona.
- Ampliar despues con flujos de tareas y diagnosticos de fallo.

## Politica recomendada

- Para cambios de `src\App.Core`: ejecutar `unitTest`.
- Para cambios en reglas criticas: ejecutar `unitTest` y `mutationTest`.
- Para cambios que afecten a cobertura o deuda tecnica: ejecutar `coverageTest`.
- Para cambios de `src\App.Win`, login o wiring UI-nucleo: ejecutar `unitTest` y `e2eTest`.
- Antes de entregar una funcionalidad completa de riesgo medio/alto: ejecutar todos los niveles aplicables.
