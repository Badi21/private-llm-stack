#!/bin/bash

# Crear directorio principal
mkdir -p private-llm-stack

# Cambiar al directorio del proyecto
cd private-llm-stack || exit

# Crear archivos raíz
touch LICENSE README.md README_EN.md CONTRIBUTING.md SECURITY.md CHANGELOG.md

# Crear estructura de directorios y archivos
mkdir -p docs/images
touch docs/setup-guide.md docs/troubleshooting.md docs/advanced-config.md
touch docs/images/screenshot-chat.png docs/images/screenshot-models.png

mkdir -p scripts/utils
touch scripts/install.sh scripts/update.sh scripts/uninstall.sh
touch scripts/utils/system_check.sh scripts/utils/backup.sh scripts/utils/security.sh

mkdir -p configs/nginx configs/docker
touch configs/nginx/server-block-ssl.conf configs/nginx/server-block-nossl.conf
touch configs/docker/docker-compose.yml.template

mkdir -p .github/ISSUE_TEMPLATE .github/workflows
touch .github/ISSUE_TEMPLATE/bug_report.md .github/ISSUE_TEMPLATE/feature_request.md
touch .github/PULL_REQUEST_TEMPLATE.md
touch .github/workflows/shellcheck.yml .github/workflows/release.yml

# Dar permisos de ejecución a los scripts
chmod +x scripts/*.sh
chmod +x scripts/utils/*.sh

# Mensaje de finalización
echo "Estructura del proyecto creada con éxito:"
tree