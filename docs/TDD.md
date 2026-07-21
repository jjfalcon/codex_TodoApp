# Guia TDD del proyecto

## Regla de oro

La UI no contiene reglas de negocio. La ventana llama a servicios del nucleo, y el nucleo se prueba con un ejecutable de consola.

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

## Patron recomendado

Cada caso nuevo empieza en `App.Core.Tests`.

Ejemplo:

```pascal
[Test]
procedure Cannot_create_task_with_empty_title;
```

Luego se implementa la regla en `App.Core`, y solo despues se conecta desde `App.Win`.

## Cobertura

La herramienta recomendada para este proyecto es DelphiCodeCoverage.

Requisitos:

- `dcc32` disponible en el `PATH`.
- `CodeCoverage.exe` versionado en `.tools\delphi-code-coverage\`.

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
