#!/bin/bash

# Setup environment and download Akachain packages
# This script supports Linux based only. 
# For Windows users, checkout https://akachain.io for more detail
# For support, please contact us at support@akachain.io


banner() {
    echo "    _    _  __    _    ____ _   _    _    ___ _   _  "
    echo "   / \  | |/ /   / \  / ___| | | |  / \  |_ _| \ | | "
    echo "  / _ \ | ' /   / _ \| |   | |_| | / _ \  | ||  \| | "
    echo " / ___ \| . \  / ___ \ |___|  _  |/ ___ \ | || |\  | "
    echo "/_/   \_\_|\_\/_/   \_\____|_| |_/_/   \_\___|_| \_| "
    echo "                                                     "
}
                                                    
footer() {
    echo "                                                     "
    echo " _____ _   _    _    _   _ _  __ __   _____  _   _   "
    echo "|_   _| | | |  / \  | \ | | |/ / \ \ / / _ \| | | |  "
    echo "  | | | |_| | / _ \ |  \| | ' /   \ V / | | | | | |  "
    echo "  | | |  _  |/ ___ \| |\  | . \    | || |_| | |_| |  "
    echo "  |_| |_| |_/_/   \_\_| \_|_|\_\   |_| \___/ \___/   "
    echo "                                                     "
}

banner

check_os() {
    if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        # linuxbase.org
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        # For some versions of Debian/Ubuntu without lsb_release command
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        # Older Debian/Ubuntu/etc.
        OS=Debian
        VER=$(cat /etc/debian_version)
    elif [ -f /etc/SuSe-release ]; then
        # Older SuSE/etc.
        ...
    elif [ -f /etc/redhat-release ]; then
        # Older Red Hat, CentOS, etc.
        ...
    else
        # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    echo $OS
}

check_docker() {
    command -v docker >& /dev/null
    NODOCKER=$?
    DOCKER=null
    if [ "${NODOCKER}" == 0 ]; then
        DOCKER=$(docker -v)
    fi
    echo ${DOCKER}
}

check_nodejs() {
    command -v node >& /dev/null
    NONODE=$?
    NODEJS=null
    if [ "${NONODE}" == 0 ]; then
        NODEJS=$(node -v)
    fi
    echo ${NODEJS}
}

OS=$(check_os)
WORKING_DIR=${HOME}/.Akachain

install_docker() {
    echo "============== INSTALL DOCKER, PLEASE WAIT =================="
    echo "Your OS system is $OS"
    echo ">>>>>> $password"
    if [ "$OS" = "Ubuntu" ]; then
        echo $password | sudo -S apt-get update
        echo $password | sudo -S apt-get install -y \
            apt-transport-https \
            ca-certificates \
            curl \
            gnupg-agent \
            software-properties-common
        
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        #TODO: check arch
        arch="amd64"
        echo $password | sudo -S add-apt-repository \
                "deb [arch=${arch}] https://download.docker.com/linux/ubuntu \
                $(lsb_release -cs) \
                stable"
  
        echo $password | sudo -S apt-get update
        echo $password | sudo -S apt-get install -y docker-ce docker-ce-cli containerd.io
        
        echo $password | sudo groupadd docker
        echo $password | sudo gpasswd -a $USER docker
        newgrp docker
    
    elif [ "$OS" = "CentOS"]; then 
        echo "Docker automation installation on CentOS will be supported soon ..."
        echo "For the time being, please visit https://docs.docker.com/install/linux/docker-ce/centos/ to install docker"
    elif [ "$OS" = "Fedora" ]; then
        echo "Docker automation installation on Fedora will be supported soon ..."
        echo "For the time being, please visit https://docs.docker.com/install/linux/docker-ce/fedora/ to install docker"
    elif [ "$OS" = "Mac" ]; then
        echo "We do not support install Docker on MacOS through script right now. \
              Please follow this link to install https://docs.docker.com/docker-for-mac/install/"
    fi 
}

install_nodejs() {
    echo "============== INSTALL NODEJS, PLEASE WAIT =================="
    echo "Your OS system is $OS"
    echo ">>>>>> $password"
    if [ "$OS" = "Ubuntu" ]; then
        echo $password | sudo -S apt-get update
        echo $password | sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common build-essential
        
        curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -

        echo $password | sudo apt-get install -y nodejs
  
    elif [ "$OS" = "CentOS"]; then 
        echo "Nodejs automation installation on CentOS will be supported soon ..."
        echo "Please follow this link to install https://nodejs.org/"
    elif [ "$OS" = "Fedora" ]; then
        echo "Nodejs automation installation on Fedora will be supported soon ..."
        echo "Please follow this link to install https://nodejs.org/"
    elif [ "$OS" = "Mac" ]; then
        echo "We do not support install Docker on MacOS through script right now. \
              Please follow this link to install https://nodejs.org/"
    fi 
}


docker=$(check_docker)
nodejs=$(check_nodejs)

if [ "$docker" = "null" ] && [ "$nodejs" = "null" ]; then 
    echo "Docker and Nodejs are not installed on your system, would you like to install them now [y/n]: "
    read yesAll
    if [ "$yesAll" = "y" ]; then
        echo -n "Please enter your sudo password to continue: "
        read -s password;
        install_docker
        install_nodejs
    fi
elif [ "$docker" = "null" ]; then 
    echo "Docker is not installed on your system, would you like to install it now [y/n]: "
    read yesDocker
    if [ "$yesDocker" = "y" ]; then 
        echo -n "Please enter your sudo password to continue: "
        read -s password;
        install_docker
    fi
elif [ "$nodejs" = "null" ]; then
    echo "Nodejs is not installed on your system, would you like to install it now [y/n]: "
    read yesNodejs
    if [ "$yesNodejs" = "y" ]; then
        echo -n "Please enter your sudo password to continue: "
        read -s password;
        install_nodejs
    fi
else 
    echo "Congrat, your system meets requirements"
    echo "Nodejs version $nodejs"
    echo $docker
fi

#check nodejs and docker version again
docker=$(check_docker)
nodejs=$(check_nodejs)
if [ "$docker" = "null" ] | [ "$nodejs" = "null" ]; then 
    echo "Docker and Nodejs are not install on your system, Exit now ..."
    exit 1
fi



echo "=================================================================="
echo "Loading Akachain packages, Please wait ..."

if [ -d ${WORKING_DIR} ]; then 
    echo "Found previous data, clean it now ..."
    rm -fr ${WORKING_DIR}
fi 

mkdir -p ${WORKING_DIR}
cd ${WORKING_DIR}

#get akachain backend, frontend, script using CURL or WGET or Git
git clone https://github.com/Akachain/devtool-backend.git
git clone https://github.com/Akachain/devtool-community-network.git

#git clone https://github.com/Akachain/devtool-scripts.git

echo "=================================================================="
echo "Runing Mysql container ..."
docker rm -f mysql
docker run -p 4406:3306 -d --restart always --name mysql -e MYSQL_ROOT_PASSWORD=Akachain mysql/mysql-server

echo "Configure Mysql, Please wait ..."
while true;
do
    isMysql=$(docker ps | grep "mysql")
    isHealthy=$(docker ps | grep "healthy")
    if [ ! -z "$isMysql" ] && [ ! -z "$isHealthy" ]; then
        docker exec -it mysql sh -c "mysql -uroot -pAkachain -e \"UPDATE mysql.user SET Host='%' WHERE User='root' AND Host='localhost'\""
        docker exec -it mysql sh -c "mysql -uroot -pAkachain -e \"GRANT ALL PRIVILEGES ON * . * TO 'root'@'%'\""
        docker exec -it mysql sh -c "mysql -uroot -pAkachain -e \"ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'Akachain'\""
        echo "finish configuration mysql"
        break
    fi
    sleep 1
done

cd ${WORKING_DIR}/devtool-community-network
git checkout develop
chmod +x ./runFabric.sh
chmod +x ./scripts/*

cd  ${WORKING_DIR}/devtool-backend
git checkout develop
npm install
nohup node server.js > output_backend.log &
docker rm -f devtool-frontend
docker run -p 4500:80 -d --restart always --name devtool-frontend akachain/devtool-frontend

echo "\n\n"
echo "Please open http://localhost:4500 to start using devtool"



footer

