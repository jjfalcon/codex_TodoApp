# Especificacion funcional: Tareas

> Nota: esta especificacion conserva el diseno inicial de la pantalla clasica de tareas. La implementacion vigente esta simplificada en `TSK` mediante `TFrmCrud` y `TTaskCrudProvider`; para el contrato actual, usar `docs\ARCHITECTURE.md`, `docs\CRUD_FORM_SPEC.md` y `docs\TASK_USER_MANUAL.md`.

## Estado

Completada el 2026-06-02.

Implementacion principal:

- Nucleo: `src/App.Core/AppCoreTaskItem.pas`, `src/App.Core/AppCoreTaskRepository.pas`, `src/App.Core/AppCoreTaskService.pas`.
- Persistencia: `src/App.Core/AppCoreTaskFileRepository.pas`.
- UI VCL vigente: `src\App.Win\CrudForm.pas` con `TTaskCrudProvider`.
- Pruebas: `tests/App.Core.Tests/AppCoreTaskServiceTests.pas`.

## Objetivo

Permitir gestionar una lista simple de tareas desde la aplicacion Windows.

La funcionalidad permite crear tareas, listarlas, marcarlas como completadas, eliminarlas, buscar por titulo y conservarlas en fichero JSON. El nucleo mantiene las reglas de negocio y la UI VCL solo invoca el servicio de tareas y refresca la lista visible.

## Alcance inicial implementado

La version actual permite:

- Crear una tarea con titulo obligatorio.
- Eliminar espacios al inicio y al final del titulo al guardar.
- Crear nuevas tareas en estado pendiente.
- Registrar la fecha de creacion usando un reloj inyectable.
- Listar todas las tareas existentes.
- Marcar una tarea como completada.
- Registrar la fecha de completado usando un reloj inyectable.
- Eliminar una tarea existente.
- Buscar tareas por texto contenido en el titulo.
- Hacer busquedas sin distinguir mayusculas y minusculas.
- Mostrar tareas pendientes y completadas en la UI.
- Integrar la pantalla de tareas como formulario incrustado dentro de `FMain`.
- Persistir tareas en un fichero JSON local llamado `tasks.json`.
- Recargar las tareas desde `tasks.json` al abrir la pantalla de tareas.

Queda fuera del alcance actual:

- Editar el titulo de una tarea existente.
- Reabrir una tarea completada.
- Asignar vencimientos, prioridades, etiquetas o responsables.
- Persistir tareas en base de datos.
- Compartir tareas entre sesiones de aplicacion.
- Confirmar eliminaciones.
- Ordenacion configurable.
- Filtros por estado distintos de la busqueda por titulo.

## Conceptos

### Tarea

Elemento de trabajo gestionado por la aplicacion.

Datos actuales:

- Identificador interno.
- Titulo.
- Fecha de creacion.
- Fecha de completado.
- Estado.

### Estado de tarea

Valores disponibles:

- `Pendiente`: tarea creada y aun no completada.
- `Completada`: tarea marcada como finalizada.

### Repositorio de tareas

Componente responsable de guardar y recuperar tareas.

Implementaciones actuales:

- `TInMemoryTaskRepository`: repositorio en memoria para pruebas y escenarios sin fichero.
- `TFileTaskRepository`: repositorio en fichero JSON para la aplicacion Windows.

La aplicacion Windows guarda las tareas en `tasks.json`, ubicado junto al ejecutable.

### Servicio de tareas

Componente de negocio que valida operaciones y coordina el repositorio.

La implementacion actual es `TTaskService`.

### Pantalla de tareas

Formulario VCL `TFrmTasks` que permite interactuar con el servicio de tareas desde la interfaz.

## Reglas de negocio

### Creacion

- El titulo de una tarea es obligatorio.
- Un titulo vacio o compuesto solo por espacios debe rechazarse.
- Los espacios al inicio y al final del titulo no deben guardarse.
- Toda tarea nueva debe crearse en estado pendiente.
- Toda tarea nueva debe recibir un identificador interno.
- La fecha de creacion debe obtenerse desde el reloj configurado.
- Una tarea creada debe quedar almacenada en el repositorio.

### Listado

- El sistema debe poder devolver todas las tareas almacenadas.
- Si no existen tareas, el listado debe estar vacio.
- La UI debe refrescar la lista tras crear, completar, eliminar o limpiar la busqueda.

### Completado

- Solo se puede completar una tarea existente.
- Al completar una tarea, su estado debe pasar a completada.
- Al completar una tarea, debe registrarse la fecha de completado desde el reloj configurado.
- Una tarea completada debe mostrarse en la UI con prefijo `[x]`.
- Una tarea pendiente debe mostrarse en la UI con prefijo `[ ]`.

### Eliminacion

- Solo se puede eliminar una tarea existente.
- Al eliminar una tarea, debe desaparecer del repositorio y del listado visible.

### Busqueda

- La busqueda debe comparar contra el titulo de la tarea.
- La busqueda no debe distinguir mayusculas y minusculas.
- El texto de busqueda debe ignorar espacios laterales.
- Si el texto de busqueda esta vacio, debe devolverse el listado completo.
- La UI debe mostrar solo los resultados encontrados tras pulsar `Buscar`.

### Tareas inexistentes

- Si se intenta completar o eliminar una tarea inexistente, el nucleo debe lanzar `ETaskNotFoundError`.

### Persistencia en fichero

- La aplicacion debe guardar las tareas en un fichero JSON llamado `tasks.json`.
- El fichero debe contener una lista de tareas.
- Cada tarea persistida debe incluir `id`, `title`, `createdAt`, `completedAt` y `status`.
- Las tareas pendientes deben guardar `completedAt` como `null`.
- Las tareas completadas deben guardar `status` como `completed`.
- Las tareas pendientes deben guardar `status` como `pending`.
- Al crear, completar o eliminar una tarea, el fichero debe actualizarse.
- Al iniciar el repositorio de fichero, las tareas existentes deben cargarse desde `tasks.json`.
- Si `tasks.json` no existe, el repositorio debe iniciar con una lista vacia.

## Flujo de usuario

### Abrir tareas

1. El usuario inicia sesion correctamente.
2. La aplicacion abre `FMain`.
3. El usuario selecciona `Tareas` en la barra lateral.
4. `FMain` incrusta `TFrmTasks` en la zona central.
5. La aplicacion carga las tareas desde `tasks.json`.
6. La pantalla muestra la lista actual de tareas.

### Crear tarea

1. El usuario escribe un titulo en el campo de nueva tarea.
2. Pulsa `Anadir`.
3. La aplicacion valida el titulo.
4. Si el titulo es valido, la tarea se crea como pendiente.
5. El campo de titulo se limpia.
6. La lista se refresca.

### Completar tarea

1. El usuario selecciona una tarea en la lista.
2. Pulsa `Completar`.
3. La aplicacion marca la tarea como completada.
4. La lista se refresca mostrando la tarea con prefijo `[x]`.

### Eliminar tarea

1. El usuario selecciona una tarea en la lista.
2. Pulsa `Eliminar`.
3. La aplicacion elimina la tarea.
4. La lista se refresca sin esa tarea.

### Buscar tareas

1. El usuario escribe un texto en el campo de busqueda.
2. Pulsa `Buscar`.
3. La aplicacion muestra las tareas cuyo titulo contiene ese texto.

### Refrescar listado

1. El usuario pulsa `Refrescar`.
2. La aplicacion limpia el campo de busqueda.
3. La aplicacion muestra todas las tareas.

## Mensajes esperados

Los textos definitivos pueden ajustarse, pero la implementacion actual usa:

- Titulo obligatorio: `Task title is required.`
- Tarea no encontrada: `Task was not found.`

## Criterios de aceptacion

- Dado un titulo valido con espacios laterales, cuando se crea la tarea, entonces se guarda el titulo sin esos espacios.
- Dado un titulo valido, cuando se crea la tarea, entonces queda en estado pendiente.
- Dado una tarea creada, cuando se lista, entonces aparece en el listado.
- Dado un titulo vacio o compuesto solo por espacios, cuando se intenta crear una tarea, entonces se rechaza la operacion.
- Dado una tarea pendiente, cuando se completa, entonces queda marcada como completada.
- Dado una tarea completada, cuando se consulta su fecha de completado, entonces corresponde al reloj configurado.
- Dado una tarea existente, cuando se elimina, entonces desaparece del listado.
- Dado varias tareas, cuando se busca por texto contenido en el titulo, entonces se devuelven las coincidencias.
- Dado una busqueda con diferente uso de mayusculas, cuando se ejecuta, entonces devuelve las coincidencias sin distinguir mayusculas y minusculas.
- Dado una busqueda vacia, cuando se ejecuta, entonces devuelve todas las tareas.
- Dado una tarea inexistente, cuando se intenta completar o eliminar, entonces se informa error de tarea no encontrada desde el nucleo.
- Dado una tarea creada, cuando se reconstruye el repositorio desde `tasks.json`, entonces la tarea vuelve a estar disponible.
- Dado una tarea completada, cuando se reconstruye el repositorio desde `tasks.json`, entonces conserva estado completado y fecha de completado.

## Escenarios TDD implementados

- `CreateTaskStoresTrimmedPendingTask`
- `CreateTaskRejectsEmptyTitle`
- `CompleteTaskMarksTaskAsCompleted`
- `DeleteTaskRemovesTask`
- `SearchTasksReturnsMatchingTitles`
- `FileRepositoryPersistsCreatedTasks`
- `FileRepositoryPersistsCompletedTasks`

## Diseno tecnico esperado

La funcionalidad debe poder probarse sin abrir ventanas VCL.

Componentes implementados:

- `TTaskItem`: entidad de tarea.
- `ITaskRepository`: contrato de persistencia.
- `TInMemoryTaskRepository`: repositorio en memoria.
- `TFileTaskRepository`: repositorio persistente en JSON.
- `ITaskService`: contrato de negocio.
- `TTaskService`: reglas de negocio y operaciones de tareas.
- `IClock`: reloj inyectable para fechas testeables.
- `TFrmTasks`: formulario VCL fino para operar contra `ITaskService`.

La UI solo debe:

- Leer el titulo introducido por el usuario.
- Llamar al servicio para crear, completar, eliminar, listar o buscar.
- Mostrar mensajes de validacion del nucleo.
- Refrescar la lista visible.

## Datos de prueba usados

Los tests usan un reloj fijo con fecha `2026-04-30`.

Ejemplos de titulos:

- `Prepare release`
- `Write test`
- `Remove me`
- `Call customer`
- `Prepare invoice`
- `Customer follow up`

## Decisiones confirmadas

- Las tareas se almacenan en memoria en la version actual.
- El nucleo no depende de VCL.
- La UI de tareas se incrusta dentro de `FMain`.
- Las tareas nuevas empiezan en estado pendiente.
- La busqueda actual opera solo sobre el titulo.
- La persistencia inicial de tareas usa JSON en `tasks.json`.

## Preguntas pendientes

- Debe permitirse editar tareas existentes?
- Debe existir confirmacion antes de eliminar?
- Deben existir filtros por estado pendiente/completada?
- Deben compartirse las tareas entre usuarios o ser independientes por usuario?
- Debe configurarse una ruta de datos distinta a la carpeta del ejecutable?
