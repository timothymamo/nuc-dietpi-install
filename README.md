# DietPi Install

Install DietPI as described [here](https://dietpi.com/docs/install/#how-to-install-dietpi-native-pc).

You will have to connect to the internet and setup WiFi if you haven't got the ethernet cable connected.

During the installation set the following options:
```yaml
Passowrd: <passowrd>
Hostname: DietPi<Name>
Timezone: Europe/Amsterdam
SSH server: OpenSSH
Software to install: git, docker, docker compose
```

Once the setup is follow the next steps.

# Setup DietPi

ssh into the system as root using the password you set and run the `root-install-script.sh` script by running the following command:
```bash
wget -O - https://raw.githubusercontent.com/timothymamo/nuc-dietpi-install/refs/heads/main/root-install-script.sh | bash
```

Once the script is done you will get a notification to change user by running `su - <user>` and modify the `docker-compose/.env` file.
```bash
vim ${HOME}/docker-compose/.env
```

Once modified run the `user-install-script.sh` script:
```bash
./user-install-script.sh
```

The script will ask you to set a new password for the user as well as asking you to enter the password whenever a sudo command is required.
Once the script finishes the system will reboot.

Re-login, now you should be running `zsh` with `starship` for your prompt, and check that everything is running as it should be by running the alias command `dps`.

You will have to set the appropriate username and password for the `${HOME}/.smbcredentials` file and reboot the system.