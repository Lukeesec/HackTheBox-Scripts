# #!/bin/bash

# Ugliest bash you'll see... Need to reformat, and rethink what the heck
# I'm doing writing this

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

usage(){
echo -e "${RED}Usage: $0 <TARGET-IP> <HOSTNAME> <VPN>"
echo -e "${YELLOW}"
echo -e "\tVpn:   Starts VPN"
echo -e ""
exit 1
}

IP="$1"
BOX="$2"

# Checks for 1 argument
if (( "$#" == 0 )); then
	usage
fi

# Creates a new session, then attachs to that session
# tmux has-session -t $BOX
# if [ $? != 0 ] 2>/dev/null
# then
# 	tmux new -s $BOX -d
#         tmux switch-client -t $BOX
# else
# 	echo -e "${RED}Session already exists"
# 	exit
# fi

# Checks if hostname is in /etc/hosts
if grep -Foq "$BOX" /etc/hosts
then
    echo "Hostname already exists in /etc/hosts"
else
	echo -e "${YELLOW} target set to $IP${NC}"
	echo "$IP	$BOX.htb" >> /etc/hosts
fi

# Goes to window 1 and renames it
tmux select-window -t 1 && tmux rename-window -t 1 "vpn/cherry"

# Selects pane 1
tmux selectp -t 1 

# Checks if VPN option was selected.. If so then starts vpn & cherry, if not starts cherry
shopt -s nocasematch
case "vpn" in
 "$3" ) tmux send-keys "cherrytree ~/htb/boxes/$BOX.htb/$BOX.ctb" C-m \
&& tmux split-window -v \
&& tmux selectp -t 2 \
&& tmux send-keys "openvpn ~/htb/tools/JaguarZz.ovpn" C-m \
&& sleep 8;;
 *) tmux send-keys "cherrytree ~/htb/boxes/$BOX.htb/$BOX.ctb" C-m;;
esac


# Creating window 2, and renaming
tmux new-window -t 2 && tmux rename-window -t 2 "htb"

# Creates the file that will contain nmap, cherrytree, ect..
tmux send-keys "cd ~/htb/boxes/ && mkdir $BOX.htb; cd $BOX.htb; mkdir www; mkdir http;  mkdir nmap" C-m

# Copies the cherrytree htb template to current dir which is ~/htb/boxes/$BOX.
# Then changes the name of the .ctb file to the box name
tmux send-keys "cp ~/htb/tools/htb_template.ctb . && mv htb_template.ctb $BOX.ctb" C-m


# Creating window 3, and renaming
tmux new-window -t 3 && tmux rename-window -t 3 "tools"

# Spliting window up
tmux split -h && tmux split -v

# # Nmap
tmux selectp -t 1 \
&& tmux send-keys "nmap -T4 --max-retries 1 --max-scan-delay 20 --defeat-rst-ratelimit $IP \
; nmap -sC -sV -T4 -p- -oN ~/htb/boxes/$BOX.htb/nmap/full_scan.nmap  $IP" C-m

# -f -- True if file exists and is a regular file
# Checks if full_$1 exists, then checks if quick_$1 exists
# If both are true, then cat both full & quick, else cat full
#if [ -f ~/htb/boxes/$BOX.htb/nmap/full_scan.nmap ]; then
#		ports=`cat ~/htb/boxes/$BOX.htb/nmap/full_scan.nmap | grep open | cut -d " " -f 1 | cut -d "/" -f 1 | tr "\n" "," | head -c-1`
#fi

#tmux send-keys 'nmap -sV --script vuln -p`echo "${ports}"` -oN ~/htb/boxes/$BOX.htb/nmap/vuln_scan.nmap $IP' C-m

# Gobuster
tmux selectp -t 2 \
&& tmux send-keys "gobuster dir -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -x .php -t 45 -l -k -o ~/htb/boxes/$BOX.htb/http/root.dir" -u $IP" C-m

# Nikto
tmux selectp -t 3 && tmux send-keys "nikto -h $IP | tee ~/htb/boxes/$BOX.htb/http/nikto-$IP" C-m


# Creating new window, and renaming it
tmux new-window -t 4 && tmux rename-window -t 4 "burp"

# Launching burp
tmux send-keys "burp-pro" C-m

# Moves current window back to htb (2)
tmux selectw -t 2























