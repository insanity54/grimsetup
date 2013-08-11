#!/bin/bash

if [ $(whoami) != root ]; then
    echo Please run this script using sudo
    exit
fi

bindir="$(dirname "$(readlink -fn "$0")")"
cd "$bindir"

source ./settings.conf

# use this script on a freshly deployed vps.
#   * run as a newly created administrative user with a home directory.
#   * run with root permissions but don't run as root.
#   * installs commonly used programs
#   * loads grimtech customized *.rc files,
#   * sets up basic ssh security settings

##########################################
#                                        #
#                WARNING                 #
#                                        #
##########################################

# this script locks root user out of ssh and disables clear text passwords.


# install commonly used programs
sudo apt-get update
apt-get -y install emacs screen unzip

# make tmp dir in home dir
mkdir ~/tmp
chown "$user":"$user" ~/tmp

# set up ssh
# create a string of allowed ssh users
users="$user"
for u in "${ssh_allowed_users[@]}"
do
  users="$users $u"
done

# find out if AllowUsers is already listed in sshd_config
if grep -q AllowUsers "$sshconf"; then

  # @todo if ran twice, this script keeps adding the same names to this line
  # add users to end of users already in the file
  sed -i "s/AllowUsers.*/& $users/g" "$sshconf"

else
  echo "AllowUsers $users" >> "$sshconf"
fi

# disallow root login via ssh
sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' "$sshconf"

# disable clear text passwords
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' "$sshconf"

# create authorized_keys file
touch "$sshauthkeys"
chown "$user":"$user" "$sshauthkeys"

# *.rc configuration
cp -r ./rc/. ~/
cp -r ./rc/. /root/
chown -R "$user":"$user" ~/rc

# .gitignore
cp ./gitconf/.gitignore_global ~/
chown "$user":"$user" ./gitconf/.gitignore_global


# LAMP stack
apt-get -y install apache2 mysql-server php5 libapache2-mod-php5 php5-xsl php5-gd php-pear libapache2-mod-auth-mysql php5-mysql php5-suhosin
# sed -i 's/; extension=mysql.so/extension=mysql\.so/g' /etc/php5/apache2/php.ini # dunno if we need this

# Apache Config
echo 'ServerName localhost' >> /etc/apache2/apache2.conf
mkdir /srv
cp /etc/apache2/sites-available/{default, "$sitename"}
ln -s /etc/apache2/sites-available/"$sitename" /etc/apache2/sites-enabled/015-"$sitename"
sed -i "s|/var/www|/srv/$sitename/wordpress|g" /etc/apache2/sites-available/"$sitename"
sed -i "s/webmaster@localhost/$webmaster/g" /etc/apache2/sites-available/"$sitename"
sed -i "/DocumentRoot/ i\ \tServerName $servername" /etc/apache2/sites-available/"$sitename"
sed -i "/DocumentRoot/ i\ \tServerAlias $serveralias" /etc/apache2/sites-available/"$sitename"

# MySQL
#mysql_install_db  # I don't think we need to run this
echo -e "[mysqld]\nlog-error = /var/log/mysql/mysql.err" > /etc/mysql/conf.d/grimtech.cnf
mysql_secure_installation

# Wordpress
cd /tmp
wget http://wordpress.org/latest.tar.gz
tar xvf latest.tar.gz
mkdir /srv/"$sitename"
mv wordpress /srv/"$sitename"/
chown -R www-data:www-data /srv

# restart services
service apache2 restart
service ssh restart

