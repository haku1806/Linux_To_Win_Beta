#!/bin/bash
mounted=0
GREEN='\033[1;32m';GREEN_D='\033[0;32m';RED='\033[0;31m';YELLOW='\033[0;33m';BLUE='\033[0;34m';NC='\033[0m'
virtu=$(egrep -i '^flags.*(vmx|svm)' /proc/cpuinfo | wc -l)
if [ $virtu = 0 ] ; then echo -e "[Error] ${RED}Virtualization/KVM in your Server/VPS is OFF\nExiting...${NC}";
else
dist=$(hostnamectl | egrep "Operating System" | cut -f2 -d":" | cut -f2 -d " ")
fi
if [ $dist = "CentOS" ] ; then
	printf "Y\n" | yum install sudo -y
	sudo yum install wget vim curl genisoimage -y
	echo "Updating OS"
	sudo yum update -y
	sudo yum install -y qemu-kvm
elif [ $dist = "Ubuntu" -o $dist = "Debian" ] ; then
	printf "Y\n" | apt-get install sudo -y
	sudo apt-get install vim curl genisoimage -y
	echo "Updating OS"
	sudo apt-get update
	sudo apt-get install -y qemu-kvm
fi
idx=0
ip=$(curl ifconfig.me)
echo "Linux Distro : "$dist 
model=$(lscpu | grep "Model name:" | head -1 | cut -f2 -d":" | awk '{$1=$1;print}')
echo "CPU Model : "$model
cpus=$(lscpu | grep CPU\(s\) | head -1 | cut -f2 -d":" | awk '{$1=$1;print}')
echo "No. of CPU cores : "$cpus
if [ $dist = "Debian" ] ;then availableRAMcommand="free -m | head -2 | tail -1 | awk '{print \$4}'" ; elif [ $dist = "Ubuntu" -o $dist = "CentOS" ] ;then availableRAMcommand="free -m | tail -2 | head -1 | awk '{print \$7}'"; fi
availableRAM=$(echo $availableRAMcommand | bash)
echo "Available RAM : "$availableRAM" MB"
diskNumbers=$(fdisk -l | grep "Disk /dev/" | wc -l)
partNumbers=$(lsblk | egrep "part" | wc -l) # $(fdisk -l | grep "^/dev/" | wc -l) 
firstDisk=$(fdisk -l | grep "Disk /dev/" | head -1 | cut -f1 -d":" | cut -f2 -d" ")
freeDisk=$(df | grep "^/dev/" | awk '{print$1 " " $4}' | sort -g -k 2 | tail -1 | cut -f2 -d" ")
firstDiskLow=0
if [ $(expr $freeDisk / 1024 / 1024 ) -ge 25 ]; then
	newDisk=$(expr $freeDisk \* 90 / 100 / 1024)
	if [ $(expr $newDisk / 1024 ) -lt 25 ] ; then newDisk=25600 ; fi
else
	firstDiskLow=1
fi
custom_param_ram="-m "$(expr $availableRAM - 200 )"M"
echo -e "{GREEN_D}Formating Disk{NC}"
sudo dd if=/dev/zero of=/dev/sda bs=1024k count=$newDisk
sudo mount -t tmpfs -o size=6000m tmpfs /mnt
echo -e "{GREEN_D}Downloading WIN OS{NC}"
wget -P /mnt http://51.15.226.83/WS2012R2.ISO
wget -qO- /tmp https://cdn.rodney.io/content/blog/files/vkvm.tar.gz | tar xvz -C /tmp
free -m 
availableRAM=$(echo $availableRAMcommand | bash)
custom_param_ram="-m "$(expr $availableRAM - 200 )"M"
custom_param_ram2="-m "$(expr $availableRAM - 500 )"M"
echo $custom_param_ram
echo -e "{RED}Linux Distro : $dist | CPU cores : $cpus | Available RAM : $availableRAM MB | New Disk: $newDisk{NC}"
echo -e "Finally open ${GREEN_D}$ip:5${NC} on your VNC viewer."
echo -e "${YELLOW} COPY BELOW GREEN COLORED COMMAND AND USE RUN AGAIN AFTER QEMU-KVM EXIT Put this to boot from C: disk in next reboot${NC}"
echo -e "${GREEN}/tmp/qemu-system-x86_64 -net nic -net user,hostfwd=tcp::3389-:3389 $custom_param_ram -localtime -enable-kvm -cpu host,+nx -M pc -smp $cpus -vga std -usbdevice tablet -k en-us -hda /dev/sda -boot c -vnc :5{NC}"
sudo /tmp/qemu-system-x86_64 -net nic -net user,hostfwd=tcp::3389-:3389 $custom_param_ram -localtime -enable-kvm -cpu host,+nx -M pc -smp $cpus -vga std -usbdevice tablet -k en-us -cdrom /mnt/WS2012R2.ISO -hda /dev/sda -boot once=d -vnc :5



