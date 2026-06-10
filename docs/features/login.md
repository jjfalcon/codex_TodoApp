# Criterios de aceptación — Login

> Generados a partir de `docs/LOGIN_SPEC.md` (líneas 251-271).

```gherkin
Feature: Login
  Como usuario de la aplicación
  Quiero autenticarme con usuario y contraseña
  Para acceder a las funcionalidades protegidas

  Background:
    Given no hay sesión activa
    When la aplicación arranca
    Then debe mostrarse el login

  # ─────────────────────────────
  # Validación de campos
  # ─────────────────────────────

  Scenario: Rechazar usuario vacío
    Given el campo usuario está vacío
    When el usuario intenta iniciar sesión
    Then se informa que el usuario es obligatorio

  Scenario: Rechazar contraseña vacía o solo espacios
    Given la contraseña está vacía o formada solo por espacios
    When se intenta iniciar sesión
    Then se informa que la contraseña es obligatoria

  Scenario: Ignorar espacios laterales en el usuario
    Given un nombre de usuario con espacios laterales
    When las credenciales son válidas
    Then el login debe funcionar igual que sin esos espacios

  # ─────────────────────────────
  # Autenticación exitosa
  # ─────────────────────────────

  Scenario: Login correcto crea sesión activa
    Given un usuario activo con credenciales válidas
    When inicia sesión
    Then se crea una sesión activa

  Scenario: Login correcto incluye el rol en la sesión
    Given un usuario activo con credenciales válidas
    When inicia sesión
    Then la sesión incluye su rol

  # ─────────────────────────────
  # Autenticación fallida
  # ─────────────────────────────

  Scenario: Rechazar usuario inexistente
    Given un usuario inexistente
    When intenta iniciar sesión
    Then se rechaza el acceso

  Scenario: Rechazar contraseña incorrecta
    Given una contraseña incorrecta
    When intenta iniciar sesión
    Then se rechaza el acceso

  Scenario: Rechazar usuario inactivo
    Given un usuario inactivo
    When intenta iniciar sesión
    Then se rechaza el acceso

  # ─────────────────────────────
  # Bloqueo por fallos consecutivos
  # ─────────────────────────────

  Scenario: Incrementar contador de fallos
    Given un usuario activo
    When falla la contraseña una vez
    Then su contador de fallos consecutivos aumenta a 1

  Scenario: Bloquear tras tercer fallo consecutivo
    Given un usuario activo con 2 fallos consecutivos
    When falla la contraseña otra vez
    Then el usuario queda bloqueado

  Scenario: Rechazar usuario bloqueado
    Given un usuario bloqueado
    When intenta iniciar sesión con credenciales correctas
    Then se rechaza el acceso

  Scenario: Resetear fallos tras login exitoso
    Given un usuario activo con fallos acumulados menores que 3
    When inicia sesión correctamente
    Then el contador de fallos vuelve a 0

  Scenario: Campos vacíos no cuentan como fallo
    Given un usuario activo
    When intenta iniciar sesión con campos obligatorios vacíos
    Then no se incrementa el contador de fallos

  Scenario: Usuario inexistente no cuenta como fallo
    Given un usuario inexistente
    When intenta iniciar sesión
    Then no se incrementa ningún contador de fallos

  # ─────────────────────────────
  # Sesión y cierre de sesión
  # ─────────────────────────────

  Scenario: Cerrar sesión
    Given un usuario autenticado
    When cierra sesión
    Then la sesión queda inactiva

  Scenario: Sesión expira por inactividad
    Given un usuario autenticado sin actividad durante más tiempo que el límite configurado
    When se comprueba la sesión
    Then la sesión queda expirada

  Scenario: La actividad renovada mantiene la sesión viva
    Given un usuario autenticado que realiza una actividad protegida antes de expirar
    When se registra la actividad
    Then se actualiza la última actividad de la sesión

  Scenario: Bloquear acceso sin sesión activa
    Given que la sesión está inactiva
    When se intenta acceder a una funcionalidad protegida
    Then el acceso se bloquea

  # ─────────────────────────────
  # Roles y permisos
  # ─────────────────────────────

  Scenario: Usuario normal no accede a funcionalidad de admin
    Given un usuario normal autenticado
    When intenta acceder a una funcionalidad de administrador
    Then el acceso se deniega

  Scenario: Administrador accede a funcionalidad de admin
    Given un administrador autenticado
    When intenta acceder a una funcionalidad de administrador
    Then el acceso se permite

  # ─────────────────────────────
  # Último usuario usado
  # ─────────────────────────────

  Scenario: Precargar último usuario en el login
    Given que existe un último usuario usado
    When se abre el login
    Then el campo usuario se precarga con ese valor

  Scenario: Actualizar último usuario tras intento
    Given un intento de login con usuario no vacío
    When termina el intento
    Then se actualiza el último usuario usado

  Scenario: No borrar último usuario si el campo está vacío
    Given un intento de login con usuario vacío
    When termina la validación
    Then no se borra el último usuario usado
```

**Resumen:** 23 escenarios Gherkin cubriendo validación de campos, autenticación exitosa/fallida, bloqueo por fallos consecutivos, sesión/logout, expiración por inactividad, roles y último usuario usado.
