#!/bin/bash

#------colors----------
red="\033[1;31m"
green="\033[1;32m"
yellow="\033[1;33m"
blue='\033[0;34m'  
purple='\033[1;35m'
cyan='\033[1;36m'  
off="\033[0m"
user=$( echo $USER )
#----------------------

while true; do
    while IFS= read -r line
    do
        echo "[+] Pinging $line .."
        OUTPUT=$(ping $line -c 1)
        if [[ $OUTPUT =~ "bytes from" ]]; then
            echo
        else 
            echo -e "$red[-] $line disconnected$off"
            echo "[-] $line disconnected" >> disconnected.log
            sed -i "/$line/d" connected.log
        fi


    done < "connected.log"
done