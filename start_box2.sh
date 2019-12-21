#!/bin/env bash
#by JaguarZz

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

	nmap -T4 --max-retries 1 --max-scan-delay 20 --defeat-rst-ratelimit -oN $name/nmap/quick_scan.nmap $1 

	echo -e ""
	echo -e ""
	echo -e ""

	echo -e "${GREEN}---------------------Starting Nmap Full Scan----------------------"
	echo -e "${NC}"

	nmap -sC -sV -T4 -p- -oN $name/nmap/full_scan.nmap $1

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

function tmuxCreate() {	
	tmux rename-window -t 1 "cherry/vpn"

	declare -a names=("htb" "tools" "burp")
	n=2
	for x in "${names[@]}"; do
	  	tmux new-window -t $n 2>/dev/null || tmux select-window -t $n && tmux rename-window -t $n "$x"

	  	if [ "$n" == "2" ]; then 
	  		mkdir -p $2/{www,recon,nmap}
	  		cp ~/htb/tools/htb_template.ctb $2/ && mv $2/htb_template.ctb $2/$2.ctb
		fi

	 	if [ "$n" == "3" ]; then
	 		tmux kill-pane -a -t 1
			tmux split -h && tmux split -v
		fi

		if [ "$n" == "4" ]; then
			tmux send-keys "echo 'burppro'" C-m # alias
		fi

		n=$(($n+1))
	done
}

reconRecommend(){
	# Gets called with $1 == IP $2 == HOSTNAME

	# Reads the output of full_scan and outputs the ports to the ports var
	if [ -f $name/nmap/full_scan.nmap ]; then		
		ports=`cat $name/nmap/full_scan.nmap | grep open | cut -d " " -f 1 | cut -d "/" -f 1 | tr "\n" "," | head -c-1`
	fi

	echo -e "${GREEN}---------------------Recon Recommendations----------------------"
	echo -e "${NC}"

	oldIFS=$IFS
	IFS=$'\n'

	if [ -f $3/nmap/full_scan.nmap ]; then
		file=`cat $3/nmap/full_scan.nmap | grep -w "open"`
	fi

	if [[ ! -z `echo "${file}" | grep -i http` ]]; then
		echo -e "${NC}"
		echo -e "${YELLOW}Web Servers Recon:"
		echo -e "${NC}"
	fi

	for line in $file; do
		if [[ ! -z `echo "${line}" | grep -i http` ]]; then
			port=`echo "${line}" | cut -d "/" -f 1`
			pages=.php,.html
			if [[ ! -z `echo "${line}" | grep ssl/http` ]]; then
				echo "sslscan $1 | tee $2/recon/sslscan_$port.txt"
				echo "gobuster dir -w /usr/share/wordlists/dirbuster/directory-list-1.0.txt -l -t 40 -e -k -x $pages -u https://$1:$port -o $2/recon/gobuster_$port.txt"
				echo "nikto -host https://$1:$port -ssl | tee $2/recon/nikto_$port.txt"
			else
				echo "gobuster dir -w /usr/share/wordlists/dirbuster/directory-list-1.0.txt -l -t 40 -e -k -x $pages -u http://$1:$port -o $2/recon/gobuster_$port.txt"
				echo "nikto -host $1:$port | tee $2/recon/nikto_$port.txt"
			fi
			echo ""
		fi
	done

	IFS=$oldIFS

	echo -e ""
	echo -e ""
	echo -e ""
}

function runRecon() {
	echo -e ""
	echo -e ""
	echo -e ""
	echo -e "${GREEN}---------------------Running Recon Commands----------------------"
	echo -e "${NC}"

	oldIFS=$IFS
	IFS=$'\n'

	reconCommands=$(reconRecommend $1 $2)
	echo "$reconCommands"

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

# set -x

# nmapScan / tmuxCreate / checkValid
function footer() {
	# Checks if the first arg is a valid IP
	checkValid $1

	if [ "$2" == "recurse4" ] || [ "$2" == "recurse3" ] || [ "$2" == "recurse2" ]; then
		:
	else	
		if [ "$2" == "recurse1" ]; then
			# Run quick & full scan
			# nmapScan $1 $3
			cp full_scan.nmap $3/nmap/
			cat $3/nmap/full_scan.nmap
		else
			# Create windows & panes
			tmuxCreate $1 $2

			# Checks if a hostname was provided, if not then IP will 
			# be used to name files
			name=$2
			if [ -z "$2" ]; then
				name=$1
			fi

			# Select window 3 pane 3
			tmux select-window -t 3 && tmux selectp -t 1

			# Call script to run nmapScan in new window/pane
			tmux send-keys "$0 $1 recurse1 $name" C-m
			exit
		fi
	fi

	if [ "$2" == "recurse4" ] || [ "$2" == "recurse3" ]; then
		:
	else
		if [ "$2" == "recurse2" ]; then

			# (I dont want recommendations, just for it to run)
			runRecon $1 $3
		else
			# Select pane 1 in window 3
			tmux selectp -t 3

			# Call script to run recondRecommend in new window/pane
			tmux send-keys "$0 $1 recurse2 $3" C-m
			exit
		fi
	fi

	# if [ "$2" == "recurse4" ]; then
	# 	:
	# else
	# 	if [ "$2" == "recurse3" ]; then
	# 		echo recurse 3
	# 	else
	# 		tmux selectp -t 4
	# 		tmux send-keys "$0 $1 recurse3" C-m
	# 		exit
	# 	fi
	# fi


	# if [ "$2" == "recurse4" ]; then
	# 	echo recurse 4
	# else
	# 	tmux selectp -t 5
	# 	tmux send-keys "$0 $1 recurse4" C-m
	# 	exit
	# fi
}


footer $1 $2 $3

# # Gobuster
# tmux selectp -t 2 \
# && tmux send-keys "gobuster dir -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -x .php -t 45 -l -k -o ~/htb/boxes/$BOX.htb/http/root.dir" -u $1" C-m

# # Nikto
# tmux selectp -t 3 && tmux send-keys "nikto -h $1 | tee ~/htb/boxes/$BOX.htb/http/nikto-$1" C-m
#cat >> ~/.bash_history <<< "$(egrep -v "recurse1|recurse2|recurse3|recurse4" ~/.bash_history)"