# Guía de Contribución

¡Gracias por tu interés en contribuir a Private LLM Stack! Este documento proporciona directrices para contribuir al proyecto.

## Código de Conducta

Este proyecto y todos los participantes están sujetos a nuestro [Código de Conducta](CODE_OF_CONDUCT.md). Al participar, se espera que cumplas con estas normas.

## ¿Cómo puedo contribuir?

### Reportando Bugs

Los bugs son rastreados como [issues de GitHub](https://github.com/badi21/private-llm-stack/issues).

**Antes de crear un nuevo issue:**
- Verifica si el problema ya ha sido reportado
- Si existe un issue abierto, añade comentarios adicionales en lugar de crear uno nuevo

**Al crear un nuevo issue:**
- Usa un título claro y descriptivo
- Describe los pasos exactos para reproducir el problema
- Incluye detalles sobre tu entorno (SO, versiones, etc.)
- Incluye capturas de pantalla si es posible

### Sugiriendo Mejoras

Las mejoras también son rastreadas como issues de GitHub.

**Al sugerir una mejora:**
- Usa un título claro y descriptivo
- Proporciona una descripción detallada de la mejora
- Explica por qué esta mejora sería útil
- Incluye mockups o ejemplos si es posible

### Enviando Pull Requests

1. Haz fork del repositorio
2. Crea una nueva rama desde `main`:
   ```bash
   git checkout -b feature/mi-nueva-funcionalidad
   ```
3. Realiza tus cambios
4. Asegúrate de que el código sigue nuestras pautas de estilo
5. Envía un Pull Request:
   - Describe los cambios en detalle
   - Referencia cualquier issue relacionado

## Estándares de Codificación

### Estilo de Código

- Sigue las mejores prácticas de shellscript
- Comenta tu código donde sea necesario
- Usa nombres de variables descriptivos
- Indenta con 2 espacios

### Mensajes de Commit

- Usa el presente ("Add feature" no "Added feature")
- Primera línea limitada a 72 caracteres
- Describe qué y por qué, no cómo
- Formato recomendado:
  ```
  [tipo]: Breve descripción del cambio

  Explicación más detallada si es necesario. Wrap a 72 caracteres.
  Explicar el problema que este commit está resolviendo.
  ```
  Donde `[tipo]` puede ser:
  - `feat`: Nueva característica
  - `fix`: Corrección de error
  - `docs`: Cambios en documentación
  - `style`: Cambios que no afectan el código (formato, espacios, etc)
  - `refactor`: Refactorización de código
  - `test`: Añadir tests o corregir tests existentes
  - `chore`: Cambios en el proceso de build o herramientas auxiliares

## Proceso de Review

Los mantenedores revisarán tu Pull Request tan pronto como sea posible. Podemos solicitar cambios antes de fusionar.

¡Gracias por contribuir a Private LLM Stack!