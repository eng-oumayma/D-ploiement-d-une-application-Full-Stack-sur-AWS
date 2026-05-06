#!/bin/bash
exec > /var/log/user-data.log 2>&1

# ── Supprimer l'ancienne version de Node qui cause le conflit ──
apt-get remove -y nodejs libnode72 nodejs-doc || true
apt-get autoremove -y || true

# ── Installer Node.js 18 proprement ──
apt-get update -y
apt-get install -y git curl nginx

curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

echo ">>> Node version: $(node -v)"
echo ">>> NPM version: $(npm -v)"

# ── Cloner le repo ──
cd /home/ubuntu
git clone ${github_repo} app
cd /home/ubuntu/app/client




# ── Injecter URL backend dans les fichiers build ──

ALB_URL="${alb_dns_name}"

echo ">>> Injection ALB URL: $ALB_URL"

find /home/ubuntu/app/client/dist -type f -name "*.js" -exec sed -i "s|http://localhost:3000|$ALB_URL|g" {} +
# ── Build Angular ──
export NODE_OPTIONS="--max-old-space-size=512"
npm install --legacy-peer-deps
npm run build -- --configuration production




# ── Trouver le dossier dist UNIQUEMENT dans client/dist ──
# Remplacer la détection automatique par le chemin direct
BUILD_DIR="/home/ubuntu/app/client/dist/client/browser"

if [ -z "$BUILD_DIR" ]; then
  echo "ERREUR: build Angular introuvable dans dist/"
  ls /home/ubuntu/app/client/
  exit 1
fi

echo ">>> Build trouvé: $BUILD_DIR"

# ── Copier vers nginx ──
rm -rf /var/www/html/*
cp -r "$BUILD_DIR"/. /var/www/html/

# ── Config nginx pour Angular routing ──
cat > /etc/nginx/sites-available/default <<'EOF'
server {
    listen 80 default_server;
    root /var/www/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOF

systemctl enable nginx
systemctl restart nginx

echo ">>> DONE - Frontend déployé ✅"