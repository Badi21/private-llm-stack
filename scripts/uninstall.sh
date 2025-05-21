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
DATA_DIR=""
DOMAIN=""

# Variables para opciones de desinstalación
remove_models="n"
remove_ollama="n"

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
    DATA_DIR=$(grep "DATA_DIR" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 || echo "")
    DOMAIN=$(grep "DOMAIN" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 || echo "")
  fi
  
  if [ -z "$DATA_DIR" ]; then
    DATA_DIR="$HOME/private-llm-data"
  fi
  
  log "info" "Directorio de datos: $DATA_DIR"
  if [ -n "$DOMAIN" ]; then
    log "info" "Dominio configurado: $DOMAIN"
  fi
}

# Función para detener y eliminar contenedores
remove_containers() {
  log "info" "Deteniendo y eliminando contenedores Docker..."
  
  # Intentar detener contenedores específicos por nombre
  local containers_to_stop=("open-webui" "ollama-webui" "private-llm")
  
  for container in "${containers_to_stop[@]}"; do
    if docker ps -q --filter "name=$container" | grep -q .; then
      log "info" "Deteniendo contenedor: $container"
      docker stop "$container" >> "$LOG_FILE" 2>&1 || log "warning" "Error al detener $container"
    fi
    
    if docker ps -a -q --filter "name=$container" | grep -q .; then
      log "info" "Eliminando contenedor: $container"
      docker rm "$container" >> "$LOG_FILE" 2>&1 || log "warning" "Error al eliminar $container"
    fi
  done
  
  # Si existe el directorio con docker-compose, usarlo
  if [ -d "$DATA_DIR/open-webui" ] && [ -f "$DATA_DIR/open-webui/docker-compose.yml" ]; then
    log "info" "Usando docker-compose para detener servicios..."
    (cd "$DATA_DIR/open-webui" && docker compose down -v) >> "$LOG_FILE" 2>&1 || {
      log "warning" "Error al detener servicios con docker-compose."
    }
  fi
  
  # Eliminar volúmenes huérfanos
  log "info" "Limpiando volúmenes Docker huérfanos..."
  docker volume prune -f >> "$LOG_FILE" 2>&1 || log "warning" "Error al eliminar volúmenes Docker."
  
  log "success" "Contenedores eliminados correctamente."
}

# Función para eliminar configuración de NGINX
remove_nginx_config() {
  if [ -n "$DOMAIN" ]; then
    log "info" "Eliminando configuración de NGINX para $DOMAIN..."
    
    # Eliminar enlaces simbólicos y archivos de configuración
    local nginx_configs=("/etc/nginx/sites-enabled/openwebui" "/etc/nginx/sites-enabled/$DOMAIN" "/etc/nginx/sites-available/openwebui" "/etc/nginx/sites-available/$DOMAIN")
    
    for config in "${nginx_configs[@]}"; do
      if [ -f "$config" ]; then
        log "info" "Eliminando: $config"
        sudo rm -f "$config" >> "$LOG_FILE" 2>&1 || log "warning" "Error al eliminar $config"
      fi
    done
    
    # Verificar configuración de NGINX
    if sudo nginx -t >> "$LOG_FILE" 2>&1; then
      # Recargar NGINX si está en ejecución
      if systemctl is-active --quiet nginx; then
        sudo systemctl reload nginx >> "$LOG_FILE" 2>&1 || log "warning" "Error al recargar NGINX."
      fi
    else
      log "warning" "Configuración de NGINX inválida después de la eliminación. Verifica manualmente."
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
    
    # Eliminar directorio de Open WebUI
    if [ -d "$DATA_DIR/open-webui" ]; then
      rm -rf "$DATA_DIR/open-webui" >> "$LOG_FILE" 2>&1 || log "warning" "Error al eliminar directorio de Open WebUI."
    fi
    
    # Eliminar otros archivos de configuración pero mantener modelos
    if [ -d "$DATA_DIR/config" ]; then
      rm -rf "$DATA_DIR/config" >> "$LOG_FILE" 2>&1 || log "warning" "Error al eliminar directorio de configuración."
    fi
    
    # Si el directorio está vacío (excepto modelos), preguntار si eliminarlo
    if [ -d "$DATA_DIR" ] && [ "$(find "$DATA_DIR" -type f | wc -l)" -eq 0 ]; then
      log "info" "El directorio $DATA_DIR está vacío. Eliminándolo..."
      rmdir "$DATA_DIR" >> "$LOG_FILE" 2>&1 || log "warning" "Error al eliminar directorio vacío."
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
      models=$(ollama list 2>/dev/null | awk 'NR>1 {print $1}' | head -20) # Limitar para evitar problemas
      
      if [[ -z "$models" ]]; then
        log "info" "No se encontraron modelos instalados."
      else
        for model in $models; do
          if [ -n "$model" ] && [ "$model" != "NAME" ]; then
            log "info" "Eliminando modelo $model..."
            ollama rm "$model" >> "$LOG_FILE" 2>&1 || log "warning" "Error al eliminar modelo $model."
          fi
        done
      fi
    else
      log "warning" "Ollama no está instalado. Omitiendo eliminación de modelos."
    fi
    
    # Limpiar directorios de modelos
    local ollama_dirs=("/root/.ollama/models" "$HOME/.ollama/models" "/usr/share/ollama/.ollama/models")
    
    for dir in "${ollama_dirs[@]}"; do
      if [ -d "$dir" ]; then
        log "info" "Eliminando directorio de modelos: $dir"
        if [[ "$dir" == "/root/.ollama/models" ]]; then
          sudo rm -rf "$dir" >> "$LOG_FILE" 2>&1 || log "warning" "Error al eliminar $dir"
        else
          rm -rf "$dir" >> "$LOG_FILE" 2>&1 || log "warning" "Error al eliminar $dir"
        fi
      fi
    done
    
    log "success" "Modelos de Ollama eliminados correctamente."
  else
    log "info" "Manteniendo modelos de Ollama (no seleccionado para eliminación)."
  fi
}

# Función para desinstalar Ollama
remove_ollama() {
  if [[ "$remove_ollama" =~ ^[Ss]$ ]]; then
    log "info" "Desinstalando Ollama..."
    
    # Detener servicio de Ollama si existe
    if systemctl is-active --quiet ollama 2>/dev/null; then
      log "info" "Deteniendo servicio de Ollama..."
      sudo systemctl stop ollama >> "$LOG_FILE" 2>&1 || log "warning" "Error al detener servicio de Ollama."
      sudo systemctl disable ollama >> "$LOG_FILE" 2>&1 || log "warning" "Error al deshabilitar servicio de Ollama."
    fi
    
    # Eliminar binario de Ollama
    if [ -f "/usr/local/bin/ollama" ]; then
      log "info" "Eliminando binario de Ollama..."
      sudo rm -f "/usr/local/bin/ollama" >> "$LOG_FILE" 2>&1 || log "warning" "Error al eliminar binario de Ollama."
    fi
    
    if [ -f "/usr/bin/ollama" ]; then
      sudo rm -f "/usr/bin/ollama" >> "$LOG_FILE" 2>&1 || log "warning" "Error al eliminar binario de Ollama."
    fi
    
    # Eliminar archivos del sistema
    local ollama_system_dirs=("/etc/systemd/system/ollama.service" "/usr/share/ollama" "/var/lib/ollama")
    
    for dir in "${ollama_system_dirs[@]}"; do
      if [ -e "$dir" ]; then
        log "info" "Eliminando: $dir"
        sudo rm -rf "$dir" >> "$LOG_FILE" 2>&1 || log "warning" "Error al eliminar $dir"
      fi
    done
    
    # Recargar systemd
    sudo systemctl daemon-reload >> "$LOG_FILE" 2>&1 || log "warning" "Error al recargar systemd."
    
    log "success" "Ollama desinstalado correctamente."
  else
    log "info" "Manteniendo instalación de Ollama (no seleccionado para desinstalación)."
  fi
}

# Función para eliminar archivos de configuración
remove_config_files() {
  log "info" "Eliminando archivos de configuración del sistema..."
  
  # Eliminar archivo de configuración principal
  if [ -f "$CONFIG_FILE" ]; then
    log "info" "Eliminando archivo de configuración: $CONFIG_FILE"
    rm -f "$CONFIG_FILE" >> "$LOG_FILE" 2>&1 || log "warning" "Error al eliminar $CONFIG_FILE"
  fi
  
  # Eliminar otros archivos de configuración relacionados
  local config_files=("$HOME/.ollama" "$HOME/.private-llm")
  
  for config in "${config_files[@]}"; do
    if [ -d "$config" ] && [[ "$remove_ollama" =~ ^[Ss]$ ]]; then
      log "info" "Eliminando directorio de configuración: $config"
      rm -rf "$config" >> "$LOG_FILE" 2>&1 || log "warning" "Error al eliminar $config"
    fi
  done
  
  log "success" "Archivos de configuración eliminados correctamente."
}

# Función para mostrar resumen final
show_summary() {
  log "success" "🎉 Desinstalación completada exitosamente!"
  echo ""
  echo -e "${GREEN}${BOLD}Resumen de la desinstalación:${NC}"
  echo " ✅ Contenedores Docker eliminados"
  echo " ✅ Configuración de NGINX eliminada"
  echo " ✅ Archivos de datos eliminados"
  
  if [[ "$remove_models" =~ ^[Ss]$ ]]; then
    echo " ✅ Modelos de Ollama eliminados"
  else
    echo " ⏭️  Modelos de Ollama conservados"
  fi
  
  if [[ "$remove_ollama" =~ ^[Ss]$ ]]; then
    echo " ✅ Ollama desinstalado"
  else
    echo " ⏭️  Ollama conservado"
  fi
  
  echo ""
  echo -e "${BLUE}Log de desinstalación guardado en: $LOG_FILE${NC}"
  echo -e "${YELLOW}Si encuentras algún problema, revisa el log para más detalles.${NC}"
}

# Función principal
main() {
  # Inicializar log
  echo "=== Private LLM Stack Uninstaller - $(date) ===" > "$LOG_FILE"
  
  show_banner
  confirm_uninstall
  get_data_dir
  
  log "info" "Iniciando proceso de desinstalación..."
  
  # Ejecutar pasos de desinstalación
  remove_containers
  remove_nginx_config
  remove_data_files
  remove_ollama_models
  remove_ollama
  remove_config_files
  
  show_summary
}

# Verificar si se ejecuta como script principal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi