# Tareas

## Pendientes

### Crear form CRUD de tabla generica

- Definir un formulario reutilizable para CRUD de tablas.
- Acordar columnas, acciones, validaciones y puntos de extension.
- Separar reglas de negocio en `src\App.Core` y mantener la UI como capa fina.

## Realizadas

### Formulario embebido de preferencias

- Se agrego `TPreferencesService` para validar idioma y opcion inicial desde `src\App.Core`.
- Se agrego `FrmPreferences` como formulario embebible en `FMain`.
- La barra lateral de `FMain` incluye `Preferencias`.
- El formulario muestra ultimo usuario en solo lectura y permite editar idioma y pantalla de inicio.
- Al guardar un nuevo idioma, `FMain` reaplica la localizacion sin reiniciar.
- Se agregaron pruebas Core y App.Win para el flujo de preferencias.

### Especificacion de preferencias de usuario

- Se documento `docs\USER_PREFERENCES_SPEC.md`.
- Se definieron preferencias locales actuales: ultimo usuario, idioma activo y ultima opcion activa de `FMain`.
- Se acordo persistencia en `app.config` mediante `TFileLoginPreferencesRepository`.
- Se extendio `ILoginPreferencesRepository` con `ActiveLanguage` y `LastMainOption`.
- Se agregaron pruebas de persistencia para idioma activo, ultima opcion principal y conservacion de claves existentes.
- `FMain` restaura la ultima opcion activa permitida para el rol actual y guarda la navegacion seleccionada.
- Verificacion: `AppCoreTests.exe` termina con `All tests passed`.

### Monitorizacion local de errores y degradacion

- Se agrego `src\App.Core\AppCoreDiagnostics.pas`.
- Se agrego `TFileDiagnosticsLogger` para escribir `logs\application.log`.
- Se agrego `TDiagnosticTimer` para medir duracion de operaciones en milisegundos.
- Se sanean valores sensibles como `password=`, `pwd=`, `token=`, `secret=` y `connectionstring=`.
- `WindowsApp.dpr` registra `App.Start`, `App.Stop` y `App.UnhandledException`.
- `TFrmLogin` registra `Auth.Login` con resultado y duracion.
- `TFrmMain` registra apertura de `Tareas`.
- `TFrmTasks` registra `Task.Create` y `Task.Complete` con resultado y duracion.
- El E2E verifica que se genera `logs\application.log` y contiene `App.Start`, `Auth.Login`, `Task.Create` y `Task.Complete`.
- Se documento el formato y los eventos en `docs\MONITORING.md`.
- Verificacion: `AppCoreTests.exe` termina con `All tests passed`.
- Verificacion: `tests\App.Win.Tests\run-tests.bat` termina con `All tests passed`.
- Verificacion: `tests\App.Win.E2E\run-smoke-login.bat` termina con `Smoke login and task CRUD flow passed`.

### Version y build number trazables a GitHub

- Se agrego `src\App.Core\AppCoreBuildInfo.pas` como fallback estable para compilaciones manuales.
- Se agrego `src\App.Core\AppCoreBuildInfo.template.pas` para restaurar el fallback despues de builds automatizadas.
- Se agrego `scripts\generate-build-info.bat`.
- Se agrego `scripts\build-windows.bat` como wrapper simple de build trazable.
- El script calcula la version como `Major.Minor.Patch.CommitCount`, usando `git rev-list --count HEAD`.
- El script incluye el commit corto con `git rev-parse --short HEAD`.
- La version actual generada es `1.0.0.34`.
- El commit actual generado es `00e623b`.
- `TAboutService` expone version, version del ejecutable, fecha de build y commit GitHub.
- `FrmAbout` muestra `Commit GitHub` y traduce el prefijo desde `languages.csv`.
- `scripts\build-windows.bat` y el runner E2E ejecutan el generador antes de compilar `WindowsApp.dpr` y restauran el fallback al terminar.
- Verificacion: `AppCoreTests.exe` termina con `All tests passed`.
- Verificacion: `tests\App.Win.Tests\run-tests.bat` termina con `All tests passed`.
- Verificacion: `tests\App.Win.E2E\run-smoke-login.bat` termina con `Smoke login and task CRUD flow passed`.

### Ampliacion de E2E con AutoIt

- Se amplio `tests\App.Win.E2E\smoke_login.au3`.
- El flujo hace login con `admin` / `admin`.
- Abre la pantalla `Tareas`.
- Crea una tarea con titulo unico.
- Verifica que la tarea aparece pendiente con prefijo `[ ]`.
- Completa la tarea y verifica el prefijo `[x]`.
- Se agregaron diagnosticos con listado de ventanas, clases y controles cuando falla una asercion E2E.
- Se guarda una captura del fallo en `tests\App.Win.E2E\runtime\diagnostics\failure.png`.
- Verificacion: `tests\App.Win.E2E\run-smoke-login.bat` termina con `Smoke login and task CRUD flow passed`.

### Ampliacion de mutation testing en autenticacion y usuarios

- Se agregaron mutantes M012-M014 para busqueda y filtros de `AppCoreUserService.pas`.
- Se agregaron mutantes M015-M017 para persistencia de campos criticos de `AppCoreUserFileRepository.pas`.
- Se actualizo M004 para el estado actual de `AppCoreConfiguration.pas`.
- Resultado: 17 mutantes probados, 17 muertos, 0 supervivientes.
- No se detectaron supervivientes que requieran nuevos tests TDD.
- Verificacion: `tests\App.Core.Tests\mutation.bat` termina con `Summary: 17 tested, 17 killed, 0 survived`.

### Auditoria estricta de localizacion

- Se agrego `tests\App.Win.Tests\LocalizationAuditTests.pas`.
- La auditoria se ejecuta desde `tests\App.Win.Tests\run-tests.bat`.
- Se valida que `src\App.Win\languages.csv` exista.
- Se validan columnas obligatorias: `key`, idioma por defecto `es` e idioma activo `en`.
- Se falla si una clave apunta a un componente inexistente.
- Se falla si una clave apunta a una propiedad publicada inexistente.
- Se detectan captions traducibles del formulario auditado que no aparecen en el CSV.
- La app mantiene aplicacion tolerante de localizacion en produccion; los tests usan modo estricto.
- Estado actual: `FrmLogin`, `FrmMain`, `FrmTasks`, `FrmUsers` y `FrmAbout` auditados contra `languages.csv`.
- Verificacion: `tests\App.Win.Tests\run-tests.bat` termina con `All tests passed`.

### Traduccion del resto de pantallas

- Se amplio `src\App.Win\languages.csv` con textos de `FrmMain`, `FrmTasks` y `FrmUsers`.
- `WindowsApp.dpr` conserva el servicio de localizacion creado al arrancar y lo pasa a la ventana principal.
- `FrmMain` aplica localizacion a sus botones de navegacion y propaga el servicio a las pantallas embebidas.
- `FrmTasks` y `FrmUsers` exponen `ApplyLocalization` y aplican sus captions desde el CSV.
- `FrmUsers` traduce las opciones de rol en ingles al aplicar idioma `en`.
- `FrmAbout` traduce sus captions desde claves `FrmAbout.*` de `languages.csv`.
- `FrmAbout` traduce sus prefijos dinamicos desde claves `About.*` de `languages.csv` y solo concatena valores de runtime.
- `FrmAbout` se repinta al cambiar entre `en` y `es` sin conservar textos del idioma anterior.
- `FrmMain` aplica la localizacion activa antes de mostrar `FrmAbout`.
- Verificacion: `tests\App.Win.Tests\run-tests.bat` termina con `All tests passed`.
- Verificacion: `dcc32 "-U..\App.Core" -B WindowsApp.dpr` termina sin errores.

### Revision del detalle del informe de DelphiCodeCoverage

- Se revisaron `CodeCoverage_summary.xml` y los HTML por fichero generados por DelphiCodeCoverage.
- El resumen global y los HTML por fichero son validos para cobertura de lineas y umbrales.
- Los HTML por fichero conservan numeros de linea y estados `covered`, `notcovered` y `nocodegen`.
- Los nodos `class` y `method` del XML/HTML muestran nombres internos truncados o sufijos en Delphi 7.
- Ejemplos observados: `oadFromFile`, `teUser`, `ser`.
- Conclusion: no usar esos nombres truncados como fuente fiable para analisis por metodo.
- Para detalle fino, usar el HTML por fichero junto con el codigo fuente, lineas no cubiertas y tests asociados.
- Se documento la limitacion en `docs\TESTING.md` y `docs\TDD.md`.

### Cobertura de `AppCoreUserService` y umbral minimo Core

- Se agregaron unit tests para permisos de actor administrador, usuario inexistente, campos obligatorios, contraseña vacia, actualizacion manteniendo usuario/email, activar, desactivar, bloquear, desbloquear y filtros por estado.
- `AppCoreUserService.pas` queda con 98,5% de cobertura en el HTML por fichero, 196 de 199 lineas con codigo generado cubiertas.
- Se agrego umbral minimo del 90% a `tests\App.Core.Tests\coverage.bat`.
- El coverageTest Core falla si `CodeCoverage_summary.xml` reporta menos del 90% cubierto.
- Verificacion: `AppCoreTests.exe` termina con `All tests passed`.
- Verificacion: `tests\App.Core.Tests\coverage.bat` termina con `All tests passed`.
- Resultado actual core: 93% de cobertura, 931 de 991 lineas cubiertas.
- Resultado del umbral: `Coverage threshold passed: 93% >= 90%`.

### Validacion de DelphiCodeCoverage en entorno limpio

- Se verifico que `CodeCoverage.exe` esta versionado en `.tools\delphi-code-coverage\CodeCoverage.exe`.
- Los scripts `coverage.bat` usan primero la herramienta versionada y solo recurren al `PATH` como fallback.
- Se limpiaron artefactos generados de compilacion e informes antes de ejecutar los coverageTest.
- Verificacion: `tests\App.Core.Tests\coverage.bat` termina con `All tests passed`.
- Resultado actual core: 91% de cobertura, 901 de 982 lineas cubiertas.
- Verificacion: `tests\App.Win.Tests\coverage.bat` termina con `All tests passed`.
- Resultado actual App.Win: 92% de cobertura, 63 de 68 lineas cubiertas.

### Textos seleccionables en formulario login

- Se agrego `AppCoreLocalization.pas` con `TCsvLocalizationService`.
- Se agrego `AppWinLocalization.pas` para aplicar solo las claves CSV del formulario actual.
- Se agrego `src\App.Win\languages.csv` con columnas `es` y `en`.
- Se agrego seccion `[Localization]` a `src\App.Win\app.config`.
- `WindowsApp.dpr` carga el CSV y aplica textos al `FrmLogin`.
- El E2E copia `languages.csv` al runtime aislado.
- Se cubren carga por idioma, fallback a idioma por defecto, CSV con comillas y filtrado de claves por form.
- Se cubren captions de formulario, usuario, password, entrar y cancelar desde un servicio de localizacion.
- Verificacion: `tests\App.Core.Tests\coverage.bat` termina con `All tests passed`.
- Resultado actual core: 91% de cobertura, 901 de 982 lineas cubiertas.
- Verificacion: `tests\App.Win.Tests\run-tests.bat` termina con `All tests passed`.
- Verificacion: `tests\App.Win.Tests\coverage.bat` termina con `All tests passed`.
- Resultado actual App.Win: 92% de cobertura, 63 de 68 lineas cubiertas.
- Verificacion visual: `tests\App.Win.Visual\run-visual-tests.bat verify` termina con `All visual tests passed`.
- Verificacion E2E: `tests\App.Win.E2E\run-smoke-login.bat` termina con `Smoke login passed`.

### Visual test de formulario login

- Se agrego `tests\App.Win.Visual\AppWinVisualTests.dpr`.
- Se agrego `tests\App.Win.Visual\run-visual-tests.bat`.
- Se implementaron modos `approve` y `verify` para baselines visuales.
- Se captura el area cliente de `TFrmLogin`.
- Se compara contra `tests\App.Win.Visual\baselines\LoginForm.bmp`.
- Se ignoran capturas actuales y diffs en `.gitignore`.
- Se documento `visualTest Forms VCL` en `docs\TESTING.md`.

### Documentacion de tests unitarios de forms VCL

- Se documento el patron `unitTest Forms VCL` en `docs\TESTING.md`.
- Se documento el patron TDD para formularios en `docs\TDD.md`.
- Se agrego `tests\App.Win.Tests\coverage.bat`.
- Se documento coverage de forms con DelphiCodeCoverage.
- Verificacion: `tests\App.Win.Tests\coverage.bat` termina con `All tests passed`.
- Resultado actual: `LoginForm.pas` queda en 92% de cobertura, 35 de 38 lineas ejecutables cubiertas.

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
