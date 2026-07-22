# Niveles de test del proyecto

Este proyecto usa cuatro niveles de verificacion. La nomenclatura consensuada es:

- `unitTest`
- `coverageTest`
- `visualTest`
- `mutationTest`
- `e2eTest`

## unitTest Core

Pruebas de consola del nucleo, sin frameworks externos.

Ubicacion:

```text
tests\App.Core.Tests\
```

Runner:

```text
tests\App.Core.Tests\AppCoreTests.dpr
```

Que cubre:

- Reglas de negocio de `src\App.Core`.
- Validaciones de entrada.
- Casos de error.
- Cambios de estado.
- Login, sesion y permisos.
- Usuarios, tareas, configuracion, repositorios y preferencias.
- Persistencia mediante repositorios fake o ficheros de prueba.

Ejecucion:

```bat
cd tests\App.Core.Tests
dcc32 "-U..\..\src\App.Core" AppCoreTests.dpr
AppCoreTests.exe
```

Uso esperado:

- Obligatorio en cada cambio de nucleo.
- Primer nivel del ciclo TDD rojo, verde, refactor.

## unitTest Forms VCL

Pruebas de consola de formularios VCL instanciados dentro del proceso, con fakes para los servicios del nucleo.

Ubicacion:

```text
tests\App.Win.Tests\
```

Runner:

```text
tests\App.Win.Tests\AppWinTests.dpr
```

Estructura por formulario:

```text
tests\App.Win.Tests\<FormName>Tests.pas
```

Patron:

- El runner llama a `Application.Initialize`.
- El test crea el formulario con `TFrmX.Create(nil)`.
- Las dependencias se inyectan con un metodo acotado para tests, por ejemplo `ConfigureForTests`.
- Los servicios del nucleo se sustituyen por fakes o stubs.
- Los eventos se invocan directamente cuando representan una accion del usuario, por ejemplo `BtnLoginClick(nil)`.
- Los asserts revisan propiedades VCL y estado observable del formulario.

Que cubre:

- Foco inicial (`ActiveControl`).
- Orden de tabulacion (`TabOrder`).
- Configuracion visual con comportamiento, como `PasswordChar`.
- Botones por defecto y cancelacion.
- Mensajes de error (`Caption` visible al usuario).
- Llamadas a servicios inyectados.
- Estado publico del formulario tras una accion, como `ModalResult` o usuario autenticado.

Que no cubre:

- Reglas de negocio.
- Persistencia real.
- Repositorios reales.
- Navegacion completa entre ventanas.
- Capturas visuales o comparacion pixel-perfect.
- Flujos completos de usuario.

Ejecucion:

```bat
cd tests\App.Win.Tests
run-tests.bat
```

Uso esperado:

- Obligatorio para cambios de comportamiento en formularios.
- Preferido frente a E2E cuando el comportamiento puede observarse en el propio form.
- El E2E queda para comprobar integracion real de la aplicacion.

## coverageTest Core

Medicion de cobertura de lineas del nucleo con DelphiCodeCoverage.

Script:

```text
tests\App.Core.Tests\coverage.bat
```

Que hace:

- Compila `AppCoreTests.dpr` con mapa detallado (`-GD`).
- Ejecuta `AppCoreTests.exe` mediante DelphiCodeCoverage.
- Genera informe HTML/XML en `tests\App.Core.Tests\coverage\`.
- Falla si el runner reporta tests fallidos o no se genera el informe.
- Falla si la cobertura global del nucleo baja del 90%.

Ejecucion:

```bat
cd tests\App.Core.Tests
coverage.bat
```

Uso esperado:

- Medicion periodica de salud de la suite.
- Antes de subir umbrales de cobertura.
- Antes de cerrar deuda de cobertura.

Estado documentado:

- Validado desde artefactos limpios el 2026-07-22.
- Umbral minimo Core: 90%.
- Cobertura global Core actual: 93%, 931 de 991 lineas cubiertas.
- `AppCoreUserService.pas`: 98,5% en el HTML por fichero, 196 de 199 lineas con codigo generado cubiertas.

Limitaciones conocidas del informe:

- El resumen global y los informes HTML por fichero son la fuente principal para cobertura de lineas.
- El HTML por fichero conserva numeros de linea y marca cada linea como cubierta, no cubierta o sin codigo generado.
- Los nodos `class` y `method` del XML/HTML pueden mostrar nombres truncados o sufijos de nombres, por ejemplo `oadFromFile`, `teUser` o `ser`.
- Esa limitacion no bloquea el umbral ni la medicion por fichero/linea, pero no debe usarse para tomar decisiones finas por metodo.
- Para analisis por metodo, usar el HTML del fichero junto con el codigo fuente y el nombre de los tests; si hace falta validacion fuerte de una regla, preferir `mutationTest`.

## coverageTest Forms VCL

Medicion de cobertura de lineas de formularios VCL con DelphiCodeCoverage.

Script:

```text
tests\App.Win.Tests\coverage.bat
```

Que hace:

- Compila `AppWinTests.dpr` con mapa detallado (`-GD`).
- Ejecuta `AppWinTests.exe` mediante DelphiCodeCoverage.
- Genera informe HTML/XML en `tests\App.Win.Tests\coverage\`.
- Falla si el runner reporta tests fallidos o no se genera el informe.

Ejecucion:

```bat
cd tests\App.Win.Tests
coverage.bat
```

Uso esperado:

- Medicion periodica de los unit tests de forms.
- Antes de cerrar tareas de testabilidad de `src\App.Win`.
- Al agregar tests para nuevos formularios, ampliar la lista `-u` del script con la unidad correspondiente.

Estado documentado:

- Validado desde artefactos limpios el 2026-07-22.
- Cobertura global App.Win actual: 92%, 63 de 68 lineas cubiertas.
- `LoginForm.pas`: 92%, 35 de 38 lineas ejecutables cubiertas.

## localizationAudit Forms VCL

Auditoria estricta del CSV de localizacion contra formularios VCL declarados como localizados.

Ubicacion:

```text
tests\App.Win.Tests\LocalizationAuditTests.pas
```

Runner:

```text
tests\App.Win.Tests\run-tests.bat
```

Que valida:

- El fichero `src\App.Win\languages.csv` existe.
- El CSV contiene las columnas obligatorias `key`, idioma por defecto `es` e idioma activo `en`.
- Las claves del CSV para el formulario apuntan a componentes existentes.
- Las claves del CSV apuntan a propiedades publicadas existentes.
- Los captions traducibles del formulario localizado tienen clave en el CSV.
- La aplicacion productiva puede seguir aplicando localizacion en modo tolerante; la auditoria de tests usa modo estricto.

Estado actual:

- `FrmLogin`, `FrmMain`, `FrmTasks`, `FrmUsers` y `FrmAbout` auditados contra `languages.csv`.
- `FrmAbout` combina datos de version, sistema y base de datos con prefijos leidos desde claves `About.*` del fichero de idioma; se cubre con `AboutFormTests`.
- Al localizar nuevos formularios, agregar su instancia a la auditoria y ampliar el CSV.

## mutationTest

Pruebas de mutacion para comprobar que los tests detectan cambios artificiales en reglas criticas.

Runner:

```text
tests\App.Core.Tests\mutation.bat
```

Mutaciones:

```text
tests\App.Core.Tests\mutations\
```

Que hace:

- Exige arbol Git limpio por defecto.
- Ejecuta una linea base de `unitTest`.
- Aplica cada patch de mutacion con `git apply`.
- Fuerza recompilacion con `dcc32 -B`.
- Ejecuta `AppCoreTests.exe`.
- Marca `Killed` si la compilacion o los tests fallan.
- Marca `Survived` si los tests pasan con la mutacion aplicada.
- Revierte cada patch con `git apply -R`.
- Genera `mutation-report.txt` y logs locales `mutation-*.log`.

Ejecucion:

```bat
cd tests\App.Core.Tests
mutation.bat
```

Uso esperado:

- Validacion fuerte de reglas criticas.
- Convertir mutantes supervivientes en nuevos tests TDD.
- Ampliar con nuevos patches cuando se identifiquen reglas sensibles.

Estado actual:

- 17 mutantes automatizados (`M001` a `M017`).
- 17 mutantes muertos.
- 0 mutantes supervivientes.
- 0 supervivientes conocidos.

## visualTest Forms VCL

Pruebas visuales de formularios VCL comparando capturas contra baselines aprobados.

Ubicacion:

```text
tests\App.Win.Visual\
```

Runner:

```text
tests\App.Win.Visual\run-visual-tests.bat
```

Modos:

- `approve`: genera o reemplaza el baseline versionado.
- `verify`: compara contra el baseline existente y falla si no existe.

Rutas:

```text
tests\App.Win.Visual\baselines\  baseline versionado
tests\App.Win.Visual\actual\     captura actual ignorada por Git
tests\App.Win.Visual\diff\       diferencia ignorada por Git
```

Ejecucion:

```bat
cd tests\App.Win.Visual
run-visual-tests.bat verify
```

Para aprobar una captura:

```bat
cd tests\App.Win.Visual
run-visual-tests.bat approve
```

Uso esperado:

- Detectar cambios accidentales de layout en `.dfm`.
- Revisar formularios en estado inicial o estados visuales importantes.
- No reemplaza unit tests de comportamiento ni E2E de integracion.
- En modo `verify`, nunca genera un baseline automaticamente.

## e2eTest

Pruebas end-to-end de la aplicacion VCL desde fuera del proceso, usando AutoIt.

Ubicacion:

```text
tests\App.Win.E2E\
```

Runner actual:

```text
tests\App.Win.E2E\run-smoke-login.bat
```

Que cubre ahora:

- Compila `src\App.Win\WindowsApp.dpr`.
- Prepara un runtime aislado.
- Abre la aplicacion VCL.
- Hace login con `admin` / `admin`.
- Verifica que aparece la ventana principal.
- Abre `Tareas`.
- Crea una tarea.
- Verifica el prefijo pendiente `[ ]`.
- Completa la tarea.
- Verifica el prefijo completado `[x]`.
- Emite diagnosticos con ventanas, clases y controles cuando falla.
- Guarda captura de pantalla del fallo en `tests\App.Win.E2E\runtime\diagnostics\failure.png`.

Ejecucion:

```bat
cd tests\App.Win.E2E
run-smoke-login.bat
```

Uso esperado:

- Smoke de integracion UI Windows.
- Validar que la app arranca, el login funciona y la pantalla `Tareas` esta conectada al nucleo.
- Detectar roturas de wiring entre UI, servicios y persistencia de tareas.

## Politica recomendada

- Para cambios de `src\App.Core`: ejecutar `unitTest Core`.
- Para cambios en reglas criticas: ejecutar `unitTest` y `mutationTest`.
- Para cambios que afecten a cobertura o deuda tecnica: ejecutar `coverageTest`.
- Para cambios de comportamiento en `src\App.Win`: ejecutar `unitTest Forms VCL`.
- Para cambios de layout en `src\App.Win`: ejecutar `visualTest Forms VCL`.
- Para cambios de wiring UI-nucleo, login real o arranque: ejecutar `unitTest Forms VCL` y `e2eTest`.
- Antes de entregar una funcionalidad completa de riesgo medio/alto: ejecutar todos los niveles aplicables.
