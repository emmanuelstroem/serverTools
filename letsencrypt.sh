#!/bin/sh
export DEBIAN_FRONTEND="noninteractive"

# command line arguments
if [ $# -gt 0 ]; then
    echo "Your command line contains $# arguments"
    domain_name="$1"
    domain_extension="$2"
    email="$3"

else
    echo "enter domain details in parameter"

fi

# Update OS
echo "======= Update OS ============"
sudo apt update && apt upgrade

echo "======= Add Certbot to Software Sources ============"
sudo apt-get install software-properties-common
sudo add-apt-repository ppa:certbot/certbot
sudo apt-get update

echo "======= install certbot ============"
sudo apt install python-certbot-nginx 

echo "======= create test url ============"
mkdir -p /var/www/$domain_name/.well-known/acme-challenge

echo "======= create directory for certificates ============"
mkdir -p /etc/letsencrypt/live/

echo "======= change permissions on /etc/letsencrypt/* to 0755 ============"
sudo chmod -R 0755 /etc/letsencrypt/

echo "======= generating certificate ============"
certbot certonly --webroot -w /var/www/$domain_name -d $domain_name.$domain_extension -m $email

echo "======= list domains ============"
ls /etc/letsencrypt/live/

echo "======= list certificates ============"
ls /etc/letsencrypt/live/$domain_name/

# sed -n "H;${x;s/^\n//;s/index.php .*$/ssl on;\n&/;p;}"
# sed -n "H;${x;s/^\n//;s/ssl on; .*$/ssl_certificate /etc/letsencrypt/live/$domain_name.$domain_extension/fullchain.pem;\n&/;p;}"
#
# sed "/index/a\
# ssl on; \r\
# \\ssl_certificate /etc/letsencrypt/live/$domain_name.$domain_extension/fullchain.pem; \
# \\ssl_certificate_key /etc/letsencrypt/live/$domain_name.$domain_extension/privkey.pem; \
# " /etc/nginx/sites-available/eopio.conf
#
# sed "/index/{s/.*/&\n
# ssl on; \
# ssl_certificate /etc/letsencrypt/live/$domain_name.$domain_extension/fullchain.pem; \
# ssl_certificate_key /etc/letsencrypt/live/$domain_name.$domain_extension/privkey.pem; \
#
# /;:a;n;ba}" /etc/nginx/sites-available/$domain_name.conf
#
#
# sed "/index/{s/.*/&\n
# ssl on; \
# ssl_certificate /etc/letsencrypt/live/$domain_name.$domain_extension/fullchain.pem; \
# ssl_certificate_key /etc/letsencrypt/live/$domain_name.$domain_extension/privkey.pem; \
#
# /;:a;n;ba}" /etc/nginx/sites-available/eopio.conf
