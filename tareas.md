# Tareas

## Pendientes

### Testear form login

- visual. formulario verificado con captura
- visual. texto cargado desde lenguaje seleccionado

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

- Agregar nuevos patches automatizados para filtros y busqueda de `AppCoreUserService.pas`.
- Probar mutantes en persistencia de campos criticos de `AppCoreUserFileRepository.pas`.
- Registrar supervivientes y convertirlos en nuevos tests TDD.

### Ampliar E2E con AutoIt

- Agregar un flujo E2E de alta de tarea desde la pantalla `Tareas`.
- Agregar un flujo E2E de completar tarea y comprobar prefijo `[x]`.
- Agregar diagnosticos con captura o listado de controles cuando falle una ventana.

## Realizadas

### Documentacion de tests unitarios de forms VCL

- Se documento el patron `unitTest Forms VCL` en `docs\TESTING.md`.
- Se documento el patron TDD para formularios en `docs\TDD.md`.
- Se agrego `tests\App.Win.Tests\coverage.bat`.
- Se documento coverage de forms con DelphiCodeCoverage.
- Verificacion: `tests\App.Win.Tests\coverage.bat` termina con `All tests passed`.
- Resultado actual: `LoginForm.pas` queda en 86% de cobertura, 20 de 23 lineas cubiertas.

### Navegacion por teclado en formulario login

- Se agrego prueba unitaria para comprobar el recorrido con `TAB`: usuario, password, entrar, cancelar.
- Se agrego prueba unitaria para comprobar que `CR` ejecuta el boton por defecto `Entrar`.
- Se simulan teclas mediante `CM_DIALOGKEY` sobre `TFrmLogin`.
- Verificacion: `tests\App.Win.Tests\run-tests.bat` termina con `All tests passed`.

### Tests unitarios de formulario login

- Se agrego `tests\App.Win.Tests\AppWinTests.dpr`.
- Se agrego `tests\App.Win.Tests\LoginFormTests.pas`.
- Se agrego `tests\App.Win.Tests\run-tests.bat`.
- Se cubre foco inicial en usuario.
- Se cubre orden de tabulacion: usuario, password, entrar, cancelar.
- Se cubre que password oculta el texto introducido.
- Se cubre que errores de autenticacion se visualizan en el formulario.
- Se cubre que el boton Entrar llama al servicio de autenticacion inyectado.
- Se agrego `TFrmLogin.ConfigureForTests` para inyectar `IAuthService` sin crear repositorios reales.
- Verificacion: `run-tests.bat` termina con `All tests passed`.
- Verificacion adicional: `AppCoreTests.exe` termina con `All tests passed` y `WindowsApp.dpr` compila.

### Filtro de tareas pendientes

- Se agrego `ITaskService.ListPendingTasks` y su implementacion en `TTaskService`.
- La regla queda en `src/App.Core`; la UI solo llama al servicio y refresca la lista.
- Se agrego la prueba `ListPendingTasksReturnsOnlyPendingTasks`.
- Se conecto un boton `Pendientes` en `TFrmTasks`.
- Verificacion: la prueba nueva pasa y la aplicacion VCL compila.

### Integracion de DelphiCodeCoverage

- Se agrego `tests/App.Core.Tests/coverage.bat`.
- Se versiono `CodeCoverage.exe` en `.tools\delphi-code-coverage\`.
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

### Smoke E2E con AutoIt

- Se instalo AutoIt portable en `.tools\autoit\install`.
- Se agrego `tests\App.Win.E2E\smoke_login.au3`.
- Se agrego `tests\App.Win.E2E\run-smoke-login.bat`.
- El runner compila `WindowsApp.dpr`, prepara un runtime aislado, lanza la app, hace login con `admin/admin` y verifica la ventana principal.
- Se documento el flujo en `docs\E2E_AUTOIT.md`.
- Se versiono `.tools\autoit\` para que el test no dependa de una instalacion global.
- Se ignoraron `autoit-v3.zip` y `tests/App.Win.E2E/runtime/`.
- Verificacion: `run-smoke-login.bat` termina con `Smoke login passed.`

### Cobertura de regla de ultimo administrador activo

- Se registraron y ampliaron tests en `AppCoreUserServiceTests.pas`.
- Se cubre que no se puede desactivar, bloquear, eliminar ni degradar el ultimo administrador activo.
- Los cuatro casos esperan `ELastAdminError`.
- Se ajusto el orden de validaciones en `TUserService` para priorizar la regla de administrador minimo en operaciones que retirarian acceso administrativo.
- Verificacion: `AppCoreTests.exe` termina con `All tests passed`.

### Runner automatizado de mutation testing

- Se agrego `tests\App.Core.Tests\mutation.bat`.
- Se agregaron patches para las mutaciones existentes M001-M011 en `tests\App.Core.Tests\mutations\`.
- El runner valida baseline, aplica cada patch, fuerza recompilacion, ejecuta tests y revierte la mutacion.
- Genera `mutation-report.txt` y logs locales ignorados por Git.
- Verificacion: 11 mutantes probados, 11 muertos, 0 supervivientes.

### Taxonomia de niveles de test

- Se documento la nomenclatura `unitTest`, `coverageTest`, `mutationTest` y `e2eTest`.
- Se agrego `docs\TESTING.md` como guia central.
- Se enlazo la taxonomia desde `README.md`, `docs\TDD.md`, `docs\MUTATION_TESTING.md` y `docs\E2E_AUTOIT.md`.
