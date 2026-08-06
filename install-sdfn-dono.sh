#!/usr/bin/env bash

# ==============================================================================
# Script d'installation automatique - Stable Diffusion WebUI Forge
# Fichier : install-sdfn-dono.sh
# ==============================================================================

set -eo pipefail

# Couleurs pour la sortie terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 1. Vérification des privilèges root
if [ "$EUID" -ne 0 ]; then
    log_error "Ce script doit être exécuté avec les privilèges root (ex: sudo bash install-sdfn-dono.sh)."
    exit 1
fi

# Définition des variables
INSTALL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$INSTALL_USER")
INSTALL_DIR="$USER_HOME/stable-diffusion-webui-forge"
SERVICE_NAME="sd-forge"

log_info "Début de l'installation de SD WebUI Forge pour l'utilisateur : $INSTALL_USER"

# 2. Mise à jour du système et installation des dépendances
log_info "Mise à jour des paquets système et installation des dépendances..."
apt-get update -y
apt-get install -y \
    git \
    python3 \
    python3-venv \
    python3-pip \
    libgl1 \
    libglib2.0-0 \
    wget \
    curl \
    google-perftools \
    build-essential \
    ffmpeg

# 3. Clonage du dépôt Stable Diffusion WebUI Forge
if [ -d "$INSTALL_DIR" ]; then
    log_warn "Le dossier $INSTALL_DIR existe déjà. Annulation du clonage."
else
    log_info "Clonage du dépôt SD WebUI Forge..."
    sudo -u "$INSTALL_USER" git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git "$INSTALL_DIR"
fi

# 4. Configuration de webui-user.sh
log_info "Configuration des arguments de lancement (Extensions autorisées & Accès distant)..."
WEBUI_USER_CONF="$INSTALL_DIR/webui-user.sh"

# Arguments préconfigurés pour VPS :
# --listen : Rend l'interface accessible de l'extérieur
# --enable-insecure-extension-access : Permet l'installation d'extensions depuis l'UI via IP distante
# --api : Active l'API REST
# --theme dark : Thème sombre par défaut
COMMANDLINE_ARGS="--listen --enable-insecure-extension-access --api --theme dark --xformers"

cat <<EOF > "$WEBUI_USER_CONF"
#!/usr/bin/env bash
# Configuration automatique générée par install-sdfn-dono.sh
COMMANDLINE_ARGS="${COMMANDLINE_ARGS}"
EOF

chown "$INSTALL_USER:$INSTALL_USER" "$WEBUI_USER_CONF"
chmod +x "$WEBUI_USER_CONF"

# 5. Création du service Systemd pour l'exécution en arrière-plan et le redémarrage
log_info "Création et configuration du service systemd ($SERVICE_NAME)..."

cat <<EOF > "/etc/systemd/system/${SERVICE_NAME}.service"
[Unit]
Description=Stable Diffusion WebUI Forge
After=network.target nvidia-persistenced.service

[Service]
Type=simple
User=${INSTALL_USER}
WorkingDirectory=${INSTALL_DIR}
ExecStart=${INSTALL_DIR}/webui.sh
Restart=always
RestartSec=5
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

# 6. Rechargement et activation du service
log_info "Activation du service systemd..."
systemctl daemon-reload
systemctl enable "${SERVICE_NAME}.service"
systemctl restart "${SERVICE_NAME}.service"

log_success "================================================================="
log_success " Installation terminée avec succès !"
log_success "================================================================="
log_info "Le service '${SERVICE_NAME}' est configuré pour :"
log_info "  - Se lancer automatiquement au démarrage du VPS."
log_info "  - Redémarrer automatiquement en cas de crash (délai : 5s)."
log_info ""
log_info "Commandes utiles pour gérer le service :"
log_info "  - Voir les logs en direct : sudo journalctl -u ${SERVICE_NAME} -f"
log_info "  - Redémarrer :             sudo systemctl restart ${SERVICE_NAME}"
log_info "  - Arrêter :                sudo systemctl stop ${SERVICE_NAME}"
log_info "  - Statut :                 sudo systemctl status ${SERVICE_NAME}"
log_success "================================================================="
