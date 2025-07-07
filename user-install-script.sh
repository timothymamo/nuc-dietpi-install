#!/bin/bash

# Change directory to $[HOME]
pushd ${HOME}

ssh-keygen -a 100 -t ed25519 -f ${HOME}/.ssh/id_ed25519 -C "${USER}@${HOST}"
ssh-keygen -a 100 -t rsa -f ${HOME}/.ssh/id_rsa -C "${USER}@${HOST}"
echo "host github.com
 HostName github.com
 IdentityFile ~/.ssh/id_ed25519" > ${HOME}/.ssh/config

# Set docker autocompletion
mkdir -p ${HOME}/.docker/completions
docker completion zsh > ${HOME}/.docker/completions/_docker

# Set zsh as the default shell for the ${USER}
echo "Settign zsh as default shell for ${USER}"
command -v zsh | sudo tee -a /etc/shells
chsh -s "$(command -v zsh)" ${USER}

# Copying .gitconfig file
cp ${HOME}/.gitconfig-example ${HOME}/.gitconfig
sed -i "s/HOST/${HOST}/g" ${HOME}/.gitconfig

# Copying snbcredentials to be able to connect to NAS
cp ${HOME}/.smbcredentials-example ${HOME}/.smbcredentials

# Start the containers
pushd ${HOME}/docker-compose
docker compose up --detach --wait --wait-timeout 60

# Allowing containers in different networks to talk to each other
echo "Finding docker compose networks and modifying iptables to allow containers in different networks to talk to each other"
for DC_NET_IDS in DC_NET_1 DC_NET_2; do
    read -r "${DC_NET_IDS}"
done <<EOF
  $(ip route | grep -oh "\w*br-\w*")
EOF

sudo iptables -I DOCKER-USER -i ${DC_NET_1} -o ${DC_NET_2} -j ACCEPT
sudo iptables -I DOCKER-USER -i ${DC_NET_2} -o ${DC_NET_1} -j ACCEPT

# Crate a password for the user
sudo passwd ${USER}

# Reboot the system
sudo poweroff --reboot