# Clips straight to the clipboard
alias xclip='xclip -selection c'

# Colorize the ls output
alias ls='ls --color=auto'

# Dunno how to fix --no-check-certificate issue
alias wgetno='wget --no-check-certificate'

# Updater
function apt-updater {
        apt-get update &&
        apt-get autoremove -y &&
        apt-get upgrade &&
	    apt-get dist-upgrade &&
        apt-get clean
}

# Git
alias gc='git commit'
alias gs='git status'
alias gl='git pull'
alias gp='git push'
alias ga='git add'
alias gacp='git add . && git commit -m  "automate update" && git push' 


# Pentesting / HTB Commands

# tcpdump "ping catcher"
alias tcpdump-ping='tcpdump -i tun0 icmp'

# VM share
alias vm-share='cd /media/sf_VM-share'

# bring X file here (add windows later)
alias here-lse.sh='cp ~/htb/tools/lse.sh .'
alias here-pspy='~/htb/tools/pspy .'
alias here-jaws='~/htb/tools/jaws-enum.ps1 .'

# server
alias pyserve='python3 -m http.server'

# Start box
alias recon='~/htb/tools/start_box.sh'

# Exploit suggester
alias windows-exploit-suggester='/opt/Windows-Exploit-Suggester/windows-exploit-suggester.py -d 2019-12-12-mssb.xls -i'

# cherry
function htb-cherry() { cherrytree ~/repos/htb/boxes/"$@".ctb; }

# Goto X box file
function gotobox() { cd ~/htb/boxes/"$@".htb; }

# nmap full scan
function nmapfull() { nmap -sC -sV -T4 -p- $1;}

# gobuster full scan (mostly)
function gobustfull() { gobuster dir -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -u $1 -x .php,.html -t 55 -k -l;}

# sub bruter
function ffuf-sub() { length=$(curl --header "Host: xyz" -v -s http://$1 2>&1 | grep -oP '(?<=< Content-Length: ).*' | tr -cd "[:print:]\n") ; ffuf -w /usr/share/wordlists/SecLists/Discovery/DNS/dns-Jhaddix.txt -u $1 -H "Host: $2" --fs "${length}";}

# ffuf dirb
function ffuf-dirb() { ffuf -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -u $1/FUZZ; }

# nc listener
function ncx() { nc -lvnp $1; }

# openvpn
function vpn() {  if [[ -z $(tmux ls | grep vpn) ]]; then tmux new -s vpn -d; tmux send-keys -t vpn:1.1 "openvpn /root/htb/tools/JaguarZz.ovpn" C-m; else tmux send-keys -t vpn:1.1 "openvpn /root/htb/tools/JaguarZz.ovpn" C-m; fi; }
