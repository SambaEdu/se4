#!/bin/bash
#
##### Permet l'installation et la conf d'un container LXC se4-AD#####
# franck molle
# version 02 - 2018 



function usage() 
{
echo "Script intéractif permettant l'installation et la configuration d'un container LXC se4-AD"
}

if [ "$1" = "--help" -o "$1" = "-h" ]
then
	usage
	echo "Usage : pas d'option"
	exit
fi

function check_whiptail()
{
if [ -z "$(which whiptail)" ];then
apt-get install whiptail -y 
fi
}


function show_title() {
BACKTITLE="Projet Sambaédu - https://www.sambaedu.org/"

WELCOME_TITLE="Installeur de container LXC pour SE4-AD"
WELCOME_TEXT="Bienvenue dans l'installation du container LXC SE4 Active directory.

Ce programme installera un container LXC Debian Stretch et y déposera tous les fichiers d'export nécessaires à la migration vers AD.

Une fois la machine LXC installée, il suffira de la démarrer afin de poursuivre son installation et sa configuration de façon automatique."

$dialog_box  --backtitle "$BACKTITLE" --title "$WELCOME_TITLE" --msgbox "$WELCOME_TEXT" 18 70
}



function erreur()
{
        echo -e "$COLERREUR"
        echo "ERREUR!"
        echo -e "$1"
        echo -e "$COLTXT"
        exit 1
}

# Poursuivre ou corriger
function poursuivre_ou_corriger()
{
	REPONSE=""
	while [ "$REPONSE" != "1" -a "$REPONSE" != "2" ]
	do
		if [ ! -z "$1" ]; then
			echo -e "$COLTXT"
			echo -e "Peut-on poursuivre (${COLCHOIX}1${COLTXT}) ou voulez-vous corriger (${COLCHOIX}2${COLTXT}) ? [${COLDEFAUT}${1}${COLTXT}] $COLSAISIE\c"
			read REPONSE

			if [ -z "$REPONSE" ]; then
				REPONSE="$1"
			fi
		else
			echo -e "$COLTXT"
			echo -e "Peut-on poursuivre (${COLCHOIX}1${COLTXT}) ou voulez-vous corriger (${COLCHOIX}2${COLTXT}) ? $COLSAISIE\c"
			read REPONSE
		fi
	done
}

# Poursuivre ou quitter en erreur
function POURSUIVRE()
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
                ERREUR "Abandon!"
        fi
}

#Activation Debug
function debug() {
debug="1"
if [ "$debug" = "1" ]; then
set -x
POURSUIVRE
fi

}

# Affichage de la partie actuelle
function show_part()
{
echo -e "$COLTXT"
echo -e "$COLPARTIE"
echo "--------"
echo "$1"
echo "--------"
echo -e "$COLTXT"
# sleep 1
}

# confirmation de la conf du lan 
function conf_network()
{
config_lan_title="Configuration du réseau local"	
se3network=$(grep network $interfaces_file | grep -v "#" | sed -e "s/network//g" | tr "\t" " " | sed -e "s/ //g")
se3bcast=$(grep broadcast $interfaces_file | grep -v "#" | sed -e "s/broadcast//g" | tr "\t" " " | sed -e "s/ //g")
se3gw=$(grep gateway $interfaces_file | grep -v "#" | sed -e "s/gateway//g" | tr "\t" " " | sed -e "s/ //g")


REPONSE=""
while [ "$REPONSE" != "yes" ]
do
	if [ "$REPONSE" = "no" ]; then
		$dialog_box --backtitle "$BACKTITLE" --title "$config_lan_title" --inputbox "Veuillez saisir l'adresse de base du reseau" 15 70 $se3network 2>$tempfile || erreur "Annulation"
		se3network="$(cat $tempfile)"
				
		$dialog_box --backtitle "$BACKTITLE" --title "$config_lan_title" --inputbox "Veuillez saisir l'adresse de broadcast" 15 70 $se3bcast 2>$tempfile || erreur "Annulation"
		se3bcast="$(cat $tempfile)"
		
		$dialog_box --backtitle "$BACKTITLE" --title "$config_lan_title" --inputbox "Veuillez saisir l'adresse de la passerelle" 15 70 $se3gw 2>$tempfile || erreur "Annulation"
		se3gw="$(cat $tempfile)"
				
	fi

	confirm_title="Configuration réseau local"
	confirm_txt="La configuration suivante a été détectée sur le serveur SE3 
	
Adresse IP du serveur SE3 :   $se3ip
Adresse réseau de base :      $se3network
Adresse de Broadcast :        $se3bcast
Adresse IP de la Passerelle : $se3gw
	
Ces valeurs sont elles correctes ?"	
	
	if ($dialog_box --backtitle "$BACKTITLE" --title "$confirm_title" --yesno "$confirm_txt" 15 70) then
		REPONSE="yes"
	else
		REPONSE="no"
	fi
done
}

# Installation package LXC 1.1 backport
function install_lxc_package()
{
show_part "Installation  et configuration de LXC"

echo "Vérification de l'existence des backports dans le sources.list"
url_depot_backport="deb http://ftp.fr.debian.org/debian/ wheezy-backports main"
grep -q "^$url_depot_backport" /etc/apt/sources.list || echo "$url_depot_backport" >> /etc/apt/sources.list
echo -e "${COLCMD}Mise à jour des dépots....${COLTXT}"
# apt-get autoremove 
apt-get -qq update

echo -e "${COLCMD}installation de LXC version backportée${COLTXT}"
apt-get install bridge-utils
apt-get install -t wheezy-backports lxc

grep -q cgroup /etc/fstab || echo "cgroup  /sys/fs/cgroup  cgroup  defaults  0   0" >> /etc/fstab
mount -a
sleep 3
}

# fonction config du lan
function write_host_lan()
{
echo -e "${COLINFO}Passage de eth0 en br0 pour installer le pont nécessaire à LXC${COLTXT}"
sleep 2
echo
SETMYSQL dhcp_iface $ecard
SETMYSQL ecard $ecard
echo -e "$COLINFO"
echo -e "Modification de $interfaces_file"
echo -e "$COLTXT"

cp $interfaces_file ${interfaces_file}_sav_install_lxc 

cat > /etc/network/interfaces <<END
# /etc/network/interfaces -- configuration file for ifup(8), ifdown(8)

# The loopback interface
auto lo
iface lo inet loopback

# The first network card - this entry was created during the Debian installation
# (network, broadcast and gateway are optional)
auto br0
iface br0 inet static
bridge_ports eth0
bridge_fd 0
address $se3ip
netmask $se3mask
network $se3network
broadcast $se3bcast
gateway $se3gw
END

chmod 644 $interfaces_file

# Redémarrage de l'interface réseau
[ -z "$ecard" ] && ecard="br0"
echo -e "$COLCMD\c"
echo -e "Redémarrage de l'interface réseau...\c"
echo -e "$COLTXT"
/etc/init.d/networking stop
/etc/init.d/networking start
echo -e "$COLTXT\c"
ifup $ecard

}

# Fonction de preconfig du container
function preconf_se4ad_lxc()
{
se4ad_lxc_lan_title="Configuration réseau du container LXC SE4"

REPONSE=""
details="no"
se4ad_ip="$(echo "$se3ip"  | cut -d . -f1-3)."
se4mask="$se3mask"
se4network="$se3network"
se4bcast="$se3bcast"
se4gw="$se3gw"
while [ "$REPONSE" != "yes" ]
do
	$dialog_box --backtitle "$BACKTITLE" --title "$se4ad_lxc_lan_title" --inputbox "Saisir l'IP du container SE4" 15 70 $se4ad_ip 2>$tempfile || erreur "Annulation"
	se4ad_ip=$(cat $tempfile)
	
	if [ "$details" != "no" ]; then
		$dialog_box --backtitle "$BACKTITLE" --title "$se4ad_lxc_lan_title" --inputbox "Saisir le Masque sous réseau" 15 70 $se3mask 2>$tempfile || erreur "Annulation"
		se4mask=$(cat $tempfile)
		
		$dialog_box --backtitle "$BACKTITLE" --title "$se4ad_lxc_lan_title" --inputbox "Saisir l'Adresse de base du réseau" 15 70 $se3network 2>$tempfile || erreur "Annulation"
		se4network=$(cat $tempfile)
		
		$dialog_box --backtitle "$BACKTITLE" --title "$se4ad_lxc_lan_title" --inputbox "Saisir l'Adresse de broadcast" 15 70 $se3bcast 2>$tempfile || erreur "Annulation"
		se4bcast=$(cat $tempfile)
		
		$dialog_box --backtitle "$BACKTITLE" --title "$se4ad_lxc_lan_title" --inputbox "Saisir l'Adresse de la passerelle" 15 70 $se3gw 2>$tempfile || erreur "Annulation"
		se4gw=$(cat $tempfile)
	fi
	details="yes"
	
	se4ad_lxc_name_title="Nom du container SE4"
	$dialog_box --backtitle "$BACKTITLE" --title "$se4ad_lxc_name_title" --inputbox "Saisir le Nom du container SE4" 15 70 se4ad 2>$tempfile || erreur "Annulation"
	se4name=$(cat $tempfile)
	
	choice_domain_title="Important - nom de domaine AD"
	choice_domain_text="Sur un domaine AD, le serveur de domaine gère le DNS. Le choix du nom de domaine est donc important.
Il est décomposé en deux parties : le nom de domaine samba suivi de son suffixe, séparés par un point.

Exemple de domaine AD : clg-dupontel.belville.ac-dijon.fr 
* le domaine samba sera clg-dupontel 
* le suffixe sera belville.ac-acad.fr 

Note : 
* le domaine samba ne doit en aucun cas dépasser 15 caractères
* Les domaines du type sambaedu.lan ou etab.local sont déconseillés en production par l'équipe samba"

	ad_domain="$(hostname -d)"
	$dialog_box --backtitle "$BACKTITLE" --title "$choice_domain_title" --inputbox "$choice_domain_text" 20 80 $ad_domain 2>$tempfile
	ad_domain="$(cat $tempfile)"		
	smb4_domain=$(echo "$ad_domain" | cut -d"." -f1)
	suffix_domain=$(echo "$ad_domain" | sed -n "s/$smb4_domain\.//p")
	
	confirm_title="Récapitulatif de la configuration prévue"
	confirm_txt="IP :         $se4ad_ip
Masque :     $se4mask
Réseau :     $se4network
Broadcast :  $se4bcast
Passerelle : $se4gw

Nom :        $se4name

Nom de domaine AD saisi : $ad_domain
Nom de domaine samba :    $smb4_domain
Suffixe du domain :       $suffix_domain

Confirmer l'enregistrement de cette configuration ?"
		
		if ($dialog_box --backtitle "$BACKTITLE" --title "$confirm_title" --yesno "$confirm_txt" 20 60) then
			REPONSE="yes"
		else
			REPONSE="no"
		fi	
done

#~ POURSUIVRE
echo -e "$COLTXT"
}

# Fonction écriture du fichier de conf LXC
function write_lxc_conf {

show_part "Installation du container $se4name"


if [ -e "usr/share/se3/sbin/lxc-mac-generator" ]; then
	echo -e "$COLINFO"
	echo "Génération de l'adresse MAC de la machine LXC"
	echo -e "$COLTXT"
	se4mac="$(usr/share/se3/sbin/lxc-mac-generator)"
else
	se4mac="00:FF:AA:00:00:01"
	echo -e "$COLINFO"
	echo "Adresse MAC de la machine LXC fixée à $se4mac"
	echo -e "$COLTXT"
fi
cat > /var/lib/lxc/$se4name.config <<END
lxc.network.type = veth
lxc.network.flags = up

# Ceci est l’interface définit plus haut dans le fichier interface de l’hôte :
lxc.network.link = br0
lxc.network.name = eth0
lxc.network.hwaddr = $se4mac
lxc.network.ipv4 = $se4ad_ip

# Définissez la passerelle pour avoir un accès à Internet
lxc.network.ipv4.gateway = $se4gw
END
}

# Fonction installation de la machine LXC se4ad
function install_se4ad_lxc()
{
if [ -e "$dir_config/lxc/template/lxc-debianse4" ]; then
	echo -e "$COLINFO"
	echo "Copie du template $dir_config/lxc/template/lxc-debianse4"
	echo -e "$COLTXT"
	cp -v $dir_config/lxc/template/lxc-debianse4 /usr/share/lxc/templates/lxc-debianse4
else
	echo -e "$COLINFO"
	echo "Récupération du template lxc-debianse4"
	echo -e "$COLTXT"
	wget -nv $url_sambaedu_config/etc/sambaedu/lxc/template/lxc-debianse4
	mv lxc-debianse4 /usr/share/lxc/templates/lxc-debianse4
fi
chmod +x /usr/share/lxc/templates/lxc-debianse4
if [ ! -e  /usr/share/debootstrap/scripts/stretch ]; then
	echo -e "$COLINFO"
	echo "création de /usr/share/debootstrap/scripts/stretch"
	echo -e "$COLTXT"
	cd /usr/share/debootstrap/scripts/ 
	ln -s sid stretch
	cd -
fi
echo -e "$COLINFO"
echo "Lancement de lxc-create - Patience !!"
echo -e "$COLCMD"
lxc-create -n $se4name -t debianse4 -f /var/lib/lxc/$se4name.config
echo -e "$COLTXT"
}

# fonction ecriture du lan LXC
function write_lxc_lan()
{
interfaces_file_lxc="/var/lib/lxc/$se4name/rootfs/etc/network/interfaces"
echo -e "$COLINFO"
echo "Modification de $interfaces_file_lxc"
echo -e "$COLTXT"
cat > $interfaces_file_lxc <<END
# /etc/network/interfaces -- configuration file for ifup(8), ifdown(8)

# The loopback interface
auto lo
iface lo inet loopback

# The first network card - this entry was created during the Debian installation
# (network, broadcast and gateway are optional)
auto eth0
iface eth0 inet static
address $se4ad_ip
netmask $se4mask
network $se4network
broadcast $se4bcast
gateway $se4gw
END

chmod 644 $interfaces_file_lxc

}

 
# Fonction personalisation .profile 
function write_lxc_profile
{
lxc_profile="/var/lib/lxc/$se4name/rootfs/root/.profile"

if [ -e "$dir_preseed/.profile" ]; then
    echo -e "$COLINFO"
    echo "Copie du .profile sur le container"
    echo -e "$COLCMD"
    cp -v $dir_preseed/.profile $lxc_profile
    echo -e "$COLTXT"
else
    echo -e "$COLINFO"
    echo "Récupération du fichier bashrc"
    echo -e "$COLCMD"
    wget -nv $url_sambaedu_config/var/www/install/.profile
    mv -v profile $lxc_profile
    echo -e "$COLTXT"
fi
}

# Fonction personalisation .bashrc 
function write_lxc_bashrc
{
lxc_bashrc="/var/lib/lxc/$se4name/rootfs/root/.bashrc"
if [ -e "$dir_preseed/.bashrc" ]; then
	echo -e "$COLINFO"
	echo "Copie de .bashrc"
	echo -e "$COLCMD"
	cp -v $dir_preseed/.bashrc $lxc_bashrc
	echo -e "$COLTXT"
else
	echo -e "$COLINFO"
	echo "Récupération du fichier bashrc"
	echo -e "$COLCMD"
	wget -nv $url_sambaedu_config/etc/sambaedu/.bashrc
	mv -v bashrc $lxc_bashrc
	echo -e "$COLTXT"
fi
chmod 644 $lxc_bashrc
}

# Fonction écriture fichier de conf /etc/sambaedu/se4ad.config
function write_sambaedu_conf
{
if [ -e "$se4ad_config" ] ; then
	echo "$se4ad_config existe on en écrase le contenu"
fi
echo -e "$COLINFO"
#echo "Pas de fichier de conf $se4ad_config  -> On en crée un avec les params du se4ad"
echo -e "$COLTXT"
echo "## Adresse IP du futur SE4-AD ##" > $se4ad_config
echo "se4ad_ip=\"$se4ad_ip\"" >> $se4ad_config
echo "## Nom de domaine samba du SE4-AD ##" >> $se4ad_config
echo "smb4_domain=\"$smb4_domain\"" >>  $se4ad_config
echo "## Suffixe du domaine##" >> $se4ad_config
echo "suffix_domain=\"$suffix_domain\"" >>  $se4ad_config
echo "## Nom de domaine complet - realm du SE4-AD ##" >> $se4ad_config
echo "ad_domain=\"$ad_domain\"" >> $se4ad_config
echo "## Adresse IP de SE3 ##" >> $se4ad_config
echo "se3ip=\"$se3ip\"" >> $se4ad_config
echo "## Nom du domaine samba actuel" >> $se4ad_config
echo "se3_domain=\"$se3_domain\""  >> $se4ad_config
echo "##Nom netbios du serveur se3 actuel##" >> $se4ad_config
echo "netbios_name=\"$netbios_name\"" >> $se4ad_config
echo "##Adresse du serveur DNS##" >> $se4ad_config
echo "nameserver=\"$nameserver\"" >> $se4ad_config
echo "##Pass admin LDAP##" >> $se4ad_config
echo "adminPw=\"$adminPw\"" >> $se4ad_config
echo "##base dn LDAP##" >> $se4ad_config
echo "ldap_base_dn=\"$ldap_base_dn\"" >> $se4ad_config
echo "##Rdn admin LDAP##" >> $se4ad_config
echo "adminRdn=\"$adminRdn\"" >> $se4ad_config
echo "##SID domaine actuel" >> $se4ad_config
echo "domainsid=\"$domainsid\"" >> $se4ad_config
echo "##NTP server " >> $se4ad_config
echo "ntpserv=\"$ntpserv\"" >> $se4ad_config


chmod +x $se4ad_config
}

# Fonction export des fichiers tdb et smb.conf 
function export_smb_files()
{
echo -e "$COLINFO"
echo "Arrêt du service Samba pour export des fichiers TDB"
echo -e "$COLTXT"
service samba stop
echo -e "$COLINFO"
echo "Copie des fichiers TDB vers $dir_export"
echo -e "$COLCMD"
tdb_smb_dir="/var/lib/samba"
pv_tdb_smb_dir="/var/lib/samba/private"
cp $pv_tdb_smb_dir/secrets.tdb $dir_export/
cp $pv_tdb_smb_dir/schannel_store.tdb $dir_export/
cp $pv_tdb_smb_dir/passdb.tdb $dir_export/

if [ -e "$tdb_smb_dir/gencache_notrans.tdb" ] ;then
	cp $tdb_smb_dir/gencache_notrans.tdb $dir_export/
fi
cp $tdb_smb_dir/group_mapping.tdb $dir_export/
cp $tdb_smb_dir/account_policy.tdb $dir_export/
cp $tdb_smb_dir/wins.tdb $dir_export/
cp $tdb_smb_dir/wins.dat $dir_export/

cp /etc/samba/smb.conf $dir_export/
}

# Fonction export des fichiers ldap conf, schémas propres à se3 et ldif
function export_ldap_files()
{
conf_slapd="/etc/ldap/slapd.conf"
echo -e "$COLINFO"
echo "Export de la conf ldap et de ldapse3.ldif vers $dir_export"
echo -e "$COLTXT"
cp $conf_slapd $dir_export/
ldapsearch -xLLL -D "$adminRdn,$ldap_base_dn" -w $adminPw > $dir_export/ldapse3.ldif
schema_dir="/etc/ldap/schema"
cp $schema_dir/ltsp.schema $schema_dir/samba.schema $schema_dir/printer.schema $dir_export/
cp /var/lib/ldap/DB_CONFIG $dir_export/
cp /etc/ldap/slapd.pem $dir_export/

}

# Fonction copie des fichiers de conf @LXC/etc/sambaedu
function cp_config_to_lxc()
{
dir_config_lxc="/var/lib/lxc/$se4name/rootfs/etc/sambaedu"
mkdir -p $dir_config_lxc
echo "Création de l'archive $se4ad_config_tgz d'export des données et copie sur la machine LXC"
cd $dir_config
echo -e "$COLCMD"
tar -czf $se4ad_config_tgz export_se4ad
cp -v $se4ad_config_tgz $dir_config_lxc/
# echo "copie de $se4ad_config_tgz sur la machine LXC"
# 
# cp -av  $se4ad_config_tgz $dir_config_lxc/
cd -
echo -e "$COLTXT"
sleep 2
}

# Fonction copie install_phase2 @LXC  
function write_se4ad_install
{
dir_root_lxc="/var/lib/lxc/$se4name/rootfs/root"
if [ -e "$dir_preseed/$script_phase2" ]; then
	echo -e "$COLINFO"
	echo "Copie de $script_phase2"
	echo -e "$COLCMD"
	cp $dir_preseed/$script_phase2 $dir_root_lxc/$script_phase2
	echo -e "$COLTXT"
else
	echo -e "$COLINFO"
	echo "Récupération de $script_phase2"
	echo -e "$COLCMD"
	wget -nv $url_sambaedu_config/var/www/install/se4ad/$script_phase2
	mv $script_phase2 $dir_root_lxc/$script_phase2
	echo -e "$COLTXT"
fi
chmod +x $dir_root_lxc/$script_phase2
}

# copie des clés ssh présente sur le serveur principal sur le container
function write_ssh_keys
{
ssh_keys_host="/root/.ssh/authorized_keys"
ssh_keys_lxc_path="/var/lib/lxc/$se4name/rootfs/root/.ssh"
if [ -e "$ssh_keys_host" ];then
	echo -e "$COLINFO"
	echo "Copie du fichier des clés SSH $ssh_keys_host"
	mkdir -p "$ssh_keys_lxc_path"
	cp "$ssh_keys_host" "$ssh_keys_lxc_path/"
	echo -e "$COLCMD"
fi

}

# Fonction génération des fichiers hosts @ LXC
function write_lxc_hosts_conf()
{
lxc_hosts_file="/var/lib/lxc/$se4name/rootfs/etc/hosts"
echo -e "$COLINFO"
echo "Génération de $lxc_hosts_file"
echo -e "$COLTXT"

cat >$lxc_hosts_file <<END
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
$se4ad_ip	se4ad.$ad_domain	se4ad
END

lxc_hostname_file="/var/lib/lxc/$se4name/rootfs/etc/hosts"
echo -e "$COLINFO"
echo "Génération de $lxc_hostname_file"
echo -e "$COLTXT"

cat >$lxc_hostname_file <<END
se4ad
END
}

# Lancement du container en arrière plan
function launch_se4ad() {
echo -e "$COLINFO"
echo "Lancement de $se4name en arrière plan"
echo -e "$COLCMD"
lxc-start -d -n $se4name 
if [ "$?" != "0" ]; then
	echo -e "$COLERREUR"
	echo "Attention "
	echo -e "Erreur lors du lancement de $se4name !"
	echo -e "$COLTXT"
	echo "Appuyez sur entrée pour continuer"
else
	echo "$se4name Lancée avec succès !!"
	echo -e "$COLTXT"
	sleep 3
fi
}

# Affichage message de fin
function display_end_message() {
display_end_title="Container $se4name installé"	
	
display_end_txt="Installation terminée !!

Les différents paramètres sont consultables dans $se4ad_config 

La machine LXC a été lancée en arrière plan. 

Afin de poursuivre l'installation, il vous suffit de vous y connecter avec la commande
lxc-console -n $se4name 
/!\ Mot de passe root : \"se4ad\"

Une fois connecté root, un nouveau script d'installation se lancera sur le container afin de finaliser sa configuration"

$dialog_box --backtitle "$BACKTITLE" --title "$display_end_title" --msgbox "$display_end_txt" 20 70


echo -e "$COLTITRE"
echo "L'installation de $se4name est terminée.
Pour se connecter : 
lxc-console -n $se4name 
/!\ Mot de passe root : \"se4ad\""
echo -e "$COLTXT"
}
clear

#Couleurs
COLTITRE="\033[1;35m"   # Rose
COLPARTIE="\033[1;34m"  # Bleu

COLTXT="\033[0;37m"     # Gris
COLCHOIX="\033[1;33m"   # Jaune
COLDEFAUT="\033[0;33m"  # Brun-jaune
COLSAISIE="\033[1;32m"  # Vert

COLCMD="\033[1;37m"     # Blanc

COLERREUR="\033[1;31m"  # Rouge
COLINFO="\033[0;36m"    # Cyan

## recuperation des variables necessaires pour interoger mysql ###
source /etc/se3/config_c.cache.sh
source /etc/se3/config_m.cache.sh
source /etc/se3/config_l.cache.sh
source /usr/share/se3/includes/functions.inc.sh 

# Variables :
dialog_box="$(which whiptail)"
tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/inst$$
tempfile2=`tempfile 2>/dev/null` || tempfile=/tmp/inst2$$
# url_sambaedu_config="https://raw.githubusercontent.com/SambaEdu/se4/master/sources/sambaedu-config"
url_sambaedu_config="https://raw.githubusercontent.com/SambaEdu/sambaedu-config/master/sources"
interfaces_file="/etc/network/interfaces" 


dir_config="/etc/sambaedu"
dir_export="/etc/sambaedu/export_se4ad"
dir_preseed="/var/www/diconf"

mkdir -p "$dir_export"

se4ad_config="$dir_export/se4ad.config"
script_phase2="install_se4ad_phase2.sh"
lxc_arch="$(arch)"
ecard="br0"
nameserver="$(grep "^nameserver" /etc/resolv.conf | cut -d" " -f2| head -n 1)"
se4ad_config_tgz="se4ad.config.tgz"



show_title
show_part "Recupération des données depuis la BDD et initialisation des variables"



check_whiptail
conf_network
install_lxc_package
write_host_lan
preconf_se4ad_lxc
write_lxc_conf
install_se4ad_lxc
show_part "Post-installation du container : Mise en place des fichiers nécessaires à la phase 2 de l'installation"
write_lxc_lan
write_lxc_profile
write_lxc_bashrc
export_smb_files
write_sambaedu_conf
export_ldap_files
cp_config_to_lxc
write_se4ad_install
write_lxc_hosts_conf
write_ssh_keys
launch_se4ad
display_end_message



# echo "Appuyez sur ENTREE "
exit 0


