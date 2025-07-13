# DietPi Install

Install DietPI as described [here](https://dietpi.com/docs/install/#how-to-install-dietpi-native-pc).

During the installation set the following options:
```yaml
Passowrd: <passowrd>
Hostname: DietPi<Name>
Timezone: Europe/Amsterdam
SSH server: OpenSSH
Software to install: git, docker, docker compose
```

Place the microSD card in the RaspberryPi and plug it in. Wait for the system to install itself (the front LED will stop flashing when its done).

# Setup DietPi

ssh into the system as root and run the `root-install-script.sh` script by running the following command:
```bash
wget -O - https://raw.githubusercontent.com/timothymamo/nuc-dietpi-install/refs/heads/main/root-install-script.sh | bash
```

Once the script is done you will get a notification to change user by running `su - <user>` and modify the `docker-compose/.env` file.
```bash
nano ${HOME}/docker-compose/.env
```

Once modified run the `user-install-script.sh` script:
```bash
./user-install-script.sh
```

The script will ask you to set a new password for the user as well as asking you to enter the password whenever a sudo command is required.
Once the script finishes the system will reboot.

Re-login, now you should be running `zsh` with `starship` for your prompt, and check that everything is running as it should be by running the alias command `dps`.