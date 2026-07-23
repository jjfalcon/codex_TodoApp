# Preview generico de CRUD - Manual de usuario

## Acceso

1. Abrir la aplicacion Windows.
2. Iniciar sesion con un usuario con permisos para la opcion deseada.
3. Entrar a una pantalla basada en el CRUD generico, por ejemplo `USR`.
4. Revisar que el grid muestre la informacion que se quiere imprimir.
5. Pulsar `Preview`.

## Que Se Imprime

El informe usa lo que se ve en el grid al pulsar `Preview`:

- Columnas visibles.
- Orden actual de columnas.
- Ancho actual de columnas.
- Titulos actuales de columnas.
- Filas cargadas actualmente.

Si una cabecera muestra indicadores como `*`, `^` o `v`, esos indicadores forman parte del titulo visible y pueden aparecer en el informe.

## Preparar La Vista

Antes de abrir el preview se puede ajustar la tabla:

- Cambiar orden haciendo click en cabeceras.
- Aplicar filtros con `Ctrl+click` en una cabecera.
- Usar `Reset` para limpiar filtros, busqueda y orden.
- Cambiar anchos de columnas en el grid.
- Ocultar columnas si la pantalla lo permite desde la configuracion del grid.

La busqueda resalta celdas en pantalla, pero no filtra filas ni se imprime como resaltado.

## Opciones Del Dialogo

- `Orientacion`: elige `Vertical` u `Horizontal`.
- `Mostrar titulo`: incluye el titulo de la pantalla CRUD.
- `Mostrar fecha`: incluye fecha y hora en el informe.
- `Mostrar pagina`: incluye el numero de pagina.
- `Vista previa`: abre el visor de QuickReport.
- `Configurar`: abre la configuracion de impresora.
- `Imprimir`: imprime directamente con las opciones actuales.
- `Cerrar`: cierra el dialogo sin imprimir.

## Flujo Recomendado

1. Ajustar filtros y columnas en el grid.
2. Pulsar `Preview`.
3. Elegir `Horizontal` si hay muchas columnas.
4. Mantener `Mostrar titulo`, `Mostrar fecha` y `Mostrar pagina` activados si el informe se va a archivar.
5. Pulsar `Vista previa` para revisar el resultado.
6. Si el resultado es correcto, imprimir desde el visor o volver al dialogo y pulsar `Imprimir`.

## Solucion De Problemas

- No aparece el boton `Preview`: confirmar que se esta usando una pantalla basada en `TFrmCrud`, como `USR`.
- No aparecen todas las columnas: revisar si estan ocultas en el grid antes de abrir `Preview`.
- El orden no es el esperado: cerrar el preview, ordenar el grid y volver a abrir `Preview`.
- Hay pocas columnas pero mucho espacio: cambiar a orientacion vertical si se prefiere una salida mas compacta.
- Hay muchas columnas comprimidas: usar orientacion horizontal y aumentar anchos en el grid antes de abrir `Preview`.
- No imprime: usar `Configurar` para verificar la impresora disponible en Windows.

## Notas

- El preview no cambia datos de la aplicacion.
- El preview no guarda preferencias.
- El informe se genera desde un snapshot; si el grid cambia despues, hay que cerrar y abrir de nuevo el preview para reflejar esos cambios.
