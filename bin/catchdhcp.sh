#!/bin/bash

iface="wlp3s0"

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

function banner() {

echo -e " "

}
function analyse(){

    declare -a macaddrs;
    declare -a ipaddrs;
    declare -a hnames;

    CADDRS=$( sudo tcpdump -ttttvnnr dhcpinfo.pcap | grep Client-Ethernet-Address | cut -d " " -f 4 | uniq )
    IPADDR=$( sudo tcpdump -ttttvnnr dhcpinfo.pcap | grep Requested-IP | cut -d ":" -f 2 | sed 's/ //g' )
    HNAMES=$( sudo tcpdump -ttttvnnr dhcpinfo.pcap | grep Hostname | uniq | cut -d '"' -f 2 )

    if [[ ! $CADDRS = "" ]]; then
        i=0
        for mac in $CADDRS
        do
            macaddrs[$i]=$mac
            i=$(( $i + 1 ))
        done
        i=0
        for ip in $IPADDR
        do
            ipaddrs[$i]=$ip
            i=$(( $i + 1 ))
        done
        i=0
        for hname in $HNAMES
        do
            hnames[$i]=$hname
            i=$(( $i + 1 ))
        done

        k=0
        c=0
        for i in "${macaddrs[@]}"
        do
            echo
            echo -e "$green[+] Client : $i | ${ipaddrs[$k]} | ${hnames[$k]}$off"
            echo
            echo ${ipaddrs[$k]} >> connected.log
            c=$(( $c + 1 ))
        done
    else
        echo
        echo -e "$red[-] No one new has been connected.$off"
        echo
    fi
}

./checkConnected.sh > /dev/null 2>&1 &
pid_check=$!

catchit=$( cat /home/oba/Bureau/projet-technicien/config.txt | head -n 4 | tail -n 1 | cut -d'{' -f2 | sed 's/}//' )

while true; do

connected=$( cat connected.log | xargs | sed 's/ / | /g' )
disconnected=$( cat disconnected.log | xargs | sed 's/ / | /g' )
long_conn=$( cat connected.log | xargs | sed 's/ / | /g' | wc -l )
long_dis=$( cat disconnected.log | xargs | sed 's/ / | /g' | wc -l )

    tcpdump -i $iface -pvn port 67 and port 68 -w dhcpinfo.pcap > /dev/null 2>&1 &
    pid=$!
    echo -e "$blue > Sniffing for 10 secs.$off"
    sleep 10
    kill $pid
    sleep 2
    analyse
    echo
    echo "+=====[disconnected.log]=====+"
    cat disconnected.log
    > disconnected.log
    echo "+============================+"
    echo "+=====[connected.log]=====+"
    cat connected.log
    echo "+============================+"
    if [ $long_conn > 0 ]; then
sed -i "4s/${catchit}/${connected}/" /home/oba/Bureau/projet-technicien/config.txt

    fi

    if [ $long_dis > 0 ]; then
sed -i "4s/${catchit}/ ${disconnected}/" /home/oba/Bureau/projet-technicien/config.txt

    fi


done