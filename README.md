# se4

SambaEdu4 est l'évolution de SambaEdu3.


## Les objectifs sont : 

* contrôleur de domaine AD, pouvant soit fonctionner de façon isolée en important directement les utilisateurs depuis les bases Siecle/STS, soit être intégré dans une infrastructure fédératrice AD gérée au niveau des rectorats ou nationale.
* Intégration automatisée de postes Windows 7 et 10, de postes Linux,
* serveur de fichiers SMB, avec gestion des instantanés (shadow copy) basé sur ZFS 
* serveur d'impression SMB/CUPS, avec intégration possible avec la solution de gestion centralisée PaperCut (payante)
* déploiement et mises à jour centralisée des logiciels à l'aide de WPKG et Wsusoffline
* solution de clonage
* intégration avec un cloud seafile/seadrive

Techniquement, le  serveur est construit sur debian 9 stretch, avec Samba 4.5.x et eventuellement ZFSonLinux ou dcache. Les paquets sont construits en respectant le standard Debian pour pouvoir être mis à jour facilement, et donc suivre les versions Debian. 

## matériel et stockage
Deux types de serveurs sont envisagés : 

* Support physique :

 - serveur de type "collège" : 2 disques SATA 2-4 To en raid 1 + cache SSD avec 'Dcache' 
 - serveurs de type "lycée" : N > 4 disques SATA en ZFS raidz1 + cache SSD, cluster iscsi ?

* Serveurs virtuels ou conteneurs : 

 - vm "AD" avec le serveur AD,  `netlogon` et `sysvol`
 - vm "NAS" avec les partages de fichiers samba, l'interface web, dhcp, ipxe, et le serveur d'impression
 - vm "cloud" avec seafile et nginx
 
 Il est possible de conserver la partie "NAS" sur le serveur physique, l'avantage potentiel étant de meilleurs performances pour les accès disques car ils sont en direct, et surtout une migration facilitée dans le cas d'un se3.

L'équipe Samba recommande fortement la séparation du serveur AD du serveur de fichiers. La configuration virtualisées est donc probablement préférable. Le serveur de fichiers est une configuration complètement standard, et peut donc être un NAS externe. Il n'y a pas d'exigence particulière à respecter. Il est possible de répartir les serveurs de fichiers sur plusieurs machines. 
Proxmox 5.x est une bonne base de virtualisation libre. Les disques virtuels peuvent être des ZVOL avec tous les avantages en terme de sauvegarde et de journalisation.

Le "NAS" doit pouvoir executer des scripts de manipulation de fichiers, soit via samba root preexec, soit à distance depuis l'interface : en gros les sudo actuels deviennent du ssh -> faire un paquet sambaedu-scripts à déployer sur les "NAS", ou déployer en scp ?

## Attention !

Bien que la plupart du code soit repris de SE3, il ne s'agit pas d'une mise à jour, mais d'un projet parallèle. Dans un premier temps, rien ne sera prévu pour permettre la migration depuis SE3 ! 

Dans un premier temps toutes les pages de l'interface faisant doublon avec les outils de la console AD GPO ne seront pas repris : seules les pages annuaire, importation, partages et parcs sont conservées. 

## Roadmap 
* mettre à disposition des développeurs une VM stretch/samba4.5/SE3 avec un annuaire migré en AD servant de base de travail pour mettre le code se3 en compatibilité AD **fait**
* avoir une VM migrée AD fonctionnelle pour les pages principales : annuaire, import (siecle/sts), partages, parcs 
* mise en place d'une arborescence permettant de générer des paquets.
* travail sur l'interopérabilité : intégration des clients linux, SSO pour sites ou applis diverses...
* wpkg et clonage,
* migration depuis se3
* intégration à l'interface d'outils GPO
