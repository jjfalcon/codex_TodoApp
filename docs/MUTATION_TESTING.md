# Mutation testing

Este documento registra las pruebas de mutacion ejecutadas contra `src\App.Core`.

Dentro de la taxonomia de `docs\TESTING.md`, este nivel se llama `mutationTest`.

## Runner automatizado

Las mutaciones existentes estan automatizadas con patches en:

```text
tests\App.Core.Tests\mutations\
```

Para ejecutarlas:

```bat
cd tests\App.Core.Tests
mutation.bat
```

El runner:

- Verifica primero que el arbol de trabajo no tenga cambios staged ni unstaged.
- Compila y ejecuta una linea base para asegurar que los tests pasan antes de mutar.
- Aplica cada patch con `git apply` desde la raiz del repositorio.
- Fuerza recompilacion con `dcc32 -B`.
- Ejecuta `AppCoreTests.exe`.
- Marca el mutante como `Killed` si la compilacion o los tests fallan.
- Revierte el patch con `git apply -R`.
- Genera `mutation-report.txt` y logs `mutation-*.log`.

Durante el desarrollo del runner puede saltarse la verificacion de arbol limpio con:

```bat
set MUTATION_ALLOW_DIRTY=1
mutation.bat
```

No usar ese bypass para comprobaciones finales.

## Resultado del lote inicial

Fecha: 2026-06-22

| Id | Fichero | Mutacion | Resultado | Test que la detecto |
| --- | --- | --- | --- | --- |
| M001 | `AppCoreTaskService.pas` | Guardar `ATitle` sin `Trim` al crear tarea | Killed | `CreateTaskStoresTrimmedPendingTask` |
| M002 | `AppCoreTaskService.pas` | Filtrar `tsCompleted` en `ListPendingTasks` | Killed | `ListPendingTasksReturnsOnlyPendingTasks` |
| M003 | `AppCoreTaskService.pas` | Buscar contra titulo sin `UpperCase` | Killed | `SearchTasksReturnsMatchingTitles` |
| M004 | `AppCoreConfiguration.pas` | Usar ruta relativa sin `ExpandFileName` | Killed | `Reads_dataPath`, `Reads_connectionString` |

Resumen: 4 mutantes probados, 4 mutantes muertos, 0 supervivientes.

## Resultado del segundo lote

Fecha: 2026-06-22

| Id | Fichero | Mutacion | Resultado | Test que la detecto |
| --- | --- | --- | --- | --- |
| M005 | `AppCoreAuth.pas` | No incrementar `FailedAttempts` con password incorrecto | Killed | `Login_increments_failed_attempts_for_wrong_password`, `Login_locks_user_after_three_consecutive_failures` |
| M006 | `AppCoreAuth.pas` | Bloquear solo con mas de 3 fallos, no con 3 | Killed | `Login_locks_user_after_three_consecutive_failures` |
| M007 | `AppCoreAuth.pas` | Permitir login de usuario inactivo | Killed | `Login_rejects_inactive_user` |
| M008 | `AppCoreAuth.pas` | Permitir login de usuario bloqueado | Killed | `Login_rejects_locked_user_even_with_valid_password` |
| M009 | `AppCoreUserService.pas` | Permitir automodificacion de usuario | Killed | `UpdateUser_rejects_self_modification` |
| M010 | `AppCoreUserService.pas` | Permitir editar/reactivar usuario eliminado | Killed | `DeleteUser_rejects_reactivation` |
| M011 | `AppCoreUserService.pas` | Desactivar la proteccion de ultimo administrador activo | Killed | `UserManagement_prevents_deactivating_last_active_admin`, `UserManagement_prevents_blocking_last_active_admin`, `UserManagement_prevents_deleting_last_active_admin`, `UserManagement_prevents_downgrading_last_active_admin` |

Resumen acumulado actualizado: 11 mutantes probados, 11 mutantes muertos, 0 supervivientes.

## Resultado del tercer lote

Fecha: 2026-07-22

| Id | Fichero | Mutacion | Resultado | Test que la detecto |
| --- | --- | --- | --- | --- |
| M012 | `AppCoreUserService.pas` | Buscar usuarios solo por username, ignorando display name/email | Killed | `SearchUsers_matches_username_display_name_and_email` |
| M013 | `AppCoreUserService.pas` | Incluir usuarios eliminados aunque no se pida filtro `ufDeleted` | Killed | `ListUsers_excludes_deleted_users_by_default` |
| M014 | `AppCoreUserService.pas` | Ignorar el filtro de usuarios activos | Killed | `FilterUsers_returns_only_active_users` |
| M015 | `AppCoreUserFileRepository.pas` | Perder `email` al recargar usuarios desde JSON | Killed | `FilePersistence_persists_multiple_fields` |
| M016 | `AppCoreUserFileRepository.pas` | Perder `failedAttempts` al recargar usuarios desde JSON | Killed | `FilePersistence_persists_multiple_fields` |
| M017 | `AppCoreUserFileRepository.pas` | Perder `passwordHash` al recargar usuarios desde JSON | Killed | `FilePersistence_round_trips_password_hash_and_salt`, `Login_succeeds_after_file_reload` |

Resumen acumulado actualizado: 17 mutantes probados, 17 mutantes muertos, 0 supervivientes.

## Supervivientes

No hay supervivientes conocidos tras automatizar y repetir las mutaciones existentes.

## Verificacion posterior

Despues de restaurar las mutaciones temporales:

```bat
cd tests\App.Core.Tests
dcc32 "-U..\..\src\App.Core" AppCoreTests.dpr
AppCoreTests.exe
```

Resultado: `All tests passed.`

## Verificacion automatizada posterior

Fecha: 2026-07-22

```bat
cd tests\App.Core.Tests
set MUTATION_ALLOW_DIRTY=1
mutation.bat
```

Resultado: 17 mutantes probados, 17 mutantes muertos, 0 supervivientes.

## Siguientes candidatos

- Ampliar persistencia con mutantes adicionales de `locked`, `deleted`, `role` y fechas si se detecta nueva deuda.
- Agregar mutantes de combinaciones de filtros multiples cuando existan reglas mas ricas que filtros individuales.
