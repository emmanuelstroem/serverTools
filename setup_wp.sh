#!/bin/sh
export DEBIAN_FRONTEND="noninteractive"

# command line arguments
if [ $# -gt 0 ]; then
    echo "Your command line contains $# arguments"
    domain_name="$1"
    domain_extension="$2"
    db_user="$3"
    db_pass="$4"
else
    echo "Your command line contains no arguments"
		domain_name="emmanuelopio"
    domain_extension=".com"
    db_user="$domain_name"
    db_pass="secret"
fi

echo "======= Got Domain Name ============"
echo $domain_name.$domain_extension

# update packages
echo "======= Updating Ubuntu ============"
sudo apt-get update

# Force Locale
echo "======= Setting Locale ============"
echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
sudo locale-gen en_US.UTF-8

echo "======= Installing software-properties-common and curl ============"
sudo apt-get install -y software-properties-common curl

echo "======= Adding Software Sources for PHP and Nginx ============"
sudo apt-add-repository ppa:ondrej/php -y
sudo apt-add-repository ppa:nginx/development -y

echo "======= Add Certbot to Software Sources ============"
sudo apt-get install software-properties-common
sudo add-apt-repository ppa:certbot/certbot

# Update Software Sources
echo "======= Applying Updates for Software Sources ============"
sudo apt-get update

echo "======= Installing System Dependencies ============"
sudo apt-get install -y build-essential dos2unix gcc git libmcrypt4 libpcre3-dev ntp unzip make python2.7-dev python-pip re2c supervisor unattended-upgrades whois vim libnotify-bin pv cifs-utils

echo "======= Installing PHP Dependencies ============"
sudo apt-get install -y php7.1-cli php7.1-dev \
php7.1-pgsql php7.1-sqlite3 php7.1-gd \
php7.1-curl php7.1-memcached \
php7.1-imap php7.1-mysql php7.1-mbstring \
php7.1-xml php7.1-zip php7.1-bcmath php7.1-soap \
php7.1-intl php7.1-readline php-xdebug

echo "======= Configuring PHP.ini ============"
sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.1/cli/php.ini
sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.1/cli/php.ini
sudo sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.1/cli/php.ini
sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.1/cli/php.ini

echo "======= Installing NGINX and PHP-fpm ============"
sudo apt-get install -y nginx php7.1-fpm

if [ -f /etc/nginx/sites-enabled/default ]; then
	sudo rm /etc/nginx/sites-enabled/default
fi

if [ -f /etc/nginx/sites-available/default ]; then
	sudo rm /etc/nginx/sites-available/default
fi

echo "======= Restarting NGINX ============"
sudo service nginx restart

# Setup Some PHP-FPM Options
echo "======= Setting up PHP-fpm Options ============"

sudo echo "xdebug.remote_enable = 1" >> /etc/php/7.1/mods-available/xdebug.ini
sudo echo "xdebug.remote_connect_back = 1" >> /etc/php/7.1/mods-available/xdebug.ini
sudo echo "xdebug.remote_port = 9000" >> /etc/php/7.1/mods-available/xdebug.ini
sudo echo "xdebug.max_nesting_level = 512" >> /etc/php/7.1/mods-available/xdebug.ini
sudo echo "opcache.revalidate_freq = 0" >> /etc/php/7.1/mods-available/opcache.ini

sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.1/fpm/php.ini
sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.1/fpm/php.ini
sudo sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.1/fpm/php.ini
sudo sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.1/fpm/php.ini
sudo sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php/7.1/fpm/php.ini
sudo sed -i "s/post_max_size = .*/post_max_size = 100M/" /etc/php/7.1/fpm/php.ini
sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.1/fpm/php.ini


# Disable XDebug On The CLI
echo "======= Disabling XDebug in CLI ============"
sudo phpdismod -s cli xdebug

# Copy fastcgi_params to Nginx because they broke it on the PPA
echo "======= Creating NGINX fastcgi_params ============"
sudo cat > /etc/nginx/fastcgi_params << EOF
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
echo "======= Setting NGINX and PHP-fpm User ============"
sudo sed -i "s/user www-data;/user www-data;/" /etc/nginx/nginx.conf
sudo sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf

sudo sed -i "s/user = www-data/user = www-data/" /etc/php/7.1/fpm/pool.d/www.conf
sudo sed -i "s/group = www-data/group = www-data/" /etc/php/7.1/fpm/pool.d/www.conf

sudo sed -i "s/listen\.owner.*/listen.owner = www-data/" /etc/php/7.1/fpm/pool.d/www.conf
sudo sed -i "s/listen\.group.*/listen.group = www-data/" /etc/php/7.1/fpm/pool.d/www.conf
sudo sed -i "s/;listen\.mode.*/listen.mode = 0666/" /etc/php/7.1/fpm/pool.d/www.conf

echo "======= Restarting NGINX and PHP-fpm ============"
sudo service nginx restart
sudo service php7.1-fpm restart

# Add grimlock User To WWW-Data
echo "======= Adding www-data user  ============"
sudo usermod -a -G www-data www-data
id www-data
groups www-data

# Install debconf-utils
echo "======= Installing debconf-utils ============"
sudo apt-get install -y debconf-utils

# apt-get -y install zsh htop

# Install MySQL
echo "======= Setting MySQL default root password ============"
# echo 'mysql-server mysql-server/root_password password password secret' | debconf-set-selections
# echo 'mysql-server mysql-server/root_password_again password password secret' | debconf-set-selections
sudo echo "mysql-server mysql-server/root_password password secret" | sudo debconf-set-selections
sudo echo "mysql-server mysql-server/root_password_again password secret" | sudo debconf-set-selections

# Update the information needed for APT by adding the 5.7 repository and updating `apt-get
#
# sudo apt-key adv --keyserver pgp.mit.edu --recv-keys 5072E1F5
# cat <<- EOF > /etc/apt/sources.list.d/mysql.list
# deb http://repo.mysql.com/apt/ubuntu/ trusty mysql-5.7
# EOF

echo "======= Installing MySQL ============"
sudo apt-get install -y mysql-server-5.7

# Configure MySQL Remote Access
echo "======= Removing any previous /root/.my.cnf ============"
if [ -f /root/.my.cnf ]; then
	sudo rm -f /root/.my.cnf
fi

echo "======= Creating /root/.my.cnf ============"
sudo echo '
[client]
user=root
password=secret

' >> /root/.my.cnf

echo "======= Setting Permissions of /root/.my.cnf to 0600 ============"
sudo chmod 0600 /root/.my.cnf

# Secure MySQL Install
echo "======= Running mysql_secure_installation ============"
echo "======= Updating MySQL Root User ============"
sudo mysql -u root -e 'USE mysql; UPDATE `user` SET `Host`="%" WHERE `User`="root" AND `Host`="localhost"; DELETE FROM `user` WHERE `Host` != "%" AND `User`="root"; FLUSH PRIVILEGES;'

echo "======= Setting MySQL Port in /etc/mysql/mysql.conf.d/mysqld.cnf ============"
sudo sed -i 's/127\.0\.0\.1/0\.0\.0\.0/g' /etc/mysql/mysql.conf.d/mysqld.cnf


# Configure MySQL Password Lifetime

echo "default_password_lifetime = 0" >> /etc/mysql/mysql.conf.d/mysqld.cnf


echo "======= Setting MySQL Bind Address to 0.0.0.0 ============"
sudo sed -i '/^bind-address/s/bind-address.*=.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

echo "======= Creating MySQL Root User ============"
sudo mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO root@'0.0.0.0' IDENTIFIED BY 'secret' WITH GRANT OPTION;"

echo "======= Restarting MySQL ============"
sudo service mysql restart

echo "======= Creating MySQL $domain_name User ============"
sudo mysql --user="root" --password="secret" -e "CREATE USER '$db_user'@'0.0.0.0' IDENTIFIED BY '$db_pass';"
sudo mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO '$db_user'@'0.0.0.0' IDENTIFIED BY '$db_pass' WITH GRANT OPTION;"
sudo mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO '$db_user'@'%' IDENTIFIED BY '$db_pass' WITH GRANT OPTION;"

echo "======= Flushing Privileges MySQL ============"
sudo mysql --user="root" --password="secret" -e "FLUSH PRIVILEGES;"

echo "======= Creating DB $domain_name ============"
sudo mysql --user="root" --password="secret" -e "CREATE DATABASE $domain_name character set UTF8mb4 collate utf8mb4_bin;"

echo "======= Restarting MySQL ============"
sudo service mysql restart

echo "======= Flushing Privileges MySQL ============"
sudo mysql --user="root" --password="secret" -e "FLUSH PRIVILEGES;"

echo "======= Restarting MySQL ============"
sudo service mysql restart

# Add Timezone Support To MySQL

mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql --user=root --password=secret mysql

# Configure Supervisor
echo "======= Enabling and Starting Supervisor ============"
sudo systemctl enable supervisor.service
sudo service supervisor start

# Install phpmyadmin
echo "======= Installing PHPmyadmin ============"
sudo echo "phpmyadmin phpmyadmin/internal/skip-preseed boolean true" | debconf-set-selections
sudo echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none" | debconf-set-selections
# echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect" | debconf-set-selections
sudo echo "phpmyadmin phpmyadmin/dbconfig-install boolean false" | debconf-set-selections



sudo apt-get -y install phpmyadmin

echo "======= Removing PHPmyadmin Symlink ============"
if [ -d /usr/share/nginx/html/phpmyadmin ]; then
	rm -rf /usr/share/nginx/html/phpmyadmin
fi

echo "======= Creating PHPmyadmin Symlink ============"
sudo ln -s /usr/share/phpmyadmin /usr/share/nginx/html

sudo apt -y install php-mcrypt php-mbstring

echo "======= Restarting Nginx and PHP-fpm ============"
sudo service nginx restart
sudo service php7.1-fpm restart


#remove previous downloads
echo "=======Removing Old Wordpress============ \n"
echo "....nothing here..."
# if [ -f /var/www/wordpress ]; then
# 	cd /var/www/
# 	rm -rf wordpress
# fi

echo "=======Downloading Wordpress============"
# Download Wordpress
if [ -d /var/www/ ]; then
	cd /var/www/
	curl -O https://wordpress.org/latest.tar.gz
fi

# Extract wordpress
echo "=======Extracting Wordpress============"

if [ -f /var/www/latest.tar.gz ]; then
	cd /var/www/
	tar xzvf latest.tar.gz
fi

# Rename the directzory name
# echo "=======Renaming wp-admin Folder to $domain_name ============"
# if [ -d /var/www/wordpress/wp-admin ]; then
# 	mv /var/www/wordpress/wp-admin/ manage
# fi

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

  echo "======= Creating .well-known/acme-challenge for SSL ============"
  mkdir -p /var/www/$domain_name/.well-known/acme-challenge

  sudo chmod -R 775 /var/www/$domain_name
	sudo chmod -R 775 /var/www/$domain_name/wp-content
fi

#Set permissions
echo "======= Chown -R www-data:www-data /var/www/$domain_name/wp-content ============"
sudo chown -R www-data:www-data /var/www/$domain_name/wp-content/

# Wordpress Salt
echo "=======Generating Wordpress Salt ============"
wp_salt="$(curl https://api.wordpress.org/secret-key/1.1/salt/)"
# wp_salt=`curl https://api.wordpress.org/secret-key/1.1/salt/`
echo "SALT: $wp_salt"

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
define('DB_NAME', '$domain_name');

/** MySQL database username */
define('DB_USER', '$db_user');

/** MySQL database password */
define('DB_PASSWORD', '$db_pass');

/** MySQL hostname */
define('DB_HOST', 'localhost');

/** Database Charset to use in creating database tables. */
define('DB_CHARSET', 'utf8');

/** The Database Collate type. Don't change this if in doubt. */
define('DB_COLLATE', '');

/** Permissions */
/** define( ‘FS_CHMOD_DIR’, ( 0755 & ~ umask() ) ); */
/** define( ‘FS_CHMOD_FILE’, ( 0644 & ~ umask() ) ); */

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
\$table_prefix  = 'wp_';

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

# fix Wordpress File permissions
echo "======= Change permissions of WP Files ============"
sudo find /var/www/$domain_name/ -type f -exec chmod 644 {} +

# fix Wordpress Folder permissions
echo "======= Change permissions of WP Folders ============"
sudo find /var/www/$domain_name/ -type d -exec chmod 755 {} +

echo "======= Change permissions of wp-config ============"
chmod 0644 /var/www/$domain_name/wp-config.php

# remove config file
echo "======= Removing NGINX Website Conf Files ============"
rm -f /etc/nginx/sites-enabled/$domain_name.conf
rm -f /etc/nginx/sites-available/$domain_name.conf

#Config file
echo "======= Creating NGINX $domain_name.conf ============"
echo "
	server {
    listen 80;
    listen [::]:80;

    root /var/www/$domain_name;
    index index.php index.html index.htm;

    server_name $domain_name.$domain_extension;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location /phpmyadmin {
            root /usr/share/nginx/html;
            location ~ ^/phpmyadmin/(.+\.php)$ {
                    try_files \$uri =404;
                    root /usr/share/nginx/html;
                    fastcgi_pass unix:/run/php/php7.1-fpm.sock;
                    fastcgi_index index.php;
                    fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
                    include /etc/nginx/fastcgi_params;
            }
            location ~* ^/phpmyadmin/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))$ {
                    root /usr/share/nginx/html;
            }
    }

    location ~ \.php$ {
        try_files \$uri /index.php =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php7.1-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
} " >>/etc/nginx/sites-available/$domain_name.conf

echo "======= Creating Symlink for config file ============"
ln -s /etc/nginx/sites-available/$domain_name.conf /etc/nginx/sites-enabled/

# Clean Up
echo "======= Restarting NGINX ============"
sudo service nginx restart

echo "======= Cleaning Up ============"
sudo apt-get -y autoremove
sudo apt-get -y clean
