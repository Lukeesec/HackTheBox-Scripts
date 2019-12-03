#!/bin/bash

# May convert to python for ease..

printf "Starting session\n"

# Current box info
read -p "target name:"  BOX
read -p "target IP:"  IP
echo "target set to $IP"

# Creates the file that will contain nmap, cherrytree, ect..
cd ~/htb/boxes/ ; mkdir $BOX.htb ; cd $BOX.htb ; mkdir www ; mkdir nmap
cp ~/htb/tools/htb_template.ctb .; mv htb_template.ctb $BOX.ctb

# Goes to window 1; stars openvpn & cherrytree (I have my windows pre split (tmux-ressurect)) So this will only work if they are pre-split
tmux select-window -t $session:1
tmux selectp -t 1 ; tmux send-keys "openvpn JaguarZz.ovpn" C-m
sleep 3
tmux selectp -t 2 ; tmux send-keys "cherrytree ~/htb/boxes/$BOX.htb/$BOX.ctb" C-m
printf "OpeVPN & Cherrytree started\n"

# Starts nmap,nikto, and gobuster
tmux select-window -t $session:3
tmux selectp -t 1 ; tmux send-keys "nmap -T4 --max-retries 1 --max-scan-delay 20 --defeat-rst-ratelimit $IP; nmap -sC -sV -T4 -p- -oN ~/htb/boxes/$BOX.htb/nmap/full_scan.nmap  $IP" C-m # nmap
tmux selectp -t 2 ; tmux send-keys "gobuster dir -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -u $IP -t 30; gobuster dir -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -u $IP -x .php,.txt,.html,.conf -t 30" C-m # gobuster
tmux selectp -t 3 ; tmux send-keys "nikto -h $IP" C-m # nikto



