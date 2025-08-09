#!/bin/bash

# Set variables"
USER_SCRIPT="tim"
HTTPS_REPO="https://github.com/timothymamo/nuc-dietpi-install.git"

HOME_USER="/home/${USER_SCRIPT}"

# Output variables
echo "\n------------------------------------------------"
echo "Creating User: ${USER_SCRIPT}"
echo "Home directory for ${USER_SCRIPT}: ${HOME_USER}"
echo "Repo to clone: ${HTTPS_REPO}"

# Create super user with no password
adduser --disabled-password --gecos "" ${USER_SCRIPT}
usermod -aG sudo ${USER_SCRIPT}
passwd -d ${USER_SCRIPT}

# Add public key and copy the .ssh directory
echo "\n------------------------------------------------"
echo "Copying SSH keys to user's home"
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAIUVrLYuMImaXmOkU3picEHpph3dfIg2YQQOiPvFMaF tmamo@macbookairm3" > /root/.ssh/authorized_keys
cp -r /root/.ssh/ ${HOME_USER}

# Install Packages
echo "\n------------------------------------------------"
echo "Installing Packages"
apt update && apt upgrade
apt -y install \
  nfs-common \
  cifs-utils \
  rsync \
  mailutils \
  build-essential \
  vim \
  zsh \
  zsh-syntax-highlighting \
  zsh-autosuggestions \
  fonts-firacode

# Install starship
curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir /usr/bin

# Disable root ssh login
echo "\n------------------------------------------------"
echo "Disabling Root login"
sed -i '/.*PermitRootLogin.*/c\PermitRootLogin no' /etc/ssh/sshd_config

# Add NAS to fstab to mount on boot
echo "\n------------------------------------------------"
echo "Adding NAS to fstab file to mount on boot"
# Credentials not working; currently using `username=<username>,password=<password>``
echo "# NAS
//192.168.1.120/nuc/ ${HOME_USER}/nas cifs _netdev,credentials=${HOME_USER}/.smbcredentials,auto,vers=3.0,uid=1000,gid=1000 0 1
//192.168.1.120/NetBackup/ /mnt/backup/ cifs _netdev,credentials=${HOME_USER}/.smbcredentials,auto,vers=3.0,uid=1000,gid=1000 0 1" >> /etc/fstab

# Mount NAS drives
echo "\n------------------------------------------------"
echo "Mounting NAS drives and verifying"
mount ${HOME_USER}/nas
mount /mnt/backup
findmnt --verify

# Copy the config directory from backup
echo "\n------------------------------------------------"
echo "Copying the config dir to the user home ${HOME_USER}"
cp -R /mnt/backup/nuc/config/ ${HOME_USER}/config

# Creating rsync backup daily cron of config dir to NAS
echo "\n------------------------------------------------"
echo "Creating a daily backup of the config directory to the NAS"
echo '#!/bin/bash

# Set Variables
HOME_USER=/home/tim
SRC=${HOME_USER}/config/
DEST=/mnt/backup/nuc/config
TMP_LOG_FILE=/var/log/rsync.log

if [ -f ${TMP_LOG_FILE} ]; then
	rm -rf ${TMP_LOG_FILE}
	touch ${TMP_LOG_FILE}
else
	touch ${TMP_LOG_FILE}
fi

# Make sure destination directory is mounted and exists
if [ ! -d ${DEST} ]; then
	echo "${DEST} drive does not exist. Please mount the Drive ${DEST} before continuing"
	exit -1
fi > ${TMP_LOG_FILE} 2>&1

# Sync the config directory to the NAS; Output logs to temp file
/usr/bin/rsync --rsh="ssh -i ${HOME_USER}/.ssh/id_ed25519" --info=skip0 --archive --recursive --human-readable --no-links --delete --exclude "${DEST}/*.log" file.txt ${SRC} ${DEST} >> ${TMP_LOG_FILE} 2>&1

# Remove any log files older than 2 weeks on the NAS
/usr/bin/find ${DEST}/*.log -mtime +14 -exec rm {} \; >> ${TMP_LOG_FILE} 2>&1

# Copy the log file to the NAS
/usr/bin/cp ${TMP_LOG_FILE} ${DEST}/"$(date +"%Y_%m_%d_%H_%M_%S").log"' > /etc/cron.daily/rsync-nas
chmod +x /etc/cron.daily/rsync-nas

# Create a git directory and clone this repo
echo "\n------------------------------------------------"
echo "Cloning repo into ${HOME_USER}/git/nuc-dietpi-install/"
mkdir -p ${HOME_USER}/git/nuc-dietpi-install/
git clone ${HTTPS_REPO} ${HOME_USER}/git/nuc-dietpi-install/

# Create symlinks for all files
echo "\n------------------------------------------------"
echo "Symlinking repo into ${HOME_USER}"
ln -s ${HOME_USER}/git/nuc-dietpi-install/* ${HOME_USER}
ln -s ${HOME_USER}/git/nuc-dietpi-install/.* ${HOME_USER}

# Remove .git directory so any changes within ${HOME} don't get pushed to the repo
echo "\n------------------------------------------------"
echo "Removing symlink for .git directory within ${HOME_USER}"
rm -rf ${HOME_USER}/.git

# Create a ${HOME}/docker-compose/.env file from ${HOME}/docker-compose/.env-sample
echo "\n------------------------------------------------"
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
echo "\n------------------------------------------------"
echo "Restarting sshd"
systemctl restart sshd

# Setup Docker to have the appropriate permissions and restart
echo "\n------------------------------------------------"
echo "Setting up Docker user and permissions"
usermod -aG docker ${USER_SCRIPT}
systemctl enable docker

# Set docker to start 30s after boot to allow volumes to mount
# DID NOT WORK!!!
echo "\n------------------------------------------------"
echo "Setting a 15s wait before starting docker at boot"
sed -i '/^ExecStart=/usr/bin/dockerd.*/i ExecStartPre=/bin/sleep 15' /lib/systemd/system/docker.service

echo "\n------------------------------------------------"
echo "Setting ownership of ${HOME_USER} to ${USER_SCRIPT}"
# DOESN"T ALWAYS WORK
chown -R ${USER_SCRIPT}:${USER_SCRIPT} ${HOME_USER}
chown -R dietpi:dietpi ${HOME_USER}/config

echo "\n------------------------------------------------"
echo "All done! Change user by running su - ${USER_SCRIPT}, modify the docker-compose/.env file and then run the script user-install-script.sh."