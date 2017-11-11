# Connexion sur le serveur ldap
Samba4 permet plusieurs modes d'accès à l'annuaire AD : 

- ldaps avec mot de passe,
- ldap kerberos
- ldb kerberos
- samba-tool

## compatibilité avec l'existant 
Le serveur ldap samba4 n'accepte de faire de bind simple (option -x) que en SSL. Il faut donc configurer correctement `/etc/ldap/ldap.conf` :
```
HOST 192.168.122.95
BASE DC=sambaedu3,DC=maison
TLS_REQCERT never
TLS_CACERTDIR /var/lib/samba/private/tls
TLS_CACERT /var/lib/samba/private/tls/ca.pem
```
**ATTENTION il semblerait que ce ficiher soit modifié par la page setup ?

Il est ensuite possible de faire des requètes ldap* de ce type : 
```
bindDN="CN=Administrator,CN=users,DC=sambaedu3,DC=maison"
baseDN="CN=users,DC=sambaedu3,DC=maison"
ldapsearch -xLLL -D $bindDN -w $bindPW -b $baseDN -H ldaps://sambaedu3.maison "(cn=*)"
```
A noter que l'adresse du serveur est directement le nom du domaine AD, pas celle du DC. 

On peut peut-être aussi faire le bind ldap admin en mode kerberos (voir plus bas). Utiliser ldap_bind_sasl ? 

IL faut ajouter la lib sasl : `apt-get install libsasl2-modules-gssapi-mit` Le bind se fait alors direct sans passwd : 
``` 
ldapsearch -LLL   -Y GSSAPI -H ldap://sambaedu3.maison "(cn=*)"
```
Attention, l'URI est ldap et non ldaps, GSSAPI fait le cryptage dans ce cas-là. Cela fonctionne aussi sans mettre d'URI !
Il faut avoir un keytab valide pour l'utilisateur qui lance la commande...

## samba-tool

www-se3 n'a pas les droits pour accéder à la base , il faut donc soit lui donner un ticket kerberos, soit passer les parametres d'auth de l'admin : 
```
samba-tool user list  -H ldap://sambaedu3.maison  -U $admincn --password=$adminpasswd
```
C'est pas terrible car le mot de passe est en clair dans ps ax... La méthode kerberos est de loin meilleure.
Il faut créer un utilisateur, créer son keytab, et le rendre accessible pour www-se3 (à détailler)

```
samba-tool user list -H ldap://sambaedu3.maison  -k www-se3@SAMBAEDU.MAISON 
```

### interface se3

L'interface tourne avec www-se3, il faut donc lui configurer ldap : le problème c'est que le dossier /var/lib/samba/private/tls est privé...  il faut le mettre en 755 !

dans includes/config.inc.php.in : 
```
$ldap_login_attr = "cn";
```
### Bind ldap en php

il faut utiliser ldap_sasl_bind : il faut qu'un keytab permanent ait été configuré pour www-se3 

``` 
$ds = @ldap_connect($ldap_server, $ldap_port);
if ($ds) {
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


### ou=Rights
contient les groupes *_is_*  
### ou=Parcs 
contient les groupes de machines et les OU parcs ( 1 parc se3 = 1 ou contenant un groupe ) Imbrication possible !
### cn=computers
contient les machines. Il est probablement possible d'avoir un seul enregistrement pour tous les OS dans le cas d'une machine en multiboot. Il faut pour cela récupérer le keytab de la première instance mise au domaine et le recopier sur toutes les autres. L'enregistrement de la machine contient le type d'OS, il faudrait vérifier si il est mis à jour à la connexion.
### ou=trash 
aucun changement

**note**
Le nom affiché de la machine est DisplayName. En cas de renommage, c'est lui seul qui change. Cela veut dire qu'il n'est pas nécessaire de renommer réellement les machines, il suffit de le faire sur AD. 
Le Productkey du poste est enregistré dans AD. Ceci peut permettre de restaurer les licences après réinstallation ou clonage.

## attributs

Le Nom Prénom,le sexe, la date de naissance étaient stockés dans "geCos". 

# Client linux

Travail en cours... Prévoir la récupération du keytab pour enregistrement unique.


