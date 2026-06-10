# Reglas del proyecto

## Stack
- Delphi 7, VCL Windows, test runner propio (sin paquetes externos)
- `src/App.Core` → reglas de negocio, interfaces, servicios
- `src/App.Win` → capa VCL fina, sin reglas de negocio
- `tests/App.Core.Tests` → pruebas de consola del núcleo

## TDD obligatorio
1. Escribir la prueba primero en `tests/App.Core.Tests`
2. Ejecutar y verla fallar (rojo)
3. Implementar lo mínimo en `src/App.Core` para que pase (verde)
4. Refactorizar sin cambiar comportamiento
5. Solo entonces conectar desde `src/App.Win`

## Qué probar
- Validaciones de entrada, casos de error, cambios de estado
- Búsquedas y filtros, reglas de permiso, persistencia con repositorios fake

## Qué NO va en la UI
- La ventana llama a servicios del núcleo, no contiene lógica de negocio
- No generar eventos VCL con reglas de validación o negocio
