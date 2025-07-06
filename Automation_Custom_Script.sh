#!/bin/bash

# Set varibales"
USER_SCRIPT="tim"
HTTPS_REPO="https://github.com/timothymamo/nuc-dietpi-install.git"

HOME_USER="/home/${USER_SCRIPT}"

# Output variables
echo "Creating User: ${USER_SCRIPT}"
echo "Home directory for ${USER_SCRIPT}: ${HOME_USER}"
echo "Repo to clone: ${HTTPS_REPO}"

# Create super user with no password
adduser --disabled-password --gecos "" ${USER_SCRIPT}
usermod -aG sudo ${USER_SCRIPT}
passwd -d ${USER_SCRIPT}

# Copy the .ssh directory
echo "Copying SSH keys to user's home"
cp -r /root/.ssh/ ${HOME_USER}

# Install Packages
echo "Installing Packages"
apt update && apt upgrade
apt -y install \
  build-essential \
  vim \
  zsh \
  zsh-syntax-highlighting \
  zsh-autosuggestions \
  fonts-firacode

# Install starship
curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir /usr/bin

# Disable root ssh login
echo "Disabling Root login"
sed -i '/#PermitRootLogin prohibit-password/c\PermitRootLogin no' /etc/ssh/sshd_config

echo "# NAS
//192.168.1.120/data/ /home/tim/nas cifs _netdev,credentials=/home/tim/.smbcredentials,auto,vers=3.0,uid=1000,gid=1000 0 1
//192.168.1.120/NetBackup/ /mnt/backup/ cifs _netdev,credentials=/home/tim/.smbcredentials,auto,vers=3.0,uid=1000,gid=1000 0 1" >> /etc/fstab

# Creating rsync backup daily cron of config dir to NAS
echo "#\!/bin/zsh

HOME_USER=/home/tim
SRC=\${HOME_USER}/config
DEST=/mnt/backup/nuc/config

if [ ! -d \${DEST} ];then
	echo \"\${DEST} drive does not exist. Please mount the Drive \${DEST} before continuing\"
	exit -1
fi

rsync --rsh=\"ssh -i \${HOME_USER}/.ssh/id_ed25519\" --info=skip0 --archive --recursive --human-readable --no-links --delete \${SRC} \${DEST}" > /etc/cron.daily/rsync-nas
chmod +x /etc/cron.daily/rsync-nas

# Create a git directory and clone this repo
echo "Clone repo into ${HOME_USER}/git/nuc-dietpi-install/"
mkdir -p ${HOME_USER}/git/nuc-dietpi-install/
git clone ${HTTPS_REPO} ${HOME_USER}/git/nuc-dietpi-install/

# Create symlinks for all files
echo "Symlinking repo into ${HOME_USER}"
ln -s ${HOME_USER}/git/nuc-dietpi-install/* ${HOME_USER}
ln -s ${HOME_USER}/git/nuc-dietpi-install/.* ${HOME_USER}

# Remove .git directory so any changes within ${HOME} don't get pushed to the repo
echo "Symlinking .git directory within ${HOME_USER}"
rm -rf ${HOME_USER}/.git

# Create a ${HOME}/docker-compose/.env file from ${HOME}/docker-compose/.env-sample
echo "Creating a ${HOME_USER}/docker-compose/.env file"
cp -r ${HOME_USER}/docker-compose/.env-example ${HOME_USER}/docker-compose/.env

# Install Vim Plugin manager
curl -fLo ${HOME_USER}/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# Download vim plugins
mkdir -p ${HOME_USER}/.vim/plugged
git clone --depth 1 https://github.com/airblade/vim-gitgutter.git ${HOME_USER}/.vim/plugged/vim-gitgutter
git clone --depth 1 https://github.com/preservim/nerdtree.git ${HOME_USER}/.vim/plugged/nerdtree
git clone --depth 1 https://github.com/vim-airline/vim-airline.git ${HOME_USER}/.vim/plugged/vim-airline
git clone --depth 1 https://github.com/vim-airline/vim-airline-themes.git ${HOME_USER}/.vim/plugged/vim-airline-themes
git clone --depth 1 https://github.com/tpope/vim-unimpaired.git ${HOME_USER}/.vim/plugged/vim-unimpaired

# Restart sshd
echo "Restarting sshd"
systemctl restart sshd

# Setup Docker to have the appropriate permissions and restart
echo "Setting up Docker user and permissions"
usermod -aG docker ${USER_SCRIPT}
systemctl enable docker

echo "Ensuring ownership of ${HOME_USER} is set to ${USER_SCRIPT}"
chown -R ${USER_SCRIPT}:${USER_SCRIPT} ${HOME_USER}