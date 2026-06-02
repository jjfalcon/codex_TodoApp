# Manual de usuario: Tareas

## Objetivo

La pantalla `Tareas` permite crear, consultar, completar, eliminar y buscar tareas simples.

Las tareas se conservan en un fichero local, por lo que siguen disponibles al cerrar y volver a abrir la aplicacion.

## Acceder a Tareas

1. Inicie sesion en la aplicacion.
2. Se abrira la pantalla principal `FMain`.
3. En la barra lateral izquierda, pulse `Tareas`.
4. La pantalla de tareas se mostrara en la zona central.

## Crear una tarea

1. Escriba el titulo de la tarea en el campo superior izquierdo.
2. Pulse `Anadir`.
3. La tarea aparecera en la lista como pendiente.

Las tareas pendientes se muestran con el prefijo `[ ]`.

Ejemplo:

```text
[ ] Preparar informe
```

## Titulo obligatorio

El titulo de una tarea es obligatorio.

Si pulsa `Anadir` sin escribir un titulo valido, la aplicacion mostrara un aviso.

Los espacios al inicio y al final del titulo se eliminan automaticamente al guardar.

## Completar una tarea

1. Seleccione una tarea en la lista.
2. Pulse `Completar`.
3. La tarea quedara marcada como completada.

Las tareas completadas se muestran con el prefijo `[x]`.

Ejemplo:

```text
[x] Preparar informe
```

## Eliminar una tarea

1. Seleccione una tarea en la lista.
2. Pulse `Eliminar`.
3. La tarea desaparecera del listado.

En la version actual no se muestra confirmacion antes de eliminar.

## Buscar tareas

1. Escriba el texto a buscar en el campo superior derecho.
2. Pulse `Buscar`.
3. La lista mostrara solo las tareas cuyo titulo contiene ese texto.

La busqueda no distingue entre mayusculas y minusculas.

Ejemplo:

- Buscar `cliente` encontrara `Llamar al cliente` y `CLIENTE pendiente`.

## Refrescar la lista

Pulse `Refrescar` para:

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

| Prefijo | Estado | Significado |
| --- | --- | --- |
| `[ ]` | Pendiente | La tarea aun no esta completada. |
| `[x]` | Completada | La tarea fue marcada como completada. |

## Limitaciones actuales

En esta version:

- No se puede editar el titulo de una tarea existente.
- No se puede reabrir una tarea completada.
- No hay confirmacion antes de eliminar.
- No hay filtros por estado.
- No hay prioridades, vencimientos ni responsables.
- Las tareas no estan separadas por usuario.

## Recomendaciones

- Use titulos cortos y claros.
- Busque por una palabra clave del titulo.
- Revise la tarea seleccionada antes de pulsar `Eliminar`.
- Use `Refrescar` si quiere volver al listado completo despues de una busqueda.
