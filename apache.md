# conf apache en mode fast_cgi + suexec

Cette config permet de faire tourner l'interface se3 dans un virtualhost apache standard, sous l'utilisateur www-se3. 
L'avantage est de permettre la mise à jour d'apache debian car il n'y a aucune conf spécifique. 

Idélement cette modification devrait être faite en Wheezy, afin de permettre la mises à jour ultérieure (TODO)

## Historique

je mets en vrac les manips que j'ai fait sur ma vm pour passer de apache2se à une config fastcgi :

Il y a probablement des trucs inutiles vu que j'ai cherché un peu, mais au final cela fonctionne.

```
  374  apt-get install php5-cgi libapache2-mod-fcgid apache2-suexec apache2-suexec-custom
  375  nano /etc/apache2/mods-enabled/fcgid.conf 
  376  nano /etc/apache2/mods-enabled/php5.conf 
  381  nano /etc/apache2/suexec/www-data 
  382  cp /etc/apache2/suexec/www-data /etc/apache2/suexec/www-se3
  383  nano /etc/apache2/suexec/www-se3
  384  mkdir /var/www/se3/cgi-bin
  386  mkdir /var/www/se3/cgi-bin/php5-default
  387  nano /var/www/se3/cgi-bin/php5-default/php-fcgi-wrapper
  388  nano /etc/apache2/sites-enabled/se3.conf 
  389  nano /usr/lib/cgi-binse/gep.cgi 
  390  nano /usr/bin/php5-cgi 
  391  nano /etc/php5/apache2/php.ini 
  393  nano /etc/apache2/suexec/www-se3
  394  nano /etc/apache2/ports.conf -> ajouter le port 909
  395  nano /etc/apache2/envvars 
  396  a2enmod suexec fcgid
  398  service apache2 restart
  399  nano /etc/apache2/mods-enabled/php5.conf 
  400  nano /etc/apache2/mods-enabled/fcgid.conf 
  401  service apache2 restart
  411  nano /etc/apache2/suexec/www-se3
  412  service apache2 restart
  413  tail -f /var/log/apache2/suexec.log 
  414  ls -l /var/www/se3
  415  chown -R www-se3:www-se3 /var/www/se3/cgi-bin/
  416  tail -f /var/log/apache2/suexec.log 
  417  chmod u+x /var/www/se3/cgi-bin/php5-default/php-fcgi-wrapper 
  418  tail -f /var/log/apache2/suexec.log 
  419  tail -f /var/log/apache2/errorse.log 
  425  chmod 750 /var/www/se3/includes/config.inc.php
  428  diff -u /etc/php5/apache2/php.ini /etc/php5/cgi/php.ini 
  429  nano /etc/php5/cgi/php.ini 
  473  nano /var/www/se3/cgi-bin/php5-default/php-fcgi-wrapper
```
## Fichiers de conf 
On définit que php sera lancé en mode cgi : 
`/etc/apache2/mods-available/fcgid.conf`
```
IfModule mod_fcgid.c>
  FcgidConnectTimeout 20
  FCGIWrapper /usr/bin/php5-cgi .php
  <IfModule mod_mime.c>
    AddHandler fcgid-script .fcgi
  </IfModule>
</IfModule>
```
Conf spécifique du module php pour se3 : Il n'y a besoin de rien de particulier, il me semble...

`/var/www/se3/cgi-bin/php5-default/php-fcgi-wrapper` :
```
#!/bin/sh
# Wrapper for PHP-fcgi
# This wrapper can be used to define settings before launching the PHP-fcgi binary.
# Define the path to php.ini. This defaults to /etc/phpX/cgi.

#PHP_INI_SCAN_DIR=/var/www/se3
#export PHP_INI_SCAN_DIR

#export PHPRC=/home/user/domain/conf

# Define the number of PHP child processes that will be launched.
# This is low to control memory usage on a server that might launch
# these processes for lots of domains.
# Leave undefined to let PHP decide.
# export PHP_FCGI_CHILDREN=1

# Maximum requests before a process is stopped and a new one is launched
export PHP_FCGI_MAX_REQUESTS=5000
# Launch the PHP CGI binary
# This can be any other version of PHP which is compiled with FCGI support.
exec /usr/bin/php5-cgi

```
Conf suexec pour le changement d'utilisateur du module : 

`/etc/apache2/suexec/www-se3`
```
/var/www/se3
cgi-bin
# The first two lines contain the suexec document root and the suexec userdir
# suffix. If one of them is disabled by prepending a # character, suexec will
# refuse the corresponding type of request.
# This config file is only used by the apache2-suexec-custom package. See the
# suexec man page included in the package for more details.
```
Et enfin la conf du virtualhost se3 : /etc/apache2/sites-enabled/se3.conf
```
<VirtualHost *:909>
        ServerAdmin webmaster@localhost

        DocumentRoot /var/www/se3/
        SuexecUserGroup www-se3 www-se3
        <FilesMatch ".ph(p3?|tml)$">
                # SetHandler application/x-httpd-php
                SetHandler fcgid-script
        </FilesMatch>


        <IfModule mod_fcgid.c>
                php_admin_flag engine off
                AddHandler fcgid-script .php
                AddHandler fcgid-script .php5
                FcgidConnectTimeout 20
                FCGIWrapper /usr/bin/php5-cgi .php
                FCGIWrapper /var/www/se3/cgi-bin/php5-default/php-fcgi-wrapper .php
        </IfModule>
        <Directory />
                Options +FollowSymLinks
                AllowOverride None
                Require all granted
        </Directory>
        <Directory /var/www/se3>
                Options -Indexes +FollowSymLinks +MultiViews +ExecCGI
                AllowOverride None
                Require all granted
        </Directory>

        <Directory /var/www/se3/setup>
                AllowOverride All
        </Directory>
        ScriptAlias /cgi-bin/ /usr/lib/cgi-binse/
        <Directory "/usr/lib/cgi-binse">
                AllowOverride None
                Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
                Require all granted
        </Directory>

        ErrorLog /var/log/apache2/errorse.log

        # Possible values include: debug, info, notice, warn, error, crit,
        # alert, emerg.
        LogLevel warn

        CustomLog /var/log/apache2/accessse.log combined
        ServerSignature On

        Alias /doc/ "/usr/share/doc/"
        <Directory "/usr/share/doc/">
                Options +Indexes +MultiViews +FollowSymLinks
                AllowOverride None
                Require  host 127.0.0.0/255.0.0.0 ::1/128
        </Directory>

        Alias /trombine /var/se3/Docs/trombine
        <Directory /var/se3/Docs/trombine>
                AllowOverride None
                Require all granted
        </Directory>

</VirtualHost>

```
A ajouter à la fin de `/etc/php5/cgi/php.ini` ( ou ailleurs ? )
```
include_path=".:/var/www/se3/includes"
```
# Auth AD Apache

La doc officielle est ici : 
https://wiki.samba.org/index.php/Authenticating_Apache_against_Active_Directory

## principe
L'utilisateur www-se3 est un compte de type service, qui n'a pas de droits particuliers sur AD, à part celui de relayer les demandes d'auth du serveur apache vers Ad, et de stocker les tickets.

Concretement, cela veut dire que lorsqu'un utilisateur s'authentifie, son ticket est stocké par apache et peut être réutilisé pour toute opération ldap, samba-tool ou n'importe quel autre outil acceptant les tickets Kerberos. Les utilisateurs ont donc exactement les mêmes droits que si ils utilisaient les outils de la console AD.

## avantages
- pas besoin de gérer l'auth au niveau php
- pas besoin de gérer les droits au niveau php
- bonne sécurisation : les droits d'accès à AD sont ceux de l'utilisateur, pas ceux d'un compte admin.
- SSO sur les Windows (conf nécessaire pour FF/Chrome)

## inconvénients
- Il n'est pas possible de changer d'identité au cours d'une session, il faut au minimum fermer le navigateur.
- La SSO est pénible si on n'a pas de certificats SSL valides. Il faut donc prévoir un mécanisme pour en obtenir chez LetsEncrypt, ce qui peut être complexe si le DNS interne n'est pas cohérent avec l'extérieur...

# test

le module auth_kerb d'apache est pourri... Impossible d'avoir un fonctionnement stable.

Testé en php5 module, fcgid + suexec, et php7-0-fpm

Il existe un module d'auth moderne : 

https://github.com/modauthgssapi/mod_auth_gssapi



