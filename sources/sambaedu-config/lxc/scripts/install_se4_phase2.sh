#!/bin/bash
# installation LXC se4 phase 2
# version pour Stretch - franck molle
# version 12 - 2017 1st version

#Couleurs
COLTITRE="\033[1;35m"   # Rose
COLDEFAUT="\033[0;33m"  # Brun-jaune
COLCMD="\033[1;37m"     # Blanc
COLERREUR="\033[1;31m"  # Rouge
COLTXT="\033[0;37m"     # Gris
COLINFO="\033[0;36m"	# Cyan
COLPARTIE="\033[1;34m"	# Bleu

function erreur()
{
	echo -e "$COLERREUR"
	echo "ERREUR!"
	echo -e "$1"
	echo -e "$COLTXT"
	exit 1
}



function poursuivre()
{
        REPONSE=""
        while [ "$REPONSE" != "o" -a "$REPONSE" != "O" -a "$REPONSE" != "n" ]
        do
                echo -e "$COLTXT"
                echo -e "Peut-on poursuivre? (${COLCHOIX}O/n${COLTXT}) $COLSAISIE\c"
                read REPONSE
                if [ -z "$REPONSE" ]; then
                        REPONSE="o"
                fi
        done

        if [ "$REPONSE" != "o" -a "$REPONSE" != "O" ]; then
                erreur "Abandon!"
        fi
}

function gensourcelist()
{
cat >/etc/apt/sources.list <<END
# Sources standard:
deb http://ftp.fr.debian.org/debian/ stretch main non-free contrib

# Security Updates:
deb http://security.debian.org/ stretch/updates main contrib non-free

# stretch-updates
deb http://ftp.fr.debian.org/debian/ stretch-updates main contrib non-free

# stretch-backports
#deb http://ftp.fr.debian.org/debian/ stretch-backports main


END
}

function gensourcese4()
{

cat >/etc/apt/sources.list.d/se4.list <<END
# sources pour se4
deb http://wawadeb.crdp.ac-caen.fr/debian stretch se4

#### Sources testing desactivee en prod ####
#deb http://wawadeb.crdp.ac-caen.fr/debian stretch se4testing

END
}


gennetwork()
{
echo "saisir l'ip de la machine"
read NEW_SE3IP
echo "saisir le masque"
read NEW_NETMASK
echo "saisir l'adresse du réseau"
read NEW_NETWORK
echo "saisir l'adresse de brodcast"
read NEW_BROADCAST
echo "saisir l'adresse de la passerrelle"
read NEW_GATEWAY

echo -e "$COLINFO"
echo "Vous vous apprêtez à modifier les paramètres suivants:"
echo -e "IP:		$NEW_SE3IP"
echo -e "Masque:		$NEW_NETMASK"
echo -e "Réseau:		$NEW_NETWORK"
echo -e "Broadcast:	$NEW_BROADCAST"
echo -e "Passerelle:	$NEW_GATEWAY"

poursuivre

cat >/etc/network/interfaces <<END
# /etc/network/interfaces -- configuration file for ifup(8), ifdown(8)

# The loopback interface
auto lo
iface lo inet loopback

# The first network card - this entry was created during the Debian installation
# (network, broadcast and gateway are optional)
auto eth0
iface eth0 inet static
        address $NEW_SE3IP
        netmask $NEW_NETMASK
        network $NEW_NETWORK
        broadcast $NEW_BROADCAST
        gateway $NEW_GATEWAY
END

cat >/etc/hosts <<END
127.0.0.1       localhost
$NEW_SE3IP    se4ad.domaine.ac-rouen.fr        se4ad

# The following lines are desirable for IPv6 capable hosts
# (added automatically by netbase upgrade)

::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
END

cat >/etc/hostname <<END
se4ad
END

cat >/etc/resolv.conf<<END
search etab.ac-rouen.fr
nameserver $NEW_GATEWAY
END

}

function show_title()
{

clear

echo -e "$COLTITRE"
echo "--------------------------------------------------------------------------------"
echo "L'installeur est maintenant sur le point de configurer SambaEdu4-AD."
echo "--------------------------------------------------------------------------------"
echo -e "$COLTXT"
}

function test_ecard()
{
ECARD=$(/sbin/ifconfig | grep eth | sort | head -n 1 | cut -d " " -f 1)
if [ -z "$ECARD" ]; then
  ECARD=$(/sbin/ifconfig -a | grep eth | sort | head -n 1 | cut -d " " -f 1)

	if [ -z "$ECARD" ]; then
		echo -e "$COLERREUR"
		echo "Aucune carte réseau n'a été détectée."
		echo "Il n'est pas souhaitable de poursuivre l'installation."
		echo -e "$COLTXT"
		echo -e "Voulez-vous ne pas tenir compte de cet avertissement (${COLCHOIX}1${COLTXT}),"
		echo -e "ou préférez-vous interrompre le script d'installation (${COLCHOIX}2${COLTXT})"
		echo -e "et corriger le problème avant de relancer ce script?"
		REPONSE=""
		while [ "$REPONSE" != "1" -a "$REPONSE" != "2" ]
		do
			echo -e "${COLTXT}Votre choix: [${COLDEFAUT}2${COLTXT}] ${COLSAISIE}\c"
			read REPONSE
	
			if [ -z "$REPONSE" ]; then
				REPONSE=2
			fi
		done
		if [ "$REPONSE" = "2" ]; then
			echo -e "$COLINFO"
			echo "Pour résoudre ce problème, chargez le pilote approprié."
			echo "ou alors complétez le fichier /etc/modules.conf avec une ligne du type:"
			echo "   alias eth0 <nom_du_module>"
			echo -e "Il conviendra ensuite de rebooter pour prendre en compte le changement\nou de charger le module pour cette 'session' par 'modprobe <nom_du_module>"
			echo -e "Vous pourrez relancer ce script via la commande:\n   /var/cache/se3_install/install_se3.sh"
			echo -e "$COLTXT"
			exit 1
		fi
	else
	cp /etc/network/interfaces /etc/network/interfaces.orig
	sed -i "s/eth[0-9]/$ECARD/" /etc/network/interfaces
	ifup $ECARD
	fi

fi
}

function installbase()
{

echo -e "$COLPARTIE"


# mv /etc/apt/sources.list /etc/apt/sources.list.sav2
# cp /etc/se3/se3.list /etc/apt/sources.list.d/

echo "Mise à jour des dépots et upgrade si necessaire, quelques mn de patience..."
echo -e "$COLTXT"
# tput reset
apt-get -qq update
apt-get upgrade --quiet --assume-yes

echo -e "$COLPARTIE"
echo "installation de ssmtp, ntpdate, makepasswd, ssh, etc...."
echo -e "$COLTXT"
apt-get install --quiet --assume-yes ssmtp ntpdate makepasswd ssh vim screen lshw atop htop smartmontools nmap tcpdump dos2unix
}

function write_hostconf()
{}

function write_resolv()
{}


#Variables :
samba_packages="samba"

while :; do
	case $1 in
		-d|--download)
		download="yes"
		;;
		
		-n|--network)
		network="yes"
		;;
		
		--debug)
		touch /root/debug
		;;
  
		--)
		shift
		break
		;;
     
		-?*)
		printf 'Attention : option inconnue ignorée: %s\n' "$1" >&2
		;;
  
		*)
		break
		esac
 		shift
done

if [ "$download" = "yes" ]; then
	show_title
	test_ecard
	echo -e "$COLINFO"
	echo "Pré-téléchargement des paquets uniquement"
	echo -e "$COLTXT"
	installbase
	gensourcelist
	gensourcese4
	echo -e "$COLINFO"
	echo "Ajout du support de l'architecture i386 pour dpkg" 
	echo -e "$COLCMD\c"

	echo -e "$COLINFO"
	echo "Téléchargement du backport samba 4.4" 
	echo -e "$COLCMD\c"

	apt-get install $samba_packages 


	echo "Phase de Téléchargement est terminée !"
	echo -e "$COLTXT"
	exit 0
fi


if [ "$network" = "yes" ]; then
	show_title
	test_ecard
	echo -e "$COLINFO"
	echo "Mofification de l'adressage IP"
	echo -e "$COLTXT"
	gennetwork
	service networking restart
	echo "Modification Ok" 
	echo "Testez la connexion internet avant de relancer le script sans option afin de procéder à l'installation"
	exit 0
fi

show_title
echo "Appuyez sur Entree pour continuer"
read dummy


echo -e "$COLPARTIE"

DEBIAN_PRIORITY="critical"
DEBIAN_FRONTEND="noninteractive"
export  DEBIAN_FRONTEND
export  DEBIAN_PRIORITY

test_ecard
# LADATE=$(date +%d-%m-%Y)
# fichier_log="/etc/se3/install-stretch-$LADATE.log"
# touch $fichier_log

[ -e /root/debug ] && DEBUG="yes"

gensourcelist

gensourcese4

installbase
echo -e "$COLPARTIE"
echo "Prise en compte des valeur de $se4_config"
echo -e "$COLTXT"

echo -e "$COLINFO"
if [ -e "$se4_config" ] ; then
 	echo "$se4_config est bien present sur la machine"
	source $se4_config 
	echo -e "$COLTXT"
else
	echo "$se4_config ne se trouve pas sur la machine"
	echo -e "$COLTXT"
fi

write_hostconf
write_resolv

echo -e "$COLPARTIE"
echo "Type de configuration Ldap et mise a l'heure"
echo -e "$COLTXT"


echo -e "$COLINFO"

if [ -n "$GATEWAY" ]; then
	echo "Tentative de Mise à l'heure automatique du serveur sur $GATEWAY..."
	ntpdate -b $GATEWAY
	if [ "$?" = "0" ]; then
		heureok="yes"
	fi
fi

if [ "$heureok" != "yes" ];then

	echo "Mise à l'heure automatique du serveur sur internet..."
	echo -e "$COLCMD\c"
	ntpdate -b fr.pool.ntp.org
	if [ "$?" != "0" ]; then
		echo -e "${COLERREUR}"
		echo "ERREUR: mise à l'heure par internet impossible"
		echo -e "${COLTXT}Vous devez donc vérifier par vous même que celle-ci est à l'heure"
		echo -e "le serveur indique le$COLINFO $(date +%c)"
		echo -e "${COLTXT}Ces renseignements sont-ils corrects ? (${COLCHOIX}O/n${COLTXT}) $COLSAISIE\c"
		read rep
		[ "$rep" = "n" ] && echo -e "${COLERREUR}Mettez votre serveur à l'heure avant de relancer l'installation$COLTXT" && exit 1
	fi
fi



echo -e "$COLPARTIE"
echo "Installation de Samba et cie" 
echo -e "$COLTXT"



echo -e "$COLINFO"
echo "Installation de samba 4.5" 
echo -e "$COLCMD\c"

apt-get install $samba_packages 

# 
# echo -e "$COLINFO"
# echo "On stopppe le service winbind" 
# echo -e "$COLCMD\c"
# service winbind stop
# insserv -r winbind


	
while [ "$TEST_PASS" != "OK" ]
do
echo -e "$COLCMD"
echo -e "Entrez un mot de passe pour le compte super-utilisateur root $COLTXT"
passwd
    if [ $? != 0 ]; then
        echo -e "$COLERREUR"
        echo -e "Attention : mot de passe a été saisi de manière incorrecte"
        echo "Merci de saisir le mot de passe à nouveau"
        sleep 1
    else
        TEST_PASS="OK"
        echo -e "$COLINFO\nMot de passe root changé avec succès :)"
        sleep 1
    fi
done
echo -e "$COLTXT"

echo -e "$COLTITRE"
echo "L'installation est terminée. Bonne utilisation de SambaEdu3 !"
echo -e "$COLTXT"

script_absolute_path=$(readlink -f "$0")
[ "$DEBUG" != "yes" ] &&  mv "$script_absolute_path" /root/install_phase2.done 
[ -e /root/install_phase2.sh ] && mv /root/install_phase2.sh  /root/install_phase2.done
. /etc/profile

DEBIAN_PRIORITY="high"
DEBIAN_FRONTEND="dialog" 
export  DEBIAN_PRIORITY
export  DEBIAN_FRONTEND
exit 0

