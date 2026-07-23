# Preview generico de CRUD - Especificacion

## Objetivo

El preview generico permite previsualizar e imprimir la tabla visible de `TFrmCrud` sin introducir reglas de negocio en la UI y sin depender de una entidad concreta.

La salida debe representar el estado actual del grid en pantalla: columnas visibles, captions actuales, anchos actuales y filas ya cargadas en el `TClientDataSet`.

## Alcance

- Aplica a formularios basados en `TFrmCrud`.
- El boton `Preview` abre `TFrmCrudPreview`.
- El preview usa un snapshot inmutable de la grilla actual mediante `TCrudPreviewData`.
- La implementacion actual usa QuickReport para previsualizar e imprimir.
- La funcionalidad es generica: no conoce usuarios, tareas, repositorios ni servicios de dominio.

## Comportamiento Esperado

- `TFrmCrud.CreatePreviewData` toma los datos desde `Grid` y `ClientDataSet`.
- Solo se incluyen columnas con `TColumn.Visible = True`.
- Las cabeceras usan `TColumn.Title.Caption`, incluyendo localizacion e indicadores activos de filtro u orden.
- Los anchos se toman desde `TColumn.Width` y se escalan proporcionalmente al ancho imprimible.
- Las filas se toman desde el `ClientDataSet` ya cargado.
- No se llama a `ICrudProvider.List` desde el preview.
- No se reevalua busqueda, filtro, orden ni permisos al generar el informe.
- El bookmark activo del dataset se restaura despues de tomar el snapshot.

## Opciones De Usuario

- Orientacion: `Vertical` o `Horizontal`.
- Mostrar titulo: incluye el caption del formulario CRUD como titulo del informe.
- Mostrar fecha: incluye fecha y hora generadas por QuickReport.
- Mostrar pagina: incluye numero de pagina en el pie.
- Configurar: abre el dialogo de configuracion de impresora.
- Vista previa: abre el preview de QuickReport.
- Imprimir: envia el informe a impresora.
- Cerrar: cierra el dialogo de opciones.

## Reglas De Integridad

- El preview no modifica datos de negocio.
- El preview no guarda layout ni preferencias.
- El preview no crea, edita ni borra registros.
- El preview debe funcionar con cualquier schema expuesto por `ICrudProvider`.
- Si no hay datos configurados, `PreviewData` y `PrintData` salen sin accion.
- Si no hay filas, el informe conserva las cabeceras pero no imprime detalle.

## Localizacion

Las claves de formulario se declaran en `src\App.Win\languages.csv`:

- `FrmCrud.BtnPreview.Caption`
- `FrmCrudPreview.Caption`
- `FrmCrudPreview.LblOrientation.Caption`
- `FrmCrudPreview.ChkShowTitle.Caption`
- `FrmCrudPreview.ChkShowDate.Caption`
- `FrmCrudPreview.ChkShowPageNumber.Caption`
- `FrmCrudPreview.BtnPreview.Caption`
- `FrmCrudPreview.BtnPrinterSetup.Caption`
- `FrmCrudPreview.BtnPrint.Caption`
- `FrmCrudPreview.BtnClose.Caption`

## Verificacion

- `CrudForm_preview_button_is_available` valida que el boton existe y esta habilitado.
- `CrudForm_preview_data_uses_visible_grid_exactly` valida columnas visibles, captions, anchos y filas cargadas.
- `CrudPreviewForm_exposes_layout_options` valida opciones del dialogo.
- `LocalizationAudit_accepts_crud_preview_form_csv` valida claves de localizacion del formulario.
