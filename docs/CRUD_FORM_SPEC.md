# Formulario CRUD generico

## Objetivo

`TFrmCrud` permite reutilizar una pantalla VCL para listar, buscar, ordenar, crear, editar y borrar entidades descritas por un proveedor de `src\App.Core`.

La UI no accede directamente a tablas ni ficheros de datos. Toda regla de negocio, validacion y persistencia pasa por `ICrudProvider` y por los servicios Core que implemente cada adaptador.

## Contrato Core

- `TCrudSchema` define los campos que se exponen a la UI.
- `TCrudFieldDef` indica nombre, caption, tipo, visibilidad, editabilidad, obligatoriedad y ancho sugerido.
- `TCrudRecord` transporta valores como texto entre UI y proveedor.
- `ICrudProvider` expone `Schema`, `List`, `CreateRecord`, `UpdateRecord` y `DeleteRecord`.
- `List` recibe filtros por columna como pares `campo=valor`.
- `ICrudGridLayoutRepository` guarda y lee el layout persistente de cada grid.

## Modos De Edicion

- `emNone`: grid en solo lectura, sin altas ni borrados, sin detalle por doble click.
- `emGrid`: permite editar directamente en el grid y persiste cambios con `UpdateRecord`.
- `emDetail`: mantiene el grid en solo lectura y abre `TFrmCrudDetail` para alta/edicion.

## Comportamiento VCL

- `TFrmCrud` crea un `TClientDataSet` dinamico desde el schema.
- `Ctrl+click` sobre una cabecera abre el filtro de esa columna.
- El boton `Reset` limpia filtros, busqueda y orden, guarda la configuracion y recarga el grid.
- El boton `Buscar` abre un formulario no modal. La busqueda no filtra filas: resalta en amarillo las celdas visibles que contienen el texto buscado.
- El boton `Preview` abre una vista previa generica imprimible de la tabla actual.
- El preview imprime exactamente lo visible en pantalla: columnas visibles, captions actuales y filas ya cargadas en el grid. No reconsulta repositorios ni proveedores.
- El click en cabecera cambia el campo de orden y alterna ascendente/descendente. La cabecera muestra `^` para ascendente, `v` para descendente y nada si no hay orden.
- La cabecera muestra `*` cuando hay un filtro activo sobre ese campo.
- Nuevo, editar y borrar delegan siempre en el proveedor.
- Borrar solicita confirmacion antes de llamar al proveedor.
- `TFrmCrudDetail` genera controles dinamicos a partir del schema y escribe los valores en `TCrudRecord`.
- `TFrmCrudPreview` recibe un snapshot generico (`TCrudPreviewData`) y genera un informe QuickReport dinamico.
- El dialogo de preview permite ajustar orientacion, titulo, fecha y numero de pagina antes de abrir la vista previa o imprimir.
- La cabecera de acciones queda `alTop` y el grid `alClient`, ocupando todo el espacio restante.

## Layout De Columnas

Si `Configure` recibe un `ICrudGridLayoutRepository` y una clave de grid, `TFrmCrud` guarda y restaura:

- orden de columnas
- ancho de columnas
- visibilidad de columnas

La persistencia se guarda en `app.config` usando una seccion por grid. Ejemplo:

```ini
[Grid.USR]
email.Index=0
email.Width=180
email.Visible=1
Filter.email=admin
Sort.Field=email
Sort.Ascending=1
```

No se generan ficheros `usr-grid.layout`.

## Usuarios USR

`USR` es una opcion administrativa de `FMain` que reutiliza `TFrmCrud` con `TUserCrudProvider` y `emDetail`. El proveedor adapta `TUserService`, por lo que mantiene las validaciones y permisos existentes del Core.

`FMain` crea el servicio de usuarios despues de embeber `TFrmCrud`; esto evita que `ClearContent` libere el servicio antes de que el provider cargue los datos.

## Tareas TSK

`TSK` es una opcion de `FMain` que convive con la pantalla clasica `Tareas` y reutiliza `TFrmCrud` con `TTaskCrudProvider` y `emDetail`.

El proveedor adapta `ITaskService`, por lo que la UI no accede a repositorios ni contiene reglas de negocio. El schema expone:

- `title`: visible, editable y requerido.
- `completed`: visible, editable y representado como booleano para checkbox en el detalle.
- `createdAt`: visible y de solo lectura.

El layout se persiste con la clave `TSK` en la seccion `Grid.TSK`.

## Verificacion

- `tests\App.Core.Tests`: cubre schema, busqueda, orden, filtros, update del provider de usuarios y layout en secciones `Grid.*`.
- `tests\App.Win.Tests`: cubre modos de edicion, columnas generadas, escritura de detalle, persistencia de layout/filtros, indicadores de cabecera, paso de filtros, busqueda de celdas sin filtrar filas y snapshot de preview exacto del grid visible.
