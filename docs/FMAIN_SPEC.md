# Especificacion funcional: Pantalla principal FMain

## Objetivo

Incorporar una pantalla principal `FMain` que actue como contenedor principal de la aplicacion tras un login correcto.

`FMain` debe comportarse como un formulario shell: tendra una barra lateral izquierda con las opciones de navegacion disponibles y una zona central donde se incrustaran los formularios correspondientes a cada opcion cuando el usuario la active.

Esta especificacion define el comportamiento esperado. No describe todavia detalles de implementacion ni estructura exacta de codigo.

## Alcance inicial

La primera version de `FMain` debe permitir:

- Mostrar una barra lateral izquierda de navegacion.
- Mostrar las opciones iniciales `Dashboard`, `TSK` y `USR`.
- Cargar automaticamente `Dashboard` al abrir la pantalla principal.
- Incrustar en la zona central el formulario asociado a la opcion seleccionada.
- Mantener una unica opcion activa en cada momento.
- Marcar visualmente la opcion activa.
- Proteger el acceso a `FMain` mediante sesion activa.
- Consultar permisos para mostrar, habilitar o ejecutar opciones protegidas.
- Bloquear o cerrar la pantalla principal si la sesion expira.
- Gestionar errores de carga de una opcion sin dejar la aplicacion en un estado inconsistente.

Queda fuera del alcance inicial:

- Definir el diseno interno completo de cada formulario incrustado.
- Implementar permisos avanzados mas alla de usuario autenticado y administrador.
- Incluir la opcion `Ayuda` en la barra lateral izquierda.
- Definir el acceso definitivo al formulario `Acerca de`.
- Persistir preferencias de navegacion del usuario.
- Permitir multiples formularios centrales abiertos simultaneamente.

## Conceptos

### FMain

Formulario principal de la aplicacion Windows.

Representa el marco general de trabajo de un usuario autenticado y contiene:

- Barra lateral izquierda.
- Zona central de contenido.
- Estado de opcion activa.
- Integracion con la sesion activa.

### Barra lateral izquierda

Area fija de navegacion situada a la izquierda de `FMain`.

Debe mostrar las opciones disponibles para el usuario autenticado.

Opciones iniciales:

- `Dashboard`
- `TSK`
- `USR`

La barra lateral izquierda no debe incluir una opcion `Ayuda`.

### Opcion de navegacion

Entrada seleccionable que representa una funcionalidad principal de la aplicacion.

Datos minimos:

- Identificador interno.
- Texto visible.
- Requisito de permiso.
- Formulario o vista asociada.
- Estado visible o no visible.
- Estado habilitado o deshabilitado.

### Zona central

Area principal de trabajo donde se incrusta el formulario asociado a la opcion activa.

Debe ocupar el espacio disponible a la derecha de la barra lateral.

### Formulario incrustado

Formulario o vista VCL que se muestra dentro de la zona central de `FMain`.

Debe integrarse como contenido del formulario principal, no como una ventana independiente, salvo que una funcionalidad concreta lo indique expresamente en otra especificacion.

### Opcion activa

Opcion actualmente seleccionada por el usuario.

Solo puede existir una opcion activa en cada momento.

### Sesion activa

Estado que indica que un usuario esta autenticado y puede acceder a funcionalidades protegidas.

`FMain` requiere una sesion activa para mostrarse y permanecer utilizable.

## Reglas de negocio

### Acceso a FMain

- `FMain` solo debe mostrarse si existe una sesion activa.
- Si no existe sesion activa, la aplicacion debe mostrar el login y bloquear el acceso a `FMain`.
- Si la sesion expira mientras `FMain` esta abierta, la aplicacion debe cerrar o bloquear `FMain` y volver a solicitar login.
- Tras cerrar sesion, ningun formulario incrustado debe quedar accesible.
- La comprobacion de sesion debe quedar fuera de reglas visuales aisladas de la UI.

### Opciones disponibles

- La barra lateral debe construir sus opciones segun la sesion y permisos del usuario autenticado.
- `Dashboard` debe estar disponible para cualquier usuario autenticado.
- `TSK` debe estar disponible para cualquier usuario autenticado.
- `USR` debe estar disponible solo para usuarios administradores.
- Las opciones no permitidas deben ocultarse o mostrarse deshabilitadas segun la decision de implementacion, pero no deben poder ejecutarse.
- La UI no debe decidir permisos por su cuenta; debe consultar al nucleo o servicio de permisos.
- La barra lateral izquierda no debe mostrar `Ayuda`.

### Vista inicial

- Al abrir `FMain`, debe cargarse automaticamente la primera opcion disponible.
- En el alcance inicial, la primera opcion esperada es `Dashboard`.
- La zona central no debe quedar vacia tras una apertura correcta de `FMain`.
- Si `Dashboard` no estuviera disponible por una condicion futura, debe cargarse la primera opcion permitida.
- Si no existe ninguna opcion permitida, debe mostrarse un mensaje de acceso no disponible y la pantalla debe permanecer en un estado controlado.

### Navegacion

- Al seleccionar una opcion de la barra lateral, debe cargarse su formulario asociado en la zona central.
- Antes de cargar un nuevo formulario, el formulario central anterior debe descargarse, cerrarse, liberarse u ocultarse de forma controlada.
- El formulario seleccionado debe incrustarse dentro del contenedor central.
- El formulario incrustado debe ocupar el area central disponible.
- La opcion seleccionada debe quedar marcada visualmente como activa.
- Seleccionar la opcion ya activa no debe crear duplicados del formulario central.
- La navegacion no debe cerrar la sesion ni reiniciar servicios globales de la aplicacion.

### Formularios iniciales

- `Dashboard` sera la vista inicial y punto de entrada tras login.
- `TSK` usa `TFrmCrud` y `TTaskCrudProvider` para gestionar tareas.
- `USR` usa `TFrmCrud` y `TUserCrudProvider` como vista protegida de administracion de usuarios.
- El detalle funcional de cada formulario podra definirse en especificaciones separadas.

### Gestion de errores

- Si ocurre un error al cargar una opcion, la aplicacion debe mostrar un mensaje claro.
- Un error de carga no debe dejar la barra lateral sin opcion activa incoherente.
- Un error de carga no debe romper la sesion por si mismo, salvo que el error sea de sesion expirada o acceso denegado.
- Si el usuario intenta acceder a una opcion no permitida, debe mostrarse acceso denegado o impedirse la accion desde la navegacion.
- Tras un error, el usuario debe poder seguir usando opciones permitidas.

### Ayuda y Acerca de

- La opcion `Ayuda` queda excluida explicitamente de la barra lateral izquierda.
- Si se mantiene el formulario `Acerca de`, su acceso debe ubicarse fuera de la barra lateral izquierda.
- El acceso a `Acerca de` podra hacerse desde un menu superior, un boton secundario u otro punto definido por una especificacion separada.

## Flujo de usuario

### Apertura tras login correcto

1. El usuario inicia sesion correctamente.
2. La aplicacion crea una sesion activa.
3. La aplicacion abre `FMain`.
4. `FMain` construye la barra lateral con las opciones permitidas para el usuario.
5. `FMain` selecciona automaticamente `Dashboard`.
6. La zona central muestra el formulario de `Dashboard`.

### Seleccionar una opcion

1. El usuario pulsa una opcion disponible de la barra lateral.
2. La aplicacion comprueba que la sesion sigue activa.
3. La aplicacion verifica que el usuario tiene permiso para esa opcion.
4. La aplicacion descarga u oculta el formulario central anterior.
5. La aplicacion incrusta el formulario asociado a la nueva opcion.
6. La barra lateral marca la nueva opcion como activa.

### Acceso a USR como administrador

1. Un usuario administrador inicia sesion correctamente.
2. `FMain` muestra la opcion `USR`.
3. El administrador selecciona `USR`.
4. La zona central muestra el formulario de administracion de usuarios.

### Acceso a USR como usuario normal

1. Un usuario normal inicia sesion correctamente.
2. `FMain` no permite ejecutar la opcion `USR`.
3. Si la opcion se muestra deshabilitada, no debe poder activarse.
4. Si se intenta acceder por una ruta no visual, el sistema debe denegar el acceso.

### Expiracion de sesion

1. El usuario esta trabajando en `FMain`.
2. La sesion supera el limite de inactividad.
3. La aplicacion detecta que la sesion ha expirado.
4. La aplicacion cierra o bloquea el formulario incrustado activo.
5. La aplicacion vuelve a solicitar login.
6. Ninguna opcion protegida queda accesible hasta un nuevo login correcto.

## Mensajes esperados

Los textos definitivos pueden ajustarse en la implementacion, pero deben respetar esta intencion:

- Sesion requerida: `Debe iniciar sesion para acceder a la aplicacion.`
- Sesion expirada: `La sesion ha expirado por inactividad.`
- Acceso denegado: `No tiene permisos para acceder a esta funcionalidad.`
- Error al cargar opcion: `No se pudo abrir la opcion seleccionada.`
- Sin opciones disponibles: `No hay opciones disponibles para el usuario actual.`

## Criterios de aceptacion

- Dado que no existe sesion activa, cuando se intenta abrir `FMain`, entonces debe bloquearse el acceso y mostrarse el login.
- Dado un usuario autenticado, cuando se abre `FMain`, entonces se muestra la barra lateral izquierda.
- Dado un usuario autenticado, cuando se abre `FMain`, entonces se carga `Dashboard` en la zona central.
- Dado un usuario autenticado, cuando se muestra la barra lateral, entonces aparecen las opciones permitidas `Dashboard` y `TSK`.
- Dado un administrador autenticado, cuando se muestra la barra lateral, entonces aparece la opcion `USR`.
- Dado un usuario normal autenticado, cuando se muestra la barra lateral, entonces la opcion `USR` no puede ejecutarse.
- Dado cualquier usuario autenticado, cuando se muestra la barra lateral izquierda, entonces no aparece la opcion `Ayuda`.
- Dado que `Dashboard` esta activo, cuando el usuario selecciona `TSK`, entonces la zona central muestra el CRUD de tareas.
- Dado que una opcion esta activa, cuando se selecciona otra opcion, entonces solo queda activo el formulario de la nueva opcion.
- Dado que una opcion esta activa, cuando el usuario vuelve a seleccionar la misma opcion, entonces no se crean formularios duplicados.
- Dado que el usuario no tiene permisos para una opcion, cuando intenta acceder a ella, entonces se deniega el acceso.
- Dado que la sesion expira, cuando el usuario intenta navegar o interactuar con `FMain`, entonces la aplicacion vuelve a solicitar login.
- Dado que ocurre un error al cargar una opcion, cuando se informa al usuario, entonces la aplicacion sigue permitiendo navegar a opciones validas.

## Escenarios TDD propuestos

Los primeros tests deben cubrir el nucleo o los servicios de navegacion sin abrir ventanas VCL:

- `Main_requires_active_session`
- `Main_loads_dashboard_by_default`
- `Main_lists_dashboard_tsk_and_usr_options`
- `Main_does_not_show_help_in_sidebar`
- `Main_lists_only_allowed_options_for_user`
- `Main_allows_admin_to_access_users`
- `Main_rejects_normal_user_from_users`
- `Main_changes_active_option_when_sidebar_item_is_selected`
- `Main_does_not_duplicate_active_form_when_same_option_is_selected`
- `Main_denies_navigation_when_session_expires`
- `Main_expires_session_and_returns_to_login`
- `Main_keeps_previous_valid_state_when_option_load_fails`

## Diseno esperado para TDD

La funcionalidad debe poder probarse sin abrir ventanas.

Componentes conceptuales:

- Servicio de sesion.
- Servicio de permisos.
- Servicio o modelo de navegacion principal.
- Definicion de opciones disponibles.
- Resolvedor de formulario o vista asociada a cada opcion.
- Controlador de estado de opcion activa.

La UI solo debe:

- Consultar si existe sesion activa.
- Solicitar las opciones disponibles para el usuario autenticado.
- Mostrar la barra lateral.
- Solicitar el cambio de opcion activa.
- Incrustar el formulario devuelto o indicado por la navegacion.
- Mostrar mensajes de error.
- Volver al login si la sesion expira o se cierra.

## Datos de prueba sugeridos

Usuario administrador:

- Usuario: `admin`
- Rol: administrador
- Opciones permitidas: `Dashboard`, `TSK`, `USR`
- Vista inicial: `Dashboard`

Usuario normal:

- Usuario: `user`
- Rol: usuario normal
- Opciones permitidas: `Dashboard`, `TSK`
- Vista inicial: `Dashboard`

Sesion inexistente:

- Sin usuario autenticado.
- `FMain` no puede abrirse.
- Debe mostrarse login.

Sesion expirada:

- Usuario autenticado previamente.
- Sesion marcada como expirada por inactividad.
- Cualquier navegacion debe bloquearse y volver al login.

## Decisiones confirmadas

- `FMain` sera la pantalla principal tras login correcto.
- `FMain` tendra barra lateral izquierda y zona central de contenido.
- La barra lateral inicial tendra `Dashboard`, `TSK` y `USR`.
- La barra lateral izquierda no incluira `Ayuda`.
- `Dashboard` sera la opcion inicial por defecto.
- `USR` sera una opcion administrativa.
- `FMain` estara protegida por sesion activa y permisos.

## Preguntas pendientes

- Deben ocultarse las opciones no permitidas o mostrarse deshabilitadas?
- Cual sera el contenido funcional exacto de `Dashboard`?
- Que operaciones concretas adicionales necesitara el CRUD `USR`?
- Donde se ubicara finalmente el acceso a `Acerca de`?
- Debe recordarse la ultima opcion activa entre sesiones?
