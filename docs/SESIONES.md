# Resumen de sesiones - TodoApp

## Estadísticas del proyecto
- Commits: 6
- Tests: 59 (todos pasan)
- Archivos fuente: ~25
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
