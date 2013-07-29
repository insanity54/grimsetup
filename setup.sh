#!/bin/bash

source ./settings.conf

# install commonly used programs
apt-get -y install screen emacs

# create administrative user, a home dir for that user, and set their shell.
useradd "$user" -m -s "$shell"


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

# create an ssh key
ssh-keygen -f ~/.ssh/id_rsa -P '' -t rsa

# *.rc configuration


# message to admin
echo -e "#\n#\n#  Please su to $user and then use passwd to set a user password. Also add an allowed host to /home/$user/.ssh/Allowed_Host\n#\n#"
