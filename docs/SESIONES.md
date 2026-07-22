# Resumen de sesiones - TodoApp

## Estadísticas del proyecto
- Commits: 6
- Tests: 67 (todos pasan)
- Archivos fuente: ~33
- Documentación: 14 docs en docs/

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
