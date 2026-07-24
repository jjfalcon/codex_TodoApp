# Resumen de sesiones - TodoApp

## Estadisticas del proyecto
- Commits: 36
- Tests registrados: 138 llamadas `RunTest` entre Core y App.Win
- Archivos fuente: ~32
- Documentacion: 19 docs en docs/

---

## 1. Sesión 1 - 2026-06-02: Base del proyecto y tareas (commit c367fe2)

### Core
- TTaskItem: modelo de tarea (id, título, completada, createdAt)
- TInMemoryTaskRepository: repositorio en memoria con TList
- TTaskService: CRUD de tareas con validaciones (título obligatorio, trim)

### VCL
- MainForm (TFrmMain): shell con sidebar de navegación y PnlContent para formularios embebidos
- TaskForm (TFrmTask): CRUD de tareas embebido
- WindowsApp.dpr: proyecto compilable

### Tests
- Suite de TaskService: crear, completar, eliminar, buscar por título
- AppCoreTests.dpr: consola de tests con contador de fallos

### Documentación
- TDD.md: guía TDD del proyecto (regla de oro: la UI no contiene reglas de negocio)
- ABOUT_SPEC.md: stub inicial
- LOGIN_SPEC.md: stub inicial

---

## 2. Sesión 2 - 2026-06-02: Especificación de FMain (commit ef48c02)

### Documentación
- FMAIN_SPEC.md: especificación funcional detallada de la pantalla principal (sidebar, navegación, roles)

---

## 3. Sesión 3 - 2026-06-02: Login y autenticación (commit d336182)

### Core
- TUser: modelo de usuario
- TInMemoryUserRepository: repositorio en memoria
- TAuthService: login con validaciones, intentos fallidos, bloqueo
- TBasicPasswordHasher: hash DJB2 con sal
- TSessionService: sesión con timeout por inactividad
- TPermissionService: control de acceso por rol
- TInMemoryLoginPreferencesRepository: recuerda último usuario
- TSystemClock: implementación de IClock

### VCL
- LoginForm (TFrmLogin): diálogo modal con username/password, manejo de errores
- MainForm: refactorizado para recibir dependencias desde LoginForm
- TaskForm: integrado en el flujo post-login

### Tests
- 22 tests de autenticación: validaciones, intentos fallidos, bloqueo tras 3, sesión, permisos, prefijo de usuario

### Documentación
- LOGIN_SPEC.md, LOGIN_TECH.md, LOGIN_USER_MANUAL.md

---

## 4. Sesión 4 - 2026-06-02: Persistencia JSON de tareas (commit 9b67393)

### Core
- TFileTaskRepository: repositorio con persistencia en JSON (inline parser/serializer, ~180 líneas)
- Soporte para crear y completar tareas con persistencia en archivo

### Tests
- Persistencia de tareas creadas y completadas en archivo JSON

### Documentación
- TASK_SPEC.md, TASK_TECH.md, TASK_USER_MANUAL.md

---

## 5. Sesión 5 - 2026-06-09: Gestión de usuarios (commit 13600d9)

### Core
- TUserService: CRUD completo (crear, actualizar, activar, desactivar, bloquear, desbloquear, eliminar, cambiar password, listar/buscar con filtros)
- EnsureDefaultAdmin: crea admin solo si no existe
- Mejoras en repositorio y auth service

### VCL
- UserForm (TFrmUsers): CRUD embebido en PnlContent, solo accesible para administradores
- LoginForm: simplificado (eliminados usuarios de prueba quemados)

### Tests
- 20 tests de gestión de usuarios: creación, validaciones, roles, bloqueo, eliminación blanda, búsqueda

### Documentación
- USER_SPEC.md, USER_TECH.md, USER_MANUAL.md

---

## 6. Sesión 6 - 2026-06-09: Formulario Acerca de (commit 6c2c820)

### Core
- TAboutInfo: record con datos de la aplicación
- TAboutService: servicio que devuelve nombre, versión, descripción, copyright; marca como No Disponible los datos opcionales faltantes; sanitiza información sensible

### VCL
- AboutForm (TFrmAbout): diálogo modal con la información, botón Aceptar
- MainForm: botón Acerca de en la barra lateral

### Tests
- 7 tests: datos básicos, opcionales ausentes, datos sensibles no expuestos

### Documentación
- ABOUT_SPEC.md (reescritura completa), ABOUT_TECH.md, ABOUT_MANUAL.md

---

## 7. Sesión 7 - 2026-06-09: Refactor JSON utils y persistencia de usuarios

### Core
- AppCoreJsonUtils.pas (NUEVO): 10 funciones compartidas de parseo/serialización JSON extraídas de TFileTaskRepository (FindFrom, EscapeJson, UnescapeJson, ExtractJsonString/Date/Bool/Integer, ExtractJsonObjects, DateTimeToJson, NullOrDateTimeToJson, BoolToJson)
- AppCoreTaskFileRepository.pas (MODIFICADO): refactorizado para usar AppCoreJsonUtils en lugar de helpers inline
- AppCoreUserFileRepository.pas (NUEVO): TFileUserRepository implementa IUserRepository con persistencia JSON completa de TUser

### Correcciones de bugs
- TUserService.NewId generaba IDs duplicados (siempre "user-1") al crear un nuevo TUserService; corregido escaneando IDs existentes en el constructor
- TFileUserRepository.Save: al guardar un TUser que ya está en FItems se producía un use-after-free (liberaba y reemplazaba el mismo objeto); corregido con guardia de identidad (solo libera si el puntero es distinto)

### VCL
- LoginForm.pas (MODIFICADO): usa TFileUserRepository, elimina usuarios de prueba quemados, admin se crea via EnsureDefaultAdmin solo al primer inicio
- WindowsApp.dpr (MODIFICADO): incluye AppCoreJsonUtils y AppCoreUserFileRepository

### Tests
- 3 tests nuevos: FilePersistence_round_trips_password_hash_and_salt, Login_succeeds_after_file_persistence_create_user, Login_succeeds_after_file_reload
- 59 tests en total, todos OK, 0 warnings

### Documentación
- USER_TECH.md actualizado: secciones AppCoreUserFileRepository y AppCoreJsonUtils
- USER_MANUAL.md actualizado: persistencia apunta a users.json, nota sobre admin solo al primer inicio

---

## 8. Sesión 8 - 2026-06-10: Refactor persistencia — Factory pattern + configuración

### Core (nuevo)
- `AppCoreConfiguration.pas` (NUEVO): `TAppConfiguration` lee `app.config` (INI) con backend, dataPath y connectionString
- `AppCoreRepositoryFactory.pas` (NUEVO): interfaz `IRepositoryFactory` + `TJsonRepositoryFactory` que crea repos según backend configurado
- `AppCorePreferencesFileRepository.pas` (NUEVO): `TFileLoginPreferencesRepository` persiste último usuario en `app.config` sección `[Login]` (antes se perdía al cerrar la app)

### VCL
- `app.config` (NUEVO): archivo INI con `[Persistence] Backend=json`, `DataPath=.`
- `WindowsApp.dpr` (MODIFICADO): actúa como composition root — lee config, crea factory según backend, inyecta en forms
- `LoginForm.pas` (MODIFICADO): recibe `IRepositoryFactory` via `Configure()` en lugar de crear repos directamente
- `MainForm.pas` (MODIFICADO): recibe `IRepositoryFactory` y lo reenvía a TaskForm/UserForm
- `TaskForm.pas` (MODIFICADO): recibe `IRepositoryFactory` via `Configure()`, elimina dependencia directa a `TFileTaskRepository`

### Tests
- 11 tests nuevos: configuración INI (4), factory (4), preferencias con archivo (4)
- 67 tests en total, todos OK, 0 errores

### Notas
- Para cambiar de backend (ej. MySQL) solo hace falta: crear `TMySQLRepositoryFactory`, registrarlo en el DPR, cambiar `app.config`
- `UserForm.pas` no se modificó — ya recibía `IUserRepository` por inyección
- Las preferencias de login se guardan en `app.config` sección `[Login]`, mismo archivo que la configuración general

---

## 9. Sesion 9 - 2026-07-22: Calidad de tests, coverage, mutationTest y E2E

Commits relevantes:

- `04c6bd0` Track all tools artifacts
- `aba49f0` Cover last active admin rule
- `fda2481` Incluir suite mutationTest

### Core
- Se cubrio la regla de ultimo administrador activo en `TUserService`.
- Se agregaron tests para impedir desactivar, bloquear, eliminar o degradar el ultimo administrador activo.
- Los cuatro casos esperan `ELastAdminError`.
- Se ajusto el orden de validaciones para priorizar la regla de administrador minimo cuando una operacion retiraria acceso administrativo.

### unitTest
- `AppCoreUserServiceTests.pas` registra ahora los cuatro casos `UserManagement_prevents_*_last_active_admin`.
- Verificacion: `AppCoreTests.exe` termina con `All tests passed`.
- Total actual observado: 78 tests de nucleo en consola.

### coverageTest
- Se integro `tests\App.Core.Tests\coverage.bat`.
- Se versiono `CodeCoverage.exe` en `.tools\delphi-code-coverage\`.
- El script compila con mapa detallado (`-GD`) y genera HTML/XML en `tests\App.Core.Tests\coverage\`.
- Resultado documentado: 92% global, 799 de 868 lineas cubiertas.

### mutationTest
- Se agrego `tests\App.Core.Tests\mutation.bat` como runner propio automatizado.
- Se agregaron patches versionados `M001`-`M011` en `tests\App.Core.Tests\mutations\`.
- El superviviente M011 quedo cubierto tras agregar los tests de ultimo administrador activo.
- Resultado verificado: 11 mutantes probados, 11 killed, 0 survived.

### e2eTest
- Se agrego AutoIt portable en `.tools\autoit\install`.
- Se agrego `tests\App.Win.E2E\smoke_login.au3`.
- Se agrego `tests\App.Win.E2E\run-smoke-login.bat`.
- El smoke compila la app VCL, prepara runtime aislado, hace login con `admin/admin` y verifica la ventana principal.

### Documentacion
- Se agrego `docs\TESTING.md` como guia central de niveles de test.
- Se consenso la nomenclatura `unitTest`, `coverageTest`, `mutationTest` y `e2eTest`.
- Se enlazo la taxonomia desde `README.md`, `docs\TDD.md`, `docs\MUTATION_TESTING.md` y `docs\E2E_AUTOIT.md`.

### Pendientes identificados
- Mejorar cobertura especifica de `AppCoreUserService`.
- Definir umbral minimo de cobertura.
- Validar DelphiCodeCoverage en entorno limpio.
- Ampliar mutationTest con filtros/busqueda de usuarios y persistencia critica de `AppCoreUserFileRepository`.
- Ampliar e2eTest con alta y completado de tareas, mas diagnosticos de fallo.

---

## 10. Sesion 10 - 2026-07-22: Tests unitarios de forms VCL y coverage de App.Win

Commits relevantes:

- `1b0479a` Incluir tests unitarios de App.Win
- `f0a982d` Documentar tests unitarios de forms VCL

### Objetivo

- Cambiar el enfoque de `LoginForm` desde checks visuales/E2E detallados hacia unit tests de formulario.
- Mantener el E2E como smoke de integracion real de la aplicacion.
- Dejar documentado un patron repetible para testear futuros forms VCL de la misma manera.

### App.Win

- `LoginForm.pas` recibio `ConfigureForTests(const AAuth: IAuthService)`.
- El formulario permite inyectar un fake de autenticacion sin crear repositorios reales.
- `FormCreate` fija `ActiveControl := EdtUsername` para asegurar foco inicial observable.
- La logica de negocio sigue fuera de la UI; el form solo llama a `IAuthService`.

### unitTest Forms VCL

- Se agrego `tests\App.Win.Tests\AppWinTests.dpr`.
- Se agrego `tests\App.Win.Tests\LoginFormTests.pas`.
- Se agrego `tests\App.Win.Tests\run-tests.bat`.
- Los tests instancian `TFrmLogin` directamente con `TFrmLogin.Create(nil)`.
- Se usa `TFakeAuthService` para aislar el formulario del nucleo real.
- Se invoca `BtnLoginClick(nil)` para simular la accion de aceptar.

Cobertura funcional de los tests:

- Foco inicial en usuario.
- Password enmascarado con `PasswordChar`.
- Orden de tabulacion: usuario, password, entrar, cancelar.
- Llamada al servicio de autenticacion inyectado.
- Captura de usuario, password, rol e id autenticado.
- Error de autenticacion visualizado en `LblMessage`.
- `ModalResult` correcto en exito y fallo.

### coverageTest Forms VCL

- Se agrego `tests\App.Win.Tests\coverage.bat`.
- El script compila `AppWinTests.dpr` con mapa detallado (`-GD`).
- Ejecuta DelphiCodeCoverage contra `AppWinTests.exe`.
- Genera HTML/XML en `tests\App.Win.Tests\coverage\`.
- Resultado verificado: `LoginForm.pas` queda en 86%, 20 de 23 lineas cubiertas.

### Documentacion

- `docs\TESTING.md` distingue ahora `unitTest Core`, `unitTest Forms VCL`, `coverageTest Core` y `coverageTest Forms VCL`.
- `docs\TDD.md` documenta el patron recomendado para forms VCL.
- `tareas.md` registra como realizadas la suite unitaria de login form y la documentacion del patron.

### Verificaciones ejecutadas

- `tests\App.Win.Tests\run-tests.bat`: `All tests passed`.
- `tests\App.Win.Tests\coverage.bat`: `All tests passed`, 86%, 20/23 lineas.
- `tests\App.Core.Tests\coverage.bat`: `All tests passed`, 92%, 819/886 lineas.
- `tests\App.Win.E2E\run-smoke-login.bat`: `Smoke login passed`.

### GitHub

- Commit `1b0479a` subido a `origin/master`.
- Commit `f0a982d` subido a `origin/master`.
- El arbol quedo limpio tras cada push.

### Pendientes derivados

- Agregar test unitario de Enter/CR y boton por defecto en `LoginForm`.
- Cubrir textos cargados desde lenguaje seleccionado.
- Mantener una verificacion visual con captura para el login.
- Ampliar `tests\App.Win.Tests\coverage.bat` con nuevas unidades en `-u` cuando se agreguen tests de otros forms.

---

## 11. Sesion 11 - 2026-07-23: E2E ampliado, build trazable y monitorizacion local

Commits relevantes:

- `00e623b` Incluir diagnosticos de captura en E2E
- `515c98c` Incluir version trazable en About
- `f885030` Agregar monitorizacion local con timings

### e2eTest

- Se amplio `tests\App.Win.E2E\smoke_login.au3` para cubrir login, apertura de `Tareas`, alta de tarea y completado.
- El flujo verifica que la tarea aparece pendiente con prefijo `[ ]` y completada con prefijo `[x]`.
- Se agrego diagnostico de fallo con listado de ventanas, clases, botones, edits, labels y seleccion de lista.
- Se agrego captura automatica de pantalla en `tests\App.Win.E2E\runtime\diagnostics\failure.png` cuando falla una asercion.
- El runner `run-smoke-login.bat` prepara `runtime\diagnostics` y valida tambien el log de monitorizacion.

### Version y build trazable

- Se agrego `src\App.Core\AppCoreBuildInfo.pas` como fallback estable.
- Se agrego `src\App.Core\AppCoreBuildInfo.template.pas` para restaurar el fallback tras builds automatizadas.
- Se agrego `scripts\generate-build-info.bat` para generar version real desde Git.
- Se agrego `scripts\build-windows.bat` como wrapper simple de build trazable.
- La version del ejecutable se calcula como `Major.Minor.Patch.CommitCount`, usando `git rev-list --count HEAD`.
- El commit GitHub se obtiene con `git rev-parse --short HEAD`.
- `TAboutService` expone version, version del ejecutable, fecha de build y commit.
- `FrmAbout` muestra `Commit GitHub` con prefijo localizado desde `languages.csv`.
- El build automatizado genera la info real antes de compilar y restaura el fallback para evitar bucles de commits.

### Monitorizacion local

- Se agrego `src\App.Core\AppCoreDiagnostics.pas`.
- `TFileDiagnosticsLogger` escribe `logs\application.log`.
- `TDiagnosticTimer` mide duraciones en milisegundos.
- El logger soporta `INFO`, `WARNING`, `ERROR` y `TIMING`.
- Se sanean valores sensibles como `password=`, `pwd=`, `token=`, `secret=` y `connectionstring=`.
- `WindowsApp.dpr` registra `App.Start`, `App.Stop` y `App.UnhandledException`.
- `TFrmLogin` registra `Auth.Login` con resultado y `durationMs`.
- `TFrmMain` registra apertura de la pantalla `Tareas`.
- `TFrmTasks` registra `Task.Create` y `Task.Complete` con resultado y `durationMs`.
- El E2E comprueba que `logs\application.log` existe y contiene `App.Start`, `Auth.Login`, `Task.Create` y `Task.Complete`.

### Tests y documentacion

- Se agrego `tests\App.Core.Tests\AppCoreDiagnosticsTests.pas`.
- Se agregaron tests para escritura de `INFO`, escritura de `TIMING durationMs` y saneado de valores sensibles.
- `tests\App.Core.Tests\coverage.bat` incluye `AppCoreDiagnostics` en la lista de unidades medidas.
- `tests\App.Win.Tests\AppWinTests.dpr` incluye la nueva unidad Core para compilar los forms instrumentados.
- Se agrego `docs\MONITORING.md` con ubicacion, formato, eventos iniciales y politica de privacidad del log.
- `README.md` enlaza la documentacion de monitorizacion.
- `.gitignore` ignora `logs/` y `tests\App.Core.Tests\diagnostics-test/`.
- `tareas.md` marco como realizadas las tareas de version/build trazable y monitorizacion local.

### Verificaciones ejecutadas

- `AppCoreTests.exe`: `All tests passed`.
- `tests\App.Win.Tests\run-tests.bat`: `All tests passed`.
- `tests\App.Win.E2E\run-smoke-login.bat`: `Smoke login and task CRUD flow passed`.
- `scripts\build-windows.bat`: compila correctamente y restaura `AppCoreBuildInfo.pas`.
- `git diff --check`: sin errores.

### GitHub

- Commit `00e623b` subido a `origin/master`.
- Commit `515c98c` subido a `origin/master`.
- Commit `f885030` subido a `origin/master`.
- El arbol quedo limpio tras cada push.

### Pendientes actuales

- Especificar preferencias de usuario.
- Crear form CRUD de tabla generica.

---

## 12. Sesion 12 - 2026-07-24: CRUD generico, preview QuickReport y selector editMode

Commits relevantes:

- `d98a67f` Agregar CRUD generico de usuarios
- `dab4612` Agregar preview y selector editMode al CRUD
- `0a2f6a1` Documentar preview generico

### CRUD generico

- Se completo `TFrmCrud` como formulario VCL generico basado en `ICrudProvider`.
- Se integro la opcion administrativa `USR` en `FMain` usando `TFrmCrud`, `TUserCrudProvider` y modo `emDetail`.
- Se agregaron filtros por columna con `Ctrl+click` sobre cabeceras.
- Se agregaron indicadores visuales en cabecera para orden (`^`/`v`) y filtro (`*`).
- Se agrego busqueda no modal que resalta celdas coincidentes sin filtrar filas.
- Se agrego persistencia de layout, filtros y orden en secciones `Grid.<clave>` de `app.config`.
- Se elimino el boton `Filtrar` y se renombro `Refrescar` a `Reset`.

### Preview e impresion

- Se agrego boton `Preview` al CRUD generico.
- Se agrego `src\App.Win\CrudPreviewForm.pas` y `src\App.Win\CrudPreviewForm.dfm`.
- `TFrmCrud.CreatePreviewData` toma un snapshot exacto del grid visible.
- El snapshot incluye columnas visibles, captions actuales, anchos actuales y filas cargadas en `ClientDataSet`.
- El preview no reconsulta repositorios ni proveedores.
- El informe se genera dinamicamente con QuickReport.
- El dialogo permite ajustar orientacion, titulo, fecha y numero de pagina.
- Se corrigio el truncado de textos eliminando el uso de `FitText`.

### Selector editMode

- Se agrego selector `editMode` visible en `CrudForm`.
- Las opciones disponibles son `Sin edicion`, `Grid` y `Detalle`.
- El cambio de modo actualiza dinamicamente `Grid.ReadOnly`, `BtnNew.Enabled` y `BtnDelete.Enabled`.
- Se agregaron claves de localizacion para el label y las opciones del selector.

### Documentacion

- Se documento el CRUD generico en `docs\CRUD_FORM_SPEC.md`.
- Se agrego `docs\PREVIEW_SPEC.md` con la especificacion funcional del preview.
- Se agrego `docs\PREVIEW_TECH.md` con el diseno tecnico.
- Se agrego `docs\PREVIEW_MANUAL.md` con el manual de usuario.

### Tests y verificacion

- Se agregaron tests de modos de edicion, columnas generadas, layout, filtros, busqueda, detalle y preview.
- Se agrego auditoria de localizacion para `FrmCrudPreview`.
- `tests\App.Win.Tests\run-tests.bat`: `All tests passed`.
- `tests\App.Core.Tests\AppCoreTests.exe`: `All tests passed`.
- `tests\App.Core.Tests\coverage.bat`: cobertura Core superior al umbral.
- `tests\App.Core.Tests\mutation.bat`: mutantes probados sin supervivientes.
- `tests\App.Win.E2E\run-smoke-login.bat`: `Smoke login and task CRUD flow passed`.
- `dcc32 "-U..\App.Core" -B WindowsApp.dpr`: compila correctamente.

### GitHub

- Commit `d98a67f` subido a `origin/master`.
- Commit `dab4612` subido a `origin/master`.
- Commit `0a2f6a1` subido a `origin/master`.

### Pendientes actuales

- Agregar exportacion a fichero CSV desde `CrudForm`, usando el estado visible actual del grid.
- Agregar update automatico/manual del programa desde servidor usando GitHub, fichero de ultima version y hash de verificacion.
- Implementar opcion Main `TSK` usando `CrudForm` generico para tareas.

---
