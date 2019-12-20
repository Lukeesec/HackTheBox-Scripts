#!/bin/bash
# gobuster dir -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -u $1 -x .php,.html -t 55 -k -l

# My idea of this project.. 
# Make 2 scripts.. One to interact with Tmux, and the other to interact with bash..
# So in tmux it'd be `tmux send-keys "/bash/script/test.sh <some arg to be passed>`"
# Which woud call test.sh, and run one of it's functions based on the input from the 
# Tmux script..

# In this script I'll need to use purely functions, and if statements checking the input from
# the first script, then deciding what to do.. Run nmap ? gobuster ? etc

IP=$1
HOST=$2
VPN=$3

function test()
{
	nmap -sC -sV -T4 "$IP"
}

# Adds hostname to /etc/hosts if arg is provided
function hostAddr()
{
	if [ -z "$HOST" ]
	then
		echo -e "Hostname not provied"
	else
		if grep -Foq "$HOST" /etc/hosts
		then
		    echo "Hostname already exists in /etc/hosts"
		else
			echo -e "${YELLOW} target set to $IP${NC}"
			echo "$IP	$HOST.htb" >> /etc/hosts
		fi
	fi
}













