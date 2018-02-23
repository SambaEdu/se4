# Bac a sable

Dossier pour échanger des fichiers, ne fait pas partie des paquets !

# Changements liés au passage de se3 vers sambaedu
## Arborescence
- /var/www/se3 -> /var/www/sambaedu
- /var/se3 -> /var/sambaedu
- /usr/share/se3 -> /usr/share/sambaedu
- la conf (ex params) est dans /etc/sambaedu/sambaedu.conf

## Mysql
- la base s'appelle sambaedu

## Scripts
- config.inc.php déclare des fonctions de type set_config(), il faut donc désormais faire des require_once "config.inc.php"
pour éviter lees erreurs fatales . A voir s'il serait préférable de déplacer ces fonctions dans le fichier includes/functions.php
- les paramètres de connexion à la bdd doivent être dans sambedu.conf car config.inc.php ne les fournit plus
