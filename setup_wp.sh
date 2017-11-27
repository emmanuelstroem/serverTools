#!/bin/sh
export DEBIAN_FRONTEND="noninteractive"

# command line arguments
if [ $# -gt 0 ]; then
    echo "Your command line contains $# arguments"
    domain_name = "$1"
else
    echo "Your command line contains no arguments"
		domain_name = "emmanuelopio"
fi


# update packages
apt-get update

# Force Locale
echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
locale-gen en_US.UTF-8

apt-get install -y software-properties-common curl
apt-add-repository ppa:ondrej/php -y
apt-add-repository ppa:nginx/development -y

apt-get update

apt-get install -y build-essential dos2unix gcc git libmcrypt4 libpcre3-dev ntp unzip make python2.7-dev python-pip re2c supervisor unattended-upgrades whois vim libnotify-bin pv cifs-utils

apt-get install -y php7.1-cli php7.1-dev \
php7.1-pgsql php7.1-sqlite3 php7.1-gd \
php7.1-curl php7.1-memcached \
php7.1-imap php7.1-mysql php7.1-mbstring \
php7.1-xml php7.1-zip php7.1-bcmath php7.1-soap \
php7.1-intl php7.1-readline php-xdebug

sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.1/cli/php.ini
sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.1/cli/php.ini
sudo sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.1/cli/php.ini
sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.1/cli/php.ini

apt-get install -y nginx php7.1-fpm

if [ -f /etc/nginx/sites-enabled/default ]; then
	rm /etc/nginx/sites-enabled/default
fi

if [ -f /etc/nginx/sites-available/default ]; then
	rm /etc/nginx/sites-available/default
fi
service nginx restart

# Setup Some PHP-FPM Options

echo "xdebug.remote_enable = 1" >> /etc/php/7.1/mods-available/xdebug.ini
echo "xdebug.remote_connect_back = 1" >> /etc/php/7.1/mods-available/xdebug.ini
echo "xdebug.remote_port = 9000" >> /etc/php/7.1/mods-available/xdebug.ini
echo "xdebug.max_nesting_level = 512" >> /etc/php/7.1/mods-available/xdebug.ini
echo "opcache.revalidate_freq = 0" >> /etc/php/7.1/mods-available/opcache.ini

sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.1/fpm/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.1/fpm/php.ini
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.1/fpm/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.1/fpm/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php/7.1/fpm/php.ini
sed -i "s/post_max_size = .*/post_max_size = 100M/" /etc/php/7.1/fpm/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.1/fpm/php.ini


# Disable XDebug On The CLI

sudo phpdismod -s cli xdebug

# Copy fastcgi_params to Nginx because they broke it on the PPA

cat > /etc/nginx/fastcgi_params << EOF
fastcgi_param	QUERY_STRING		\$query_string;
fastcgi_param	REQUEST_METHOD		\$request_method;
fastcgi_param	CONTENT_TYPE		\$content_type;
fastcgi_param	CONTENT_LENGTH		\$content_length;
fastcgi_param	SCRIPT_FILENAME		\$request_filename;
fastcgi_param	SCRIPT_NAME		\$fastcgi_script_name;
fastcgi_param	REQUEST_URI		\$request_uri;
fastcgi_param	DOCUMENT_URI		\$document_uri;
fastcgi_param	DOCUMENT_ROOT		\$document_root;
fastcgi_param	SERVER_PROTOCOL		\$server_protocol;
fastcgi_param	GATEWAY_INTERFACE	CGI/1.1;
fastcgi_param	SERVER_SOFTWARE		nginx/\$nginx_version;
fastcgi_param	REMOTE_ADDR		\$remote_addr;
fastcgi_param	REMOTE_PORT		\$remote_port;
fastcgi_param	SERVER_ADDR		\$server_addr;
fastcgi_param	SERVER_PORT		\$server_port;
fastcgi_param	SERVER_NAME		\$server_name;
fastcgi_param	HTTPS			\$https if_not_empty;
fastcgi_param	REDIRECT_STATUS		200;
EOF


# Set The Nginx & PHP-FPM User

sed -i "s/user www-data;/user www-data;/" /etc/nginx/nginx.conf
sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf

sed -i "s/user = www-data/user = www-data/" /etc/php/7.1/fpm/pool.d/www.conf
sed -i "s/group = www-data/group = www-data/" /etc/php/7.1/fpm/pool.d/www.conf

sed -i "s/listen\.owner.*/listen.owner = www-data/" /etc/php/7.1/fpm/pool.d/www.conf
sed -i "s/listen\.group.*/listen.group = www-data/" /etc/php/7.1/fpm/pool.d/www.conf
sed -i "s/;listen\.mode.*/listen.mode = 0666/" /etc/php/7.1/fpm/pool.d/www.conf

service nginx restart
service php7.1-fpm restart

# Add grimlock User To WWW-Data

usermod -a -G www-data www-data
id www-data
groups www-data

# Install debconf-utils

apt-get install -y debconf-utils

# Install MySQL

echo 'mysql-server mysql-server/root_password password password secret' | debconf-set-selections
echo 'mysql-server mysql-server/root_password_again password password secret' | debconf-set-selections

apt-get install -y mysql-server

# Configure MySQL Password Lifetime

echo "default_password_lifetime = 0" >> /etc/mysql/mysql.conf.d/mysqld.cnf

# Configure MySQL Remote Access

# config remote Access
echo '
[client]
user=root
password=secret

' >> /root/.my.cnf

chmod 0600 /root/.my.cnf

sed -i '/^bind-address/s/bind-address.*=.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO root@'0.0.0.0' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
service mysql restart

mysql --user="root" --password="secret" -e "CREATE USER '$domain_name'@'0.0.0.0' IDENTIFIED BY 'secret';"
mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO '$domain_name'@'0.0.0.0' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO '$domain_name'@'%' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
mysql --user="root" --password="secret" -e "FLUSH PRIVILEGES;"
mysql --user="root" --password="secret" -e "CREATE DATABASE $domain_name character set UTF8mb4 collate utf8mb4_bin;"
service mysql restart

# Add Timezone Support To MySQL

mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql --user=root --password=secret mysql

# Configure Supervisor

systemctl enable supervisor.service
service supervisor start

# Install phpmyadmin
echo "phpmyadmin phpmyadmin/internal/skip-preseed boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect" | debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean false" | debconf-set-selections

sudo apt-get -y install phpmyadmin

sudo ln -s /usr/share/phpmyadmin /usr/share/nginx/html

sudo apt -y install php-mcrypt php-mbstring

sudo service nginx restart
sudo service php7.1-fpm restart


#remove previous downloads
echo "=======Removing Old Wordpress============ \n"
if [ -f /var/www/latest.tar.gz ]; then
	cd /var/www/
	rm -f latest.tar.gz
else if [ -f /var/www/wordpress ]; then
	cd /var/www/
	rm -rf wordpress
fi

echo "=======Downloading Wordpress============"
# Download Wordpress
if [ -d /var/www/ ]; then
	cd /var/www/
	curl -O https://wordpress.org/latest.tar.gz
else
	mkdir -p /var/www/ && cd /var/www/
	curl -O https://wordpress.org/latest.tar.gz
fi

# Extract wordpress
echo "=======Extracting Wordpress============"

if [ -f /var/www/latest.tar.gz ]; then
	cd /var/www/
	tar xzvf latest.tar.gz
fi

echo "=======Remove Old Site Folder============"
if [ -d /var/www/$domain_name ]; then
	cd /var/www/
  rm -rf $domain_name
fi

# Rename the directzory name
echo "=======Renaming Wordpress Folder to $domain_name ============"
if [ -d /var/www/wordpress ]; then
	cd /var/www/
  mv wordpress $domain_name
fi


#Set permissions
echo "=======Changing Permissions on WP Folder============"
if [ -d /var/www/$domain_name ]; then
	sudo chmod -R 775 /var/www/$domain_name
	sudo chmod -R 775 /var/www/$domain_name/wp-content
fi

# Wordpress Salt
echo "=======Generating Wordpress Salt ============"
wp_salt = curl https://api.wordpress.org/secret-key/1.1/salt/

# create wp config file

echo "=======Creating wp-config.php file ============"
echo "

<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the
 * installation. You don't have to use the web site, you can
 * copy this file to wp-config.php and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * MySQL settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://codex.wordpress.org/Editing_wp-config.php
 *
 * @package WordPress
 */

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define('DB_NAME', $domain_name);

/** MySQL database username */
define('DB_USER', $domain_name);

/** MySQL database password */
define('DB_PASSWORD', 'secret');

/** MySQL hostname */
define('DB_HOST', 'localhost');

/** Database Charset to use in creating database tables. */
define('DB_CHARSET', 'utf8');

/** The Database Collate type. Don't change this if in doubt. */
define('DB_COLLATE', '');

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */

$wp_salt

/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
'$'table_prefix  = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the Codex.
 *
 * @link https://codex.wordpress.org/Debugging_in_WordPress
 */
define('WP_DEBUG', false);

/* That's all, stop editing! Happy blogging. */

/** Absolute path to the WordPress directory. */
if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) . '/');

/** Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');

" >> /var/www/$domain_name/wp-config.php

# remove config file
rm -f etc/nginx/sites-enabled/$domain_name.conf
rm -f etc/nginx/sites-available/$domain_name.conf

#Config file
echo "
server {
    listen 80;
    listen [::]:80;

    root /var/www/$domain_name;
    index index.php index.html index.htm;

    server_name $domain_name.com;

    location / {
        try_files '$'uri '$'uri/ /index.php?'$'query_string;
    }

    location /phpmyadmin {
            root /usr/share/nginx/html;
            location ~ ^/phpmyadmin/(.+\.php)$ {
                    try_files '$'uri =404;
                    root /usr/share/nginx/html;
                    fastcgi_pass unix:/run/php/php7.1-fpm.sock;
                    fastcgi_index index.php;
                    fastcgi_param SCRIPT_FILENAME '$'document_root$fastcgi_script_name;
                    include /etc/nginx/fastcgi_params;
            }
            location ~* ^/phpmyadmin/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))$ {
                    root /usr/share/nginx/html;
            }
    }

    location ~ \.php$ {
        try_files '$'uri /index.php =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php7.1-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME '$'document_root'$'fastcgi_script_name;
        include fastcgi_params;
    }
} " >>/etc/nginx/sites-available/$domain_name.conf

ln -s /etc/nginx/sites-available/$domain_name.conf etc/nginx/sites-enabled/$domain_name.conf

# Clean Up
sudo service nginx restart
apt-get -y autoremove
apt-get -y clean
