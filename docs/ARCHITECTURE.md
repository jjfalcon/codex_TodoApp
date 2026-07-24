# Arquitectura minima

## Objetivo

Mantener una aplicacion Delphi 7/VCL sencilla, testeable y facil de cambiar sin crear una arquitectura pesada.

## Capas

```text
src\App.Core
  Entidades, servicios, interfaces, repositorios y utilidades puras.

src\App.Win
  Formularios VCL, adaptadores visuales, localizacion de controles y wiring.

tests
  Pruebas Core, pruebas de formularios, visual tests, E2E y mutation testing.
```

## Reglas

- Las reglas de negocio viven en `App.Core`.
- Los formularios VCL llaman a servicios o providers; no validan reglas de dominio.
- El Core no depende de VCL, formularios, datasets ni controles.
- `TFrmCrud` es la pantalla reutilizable para entidades tabulares.
- `ICrudProvider` adapta servicios Core al CRUD generico.
- Los helpers puros que no necesitan controles deben vivir fuera del form que los usa.
- No se agrega una abstraccion si solo mueve codigo sin reducir complejidad real.

## Opciones principales

- `Dashboard`: pantalla inicial simple.
- `TSK`: tareas mediante `TFrmCrud` y `TTaskCrudProvider`.
- `USR`: usuarios mediante `TFrmCrud` y `TUserCrudProvider`, solo para administradores.
- `Preferences`: preferencias locales.

Las preferencias de pantalla inicial validas son solo `Dashboard`, `TSK` y `USR`.

## Verificacion

Antes de cerrar cambios:

```bat
cd tests\App.Core.Tests
AppCoreTests.exe

cd ..\App.Win.Tests
run-tests.bat
```

Para cambios de integracion UI/Core:

```bat
cd tests\App.Win.E2E
run-smoke-login.bat
```

Para reglas criticas:

```bat
cd tests\App.Core.Tests
mutation.bat
```
