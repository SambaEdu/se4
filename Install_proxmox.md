# Installation du serveur de virtualisation Proxmox

Proxmox est une bonne base pour monter un serveur de virtualisation Sambaedu. 

## Matériel

### Controleurs disques

Pour profiter pleinement des fonctionnalités de PVE, l'utilisation de ZFS est fortement conseillée. PVE le propose dès l'installation. 
ZFS est un système de fichiers très sophistiqué, qui remplace le raid, lvm et ext4. Il s'agit d'une solution purement logicielle, qui pour fonctionner avec les performances et la sécurité maximale doit pouvoir accéder directement aux disques.
Toute forme de RAID matériel est donc à proscrire. Plusieurs cas de figure sont possibles : 

- pas de carte raid : les disques sont connectés directement sur les ports SATA de de la carte mère. Inconvénient, ceux-si sont rarement connectables à chaud, et souvent limités à moins de 6. Souvent les perfs sont relativement limitées surtout sur du matériel un peu ancien.
- carte raid SATA/SAS basse/moyenne gamme : il faut configurer la carte dans le bios pour qu'elle soit en mode `JBOD`, `IT mode`, `HBA` ou accès direct au disques. La désignation dépend de la marque. Pour certaines cartes LSI, il est possible de flasher un firmware spécial `IT mode` qui permet d'avoir de bien meilleurs performances. 
- cartes raid avec batteries (BBU) : même remarque que ci dessus, sauf que certains cartes ne permettent pas du tout l'accès direct. Elles sont donc inutilisables. C'est notamment le cas de toutes les DELL PERC6.
- cartes d'extension HBA SAS/SATA : pas de problème, c'est fait spécialement pour...

Si le chassis du serveur le permet, rien n'interdit de répartir les disques sur plusieurs contrôleurs, les perfs n'en seront que meilleures. On peut aussi utiliser une baie de stockage externe.

### Disques

Eviter les disques Sata pour NAS et les disques grand public, ils sont très lents pour les accès simultanés. 

Par ordre de performance : 

- disques SATA serveur ou NearLine SAS : bon rapport capacité-perfs/coût et fiabilité. Compter 230 € pour 4 To
- disques SAS serveur 10 ou 15k : même si ils sont relativement anciens, ces disques sont rapides mais généralement de faible capacité. Cela peut malgré tout valoir le coup de les récuperer.
- SSD grand public : excellentes perfs et prix en baisse, fiablilité correcte. compter 300 € / To
- SSD pro : perfs et fiablilité. Compter 400 € / To. C'est ceux-ci qu'il faut utiliser pour le cache (samsung 850 evo pro).

## Pool de stockage
PVE propose à l'installation de créer directement un poll de stockage global pour tout le systmèe. C'est une bonne idée, car il est très facile de l'étendre ensuite.

Deux solutions sont possibles :
### RAID 5/6
Pour ZFS ce type de pool s'appelle raidz1 ou raidz2. Il comporte 1 ou 2 disques de redondance, et est équivalement à un raid 5 ou 6. 

Avantages : 

- la redondance ne consomme que 1 ou 2 disques

Inconvénients :

- perfs équivalentes à  un seul disque.
- pour augmenter la capacité il faut ajouter le même nombre de disques que ceux présents dans le pool
- raidz1 dangereux (si un deuxième disque meurt pendant le reconstruction, qui peut être très longue...)

### RAID 10
Pour zfs cette solution s'appelle mirror. Il est possible d'ajouter à chaud autant de paires de disques que l'on veut

Avantages :

- ajout de capacité à chaud très simple.
- perfs proportionnelles au nombre de disques.
- sécurité (la probabilité pour que les 2 disques d'une même paire meurent simultanément est faible, et la reconstruction est très rapide)

Inconvénients : 

- la redondance consomme la moitié de la capacité

Dans le cas d'un serveur Sambaedu, la config en miroir est la meilleure. En revanche pour un serveur de sauvegarde le raidz2 est la meilleure solution.

### cache
ZFS permet d'avoir un cache en écriture (log) et en lecture (cache). Un petit SSD de 128 go est suffisant. Il peut être ajouté à chaud à tout moment.  Prendre un disque "pro" ou une carte PCIE



