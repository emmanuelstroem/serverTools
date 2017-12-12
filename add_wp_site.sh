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

# Update Software Sources
echo "======= Applying Updates for Software Sources ============"
sudo apt-get update


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

echo "======= Removing PHPmyadmin Symlink ============"
if [ -d /usr/share/nginx/html/phpmyadmin ]; then
	rm -rf /usr/share/nginx/html/phpmyadmin
fi

echo "======= Creating PHPmyadmin Symlink ============"
sudo ln -s /usr/share/phpmyadmin /usr/share/nginx/html

echo "======= Restarting Nginx and PHP-fpm ============"
sudo service nginx restart
sudo service php7.1-fpm restart


#remove previous downloads
echo "=======Removing Old Wordpress============ \n"
echo "....nothing here..."
if [ -f /var/www/latest.tar.gz ]; then
	cd /var/www/
	rm -rf latest.tar.gz
fi

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

echo "======= Add site to hosts file ============"
sudo cat > /etc/hosts << EOF
172.104.247.123     $domain_name.$domain_extension
EOF

# Clean Up
echo "======= Restarting NGINX ============"
sudo service nginx restart

echo "======= Cleaning Up ============"
sudo apt-get -y autoremove
sudo apt-get -y clean
