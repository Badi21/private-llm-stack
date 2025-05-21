#!/bin/bash
# =================================================================
# Private LLM Stack Updater
# Autor: Tu Nombre <tu@email.com>
# Repositorio: https://github.com/tuusuario/private-llm-stack
# Licencia: MIT
# =================================================================

# Configuración estricta para detectar errores
set -euo pipefail
IFS=$'\n\t'

# Variables globales
VERSION="1.0.0"
LOG_FILE="/tmp/private-llm-updater.log"
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
  echo "║               🔄 PRIVATE LLM STACK UPDATER               ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
  echo -e "${CYAN}Actualizando tu asistente de IA privado y seguro${NC}"
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

# Función para crear backup antes de actualizar
create_backup() {
  log "step" "Creando backup antes de actualizar..."
  
  # Determinar directorio de datos
  local data_dir
  if [ -f "$CONFIG_FILE" ]; then
    data_dir=$(grep "DATA_DIR" "$CONFIG_FILE" | cut -d'=' -f2)
  else
    data_dir="$HOME/private-llm-data"
  fi
  
  # Crear directorio de backups si no existe
  local backup_dir="$data_dir/backups"
  mkdir -p "$backup_dir"
  
  # Crear backup con fecha y hora
  local backup_date=$(date +"%Y%m%d_%H%M%S")
  local backup_file="$backup_dir/backup_$backup_date.tar.gz"
  
  log "info" "Guardando configuración en $backup_file..."
  
  # Crear archivo tar con configuraciones importantes
  tar -czf "$backup_file" \
    -C "$data_dir" \
    --exclude="*/models" \
    --exclude="backups" \
    . > /dev/null 2>&1 || {
    log "error" "Error al crear backup. Continuando de todos modos..."
  }
  
  log "success" "Backup creado correctamente en $backup_file"
}

# Función para actualizar Ollama
update_ollama() {
  log "step" "Actualizando Ollama AI runtime..."
  
  if ! command -v ollama &> /dev/null; then
    log "warning" "Ollama no está instalado. Instalando..."
    curl -fsSL https://ollama.com/install.sh | sh >> "$LOG_FILE" 2>&1 || {
      log "error" "Error al instalar Ollama."
      exit 1
    }
  else
    log "info" "Reinstalando/actualizando Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh >> "$LOG_FILE" 2>&1 || {
      log "error" "Error al actualizar Ollama."
      exit 1
    }
  fi
  
  # Verificar instalación
  if ! command -v ollama &> /dev/null; then
    log "error" "La actualización de Ollama falló."
    exit 1
  fi
  
  local ollama_version
  ollama_version=$(ollama --version 2>&1 | head -n 1)
  log "success" "Ollama actualizado correctamente a versión: $ollama_version"
}

# Función para actualizar Open WebUI
update_open_webui() {
  log "step" "Actualizando Open WebUI..."
  
  # Determinar directorio de datos
  local data_dir
  if [ -f "$CONFIG_FILE" ]; then
    data_dir=$(grep "DATA_DIR" "$CONFIG_FILE" | cut -d'=' -f2)
  else
    data_dir="$HOME/private-llm-data"
  fi
  
  local webui_dir="$data_dir/open-webui"
  
  # Verificar si existe el directorio
  if [ ! -d "$webui_dir/open-webui" ]; then
    log "warning" "Directorio de Open WebUI no encontrado. Clonando repositorio..."
    mkdir -p "$webui_dir"
    git clone https://github.com/open-webui/open-webui.git "$webui_dir/open-webui" >> "$LOG_FILE" 2>&1 || {
      log "error" "Error al clonar repositorio de Open WebUI."
      exit 1
    }
  else
    log "info" "Actualizando repositorio Open WebUI..."
    (cd "$webui_dir/open-webui" && git pull) >> "$LOG_FILE" 2>&1 || {
      log "error" "Error al actualizar repositorio de Open WebUI."
      log "info" "Intentando reiniciar repositorio local..."
      (cd "$webui_dir/open-webui" && git reset --hard && git pull) >> "$LOG_FILE" 2>&1 || {
        log "error" "Error al reiniciar y actualizar repositorio."
        exit 1
      }
    }
  fi
  
  # Asegurar que existe el archivo .env
  if [ ! -f "$webui_dir/open-webui/.env" ]; then
    log "warning" "Archivo .env no encontrado. Creando..."
    echo "OLLAMA_BASE_URL=http://localhost:11434" > "$webui_dir/open-webui/.env"
  fi
  
  # Reiniciar contenedores
  log "info" "Reiniciando contenedores Docker..."
  (cd "$webui_dir/open-webui" && docker compose down && docker compose up -d) >> "$LOG_FILE" 2>&1 || {
    log "error" "Error al reiniciar contenedores de Open WebUI."
    exit 1
  }
  
  # Verificar que el contenedor está en ejecución
  sleep 5
  if ! docker ps | grep -q open-webui; then
    log "error" "Los contenedores de Open WebUI no están en ejecución."
    log "error" "Verifica los logs de Docker para más detalles: docker logs open-webui-open-webui-1"
    exit 1
  }
  
  log "success" "Open WebUI actualizado correctamente."
}

# Función para comprobar y actualizar modelos
update_models() {
  log "step" "Comprobando actualizaciones de modelos..."
  
  # Determinar qué modelos hay instalados
  local models
  models=$(ollama list | awk 'NR>1 {print $1}')
  
  if [[ -z "$models" ]]; then
    log "warning" "No se encontraron modelos instalados."
    return
  fi
  
  log "info" "Modelos instalados: $models"
  
  # Preguntar si desea actualizar modelos
  read -rp "¿Deseas actualizar todos los modelos instalados? (s/N): " update_all_models
  
  if [[ "$update_all_models" =~ ^[Ss]$ ]]; then
    for model in $models; do
      log "info" "Actualizando modelo $model..."
      ollama pull "$model" >> "$LOG_FILE" 2>&1 || {
        log "warning" "Error al actualizar el modelo $model."
      }
    done
    log "success" "Actualización de modelos completada."
  else
    log "info" "Omitiendo actualización de modelos."
  fi
}

# Función principal
main() {
  show_banner
  
  # Verificar que el script se ejecuta con permisos adecuados
  if [ "$EUID" -eq 0 ]; then
    log "warning" "Estás ejecutando el script como root. Se recomienda ejecutarlo como usuario normal con permisos sudo."
    read -rp "¿Continuar de todos modos? (s/N): " continue_as_root
    if [[ ! "$continue_as_root" =~ ^[Ss]$ ]]; then
      log "error" "Actualización cancelada. Ejecuta el script sin privilegios de root."
      exit 1
    fi
  fi
  
  # Crear backup
  create_backup
  
  # Actualizar componentes
  update_ollama
  update_open_webui
  update_models
  
  log "success" "¡Actualización de Private LLM Stack completada con éxito!"
  log "info" "Para comprobar que todo funciona correctamente, accede a tu interfaz web."
}

# Ejecutar función principal
main "$@"