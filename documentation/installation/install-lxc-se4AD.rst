===============================================================
Procédure d'installation automatique d'un container LXC SE4-AD 
===============================================================

.. sectnum::
.. contents:: Table des matières


Introduction
============

Ce document a pour but de décrire précisément la procédure d'installation automatique d'un container ``LXC`` hébergeant ``SE4 Active Directory (Se4-AD)``.

L’installation se déroule en deux temps :

* Installation du container ``LXC`` avec export des données importantes de la machine ``Se3``, à savoir tout ce qui concerne l'annuaire et samba
* La finalisation de la configuration du container ``LXC`` avec réintégration des données précédentes et peuplement de l'``AD (Active Directory)`` 

Cette documentation s’attardera plus précisément sur la première partie. La seconde partie est traitée à part dans une autre documentation_ car elle n'est pas propre à l'utilisation de ``LXC``.
 

.. _documentation : install-se4AD.rst


Déroulement de l'installation de ``LXC``
========================================

À partir du moment où le paquet ``sambaedu-config`` est installé, le script d'installation du container ``LXC`` se trouve dans le dossier ``/usr/share/se3/sbin``.

La commande à lancer est donc la suivante :

.. Code::

 /usr/share/se3/sbin/install_se4lxc.sh


Accueil
-------

.. figure:: images/lxc_title.png


Après le message de bienvenue, un court résumé des paramètres réseau actuel détectés est affiché. 


.. figure:: images/lxc_reseau_confirm.png


Ces valeurs serviront de base pour la configuration de la machine ``LXC`` par la suite. Si elles ne sont pas correctes, il suffit de répondre ``non``. Dans ce cas il sera possible de préciser les bonnes valeurs une par une à l'aide de boîtes de dialogue.



Installation de ``LXC`` et configuration de la carte réseau en mode pont
------------------------------------------------------------------------

Après le message de bienvenue et une éventuelle modification de paramètres, l'installation de ``LXC`` s'effectue.

**Remarque :** ``LXC`` n'est pas installé par défaut sur les ``Se3 Wheezy``. Par ailleurs seule la version 1.0 est disponible sur les dépôts ``Debian Wheezy``. La version 1.1 étant plus aboutie, elle sera récupérée sur les dépôts ``Debian Backport`` ou le dépôt ``SambaEdu`` lui-même.


.. figure:: images/lxc_package.png


Une demande de confirmation est demandée avant de poursuivre le téléchargement. Elle permet de vérifier que tout va bien.


.. figure:: images/lxc_conf_bridge.png


Configuration de la carte réseau de la machine hôte en mode **pont**. Ceci est en effet nécessaire pour que votre ``Se4-AD`` puisse utiliser la même carte réseau que son hôte et ainsi pouvoir se connecter au réseau local et donc à internet.

**Note :**  Pour les utilisateur de ``VMWARE`` sous ``Linux``, il sera nécessaire de modifier les droits de ``/dev/vmnet0`` (à l'aide de la commande ``chmod a+rw /dev/vmnet0``) de la machine hote. Cette opération permet à ``VMWARE`` de faire fonctionner la carte réseau en mode "promiscous". Ce mode est nécessaire au bon fonctionnement du pont.


Paramétrage du container ``SE4``
--------------------------------

Viennent ensuite quelques questions sur la configuration du container.

Choisir une ``IP`` et un nom
............................

On commence par saisir l'``IP``. Si le container est dans le même subnet que le serveur principal, il suffit de compléter le début de l'``IP`` suggérée.

**Attention :** un container est considéré comme une autre machine, avec une adresse ``IP`` indépendante, donc ce ne sera pas la même adresse ``IP`` que le ``Se3``.

.. figure:: images/lxc_ip_containe.png

De même, on donne un nom au container. Le choix par défaut semble correct :).


.. figure:: images/lxc_nom_container.png


Choix du nom de domaine
.......................

**Attention :** Un point tout particulier est à apporter au domaine ``AD``. En mode active directory il correspond au domaine ``DNS`` sur lequel Le serveur ``AD`` sera serveur de nom. Par défaut le nom de domaine ``AD`` proposé sera le domaine ``DNS`` actuel du ``Se3``. Vous pouvez utiliser ce choix ou le modifier à votre convenance. Le fait que toutes les machines clientes seront sur cette même zone ``DNS`` distribuée par le ``DHCP` est également à prendre en compte. Il faut donc bien réfléchir à ce choix si l'on veut obtenir quelque chose de cohérent au final.

Ce nom de domaine devra être composé d'au moins deux parties séparées par un point. Dans notre exemple, il y en a trois.
 
* La première partie correspond au domaine ``samba``. Appelé également ``workgroup``, cet élément **ne doit absolument pas dépasser 15 caractères**. À noter également qu'il n'est pas souhaitable de reprendre celui de ``Se3``, à savoir l'habituel "sambaedu3" afin d'éviter tout conflit.

* La ou les parties suivantes correspondent à ce que l'on nomme le suffixe ``DNS``.


.. figure:: images/lxc_nom_domaine.png


Résumé des paramètres avant lancement de l'installation
.......................................................

Un récapitulatif de l'ensemble des paramètres saisis précédemment est affiché

.. figure:: images/lxc_recap_config.png

Si tout paraît correct, on peut confirmer afin de poursuivre l'installation. Dans le cas contraire, il sera proposé de corriger chaque paramètre.


Installation du container
-------------------------

Durant cette phase, ``lxc-create`` est utilisé afin de mettre en place un container sous ``Debian Stretch``. Cela nécessite le téléchargement d'un grand nombre de paquets, cela peut durer quelques minutes. Patience !

.. figure:: images/lxc_install_container.png
   :scale: 60 %

Une fois installé, le container est configuré avec les éléments saisis précédemment

.. figure:: images/lxc_install_container_postconf.png
   :scale: 50 %
  
Les éléments suivants sont exportés et placés dans une archive ``tgz`` sur le container :

* La configuration ``ldap`` ``slapd.conf``
* un export au format ``ldif`` complet de l'annuaire
* un export de certains paramètres de la base de données
* Les fichiers de base de données ``samba``

**Attention :** Durant l'opération le service ``samba`` est coupé afin d'extraire les fichier ``TDB``. Il est par ailleurs conseillé qu'il soit coupé lors de l'alimentation de l'active directory.


Fin de l'installation
--------------------- 

À ce stade un message de fin s'affiche


.. figure:: images/lxc_fini.png


le container a, par ailleurs, été lancé en arrière plan. La commande pour s'y connecter ainsi que le mot de passe ``root`` provisoire sont rappelés.


.. figure:: images/lxc_fini1.png


Connexion au container
======================

Lorsque le container est déjà actif, il suffit de se connecter dessus via la commande ``lxc-console``. Dans notre cas la commande complète sera la suivante :

::

 lxc-console -n se4ad 

.. figure:: images/lxc_cnx_container.png

Nous voilà sur notre container Stretch... Une fois connecté une nouvelle phase d'installation se déroulera.
On pourra se reporter à cette documentation_

.. _documentation: install-se4AD.rst


Annexe : Quelques commandes ``LXC`` utiles
------------------------------------------

* lxc-start : lancement d'un container 

 * En avant plan : ``lxc-start -n se4ad`` 

 * En arrière plan : : ``lxc-start -d -n se4ad`` 


* lxc-ls : lister les containers avec leur état. L'option -f permet d'avoir l'état en cours
 
::
 
    # lxc-ls -f
    NAME   STATE    IPV4            IPV6                                AUTOSTART  
    -----------------------------------------------------------------------------
    se4ad  RUNNING  10.127.164.214  2a01:cb06:267:e900:2ff:aaff:fe00:1  NO         

* lxc-console : connexion à un container

* lxc-stop : arrêter le container 

* lxc-destroy : Supprimer un container


