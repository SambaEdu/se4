================================================================
Installation et configuration de la machine SE4-AD sur Stretch 
================================================================

.. sectnum::
.. contents:: Table des matières

Introduction
============

La machine pourra être soit une machine virtuelle ou bien un container LXC, au choix. L'installation automatique décrite ici prend en compte les deux cas de figure.

* Machine virtuelle : A la suite de l'installation de debian Stretch, le script d'installation devra être  téléchargé puis lancé afin de paramétrer se4-AD


* Machine LXC : Elle est installée depuis le serveur de fichiers Se3 qui se chargera de pousser tous les fichiers configuration dessus. Dans ce cas tout sera automatique.

* Avantages :
 
 * **Léger et facile à déployer** On peut monter une machine stretch tout en étant sur une machine se3 wheezy pour tester l'annuaire.
 
 * Dans un cas comme dans l'autre, on conserve une machine fonctionnelle durant toute la phase de migration et on s'assure de la compatibilité de l'annuaire.


.. Note :: Au 01/03/2018 Seul le mode d'installation LXC est supportée en mode automatique. L'installation automatique par preseed sur machine Virtuelle Proxmox ou autre est en cours  de développement.


Déroulement de l'installation
=============================

A l'installation de la machine virtuelle ou du container, le script d'installation a été poussé sur la machine dans /root. Il se lance immédiatement au login root à l'aide d'un .profile modifié pour ce faire.



Accueil
-------

.. figure:: images/se4ad_title.png



Après le message de bienvenue, La liste de choix s'affiche. 


.. figure:: images/se4ad_type_action.png

Quelques précisions sur chacune des options 

#. Installation classique

#. Téléchargement des paquets uniquement

#. Configuration du réseau
 