#!/bin/env bash
#by JaguarZz

# Creds to the cretor of nmapAutomater: https://github.com/21y4d/nmapAutomator

# Expects to be in a tmux session already (fix later)

# List of tools used:
# HTTP: -----
# sslscan
# ffuf
# nikto
# joomscan
# wpscan
# droopescan
# ffuf (sub-domain dirbusting)
# Windows: -----
# smbmap/smbclient 
# enum4linux
# snmpwalk
# snmp-check
# odat.py sidguesser/passwordgusser

# TODO:
# [1] Add more tools to be ran automatically
# [2] Somehow change runRecon so that gobuster / sslscan gets ran in a pane by it's self
# Then nikto & whatever else is ran in another pane
# [3] Clean up code
# [4] Create a better recurse function
# [5] Implement a better way of dirbusting
# [6] If there is a hostname -- add it to /etc/hosts, if not, do nothing
# [7] Run cherrytree in the first window, first pane (or split pane, then use second pane?)

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

function usage(){
	echo -e "${RED}Usage: $0 <TARGET-IP> <HostName>"
	echo -e "${YELLOW}"
	echo -e "\tHostName:    Creates files using hostname instead of the IP"
	echo -e ""
	echo -e "\tInfo:"
	echo -e ""
	echo -e "\t[1] Run the below command below to have less false positives during dirb"
	echo -e "\tsed -i '/#/d' /usr/share/wordlists/dirbuster/directory-list-2.3-small.txt"
	echo -e ""
	echo -e "\t[2] Must already be in a tmux session"
	echo -e ""
	exit 1
}


function nmapScan() {
	echo -e ""

	# Returns nmap "down" if "ttl" was not found in ping test
	checkPing=`checkPing $1`

	ttl=`echo "${checkPing}" | tail -n 1`
	if [[  `echo "${ttl}"` != "down" ]]; then
		osType="$(checkOS $ttl)"	
		echo -e "${NC}"
		echo -e "${GREEN}Host is likely running $osType"
		echo -e "${NC}"
	else
		echo -e "${NC}"
		echo -e "${GREEN}Host is likely down"
		echo -e "${NC}"
	fi

	echo -e ""
	echo -e ""

	echo -e "${GREEN}---------------------Starting Nmap Quick Scan---------------------"
	echo -e "${NC}"

	nmap -T4 --max-retries 1 --max-scan-delay 20 --defeat-rst-ratelimit -oN $2/nmap/quick_scan.nmap $1 

	echo -e ""
	echo -e ""
	echo -e ""

	echo -e "${GREEN}---------------------Starting Nmap Full Scan----------------------"
	echo -e "${NC}"

	nmap -sC -sV -T4 -p- -oN $2/nmap/full_scan.nmap $1

	echo -e ""
	echo -e ""
	echo -e ""
}

function checkPing() {
	pingTest=`ping -c 1 -W 3 $1 | grep ttl`
	if [[ -z $pingTest ]]; then
		echo "down"
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

	tmux rename-window -t 1 "bg-tools"
	tmux send-keys -t 1 "cherrytree $2/$2.ctb"
	tmux split -h
	tmux send-keys -t 2 "burpsuite"

	declare -a names=("main" "nmap/web" "misc")
	n=2
	for x in "${names[@]}"; do
	  	tmux new-window -t $n 2>/dev/null || tmux select-window -t $n && tmux rename-window -t $n "$x"

	  	if [ "$n" == "2" ]; then 
	  		mkdir -p $2/{www,recon,nmap}
	  		cp ~/htb/tools/htb_template.ctb $2/ && mv $2/htb_template.ctb $2/$2.ctb
		fi

	 	if [ "$n" == "3" ]; then
	 		tmux kill-pane -a -t 1
			tmux split -h
		fi

		if [ "$n" == "4" ]; then
	 		tmux kill-pane -a -t 1
			tmux split -h
		fi

		n=$(($n+1))
	done

	# Selecting window 3, pane 1 -- setup for running nmapScan
	tmux select-window -t 3 && tmux selectp -t 1

}

reconRecommend(){
	echo -e "${GREEN}---------------------Recon Recommendations----------------------"
	echo -e "${NC}"

	# Verifies that the full_scan.nmap file exists, outputs the ports found into allPorts var
	if [ -f $2/nmap/full_scan.nmap ]; then		
		ports=`cat $2/nmap/full_scan.nmap | grep open | cut -d " " -f 1 | cut -d "/" -f 1 | tr "\n" "," | head -c-1`
		file=`cat $2/nmap/full_scan.nmap | grep -w "open"`

	fi

	osType="$(checkOS $ttl)"

	oldIFS=$IFS
	IFS=$'\n'

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
				echo "ffuf -u https://$1:$port/FUZZ -w /usr/share/wordlists/dirbuster/directory-list-2.3-small.txt -t 40 -r -e $pages -o $2/recon/dirb_$port.txt"
				echo "nikto -host https://$1:$port -ssl | tee $2/recon/nikto_$port.txt"
			else
				echo "ffuf -u https://$1:$port/FUZZ -w /usr/share/wordlists/dirbuster/directory-list-2.3-small.txt -t 40 -r -e $pages -o $2/recon/dirb_$port.txt"
				echo "nikto -host $1:$port | tee $2/recon/nikto_$port.txt"
			fi
			echo ""
		fi
	done

	if [ -f $2/nmap/full_scan.nmap ]; then
	cms=`cat $2/nmap/full_scan.nmapp | grep http-generator | cut -d " " -f 2`
		if [ ! -z `echo "${cms}"` ]; then
			for line in $cms; do
				port=`cat nmap/Basic_$1.nmap | grep $line -B1 | grep -w "open" | cut -d "/" -f 1`
				if [[ "$cms" =~ ^(Joomla|WordPress|Drupal)$ ]]; then
					echo -e "${NC}"
					echo -e "${YELLOW}CMS Recon:"
					echo -e "${NC}"
				fi
				case "$cms" in
					Joomla!) echo "joomscan --url $1:$port | tee $2/recon/joomscan_$port.txt";;
					WordPress) echo "wpscan --url $1:$port --enumerate p | tee $2/recon/wpscan_$port.txt";;
					Drupal) echo "droopescan scan drupal -u $1:$port | tee $2recon/droopescan_$port.txt";;
				esac
			done
		fi
	fi

	if [[ ! -z `echo "${file}" | grep -w "445/tcp"` ]]; then
		echo -e "${NC}"
		echo -e "${YELLOW}SMB Recon:"
		echo -e "${NC}"
		echo "smbmap -H $1 | tee $2/recon/smbmap.txt"
		echo "smbclient -L \"//$1/\" -U \"guest\"% | tee $2/recon/smbclient.txt"
		if [[ $osType == "Windows" ]]; then
			echo "nmap -Pn -p445 --script vuln -oN $2/recon/SMB_vulns.txt $1"
		fi
		if [[ $osType == "Linux" ]]; then
			echo "enum4linux -a $1 | tee $2/recon/enum4linux.txt"
		fi
		echo ""
	elif [[ ! -z `echo "${file}" | grep -w "139/tcp"` ]] && [[ $osType == "Linux" ]]; then
		echo -e "${NC}"
		echo -e "${YELLOW}SMB Recon:"
		echo -e "${NC}"
		echo "enum4linux -a $1 | tee $2/recon/enum4linux.txt"
		echo ""
	fi


	if [ -f $2/nmap/full_scan.nmap ] && [[ ! -z `cat $2/nmap/full_scan.nmap | grep open | grep -w "161/udp"` ]]; then
		echo -e "${NC}"
		echo -e "${YELLOW}SNMP Recon:"
		echo -e "${NC}"
		echo "snmp-check $1 -c public | tee $2/recon/snmpcheck.txt"
		echo ""
	fi


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
	
	reconCommands=`cat $3/recon/recon.txt | grep $2`

	for line in `echo "${reconCommands}"`; do
		currentScan=`echo $line | cut -d " " -f 1 | sed 's/.\///g; s/.py//g; s/cd/odat/g;' | sort -u | tr "\n" "," | sed 's/,/,\ /g' | head -c-2`
		fileName=`echo "${line}" | awk -F "recon/" '{print $2}' | head -c-1`
		if [ ! -z recon/`echo "${fileName}"` ] && [ ! -f recon/`echo "${fileName}"` ]; then
			if [[ "$line" =~ "smbclient"|"smbmap"|"snmp-check"|"enum4linux" ]]; then 
				tmux send-keys -t "$sesID:4.1" " $1 recurse3 $line $currentScan $filename" C-m
			elif [[ "$line" =~ "joomscan"|"wpscan"|"droopescan" ]]; then
				tmux send-keys -t "$sesID:4.2" " $1 recurse3 $line $currentScan $filename" C-m
			else
				echo -e "${NC}"
				echo -e "${YELLOW}Starting $currentScan scan"
				echo -e "${NC}"
				echo $line | /bin/bash
				echo -e "${NC}"
				echo -e "${YELLOW}Finished $currentScan scan"
				echo -e "${NC}"
				echo -e "${YELLOW}========================="
			fi
		fi
	done

	IFS=$oldIFS

	echo -e ""
	echo -e ""
	echo -e ""
}

function displayRecon() {
	sleep .5
	echo -e "${NC}"
	echo -e "${YELLOW}Starting $3 scan"
	echo -e "${NC}"
	echo $2 #| /bin/bash
	echo -e "${NC}"
	echo -e "${YELLOW}Finished $3 scan"
	echo -e "${NC}"
	echo -e "${YELLOW}========================="
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

# nmapScan / tmuxCreate / checkValid
function footer() {
	# Checks if the first arg is a valid IP
	checkValid $1

	if [[ $2 =~ recurse4|recurse3|recurse2 ]]; then
		:
	else	
		if [ "$2" == "recurse1" ]; then
			# Run quick & full scan ($3 is the hostname provided as arg 2 -- if it was provided, if not, then it's the IP)
			nmapScan $1 $3
		else
			# Checks if a hostname was provided, if not then IP will 
			# be used to name files
			name=$2
			if [ -z "$2" ]; then
				name=$1
			fi

			# Create windows & panes
			tmuxCreate $1 $name

			# Call script to run nmapScan in new window/pane
			tmux send-keys "$0 $1 recurse1 $name" C-m
			exit 1
		fi
	fi

	if [[ $2 =~ recurse4|recurse3 ]]; then
		:
	else
		if [ "$2" == "recurse2" ]; then

			reconRecommend $1 $3 | tee $3/recon/recon.txt
			runRecon $0 $1 $3
		else
			# Select pane 1 in window 3
			tmux selectp -t 2

			# Call script to run recondRecommend in new window/pane
			tmux send-keys "$0 $1 recurse2 $3" C-m
			exit 1
		fi
	fi

	if [ "$2" == "recurse3" ]; then
		displayRecon $2 $3 $4
	fi
}

footer $1 $2 $3
