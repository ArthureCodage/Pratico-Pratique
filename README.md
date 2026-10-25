# 🧰 Pratico-Pratique

Des scripts d'installation en une commande pour monter vite un serveur IA sous Linux (Ubuntu / Debian, VPS ou machine perso).

| Script | Ce qu'il installe |
|---|---|
| [`install-ollama-dono.sh`](install-ollama-dono.sh) | **Ollama** en service systemd, accessible depuis le réseau (port `11434`), démarrage automatique |
| [`install-sdfn-dono.sh`](install-sdfn-dono.sh) | **Stable Diffusion WebUI Forge** avec ses dépendances, préréglé pour un serveur : accès distant, API, thème sombre, xformers |

## Utilisation

```bash
git clone https://github.com/ArthureCodage/Pratico-Pratique.git
cd Pratico-Pratique
sudo bash install-ollama-dono.sh
sudo bash install-sdfn-dono.sh
```

Les scripts doivent être lancés avec `sudo`.

> ⚠️ Les deux services écoutent sur toutes les interfaces réseau. Sur un VPS, protège-les (pare-feu, tunnel SSH ou VPN comme Tailscale) avant de les laisser tourner.

## Projets liés

- [sd-forge-ollama-prompt](https://github.com/ArthureCodage/sd-forge-ollama-prompt) — génère des prompts Stable Diffusion avec Ollama, directement dans Forge
- [DonoGenSoft](https://github.com/ArthureCodage/DonoGenSoft) — kohya_ss + LoRA Creator + Forge Neo en une commande sur vast.ai / RunPod
