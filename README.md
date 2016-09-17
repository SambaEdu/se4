# se4

SambaEdu4 est l'évolution de SambaEdu3.


## Les objectifs sont : 

* contrôleur de domaine AD, pouvant soit fonctionner de façon isolée en important directement les utilisateurs depuis les bases Siecle/STS, soit être intégré dans une infrastructure fédératrice AD gérée au niveau des rectorats ou nationale.
* Intégration automatisée de postes Windows 7 et 10, de postes Linux,
* serveur de fichiers SMB, avec gestion des instantanés (shadow copy) basé sur ZFS
* serveur d'impression SMB/CUPS, avec intégration possible avec la solution de gestion centralisée PaperCut (payante)
* mise à jour centralisée des logiciels WPKG et Wsusoffline
* solution de clonage

Techniquement, le  serveur est construit sur debian Jessie, avec Samba 4.4.x et ZFSonLinux. Les paquets sont construits en respectant le standard Debian pour pouvoir être mis à jour facilement, et donc suivre les versions Debian. 

## Attention !

Bien que la plupart du code soit repris de SE3, il ne s'agit pas d'une mise à jour, mais d'un projet parallèle. Dans un premier temps, rien ne sera prévu pour permettre la migration depuis SE3 ! 

Dans un premier temps tous les pages de l'interface faisant doublon avec les outils de la console AD GPO ne seront pas repris : seules les pages annuaire, importation, partages et parcs sont conservées. 

## Roadmap 
* mettre à disposition des développeurs une VM jessie/samba4.4/SE3 avec un annuaire migré en AD servant de base de travail pour mettre le code se3 en compatibilité AD
* avoir une VM migrée AD fonctionnelle pour les pages principales : annuaire, import (siecle/sts), partages, parcs 
* mise en place d'une arborescence permettant de générer des paquets.
* travail sur l'interopérabilité : intégration des clients linux, SSO pour sites ou applis diverses...
* wpkg et clonage,
* migration depuis se3
* intégration à l'interface d'outils GPO
