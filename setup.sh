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
apt-get -y install emacs screen

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
cp ./configs/* ~/

# restart services
service ssh restart
