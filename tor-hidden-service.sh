##
# for Ubuntu 16.04 Xenial Xerus
##

######################################
# INITIAL SERVER SETUP & HARDENING
######################################

# most VPS providers give you root user from the start
ssh root@1.2.3.4

# Update all the things
apt-get update && apt-get upgrade && apt-get autoremove

# Set timezone
dpkg-reconfigure tzdata
apt-get install ntp

# Create new user
adduser USERNAME
usermod -a -G sudo USERNAME

# passwordless sudo
visudo
  
  # add to very end of file
  USERNAME ALL=NOPASSWD: ALL

# copy over authorized_keys file to new user
mkdir /home/USERNAME/.ssh
cp .ssh/authorized_keys /home/USERNAME/.ssh/authorized_keys
chown -R USERNAME:USERNAME /home/USERNAME/.ssh
chmod 700 /home/USERNAME/.ssh
chmod 600 /home/USERNAME/.ssh/authorized_keys

logout
ssh USERNAME@1.2.3.4

##
# SSH configuration
##
sudo vi /etc/ssh/sshd_config

  # disable root login & password login
  PermitRootLogin no
  PasswordAuthentication no

sudo service ssh restart

##
# Firewall
##
sudo apt-get install ufw

# setup defaults
sudo ufw default deny incoming
sudo ufw default allow outgoing

# allow specific services
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow ntp

sudo apt-get install fail2ban
sudo service fail2ban start

######################################
# TOR INSTALLATION
######################################

# Add new package source & keys
sudo sh -c 'echo "deb http://deb.torproject.org/torproject.org xenial main" >> /etc/apt/sources.list.d/torproject.list'
gpg --keyserver keys.gnupg.net --recv 886DDD89
gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | sudo apt-key add -

# Refresh package list and install Tor
sudo apt-get update && sudo apt-get install tor deb.torproject.org-keyring

# torrc file configuration & hidden service key generation
sudo rm /etc/tor/torrc && sudo vi /etc/tor/torrc

  DataDirectory /var/lib/tor
  HiddenServiceDir /var/lib/tor/hidden_service/
  HiddenServicePort 80 127.0.0.1:80

sudo service tor reload

# get your hostname printed in Terminal
sudo cat /var/lib/tor/hidden_service/hostname

# (optional) show private key
sudo cat /var/lib/tor/hidden_service/private_key


######################################
# NGINX
######################################

# install nginx
sudo apt-get install nginx

# create folder hosting our hidden service files
sudo mkdir -p /var/www/hidden_service/

# set permissions
sudo chown -R www-data:www-data /var/www/hidden_service/ && sudo chmod 755 /var/www

# create server block
sudo vi /etc/nginx/sites-available/hidden_service

  server {
    listen   127.0.0.1:80;

    root /var/www/hidden_service/;
    index index.html index.htm;
    server_name YOURHOSTNAME.onion;
  }

# activate new site
sudo ln -s /etc/nginx/sites-available/hidden_service /etc/nginx/sites-enabled/hidden_service

# restart nginx to activate changes
sudo service nginx restart
