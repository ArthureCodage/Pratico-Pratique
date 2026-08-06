#!/usr/bin/env bash

# ==============================================================================
# Script d'installation automatique - Ollama Server
# Fichier : install-ollama-dono.sh
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
    log_error "Ce script doit être exécuté avec les privilèges root (ex: sudo bash install-ollama-dono.sh)."
    exit 1
fi

SERVICE_NAME="ollama"

log_info "Début de l'installation d'Ollama Server..."

# 2. Dépendances de base
log_info "Installation des outils réseau de base..."
apt-get update -y
apt-get install -y curl wget systemd

# 3. Installation d'Ollama via le script officiel
log_info "Téléchargement et installation du binaire Ollama..."
curl -fsSL https://ollama.com/install.sh | sh

# 4. Configuration du service Systemd pour écouter à distance et redémarrer en cas de crash
log_info "Configuration du service systemd ($SERVICE_NAME) avec accès distant et auto-restart..."

OVERRIDE_DIR="/etc/systemd/system/ollama.service.d"
mkdir -p "$OVERRIDE_DIR"

# OLLAMA_HOST=0.0.0.0:11434 autorise les connexions externes sur le port 11434
cat <<EOF > "$OVERRIDE_DIR/override.conf"
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
Restart=always
RestartSec=5
EOF

# 5. Rechargement et activation du service
log_info "Rechargement et démarrage du service Ollama..."
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl restart "$SERVICE_NAME"

# Attente du démarrage de l'API Ollama
log_info "Attente de l'initialisation du service..."
sleep 3

# 6. Téléchargement optionnel d'un modèle par défaut
DEFAULT_MODEL="llama3.2"
log_info "Téléchargement du modèle par défaut ($DEFAULT_MODEL)..."
ollama run "$DEFAULT_MODEL" "" || log_warn "Le pré-téléchargement du modèle a échoué. Vous pourrez exécuter 'ollama pull $DEFAULT_MODEL' plus tard."

log_success "================================================================="
log_success " Installation d'Ollama terminée avec succès !"
log_success "================================================================="
log_info "Détails de la configuration :"
log_info "  - Port API : 11434 (ouvert sur 0.0.0.0)"
log_info "  - Auto-start au démarrage : Activé"
log_info "  - Auto-restart en cas de crash : Activé (délai : 5s)"
log_info ""
log_info "Commandes utiles :"
log_info "  - Télécharger un modèle :  ollama pull <modèle>"
log_info "  - Lister les modèles :      ollama list"
log_info "  - Voir les logs du service: sudo journalctl -u ${SERVICE_NAME} -f"
log_info "  - Redémarrer le service :   sudo systemctl restart ${SERVICE_NAME}"
log_success "================================================================="
