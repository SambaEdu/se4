# fichier bash à sourcer
#
# fonctions utiles pour générer les configurations des services sambaedu
# 
# Denis Bonnenfant
#

function cdr2mask()
{
   # Number of args to shift, 255..255, first non-255 byte, zeroes
   set -- $(( 5 - ($1 / 8) )) 255 255 255 255 $(( (255 << (8 - ($1 % 8))) & 255 )) 0 0 0
   [ $1 -gt 1 ] && shift $1 || shift
   echo ${1-0}.${2-0}.${3-0}.${4-0}
}

# Fonction permettant de récuperer la configuration réseau complète
# 

function my_network() {


read my_gateway my_interface<<<$(ip -o -f inet route show default 0.0.0.0/0 | cut -d ' ' -f3,5)
read my_address my_cdr my_broadcast<<<$(ip -o -f inet addr show dev "$my_interface" | awk '{sub("/", " ", $4); print $4, $6}')
my_mask=$(cdr2mask $my_cdr)
my_network=$(ip -o -f inet route show dev $my_interface  src $my_address | cut -d/ -f1)
my_hostname=$(hostname -s)
my_domain=$(hostname -d)
my_fqdn=$(hostname -f)
# attention ne donne pas le dns externe si ad est configuré
my_dnsserver=$(grep -m 1 "^nameserver" /etc/resolv.conf | cut -d" " -f2)
my_proxy="$http_proxy"
if [ -e "etc/sambaedu/sambaedu.conf.d/dhcp.conf" ]; then
    my_vlan=$(grep $my_network /etc/sambaedu/sambaedu.conf.d/dhcpd.conf | cut -d= -f1 | sed "s/^.*_//")
fi
}


# Dialogue de configuration dhcp minimale
function conf_dhcp()
{
dhcp_title="Configuration dhcp minimale du serveur"
tempfile=/tmp/menu
REPONSE=""
my_network
dhcp_begin_range=$(echo $my_network | sed "s/\.[0-9]*$/.100/")
dhcp_end_range=$(echo $my_network | sed "s/\.[0-9]*$/.200/")

if [ "DEBIAN_FRONTEND" != "noninteractive" ] && [ "DEBIAN_PRIORITY" != "low" ]; then

while [ "$REPONSE" != "yes" ]
do
	dialog --backtitle "$BACKTITLE" --title "$dhcp_title" --inputbox "Saisir le début de la plage dynamique" 15 70 $dhcp_begin_range 2>$tempfile || erreur "Annulation"
	dhcp_begin_range=$(cat $tempfile)

	dialog --backtitle "$BACKTITLE" --title "$dhcp_title" --inputbox "Saisir le début de la plage dynamique" 15 70 $dhcp_end_range 2>$tempfile || erreur "Annulation"
	dhcp_end_range=$(cat $tempfile)

	
	confirm_title="Récapitulatif de la configuration prévue"
	confirm_txt="Interface :  $my_interface
IP :         $my_address
Masque :     $my_mask
Réseau :     $my_network
Broadcast :  $my_broadcast
Passerelle : $my_gateway
Début plage dhcp : $dhcp_begin_range
Fin plage dhcp : $dhcp_end_range

Confirmer l'enregistrement de cette configuration ?"
		
		if (dialog --backtitle "$BACKTITLE" --title "$confirm_title" --yesno "$confirm_txt" 20 60) then
            REPONSE="yes" 
        else    
 			REPONSE="no"
		fi	
done

echo -e "$COLTXT"
fi
}

function erreur()
{
        echo -e "$COLERREUR"
        echo "ERREUR!"
        echo -e "$1"
        echo -e "$COLTXT"
        exit 1
}


function couleurs() {
# vt220 sucks !
[ "$TERM" = "vt220" ] && TERM="linux"

#Variables :

#Couleurs
COLTITRE="\033[1;35m"   # Rose
COLDEFAUT="\033[0;33m"  # Brun-jaune
COLCMD="\033[1;37m\c"     # Blanc
COLERREUR="\033[1;31m"  # Rouge
COLTXT="\033[0;37m\c"     # Gris avec coupure
COLTXL="\033[0;37m"     # Gris 
COLINFO="\033[0;36m\c"	# Cyan
COLPARTIE="\n\033[1;34m\c"	# Bleu
COLDEFAUT="\033[0;33m"  # Brun-jaune
COLSAISIE="\033[1;32m"  # Vert
}
