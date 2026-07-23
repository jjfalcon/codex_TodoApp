# Preview generico de CRUD - Diseno tecnico

## Componentes

- `src\App.Win\CrudForm.pas`: origen del snapshot visible.
- `src\App.Win\CrudPreviewForm.pas`: datos de preview y generador QuickReport.
- `src\App.Win\CrudPreviewForm.dfm`: dialogo de opciones.
- `src\App.Win\WindowsApp.dpr`: registra `CrudPreviewForm` en la aplicacion.
- `tests\App.Win.Tests\CrudFormTests.pas`: pruebas del boton, snapshot y opciones.
- `tests\App.Win.Tests\LocalizationAuditTests.pas`: auditoria de localizacion.

## Flujo

1. El usuario pulsa `Preview` en `TFrmCrud`.
2. `TFrmCrud.BtnPreviewClick` crea `TFrmCrudPreview`.
3. `TFrmCrud.CreatePreviewData` crea un `TCrudPreviewData` con el estado visible del grid.
4. `TFrmCrudPreview.Configure` toma ownership del `TCrudPreviewData`.
5. El usuario ajusta opciones y pulsa `Vista previa` o `Imprimir`.
6. `BuildReport` crea dinamicamente un `TQuickRep` con bandas, cabeceras y detalle.
7. QuickReport llama `ReportNeedData` y `DetailBeforePrint` para recorrer filas.

## Modelo De Datos

`TCrudPreviewData` contiene:

- `Title`: titulo del informe.
- `FColumns`: captions de columnas.
- `FColumnWidths`: anchos originales del grid.
- `FRows`: lista de `TStringList`, una por fila.

Metodos principales:

- `AddColumn`: agrega una columna con ancho por defecto.
- `AddColumnEx`: agrega caption y ancho original.
- `AddRow`: copia valores de una fila.
- `ColumnCount`, `ColumnCaption`, `ColumnWidth`: acceso a columnas.
- `RowCount`, `Cell`: acceso a filas y celdas.

## Snapshot Del Grid

`TFrmCrud.CreatePreviewData` usa:

- `Caption` del formulario como `Title`.
- `Grid.Columns[I].Visible` para decidir inclusion.
- `Grid.Columns[I].Title.Caption` para cabeceras.
- `Grid.Columns[I].Width` para anchos relativos.
- `ClientDataSet.FieldByName(Column.FieldName).AsString` para valores.

El metodo preserva la posicion del dataset con `GetBookmark`, `GotoBookmark` y `FreeBookmark`, y desactiva controles durante la iteracion.

## Generacion QuickReport

`TFrmCrudPreview.BuildReport` crea el informe en tiempo de ejecucion:

- `TQuickRep` invisible y con owner temporal.
- Banda de titulo si se muestra titulo o fecha.
- Banda de cabecera con un `TQRLabel` por columna.
- Banda de detalle con labels reutilizados por fila.
- Banda de pie si se muestra numero de pagina.

La orientacion se decide desde `CmbOrientation`:

- `ItemIndex = 0`: `poPortrait`.
- `ItemIndex = 1`: `poLandscape`.

El ancho disponible interno es fijo por orientacion:

- Vertical: `640`.
- Horizontal: `920`.

Los anchos se calculan de forma proporcional:

```pascal
Result := (FData.ColumnWidth(AIndex) * ATotalWidth) div TotalColumnWidth;
```

Cada columna tiene un minimo de `40` unidades para evitar columnas invisibles.

## BandType

En este entorno de Delphi 7 y QuickReport no estan disponibles constantes como `rbTitle` o `rbDetail`.

Por eso `SetBandType` usa RTTI:

```pascal
SetOrdProp(ABand, 'BandType', ABandType);
```

Valores usados:

- `0`: titulo.
- `8`: cabecera de columna.
- `2`: detalle.
- `3`: pie.

## Ciclo De Vida

- `TFrmCrud.BtnPreviewClick` crea y libera `TFrmCrudPreview` con `try/finally`.
- `TFrmCrudPreview.Configure` libera cualquier `FData` anterior y conserva el nuevo snapshot.
- `TFrmCrudPreview.Destroy` libera `FData` y `FDetailLabels`.
- `PreviewData` y `PrintData` crean un `TQuickRep` temporal y lo liberan despues de usarlo.
- `ClearDetailLabels` limpia referencias despues de liberar el informe.

## Limitaciones Conocidas

- El informe no exporta a PDF ni a otros formatos.
- El texto largo no se trunca manualmente; QuickReport lo renderiza dentro del ancho asignado.
- El preview no pagina horizontalmente columnas muy numerosas; las escala al ancho disponible.
- El dialogo de opciones no persiste preferencias.
- La busqueda visual del grid solo afecta el resaltado en pantalla, no aplica color en el informe.

## Comandos De Verificacion

```bat
cd tests\App.Win.Tests
run-tests.bat
```

```bat
cd src\App.Win
dcc32 "-U..\App.Core" -B WindowsApp.dpr
```

Si `WindowsApp.exe` esta bloqueado, compilar a salida temporal:

```bat
dcc32 "-U..\App.Core" "-EC:\Users\Juanjo\AppData\Local\Temp\opencode" -B WindowsApp.dpr
```
