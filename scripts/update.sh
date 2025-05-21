#!/bin/bash
# =================================================================
# Private LLM Stack Updater
# Author: Your Name <your@email.com>
# Repository: https://github.com/yourusername/private-llm-stack
# License: MIT
# =================================================================

# Configuración para detectar errores (menos estricta para CI)
set -eo pipefail

# Variables globales
VERSION="1.0.0"
LOG_FILE="${LOG_FILE:-/tmp/private-llm-updater.log}"
CONFIG_FILE="${CONFIG_FILE:-$HOME/.private-llm-config}"
CI_MODE="${CI:-false}"
INTERACTIVE="${INTERACTIVE:-true}"

# Colores para mensajes (deshabilitados en CI)
if [[ "$CI_MODE" == "true" ]] || [[ ! -t 1 ]]; then
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  MAGENTA=''
  CYAN=''
  BOLD=''
  NC=''
else
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  MAGENTA='\033[0;35m'
  CYAN='\033[0;36m'
  BOLD='\033[1m'
  NC='\033[0m'
fi

# Función para mostrar mensaje de bienvenida
show_banner() {
  if [[ "$CI_MODE" != "true" ]]; then
    clear
  fi
  echo -e "${BLUE}${BOLD}"
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║               🔄 PRIVATE LLM STACK UPDATER               ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
  echo -e "${CYAN}Actualizando tu asistente de IA privado y seguro${NC}"
  echo ""
}

# Función para mostrar mensajes de log
log() {
  local type="${1:-info}"
  local message="${2:-}"
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

# Función para input compatible con CI
safe_read() {
  local prompt="$1"
  local default="${2:-N}"
  local var_name="$3"
  
  if [[ "$CI_MODE" == "true" ]] || [[ "$INTERACTIVE" != "true" ]]; then
    log "info" "$prompt (usando valor por defecto: $default)"
    eval "$var_name=\"$default\""
  else
    read -rp "$prompt" "$var_name"
    # Si está vacío, usar default
    if [[ -z "${!var_name}" ]]; then
      eval "$var_name=\"$default\""
    fi
  fi
}

# Función para detectar el sistema operativo
detect_os() {
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS=$ID
    OS_VERSION=$VERSION_ID
  elif command -v lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
    OS_VERSION=$(lsb_release -sr)
  elif [[ -f /etc/redhat-release ]]; then
    OS="rhel"
    OS_VERSION=$(grep -oE '[0-9]+\.[0-9]+' /etc/redhat-release | head -1)
  else
    OS="unknown"
    OS_VERSION="unknown"
  fi
  
  log "info" "Sistema operativo detectado: $OS $OS_VERSION"
}

# Función para verificar dependencias
check_dependencies() {
  log "step" "Verificando dependencias del sistema..."
  
  local missing_deps=()
  
  # Verificar Docker
  if ! command -v docker &> /dev/null; then
    missing_deps+=("docker")
  fi
  
  # Verificar Docker Compose
  if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    missing_deps+=("docker-compose")
  fi
  
  # Verificar curl
  if ! command -v curl &> /dev/null; then
    missing_deps+=("curl")
  fi
  
  # Verificar git
  if ! command -v git &> /dev/null; then
    missing_deps+=("git")
  fi
  
  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    log "error" "Dependencias faltantes: ${missing_deps[*]}"
    log "error" "Por favor, instala las dependencias faltantes antes de continuar."
    return 1
  fi
  
  log "success" "Todas las dependencias están disponibles."
  return 0
}

# Función para crear backup antes de actualizar
create_backup() {
  log "step" "Creando backup antes de actualizar..."
  
  # Determinar directorio de datos
  local data_dir="${DATA_DIR:-}"
  if [[ -f "$CONFIG_FILE" ]] && [[ -z "$data_dir" ]]; then
    data_dir=$(grep "^DATA_DIR=" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 || echo "")
  fi
  
  # Valor por defecto si no se encuentra
  data_dir="${data_dir:-$HOME/private-llm-data}"
  
  # Crear directorio de datos si no existe
  mkdir -p "$data_dir"
  
  # Crear directorio de backups si no existe
  local backup_dir="$data_dir/backups"
  mkdir -p "$backup_dir"
  
  # Crear backup con fecha y hora
  local backup_date=$(date +"%Y%m%d_%H%M%S")
  local backup_file="$backup_dir/backup_$backup_date.tar.gz"
  
  log "info" "Guardando configuración en $backup_file..."
  
  # Crear archivo tar con configuraciones importantes
  if tar -czf "$backup_file" \
    -C "$data_dir" \
    --exclude="*/models" \
    --exclude="backups" \
    . 2>/dev/null; then
    log "success" "Backup creado correctamente en $backup_file"
  else
    log "warning" "Error al crear backup. Continuando de todos modos..."
  fi
}

# Función para actualizar Ollama
update_ollama() {
  log "step" "Actualizando Ollama AI runtime..."
  
  if ! command -v ollama &> /dev/null; then
    log "warning" "Ollama no está instalado. Instalando..."
    if curl -fsSL https://ollama.com/install.sh | sh >> "$LOG_FILE" 2>&1; then
      log "success" "Ollama instalado correctamente."
    else
      log "error" "Error al instalar Ollama."
      return 1
    fi
  else
    log "info" "Reinstalando/actualizando Ollama..."
    if curl -fsSL https://ollama.com/install.sh | sh >> "$LOG_FILE" 2>&1; then
      log "success" "Ollama actualizado correctamente."
    else
      log "error" "Error al actualizar Ollama."
      return 1
    fi
  fi
  
  # Verificar instalación
  if ! command -v ollama &> /dev/null; then
    log "error" "La instalación/actualización de Ollama falló."
    return 1
  fi
  
  # Obtener versión (manejo de errores mejorado)
  local ollama_version
  if ollama_version=$(ollama --version 2>&1 | head -n 1); then
    log "success" "Ollama disponible - versión: $ollama_version"
  else
    log "success" "Ollama instalado correctamente."
  fi
  
  return 0
}

# Función para actualizar Open WebUI
update_open_webui() {
  log "step" "Actualizando Open WebUI..."
  
  # Determinar directorio de datos
  local data_dir="${DATA_DIR:-}"
  if [[ -f "$CONFIG_FILE" ]] && [[ -z "$data_dir" ]]; then
    data_dir=$(grep "^DATA_DIR=" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 || echo "")
  fi
  data_dir="${data_dir:-$HOME/private-llm-data}"
  
  local webui_dir="$data_dir/open-webui"
  
  # Verificar si existe el directorio
  if [[ ! -d "$webui_dir/open-webui" ]]; then
    log "warning" "Directorio de Open WebUI no encontrado. Clonando repositorio..."
    mkdir -p "$webui_dir"
    if git clone https://github.com/open-webui/open-webui.git "$webui_dir/open-webui" >> "$LOG_FILE" 2>&1; then
      log "success" "Repositorio clonado correctamente."
    else
      log "error" "Error al clonar repositorio de Open WebUI."
      return 1
    fi
  else
    log "info" "Actualizando repositorio Open WebUI..."
    if (cd "$webui_dir/open-webui" && git pull) >> "$LOG_FILE" 2>&1; then
      log "success" "Repositorio actualizado correctamente."
    else
      log "warning" "Error al actualizar repositorio. Intentando reiniciar..."
      if (cd "$webui_dir/open-webui" && git reset --hard && git pull) >> "$LOG_FILE" 2>&1; then
        log "success" "Repositorio reiniciado y actualizado."
      else
        log "error" "Error al reiniciar y actualizar repositorio."
        return 1
      fi
    fi
  fi
  
  # Asegurar que existe el archivo .env
  if [[ ! -f "$webui_dir/open-webui/.env" ]]; then
    log "warning" "Archivo .env no encontrado. Creando configuración básica..."
    cat > "$webui_dir/open-webui/.env" << EOF
OLLAMA_BASE_URL=http://localhost:11434
WEBUI_SECRET_KEY=$(openssl rand -hex 32 2>/dev/null || echo "change-this-secret-key")
EOF
  fi
  
  # Solo reiniciar contenedores si no estamos en CI
  if [[ "$CI_MODE" != "true" ]]; then
    log "info" "Reiniciando contenedores Docker..."
    if (cd "$webui_dir/open-webui" && docker compose down && docker compose up -d) >> "$LOG_FILE" 2>&1; then
      # Verificar que el contenedor está en ejecución
      sleep 5
      if docker ps | grep -q open-webui 2>/dev/null; then
        log "success" "Open WebUI actualizado y en ejecución."
      else
        log "warning" "Open WebUI actualizado pero no se pudo verificar el estado del contenedor."
      fi
    else
      log "error" "Error al reiniciar contenedores de Open WebUI."
      return 1
    fi
  else
    log "info" "Modo CI detectado. Omitiendo reinicio de contenedores."
  fi
  
  return 0
}

# Función para comprobar y actualizar modelos
update_models() {
  log "step" "Comprobando actualizaciones de modelos..."
  
  # Verificar si Ollama está disponible
  if ! command -v ollama &> /dev/null; then
    log "warning" "Ollama no está disponible. Omitiendo actualización de modelos."
    return 0
  fi
  
  # Determinar qué modelos hay instalados
  local models
  if models=$(ollama list 2>/dev/null | awk 'NR>1 {print $1}' | grep -v '^$'); then
    log "info" "Modelos instalados encontrados."
  else
    log "warning" "No se encontraron modelos instalados o Ollama no está en ejecución."
    return 0
  fi
  
  if [[ -z "$models" ]]; then
    log "warning" "No hay modelos para actualizar."
    return 0
  fi
  
  log "info" "Modelos disponibles para actualizar:"
  echo "$models"
  
  # Preguntar si desea actualizar modelos (solo en modo interactivo)
  local update_all_models=""
  safe_read "¿Deseas actualizar todos los modelos instalados? (s/N): " "N" "update_all_models"
  
  if [[ "$update_all_models" =~ ^[Ss]$ ]]; then
    while IFS= read -r model; do
      if [[ -n "$model" ]]; then
        log "info" "Actualizando modelo $model..."
        if ollama pull "$model" >> "$LOG_FILE" 2>&1; then
          log "success" "Modelo $model actualizado correctamente."
        else
          log "warning" "Error al actualizar el modelo $model."
        fi
      fi
    done <<< "$models"
    log "success" "Actualización de modelos completada."
  else
    log "info" "Omitiendo actualización de modelos."
  fi
  
  return 0
}

# Función para limpiar al salir
cleanup() {
  local exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    log "error" "El script terminó con errores. Revisa el log: $LOG_FILE"
  fi
  exit $exit_code
}

# Configurar trap para cleanup
trap cleanup EXIT

# Función principal
main() {
  # Detectar entorno CI
  if [[ "$CI" == "true" ]] || [[ "$GITHUB_ACTIONS" == "true" ]]; then
    CI_MODE="true"
    INTERACTIVE="false"
    log "info" "Modo CI detectado. Ejecutando en modo no interactivo."
  fi
  
  show_banner
  
  # Detectar sistema operativo
  detect_os
  
  # Verificar dependencias
  if ! check_dependencies; then
    log "error" "Faltan dependencias críticas. Abortando actualización."
    exit 1
  fi
  
  # Verificar permisos (solo advertencia en CI)
  if [[ "$EUID" -eq 0 ]]; then
    if [[ "$CI_MODE" == "true" ]]; then
      log "warning" "Ejecutándose como root en CI. Continuando..."
    else
      log "warning" "Estás ejecutando el script como root. Se recomienda ejecutarlo como usuario normal."
      local continue_as_root=""
      safe_read "¿Continuar de todos modos? (s/N): " "N" "continue_as_root"
      if [[ ! "$continue_as_root" =~ ^[Ss]$ ]]; then
        log "error" "Actualización cancelada. Ejecuta el script sin privilegios de root."
        exit 1
      fi
    fi
  fi
  
  # Crear backup
  create_backup
  
  # Actualizar componentes
  local update_failed=0
  
  if ! update_ollama; then
    log "error" "Falló la actualización de Ollama."
    update_failed=1
  fi
  
  if ! update_open_webui; then
    log "error" "Falló la actualización de Open WebUI."
    update_failed=1
  fi
  
  if ! update_models; then
    log "warning" "Hubo problemas con la actualización de modelos."
  fi
  
  if [[ $update_failed -eq 0 ]]; then
    log "success" "¡Actualización de Private LLM Stack completada con éxito!"
    if [[ "$CI_MODE" != "true" ]]; then
      log "info" "Para comprobar que todo funciona correctamente, accede a tu interfaz web."
    fi
  else
    log "error" "La actualización se completó con algunos errores. Revisa el log para más detalles."
    exit 1
  fi
}

# Ejecutar función principal solo si no estamos siendo sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi