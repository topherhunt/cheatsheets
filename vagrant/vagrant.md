_*TODO: This is cluttered and probably has lots of duplicates. Clean it up.*_

## Basics

- `vagrant init ubuntu/xenial64`
- `vagrant up`
- `vagrant ssh`
- Now you're in a brand new Ubuntu VM. Do any additional install and add it to a provisioning shell script in the generated Vagrantfile.
- You can put your provisioning commands in a dedicated file and point to it like this: `config.vm.provision "shell", path: "./vagrant_files/provision.sh", privileged: false`. **Disable privileged mode** so the script runs as the `vagrant` user rather than `root` (sudo still works fine).
- Vagrant VMs have slow performance by default. You can tune performance, see these guides:
  - https://stefanwrobel.com/how-to-make-vagrant-performance-not-suck
  - http://stackoverflow.com/questions/31742264/php-on-vagrant-virtualbox-on-linux


## Packaging up a box

Instead of expecting each user to download a base box then run the full setup script which can be time-consuming, you can set up the box (manually or via script) then package it

Steps:

  * Init a VM from a base box
  * Set it up the way you want, possibly saving the steps in a bash script for reproducibility later
  * Exit and halt the VM
  * `vagrant package --output my_box_name` - this takes a long time, then creates `my_box_name.box`
  * Upload `my_box_name.box` to S3
  * In your final Vagrantfile, specify the box name and url where it can be downloaded. Then whenever someone calls `vagrant up`, they'll download this box and start up a VM in identical state.

```
config.vm.box = 'NAME'
config.vm.box_url = 'https://s3.amazonaws.com/BUCKET/vagrant/NAME.box'
```

Thanks to: https://stefanwrobel.com/how-to-make-vagrant-performance-not-suck.


## Rails

By default, a Rails dev server only binds to `localhost`, but in Vagrant you need to listen for _external_ incoming connections. Fix this (in Rails 5) by setting `HOST=0.0.0.0`; this will cause Rails to listen for incoming requests, not just local ones.


## Mysql install & setup

Mysql is complicated by a wizard install. You need to set a *non-blank* root_password and root_password_again value in order to skip the wizard.

```
sudo debconf-set-selections <<< 'mysql-server-5.5 mysql-server/root_password password rootpass'
sudo debconf-set-selections <<< 'mysql-server-5.5 mysql-server/root_password_again password rootpass'
sudo apt-get install -y mysql-server-5.5 php5-mysql
# Now set the mysql root pw back to blank
mysql --user=root --password=rootpass --database='mysql' --execute="UPDATE user SET Password=PASSWORD('') WHERE User='root'; FLUSH PRIVILEGES;"
sleep 1
sudo service mysql restart
```

Setting up databases:

```
# Set up dummy databases from SQL dump
mysql --user=root --execute="CREATE DATABASE reservesdirect; CREATE DATABASE reservesdirect_test;"
mysql --user=root --database=reservesdirect < /vagrant/vagrant_files/reservesdirect_smith.sql
mysql --user=root --database=reservesdirect_test < /vagrant/vagrant_files/reservesdirect_smith.sql
```

## Postgres install & setup

Postgres is tricky because of ***

```
# Ubuntu + Postgres + Rails = locale nightmares. See http://crohr.me/journal/2014/postgres-rails-the-chosen-lc-ctype-setting-requires-encoding-latin1.html
echo '
LC_ALL="en_US.UTF-8"
LANG="en_US.UTF-8"
' | sudo tee /etc/default/locale
# Apply the new locale settings to this shell session
. /etc/default/locale
echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
# Install Postgresql 9.4 (the default repositories are stuck with a way older
# version for now; we need 9.4+ for JSON data type support)
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install libpq-dev postgresql-9.4
sudo -u postgres psql -d postgres -c "CREATE ROLE vagrant SUPERUSER CREATEDB LOGIN;"
createdb # creates a dummy `vagrant` db, required for vagrant user to login
```

## Install RVM, Ruby, and Bundler

```
# Installing RVM...
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
curl -L https://get.rvm.io | bash -s stable
source /home/vagrant/.rvm/scripts/rvm
# Installing Ruby 2.2.0...
rvm install 2.2.0
rvm use 2.2.0 --default
echo "gem: --no-ri --no-rdoc" > ~/.gemrc
gem install bundler
```
