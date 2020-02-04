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



function liste_addr() {

echo -e "${yellow}[!]-Scanning your network ..${off}"
nmap -F 192.168.2.0/24 > tr069.txt
cat tr069.txt | grep -o '[0-9].[0-9].[0-9].[0-9].[0-9].[0-9].[0-9]*' | tr -d ')' | sed 's/ //g' | uniq > list.txt
liste=$(cat tr069.txt | grep -o '[0-9].[0-9].[0-9].[0-9].[0-9].[0-9].[0-9]*' | tr -d ')')

input="list.txt"
echo -e "+--------------------------------------------------------+"
echo -e "||${green}                    CONNECTED ADDRESSES               ${off}||"
echo -e "+--------------------------------------------------------+"
while IFS= read -r line
do
length=$(echo $line | wc -c)
if [[ $length == 12 ]];then
echo -e "||                       $line                    ||"

elif [[ $length == 13 ]];then
echo -e "||                       $line                   ||"

elif [[ $length == 14 ]];then
echo -e "||                       $line                  ||"



fi

done < "$input"
echo -e "+--------------------------------------------------------+"
echo -e "${green}"

}

function ping_req() {
catchit3=$( cat config.txt | head -n 3 | tail -n 1 | cut -d'{' -f2 | sed 's/}//g' )
while true; do

    inter=$( ip addr | grep inet | grep brd  | grep "noprefixroute" | awk '{print $9}' )
    echo -e "${cyan}Start Listenig For Every 10 sec..${off}"
    sleep 2
    xterm -e "sudo tcpdump -i $inter icmp and icmp[icmptype]=icmp-echo > ping.txt" &
    sleep 10
    last_id=$( pgrep --newest xterm ) 
    kill  $last_id


    pack_number=$( cat ping.txt | cut -f1,2,3 -d" "  | sort -u | wc -l  )



    if [[ $pack_number == 1 ]];then
    sed -i "3s/${catchit3}/0 PACKS/" config.txt
    echo -e "\nTOTAL ICMP PACKET RECIEVE :${red} $pack_number ${off}  ${yellow}[--+${off} ${blue}IF YOU ONLY RECIEVE ${red}1${off} ${blue}PACKET IT MEANS THE => IP HEADER ! ${off}${yellow}+--]${off}"
    
    break
    else
    sed -i "3s/${catchit3}/${pack_number} PACKS/" config.txt
    echo -e "TOTAL ICMP PACKET RECIEVE :${red} $pack_number ${off} "
   
    break
    echo -e "${off}"
    echo -e "TIME         -      FROM"
    cat ping.txt | cut -f1,2,3 -d" "  | sort -u | uniq
    echo -e "\n"
    sleep 5
    fi
done
}

function web_index(){

#-----------------genering index HTML extension-------------------------

echo -e "\n${yellow}CREATING INDEX TO THE CLIENT.. ${off}"
sleep 2

client_addr=$( ip addr | grep inet | grep brd | head -n 1 | awk '{print $2}' | cut -d"/" -f1 )
client_interface=$( ip addr | grep inet | grep brd  | grep "noprefixroute" | awk '{print $9}' )
inp="ping.txt"

pack_num=$( cat ping.txt | cut -f1,2,3 -d" "  | sort -u | wc -l  )
pack_number=$(( $pack_num - 1 ))

echo -e "<head>
<body>
<p>" > /var/www/html/icmp_diag.html

echo -e " CLIENT ADDRESS : $client_addr \n" >> /var/www/html/icmp_diag.html
echo -e "<BR>" >> /var/www/html/icmp_diag.html
echo -e " CLIENT INTERFACE : $client_interface \n\n" >> /var/www/html/icmp_diag.html
echo -e "<BR>" >> /var/www/html/icmp_diag.html
echo -e " ICMP PACK RECEIVED : $pack_number \n\n" >> /var/www/html/icmp_diag.html
echo -e "<BR>" >> /var/www/html/icmp_diag.html



echo -e "<h3>ICMP TRAFFIC HISTORY : </h3>" >> /var/www/html/icmp_diag.html
echo -e "<BR>" >> /var/www/html/icmp_diag.html

while IFS= read -r line
do

echo $line | cut -f1,2,3 -d" "  | sort -u >> /var/www/html/icmp_diag.html
echo -e "<BR>" >> /var/www/html/icmp_diag.html

done < "$inp"


echo -e "</p>
</body>
</head>
" >> /var/www/html/icmp_diag.html

}

function sendto_server() {
echo -e "\n"

echo -n "[!]- Give Me The Server IP : "

read serv_add
echo -e "${red}[!]-${off}YOU SHOULD START UP THE SERVER TO SEND DATA ! .."
sleep 3 

}

function connected_servers() {
catchit5=$( cat config.txt | head -n 5 | tail -n 1 | cut -d'{' -f2 | sed 's/}//g' )

sudo netstat -ntla | grep ESTABLISHED > netstat.txt

netst="netstat.txt"
echo -e "${green}[!]-${off}GENERATING CONNEXIONS STATUS .."
sleep 3
echo -e "<BR>" >> /var/www/html/icmp_diag.html

echo -e "<h2> les connections internet actives : </h2>" >> /var/www/html/icmp_diag.html
echo -e "<BR>" >> /var/www/html/icmp_diag.html
echo -e "<h4>" >> /var/www/html/icmp_diag.html
echo -e "       Adresse Local :Port        Adresse Distante:Port" >> /var/www/html/icmp_diag.html
echo -e "<BR>" >> /var/www/html/icmp_diag.html
while IFS= read -r line
do

echo $line  >> /var/www/html/icmp_diag.html
echo -e "<BR>" >> /var/www/html/icmp_diag.html


done < "$netst"
echo -e "</h4>" >> /var/www/html/icmp_diag.html


echo -e "${green}[+]-${off}SENDING CONNECTIONS STATUS TO THE SERVER ..\n"
./soc/client $serv_add /var/www/html/icmp_diag.html #appel du client pour envoyer l'index
sed -i "5s/${catchit5}/SENT TO SERVER/" config.txt
echo -e "${green}[+]-${off}DATA SENT WITH SUCCESS \n"

}

function arp() {
banner
real_gateway=$( sudo route -n | grep "UG" | awk '{print $2}' )
mac_gateway=$( sudo arp -a | grep $real_gateway | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' )
sudo arp -a | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' > all_arp_mac.txt
file="all_arp_mac.txt"
sudo arp -a | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" >arp_addr.txt
echo "your gateway is $real_gateway"
sleep 1
echo "your BSSID : $mac_gateway"
sleep 2
k=0
line=0
while IFS= read -r line
do
#echo -e " $line "
l=$(( $l + 1 ))
#echo -e "ra9m ligne : $l"
#sleep 3
if [[ $line == $mac_gateway ]];then
k=$(( $k + 1 ))
#echo -e "9adeh men ligne l9a kifkif $k"
#sleep 2 
catchit=$( cat config.txt | head -n 1 | cut -d'{' -f2 | sed 's/}//g' )
thisisit=$( cat arp_addr.txt | grep -n '' | grep "^$l" | sed "s/$l://g" )

    if [ $k == 2 ]; then
        echo -e "${red}[-] You Are Attacked With arp Spoof From $thisisit !${off}"
        sed -i "1s/${catchit}/SPOOFED/" config.txt
        sleep 2
        echo -e "${yellow}[!] Do You want to Detect Who spoofing you [yes/no]?${off}"
        echo -n "<choice> "
        read choix
        if [ $choix == "yes" || $choix == "YES" ]; then
#--------------------------------------------------------------------
    echo -e "\n${green}Detection of Version + Open Ports..  - [ ${yellow}Wait a second !${off}]"
        echo -e "\n"
        echo -e "<h3>Detection of Version + Open Ports :</h3>" >> /var/www/html/icmp_diag.html
        echo -e "<BR>" >> /var/www/html/icmp_diag.html
    nmap -sV $hacker_addr > hacker.txt
    service_info=$( cat hacker.txt | grep 'Service Info' )
    port_scan=$( cat hacker.txt | grep tcp )
    echo -e "${yellow}+-------------------------------------------------------------+${off}"
        echo -e "<h3>+-------------------------------------------------------------------------------------------------------------------------------------+</h3>" >> /var/www/html/icmp_diag.html
        echo -e "<BR>" >> /var/www/html/icmp_diag.html
    echo -e "${red}$service_info ${off}"
        echo -e "$service_info" >> /var/www/html/icmp_diag.html
        echo -e "<BR>" >> /var/www/html/icmp_diag.html
    echo -e "${yellow}+-------------------------------------------------------------+${off}"
        echo -e "<h3>+-------------------------------------------------------------------------------------------------------------------------------------+</h3>" >> /var/www/html/icmp_diag.html
        echo -e "<BR>" >> /var/www/html/icmp_diag.html
    echo -e "$port_scan"
        echo -e "$port_scan" >> /var/www/html/icmp_diag.html
        echo -e "<BR>" >> /var/www/html/icmp_diag.html
    echo -e "${yellow}+-------------------------------------------------------------+${off}"
    echo -e "\n"
        echo -e "<h3>+-------------------------------------------------------------------------------------------------------------------------------------+</h3>" >> /var/www/html/icmp_diag.html
        echo -e "<BR>" >> /var/www/html/icmp_diag.html
    echo -e "\n"
    tcp-dumper 
#-------------------------------------------------------
        fi
    break
    fi
fi
done < "$file"
echo -e "${green}[+] NO ARPSPOOF DETECTED , YOU ARE SAFE !${off}"
sleep 2

sed -i "1s/${catchit}/SAFE/" config.txt

}

function tcp-dumper() {

my_interface=$( ip addr | grep inet | grep brd  | grep "noprefixroute" | awk '{print $9}' )
echo -e "${yellow}+------------------------------------------------------------------------------+${off}"
    echo -e "${purple}[+]-Starting ..${off}"
    echo -e "${yellow}+--------------------------------------------------------------------------------------------------------------+${off}"
    echo -e "${yellow}TARGET IP      -          DESTINATION        -            RESOLUTION DNS DIRECTE OF DESTINATION ${off}"
    echo -e "${yellow}+--------------------------------------------------------------------------------------------------------------+${off}"
    sleep 2
    
    sudo  tshark -i $my_interface | grep $attacker  &&  sleep 5 && pshark_id=$( pgrep --newest tshark ) && sudo kill  $pshark_id
    echo -e "${yellow}+----------------------------------------------------------------------------------------------------------------+${off}"

}

function dns_spoof_detection() {
echo -e "<h2>CONSULTING DNS SPOOF ATTACKS : </h2>" >> /var/www/html/icmp_diag.html
echo -e "<BR>" >> /var/www/html/icmp_diag.html
echo -e "${green}[+]-START SCANNING DNS PACKETS..  ${off}<It Takes 12 Seconds> "
var1=$( netstat -ntla  | grep TIME_WAIT | awk '{print $5}' | sed 's/:[0-9][0-9][0-9]*//g' | tail -n 1 )
catchit2=$( cat config.txt | head -n 2 | tail -n 1 | cut -d'{' -f2 | sed 's/}//' )
xterm -e 'ping kiteb.net  > dns.txt' &
sleep 12 
pingid=$( pgrep --newest xterm ) 
sudo kill $pingid
parallel=$( cat dns.txt | grep from | tail -n 1 | awk '{print $4}' | sed 's/://g' )

if [[ $var1 == $parallel ]];then
echo -e "${red}[!]-${off}You Are ATTACKED WITH DNS SPOOF FROM ${red} $var1 ${off}, ${blue}WATCH OUT YOUR TRAFFIC !${off}"
  sed -i "2s/${catchit2}/ATTACKED/" config.txt
echo -e "<h2>[!] HACKER MACHINE : </h2>" >> /var/www/html/icmp_diag.html
echo -e "<BR>" >> /var/www/html/icmp_diag.html
echo -e "[!]-This Client ATTACKED WITH DNS SPOOF FROM $var1 " >> /var/www/html/icmp_diag.html
echo -e "<BR>" >> /var/www/html/icmp_diag.html

sleep 2
echo -e "${yellow}[!]-DO YOU WANT TO BLOC THIS IP <yes/no> : ${off} $VAR1"
read decision

    if [[ $decision == "yes" || $decision == "YES" ]];then
    sudo iptables -A INPUT -p ICMP -s $parallel -j DROP
    sudo iptables -A INPUT -p tcp -s $parallel -j DROP     
    sudo iptables -A INPUT -p tcp -m multiport --dport 21,22,23,24,80,443 -s $parallel -j DROP
        echo -e "<h2>ADDING FIREWALL RULES :</h2>" >> /var/www/html/icmp_diag.html
        echo -e "<BR>" >> /var/www/html/icmp_diag.html
        echo -e "PROTO  : TCP ==> DROPED" >> /var/www/html/icmp_diag.html
        echo -e "<BR>" >> /var/www/html/icmp_diag.html
        echo -e "PROTO  : ICMP ==> DROPED" >> /var/www/html/icmp_diag.html
        echo -e "<BR>" >> /var/www/html/icmp_diag.html
        echo -e "PROTO  : USING PORTS (21,22,23,24,80,443) ==> DROPED" >> /var/www/html/icmp_diag.html
        echo -e "<BR>" >> /var/www/html/icmp_diag.html
    fi
    echo -e "${green}[+]- Restarting All Networking Service .. [${cyan} This Is Necessary !! ${off}]"
    sleep 2
    sudo service network-manager restart
else
echo -e "${green}[+]-${off} Your Traffic Is Not Spoofed With DNS ,${green} It's Safe ${off}"
sed -i "2s/${catchit2}/SAFE/" config.txt
echo -e "Your Traffic Is Safe For This Moment " >> /var/www/html/icmp_diag.html
        echo -e "<BR>" >> /var/www/html/icmp_diag.html
        sleep 2
fi

}

function banner() {
echo -e "${yellow}"
cat banner.txt
echo -e "${off}"
}

function arp_sniffer() {
banner
sleep 1

echo -e "${yellow}[!]-Starting ARP Sniffer.. ${off}"
sleep 3
interface=$( ip addr | grep inet | grep brd  | grep "noprefixroute" | awk '{print $9}' )

sudo ./arpsniffer $interface

}


function tcp_sniffer() {
banner
sleep 1
echo -e "${yellow}[!]-Starting Tcp Sniffer.. ${off}"
sleep 3
interface=$( ip addr | grep inet | grep brd  | grep "noprefixroute" | awk '{print $9}' )

sudo ./tcpsyndos $interface
}

function show_config() {
    banner
echo -e "${blue}+-------------------------------------------------+${off}"
cat config.txt | grep -E  --color=always "[A-Z]"
echo -e "${blue}+-------------------------------------------------+${off}"
}

function initial_conf() {

echo -e "ARP ANALYSE     |  {NULL}" > config.txt 
echo -e "DNS ANALYSE     |  {NULL}"  >> config.txt    
echo -e "ICMP ANALYSE    |  {NULL}"  >>config.txt 
echo -e "CONNECTED HOST  |  {NULL}"  >> config.txt 
echo -e "CREATION INDEX  |  {NULL}" >> config.txt 

}

function dhcp_flood() {

command -v dhcpstarv >/dev/null 2>&1 || { echo -e "${red}[-] need to install DHCPSTARV.. ";sleep 1 ; apt-get install dhcpstarv ;}

interface=$( ip addr | grep inet | grep brd  | grep "noprefixroute" | awk '{print $9}' )
echo -e "${yellow}[+]${green} STARTING SNIFFING FOR INCOMING DHCP DATA...\n${off} "

sleep 2 

sudo dhcpstarv -i $interface -v

}
#-------------------------------------------------------- MAIN --------------------------------------------------------------------


while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`

    case $PARAM in
        -h | --help)
        banner
     echo -e "${blue}+------------------------------------------------------------------------------------+${off}
-h  | --help :${blue} Help menu.${off}
-ci | --Consultation-info ${green}OR${off} -rc ${green}To Reload Config :${blue} Showing Configuration Details.${off}
-l  | --liste-addr : ${blue}Show ALL IP in Same Network .${off}
-p  | --ping-request :${blue} Detection des packets ICMP Envoyées Vers Ta Machine. ${off}
-a  | --arp-scan :${blue} Detection ARP poisoning attack.  ${off}
-d  | --dns-spoofscan :${blue} Detection DNS SPOOF attack.  ${off}
-b  | --build-index :${blue} Build a HTML index and send it to The Administation Server.  ${off}
-C  | --catch-dhcp :${blue} Check and catch Every New Client Request a DHCP DISCOVER.  ${off}
-as | --arp-sniffer :${blue}Start ARP SNIFER ==> built with libpcap ©.${off}
-ts | --tcp-sniffer : ${blue} Start a TCP sniffer 'sniff all packet'==> built with libpcap © .${off}
-sd | --scan-dhcp :  ${blue} Scan All The Incoming DHCP DATA .${off}
-sc | --start-compile : ${blue} Compile All C files .${off}
${blue}+------------------------------------------------------------------------------------+${off}
"
            exit
            ;;
        -l | --liste-addr)
            liste_addr
            ;;
        -p | --ping-request)
            ping_req
            ;;
        -a | --arp-scan)
            arp
            ;; 
        -d | --dns-spoof-scan)

        dns_spoof_detection           
             ;;
        -b | --build-index)
        web_index 
        sendto_server
        connected_servers
            ;;       

        -C | --catch-dhcp)
        ./bin/catchdhcp.sh
            ;;

        -as | --arp-sniffer)
        arp_sniffer
            ;;
        -sc | --start-compile)
    gcc tcpsyndos.c -o tcpsyndos -lpcap           
    gcc arpsniffer.c -o arpsniffer -lpcap
            ;;
        -ts | --tcp-sniff)
        tcp_sniffer
            ;;
        -ci | --consultation-info)
        show_config
            ;;
        -rc | --reload_config)
            initial_conf
            ;;

        -sd | --scan-dhcp)
        dhcp_flood
            ;;
        *)
            echo -e "${red}[-]- ERROR: unknown parameter \"$PARAM\" ${off}"
         
            exit 1
            ;;
    esac
    shift
done


