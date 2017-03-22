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

## samba-tool

www-se3 n'a pas les droits pour accéder à la base , il faut donc soit lui donner un ticket kerberos, soit passer les parametres d'auth de l'admin : 
```
samba-tool user list  -H ldap://sambaedu3.maison  -U $admincn --password=$adminpasswd
```
C'est pas terrible car le mot de passe est en clair dans ps ax... La méthode kerberos est de loin meilleure.
Il faut créer un utilisateur, créer son keytab, et le rendre accessible pour www-se3 (à détailler)

```
samba-tool user list  -H ldap://sambaedu3.maison  -k www-se3@SAMBAEDU.MAISON 
```

### interface se3

L'interface tourne avec www-se3, il faut donc lui configurer ldap : le problème c'est que le dossier /var/lib/samba/private/tls est privé...  il faut le mettre en 755 !

dans includes/config.inc.php.in : 
```
$ldap_login_attr = "cn";
```
## structure
On cherche à garder en gros la structure du ldap se3 :

### cn=users
contient les utilisateurs 
### ou=Groups
contient les groupes et les OU si besoin de gpo ( dans ce cas on met le groupe dans l'OU ) Imbrication possible
### ou=Rights
contient les groupes *_is_*  
### ou=Parcs 
contient les groupes de machines et les ou parcs ( 1 parc se3 = 1 ou contenant un groupe ) Imbrication possible !
### cn=computers
contient les machines
