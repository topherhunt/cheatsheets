# Provision script should have installed phpfarm 5.3.3 here
alias php-5-3-3='~/phpfarm/inst/php-5.3.3/bin/php'
alias b='tput bel; sleep 2'

echo "VM is accessible at 192.168.33.10 UN vagrant PW vagrant"
echo "The default PHP install is version 5.3.10."
echo "Access PHP 5.3.3 using the alias 'php-5-3-3'."
echo "Other PHP versions can be installed using PHPfarm like this:"
echo "> cd ~/phpfarm/src"
echo "> ./compile.sh 5.n.n"
echo "> ~/phpfarm/inst/php-5.n.n/bin/php -v"
echo ""

cd /vagrant
