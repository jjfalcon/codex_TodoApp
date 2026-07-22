# Guia TDD del proyecto

## Regla de oro

La UI no contiene reglas de negocio. La ventana llama a servicios del nucleo, y el nucleo se prueba con un ejecutable de consola.

La taxonomia completa de test esta en `docs/TESTING.md`: `unitTest`, `coverageTest`, `mutationTest` y `e2eTest`.

## Ciclo

1. Rojo: escribe una prueba que describa el comportamiento.
2. Verde: implementa lo minimo para que pase.
3. Refactor: mejora nombres, duplicacion y diseno con las pruebas en verde.

## Que probar

- Validaciones de entrada.
- Casos de error.
- Cambios de estado.
- Busquedas y filtros.
- Reglas de permisos o flujo.
- Persistencia mediante interfaces o repositorios fake.

## Que no probar primero

- Posicion exacta de botones.
- Eventos VCL triviales.
- Detalles visuales que no cambian reglas de negocio.

## Patron recomendado para nucleo

Cada caso nuevo empieza en `App.Core.Tests`.

Ejemplo:

```pascal
[Test]
procedure Cannot_create_task_with_empty_title;
```

Luego se implementa la regla en `App.Core`, y solo despues se conecta desde `App.Win`.

## Patron recomendado para forms VCL

Cuando el cambio es comportamiento propio del formulario, se prueba en `App.Win.Tests` sin arrancar toda la aplicacion:

- Crear el form con `TFrmX.Create(nil)`.
- Inyectar dependencias con un metodo acotado para tests, por ejemplo `ConfigureForTests`.
- Usar fakes para servicios del nucleo.
- Invocar eventos directamente cuando representen una accion del usuario.
- Comprobar estado observable del form: foco, `TabOrder`, `PasswordChar`, mensajes, `ModalResult` y llamadas al fake.

Estos tests no deben contener reglas de negocio. Si aparece una regla, primero debe moverse o mantenerse en `App.Core` y probarse en `App.Core.Tests`.

## Cobertura

La herramienta recomendada para este proyecto es DelphiCodeCoverage.

Requisitos:

- `dcc32` disponible en el `PATH`.
- `CodeCoverage.exe` versionado en `.tools\delphi-code-coverage\`.

Los scripts de coverage usan primero la herramienta versionada:

```text
.tools\delphi-code-coverage\CodeCoverage.exe
```

Si esa ruta no existe, intentan resolver `CodeCoverage.exe` desde el `PATH`. En una maquina nueva basta con clonar el repositorio y tener `dcc32` disponible; DelphiCodeCoverage no requiere instalacion global mientras el ejecutable versionado siga presente.

Ejecucion:

```bat
cd tests\App.Core.Tests
coverage.bat
```

El script compila `AppCoreTests.dpr` con mapa detallado (`-GD`), ejecuta `AppCoreTests.exe` mediante DelphiCodeCoverage desde `.tools\delphi-code-coverage\` y deja el informe en:

```text
tests\App.Core.Tests\coverage\
```

El informe HTML principal es `CodeCoverage_summary.html`. El XML `CodeCoverage_summary.xml` puede usarse despues para integracion continua si se anade CI.

Validacion limpia realizada el 2026-07-22:

- `tests\App.Core.Tests\coverage.bat`: `All tests passed`, 91%, 901/982 lineas.
- `tests\App.Win.Tests\coverage.bat`: `All tests passed`, 80%, 55/68 lineas.

Para forms VCL:

```bat
cd tests\App.Win.Tests
coverage.bat
```

El informe queda en:

```text
tests\App.Win.Tests\coverage\
```

## Mutation testing

Las mutaciones existentes se ejecutan con el runner propio:

```bat
cd tests\App.Core.Tests
mutation.bat
```

El runner aplica patches de `tests\App.Core.Tests\mutations\`, fuerza recompilacion y considera muerto un mutante si la compilacion o los tests fallan. Los supervivientes deben convertirse en nuevos tests TDD.

## E2E

El smoke E2E actual valida el arranque de la app VCL y el login:

```bat
cd tests\App.Win.E2E
run-smoke-login.bat
```

Estos tests no sustituyen a `unitTest`; sirven para comprobar integracion UI-nucleo desde fuera del proceso.
