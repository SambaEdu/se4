#!/bin/bash

# Génération de la config dhcp de base à partir des fichiers de conf.
# N'écrit pas les réservations. Celles-ci sont inclues par le fichier
# reservations.conf généré  à partir de l'AD


. /usr/share/sambaedu/includes/config.inc.sh

conf=/etc/dhcp/dhcpd.conf

echo "################################################################################">$conf
echo "# This File is automagically created by sambaedu, do not edit  ">>$conf
echo "##       GENERAL OPTIONS          ##############################################">>$conf
echo "allow booting;">>$conf
echo "allow bootp;">>$conf
echo "authoritative;">>$conf

echo "option domain-name \"$config_domain_name;\"">>$conf
echo "option domain-search \"$config_domain_name;\"">>$conf
echo "option domain-name-servers \"$config_se4ad_ip;\"">>$conf

echo "max-lease-time $config_max_bail;">>$conf
echo "default-lease-time $config_normal_bail;">>$conf

echo "option wpad-url code 252 = string;">>$conf
echo "option wpad-url \"$config_wpad\";">>$conf

echo "option netbios-name-servers \"$config_se4ad_ip\";">>$conf

# boot ipxe
echo "###       BOOT OPTIONS          ##############################################">>$conf
echo "next-server  $config_tftp_server;">>$conf
# booter ipxe.lkrn, puis la conf ipxe :
# script ipxe statique avent install de sambaedu-ipxe, puis page php
echo "if option client-architecture = encode-int ( 16, 16 ) \{">>$conf
# uefi 
echo "     option vendor-class-identifier \"HTTPClient\";">>$conf
echo "     filename \"$config_ipxe_url/ipxe.efi\";">>$conf
echo "\} else \{">>$conf
# bios
echo "   if exists user-class and option user-class = \"sambaedu\" \{">>$conf
#echo "    filename \"http://$config_tftp_server:909/ipxe/boot.php?mac=\$\{net0/mac\}\";">>$conf  
echo "        filename \"$config_ipxe_url/$config_ipxe_script\";">>$conf  
echo "   \} else \{">>$conf
echo "        filename \"$config_ipxe_url/ipxe.lkrn\";">>$conf
echo "   \}">>$conf
echo "\}">>$conf
# fichier option supplémentaire
if [ -n "$config_extra_option" ]; then
	echo "include \"$config_extra_option\";">>$conf
fi

# reseaux
echo "###       SUBNETS          ##############################################">>$conf

if [ -n "$config_vlan" ]; then
    i="0"
    while [ $i -lt $config_vlan ]; do
        i=$[$i+1]
        RESEAU=$config_dhcp_reseau_$i
        MASQUE=$config_dhcp_masque_$i
        BEGIN_RANGE=$config_dhcp_begin_range_$i
        END_RANGE=$config_dhcp_end_range_$i
        GATEWAY=$config_dhcp_gateway_$i
        EXTRA_OPTION=$config_dhcp_extra_option_$i
        if [ -n "${!RESEAU}" ]; then 
            echo "">>$conf
		    echo "#####  SUBNETS DECLARATION #########">>$conf
		    echo "subnet ${!RESEAU} netmask ${!MASQUE} \{">>$conf
		    echo "    range ${!BEGIN_RANGE} ${!END_RANGE};">>$conf
		    echo "    option routers ${!GATEWAY};">>$conf
		    if [ -n "${!EXTRA_OPTION}" ]; then
		        echo "    include \"${!EXTRA_OPTION}\";">>$conf
		    fi
		    echo "\}">>$conf
        fi
    done
else
    RESEAU=$config_dhcp_reseau
    MASQUE=$config_dhcp_masque
    BEGIN_RANGE=$config_dhcp_begin_range
    END_RANGE=$config_dhcp_end_range
    GATEWAY=$config_dhcp_gateway
    EXTRA_OPTION=$config_dhcp_extra_option

    echo "">>$conf
    echo "#####  SUBNETS DECLARATION #########">>$conf
	echo "subnet ${RESEAU} netmask ${MASQUE} \{">>$conf
	echo "    range ${BEGIN_RANGE} ${END_RANGE};">>$conf
	echo "    option routers ${GATEWAY};">>$conf
	if [ -n "${EXTRA_OPTION}" ]; then
	   echo "    include \"${EXTRA_OPTION}\";">>$conf
	fi
	echo "\}">>$conf
fi

# reservations
if [ -e /var/www/sambaedu/dhcp/make_reservations.php ]; then 
    php /var/www/sambaedu/dhcp/make_reservations.php
fi
if [ -e /etc/dhcp/reservations.conf ] ; then
    echo "include \"/etc/dhcp/reservations.conf\";" >> $conf
fi

systemctl reload isc-dhcp-server.service




