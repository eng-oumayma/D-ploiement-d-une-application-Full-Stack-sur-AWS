# #!/bin/bash
# set -e   # Arrêter le script si une commande échoue

# # ── Mise à jour du système et installation des outils ──
# apt update -y
# apt install -y git nodejs npm

# # ── Cloner votre application ──
# cd /home/ubuntu
# git clone ${github_repo} app
# cd app

# # ── Installer les dépendances ──
# npm install

# # ── Injecter les variables d'environnement (jamais en dur dans le code !) ──
# export DB_HOST="${db_host}"
# export DB_NAME="${db_name}"
# export DB_USER="${db_username}"
# export DB_PASS="${db_password}"
# export PORT="${app_port}"
# export NODE_ENV="production"

# # ── Écrire les variables dans un fichier .env pour la persistance ──
# cat > /home/ubuntu/app/.env <<EOF
# DB_HOST=${db_host}
# DB_NAME=${db_name}
# DB_USER=${db_username}
# DB_PASS=${db_password}
# PORT=${app_port}
# NODE_ENV=production
# EOF

# # ── Démarrer l'application ──
# npm start &

# # ── (Optionnel) Installer PM2 pour une gestion plus robuste du processus ──
# # npm install -g pm2
# # pm2 start npm -- start
# # pm2 startup && pm2 save


#!/bin/bash
exec > /var/log/user-data.log 2>&1

# Supprimer conflits Node.js
apt-get remove -y nodejs libnode72 nodejs-doc || true
apt-get autoremove -y || true

apt-get update -y
apt-get install -y git curl

# Installer Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

echo ">>> Node: $(node -v) | NPM: $(npm -v)"

# Cloner le repo
cd /home/ubuntu
git clone ${github_repo} app
cd /home/ubuntu/app/backend

# Fichier .env
cat > .env << EOF
DB_HOST=${db_host}
DB_NAME=${db_name}
DB_USER=${db_username}
DB_PASSWORD=${db_password}
PORT=${app_port}
EOF

echo ">>> .env créé"

# Installer dépendances
npm install

# Installer PM2 et démarrer
npm install -g pm2
pm2 start index.js --name backend
pm2 startup systemd -u ubuntu --hp /home/ubuntu
pm2 save

echo ">>> PM2 status:"
pm2 status

echo ">>> Test local:"
sleep 3
curl -s http://localhost:${app_port}/health || echo "WARN: /health ne répond pas"

echo ">>> DONE backend déployé ✅"