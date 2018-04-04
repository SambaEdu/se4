#!/bin/bash
#
##### Permet la génération du preseed de se4-AD#####
# franck molle
# version 03 - 2018 



function usage() 
{
echo "Script intéractif permettant la génération du preseed  se4-AD"
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

WELCOME_TITLE="Génération du preseed pour SE4-AD"
WELCOME_TEXT="Bienvenue dans la pré-installation SE4 Active Directory.

Ce programme va générer un fichier de configuration automatique (preseed) utilisable pour l'installation d'un SE4-AD sous Debian Stretch.

Une fois la machine SE4-AD installée, il suffira de la démarrer afin de poursuivre son installation et sa configuration de façon automatique."

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


# Fonction de preconfig du container
function preconf_se4ad()
{
se4ad_lan_title="Configuration réseau du futur SE4-AD"

REPONSE=""
details="no"
se4ad_ip="$(echo "$se3ip"  | cut -d . -f1-3)."
se4mask="$se3mask"
se4network="$se3network"
se4bcast="$se3bcast"
se4gw="$se3gw"
while [ "$REPONSE" != "yes" ]
do
	$dialog_box --backtitle "$BACKTITLE" --title "$se4ad_lan_title" --inputbox "Saisir l'IP du SE4-AD" 15 70 $se4ad_ip 2>$tempfile || erreur "Annulation"
	se4ad_ip=$(cat $tempfile)
	
	if [ "$details" != "no" ]; then
		$dialog_box --backtitle "$BACKTITLE" --title "$se4ad_lan_title" --inputbox "Saisir le Masque sous réseau" 15 70 $se3mask 2>$tempfile || erreur "Annulation"
		se4mask=$(cat $tempfile)
		
		$dialog_box --backtitle "$BACKTITLE" --title "$se4ad_lan_title" --inputbox "Saisir l'Adresse de base du réseau" 15 70 $se3network 2>$tempfile || erreur "Annulation"
		se4network=$(cat $tempfile)
		
		$dialog_box --backtitle "$BACKTITLE" --title "$se4ad_lan_title" --inputbox "Saisir l'Adresse de broadcast" 15 70 $se3bcast 2>$tempfile || erreur "Annulation"
		se4bcast=$(cat $tempfile)
		
		$dialog_box --backtitle "$BACKTITLE" --title "$se4ad_lan_title" --inputbox "Saisir l'Adresse de la passerelle" 15 70 $se3gw 2>$tempfile || erreur "Annulation"
		se4gw=$(cat $tempfile)
	fi
	details="yes"
	
	se4ad_name_title="Nom du SE4-AD"
	$dialog_box --backtitle "$BACKTITLE" --title "$se4ad_name_title" --inputbox "Saisir le Nom de la machine SE4-AD" 15 70 se4ad 2>$tempfile || erreur "Annulation"
	se4name=$(cat $tempfile)
	
	choice_domain_title="Important - nom de domaine AD"
	choice_domain_text="Sur un domaine AD, le serveur de domaine gère le DNS. Le choix du nom de domaine est donc important.
Il est composé de plusieurs parties : le nom de domaine samba suivi de son suffixe, séparés par un point.

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

echo -e "$COLTXT"
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
function cp_config_to_preseed()
{
echo "Création de l'archive d'export des données $se4ad_config_tgz et copie sur $dir_preseed"
cd $dir_config
echo -e "$COLCMD"
tar -czf $se4ad_config_tgz export_se4ad
cp -av  $se4ad_config_tgz $dir_preseed/
cd -
echo -e "$COLTXT"
sleep 2
}

# copie des clés ssh présente sur le serveur principal sur le container
function write_ssh_keys
{
ssh_keys_host="/root/.ssh/authorized_keys"

if [ -e "$ssh_keys_host" ];then
    echo -e "$COLINFO"
    echo "Copie du fichier des clés SSH $ssh_keys_host"
    cp "$ssh_keys_host" "$dir_preseed/"
    echo -e "$COLCMD"
else
    touch $dir_preseed/authorized_keys
    chmod 600 $dir_preseed/authorized_keys
fi
}

# Génération du preseed avec les données saisies
function write_preseed
{
dir_config_preseed="$dir_config/preseed"
template_preseed="preseed_se4_stretch.in"
target_preseed="$dir_preseed/se4ad.preseed"

if [ -e "$dir_config_preseed/$template_preseed" ];then
    echo -e "$COLINFO"
    echo "Copie du modele $template_preseed dans $target_preseed"
    cp "$dir_config_preseed/$template_preseed" "$target_preseed"
    echo -e "$COLCMD"
else
    echo -e "$COLINFO"
    echo "Récupération du fichier preseed"
    echo -e "$COLCMD"
    wget -nv $url_sambaedu_config/etc/sambaedu/preseed/$template_preseed
    mv -v $template_preseed $target_preseed
    echo -e "$COLTXT"
fi


echo -e "$COLINFO"
echo "Modification du preseed avec les données saisies"
echo -e "$COLCMD"

sed -e "s/###_SE4AD_IP_###/$se4ad_ip/g; s/###_SE4MASK_###/$se4mask/g; s/###_SE4GW_###/$se4gw/g; s/###_NAMESERVER_###/$nameserver/g; s/###_SE4NAME_###/$se4name/g" -i  $target_preseed
sed -e "s/###_AD_DOMAIN_###/$ad_domain/g; s/###_IP_SE3_###/$se3ip/g; s/###_NTP_SERV_###/$ntpserv/g" -i  $target_preseed 
}

# verif somme MD5
function check_md5() {

if [ -e "netboot_stretch.tar.gz" -a -e "MD5SUMS" ]; then
    md5_netboot_dl="$(grep "./netboot/netboot.tar.gz" MD5SUMS | cut -f1 -d" ")"
    md5_netboot_local="$(md5sum netboot_stretch.tar.gz  | cut -f1 -d" ")"
    
        
    if [ "$md5_netboot_dl" != "$md5_netboot_local" ]; then
        rm -f netboot_stretch.tar.gz
        rm -f MD5SUMS
        testmd5="ko"
    else
        testmd5="ok"
    fi
else
    testmd5="ko"
    fi

}

# Chargement du boot PXE debian Stretch et conf du tftp pour bootPXE
function conf_tftp() {
echo -e "$COLINFO"
echo "Configuration du TFTP"
echo -e "$COLTXT"
url_debian="ftp.fr.debian.org/debian"
tftp_menu="/tftpboot/tftp_modeles_pxelinux.cfg/menu/install.menu" 

# vérification de la présence du paquet se3-clonage
if [ ! -e "/usr/share/se3/scripts/se3_pxe_menu_ou_pas.sh" ]
then
    echo "installation du module Clonage" | tee -a $compte_rendu
    /usr/share/se3/scripts/install_se3-module.sh se3-clonage
    echo ""
fi

cd /tftpboot
check_md5
if [ "$testmd5" = "ko" ];then
    wget http://$url_debian/dists/stretch/main/installer-amd64/current/images/MD5SUMS
    wget http://$url_debian/dists/stretch/main/installer-amd64/current/images/netboot/netboot.tar.gz -O netboot_stretch.tar.gz
    check_md5
fi

if [ "$testmd5" != "ko" ]; then
    mkdir /tmp/netboot
    tar -xzf netboot_stretch.tar.gz -C /tmp/netboot 
    rm -rf /tftpboot/debian-installer-stretch
    mv  /tmp/netboot/debian-installer /tftpboot/debian-installer-stretch 
    rm -rf mkdir /tmp/netboot
    if [ -z "$(grep "DebianStretch64se4ad" $tftp_menu)" ] ; then
        echo "Ajout du menu d'installation SE4-AD dans le menu TFTP"
        echo "LABEL DebianStretch64se4ad
            MENU LABEL ^Netboot Debian stretch SE4-AD (amd64)
            KERNEL  debian-installer-stretch/amd64/linux
            APPEND  auto=true priority=critical preseed/url=http://$se3ip/diconf/se4ad.preseed initrd=debian-installer-stretch/amd64/initrd.gz --
            TEXT HELP
            Installation auto de se4-AD sur Debian Stretch amd64 
            ENDTEXT" >> $tftp_menu
        /usr/share/se3/scripts/se3_pxe_menu_ou_pas.sh menu
    fi
else
    echo -e "$COLERREUR"
    echo -e "Erreur MD5 du fichier téléchargé"
    echo -e "$COLTXT"
fi
service isc-dhcp-server restart
}

# Affichage message de fin
function display_end_message() {
display_end_title="Génération du preseed terminée !!"	
	
display_end_txt="Le preseed de $se4name a été généré

Pour lancer l'installation sur serveur $se4name, deux solutions :
- Via un boot PXE sur le se3, partie maintenance, rubrique installation puis  **Netboot Debian stretch SE4-AD**

- Par installation via clé ou CD netboot. vous devrez entrer l'url suivante au debian installeur :
http://$se3ip/diconf/se4ad.preseed

Le mot de passe root temporaire sera fixé à \"se4ad\""

$dialog_box --backtitle "$BACKTITLE" --title "$display_end_title" --msgbox "$display_end_txt" 20 70


echo -e "$COLTITRE"
echo "Génération du preseed de $se4name terminée !!
url pour l'installation :  
http://$se3ip/diconf/se4ad.preseed"
echo -e "$COLTXT"
}


######## Debut du Script ########

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
url_sambaedu_config="https://raw.githubusercontent.com/SambaEdu/sambaedu-config/master/sources"
interfaces_file="/etc/network/interfaces" 

dir_config="/etc/sambaedu"
dir_export="/etc/sambaedu/export_se4ad"
mkdir -p "$dir_export"
dir_preseed="/var/www/diconf"
se4ad_config="$dir_export/se4ad.config"
script_phase2="install_se4ad_phase2.sh"
nameserver="$(grep "^nameserver" /etc/resolv.conf | cut -d" " -f2| head -n 1)"
se4ad_config_tgz="se4ad.config.tgz"


show_title
check_whiptail
conf_network
preconf_se4ad
export_smb_files
write_sambaedu_conf
export_ldap_files
cp_config_to_preseed
write_ssh_keys
write_preseed
conf_tftp
display_end_message



# echo "Appuyez sur ENTREE "
exit 0


