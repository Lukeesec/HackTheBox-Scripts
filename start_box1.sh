#!/bin/bash

# Creds to the cretor of nmapAutomater: https://github.com/21y4d/nmapAutomator

# Details on what to change for this script to work for you:
# xyz


# Current things to figure out / do (I have no idea)
# Make a var that stores the path to the working directory (add full paths for scans)

# go to window 3, select pane 2.. Check for ports 443/80 run gobuster on both
# Same for nikto.. check if ports 443/80 exist, then run scans

# window 3 is (nmap / gobuster / nikto)
# window 4 is (anything extra..)

# IMPORTANT
# Run quick nmap scan, switch to a new window, run gobuster, switch back 
# and run full nmap


RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

function usage(){
echo -e "${RED}Usage: $0 <TARGET-IP> <HostName>"
echo -e "${YELLOW}"
echo -e "\tHostName:    Creates files using hostname instead of the IP"
echo -e "\tCreates 4 windows & splits 1 & 3"
echo -e "\t[1] Window 1 split horizontal"
echo -e "\t[2] Window 3 split horizontal then vertically"
exit 1
}

function ports() {
if [ -f full_scan.nmap ]; then		
		allPorts=`cat full_scan.nmap | grep open | cut -d " " -f 1 | cut -d "/" -f 1 | tr "\n" "," | head -c-1`
fi
}

function nmapScan() {
echo -e ""

checkPing=`checkPing $1`
nmapType="nmap -Pn"

ttl=`echo "${checkPing}" | tail -n 1`
if [[  `echo "${ttl}"` != "nmap -Pn" ]]; then
	osType="$(checkOS $ttl)"	
	echo -e "${NC}"
	echo -e "${GREEN}Host is likely running $osType"
	echo -e "${NC}"
fi

echo -e ""
echo -e ""

echo -e "${GREEN}---------------------Starting Nmap Quick Scan---------------------"
echo -e "${NC}"

nmap -T4 --max-retries 1 --max-scan-delay 20 --defeat-rst-ratelimit $1

echo -e ""
echo -e ""
echo -e ""

echo -e "${GREEN}---------------------Starting Nmap Full Scan----------------------"
echo -e "${NC}"

nmap -sC -sV -T4 -p- -oN full_scan.nmap $1

ports

echo -e ""
echo -e ""
echo -e ""
}

function checkPing() {
pingTest=`ping -c 1 -W 3 $1 | grep ttl`
if [[ -z $pingTest ]]; then
	echo "nmap -Pn"
else
	echo "nmap"
	ttl=`echo "${pingTest}" | cut -d " " -f 6 | cut -d "=" -f 2`
	echo "${ttl}"
fi
}

function checkOS() {
if [ "$1" == 256 ] || [ "$1" == 255 ] || [ "$1" == 254 ]; then
        echo "OpenBSD/Cisco/Oracle"
elif [ "$1" == 128 ] || [ "$1" == 127 ]; then
        echo "Windows"
elif [ "$1" == 64 ] || [ "$1" == 63 ]; then
        echo "Linux"
else
        echo "Unknown OS!"
fi
}

# Creates the windows / panes... Also creates the directory structure
function tmuxCreate() {
tmux rename-window -t 1 "cherry/vpn"

# Creating windows / panes / naming
declare -a names=("htb" "tools" "burp")
n=2
for x in "${names[@]}"; do
  	tmux new-window -t $n 2>/dev/null || tmux select-window -t $n && tmux rename-window -t $n "$x"

  	if [ "$n" == "2" ]; then 
  		name=$2
	  	if [ -z "$2" ]; then
	  		name=$1
	  	fi
  		tmux send-keys "cd . && mkdir $name.htb; cd $name.htb; mkdir www; mkdir http;  mkdir nmap" C-m
  		tmux send-keys "cp ~/htb/tools/htb_template.ctb . && mv htb_template.ctb $name.ctb" C-m
	fi

	if [ "$n" == "4" ]; then
		tmux send-keys "echo 'burppro'" C-m
	fi

 	if [ "$n" == "3" ]; then
 		tmux kill-pane -a -t 1
		tmux split -h && tmux split -v
	fi

	n=$(($n+1))
done
}

function checkValid() {
# Checks if if at least 1 arg provided
if (( "$#" < 1 )); then
	usage
fi

# Checks if the input is an IP
if [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	:
else
	echo -e "${RED}"
	echo -e "${RED}Invalid IP!"
	echo -e "${RED}"
	usage
fi
}

set -x
checkValid $1

if [ "$2" == "recurse2" ]; then
	:
else
	if [ "$2" == "recurse1" ]; then
		header $1
    	nmapScan $1
	else
		tmuxCreate $1 $2
		tmux select-window -t 3 && tmux selectp -t 1
		tmux send-keys "./start_box.sh $1 recurse1" C-m
		exit
	fi
fi

# if [ "$2" == "recurse1" ]; then
# 	tmux selectp -t 2
# 	tmux send-keys "./start_box.sh $1 recurse2" C-m
# 	exit
# else
# 	cat >> ~/.bash_history <<< "$(egrep -v "recurse1|recurse2|recurse3|recurse4" ~/.bash_history)"
# 	echo "$allPorts" || echo "full scan failed?"
# fi


# # Gobuster
# tmux selectp -t 2 \
# && tmux send-keys "gobuster dir -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -x .php -t 45 -l -k -o ~/htb/boxes/$BOX.htb/http/root.dir" -u $1" C-m

# # Nikto
# tmux selectp -t 3 && tmux send-keys "nikto -h $1 | tee ~/htb/boxes/$BOX.htb/http/nikto-$1" C-m


# # Creating new window, and renaming it
# tmux new-window -t 4 && tmux rename-window -t 4 "burp"



# # Moves current window back to htb (2)
# tmux selectw -t 2