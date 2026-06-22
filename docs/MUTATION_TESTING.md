# Mutation testing manual

Este documento registra pruebas manuales de mutacion ejecutadas contra `src/App.Core`.

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
| M011 | `AppCoreUserService.pas` | Desactivar la proteccion de ultimo administrador activo | Survived | - |

Resumen acumulado: 11 mutantes probados, 10 mutantes muertos, 1 superviviente.

## Supervivientes

### M011: ultimo administrador activo

La mutacion que desactiva `AssertCanRemoveAdminAccess` sobrevivio. Esto indica que la suite actual no falla si se permite quitar el ultimo administrador activo mediante operaciones como desactivar, bloquear, eliminar o cambiar rol.

Accion recomendada: agregar tests explicitos para operaciones que intenten dejar el sistema sin administradores activos.

## Verificacion posterior

Despues de restaurar las mutaciones temporales:

```bat
cd tests\App.Core.Tests
dcc32 "-U..\..\src\App.Core" AppCoreTests.dpr
AppCoreTests.exe
```

Resultado: `All tests passed.`

## Siguientes candidatos

- `AppCoreUserService.pas`: cubrir la regla de ultimo administrador activo con tests especificos.
- `AppCoreUserService.pas`: mutar filtros de usuarios activos/inactivos/bloqueados/eliminados.
- `AppCoreUserService.pas`: mutar busqueda por email, username y display name.
- `AppCoreUserFileRepository.pas`: mutar persistencia de campos criticos como `locked`, `deleted` y `role`.
