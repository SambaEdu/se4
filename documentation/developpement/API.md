page destinée à lister les fonctions se4, leur correspondance se3 ou ldap et leur implémentation
# Interface de communication AD
Afin de simplifier la programmation, on évite d'utiliser directement ldap ou ldb. 

- Il existe une classe php https://github.com/Adldap2/Adldap2 Mais est-ce une bonne idée ? Le problème c'est que on aura des outils différents pour le php et pour les scripts shell. l'API est relativement complète, simple et bien documentée, il manque les GPO et des méthodes pour les OU ?

- L'autre solution est d'utiliser samba-tool et l'api python samba et de l'étendre les classes  pour couvrir toutes les operations qui sont nécessaires.  On l'appelle de façon unifiée quelque soit le langage. L'API est complète (normal !), en revanche les OU ne sont pas gérées par samba-tool (j'ai un patch).  

Dans le premier cas, on aura assez peu d'abstraction sur la structure ldap, et donc la manipulation des objets se fera dans les scripts comme actuellement (avec quand même beaucoup plus d'abstraction). Dans le second cas, la manipulation des objets se fait au niveau des classes python, on ajoute toutes les méthodes nécessaires au se3 à ce niveau et donc les scripts finaux sont simplifiés quelque soit le langage.  

En gros dans le premier cas on part sur une solution 100% php, dans le second on s'ouvre à tous les langages. 

La question de l'authentification et de sa persistence se pose : dans le premier cas, c'est simple et propre (mais php uniquement !). Dans le second il faut le faire dans chaque langage, samba-tool permet soit une auth ldap, soit par ticket kerberos, il faut le gérer (soit c'est l'utilisateur authentifié, soit c'est www-se3).
# PHP
## solution "adldap2"

adaptation directe du code existant, en remplaçant intelligemment les ldap\*. Pas mal de simplifications, bonne documentation de la classe

## ldap_*

on modifie l'existant... cracra mais simple.

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
## authentification 
### élévation des privilèges
On crée un utilisateur www-se3, administrateur du domaine avec un password aléatoire. Ce compte permettra d'effectuer toutes les opérations ldap, samba-tool et rpc directement avec les droits admin, sans avoir besoin de sudo

on exporte une clé avec la commande : 
```
samba-tool user create www-se3 --description="Utilisateur admin de l'interface web" --random-password
samba-tool user setexpiry www-se3 --noexpiry
samba-tool group addmembers "Domain Admins" www-se3
samba-tool domain exportkeytab --principal=www-se3@SAMBAEDU3.MAISON /var/remote_adm/www-se3.keytab
chown www-se3 /var/remote_adm/www-se3.keytab
chmod 600 /var/remote_adm/www-se3.keytab
```
si cette clé est accessible à www-se3, le code php ou les scripts peuvent générer un ticket pour l'utilisateur www-se3@SAMBAEDU3.MAISON avec kinit sans mot de passe, et donc faire les opérations ent tant qu'admin du domaine avec samba-tool.

```
su www-se3
kinit -k -t /var/remote_adm/www-se3.keytab www-se3@SAMBAEDU3.MAISON
```
Ces commandes sont à lancer en cron toutes les heures pour renouveler le ticket.

### auth pour samba-tool

L'outil `samba-tool` peut être utilisé pour administrer à distance le domaine en ajoutant en fin de commande -H ldap://se3.sambaedu3.maison. Ne pas mettre l'IP d'un serveur !

L'authentification peut se faire de façon traditionnelle pour tous les utilisateurs en ajoutant en fin de commande `-U <domain username>`

```
samba-tool user list -U administrator -H ldap://se3.sambaedu3.maison
Password for [EXAMPLE\Administrator]:
administrator
krbtgt
Guest
```
Ou sur base du ticket Kerberos en ajoutant en fin de commande -k yes pour un utilisateur du domaine correctement authentifié
```
su www-se3
samba-tool user list -k yes -H ldap://se3.sambaedu3.maison
administrator
krbtgt
Guest
```

Ou sur base du ticket Kerberos en ajoutant en fin de commande -k yes pour un utilisateur quelconque ayant demandé un ticket avec //kinit// pour le compte d'un utilisateur du domaine

```
localuser@ubnwks01:~$ kinit administrator@EXAMPLE.COM
Password for administrator@EXAMPLE.COM: 
localuser@ubnwks01:~$ klist
Ticket cache: FILE:/tmp/krb5cc_1000
Default principal: administrator@EXAMPLE.COM

Valid starting       Expires              Service principal
10/31/2014 15:41:37  11/01/2014 01:41:37  krbtgt/EXAMPLE.COM@EXAMPLE.COM
        renew until 11/01/2014 15:41:31
localuser@ubnwks01:~$ samba-tool user list -k yes -H ldap://ubndc01.example.com
administrator
krbtgt
Guest
localuser@ubnwks01:~$ kdestroy
```

## Auth ldap 
idem avec avec www-se3 et kerberos configuré
```
su www-se3
kinit -k -t /var/remote_adm/www-se3.keytab www-se3@SAMBAEDU3.MAISON
ldapsearch -LLL -Y gssapi -H ldap://se3.sambaedu3.maison "(cn=*)"
```
On peut ne pas donner le nom du serveur dans l'URL et mettre juste le domaine.


## Roles et droits (auth sur l'interface)

Si on donne des droits restreints à certains groupes, et que l'on fait le bind des utilisateurs, alors on aura les droits correspondants sans devoir gérer cela au niveau du code php. *_A détailler_*

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















