# Connexion sur le serveur ldap
Samba4 permet plusieurs modes d'accès à l'annuaire AD : 

- ldaps avec mot de passe,
- ldap kerberos
- ldb kerberos
- samba-tool

## élévation des privilèges
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
C'est pas terrible car le mot de passe est en clair dans ps ax... La méthode kerberos est de loin meilleure.
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
### Stratégie d'authentification possible :

1. on configure apache pour faire de l'auth SSO si il y arrive, sinon il autorise par défaut, on tombe alors sur la page.
1. on teste $_SERVER['REMOTE_USER'] : si ok, alors on ouvre direct la session php
1. on teste la validité du ticket : si invalide on redemande l'auth.
1. si pas de ticket on affiche le dialogue d'auth.
1. on fait un ldap_bind () pour vérifier.
1. on fait un shell_exec (kinit $user@SAMBAEDU ... et on sauve le chemin du ticket dans le cookie de session.

Dans les pages on fait :

- $path_ticket = get_ticket_from_session (.....
- putenv("KRB5CCNAME=$path_ticket);
- ldap_sasl_bind($ds, NULL, NULL,  GSSAPI);
- shell_exec ( samba-tool -k yes....);  
 
## compatibilité avec l'existant 
Le serveur ldap samba4 n'accepte de faire de bind simple (option -x) que en SSL. Il faut donc configurer correctement `/etc/ldap/ldap.conf` :
```
HOST 192.168.200.3
BASE DC=sambaedu3,DC=maison
TLS_REQCERT never
TLS_CACERTDIR /var/lib/samba/private/tls
TLS_CACERT /var/lib/samba/private/tls/ca.pem
```
**ATTENTION** il semblerait que ce ficiher soit modifié par la page setup ?

Il est ensuite possible de faire des requètes ldap de ce type : 
```
bindDN="CN=Administrator,CN=users,DC=sambaedu3,DC=maison"
baseDN="CN=users,DC=sambaedu3,DC=maison"
ldapsearch -xLLL -D $bindDN -w $bindPW -b $baseDN -H ldaps://sambaedu3.maison "(cn=*)"
```
*A noter que l'adresse du serveur est directement le nom du domaine AD, pas celle du DC.* 

On peut peut-être aussi faire le bind ldap admin en mode kerberos (voir plus bas). Utiliser ldap_bind_sasl ? 

IL faut ajouter la lib sasl : `apt-get install libsasl2-modules-gssapi-mit` Le bind se fait alors direct sans passwd : 
``` 
ldapsearch -LLL -Y gssapi -H ldap://sambaedu3.maison "(cn=*)"
```
Attention, l'URI est ldap et non ldaps, GSSAPI fait le cryptage dans ce cas-là. Cela fonctionne aussi sans mettre d'URI !
Il faut avoir un keytab valide pour l'utilisateur qui lance la commande...


**Remarque** Sur le serveur AD lui même, il est possible de consulter / modifier directement les fichiers ldb avec les commandes ldbsearch, ldbmodify, ldbadd, etc....
Exemple :
```
ldbsearch -H /var/lib/samba/private/sam.ldb -b OU=Groups,$baseDN "(objectClass=group)" dn
```
Permet de récupérer la liste des groupes un emplacement donné, ici OU=Groups

### interface se3 existante

L'interface tourne avec www-se3, il faut donc lui configurer ldap : le problème c'est que le dossier /var/lib/samba/private/tls est privé...  il faut le mettre en 755 !

dans includes/config.inc.php.in : 
```
$ldap_login_attr = "cn";
```
### Bind ldap en php avec kerberos

il faut utiliser `ldap_sasl_bind()` : il faut qu'un keytab permanent ait été configuré pour www-se3 

``` 
$ldap_serveur="sambaedu3.maison";
$ldap_port="389";
$ds = @ldap_connect($ldap_server, $ldap_port);
if ($ds) {
    ldap_set_option($ds, LDAP_OPT_PROTOCOL_VERSION, 3);
    $ret = ldap_sasl_bind($ds, null, null, 'GSSAPI');
}
```

## structure
On cherche à garder en gros la structure du ldap se3. On fait en sorte d'utiliser les attributs standard AD, de façon à pouvoir tout administrer simplement depuis la console RSAT également. Bien que l'on puisse utiliser les atributs POSIX, il est préférable de ne pas le faire car cela pose des soucis pour y accéder depuis ADUC (manip compliquée)

Pour les clients Linux, les attrbuts POSIX ne sont pas utiles car l'ouverture de session se fait en mode AD, avec winbind sur le client qui fera le mappage AD/Posix à la volée.

### cn=users
contient les utilisateurs

- uid -> cn
- cn -> displayName : Prénom Nom
- sn : nom
- givenName : prénom
- gecos (nom,premon,naissance,sexe) -> physicaldeliveryofficename (naissance,sexe)
- employeeNumber -> title

### ou=Groups
contient les groupes et les OU si besoin de gpo ( dans ce cas on met le groupe dans l'OU ) Imbrication possible. C'est ce qui permet l'héritage des droits et GPO.

- objectclass : group
- memberUid -> member

lorsque on crée un groupe (classe, equipe ) on crée une OU correspondant et on les met dedans
```
ou=groups-+ou=TS1-+-cn=classe_TS1
          |       +-cn=equipe_TS1
          +ou=Profs-cn=Profs
          +ou=Eleves-cn=eleves
          +ou=Administratifs-cn=Administratifs
```



### ou=Rights
contient les groupes *_is_*  aucun changement
### ou=Parcs 
contient les groupes de machines et les OU parcs ( 1 parc se3 = 1 ou contenant un groupe ) Imbrication possible !
ou=Parcs qui contient les `ou=nom_parc` qui contient `cn=nom_parc`.

* Les machines sont membres des groupes `cn=nom_parc,ou=parcs`
* les GPO sont appliquées sur `ou=nom_parc`

### cn=computers
contient les machines. Il est probablement possible d'avoir un seul enregistrement pour tous les OS dans le cas d'une machine en multiboot. Il faut pour cela récupérer le keytab de la première instance mise au domaine et le recopier sur toutes les autres. 
L'enregistrement de la machine contient le type d'OS, il faudrait vérifier si il est mis à jour à la connexion.

#### Configuration réseau

Afin de pouvoir faire du WakeOnLan, et éventuellemnt pour les réservations dhcp, on stocke l'adresse ip et mac. Ces enregistrements sont facultatifs, ne pas les renseigner ne bloquera pas le fonctionnement du domaine

IP : ipHostNumber
MAC : networkAddress


Pour les afficher dans la console il faut cliquer sur fonctionnalités avancées, et après on a accès à l'éditeur d'attributs dans l'enregistrement de la machine.

**note**
Le nom affiché de la machine est DisplayName. En cas de renommage, c'est lui seul qui change. Cela veut dire qu'il n'est pas nécessaire de renommer réellement les machines, il suffit de le faire sur AD. 

### ou=trash 
aucun changement


## attributs

Le Nom Prénom,le sexe, la date de naissance étaient stockés dans "geCos". On prend un chanp qui ne sert à rien  "physicaldeliveryofficename"

# Client linux

Travail en cours... Prévoir la récupération du keytab pour enregistrement unique.


