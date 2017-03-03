page destinée à lister les fonctions se4, leur correspondance se3 ou ldap et leur implémentation
# Interface de communication AD
Afin de simplifier la programmation, on évite d'utiliser directement ldap ou ldb. 

- Il existe une classe https://github.com/Adldap2/Adldap2 Mais est-ce une bonne idée ? Le problème c'est que on aura des outils différents pour le php et pour les scripts shell. l'API est relativement complète et bien documentée, il manque les GPO et des méthodes pour les OU ?

- L'autre solution est d'utiliser samba-tool et de l'étendre les classes python pour couvrir toutes les operations qui sont nécessaires.  On l'appelle de façon unifiée quelque soit le langage. L'API est complète (normal !), en revanche les OU ne sont pas gérées par samba-tool (j'ai un patch).  

Dans le premier cas, on aura assez peu d'abstraction sur la structure ldap, et donc la manipulation des objets se fera dans les scripts comme actuellement (avec quand même plus d'abstraction). Dans le second cas, la manipulation des objets se fait au niveau des classes python, on ajoute toutes les méthodes nécessaires au se3 à ce niveau et donc les scripts finaux sont simplifiés quelque soit le langage.  

En gros la classe php Adldap2 est fonctionnellement équivalente à la classe python Samba. 

# solution "adldap2"
## php 
adaptation directe du code existant, en remplaçant intelligemment les ldap\*. Pas mal de simplifications, bonne documentation de la classe.
## autres langages
On utilise samba-tool
# solution "python samba"
## fonctions de base : classe php
On utilise l'outil CLI samba-tool, et on crée les fonctions php correspondant aux commandes samba-tool : samba-tool.inc.php

Enormément de code et de fonctions disparaissent purement et simplement car directement implémentés dans l'API samba ! Les décomptes ci dessous ne sont pas forcément très significatifs.

## fonctions spécifiques se4 : 

samba-tool est un script python qui se base sur python-samba, qui fournit toutes l'API samba. Il est donc très simple d'ajouter des nouvelles commandes utilisables dans les différents langages. C'est ici qu'il faut implémenter les fonctions php actuelles.

- si c'est suffisamment générique, on soumet les changements upstream

- si c'est spécifique se3, on crée un nouvel outil se4-samba-tool avec les commandes supplémentaires, avec une lib étendant python-samba. 

on cree la lib php se4-samba-tool.php correspondante

# fonctions se3

## état du code php
Il reste encore des fonctions à sortir des pages et à mettre dans les includes.

* nombre de ldap_search : 21
* nombre de ldap_modify : 11
* nombre de ldap_delete : 3
* nombre de ldap_add : 5
* nombre de ldap_list : 13
* nombre de ldap_read : 11

## état des scripts shell
Pas mal de simplifications à prévoir avec samba-tool

* nombre de ldapsearch : 251
* nombre de ldap_modify : 37
* nombre de ldapdel : 11
* nombre de ldapadd : 11

## état des scripts perl
Enormément de doublons avec le php ! on devrait pouvoir tout éliminer

* nombre de ldap->search : 48
* nombre de ldap->modify : 26
* nombre de ldap->delete : 7
* nombre de ldap->add : 4

## etat de logonpy
Il faut simplement utiliser les classes samba au lieu de ldap. 

En théorie logonpy n'est plus nécessaire. Les GPO sont gérées nativement. Mais il faut mettre les fichiers dans SYSVOL, donc il faudra conserver Se3GPO qui oit permettre de générer les GPO côté serveur. En revanche il manque la gestion des fichiers templates .admx ( mais on peut passer par la console MS)

# gestion des utilisateurs

## functions.inc.php
function user_valid_passwd ( $login, $password )

function user_search_dn ( $login ,$dn ) 

function ldap_get_right_search ($type,$search_filter,$ldap)

function ldap_get_right($type,$login)

function people_get_variables($uid, $mode)

## ldap.inc.php
function people_get_variables($uid, $mode)

function search_people($filter)

function search_uids($filter)

function search_groups($filter)

function search_people_groups($uids, $filter, $order)

unction search_computers($filter)

function group_type($groupe)

function search_samba($computername)

function search_parcs($machine)

function gof_members($gof, $branch, $extract)

function liste_parc($parc)

function filter_parcs($filter)

function tstclass($prof, $eleve)

function verifGroup($login)

function userChangedPwd($uid, $userpwd)

function userDesactive($uid, $act)

function are_you_in_group($login, $group)

function search_description_parc($parc)

unction modif_description_parc($parc, $entree)

function get_infos_admin_ldap2()

function affiche_all_groups($align,$afftype)

##crob_ldap_functions.php
function test_creation_trash()

function add_entry ($entree, $branche, $attributs)

function del_entry ($entree, $branche)

function modify_entry ($entree, $branche, $attributs)

function modify_attribut ($entree, $branche, $attributs, $mode)

function creer_uid($nom,$prenom)

function verif_employeeNumber($employeeNumber)

function verif_nom_prenom_sans_employeeNumber($nom,$prenom)

function get_tab_attribut($branche, $filtre, $attribut)

function get_first_free_uidNumber()

function get_first_free_gidNumber($start=NULL)

function add_user($uid,$nom,$prenom,$sexe,$naissance,$password,$employeeNumber)

function verif_et_corrige_gecos($uid,$nom,$prenom,$naissance,$sexe)

function verif_et_corrige_givenname($uid,$prenom)

function verif_et_corrige_pseudo($uid,$nom,$prenom)

function search_people_trash ($filter)

function recup_from_trash($uid)















