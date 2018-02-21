

## Add Wordpress Site to Server
- SSH into your server
	- ssh username@server -p {port}

- Become Root
	- sudo su

- Execute script to add site (e.g: example.com)
	- curl https://raw.githubusercontent.com/emmanuelstroem/serverTools/master/add_wp_website.sh | bash -s {site_name} {site_extension} {db_user} {db_password}

	- site_name: name of your site. in this case _example_
	- site_extension: extension of your site. in this case _com_ (for .com)
	- db_user: is the username for the site to connect to WP database
	- db_password: is the password for that user


