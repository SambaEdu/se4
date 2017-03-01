# Installation sur Stretch
On part d'une machine à jour avec se3master, se3-logonpy et se3-domain

ce fichier décrit les chose à faire manuellement, à éliminer au fur et à mesure de la construction du paquet !

##dépendances

verifier les ldb* sur une nouvelle install

il faut activer winbind et libnss_winbind à la place de ldap (fait)

##résolution des noms
se3 doit être l'unique serveur dns configuré, il fera le forwarding

se3 doit résoudre l'ip réelle dans /etc/hosts

/etc/resolv.conf : 
```
domain sambaedu.maison
nameserver 127.0.0.1
```
surtout rien d'autre ! cela plante tout.

## init
on est en systemd : 

̀```systemctl stop slapd
   systemctl enable samba-ad-dc
   systemctl disable samba
   systemctl start samba-ad-dc
```
## modifs ultérieures depuis ldap
changer le port d'écoute de slapd, et lancer le service.

## Authentification
conf kerberos de base : `ln -sf /var/lib/samba/private/krb5.conf /etc/krb5.conf`
l'utilisateur "admin" est devenu "administrator"  (a changer ?) mdp admin du se3

interface se3 :
https://wiki.samba.org/index.php/Authenticating_Apache_against_Active_Directory
       AuthType Kerberos
       AuthName "Network Login"
       KrbMethodNegotiate On
       KrbMethodK5Passwd On
       KrbAuthRealms YOUR_REALM_NAME.TLD
       require valid-user
       Krb5KeyTab /etc/httpd/conf/httpd.keytab
       KrbLocalUserMapping On

apt-get install libapache2-mod-auth-kerb
