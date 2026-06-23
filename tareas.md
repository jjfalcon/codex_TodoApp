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

### Lote inicial de mutation testing manual

- Se probaron 4 mutantes acotados en `AppCoreTaskService.pas` y `AppCoreConfiguration.pas`.
- Resultado: 4 mutantes muertos, 0 supervivientes.
- M001: guardar `ATitle` sin `Trim` al crear tarea. Lo mata `CreateTaskStoresTrimmedPendingTask`.
- M002: filtrar `tsCompleted` en `ListPendingTasks`. Lo mata `ListPendingTasksReturnsOnlyPendingTasks`.
- M003: buscar contra titulo sin `UpperCase`. Lo mata `SearchTasksReturnsMatchingTitles`.
- M004: usar ruta relativa sin `ExpandFileName`. Lo matan `Reads_dataPath` y `Reads_connectionString`.
- Los tests relevantes detectados fueron `CreateTaskStoresTrimmedPendingTask`, `ListPendingTasksReturnsOnlyPendingTasks`, `SearchTasksReturnsMatchingTitles`, `Reads_dataPath` y `Reads_connectionString`.
- Se documento el detalle en `docs/MUTATION_TESTING.md`.
- Verificacion final: tras restaurar las mutaciones temporales, `AppCoreTests.exe` termina con `All tests passed`.

### Segundo lote de mutation testing manual

- Se probaron 7 mutantes en `AppCoreAuth.pas` y `AppCoreUserService.pas`.
- Resultado: 6 mutantes muertos y 1 superviviente.
- M005: no incrementar `FailedAttempts` con password incorrecto. Lo matan `Login_increments_failed_attempts_for_wrong_password` y `Login_locks_user_after_three_consecutive_failures`.
- M006: bloquear solo con mas de 3 fallos, no con 3. Lo mata `Login_locks_user_after_three_consecutive_failures`.
- M007: permitir login de usuario inactivo. Lo mata `Login_rejects_inactive_user`.
- M008: permitir login de usuario bloqueado. Lo mata `Login_rejects_locked_user_even_with_valid_password`.
- M009: permitir automodificacion de usuario. Lo mata `UpdateUser_rejects_self_modification`.
- M010: permitir editar/reactivar usuario eliminado. Lo mata `DeleteUser_rejects_reactivation`.
- M011: desactivar la proteccion de ultimo administrador activo. Sobrevive.
- Los tests relevantes detectados fueron `Login_increments_failed_attempts_for_wrong_password`, `Login_locks_user_after_three_consecutive_failures`, `Login_rejects_inactive_user`, `Login_rejects_locked_user_even_with_valid_password`, `UpdateUser_rejects_self_modification` y `DeleteUser_rejects_reactivation`.
- Superviviente: la proteccion de ultimo administrador activo no esta cubierta por la suite actual.
- Verificacion final: tras restaurar las mutaciones temporales, `AppCoreTests.exe` termina con `All tests passed`.

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

### Ampliar mutation testing a autenticacion y usuarios

- Probar mutantes en filtros y busqueda de `AppCoreUserService.pas`.
- Probar mutantes en persistencia de campos criticos de `AppCoreUserFileRepository.pas`.
- Registrar supervivientes y convertirlos en nuevos tests TDD.

### Cubrir regla de ultimo administrador activo

- El mutante M011 sobrevivio al desactivar `AssertCanRemoveAdminAccess`.
- Agregar tests que verifiquen que no se puede desactivar, bloquear, eliminar ni degradar el ultimo administrador activo.
- Los tests deberian esperar `ELastAdminError`.
