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
ATTENTION il semblerait que ce ficiher soit modifié par une tâche cron, laquelle ?

Il est ensuite possible de faire des requètes ldap* de ce type : 
```
bindDN="CN=Administrator,CN=users,DC=sambaedu3,DC=maison"
baseDN="CN=users,DC=sambaedu3,DC=maison"
ldapsearch -xLLL -D $bindDN -w $bindPW -b $baseDN -H ldaps://sambaedu3.maison "(cn=*)"
```
A noter que l'adresse du serveur est directement le nom du domaine AD, pas celle du DC. 

### interface se3

L'interface tourne avec www-se3, il faut donc lui configurer ldap : le problème c'est que le dossier /var/lib/samba/private/tls est privé... Donc soit on copie le certificat dans /var/_remote_adm, soit on donne les droits à www-se3. 

On crée un ficiher /var/remote_adm/.ldaprc :
```
HOST sambaedu.maison
BASE DC=sambaedu3,DC=maison
TLS_REQCERT never
TLS_CACERTDIR ~/ 
TLS_CACERT ~/ca.pem
```
