# Arborescence : 

Le dépôt SE4 contient l'ensemble des sources SambaEdu. Sont exclus les modules optionnels.

## dossier sources 
contient l'arborescence des ficihers tels qu'ils seront sur le serveur + le dossier debian
## dossier debian
contient les scripts de construction et d'installation des paquets.

Le principe est que chaque fichier peut être préfixé par le paquet qui le concerne : `sambaedu-config.postinst` 

Par exemple 
`sambaedu-config.dirs` contient les dossiers ̀ etc/sambaedu/sambaedu.conf.d`
*note* on peut aussi faire des makefile avec des regles pour chaque paquet... mais dans notre cas c'est peut-etre plus commpliqué.

## chemins
On revient au standard /etc, /usr/bin, /usr/lib /var/www/sambaedu ?
On prefixe les scripts bin/se-* ou bin/sambaedu-* ?

Avantage : peu d'interférence avec le code se3, conformité Debian, path ok
Inconvénient : il faut tout déplacer

## Découpage :

L'idée est de construire des paquets par fonction avec un arbre de dépendance le plus simple possible. 
La question à se poser est : peut-on mettre à jour ce sous ensemble sans interférence avec d'autres parties définies comme non dépendantes ?
Pas la peine non plus d'aller trop loin dans la division...

Voir debian/control : https://github.com/SambaEdu/se4/blob/master/sources/debian/control


