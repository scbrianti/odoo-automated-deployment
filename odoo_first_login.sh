
# Third phase
# Install PostgreSQL and create odoo user
sudo apt-get install postgresql --assume-yes
sudo su postgres sh -c "createuser -d -A $(whoami)"

# Remove second phase setup in cron
touch cron-empty
crontab -u odoo cron-empty

# Clone Odoo
cd ~
git clone https://github.com/mcb30/odoo.git --depth 20 --branch import

# Clone project
cd ~
git clone "$unipart_username"@git.unipart.io:/home/scm/"$project_repo_name".git

# Clone second repo if set
if test "$mobile_project_repo_name" != ""; then
	echo "Clone mobile from git"
	cd ~
	git clone "$unipart_username"@git.unipart.io:/home/scm/"$mobile_project_repo_name".git
fi

# Create Odoo 10 addon symlinks
mkdir -p ~/.local/share/Odoo/addons/10.0
sudo ln -sf ~/"$project_repo_name"/odoo_addons/"$project_repo_name" ~/.local/share/Odoo/addons/10.0/
sudo ln -sf ~/"$project_repo_name"/odoo_addons"$project_repo_name"_import ~/.local/share/Odoo/addons/10.0/
sudo ln -sf ~/"$project_repo_name"/odoo_addons/print ~/.local/share/Odoo/addons/10.0/
sudo ln -sf ~/"$project_repo_name"/odoo_addons/edi ~/.local/share/Odoo/addons/10.0/

# Install python packages
sudo apt-get --assume-yes install python-passlib python-werkzeug python-lxml \
python-dateutil python-tz python-babel python-psycopg2 python-yaml \
python-pychart python-reportlab python-mako python-psutil \
python-jinja2 python-docutils python-xlrd python-pypdf python-xlwt \
python-decorator python-requests python-paramiko python-psycogreen \
python-gevent python-ply node-less wkhtmltopdf apache2 php7.0 \
libapache2-mod-php7.0 php7.0-xmlrpc xfonts-75dpi

# Update wkhtmltopdf
sudo dpkg -i wkhtmltox-0.12.2_linux-trusty-amd64.deb

# Setup Apache mods
sudo /etc/init.d/apache2 start
sudo update-rc.d apache2 defaults
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod proxy_ajp
sudo a2enmod rewrite
sudo a2enmod deflate
sudo a2enmod headers
sudo a2enmod proxy_balancer
sudo a2enmod proxy_connect
sudo a2enmod proxy_html

# Move and amend Apache .conf files
sudo mv vm_ip_address.conf /etc/apache2/sites-available/"$vm_ip_address".conf
sudo mv vm_ip_address-mobile.conf /etc/apache2/sites-available/"$vm_ip_address"-mobile.conf
sudo sed -i -e 's/vm_ip_address/'"$vm_ip_address"'/g' /etc/apache2/sites-available/"$vm_ip_address".conf
sudo sed -i -e 's/vm_ip_address/'"$vm_ip_address"'/g' /etc/apache2/sites-available/"$vm_ip_address"-mobile.conf

# Remove default Apache index and replace with redirect
sudo rm /var/www/html/index.html
sudo mv ~/index.html /var/www/html/index.html
sudo sed -i -e 's/vm_ip_address/'"$vm_ip_address"'/g' /var/www/html/index.html

# Make vhost directories
sudo mkdir /var/www/vhosts
sudo mkdir /var/www/vhosts/"$vm_ip_address"
sudo mkdir /var/www/vhosts/"$vm_ip_address"/httpdocs

# Enable main and mobile sites, and disable default
sudo a2ensite "$vm_ip_address"
sudo a2ensite "$vm_ip_address"-mobile
sudo a2dissite 000-default

# Setup odoo as service
#setup

# Make manual script executable for dev
sudo chmod +x ~/run_odoo.sh

# Update mobile config.php file
sudo mv ~/config.php ~/mclaren/mobile/config.php

# Load changes into Apache
sudo service apache2 reload

# Start Odoo service and wait (first time running)
#sudo start
sleep 5m

# Stop Odoo service, drop the db and restore the one provided
#sudo stop
sleep 30s
dropdb odoo

if [ ! -f ~/*.gz ]; then
	gunzip -ck *.gz | psql postgres
else
	bzcat *.bz2 | psql postgres
fi
	
# Start Odoo with restored db
#sudo start

# Tidy up! #messybastard
sudo rm *.bz2 && sudo rm *.gz
sudo rm wkhtmltox-0.12.2_linux-trusty-amd64.deb
sudo rm odoo_auto_install.sh
sudo rm cron-empty
sudo rm db_copy.sh

# Script completed!
sudo touch ~/setup_completed
