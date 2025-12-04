#!/bin/bash

set -e

echo "🚀 Déploiement en cours..."

APP_DIR="/var/www/zetta_api"
PHP_BIN="php8.3"
COMPOSER_BIN="/usr/local/bin/composer"  # adapte si besoin, ex: /usr/bin/composer

cd "$APP_DIR"

echo "📥 Sauvegarde du fichier .env..."
cp .env /tmp/.env_backup

echo "📥 Mise à jour du dépôt depuis GitHub...."
git fetch --all
git reset --hard origin/main
git clean -fd

echo "♻️ Restauration du fichier .env..."
mv /tmp/.env_backup .env

echo "📦 Installation des dépendances PHP..."
$PHP_BIN $COMPOSER_BIN install --no-interaction --prefer-dist --optimize-autoloader --no-dev

echo "📦 Installation des dépendances npm..."
if command -v npm >/dev/null 2>&1; then
  npm install
  npm run build
else
  echo "⚠️ npm non installé, étape ignorée."
fi

echo "⚙️  Configuration de l'environnement (migrations)..."
$PHP_BIN artisan migrate --force

echo "🧹 Nettoyage du cache..."
$PHP_BIN artisan cache:clear
$PHP_BIN artisan config:clear
$PHP_BIN artisan route:clear
$PHP_BIN artisan view:clear

echo "⚡ Optimisation de l'application..."
$PHP_BIN artisan config:cache
$PHP_BIN artisan route:cache
$PHP_BIN artisan view:cache

echo "🔄 Redémarrage de PHP-FPM et Nginx..."
systemctl restart php8.3-fpm
systemctl restart nginx

echo "✅ Déploiement terminé avec succès ! 🎉"
