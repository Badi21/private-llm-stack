# Política de Seguridad

## Versiones Soportadas

| Versión | Soporte          |
| ------- | ---------------- |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reportando una Vulnerabilidad

La seguridad de Private LLM Stack es extremadamente importante ya que el proyecto maneja modelos de IA privados y potencialmente sensibles.

### Cómo Reportar

Si descubres una vulnerabilidad de seguridad, por favor:

1. **No reveles públicamente la vulnerabilidad** - No crees un issue público en GitHub
2. Envía un email a [tu-email@ejemplo.com] con detalles sobre la vulnerabilidad
3. Incluye los siguientes detalles:
   - Tipo de problema (ej. inyección, autenticación, DoS, etc.)
   - Ruta completa de los archivos relacionados con la vulnerabilidad
   - Ubicación del código fuente relacionado
   - Cualquier configuración especial requerida para reproducir el problema
   - Pasos detallados para reproducir el problema
   - Prueba de concepto o código de explotación (si es posible)
   - Impacto de la vulnerabilidad

### Qué Esperar

Después de reportar una vulnerabilidad:

1. **Confirmación**: Recibirás un acuse de recibo dentro de 48 horas
2. **Verificación**: Evaluaremos la vulnerabilidad y determinaremos su impacto
3. **Corrección**: Desarrollaremos y probaremos una solución
4. **Divulgación**: Una vez corregida, coordinaremos la divulgación pública (si es aplicable)

## Mejores Prácticas de Seguridad para Usuarios

Para maximizar la seguridad de tu instalación:

1. **Mantén todo actualizado**: Actualiza regularmente tu sistema operativo, Docker, Nginx y todos los componentes
2. **Limita el acceso**: Configura tu firewall para permitir sólo los puertos necesarios (80, 443)
3. **Utiliza VPN o IP fijas**: Considera limitar el acceso a direcciones IP específicas o a través de una VPN
4. **Monitoreo**: Implementa monitoreo de logs para detectar intentos de acceso no autorizados
5. **Backups**: Realiza copias de seguridad regulares de tu configuración y datos
6. **Cambio regular de credenciales**: Cambia periódicamente las contraseñas de acceso

## Política de Divulgación

Seguimos un proceso de divulgación responsable:

1. La seguridad de nuestros usuarios es nuestra prioridad
2. Las vulnerabilidades serán corregidas lo antes posible
3. Publicaremos advisories de seguridad después de que se hayan lanzado los parches
4. Acreditaremos a los investigadores que reporten vulnerabilidades (con su permiso)