#!/bin/bash
# =================================================================
# Private LLM Stack Uninstaller
# Autor: Tu Nombre <tu@email.com>
# Repositorio: https://github.com/tuusuario/private-llm-stack
# Licencia: MIT
# =================================================================

# Configuración estricta para detectar errores
set -euo pipefail
IFS=$'\n\t'

# Variables globales
LOG_FILE="/tmp/private-llm-uninstaller.log"
CONFIG_FILE="$HOME/.private-llm-config"

# Colores para mensajes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

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
  esac
  
  echo -e "${color}${prefix}${message}${NC}"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${type^^}] ${message}" >> "$LOG_FILE"
}

# Función para mostrar mensaje de bienvenida
show_banner() {
  clear
  echo -e "${RED}${BOLD}"
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║              🗑️ PRIVATE LLM STACK UNINSTALLER            ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
  echo -e "${YELLOW}¡ATENCIÓN! Este script eliminará tu instalación de Private LLM Stack${NC}"
  echo ""
}

# Función para confirmar desinstalación
confirm_uninstall() {
  echo -e "${YELLOW}${BOLD}⚠️  ADVERTENCIA: Esta acción eliminará:${NC}"
  echo " - Configuración de NGINX para tu dominio"
  echo " - Contenedores Docker de Open WebUI"
  echo " - Archivos de configuración"
  echo -e "${YELLOW}Por defecto, NO se eliminarán:${NC}"
  echo " - Los modelos descargados de Ollama (pueden ser muy grandes)"
  echo " - La instalación de Ollama, Docker o NGINX"
  echo ""
  
  read -rp "¿Estás seguro de que deseas desinstalar Private LLM Stack? (escribe 'DESINSTALAR' para confirmar): " confirmation
  
  if [ "$confirmation" != "DESINSTALAR" ]; then
    log "info" "Desinstalación cancelada."
    exit 0
  fi
  
  echo ""
  read -rp "¿Deseas también eliminar los modelos descargados de Ollama? (s/N): " remove_models
  echo ""
  read -rp "¿Deseas también desinstalar Ollama? (s/N): " remove_ollama
  echo ""
}

# Función para determinar la ubicación de los datos
get_data_dir() {
  if [ -f "$CONFIG_FILE" ]; then
    DATA_DIR=$(grep "DATA_DIR" "$CONFIG_FILE" | cut -d'=' -f2)
  else
    DATA_DIR="$HOME/private-llm-data"
  fi
  
  DOMAIN=$(grep "DOMAIN" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 || echo "")
  
  log "info" "Directorio de datos: $DATA_DIR"
  if [ -n "$DOMAIN" ]; then
    log "info" "Dominio configurado: $DOMAIN"
  fi
}

# Función para detener y eliminar contenedores
remove_containers() {
  log "info" "Deteniendo y eliminando contenedores Docker..."
  
  if [ -d "$DATA_DIR/open-webui" ]; then
    (cd "$DATA_DIR/open-webui" && docker compose down -v) >> "$LOG_FILE" 2>&1 || {
      log "warning" "Error al detener contenedores. Es posible que ya estén detenidos."
    }
  else
    log "warning" "Directorio de Open WebUI no encontrado. Intentando detener contenedores manualmente..."
    docker stop $(docker ps -q --filter "name=open-webui") 2>/dev/null || true
    docker rm $(docker ps -a -q --filter "name=open-webui") 2>/dev/null || true
  fi
  
  # Eliminar volúmenes sin usar
  docker volume prune -f >> "$LOG_FILE" 2>&1 || log "warning" "Error al eliminar volúmenes Docker."
  
  log "success" "Contenedores eliminados correctamente."
}

# Función para eliminar configuración de NGINX
remove_nginx_config() {
  if [ -n "$DOMAIN" ]; then
    log "info" "Eliminando configuración de NGINX para $DOMAIN..."
    
    if [ -f "/etc/nginx/sites-enabled/openwebui" ]; then
      sudo rm -f "/etc/nginx/sites-enabled/openwebui" >> "$LOG_FILE" 2>&1 || log "warning" "Error al eliminar enlace simbólico de NGINX."
    fi
    
    if [ -f "/etc/nginx/sites-available/openwebui" ]; then
      sudo rm -f "/etc/nginx/sites-available/openwebui" >> "$LOG_FILE" 2>&1 || log "warning" "Error al eliminar configuración de NGINX."
    fi
    
    # Recargar NGINX si está en ejecución
    if systemctl is-active --quiet nginx; then
      sudo systemctl reload nginx >> "$LOG_FILE" 2>&1 || log "warning" "Error al recargar NGINX."
    fi
    
    log "success" "Configuración de NGINX eliminada correctamente."
  else
    log "info" "No se encontró configuración de dominio. Omitiendo limpieza de NGINX."
  fi
}

# Función para eliminar archivos de datos
remove_data_files() {
  if [ -d "$DATA_DIR" ]; then
    log "info" "Eliminando archivos de configuración en $DATA_DIR..."
    
    # Eliminar todo excepto la carpeta de modelos
    if [ -d "$DATA_DIR/open-webui" ]; then
      rm -rf "$DATA_DIR/open-webui" >> "$LOG_FILE" 2>&1 || log "warning" "Error al eliminar directorio de Open WebUI."
    fi
    
    log "success" "Archivos de configuración eliminados correctamente."
  else
    log "info" "Directorio de datos no encontrado. Omitiendo limpieza."
  fi
}

# Función para eliminar modelos de Ollama
remove_ollama_models() {
  if [[ "$remove_models" =~ ^[Ss]$ ]]; then
    log "info" "Eliminando modelos de Ollama..."
    
    if command -v ollama &> /dev/null; then
      # Obtener lista de modelos
      local models
      models=$(ollama list | awk 'NR>1 {print $1}')
      
      if [[ -z "$models" ]]; then
        log "info" "No se encontraron modelos instalados."
      else
        for model in $models; do
          log "info" "Eliminando modelo $model..."
          ollama rm "$model" >> "$LOG_FILE" 2>&1 || log "warning" "Error al eliminar modelo $model."
        done
      fi
    else
      log "warning" "Ollama no está instalado. Omitiendo eliminación de modelos."
    fi
    
    # Limpiar directorio de modelos
    if [ -d "/root/.ollama" ]; then
      sudo rm -rf "/root/.ollama/models" >> "$LOG_FILE" 2>&1 || log "warning" "Error al eliminar modelos de Ollama."
    fi
    
    if [ -d "$HOME/.ollama" ]; then
      rm -rf "$HOME/.ollama/models" >> "$LOG_FILE" 2>&1 || log "warning" "Error