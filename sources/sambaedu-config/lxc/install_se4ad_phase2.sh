#!/bin/bash
# installation Se4-AD phase 2
# version pour Stretch - franck molle
# version 12 - 2017 

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

#### Sources testing seront desactivees en prod ####
deb http://wawadeb.crdp.ac-caen.fr/debian stretch se4testing


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
echo "installation ntpdate, vim, etc..."
echo -e "$COLTXT"
prim_packages="ntpdate vim wget nano iputils-ping bind9-host libldap-2.4-2 ldap-utils makepasswd haveged"
apt-get install --quiet --assume-yes $prim_packages
}

function write_hostconf()
{
cat >/etc/hosts <<END
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
$se4ad_ip	se4ad.$fulldomaine	se4ad
END

cat >/etc/hostname <<END
se4ad
END
}

function install_slapd
{

echo -e "$COLINFO"
echo "Installation et configuration du backend slapd pour récupération des anciennes données" 
echo -e "$COLCMD"
apt-get install --assume-yes slapd ldb-tools
echo -e "$COLTXT"
echo -e "$COLINFO"
echo "configuration et import de l'annuaire" 
echo -e "$COLTXT"
/etc/init.d/slapd stop

cat > /etc/default/slapd <<END
SLAPD_CONF="/etc/ldap/slapd.conf"
SLAPD_USER="openldap"
SLAPD_GROUP="openldap"
SLAPD_PIDFILE=
SLAPD_SERVICES="ldap:/// ldapi:///"
SLAPD_SENTINEL_FILE=/etc/ldap/noslapd
SLAPD_OPTIONS=""
END

cat > /etc/ldap/ldap.conf <<END
HOST $se4ad_ip
BASE $ldap_base_dn
END

cat > /etc/ldap.secret <<END
$adminPw
END

rm /etc/ldap/slapd.d -rf
cp $dir_config/slapd.conf $dir_config/slapd.pem /etc/ldap/
sed "s/$sambadomaine_old/$sambadomaine_new/" -i $dir_config/$se3ldif


cp $dir_config/DB_CONFIG  /var/lib/ldap/
slapadd -l $dir_config/$se3ldif
chown -R openldap:openldap /var/lib/ldap/
chown -R openldap:openldap /etc/ldap
# Attnetion au droits !
/etc/init.d/slapd start

}

function extract_ldifs ()
{

ldapsearch -o ldif-wrap=no -xLLL -D $adminRdn,$ldap_base_dn -w $adminPw -b ou=Rights,$ldap_base_dn cn | sed -n 's/^cn: //p' | while read cn_rights
do
	
cat >> $dir_config/ad_rights.ldif <<END	
dn: CN=$cn_rights,OU=Rights,$ad_base_dn
objectClass: group
objectClass: top
instanceType: 4
member: CN=Administrator,CN=Users,$ad_base_dn
END
ldapsearch -o ldif-wrap=no -xLLL -D $adminRdn,$ldap_base_dn -w $adminPw -b cn=$cn_rights,ou=Rights,$ldap_base_dn member | sed -n 's/member: uid=//p' | cut -d "," -f1 | grep -v "^admin" | while read member_rights
	do
		echo "member: CN=member_rights,CN=Users,$ad_base_dn" >> $dir_config/ad_rights.ldif
	done
	
ldapsearch -o ldif-wrap=no -xLLL -D $adminRdn,$ldap_base_dn -w $adminPw -b cn=$cn_rights,ou=Rights,$ldap_base_dn member | sed -n 's/member: cn=//p' | cut -d "," -f1 | while read member_rights
	do
		echo "member: CN=member_rights,OU=Groups,$ad_base_dn" >> $dir_config/ad_rights.ldif
	done
echo ""	>> $dir_config/ad_rights.ldif
done

if [ -n "$(ldapsearch -o ldif-wrap=no -xLLL -b ou=Parcs,$ldap_base_dn cn| sed -n 's/^cn: //p')" ]; then
	ldapsearch -o ldif-wrap=no -xLLL -b ou=Parcs,$ldap_base_dn cn| sed -n 's/^cn: //p' | while read cn_parcs
	do
	cat >> $dir_config/ad_parcs.ldif <<END	
dn: CN=$cn_parcs,OU=Parcs,$ad_base_dn
objectClass: group
objectClass: top
instanceType: 4
END
	if [ -n "$(ldapsearch -o ldif-wrap=no -xLLL -b ou=Parcs,$ldap_base_dn cn=$cn_parcs | sed -n 's/member: uid=//p'   ]; then
		ldapsearch -o ldif-wrap=no -xLLL -b ou=Parcs,$ldap_base_dn cn=$cn_parcs | sed -n 's/member: uid=//p'  | cut -d "," -f1 | while read member_parcs
		do
			echo "member: CN=member_parcs,OU=Parcs,$ad_base_dn" >> $dir_config/ad_parcs.ldif
		done
	fi
	done
fi
}



function installsamba()
{


echo -e "$COLINFO"
echo "Installation de samba 4.5" 
echo -e "$COLCMD"

apt-get install $samba_packages 

echo -e "$COLTXT"
}

function write_krb5()
{
cat > /etc/krb5.conf <<END
[libdefaults]
 dns_lookup_realm = false
 dns_lookup_kdc = true
 default_realm = $fulldomaine_up
END

}


function convert_smb_to_ad()
{

rm -f /etc/samba/smb.conf
if [ -e "$dir_config/smb.conf" ]; then
		
	echo -e "$COLINFO"
	echo "Lancement de la migration du domaine NT4 vers Samba AD avec sambatool" 
	echo -e "$COLCMD"
	sed "s/$netbios_name/se4ad/" -i $dir_config/smb.conf
	sed "s/$sambadomaine_old/$sambadomaine_new/" -i $dir_config/smb.conf
	sed "s#passdb backend.*#passdb backend = ldapsam:ldap://$se4ad_ip#" -i $dir_config/smb.conf  
	echo "samba-tool domain classicupgrade --dbdir=$db_dir --use-xattrs=yes --realm=$fulldomaine_up --dns-backend=SAMBA_INTERNAL $dir_config/smb.conf"
	samba-tool domain classicupgrade --dbdir=$db_dir --use-xattrs=yes --realm=$fulldomaine_up --dns-backend=SAMBA_INTERNAL $dir_config/smb.conf
	echo -e "$COLTXT"
else
	echo -e "$COLINFO"
	echo "$db_dir/smb.conf Manquant - Lancement d'une nouvelel installation de Samba AD avec sambatool" 
	samba-tool domain provision --realm=$fulldomaine_up --domain $mondomaine_up --adminpass $ad_admin_pass  
	echo -e "$COLCMD"
fi

systemctl unmask samba-ad-dc
systemctl enable samba-ad-dc
# systemctl disable samba winbind nmbd smbd
systemctl mask samba winbind nmbd smbd

echo -e "$COLINFO"
echo "En avant la musique :) - lancement de Samba AD-DC"
echo -e "$COLCMD"
/etc/init.d/samba-ad-dc start
echo -e "$COLTXT"


}


function change_pass_admin()
{
TEST_PASS="none"
while [ "$TEST_PASS" != "OK" ]
do
echo -e "$COLCMD"
echo -e "Entrez un mot de passe pour le compte Administrator AD $COLTXT"
echo -e "Attention le mot de passe doit contenir au moins 8 caractères tout en mélangeant lettres / chiffres et au moins une Majuscule $COLTXT"
read -r administrator_pass
printf '%s\n%s\n' "$administrator_pass" "$administrator_pass"|(/usr/bin/smbpasswd -s Administrator)
smbclient -L localhost -U Administrator%"$administrator_pass" >/dev/null 

    if [ $? != 0 ]; then
        echo -e "$COLERREUR"
        echo -e "Attention : mot de passe a été saisi de manière incorrecte ou ne respecte pas les critères de sécurité"
        echo "Merci de saisir le mot de passe à nouveau"
        sleep 1
    else
        TEST_PASS="OK"
        echo -e "$COLINFO\nMot de passe Administrator changé avec succès :)"
        sleep 1
    fi
done
echo -e "$COLTXT"
}




function ldbadd_ou()
{
local dn_add=$1
local rdn_add=$2
local desc_add=$3
ldbmodify -H /var/lib/samba/private/sam.ldb <<EOF
dn: $dn_add
changetype: add
objectClass: organizationalUnit
objectClass: top
instanceType: 4
OU: $rdn_add
description: $desc_add
EOF
}

function ldbmv_grp()
{
local dn_mv=$1
local rdn_mv=$2
local target_dn_mv=$3

ldbmodify -H /var/lib/samba/private/sam.ldb <<EOF
dn: $dn_mv
changetype: moddn
newrdn: $rdn_mv
deleteoldrdn: 1
newsuperior: $target_dn_mv
EOF
}

function modif_ldb()
{
echo -e "$COLINFO"
echo "Ajout des branches de l'annuaire propres à SE4"
echo -e "$COLCMD"
ldbadd_ou "OU=Groups,$ad_base_dn" "Groups" "Branche des Groupes"
ldbadd_ou "OU=Trash,$ad_base_dn" "Trash" "Branche de la corbeille"
ldbadd_ou "OU=Parcs,$ad_base_dn" "Parcs" "Branche parcs"
ldbadd_ou "OU=Printers,$ad_base_dn" "Printers" "Branche imprimantes"

ldbadd -H /var/lib/samba/private/sam.ldb $dir_config/rights_ad.ldif

echo -e "$COLINFO"
echo "Déplacement des groupes dans la branche dédiée"
echo -e "$COLCMD"
# ldapsearch -xLLL -D $ad_bindDN -w $administrator_pass -b $ad_base_dn -H ldaps://sambaedu4.lan "(objectClass=group)" dn | grep "dn:" | while read dn
ldbsearch -H /var/lib/samba/private/sam.ldb -b "CN=users,$ad_base_dn" "(objectClass=group)" dn | grep "dn:" | while read dn
do
	rdn="$(echo $dn | sed -e "s/dn: //" | cut -d "," -f1)"
	rdn_classe="$(echo $rdn | sed -n "s/^CN=Classe_\|^CN=Equipe_//"p)"
# 	rdn_equipe="$(echo $rdn | sed -n "s/^CN=Equipe_//"p)"
	if [ -n "$rdn_classe" ];then
		target_dn="OU=$rdn_classe,OU=Groups,$ad_base_dn"
		ldbsearch -H /var/lib/samba/private/sam.ldb -b "$target_dn" | grep "dn:" || ldbadd_ou "$target_dn" "$rdn_classe" "ensemble $rdn_classe"
	else
		target_dn="OU=Groups,$ad_base_dn"
	fi
	ldbmv_grp "$rdn,CN=users,$ad_base_dn" "$rdn" "$target_dn"
done

}


function write_smbconf()
{
mv /etc/samba/smb.conf /etc/samba/smb.conf.ori
cat >/etc/samba/smb.conf<END
# Global parameters
[global]
	netbios name = SE4AD
	realm = $fulldomaine_up
	workgroup = $mondomaine_up
	dns forwarder = $nameserver
	server role = active directory domain controller
	idmap_ldb:use rfc2307 = yes
	
[netlogon]
	path = /var/lib/samba/sysvol/sambaedu4.lan/scripts
	read only = No

[sysvol]
	path = /var/lib/samba/sysvol
	read only = No
END
}


function set_time 
{
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
}


function write_resolvconf()
{
cat >/etc/resolv.conf<<END
search $fulldomaine
nameserver 127.0.0.1
END
}

function Permit_ssh_by_password()
{
grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config || echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

/usr/sbin/service ssh restart
}



function change_policy_passwords() {
samba-tool domain passwordsettings set --complexity=off
samba-tool domain passwordsettings set --history-length=0
samba-tool domain passwordsettings set --min-pwd-age=0
samba-tool domain passwordsettings set --max-pwd-age=0
}

function change_pass_root()
{	
TEST_PASS="none"
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
}

#Variables :

### Mode devel pour le moment on !###
devel="yes"

samba_packages="samba winbind libnss-winbind krb5-user smbclient"
export DEBIAN_FRONTEND=noninteractive
dir_config="/etc/sambaedu"
se4ad_config="$dir_config/se4ad.config"
db_dir="/etc/sambaedu/smb_export"
nameserver=$(grep "^nameserver" /etc/resolv.conf | cut -d" " -f2)
se3ldif="ldapse3.ldif"

echo -e "$COLPARTIE"
echo "Prise en compte des valeurs de $se4ad_config"
echo -e "$COLTXT"

#### Fichier de conf contient ces variables ####
# ip du se4ad --> $se4ad_ip" 

# Nom de domaine samba du SE4-AD --> $mondomaine" 

# Suffixe du domaine --> $suffixe_domaine" 

# Nom de domaine complet - realm du SE4-AD --> $fulldomaine" 

# Adresse IP de l'annuaire LDAP à migrer en AD --> $se3ip" 

# Nom du domaine samba actuel --> $se3_domain"  

# Nom netbios du serveur se3 actuel--> $netbios_name" 

# Adresse du serveur DNS --> $nameserver" 

# Pass admin LDAP --> $adminPw" 

# base dn LDAP ancienne --> $ldap_base_dn


echo -e "$COLINFO"
if [ -e "$se4ad_config" ] ; then
 	echo "$se4ad_config est bien present sur la machine"
	source $se4ad_config 
	echo -e "$COLTXT"
else
	echo "$se4ad_config ne se trouve pas sur la machine"
	echo -e "$COLTXT"
	se4ad_ip="$(ifconfig eth0 | grep "inet " | awk '{ print $2}')"
fi

poursuivre

if [ -n "$devel" ]; then
	mkdir -p /root/.ssh/
	ssh_keyser="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDMQ6Nd0Kg+L8200pR2CxUVHBtmjQ2xAX2zqArqV45horU8qopf6AYEew0oKanK3GzY2nrs5g2SYbxqs656YKa/OkTslSc5MR/Nndm9/J1CUsurTlo+VwXJ/x1qoLBmGc/9mZjdlNVKIPwkuHMKUch+XmsWF92GYEpTA1D5ZmfuTxP0GMTpjbuPhas96q+omSubzfzpH7gLUX/afRHfpyOcYWdzNID+xdmML/a3DMtuCatsHKO94Pv4mxpPeAXpJdE262DPXPz2ZIoWSqPz8dQ6C3v7/YW1lImUdOah1Fwwei4jMK338ymo6huR/DheCMa6DEWd/OZK4FW2KccxjXvHALn/QCHWCw0UMQnSVpmFZyV4MqB6YvvQ6u0h9xxWIvloX+sjlFCn71hLgH7tYsj4iBqoStN9KrpKC9ZMYreDezCngnJ87FzAr/nVREAYOEmtfLN37Xww3Vr8mZ8/bBhU1rqfLIaDVKGAfnbFdN6lOJpt2AX07F4vLsF0CpPl4QsVaow44UV0JKSdYXu2okcM80pnVnVmzZEoYOReltW53r1bIZmDvbxBa/CbNzGKwxZgaMSjH63yX1SUBnUmtPDQthA7fK8xhQ1rLUpkUJWDpgLdC2zv2jsKlHf5fJirSnCtuvq6ux1QTXs+bkTz5bbMmsWt9McJMgQzWJNf63o8jw== GitLab"
	echo $ssh_keyser >> /root/.ssh/authorized_keys 
fi
# A voir pour modifier ou récupérer depuis sambaedu.config 
[ -z "$mondomaine" ] && mondomaine="sambaedu4"
[ -z "$suffixe_domaine" ] && suffixe_domaine="lan"
fulldomaine="$mondomaine.$suffixe_domaine" 
ad_base_dn="DC=$mondomaine,DC=$suffixe_domaine"
ad_bindDN="CN=Administrator,CN=users,$ad_base_dn"

mondomaine_up="$(echo "$mondomaine" | tr [:lower:] [:upper:])"
suffixe_domaine_up="$(echo "$suffixe_domaine" | tr [:lower:] [:upper:])"
fulldomaine_up="$(echo "$fulldomaine" | tr [:lower:] [:upper:])"
sambadomaine_old="$(echo $se3_domain| tr [:lower:] [:upper:])"
sambadomaine_new="$mondomaine_up"
haveged
ad_admin_pass=$(makepasswd --minchars=8)

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
	echo "Téléchargement de samba 4" 
	echo -e "$COLCMD\c"

	apt-get install $samba_packages -d


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
# LADATE="$(date +%d-%m-%Y)"
# fichier_log="/etc/se3/install-stretch-$LADATE.log"
# touch $fichier_log

[ -e /root/debug ] && DEBUG="yes"

gensourcelist

gensourcese4

installbase

write_hostconf

echo -e "$COLPARTIE"
echo "Installation de Samba et cie" 
echo -e "$COLTXT"

installsamba

install_slapd

extract_ldifs

convert_smb_to_ad

write_krb5

write_smbconf

write_resolvconf

change_pass_admin

modif_ldb

change_policy_passwords

Permit_ssh_by_password	

change_pass_root

echo -e "$COLTITRE"
echo "L'installation est terminée. Bonne utilisation de SambaEdu4-AD ! :)"
echo -e "$COLTXT"

# script_absolute_path=$(readlink -f "$0")
# [ "$DEBUG" != "yes" ] &&  mv "$script_absolute_path" /root/install_phase2.done 
[ -e /root/install_phase2.sh ] && mv /root/install_se4ad_phase2.sh  /root/install_phase2.done
. /etc/profile

unset DEBIAN_FRONTEND
exit 0

