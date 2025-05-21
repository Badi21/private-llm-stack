#!/bin/bash
# =================================================================
# Private LLM Stack Installer
# Autor: Tu Nombre <tu@email.com>
# Repositorio: https://github.com/tuusuario/private-llm-stack
# Licencia: MIT
# =================================================================

# Configuración estricta para detectar errores
set -euo pipefail
IFS=$'\n\t'

# Variables globales
VERSION="1.0.0"
LOG_FILE="/tmp/private-llm-installer.log"
DEFAULT_PORT=3000
CONFIG_FILE="$HOME/.private-llm-config"

# Colores para mensajes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Función para mostrar mensaje de bienvenida
show_banner() {
  clear
  echo -e "${BLUE}${BOLD}"
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║               🚀 PRIVATE LLM STACK v${VERSION}               ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
  echo -e "${CYAN}Tu asistente de IA privado, seguro y fácil de instalar${NC}"
  echo -e "${CYAN}https://github.com/tuusuario/private-llm-stack${NC}"
  echo ""
}

# Función para mostrar mensajes de log
log() {
  local type=$1
  local message=$2
  local color=$NC
  local prefix=""
  
  case $type in
    "info") color=$BLUE; prefix="ℹ️ INFO:    " ;;
    "success") color=$GREEN; prefix="✅ SUCCESS: " ;;
    "warning") color=$YELLOW; prefix="⚠️ WARNING: " ;;
    "error") color=$RED; prefix="❌ ERROR:   " ;;
    "step") color=$MAGENTA; prefix="🔍 STEP:    " ;;
  esac
  
  echo -e "${color}${prefix}${message}${NC}"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${type^^}] ${message}" >> "$LOG_FILE"
}

# Función para mostrar ayuda
show_help() {
  echo -e "${BOLD}Uso:${NC} $0 [opciones]"
  echo
  echo "Instalador para Private LLM Stack (Ollama + Open WebUI + NGINX + SSL)"
  echo
  echo -e "${BOLD}Opciones:${NC}"
  echo "  --model MODELO      Modelo de IA a instalar (phi, llama2:7b-chat, etc.)"
  echo "  --domain DOMINIO    Dominio para acceso web (ej: ia.tudominio.com)"
  echo "  --username USUARIO  Nombre de usuario para autenticación web"
  echo "  --password PASS     Contraseña para autenticación (si no se especifica, se solicitará)"
  echo "  --port PUERTO       Puerto para Open WebUI (por defecto: 3000)"
  echo "  --no-ssl            Omitir configuración de SSL (no recomendado)"
  echo "  --data-dir DIR      Directorio para datos persistentes (por defecto: ~/private-llm-data)"
  echo "  --no-auto-start     No configurar inicio automático con el sistema"
  echo "  --gpu               Habilitar soporte para GPU (experimental)"
  echo "  --uninstall         Desinstalar Private LLM Stack"
  echo "  --version, -v       Mostrar versión del instalador"
  echo "  --help, -h          Mostrar este mensaje de ayuda"
  echo
  echo -e "${BOLD}Ejemplos:${NC}"
  echo "  $0 --model mistral:7b-instruct --domain ia.tudominio.com --username admin"
  echo "  $0 --no-ssl --port 8080"
  echo "  $0 --uninstall"
  exit 0
}

# Función para mostrar versión
show_version() {
  echo "Private LLM Stack Installer v${VERSION}"
  exit 0
}

# Función para verificar requisitos del sistema
check_system_requirements() {
  log "step" "Verificando requisitos del sistema..."
  
  # Comprobar si es root
  if [ "$EUID" -eq 0 ]; then
    log "warning" "Estás ejecutando el script como root. Se recomienda ejecutarlo como usuario normal con permisos sudo."
    read -rp "¿Continuar de todos modos? (s/N): " continue_as_root
    if [[ ! "$continue_as_root" =~ ^[Ss]$ ]]; then
      log "error" "Instalación cancelada. Ejecuta el script sin privilegios de root."
      exit 1
    fi
  fi
  
  # Comprobar distribución
  if ! command -v apt &> /dev/null; then
    log "error" "Este script está diseñado para sistemas basados en Debian/Ubuntu."
    log "error" "Para otras distribuciones, consulta la guía manual en el repositorio."
    exit 1
  fi
  
  # Comprobar memoria RAM
  local ram_kb
  ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  local ram_gb=$(( ram_kb / 1024 / 1024 ))
  log "info" "Memoria RAM detectada: ${ram_gb} GB"
  
  if [ "$ram_gb" -lt 2 ]; then
    log "warning" "Se detectaron menos de 2GB de RAM."
    log "warning" "Se puede continuar, pero solo con modelos muy ligeros como tinyllama."
    read -rp "¿Deseas continuar de todos modos? (s/N): " continue_low_ram
    if [[ ! "$continue_low_ram" =~ ^[Ss]$ ]]; then
      log "error" "Instalación cancelada por requisitos de RAM insuficientes."
      exit 1
    fi
  fi
  
  # Comprobar espacio en disco
  local disk_space
  disk_space=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')
  log "info" "Espacio libre en disco: ${disk_space}GB"
  
  if [ "$disk_space" -lt 10 ]; then
    log "warning" "Se recomienda al menos 10GB de espacio libre en disco."
    read -rp "¿Deseas continuar de todos modos? (s/N): " continue_low_space
    if [[ ! "$continue_low_space" =~ ^[Ss]$ ]]; then
      log "error" "Instalación cancelada por espacio en disco insuficiente."
      exit 1
    fi
  fi
  
  # Comprobar si Docker está instalado
  if ! command -v docker &> /dev/null; then
    log "info" "Docker no está instalado. Se instalará durante el proceso."
  else
    docker_version=$(docker --version | awk '{print $3}' | tr -d ',')
    log "info" "Docker ya instalado (versión $docker_version)"
  fi
}

# Función para instalar dependencias
install_dependencies() {
  log "step" "Instalando dependencias necesarias..."
  
  # Actualizar índices de paquetes
  log "info" "Actualizando índices de paquetes..."
  sudo apt update -y >> "$LOG_FILE" 2>&1 || {
    log "error" "Error al actualizar repositorios. Verifica tu conexión a internet."
    exit 1
  }
  
  # Instalar dependencias básicas
  log "info" "Instalando paquetes esenciales..."
  sudo apt install -y curl git nginx apache2-utils certbot python3-certbot-nginx >> "$LOG_FILE" 2>&1 || {
    log "error" "Error al instalar dependencias básicas."
    exit 1
  }
  
  # Instalar Docker si no está disponible
  if ! command -v docker &> /dev/null; then
    log "info" "Instalando Docker..."
    
    # Método 1: Instalación oficial recomendada
    curl -fsSL https://get.docker.com -o get-docker.sh >> "$LOG_FILE" 2>&1
    sudo sh get-docker.sh >> "$LOG_FILE" 2>&1
    
    # Comprobar si la instalación fue exitosa
    if ! command -v docker &> /dev/null; then
      log "warning" "Instalación oficial de Docker falló, intentando método alternativo..."
      
      # Método 2: Instalación desde repositorios
      sudo apt install -y docker.io docker-compose >> "$LOG_FILE" 2>&1 || {
        log "error" "No se pudo instalar Docker. Consulta el log para más detalles."
        exit 1
      }
    fi
    
    # Configurar permisos para el usuario actual
    sudo usermod -aG docker "$USER" >> "$LOG_FILE" 2>&1
    log "warning" "El usuario ha sido añadido al grupo 'docker'. Es posible que necesites cerrar sesión y volver a iniciarla para aplicar los cambios."
  fi
  
  # Iniciar y habilitar Docker
  log "info" "Habilitando Docker para iniciar con el sistema..."
  sudo systemctl enable docker >> "$LOG_FILE" 2>&1
  sudo systemctl start docker >> "$LOG_FILE" 2>&1 || {
    log "error" "Error al iniciar el servicio Docker."
    exit 1
  }
  
  log "success" "Todas las dependencias instaladas correctamente."
}

# Función para instalar Ollama
install_ollama() {
  log "step" "Instalando Ollama AI runtime..."
  
  if command -v ollama &> /dev/null; then
    local ollama_version
    ollama_version=$(ollama --version 2>&1 | head -n 1)
    log "info" "Ollama ya está instalado (versión: $ollama_version)"
    read -rp "¿Deseas reinstalar/actualizar Ollama? (s/N): " reinstall_ollama
    if [[ ! "$reinstall_ollama" =~ ^[Ss]$ ]]; then
      return 0
    fi
  fi
  
  log "info" "Descargando e instalando Ollama..."
  curl -fsSL https://ollama.com/install.sh | sh >> "$LOG_FILE" 2>&1 || {
    log "error" "Error al instalar Ollama."
    exit 1
  }
  
  # Verificar instalación
  if ! command -v ollama &> /dev/null; then
    log "error" "La instalación de Ollama falló. Verifica el log para más detalles."
    exit 1
  fi
  
  log "success" "Ollama instalado correctamente."
}

# Función para seleccionar y descargar modelo
download_ai_model() {
  log "step" "Configurando modelo de IA..."
  
  if [ -n "${MODEL:-}" ]; then
    log "info" "Modelo seleccionado mediante parámetro: $MODEL"
  else
    # Detectar RAM para recomendaciones
    local ram_kb
    ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local ram_gb=$(( ram_kb / 1024 / 1024 ))
    
    echo -e "\n${CYAN}${BOLD}🤖 Selección de modelo de IA${NC}"
    echo "Modelos recomendados según tu RAM disponible (${ram_gb}GB):"
    
    echo -e "${YELLOW}Modelos ligeros (2-4GB RAM):${NC}"
    echo "1) phi - Microsoft Phi (básico)"
    echo "2) gemma:2b - Google Gemma 2B (equilibrado)"
    echo "3) tinyllama - Tiny LLaMA (muy ligero)"
    
    if [ "$ram_gb" -ge 8 ]; then
      echo -e "\n${YELLOW}Modelos medios (8GB RAM):${NC}"
      echo "4) llama2:7b-chat - Meta LLaMA 2 7B Chat"
      echo "5) mistral:7b-instruct - Mistral AI 7B Instruct"
    fi
    
    if [ "$ram_gb" -ge 12 ]; then
      echo -e "\n${YELLOW}Modelos avanzados (12-16GB RAM):${NC}"
      echo "6) neural-chat - Qualcomm Neural Chat"
      echo "7) llama2:13b-chat - Meta LLaMA 2 13B Chat (muy potente)"
    fi
    
    echo -e "\n8) Otro modelo (especificar manualmente)"
    
    read -rp "Selecciona el número del modelo (1-8): " model_option
    
    case $model_option in
      1) MODEL="phi" ; MIN_RAM=2 ;;
      2) MODEL="gemma:2b" ; MIN_RAM=4 ;;
      3) MODEL="tinyllama" ; MIN_RAM=2 ;;
      4) MODEL="llama2:7b-chat" ; MIN_RAM=8 ;;
      5) MODEL="mistral:7b-instruct" ; MIN_RAM=8 ;;
      6) MODEL="neural-chat" ; MIN_RAM=12 ;;
      7) MODEL="llama2:13b-chat" ; MIN_RAM=16 ;;
      8) 
        read -rp "Introduce el nombre del modelo Ollama (ej: mixtral:8x7b): " MODEL
        read -rp "RAM mínima recomendada para este modelo (GB): " MIN_RAM
        ;;
      *) 
        log "error" "Opción inválida seleccionada."
        download_ai_model
        return
        ;;
    esac
  fi
  
  # Validar RAM para el modelo elegido
  local ram_kb
  ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  local ram_gb=$(( ram_kb / 1024 / 1024 ))
  
  if [ "$ram_gb" -lt "$MIN_RAM" ]; then
    log "warning" "⚠️ La RAM disponible (${ram_gb}GB) es menor que la recomendada para $MODEL (${MIN_RAM}GB)."
    log "warning" "El modelo podría funcionar lento o no funcionar correctamente."
    read -rp "¿Deseas continuar de todos modos? (s/N): " continue_ram
    if [[ ! "$continue_ram" =~ ^[Ss]$ ]]; then
      download_ai_model
      return
    fi
  fi
  
  log "info" "Descargando modelo $MODEL en Ollama..."
  ollama pull "$MODEL" >> "$LOG_FILE" 2>&1 || {
    log "error" "Error al descargar el modelo $MODEL."
    log "error" "Verifica que el nombre del modelo sea correcto y tu conexión a internet."
    exit 1
  }
  
  log "success" "Modelo $MODEL descargado correctamente."
}

# Función para instalar Open WebUI
install_open_webui() {
  log "step" "Instalando Open WebUI..."
  
  local webui_dir="${DATA_DIR:-$HOME/private-llm-data}/open-webui"
  mkdir -p "$webui_dir"
  
  # Clonar repositorio si no existe
  if [ ! -d "$webui_dir/open-webui" ]; then
    log "info" "Clonando repositorio Open WebUI..."
    git clone https://github.com/open-webui/open-webui.git "$webui_dir/open-webui" >> "$LOG_FILE" 2>&1 || {
      log "error" "Error al clonar repositorio de Open WebUI."
      exit 1
    }
  else
    log "info" "Actualizando repositorio Open WebUI..."
    (cd "$webui_dir/open-webui" && git pull) >> "$LOG_FILE" 2>&1
  fi
  
  # Crear archivo .env
  log "info" "Configurando conexión con Ollama..."
  echo "OLLAMA_BASE_URL=http://localhost:11434" > "$webui_dir/open-webui/.env"
  
  # Crear o actualizar docker-compose
  log "info" "Configurando Docker Compose para Open WebUI..."
  (cd "$webui_dir/open-webui" && docker compose up -d) >> "$LOG_FILE" 2>&1 || {
    log "error" "Error al iniciar Open WebUI con Docker Compose."
    exit 1
  }
  
  # Verificar que el contenedor está en ejecución
  sleep 5
  if ! docker ps | grep -q open-webui; then
    log "error" "Los contenedores de Open WebUI no están en ejecución."
    log "error" "Verifica los logs de Docker para más detalles: docker logs open-webui-open-webui-1"
    exit 1
  fi
  
  # Esperar a que el servicio esté disponible
  log "info" "Esperando a que Open WebUI esté disponible..."
  local max_attempts=10
  local attempt=1
  local webui_ready=false
  
  while [ $attempt -le $max_attempts ]; do
    if curl -s "http://localhost:${PORT:-3000}" -o /dev/null; then
      webui_ready=true
      break
    fi
    log "info" "Intento $attempt/$max_attempts: Open WebUI aún no está listo..."
    sleep 5
    attempt=$((attempt + 1))
  done
  
  if [ "$webui_ready" = true ]; then
    log "success" "Open WebUI instalado y funcionando correctamente en el puerto ${PORT:-3000}."
  else
    log "warning" "Open WebUI parece estar iniciando, pero no responde aún."
    log "warning" "Puedes verificar el estado con: docker ps"
  fi
}

# Función para configurar NGINX
configure_nginx() {
  log "step" "Configurando NGINX como proxy inverso..."
  
  if [ -z "${DOMAIN:-}" ]; then
    read -rp "🌐 Introduce el dominio para acceso web (ej: ia.tudominio.com): " DOMAIN
  fi
  
  if [ -z "${USERNAME:-}" ]; then
    read -rp "🔐 Usuario para acceso web: " USERNAME
  fi
  
  if [ -z "${PASSWORD:-}" ]; then
    read -rsp "🔑 Contraseña para acceso web (no se mostrará): " PASSWORD
    echo ""
  fi
  
  # Comprobar que el dominio es válido
  if ! echo "$DOMAIN" | grep -qE '^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$'; then
    log "error" "El dominio introducido no parece válido."
    log "error" "Debe tener formato: ejemplo.com o subdominio.ejemplo.com"
    exit 1
  fi
  
  # Crear configuración NGINX
  NGINX_CONF="/