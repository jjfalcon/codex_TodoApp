# Tareas

## Realizadas

### Filtro de tareas pendientes

- Se agrego `ITaskService.ListPendingTasks` y su implementacion en `TTaskService`.
- La regla queda en `src/App.Core`; la UI solo llama al servicio y refresca la lista.
- Se agrego la prueba `ListPendingTasksReturnsOnlyPendingTasks`.
- Se conecto un boton `Pendientes` en `TFrmTasks`.
- Verificacion: la prueba nueva pasa y la aplicacion VCL compila.

### Integracion de DelphiCodeCoverage

- Se agrego `tests/App.Core.Tests/coverage.bat`.
- El script compila `AppCoreTests.dpr` con mapa detallado (`-GD`).
- Ejecuta `CodeCoverage.exe` contra el runner de tests.
- Genera informe HTML/XML en `tests/App.Core.Tests/coverage/`.
- Devuelve error si el informe no se genera o si el runner reporta tests fallidos.
- Se documento el uso en `docs/TDD.md`.
- Se ignoraron los artefactos generados de cobertura y el INI temporal de tests.
- Resultado actual: 92% de cobertura de lineas, 799 de 868 lineas cubiertas.

### Correccion de tests de configuracion

- Se corrigieron los fallos `Reads_dataPath` y `Reads_connectionString`.
- Causa: `TIniFile` podia resolver rutas relativas de forma distinta a `FileExists`.
- Solucion: `TAppConfiguration` expande el nombre de fichero con `ExpandFileName` antes de comprobarlo y abrirlo.
- Verificacion: `AppCoreTests.exe` termina con `All tests passed`.
- Verificacion adicional: `coverage.bat` termina correctamente con todos los tests en verde.

## Pendientes

### Mejorar cobertura de `AppCoreUserService`

- Cobertura actual: 85%, 128 de 150 lineas.
- Es el fichero con menor cobertura del nucleo.
- Revisar ramas no cubiertas antes de subir el umbral global de cobertura.

### Definir umbral minimo de cobertura

- La medicion ya existe, pero no hay politica de corte.
- Propuesta inicial: no bajar del 90% global y subir despues por modulos criticos.
- El umbral deberia aplicarse en script o CI cuando exista integracion continua.

### Validar DelphiCodeCoverage en entorno limpio

- En esta maquina `CodeCoverage.exe` esta disponible en el `PATH`.
- Falta documentar o automatizar de donde instalarlo para una maquina nueva.
- Confirmar que el flujo funciona igual sin artefactos previos de compilacion.

### Revisar detalle del informe generado por Delphi 7

- El resumen global y por fichero es util.
- Algunos nombres internos de clases/metodos aparecen truncados en el XML/HTML.
- No bloquea la medicion de lineas, pero conviene revisarlo si se quiere usar el informe para analisis fino por metodo.
