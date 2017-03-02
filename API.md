page destinée à lister les fonctions se4, leur correspondance se3 ou ldap et leur implémentation
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















