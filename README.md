# 🚀 Private LLM Stack

<div align="center">

![GitHub stars](https://img.shields.io/github/stars/badi21/private-llm-stack?style=social)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Docker Pulls](https://img.shields.io/badge/docker%20pulls-compatible-blue)
[![Twitter Follow](https://img.shields.io/twitter/follow/badrmind?style=social)](https://twitter.com/badrmind)

**Despliega tu propia plataforma de IA conversacional segura y privada en minutos**

[English](./README_EN.md) | [Español](./README.md)
</div>

## 📋 Contenido

- [🔍 Visión general](#-visión-general)
- [✨ Características](#-características)
- [🖥️ Requisitos del sistema](#️-requisitos-del-sistema)
- [📦 Instalación rápida](#-instalación-rápida)
- [🛠️ Configuración avanzada](#️-configuración-avanzada)
- [🤖 Modelos compatibles](#-modelos-compatibles)
- [🔐 Seguridad](#-seguridad)
- [🔄 Actualización](#-actualización)
- [❓ Preguntas frecuentes](#-preguntas-frecuentes)
- [👥 Contribución](#-contribución)
- [📜 Licencia](#-licencia)

## 🔍 Visión general

**Private LLM Stack** te permite desplegar tu propio **ChatGPT autónomo, privado y seguro** en cualquier servidor VPS, utilizando modelos de lenguaje avanzados como LLaMA, Mistral y otros. Todo con una interfaz web moderna similar a ChatGPT, protegida con HTTPS y autenticación.

> **¿Por qué usar Private LLM Stack?** Mantén tus datos sensibles bajo tu control, evita dependencias externas, y opera completamente sin conexión a internet tras la instalación inicial.

## ✨ Características

- **🧠 IA localmente instalada**: Ollama AI runtime con soporte para múltiples modelos de lenguaje
- **🎭 Múltiples modelos según tu hardware**: Desde opciones ligeras (2GB RAM) hasta modelos avanzados (16GB+)
- **🖌️ Interfaz moderna web**: Open WebUI con diseño similar a ChatGPT, compatible con móvil
- **🔒 Seguridad integrada**: NGINX como proxy inverso, HTTPS con SSL automático y autenticación básica
- **🚀 Instalación en un paso**: Script automatizado que configura todo el stack
- **📱 Acceso multiplataforma**: Accede desde cualquier dispositivo a través de tu dominio seguro
- **🔄 API compatible**: Expone endpoints compatibles con la API de OpenAI para integraciones
- **💾 Sin datos en la nube**: Toda la información se procesa y almacena localmente
- **🛠️ Fácil mantenimiento**: Comandos sencillos para actualizar y gestionar el sistema

## 🖥️ Requisitos del sistema

| Recurso | Requisito mínimo | Recomendado |
|---------|-----------------|-------------|
| CPU | 2 vCPU | 4+ vCPU (AVX2 soportado) |
| RAM | 2GB (modelos ligeros) | 8-16GB (modelos avanzados) |
| Almacenamiento | 10GB libre | 20GB+ SSD |
| SO | Ubuntu 20.04/22.04 | Ubuntu 22.04+ o Debian 11+ |
| Red | Puerto 80, 443 abiertos | Velocidad de subida estable |
| Dominio | Requerido para SSL | Con DNS configurado hacia tu servidor |

## 📦 Instalación rápida

```bash
# 1. Descarga el script de instalación
curl -sSL https://raw.githubusercontent.com/badi21/private-llm-stack/main/install.sh -o install.sh

# 2. Haz el script ejecutable
chmod +x install.sh

# 3. Ejecuta el instalador
./install.sh
```

El script te guiará a través de un proceso interactivo para elegir tu modelo, configurar tu dominio y establecer credenciales de acceso.

## 🛠️ Configuración avanzada

Para personalizar la instalación, puedes ejecutar el script con opciones:

```bash
./install.sh --model mistral:7b-instruct --domain ia.tudominio.com --username admin
```

Parámetros disponibles:
- `--model`: Selecciona el modelo de IA (ver [modelos compatibles](#-modelos-compatibles))
- `--domain`: Especifica el dominio para acceso web
- `--username`: Define el nombre de usuario para la autenticación
- `--port`: Cambia el puerto predeterminado (por defecto: 3000)
- `--no-ssl`: Omite la configuración de SSL (no recomendado)
- `--help`: Muestra todas las opciones disponibles

## 🤖 Modelos compatibles

Private LLM Stack es compatible con todos los modelos de Ollama. Recomendamos:

| Modelo | RAM mínima | Caso de uso |
|--------|------------|------------|
| phi | 2GB | Chatbot básico, dispositivos de recursos limitados |
| gemma:2b | 4GB | Asistente general, buena relación rendimiento/recursos |
| tinyllama | 2GB | Asistente ligero para VPS económicos |
| llama2:7b-chat | 8GB | Conversación avanzada, mejor comprensión |
| mistral:7b-instruct | 8GB | Excelente rendimiento general, instrucciones complejas |
| neural-chat | 12-16GB | Experiencia conversacional premium, alta precisión |

> 💡 **Consejo**: Puedes instalar múltiples modelos y cambiar entre ellos según tus necesidades.

## 🔐 Seguridad

- **HTTPS automático**: Certificados Let's Encrypt autogestionados
- **Autenticación**: Protección con usuario/contraseña
- **Aislamiento**: Docker para contenerización segura
- **Comunicación local**: Los datos nunca salen de tu servidor

### Mejores prácticas de seguridad

- Cambia regularmente la contraseña de autenticación
- Actualiza el sistema y componentes regularmente
- Utiliza un firewall para limitar el acceso al servidor
- Considera configurar una VPN para acceso remoto más seguro


## 🔄 Actualización

Para actualizar el sistema a la última versión:

```bash
cd private-llm-stack
git pull
./update.sh
```

## ❓ Preguntas frecuentes

<details>
<summary><b>¿Es posible usar este sistema sin conexión a internet?</b></summary>
Sí, una vez instalado y descargados los modelos, el sistema puede funcionar completamente sin conexión.
</details>

<details>
<summary><b>¿Cómo puedo añadir más usuarios?</b></summary>
Puedes añadir más usuarios editando el archivo de autenticación de NGINX:

```bash
sudo htpasswd /etc/nginx/.htpasswd nuevo_usuario
```
</details>

<details>
<summary><b>¿Funciona en una Raspberry Pi?</b></summary>
Sí, con modelos ligeros (phi, tinyllama) puede funcionar en Raspberry Pi 4 con 4GB+ RAM.
</details>

<details>
<summary><b>¿Puedo usar esto para fines comerciales?</b></summary>
Sí, pero debes verificar las licencias de los modelos específicos que utilices, ya que varían.
</details>

## 👥 Contribución

¡Las contribuciones son bienvenidas! Si quieres mejorar Private LLM Stack:

1. Haz fork del repositorio
2. Crea una rama para tu funcionalidad (`git checkout -b feature/amazing-feature`)
3. Haz commit de tus cambios (`git commit -m 'Add: amazing feature'`)
4. Push a la rama (`git push origin feature/amazing-feature`)
5. Abre un Pull Request

También puedes [reportar problemas](https://github.com/badi21/private-llm-stack/issues) o [sugerir mejoras](https://github.com/badi21/private-llm-stack/discussions).

## 📜 Licencia

Este proyecto está bajo la licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

---

<div align="center">
<p>¿Te gusta este proyecto? ¡Dale una estrella! ⭐</p>
<p>Creado con 💻 por <a href="https://github.com/badi21">Badar - بدر دين | Software Engineer & Inspiration</a></p>
</div>