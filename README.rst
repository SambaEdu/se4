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
   basé sur ZFS.
-  Serveur d'impression SMB/CUPS. Intégration possible avec la
   solution de gestion centralisée PaperCut (payante)
-  Déploiement de logiciels et de mises à jour centralisé à l'aide de
   WPKG ou Wsusoffline
-  Solutions de clonage ou déploiements automatique de Windows 10 
-  Intégration avec un cloud seafile/seadrive

Techniquement, le serveur est construit sur debian 9 stretch, avec Samba
4.5.x et éventuellement ZFSonLinux ou dcache. Les paquets sont
construits en respectant le standard Debian pour pouvoir être mis à jour
facilement, et donc suivre les évolutions des versions Debian.


Un nouveau projet
------------------

Bien que la plupart du code soit repris de SE3, il ne s'agit pas d'une
mise à jour, mais d'un projet parallèle. Cela n'empêche pas que tout
est  fait pour simplifier le passage de *Se3* vers *Se4* notamment à l'aide du paquet dédié `sambaedu-config. <https://github.com/SambaEdu/sambaedu-config>`__ qui s'installe sur le Se3.

Dans un premier temps toutes les pages de l'interface faisant doublon
avec les outils de la console AD GPO ne seront pas reprises : seules les
pages ``annuaire``, ``importation``, ``partages`` et ``parcs`` sont conservées.

Feuille de route
----------------

L'état d'avancement du projet SambaEdu est disponible dans la `partie dédiée de Github <https://github.com/orgs/SambaEdu/projects?query=is%3Aopen+sort%3Aname-asc>`__


Matériel et stockage
--------------------

Comme l'équipe Samba le préconise, le serveur AD et le serveur de fichiers sont séparés.

Solution basée sur la virtualisation
....................................

Deux types de serveurs sont donnés ci-dessous à titre d'exemple. Bien dimensionner son serveur est primordial si l'on veut mettre en place la virtualisation dans les meilleures conditions et ainsi bénéficier de performances optimales.

-  Serveur physique :

   -  serveur de type « collège » : 2 disques SATA 2-4 To en raid 1 + cache
      SSD avec ``Dcache``
   -  serveurs de type « lycée » : N > 4 disques SATA en ZFS raid10 + cache
      SSD, cluster iscsi ?

Proxmox 5.x est une excellente base de virtualisation libre, mais d'autres solutions comme Xen ou Vmware sont aussi possibles.
	  
-  Serveurs virtuels 

   -  vm « SE4-AD » avec le serveur AD, ``netlogon`` et ``sysvol``
   -  vm « SE4-FS » avec les partages de fichiers ``samba``, l'interface ``web``, ``dhcp``,
      ``ipxe``, et le serveur d'impression
   -  optionnel : vm « cloud » avec ``seafile`` et ``nginx``

   
Solution basée sur un serveur classique non virtualisé
........................................................   

Pour les petites structures type collège ne disposant pas d'un serveur permettant la mise en place de la virtualisation, Il sera possible migrer le SE3 en SE4FS alors que le S4AD sera lancé dans un conteneur LXC.

Modalités d'installation
------------------------

A partir d'un SE3 existant
..........................

La migration s'appuie pleinement sur le paquet `sambaedu-config. <https://github.com/SambaEdu/sambaedu-config>`__ 
Les deux options d'installation y sont décrites :

- Virtualiser SE4FS et SE4AD sur deux machines installées automatiquement `via un fichier preseed <https://github.com/SambaEdu/se4/blob/master/documentation/installation/gen-preseed-se4AD.rst#g%C3%A9n%C3%A9ration-dun-preseed-et-installation-automatique-dun-serveur-se4-ad>`__ - **solution recommandée**

- Installer SE4-AD dans un `container LXC <https://github.com/SambaEdu/se4/blob/master/documentation/installation/install-lxc-se4AD.rst#proc%C3%A9dure-dinstallation-automatique-dun-container-lxc-se4-ad>`__ sur le SE3 avant de le migrer en SE4-FS - **solution réservée aux petites structures**

Cas d'un nouvelle installation
..............................

Si vous n'aviez pas de serveur Sambaedu et que vous désirez réaliser une installation Sambaedu4, c'est parfaitement possible mais uniquement en mode virtualisé.

- La première machine à installer sera SE4AD (Debian Stretch de base). 32Go de stockage suffisent pour cette machine. Une fois la machine installée sous debian. Il suffira de récupérer le script d'installation SE4AD à cette adresse : https://raw.githubusercontent.com/SambaEdu/sambaedu-config/master/sources/var/www/diconf/install_se4ad_phase2.sh avant de le lancer
- Restera ensuite Se4-FS selon les mêmes modalités : installation Debian Stretch de base puis lancement du script d'installation SE4FS :  https://raw.githubusercontent.com/SambaEdu/sambaedu-config/master/sources/var/www/diconf/install_se4fs_phase2.sh

.. Note:: Il est prévu qu'une page de type dimaker soit développée afin d'automatiser ces installations.


Annexe : Documentations en rapport avec le développement
--------------------------------------------------------

-  `communication avec AD - API <documentation/developpement/API.md>`__
-  `Notes diverses <documentation/developpement/notes.md>`__
-  `Règles d'utilisations et structures des fichiers de
   conf <documentation/developpement/Fichiers_de_conf.md>`__
-  `Install\_proxmox - configuration matériel <https://github.com/SambaEdu/se3-docs/blob/master/se3-virtualisation/proxmox.md>`__
-  `Modèle de données manipulé par SambaEdu <documentation/developpement/Modele.md>`__
-  `Structure du paquet debian SE4 <documentation/developpement/Paquets%20Debian.md>`__
-  `Supprimer Mysql pour les paramètres <documentation/developpement/Virer_mysql.md>`__
-  `installation stretch - concepts (deprecated car géré par
   script) <documentation/developpement/install_stretch.md>`__
-  `migration ldap-->AD Principes <documentation/developpement/migration-ldap.md>`__
-  `Configuration Apache en mode fast\_cgi + suexec <documentation/developpement/apache.md>`__
