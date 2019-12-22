# #!/bin/bash

# Colors
NC='\033[0m' # No Color
BBLUE='\033[1;34m'

# Need to know the IP of the target & the hostname
printf "Please only have 1 window open\n"
read -p "target name:"  BOX
read -p "target IP: "  IP

# Checks if the box name has already been added to the hosts file 
if grep -Foq "$BOX" /etc/hosts
then
    echo "Hostname already exists in /etc/hosts"
else
	echo -e "target set to ${BBLUE}$IP${NC}"
	echo "$IP	$BOX.htb" >> /etc/hosts
fi


# Directory Structure

# Creating window 2, and renaming
tmux new-window -t 2 && tmux rename-window -t 2 "htb"

# Creates the file that will contain nmap, cherrytree, ect..
tmux send-keys "cd ~/htb/fortress/ && mkdir $BOX.htb; cd $BOX.htb; mkdir www; mkdir nmap" C-m

# Copies the cherrytree htb template to current dir which is ~/htb/boxes/$BOX.
# Then changes the name of the .ctb file to the box name
tmux send-keys "cp ~/htb/tools/htb_template.ctb . && mv htb_template.ctb $BOX.ctb" C-m


# VPN / Note setup

# Goes to window 1 and renames it
tmux select-window -t 1 && tmux rename-window -t 1 "vpn/note"

# Selects pane 1, runs VPN, and split's pane
tmux selectp -t 1 && tmux send-keys "openvpn ~/htb/tools/JaguarZz.ovpn" C-m && tmux split-window -v

# Selects pane 2, runs cherrytree
tmux selectp -t 2 && sleep .1 && tmux send-keys "cherrytree ~/htb/fortress/$BOX.htb/$BOX.ctb" C-m

# Sleep so that the VPN can get started
sleep 5


# Enumeration tools (add more) nmapautomater for reference

# Creating window 3, and renaming
tmux new-window -t 3 && tmux rename-window -t 3 "tools"

# Spliting window up
tmux split -h && tmux split -v

# Nmap (Somehow need to make this faster.. )
tmux selectp -t 1 \
&& tmux send-keys "nmap -T4 --max-retries 1 --max-scan-delay 20 --defeat-rst-ratelimit $IP \
; nmap -sC -sV -T4 -p- -oN ~/htb/fortress/$BOX.htb/nmap/full_scan.nmap  $IP" C-m # nmap

# Gobuster
tmux selectp -t 2 \
&& tmux send-keys "gobuster dir -w /usr/share/wordlists/SecLists/Discovery/Web-Content/big.txt -u $IP -t 40 -k -l \
; gobuster dir -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -u $IP -x .php,.html -t 40 -k -l" C-m

# Nikto
tmux selectp -t 3 && tmux send-keys "nikto -h $IP" C-m


# Misc

# Creating new window, and renaming it
tmux new-window -t 4 && tmux rename-window -t 4 "burp"

# Launching burp
tmux send-keys "burp-pro" C-m

# Moves current window back to htb (2)
tmux selectw -t 2
