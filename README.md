# se4
sambaedu4
SambaEdu4 erst l'évolution de SambaEdu3.


Les objectifs sont : 

* contrôleur de domaine AD, pouvant soit fonctionner de façon isolée en important directement les utilisateurs depuis les bases Siecle/STS, soit être intégré dans une infrastructure fédératrice gérée au niveau des rectorats ou nationale.
* Intégration automatisée de postes Windows 7 et 10, de postes Linux,
* serveur de fichiers SMB, avec gestion des instantanés (shadow copy) basé sur ZFS
* serveur d'impression SMB/CUPS, avec intégration possible avec la solution de gestion centralisée PaperCut (payante)
* mise à jour centralisée des logiciels WPKG et Wsusoffline
* solution de clonage

Techniquement, le  serveur est construit sur debian Jessie, avec Samba 4.4.x et ZFSonLinux

Attention !

Bien que la plupart du code soit repris de SE3, il ne s'agit pas d'une mise à jour, mais d'un nouveau projet. Dans un premier temps, rien ne sera prévu pour permettre la migration d'une solution à l'autre !
