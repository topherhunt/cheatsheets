
echo "Provisioning from Vagrantfile script as user: `whoami`"
echo "This will take a few minutes."

sudo apt-get update

echo "Installing Mysql..."
sudo debconf-set-selections <<< 'mysql-server-5.5 mysql-server/root_password password rootpass'
sudo debconf-set-selections <<< 'mysql-server-5.5 mysql-server/root_password_again password rootpass'
sudo apt-get install -y mysql-server-5.5
# Now set the mysql root pw back to blank
mysql -u root -p rootpass --database='mysql' --execute="UPDATE user SET Password=PASSWORD('') WHERE User='root'; FLUSH PRIVILEGES;"
sleep 1
sudo service mysql restart

# Set up dummy databases from SQL dump
mysql -u root --execute="CREATE DATABASE reservesdirect; CREATE DATABASE reservesdirect_test;"
mysql -u root --database=reservesdirect < /vagrant/vagrant_files/reservesdirect_smith.sql
mysql -u root --database=reservesdirect_test < /vagrant/vagrant_files/reservesdirect_smith.sql

echo "Installing PHP..."
# Packages required for PHP and Mysql extensions to be built properly
# See http://stackoverflow.com/a/29173314/1729692
sudo apt-get install -y libxml2 libxml2-dev make apache2 php5 php5-common php5-cli php5-mysql php5-gd php5-mcrypt php5-curl libapache2-mod-php5 php5-xmlrpc libapache2-mod-fastcgi build-essential php5-dev libbz2-dev libmysqlclient-dev libxpm-dev libmcrypt-dev libcurl4-gnutls-dev libxml2-dev libjpeg-dev libpng12-dev
# Download latest PHP 5.3 from http://in1.php.net/releases/
# wget http://us1.php.net/get/php-5.3.29.tar.bz2/from/this/mirror
# tar -xvf mirror # to folder: php-5.3.29
# cd php-5.3.29
# # Configure and compile PHP
# ./configure --with-mysql=/usr/bin/mysql --with-mysqli
# make
# sudo make install
# # If PHP was installed correctly, `php -i | grep mysql` will display lots of lines about the mysql and mysqli extensions
# # Copy over default php.ini config (mysqli extension enabled)
# sudo cp /vagrant/vagrant_files/php.ini /usr/local/lib/php/php.ini
# install mysqli support
# sudo apt-get -y install php5-mysqlnd

# Install the login script
echo "source /vagrant/vagrant_files/login.sh" >> /home/vagrant/.bashrc
echo "Provisioning is complete. Type 'vagrant ssh' to log in."
