page destinée à lister les fonctions se4, leur correspondance se3 ou ldap et leur implémentation
# Interface de communication AD
Afin de simplifier la programmation, on évite d'utiliser directement ldap ou ldb. 
## fonctions de base
On utilise l'outil CLI samba-tool, et on crée les fonctions php correspondant aux commandes samba-tool

## fonctions spécifiques se4 : 

samba-tool est un script python qui se base sur python-samba, qui fournit toutes l'API samba. Il est donc très simple d'ajouter des nouvelles commandes utilisables dans les différents langages. C'est ici qu'il faut implémenter les fonctions php actuelles.

- si c'est suffisamment générique, on soumet les chagements upstream

- si c'est spécifique se3, on crée un nouvel outil se4-tool avec les commandes supplémentaires, avec une lib étandant python-samba. 

##état du code php
* nombre de ldap_search : 21
* nombre de ldap_modify : 11
* nombre de ldap_delete : 3
* nombre de ldap_add : 5
* nombre de ldap_list : 13
* nombre de ldap_read : 11
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















