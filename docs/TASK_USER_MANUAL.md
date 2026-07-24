# Manual de usuario: TSK

## Objetivo

La pantalla `TSK` permite crear, consultar, completar, eliminar y buscar tareas simples mediante el CRUD generico.

Las tareas se conservan en un fichero local, por lo que siguen disponibles al cerrar y volver a abrir la aplicacion.

## Acceder a TSK

1. Inicie sesion en la aplicacion.
2. Se abrira la pantalla principal `FMain`.
3. En la barra lateral izquierda, pulse `Tareas` / `Tasks`.
4. La pantalla de tareas se mostrara en la zona central.

## Crear una tarea

1. Pulse `Nuevo`.
2. Escriba el titulo de la tarea en el detalle.
3. Acepte el detalle.
4. La tarea aparecera en el grid como pendiente.

Las tareas pendientes muestran la columna `Completada` sin marcar.

## Titulo obligatorio

El titulo de una tarea es obligatorio.

Si acepta el detalle sin escribir un titulo valido, la aplicacion mostrara un aviso.

Los espacios al inicio y al final del titulo se eliminan automaticamente al guardar.

## Completar una tarea

1. Seleccione una tarea en la lista.
2. Pulse `Editar`.
3. Marque `Completada`.
4. Acepte los cambios.

Las tareas completadas muestran la columna `Completada` marcada.

## Eliminar una tarea

1. Seleccione una tarea en la lista.
2. Pulse `Eliminar`.
3. La tarea desaparecera del listado.

La aplicacion pide confirmacion antes de eliminar desde el CRUD generico.

## Buscar tareas

1. Escriba el texto a buscar en el campo superior derecho.
2. Pulse `Buscar`.
3. El grid resaltara las celdas coincidentes.

La busqueda no distingue entre mayusculas y minusculas.

Ejemplo:

- Buscar `cliente` encontrara `Llamar al cliente` y `CLIENTE pendiente`.

Tambien puede filtrar por columna con `Ctrl+click` sobre la cabecera de la columna.

## Reset

Pulse `Reset` para:

- Limpiar el campo de busqueda.
- Volver a mostrar todas las tareas.

## Persistencia

Las tareas se guardan automaticamente en el fichero `tasks.json`.

La aplicacion guarda los cambios cuando:

- Crea una tarea.
- Completa una tarea.
- Elimina una tarea.

No es necesario guardar manualmente.

## Estados de tarea

| Campo | Estado | Significado |
| --- | --- | --- |
| `Completada` sin marcar | Pendiente | La tarea aun no esta completada. |
| `Completada` marcada | Completada | La tarea fue marcada como completada. |

## Limitaciones actuales

En esta version:

- No hay prioridades, vencimientos ni responsables.
- Las tareas no estan separadas por usuario.

## Recomendaciones

- Use titulos cortos y claros.
- Busque por una palabra clave del titulo.
- Revise la tarea seleccionada antes de pulsar `Eliminar`.
- Use `Reset` si quiere volver al listado completo despues de una busqueda.
