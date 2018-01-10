#!/bin/bash
#
##### Permet l'installation et la conf d'un container LXC se4-AD#####
#



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

function erreur()
{
        echo -e "$COLERREUR"
        echo "ERREUR!"
        echo -e "$1"
        echo -e "$COLTXT"
        exit 1
}

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

function debug() {
debug="1"
if [ "$debug" = "1" ]; then
set -x
POURSUIVRE
fi

}

function install_lxc()
{
echo "Vérification de l'existence des backports dans le sources.list"
echo
url_depot_backpot="deb http://ftp.fr.debian.org/debian/ wheezy-backports main"
grep -q "^$url_depot_backpot" /etc/apt/sources.list || echo "$url_depot_backpot" >> /etc/apt/sources.list
echo -e "${COLCMD}Mise à jour des dépots....${COLTXT}"
# apt-get autoremove 
apt-get -qq update

echo -e "${COLCMD}installation de LXC version backportée${COLTXT}"
apt-get install bridge-utils
apt-get install -t wheezy-backports lxc

grep -q cgroup /etc/fstab || echo "cgroup  /sys/fs/cgroup  cgroup  defaults  0   0" >> /etc/fstab
mount -a
}

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
}

function write_lxc_conf {

if [ -e "usr/share/se3/sbin/lxc_mac_generator" ]; then
	echo -e "$COLINFO"
	echo "Génération de l'adresse MAC de la machine LXC"
	echo -e "$COLTXT"
	se4mac="$(usr/share/se3/sbin/lxc_mac_generator)"
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
lxc.network.ipv4.gateway = $se3gw

END
}

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
	wget $url_sambaedu_config/lxc/template/lxc-debianse4
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
netmask $se3mask
network $se3network
broadcast $se3bcast
gateway $se3gw
END

chmod 644 $interfaces_file_lxc

}

function write_lxc_profile
{

profile_lxc="/var/lib/lxc/$se4name/rootfs/root/.profile"
echo -e "$COLINFO"
echo "Génération de $profile_lxc"
echo -e "$COLTXT"
echo '# ~/.profile: executed by Bourne-compatible login shells.
if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi

mesg n' > $profile_lxc
echo "
if [ -f /root/$script_phase2 ]; then
    . /root/$script_phase2  
fi

if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
" >> $profile_lxc 
}

function write_lxc_bashrc
{
lxc_bashrc="/var/lib/lxc/$se4name/rootfs/root/.bashrc"
if [ -e "$dir_config/lxc/bashrc" ]; then
	echo -e "$COLINFO"
	echo "Copie de $dir_config/lxc/bashrc"
	echo -e "$COLCMD"
	cp -v $dir_config/lxc/bashrc $lxc_bashrc
	echo -e "$COLTXT"
else
	echo -e "$COLINFO"
	echo "Récupération du fichier bashrc"
	echo -e "$COLCMD"
	wget $url_sambaedu_config/lxc/bashrc
	mv -v bashrc $lxc_bashrc
	echo -e "$COLTXT"
fi
chmod 644 $lxc_bashrc
}


function write_sambaedu_conf
{
if [ ! -e "$se4ad_config" ] ; then
	echo -e "$COLINFO"
	echo "Pas de fichier de conf $se4ad_config  -> On en crée un avec les params du se4ad"
	echo -e "$COLTXT"
	echo "se4ad_ip=$se4ad_ip" > $se4ad_config
	echo "mondomaine=$mondomaine" >>  $se4ad_config
	echo "lan=$lan" >>  $se4ad_config
	echo "fulldomaine=$fulldomaine" >> $se4ad_config
	echo "se3ip=$se3ip" >> $se4ad_config
	echo "se3_domain=$se3_domain"  >> $se4ad_config
	echo "netbios_name=$netbios_name" >> $se4ad_config
	echo "se3gw=$se3gwnetbios_name" >> $se4ad_config
	

	chmod +x $se4ad_config
fi

if [ ! -e "$dir_config/ldap.conf" ]; then
	conf_ldap="/etc/ldap/ldap.conf"
	echo -e "$COLINFO"
	echo "Export de la conf ldap vers $dir_config"
	echo -e "$COLTXT"
	cp -v $conf_ldap $dir_config/
fi

dir_config_lxc="/var/lib/lxc/$se4name/rootfs/etc"
# mkdir -p $dir_config_lxc
echo "copie de $dir_config sur la machine LXC"
echo -e "$COLCMD"
cp -av  $dir_config $dir_config_lxc/
echo -e "$COLTXT"
}

function write_se4ad_install
{

dir_root_lxc="/var/lib/lxc/$se4name/rootfs/root"
if [ -e "$dir_config/lxc/$script_phase2" ]; then
	echo -e "$COLINFO"
	echo "Copie de $dir_config/lxc/$script_phase2"
	echo -e "$COLCMD"
	cp -v $dir_config/lxc/$script_phase2 $dir_root_lxc/$script_phase2
	echo -e "$COLTXT"
else
	echo -e "$COLINFO"
	echo "Récupération de $script_phase2"
	echo -e "$COLCMD"
	wget $url_sambaedu_config/lxc/$script_phase2
	mv -v $script_phase2 $dir_root_lxc/$script_phase2
	echo -e "$COLTXT"
fi
chmod +x $dir_root_lxc/$script_phase2
}

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
$se4ad_ip	se4ad.$fulldomaine	se4ad
END

lxc_hostname_file="/var/lib/lxc/$se4name/rootfs/etc/hosts"
echo -e "$COLINFO"
echo "Génération de $lxc_hostname_file"
echo -e "$COLTXT"

cat >$lxc_hostname_file <<END
se4ad
END
}

function export_smb_files()
{
echo -e "$COLINFO"
echo "Coupure du service Samba pour export des fichier TDB"
echo -e "$COLTXT"
service samba stop
smb_dbdir_export="/etc/sambaedu/smb_export"
mkdir -p "$smb_dbdir_export"
echo -e "$COLINFO"
echo "Copie des fichiers TDB vers $smb_dbdir_export"
echo -e "$COLCMD"
tdb_smb_dir="/var/lib/samba"
pv_tdb_smb_dir="/var/lib/samba/private"
cp $pv_tdb_smb_dir/secrets.tdb $smb_dbdir_export/
cp $pv_tdb_smb_dir/schannel_store.tdb $smb_dbdir_export/
cp $pv_tdb_smb_dir/passdb.tdb $smb_dbdir_export/

cp $tdb_smb_dir/gencache_notrans.tdb $smb_dbdir_export/
cp $tdb_smb_dir/group_mapping.tdb $smb_dbdir_export/
cp $tdb_smb_dir/account_policy.tdb $smb_dbdir_export/

cp /etc/samba/smb.conf $dir_config/
}

clear
echo -e "$COLTITRE"
usage
echo -e "$COLINFO"
echo "Appuyez sur Entree pour continuer..."

echo -e "$COLTXT"
read

echo -e $COLPARTIE
echo "--------"
echo "Partie 1 : Recupération des données"
echo "--------"
echo -e "$COLTXT"

## recuperation des variables necessaires pour interoger mysql ###
source /etc/se3/config_m.cache.sh
source /usr/share/se3/includes/functions.inc.sh 


# Variables :
url_sambaedu_config="https://raw.githubusercontent.com/SambaEdu/se4/master/sources/sambaedu-config"
interfaces_file="/etc/network/interfaces" 
dir_config="/etc/sambaedu"
se4ad_config="$dir_config/se4ad.config"
script_phase2="install_se4ad_phase2.sh"
lxc_arch="$(arch)"
ecard="br0"

# A voir pour modifier avec hostname -d pour le moment on fixe sambaedu4 

# mondomaine=$(hostname -d | cut -d"." -f1)
# fulldomaine=$(hostname -d)

[ -z "$mondomaine" ] && mondomaine="sambaedu4"
[ -z "$fulldomaine" ] && fulldomaine="${mondomaine}.lan" 

# source /usr/share/se3/sbin/bibliotheque_ip_masque.sh

se3network=$(grep network $interfaces_file | grep -v "#" | sed -e "s/network//g" | tr "\t" " " | sed -e "s/ //g")
se3bcast=$(grep broadcast $interfaces_file | grep -v "#" | sed -e "s/broadcast//g" | tr "\t" " " | sed -e "s/ //g")
se3gw=$(grep gateway $interfaces_file | grep -v "#" | sed -e "s/gateway//g" | tr "\t" " " | sed -e "s/ //g")


REPONSE=""
while [ "$REPONSE" != "o" ]
do
	if [ "$REPONSE" = "n" ]; then
		echo -e "${COLTXT}Adresse de base du réseau $COLSAISIE\c"
		read se3network
		echo -e "${COLTXT}Adresse de broadcast $COLSAISIE\c"
		read se3bcast
		echo -e "${COLTXT}Adresse de la passerelle $COLSAISIE\c"
		read se3gw
	fi

	echo -e "$COLINFO"
	echo "Configuration réseau actuelle détectée :"
	echo -e "$COLTXT\c"
	echo "Adresse IP du serveur :  $se3ip"
	echo "Adresse réseau de base : $se3network"
	echo "Adresse de Broadcast :   $se3bcast"
	echo "IP de la Passerelle :    $se3gw"
	
	
	echo -e "$COLTXT"
	echo -e "Confirmer cette configuration réseau ? (${COLCHOIX}o${COLTXT}/${COLCHOIX}n${COLTXT}) $COLSAISIE\c "
	read REPONSE
done



echo -e $COLPARTIE
echo "--------"
echo "Partie 2 : Installation  et configuration de LXC"
echo "--------"
echo -e "$COLTXT"
install_lxc
echo 
write_host_lan


#refresh cache params sql 
# /usr/share/se3/includes/config.inc.sh -mf
# source /etc/se3/config_m.cache.sh

#
# Redémarrage de l'interface réseau
#

[ -z "$ecard" ] && ecard="br0"
echo -e "$COLCMD\c"
echo -e "Redémarrage de l'interface réseau...\c"
echo -e "$COLTXT"
/etc/init.d/networking stop
/etc/init.d/networking start
echo -e "$COLTXT\c"
ifup $ecard

echo -e $COLPARTIE
echo "--------"
echo "Partie 3 : Pré-configuration du container LXC SE4"
echo "--------"
echo -e "$COLTXT"

REPONSE=""
details="no"
while [ "$REPONSE" != "o" ]
do
	echo -e "${COLTXT}IP du container SE4 : $COLSAISIE\c"
	read se4ad_ip

	if [ "$details" != "no" ]; then
		echo -e "${COLTXT}Masque sous réseau: $COLSAISIE\c"
		read se3mask
		echo -e "${COLTXT}Adresse réseau $COLSAISIE\c"
		read se3network
		echo -e "${COLTXT}Adresse de broadcast $COLSAISIE\c"
		read s3bcast
		echo -e "${COLTXT}Adresse de la passerelle $COLSAISIE\c"
		read se3gw
	fi
	details="yes"
	
		
		echo -e "$COLINFO"
		echo "Configuration IP prévue pour le container :"
		echo -e "$COLTXT\c"
		echo "IP :         $se4ad_ip"
		echo "Masque :     $se3mask"
		echo "Réseau :     $se3network"
		echo "Broadcast :  $se3bcast"
		echo "Passerelle : $se3gw"
	
		echo -e "$COLTXT"
		echo -e "Confirmer la configuration pour le container ? (${COLCHOIX}o${COLTXT}/${COLCHOIX}n${COLTXT}) $COLSAISIE\c"
		read REPONSE
done
echo -e "${COLTXT}Nom du container SE4: [se4ad]$COLSAISIE \c"
read se4name
[ -z "$se4name" ] && se4name="se4ad"
POURSUIVRE
echo -e "$COLTXT"
echo -e $COLPARTIE
echo "--------"
echo "Partie 4 : Installation du container $se4name"
echo "--------"
echo -e "$COLTXT"
sleep 2

write_lxc_conf
install_se4ad_lxc

echo -e "$COLTXT"
echo -e $COLPARTIE
echo "--------"
echo "Partie 5 : Post-installation du container : Mise en place des fichiers nécessaires à la phase 2"
echo "--------"
echo -e "$COLTXT"
sleep 2

write_lxc_lan
write_lxc_profile
write_lxc_bashrc
export_smb_files
write_sambaedu_conf
write_se4ad_install
write_lxc_hosts_conf
echo -e "/!\ notez bien le mot de passe root du container  --->$COLINFO se4ad $COLTXT
Il vous sera indispensable pour le premier lancement"

echo -e "$COLTXT"
# echo "Appuyez sur ENTREE "

# echo "Un nouveau script d'installation se lancera sur le container une fois que vous serez connecté root"
echo -e "$COLTITRE"
echo "Terminé!"
echo "--------"
echo -e "$COLTXT"
echo -e "${COLINFO}Container $se4name installé. Pour lancer la machine, utiliser la commande suivante :$COLCMD
lxc-start -n $se4name"
echo -e "${COLTXT}L'installation se poursuivra ensuite une fois identifié root
/!\ Mot de passe root --->$COLINFO se4ad $COLTXT"
echo "--------"

echo ""
# echo "Appuyez sur ENTREE "
exit 0


