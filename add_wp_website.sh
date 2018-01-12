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
apt-get -o Acquire::ForceIPv4=true update


echo "======= Creating MySQL Root User ============"
mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO root@'0.0.0.0' IDENTIFIED BY 'secret' WITH GRANT OPTION;"

echo "======= Restarting MySQL ============"
service mysql restart

echo "======= Creating MySQL $domain_name User ============"
mysql --user="$db_user" --password="secret" -e "CREATE USER '$domain_name'@'0.0.0.0' IDENTIFIED BY 'secret';"
mysql --user="$db_user" --password="secret" -e "GRANT ALL ON *.* TO '$domain_name'@'0.0.0.0' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
mysql --user="$db_user" --password="secret" -e "GRANT ALL ON *.* TO '$domain_name'@'%' IDENTIFIED BY 'secret' WITH GRANT OPTION;"

echo "======= Flushing Privileges MySQL ============"
mysql --user="root" --password="secret" -e "FLUSH PRIVILEGES;"

echo "======= Creating DB $domain_name ============"
mysql --user="root" --password="secret" -e "CREATE DATABASE $domain_name character set UTF8mb4 collate utf8mb4_bin;"

echo "======= Restarting MySQL ============"
service mysql restart

echo "======= Flushing Privileges MySQL ============"
mysql --user="root" --password="secret" -e "FLUSH PRIVILEGES;"

echo "======= Restarting MySQL ============"
service mysql restart

# Add Timezone Support To MySQL

mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql --user=root --password=secret mysql

# Configure Supervisor
echo "======= Enabling and Starting Supervisor ============"
systemctl enable supervisor.service
service supervisor start

# Install phpmyadmin
echo "======= Installing PHPmyadmin ============"
echo "phpmyadmin phpmyadmin/internal/skip-preseed boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect" | debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean false" | debconf-set-selections

sudo apt-get -y install phpmyadmin

echo "======= Removing PHPmyadmin Symlink ============"
if [ -d /usr/share/nginx/html/phpmyadmin ]; then
	rm -rf /usr/share/nginx/html/phpmyadmin
fi

echo "======= Creating PHPmyadmin Symlink ============"
sudo ln -s /usr/share/phpmyadmin /usr/share/nginx/html

sudo apt -y install php-mcrypt php-mbstring

# echo "======= Creating /etc/php/7.1/fpm/pool.d/$domain_name.conf ============"
# sudo echo '
# listen = /run/php/php7.1-fpm.sock
# pm = dynamic
# pm.max_children = 25
# pm.start_servers = 10
# pm.min_spare_servers = 5
# pm.max_spare_servers = 25
# pm.max_requests = 500
#
# ' >> /etc/php/7.1/fpm/pool.d/$domain_name.conf

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
define('DB_USER', '$domain_name');

/** MySQL database password */
define('DB_PASSWORD', 'secret');

/** MySQL hostname */
define('DB_HOST', 'localhost');

/** Database Charset to use in creating database tables. */
define('DB_CHARSET', 'utf8');

/** The Database Collate type. Don't change this if in doubt. */
define('DB_COLLATE', '');

/** Permissions */
/** define( ‘FS_CHMOD_DIR’, ( 0755 & ~ umask() ) ); */
/** define( ‘FS_CHMOD_FILE’, ( 0644 & ~ umask() ) ); */

/** Disable FTP for installing a theme */
define('FS_METHOD', 'direct');

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

    server_name $domain_name.$domain_extension *.$domain_name.$domain_extension;

    # logs
    access_log /var/log/nginx/$domain_name.$domain_extension-access.log;
    error_log /var/log/nginx/$domain_name.$domain_extension-error.log;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~*  \.(jpg|jpeg|png|gif|ico|css|js|pdf)$ {
        expires 7d;
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

# Add grimlock User To WWW-Data
echo "======= Adding www-data user  ============"
sudo usermod -aG www-data $USER

# Add grimlock User To WWW-Data
echo "======= Adding domain to /etch/hosts  ============"
ip_address=`ifconfig ${NET_IF} | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`

echo "
$ip_address		   $domain_name.$domain_extension
" >>/etc/hosts

echo "======= www-data owning the /var/www folder  ============"
sudo chown -R www-data:www-data /var/www
sudo chmod -R g+rwX /var/www

# Clean Up
echo "======= Restarting NGINX ============"
sudo service nginx restart

echo "======= Cleaning Up ============"
apt-get -y autoremove
apt-get -y clean
