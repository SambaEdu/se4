Passer tous les fichiers de conf de SambaEdu et des modules dans un format simple et facile à utiliser

# Structure

Tous les fichiers sont sous la forme `key="value"`, afin d'être lisibles simplement dans tous les langages.

L'arborescence est au standard Debian des fichiers de conf :
```
/etc/sambaedu/+------------se4.conf
         +se4.conf.d/+dhcp.conf
                     +ipxe.conf
                     +xxx.conf
                     ....
```
## bash
On peut directement evaluer les fichiers, à condition qu'il n'y ait pas d'espace autour du = !. Par sécurité, le mieux est d'avoir un script qui lise se3.conf, puis qui boucle sur se3.conf.d/*

```
eval $(sed "s|^\(.*\)\s*=\s*\(.*\)|config_\1=\2;\1=\2|" /etc/sambaedu/se4.conf*)
```
Doit faire l'affaire. Pour optimiser on pourrait ecrire une fonction `get_conf module1...` modulen afin de ne pas tout lire à chaque fois ?

## php
On utilise parse_ini_file()

# ecriture

Différents cas d'utilisation sont possibles : 

## debconf
pour tous les parametrages interactifs ou automatisés lors de l'installation
## Ansible
Configuration à distance des serveurs : on utilise le module Ansible debconf
## page setup.php
conf manuelle  post-installation par l'utilisateur
## pages php diverses
configuration de parametres divers via l'interface


# Impact sur le code actuel 

## scripts shell

Il existe déjà des fonctions qui lisent et ecrivent les fichiers de conf dans /etc/se3. Il faut juste les adapter pour la nouvelle arborescence. 

De façon transitoire pour les paquets existants (3.0.x) on conserve la base sql, que l'on met à jour depuis /etc/se3. En revanche pour se4 on vire la base. 

## php et autres 

Il faut virer tout le code sql et aller chercher la conf dans /etc/se3
de façon transitoire on peut garder la base sql, et donc n'avoir aucun changement à faire.
la lecture de la conf est faite dans l'entête des pages, il suffit donc de modifier cette page d'includes 





                     
