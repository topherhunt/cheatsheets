
echo "Provisioning from Vagrantfile script as user: `whoami`"
echo "This will take a few minutes."

# Basic / common packages
sudo apt-get update
sudo apt-get install -y git make unzip

echo "Installing Mysql..."
sudo debconf-set-selections <<< 'mysql-server-5.5 mysql-server/root_password password rootpass'
sudo debconf-set-selections <<< 'mysql-server-5.5 mysql-server/root_password_again password rootpass'
sudo apt-get install -y mysql-server-5.5
# Now set the mysql root pw back to blank
mysql -u root --password=rootpass --database='mysql' --execute="UPDATE user SET Password=PASSWORD('') WHERE User='root'; FLUSH PRIVILEGES;"
sleep 1
sudo service mysql restart

# Set up dummy databases from SQL dump
mysql -u root --execute="CREATE DATABASE reservesdirect; CREATE DATABASE reservesdirect_test;"
mysql -u root --database=reservesdirect < /vagrant/vagrant_files/reservesdirect_smith.sql
mysql -u root --database=reservesdirect_test < /vagrant/vagrant_files/reservesdirect_smith.sql

echo "Installing PHP..."
# Packages required for PHP and Mysql extensions to be built properly
# Should be installed BEFORE php but AFTER mysql
# See http://stackoverflow.com/a/29173314/1729692
sudo apt-get install -y libxml2 libxml2-dev apache2 php5 php5-common php5-cli php5-mysql php5-gd php5-mcrypt php5-curl libapache2-mod-php5 php5-xmlrpc libapache2-mod-fastcgi build-essential php5-dev libbz2-dev libmysqlclient-dev libxpm-dev libmcrypt-dev libcurl4-gnutls-dev libxml2-dev libjpeg-dev libpng12-dev

cd ~ # I should already be here, but just in case
# PHPfarm gives you a one-line setup to install any php version
# though maybe it would be easier to use the source: http://museum.php.net/php5/
git clone https://github.com/cweiske/phpfarm
cd phpfarm/src
# Custom options (add flags for mysql extensions etc.)
cp /vagrant/vagrant_files/phpfarm_options.sh ~/phpfarm/src/options.sh
./compile.sh 5.3.3

installed_correctly=`~/phpfarm/inst/php-5.3.3/bin/php -i | grep mysql | wc -l`
if [ $installed_correctly -gt 0 ]
then
  echo "PHP v5.3.3 installed correctly."
else
  echo "FAILED to install PHP v5.3.3. You'll need to install it manually."
fi

# Add the login script
echo "source /vagrant/vagrant_files/login.sh" >> /home/vagrant/.bashrc

echo "Provisioning is complete. Type 'vagrant ssh' to log in."
