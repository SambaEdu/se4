#!/bin/bash
# lecture et ecriture des parametres de config sambaedu4
# fichier à inclure au début de tout script devant accéder à la conf 
#
# assignation des variables de conf
for conf in $(find /etc/sambaedu -type f); do
# version de transition avec param=value et config_param= value
    for ligne in $(sed -E "/^#.*$/d;s|^(\S+)\s*=\s*(\".*\")$|config_\1=\2 \1=\2|g" $conf); do
# version finale
#    for ligne in $(sed -E "/^#.*$/d;s|^(\S+)\s*=\s*(\".*\")$|config_\1=\2|g" $conf); do
        eval $ligne
    done
done
# fonction permettant l'écriture des parametres
# set_config module param [value]
set_config () {
    if [ "$1" == "sambaedu" ]; then
	    conf="/etc/sambaedu/sambaedu.conf"
    else
	    conf="/etc/sambaedu/sambaedu.conf.d/$1.conf"
    fi
    if [ -n "$2" ]; then
        if [ -f "$conf" ]; then
            if $(grep -q "$2" $conf); then
               if [ -z "$3" ]; then
                   sed -i "|^${2}\s*=.*$|d" $conf
	           else 	 	
                   sed -i "s|^${2}\s*=\s*.*$|${2} = \"${3}\"|" $conf
               fi
            fi
        else
	        if [ -n "$3" ]; then
                echo "$2 = \"$3\"">>$conf
            fi
        fi
        eval $2="$3" 
        eval config_$2="$3"
    fi
}
