#!/bin/bash

set -e

DB_PASSWORD="StrongPassword"
ZBX_SERVER_IP="127.0.0.1"

echo
apt update -y
apt upgrade -y

echo 
apt install -y apache2 php libapache2-mod-php php-mysql php-xml php-bcmath php-mbstring php-gd php-ldap php-json php-cli

echo 
apt install -y mariadb-server mariadb-client
systemctl enable mariadb
systemctl start mariadb

echo 
sudo mysql <<EOF
CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER 'zabbix'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';
FLUSH PRIVILEGES;
EOF

echo 
wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-4+ubuntu24.04_all.deb
dpkg -i zabbix-release_7.0-4+ubuntu24.04_all.deb
apt update -y

echo 
apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent

echo 
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql -uzabbix -p${DB_PASSWORD} zabbix

echo 
sed -i "s/# DBPassword=/DBPassword=${DB_PASSWORD}/" /etc/zabbix/zabbix_server.conf

echo 
cat <<EOF > /etc/zabbix/web/zabbix.conf.php
<?php
global \$DB;
\$DB['TYPE']     = 'MYSQL';
\$DB['SERVER']   = 'localhost';
\$DB['PORT']     = '0';
\$DB['DATABASE'] = 'zabbix';
\$DB['USER']     = 'zabbix';
\$DB['PASSWORD'] = '${DB_PASSWORD}';
\$ZBX_SERVER     = '${ZBX_SERVER_IP}';
\$ZBX_SERVER_PORT = '10051';
\$ZBX_SERVER_NAME = 'Zabbix Server';
\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
?>
EOF

echo 
systemctl restart zabbix-server zabbix-agent apache2
systemctl enable zabbix-server zabbix-agent apache2

echo 
echo 
echo 
