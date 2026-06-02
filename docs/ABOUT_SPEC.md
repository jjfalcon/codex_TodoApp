# Especificacion funcional: Formulario Acerca de

## Objetivo

Incorporar un formulario `Acerca de` que muestre informacion basica de la aplicacion, version, titularidad y datos tecnicos utiles para soporte.

Esta especificacion define el comportamiento esperado. No describe todavia detalles de implementacion ni estructura de codigo.

## Alcance inicial

La primera version del formulario debe permitir:

- Mostrar el nombre de la aplicacion.
- Mostrar la version de la aplicacion.
- Mostrar una descripcion breve del producto.
- Mostrar informacion de copyright o titularidad.
- Mostrar informacion tecnica basica.
- Cerrar el formulario desde un boton visible.
- Abrirse desde el menu principal de la aplicacion.

Queda fuera del alcance inicial:

- Actualizacion automatica de la aplicacion.
- Consulta online de nuevas versiones.
- Licenciamiento avanzado.
- Envio automatico de informacion a soporte.
- Pantalla de creditos extensa.

## Conceptos

### Informacion de aplicacion

Datos que identifican la aplicacion instalada.

Datos minimos:

- Nombre de la aplicacion.
- Version.
- Descripcion.
- Nombre de la empresa o autor.
- Copyright.

### Informacion tecnica

Datos utiles para soporte o diagnostico.

Datos minimos:

- Version del ejecutable.
- Sistema operativo.
- Arquitectura o plataforma si esta disponible.
- Fecha de compilacion si esta disponible.
- Ruta de base de datos o alias de conexion si aplica y no expone informacion sensible.

### Formulario Acerca de

Ventana modal que presenta la informacion de aplicacion y tecnica de forma solo lectura.

## Reglas de negocio

### Visualizacion

- El formulario debe ser de solo lectura.
- El usuario no debe poder editar ningun dato mostrado.
- El formulario debe poder abrirse desde el menu principal.
- El formulario debe mostrarse como ventana modal.
- El formulario debe cerrarse con un boton `Aceptar` o `Cerrar`.
- El formulario no debe modificar el estado de la aplicacion.

### Datos mostrados

- El nombre de la aplicacion es obligatorio.
- La version de la aplicacion es obligatoria.
- Si algun dato tecnico no esta disponible, debe mostrarse un valor claro como `No disponible`.
- No debe mostrarse informacion sensible como contrasenas, hashes, tokens, cadenas completas de conexion con credenciales o datos personales de usuarios.
- La informacion debe poder obtenerse desde un servicio o proveedor testeable, no directamente desde la UI.

### Acceso

- Cualquier usuario autenticado puede abrir el formulario.
- Si en el futuro existe una pantalla de login previa, el formulario `Acerca de` puede estar disponible antes o despues del login segun decision de producto.
- Para el alcance inicial, se recomienda ubicarlo en el menu `Ayuda`.

## Flujo de usuario

### Abrir formulario

1. El usuario accede al menu `Ayuda`.
2. El usuario selecciona `Acerca de`.
3. La aplicacion obtiene la informacion de aplicacion y datos tecnicos.
4. La aplicacion muestra el formulario de forma modal.

### Cerrar formulario

1. El usuario pulsa `Aceptar` o `Cerrar`.
2. El formulario se cierra.
3. El usuario vuelve a la pantalla desde la que abrio el formulario.
4. No cambia la sesion ni los datos de negocio.

## Contenido esperado

Los textos definitivos pueden ajustarse en la implementacion, pero el formulario debe contener:

- Titulo: `Acerca de`
- Nombre: `Delphi TDD App`
- Version: valor de version de la aplicacion.
- Descripcion: `Aplicacion Windows desarrollada en Delphi siguiendo principios TDD.`
- Copyright: valor configurable.
- Informacion tecnica: seccion con datos utiles para soporte.

## Mensajes esperados

- Dato no disponible: `No disponible`
- Boton de cierre: `Aceptar`
- Menu recomendado: `Ayuda > Acerca de`

## Criterios de aceptacion

- Dado que el usuario abre el menu `Ayuda`, cuando selecciona `Acerca de`, entonces se muestra el formulario `Acerca de`.
- Dado que el formulario se muestra, cuando se carga la informacion, entonces debe verse el nombre de la aplicacion.
- Dado que el formulario se muestra, cuando se carga la informacion, entonces debe verse la version de la aplicacion.
- Dado que el formulario se muestra, cuando existe informacion tecnica disponible, entonces debe mostrarse en modo solo lectura.
- Dado que un dato tecnico no esta disponible, cuando se muestra el formulario, entonces debe mostrarse `No disponible`.
- Dado que el formulario esta abierto, cuando el usuario pulsa `Aceptar`, entonces el formulario se cierra.
- Dado que el formulario esta abierto, cuando el usuario lo cierra, entonces no debe modificarse la sesion activa.
- Dado que existe informacion sensible en la configuracion, cuando se muestra el formulario, entonces esa informacion no debe aparecer.

## Escenarios TDD propuestos

Los primeros tests deben cubrir el nucleo, sin formularios VCL:

- `AboutInfo_returns_application_name`
- `AboutInfo_returns_application_version`
- `AboutInfo_returns_description`
- `AboutInfo_returns_copyright`
- `AboutInfo_returns_not_available_for_missing_optional_data`
- `AboutInfo_does_not_expose_sensitive_connection_data`
- `AboutInfo_can_be_loaded_without_active_business_changes`

## Diseno esperado para TDD

La funcionalidad debe poder probarse sin abrir ventanas.

Componentes conceptuales:

- Proveedor de informacion de aplicacion.
- Proveedor de informacion tecnica.
- Servicio de datos `Acerca de`.
- Sanitizador de informacion sensible.

La UI solo debe:

- Solicitar los datos al servicio `Acerca de`.
- Mostrar la informacion recibida.
- Cerrar el formulario cuando el usuario pulse el boton correspondiente.

## Datos de prueba sugeridos

Aplicacion:

- Nombre: `Delphi TDD App`
- Version: `1.0.0`
- Descripcion: `Aplicacion Windows desarrollada en Delphi siguiendo principios TDD.`
- Empresa o autor: `Juanjo`
- Copyright: `Copyright 2026`

Informacion tecnica:

- Sistema operativo: valor detectado o simulado en pruebas.
- Version del ejecutable: `1.0.0`
- Base de datos: `No disponible` en la primera version si aun no existe conexion real.

## Preguntas pendientes

- Cual sera el nombre definitivo de la aplicacion?
- Cual sera el texto exacto de copyright?
- Debe mostrarse el logo de la aplicacion?
- El formulario debe estar disponible antes del login?
- Que datos tecnicos concretos necesita soporte?
