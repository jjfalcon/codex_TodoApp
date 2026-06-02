# Documentacion tecnica: Tareas

## Resumen

La funcionalidad de tareas esta implementada en el nucleo `App.Core` y expuesta en VCL mediante `TFrmTasks`.

El servicio de negocio no depende de la UI ni del tipo de persistencia. Las tareas se guardan mediante `ITaskRepository`, con dos implementaciones disponibles:

- `TInMemoryTaskRepository`: repositorio en memoria.
- `TFileTaskRepository`: repositorio persistente en JSON.

La aplicacion Windows usa `TFileTaskRepository` y guarda las tareas en `tasks.json`, ubicado junto al ejecutable.

## Componentes

### `AppCoreTaskItem.pas`

Define la entidad `TTaskItem`.

Campos principales:

- `Id`
- `Title`
- `CreatedAt`
- `CompletedAt`
- `Status`

Estados:

- `tsPending`
- `tsCompleted`

Metodo auxiliar:

- `IsCompleted`

### `AppCoreTaskRepository.pas`

Define el contrato `ITaskRepository`.

Operaciones:

- `Add`
- `Delete`
- `FindById`
- `ListAll`
- `Save`

Tambien contiene `TInMemoryTaskRepository`, usado para tests y escenarios sin persistencia en fichero.

### `AppCoreTaskFileRepository.pas`

Implementa `TFileTaskRepository`.

Responsabilidades:

- Cargar tareas desde `tasks.json` al construirse.
- Guardar el fichero al crear, completar o eliminar tareas.
- Serializar tareas a JSON.
- Reconstruir tareas desde JSON.
- Mantener el contrato `ITaskRepository`.

Formato usado:

```json
[
  {
    "id": "{GUID}",
    "title": "Prepare release",
    "createdAt": "2026-04-30T00:00:00",
    "completedAt": null,
    "status": "pending"
  }
]
```

Valores de `status`:

- `pending`
- `completed`

`completedAt` se guarda como `null` cuando la tarea esta pendiente.

### `AppCoreTaskService.pas`

Implementa `TTaskService`.

Responsabilidades:

- Validar que el titulo no este vacio.
- Recortar espacios laterales del titulo.
- Crear tareas pendientes.
- Completar tareas existentes.
- Eliminar tareas existentes.
- Buscar tareas por titulo.
- Lanzar errores de dominio.

Excepciones:

- `ETaskValidationError`
- `ETaskNotFoundError`

### `TaskForm.pas`

Formulario VCL de tareas.

Responsabilidades:

- Crear el servicio con `TFileTaskRepository`.
- Usar `tasks.json` junto al ejecutable:

```pascal
ExtractFilePath(Application.ExeName) + 'tasks.json'
```

- Mostrar tareas en un `TListBox`.
- Usar prefijo `[ ]` para pendientes.
- Usar prefijo `[x]` para completadas.
- Invocar el servicio para crear, completar, eliminar, buscar y refrescar.

## Flujo de Persistencia

### Crear tarea

1. `TFrmTasks` llama a `TTaskService.CreateTask`.
2. `TTaskService` valida el titulo.
3. `TTaskService` crea `TTaskItem`.
4. `TTaskService` llama a `ITaskRepository.Add`.
5. `TFileTaskRepository.Add` agrega la tarea a memoria.
6. `TFileTaskRepository` escribe `tasks.json`.

### Completar tarea

1. `TFrmTasks` llama a `TTaskService.CompleteTask`.
2. `TTaskService` busca la tarea con `FindById`.
3. Cambia el estado a `tsCompleted`.
4. Registra `CompletedAt`.
5. Llama a `ITaskRepository.Save`.
6. `TFileTaskRepository.Save` reescribe `tasks.json`.

### Eliminar tarea

1. `TFrmTasks` llama a `TTaskService.DeleteTask`.
2. `TTaskService` verifica que la tarea existe.
3. Llama a `ITaskRepository.Delete`.
4. `TFileTaskRepository.Delete` elimina la tarea de memoria.
5. Reescribe `tasks.json`.

### Cargar tareas

1. `TFrmTasks` crea `TFileTaskRepository`.
2. El repositorio busca `tasks.json`.
3. Si no existe, inicia una lista vacia.
4. Si existe, parsea los objetos JSON y reconstruye `TTaskItem`.
5. `TFrmTasks` llama a `ListTasks` y refresca la lista.

## Tests

Archivo:

- `tests/App.Core.Tests/AppCoreTaskServiceTests.pas`

Escenarios cubiertos:

- `CreateTaskStoresTrimmedPendingTask`
- `CreateTaskRejectsEmptyTitle`
- `CompleteTaskMarksTaskAsCompleted`
- `DeleteTaskRemovesTask`
- `SearchTasksReturnsMatchingTitles`
- `FileRepositoryPersistsCreatedTasks`
- `FileRepositoryPersistsCompletedTasks`

Los tests de fichero crean JSON temporal junto al ejecutable de pruebas y lo eliminan al finalizar.

## Comandos de Verificacion

```bat
cd tests\App.Core.Tests
dcc32 "-U..\..\src\App.Core" AppCoreTests.dpr
AppCoreTests.exe

cd ..\..\src\App.Win
dcc32 "-U..\App.Core" WindowsApp.dpr
```

## Decisiones Tecnicas

- Se usa JSON porque es legible, portable y permite evolucionar la estructura de datos.
- Se mantiene `ITaskRepository` para poder sustituir la persistencia sin tocar `TTaskService`.
- La aplicacion Windows usa fichero; los tests pueden seguir usando memoria.
- `tasks.json` esta ignorado en Git porque contiene datos locales de ejecucion.
- No se introducen dependencias externas para conservar compatibilidad con Delphi 7.

## Limitaciones Actuales

- El parser JSON es especifico para el formato generado por `TFileTaskRepository`.
- No hay migraciones de esquema.
- No hay bloqueo de fichero para acceso concurrente.
- No hay recuperacion automatica ante JSON corrupto.
- La ruta de datos es la carpeta del ejecutable.
- Las tareas no estan separadas por usuario.

## Evolucion Recomendada

- Separar la ruta de datos en una configuracion.
- Crear copias de seguridad antes de reescribir `tasks.json`.
- Agregar manejo claro de fichero corrupto.
- Separar tareas por usuario autenticado si el producto lo requiere.
- Sustituir el parser propio por una libreria JSON si se acepta una dependencia externa.
