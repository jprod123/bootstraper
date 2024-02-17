#/bin/bash

display_usage(){
  echo "Installs common packages and sets jps preffered defaults"
  echo "Usage: $0 <command>"
  echo "Options:"
  echo "  -h, --help      Display this help message"
  echo "  --no-docker     Disable Docker install"
  echo "  --no-zsh     	  Disable zsh install"

}

install_packages(){
  apt install -y \
    vim \
    openssh-server \
    openssh-client \
    git \
    curl \
    wget \
    nvim \
    build-essential \
    cmake 
  }


install_docker(){
  # Add Docker's official GPG key:
  apt-get update
  apt-get install ca-certificates curl
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update

  apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin


  groupadd docker 
  usermod -aG docker $ORIGINAL_USERNAME
}


install_zsh(){
  sudo -u $ORIGINAL_USERNAME chsh -s /usr/bin/zsh
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  curl -fsSL https://raw.githubusercontent.com/jprod123/bootstraper/main/zsh-config >> /home/$ORIGINAL_USERNAME/.zshrc
}

mount_network_share(){
  echo "Configuring cifs share"
  CREDENTIALS_FILE="/home/$ORIGINAL_USERNAME/.creds"
  DEFAULT_MOUNT_LOCATION="/mnt/HDD1-share"
  read -p "Enter cifs user: " CIFS_USER
  read -s -p "Enter cifs user: " CIFS_PASSWORD

  echo "username=$CIFS_USER" >> $CREDENTIALS_FILE
  echo "password=$CIFS_PASSWORD" >> $CREDENTIALS_FILE

  mkdir $DEFAULT_MOUNT_LOCATION

  echo "//192.168.0.31/HDD1-share $DEFAULT_MOUNT_LOCATION cifs credentials=$CREDENTIALS_FILE,uid=$ORIGINAL_USERNAME,forceuid,gid=$ORIGINAL_GROUP_ID,forcegid,noauto,x-systemd.automount 0 0" >> /etc/fstab

}


if [ "$(id -u)" != "0" ]; then
  echo "This script must be run with sudo."
  display_usage() 
  exit 1
fi

# Check for flags
for arg in "$@"; do
  case $arg in
    -h|--help)
      display_usage
      exit 0
      ;;
    --no-docker)
      NO_DOCKER=true
      ;;
    --no-zsh)
      NO_ZSH=true
      ;;
  esac
done

ORIGINAL_USER_ID="$SUDO_UID"
ORIGINAL_GROUP_ID="$SUDO_GID"
ORIGINAL_USERNAME="$SUDO_USER"

echo "User: $ORIGINAL_USERNAME"
echo "Selected Options:"
echo "  No Docker: $NO_DOCKER"
echo "  No Zsh: $NO_ZSH"


if [ "$#" -eq 0 ]; then
  echo "No options provided. Proceeding with the installation..."
else
  # Prompt the user to continue
  read -p "Do you want to continue with the installation? (y/n): " choice
  case "$choice" in
    y|Y ) echo "Starting installation..." ;;
    n|N ) echo "Installation cancelled." && exit 0 ;;
    * ) echo "Invalid choice. Installation cancelled." && exit 1 ;;
  esac
fi

install_packages

if [ "$NO_DOCKER" = true ]; then
  echo "Docker disabled."
else
  install_docker
fi

if [ "$NO_ZSH" = true ]; then
  echo "Zsh disabled."
else
  install_oh_my_zsh
fi


read -p "Installation complete, do you wish to reboot" reboot_choice
case "$reboot_choice" in
  y|Y ) reboot ;;
  * ) exit 0 ;;
esac
