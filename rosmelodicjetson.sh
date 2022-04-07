#!/bin/bash

NOMBRE_CODIGO_DISTRIBUCION=$( lsb_release -sc )

case $NOMBRE_CODIGO_DISTRIBUCION in
  "xenial" )
    echo "ESTA INSTALACION ES RECOMENDADA PARA UBUNTU 18.4."
    echo "ROS Bionic es la version recomendada."
    echo "este  script instala ROS Melodic. usted podria necesitar modificaciones para esto."
    exit 0
  ;;
  "bionic")
    echo "esta distribución es ubuntu bionic 18.4   (18.04)"
    echo "Instalando  ROS Melodic"
  ;;
  *)
    echo "Esta distribucion es $NOMBRE_CODIGO_DISTRIBUCION"
    echo "este script  script solo funcionará para Ubuntu Bionic (18.04)"
    exit 0
esac

# Instale el sistema operativo de robot (ROS) en NVIDIA Jetson Developer Kit
# El soporte  de compilaciones ARM para ROS es http://answers.ros.org/users/1034/ahendrix/
# Informacion de:
# http://wiki.ros.org/melodic/Installation/UbuntuARM

# Red is 1
# Green is 2
# Reset is sgr0

usage ()
{
    echo "Usage: ./ROSbyJETSON.sh [[-p package] | [-h]]"
    echo "Install ROS Melodic"
    echo "Installs ros-melodic-ros-base as default base package; Use -p to override"
    echo "-p | --package <packagename>  ROS package to install"
    echo "                              Multiple usage allowed"
    echo "                              Must include one of the following:"
    echo "                               ros-melodic-ros-base"
    echo "                               ros-melodic-desktop"
    echo "                               ros-melodic-desktop-full"
    echo "-h | --help  This message"
}

shouldInstallPackages ()
{
    tput setaf 1
    echo "Your package list did not include a recommended base package"
    tput sgr0 
    echo "Please include one of the following:"
    echo "   ros-melodic-ros-base"
    echo "   ros-melodic-desktop"
    echo "   ros-melodic-desktop-full"
    echo ""
    echo "ROS not installed"
}

# Iterar a través de entradas de línea de comando
paquetes=()
while [ "$1" != "" ]; do
    case $1 in
        -p | --paquete )        shift
                                paquetes+=("$1")
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done
# Check to see if other paquetes were specified
# If not, set the default base package
if [ ${#paquetes[@]}  -eq 0 ] ; then
 paquetes+="ros-melodic-ros-base"
fi
echo "Paquetes to install: "${paquetes[@]}
# Check to see if we have a ROS base kinda thingie
hasBasePackage=false
for paquete in "${paquetes[@]}"; do
  if [[ $package == "ros-melodic-ros-base" ]]; then
     hasBasePackage=true
     break
  elif [[ $paquete == "ros-melodic-desktop" ]]; then
     hasBasePackage=true
     break
  elif [[ $paquete == "ros-melodic-desktop-full" ]]; then
     hasBasePackage=true
     break
  fi
done
if [ $hasBasePackage == false ] ; then
   shouldInstallPackages
   exit 1
fi

# Let's start installing!

tput setaf 2
echo "agregando repositorios y  source list"
tput sgr0
sudo apt-add-repository universe
sudo apt-add-repository multiverse
sudo apt-add-repository restricted
tput setaf 2
echo "actualizando apt list"
tput sgr0
sudo apt update

# Setup sources.lst
sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'

# Setup keys
sudo apt install curl 
curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -

tput setaf 2
echo "actualizando  apt list"
tput sgr0
sudo apt update

tput setaf 2
echo "Instalando ROS"
tput sgr0
# Aquí es donde puede comenzar a modificar los paquetes que se están instalando, es decir,
# sudo apt-get install ros-melodic-desktop

# Aquí es donde puede comenzar a modificar los paquetes que se están instalando, es decir,
# Instalar paquetes...
for package in "${paquetes[@]}"; do
  sudo apt-get install $paquete -y
done

# agregue sus paquetes individuales aqui
# usted puede instalar un paquete especifico de ROS(remplace la lidea de abajo con el nombre del paquete):
# sudo apt-get install ros-melodic-PACKAGE
# EJEMPLO
# sudo apt-get install ros-melodic-navigation
#
# buscar el paquete disponible:
# apt-cache search ros-melodic
# 
# inicializar  rosdep
tput setaf 2
echo "Installing rosdep"
tput sgr0
sudo apt-get install python-rosdep -y

# Inicializar rosdep
tput setaf 2
echo "Initializaing rosdep"
tput sgr0
sudo rosdep init
# Para encontrar paquetes disponibles, use:

rosdep update
# Configuración del entorno - source melodic setup.bash
# no agregar /opt/ros/melodic/setup.bash si esto esta listo en  bashrc
grep -q -F 'source /opt/ros/melodic/setup.bash' ~/.bashrc || echo "source /opt/ros/melodic/setup.bash" >> ~/.bashrc
source ~/.bashrc

# instalar rosinstall
tput setaf 2
echo "Installing rosinstall tools"
tput sgr0

# Instale herramientas útiles de desarrollo de ROS
sudo apt-get install -y python-rosinstall \
  python-rosinstall-generator \
  python-wstool \
  build-essential

# Use ip para obtener las direcciones IP actuales de eth0 y wlan0; analizar en forma xx.xx.xx.xx
ETH0_IPADDRESS=$(ip -4 -o addr show eth0 | awk '{print $4}' | cut -d "/" -f 1)
WLAN_IPADDRESS=$(ip -4 -o addr show wlan0 | awk '{print $4}' | cut -d "/" -f 1)

if [ -z "$ETH0_IPADDRESS" ] ; then
  echo "Ethernet (eth0) is not available"
else
  echo "Ethernet (eth0) is $ETH0_IPADDRESS"
fi
if [ -z "$WLAN_IPADDRESS" ] ; then
  echo "Wireless (wlan0) is not available"
else
  echo "Wireless (wlan0) ip address is $WLAN_IPADDRESS"
fi

# Predeterminado a eth0 si está disponible; wlan0 siguiente
ROS_IP_ADDRESS=""
if [ ! -z "$ETH0_IPADDRESS" ] ; then
  ROS_IP_ADDRESS=$ETH0_IPADDRESS
else
  ROS_IP_ADDRESS=$WLAN_IPADDRESS
fi
if [ ! -z "$ROS_IP_ADDRESS" ] ; then
  echo "Setting ROS_IP in ${HOME}/.bashrc to: $ROS_IP_ADDRESS"
else
  echo "Setting ROS_IP to empty. Please change ROS_IP in the ${HOME}/.bashrc file"
fi

#configurar variables de entorno ROS
grep -q -F ' ROS_MASTER_URI' ~/.bashrc ||  echo 'export ROS_MASTER_URI=http://localhost:11311' | tee -a ~/.bashrc
grep -q -F ' ROS_IP' ~/.bashrc ||  echo "export ROS_IP=${ROS_IP_ADDRESS}" | tee -a ~/.bashrc
tput setaf 2

echo "Installation complete!"
echo "Please setup your Catkin Workspace and ~/.bashrc file"
echo"calamardo tecnologico listo"
tput sgr0
