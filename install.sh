#!/bin/bash

# Déchiffrer le fichier des mots de passe
gpg -d passwords.env.gpg > passwords.env

# Charger les variables d'environnement depuis le fichier déchiffré
if [ -f passwords.env ]; then
    export $(cat passwords.env | xargs)
else
    echo "Le fichier passwords.env n'existe pas."
    exit 1
fi

# Vérification des variables d'environnement
if [ -z "$DB_ROOT_PASSWORD" ] || [ -z "$PHPMYADMIN_PASSWORD" ]; then
    echo "Les variables d'environnement DB_ROOT_PASSWORD et PHPMYADMIN_PASSWORD doivent être définies."
    exit 1
fi

# Mise à jour du système
sudo apt update && sudo apt upgrade -y

# Installation d'Apache
sudo apt install apache2 -y

# Démarrage et activation d'Apache
sudo systemctl start apache2
sudo systemctl enable apache2

# Installation de PHP 8.2
sudo apt install -y lsb-release apt-transport-https ca-certificates
wget -qO - https://packages.sury.org/php/apt.gpg | sudo apt-key add -
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list
sudo apt update
sudo apt install php8.2 libapache2-mod-php8.2 -y

# Installation des extensions PHP couramment utilisées
sudo apt install php8.2-{cli,common,curl,gd,mbstring,mysql,xml,zip} -y

# Installation de MariaDB
sudo apt install mariadb-server mariadb-client -y

# Démarrage et activation de MariaDB
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Configuration sécurisée de MariaDB
sudo mysql_secure_installation <<EOF

Y
$DB_ROOT_PASSWORD
$DB_ROOT_PASSWORD
Y
Y
Y
Y
EOF

# Installation de Node.js (dernière version LTS)
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

# Préconfigurer les réponses debconf pour phpMyAdmin
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $PHPMYADMIN_PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $DB_ROOT_PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $PHPMYADMIN_PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"

# Installation de phpMyAdmin
sudo apt install phpmyadmin -y

# Configuration de phpMyAdmin avec Apache
sudo ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin

# Redémarrage d'Apache pour prendre en compte les changements
sudo systemctl restart apache2

echo "Installation complète du serveur LAMP avec Apache, PHP 8.2, MariaDB, Node.js et phpMyAdmin."

# Nettoyage du fichier déchiffré
rm -f passwords.env
