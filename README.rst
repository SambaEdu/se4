SambaEdu4 - évolution de SambaEdu3
==================================

.. sectnum::
.. contents:: Table des matières

Objectifs
---------

-  Contrôleur de domaine AD, pouvant soit fonctionner de façon isolée en
   important directement les utilisateurs depuis les bases Siecle/STS,
   soit être intégré dans une infrastructure fédératrice AD gérée au
   niveau des rectorats ou nationale.
-  Intégration automatisée de postes Windows 7 et 10, de postes GNU/Linux,
-  Serveur de fichiers SMB, avec gestion des instantanés (shadow copy)
   basé sur ZFS
-  Serveur d'impression SMB/CUPS, avec intégration possible avec la
   solution de gestion centralisée PaperCut (payante)
-  Déploiement et mises à jour centralisée des logiciels à l'aide de
   WPKG et Wsusoffline
-  Solution de clonage
-  Intégration avec un cloud seafile/seadrive

Techniquement, le serveur est construit sur debian 9 stretch, avec Samba
4.5.x et eventuellement ZFSonLinux ou dcache. Les paquets sont
construits en respectant le standard Debian pour pouvoir être mis à jour
facilement, et donc suivre les versions Debian.

Matériel et stockage
--------------------

Proxmox 5.x est une excellente base de virtualisation libre. Mais
XenEdu, VMWare ou autres sont aussi possibles...

Deux types de serveurs sont envisagés :

-  Support physique :

   -  serveur de type « collège » : 2 disques SATA 2-4 To en raid 1 + cache
      SSD avec ``Dcache``
   -  serveurs de type « lycée » : N > 4 disques SATA en ZFS raid10 + cache
      SSD, cluster iscsi ?

-  Serveurs virtuels ou conteneurs LXC :

   -  vm « AD » avec le serveur AD, ``netlogon`` et ``sysvol``
   -  vm « NAS » avec les partages de fichiers ``samba``, l'interface ``web``, ``dhcp``,
      ``ipxe``, et le serveur d'impression
   -  vm « cloud » avec ``seafile`` et ``nginx``

Il est possible de conserver la partie « NAS » sur le serveur physique,
l'avantage potentiel étant de meilleurs performances pour les accès
disques car ils sont en direct, et surtout une migration facilitée dans
le cas d'un se3.

L'équipe Samba recommande fortement la séparation du serveur AD du
serveur de fichiers. Le choix a donc été d'utiliser un container ou la
virtualisation. Le serveur de fichiers est une configuration
complètement standard, et peut donc être un NAS externe. Il n'y a pas
d'exigence particulière à respecter. Il est possible de répartir les
serveurs de fichiers sur plusieurs machines. Les disques virtuels
peuvent être des ZVOL avec tous les avantages en terme de sauvegarde et
de journalisation.

Le « NAS » doit pouvoir executer des scripts de manipulation de fichiers,
soit via samba root preexec, soit à distance depuis l'interface : en
gros les sudo actuels deviennent du ssh -> faire un paquet
sambaedu-scripts à déployer sur les « NAS », ou déployer en scp ?

Un nouveau projet
------------------

Bien que la plupart du code soit repris de SE3, il ne s'agit pas d'une
mise à jour, mais d'un projet parallèle. Cela n'empêche pas que tout
sera fait pour simplifier le passage de *Se3* vers *Se4*.

Dans un premier temps toutes les pages de l'interface faisant doublon
avec les outils de la console AD GPO ne seront pas repris : seules les
pages ``annuaire``, ``importation``, ``partages`` et ``parcs`` sont conservées.

Roadmap
-------

+-------------------------------------------------------------------+----------------+
| Mettre à disposition des développeurs une VM                      |                |
| ``stretch/samba4.5/SE3`` avec un annuaire migré en AD servant     |                |
| de base de travail pour mettre le code se3 en compatibilité AD    | **☑ Fait**     |
+-------------------------------------------------------------------+----------------+
| Avoir une VM migrée AD fonctionnelle pour les pages principales : |                |          
| ``annuaire``, ``import`` (siecle/sts), ``partages``, ``parcs``    | **☐ En cours** |
+-------------------------------------------------------------------+----------------+
| Mise en place d'une arborescence permettant de générer des        |                |
| paquets.                                                          | **✋À faire**  |
+-------------------------------------------------------------------+----------------+
| Travail sur l'interopérabilité : intégration des clients          |                |
| GNU/Linux, SSO pour sites ou applis diverses...                   | **✋À faire**  |
+-------------------------------------------------------------------+----------------+
| ``wpkg`` et ``clonage``                                           | **✋À faire**  |
+-------------------------------------------------------------------+----------------+
| Migration depuis se3                                              | **☐ En cours** |
+-------------------------------------------------------------------+----------------+
| Intégration à l'interface d'outils ``GPO``                        | **✋À faire**  |
+-------------------------------------------------------------------+----------------+


Documentations en rapport avec le développement de SE4
------------------------------------------------------

-  `communication avec AD - API <API.md>`__
-  `Notes diverses <notes.md>`__
-  `Règles d'utilisations et structures des fichiers de
   conf <Fichiers_de_conf.md>`__
-  `Install\_proxmox - configuration matériel <Install_proxmox.md>`__
-  `Modèle de données manipulé par SambaEdu <Modele.md>`__
-  `Structure du paquet debian SE4 <Paquets%20Debian.md>`__
-  `Supprimer Mysql pour les paramètres <Virer_mysql.md>`__
-  `installation stretch - concepts (deprecated car géré par
   script) <install_stretch.md>`__
-  `migration ldap-->AD Principes <migration-ldap.md>`__
-  `Configuration Apache en mode fast\_cgi + suexec <apache.md>`__
