#!/bin/bash
printf "\e[1;34m                _____                    __                                     \e[0m\n"
printf "\e[1;34m               |_   _|__ _ __ _ __ __ _ / _| ___  _ __ _ __ ___                 \e[0m\n"
printf "\e[1;34m                 | |/ _ \ '__| '__/ _' | |_ / _ \| '__| '_ ' _ \                \e[0m\n"
printf "\e[1;34m                 | |  __/ |  | | | (_| |  _| (_) | |  | | | | | |               \e[0m\n"
printf "\e[1;34m                 |_|\___|_|  |_|  \__,_|_|  \___/|_|  |_| |_| |_|               \e[0m\n"

printf "\e[1;34m               ___           _        _ _       _   _                            \e[0m\n"
printf "\e[1;34m              |_ _|_ __  ___| |_ __ _| | | __ _| |_(_) ___  _ __                 \e[0m\n"
printf "\e[1;34m               | || '_ \/ __| __/ _' | | |/ _' | __| |/ _ \| '_ \                \e[0m\n"
printf "\e[1;34m               | || | | \__ \ || (_| | | | (_| | |_| | (_) | | | |               \e[0m\n"
printf "\e[1;34m              |___|_| |_|___/\__\__,_|_|_|\__,_|\__|_|\___/|_| |_|               \e[0m\n"
echo""
echo""
echo""
if [ -f /usr/bin/terraform ]; then
        echo "Already Installed"
        echo""
else
        wget https://releases.hashicorp.com/terraform/1.0.6/terraform_1.0.6_linux_amd64.zip
        unzip terraform*.zip
        mv terraform /usr/bin/
        rm -rf terraform*.zip
        echo""
        echo""
        echo "Terrform Installtion has been Sucessfully completed"
        echo""
        echo "The Installed Version is"
        terraform -v
        echo""
        echo""
fi