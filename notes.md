#Samba 4 (SE4)
Notes concernant la faisabilité du passage de SE3 en contrôleur AD samba4. 

##Base de travail
une distrib Debian Wheezy fraîchement installée avec SE3 branche trunk à jour, et un annuaire complet d'un lycée de façon à avoir une vraie base d'utilisateur à migrer. 
Une ou deux machines XP et Seven sont mises au domaine.

howto s4

https://wiki.samba.org/index.php/Samba4/HOWTO#Step_1:_Download_Samba4

Howto migration

https://wiki.samba.org/index.php/Samba4/HOWTO#Migrating_an_Existing_Samba3_Domain_to_Samba4

Questions : 

comment interagit-on avec l'annuaire intégré samba4 : requetes ldap classiques, utilisation des outils samba-tools, libs python samba4 ?


http://en.gentoo-wiki.com/wiki/Samba4_as_Active_Directory_Server#Example_for_application_specific_auth_plugin:_Apache

https://wiki.samba.org/index.php/Samba4/Winbind

##Structure de l'annuaire
En fait il possible de conserver un schéma contenant les attributs Posix ( uid, unixhomedirectory...), et donc on devrait pouvoir continuer à utiliser tel quel les applis extérieures type LCS sans changement. Avec toutefois une nuance de taille : en AD, les utilisateurs, groupes et machines ne sont pas rangés dans des branches, ils peuvent être n'importe où, c'est même le principe des GPO : on déplace les objets vers un OU, et il hérite des GPO de celui-ci.

Dans l'absolu, cela veut dire qu'une requête ldapsearch -b ou=people,dc=truc "(uid=toto)"  devrait être ldapsearch "(&(objectclass=user)(uid=toto))"

Mais on peut ruser : en pratique, rien n'empêche de créer les OU des gpo dans OU=people : les utilisateurs resteront donc bien toujours dans ou=people, et une recherche avec SCOPE_SUBTREE aboutira toujours.

Il faudra en revanche écrire l'attribut uid, car les outils samba4 ne le font pas par défaut ( modif à proposer upstream).

En revanche pour les groupes c'est plus problématique : on ne peut pas créer OU séparés, car c'est justement le principe de pouvoir mettre des groupes dans des OU, comme les utilisateurs. Les groupes AD peuvent contenir des groupes, il faut donc tenir compte de cela au niveau de l'interface : garde-t-on la structure actuelle des classes, ou fait-on des changements  ? Moins on change, mieux c'est...

donc $groupsRdn =peopleRdn

Pour les GPO, si un groupe doit avoir une config particulière, le plus simple est de créer une OU avec une GPO, puis de mettre dedans le groupe 

exemple : on veut que les BTS aient une GPO spécifique

 - on crée ou=BTS,ou=People,
     - on met dedans tous les groupes classes des BTS
     ou
     - on crée un groupe BTS et on met dedans tous les groupes classes de BTS

on veut en plus que les BTS_CIM1 et 2 aient un paramétrage de Solidworks :

 - on crée ou=SW_CIM,ou=BTS,ou=People, et la GPO associée,
 - on déplace Classe_CIM1 et Classe_CIM2 dedans

plus compliqué : on veut en plus une config particulière pour tous les élèves de CPI2 et CIM2 : on ne peut pas déplacer CIM2, il est déjà dans un groupe :

 - on va donc créer un nouveau groupe, contenant Classe_CIM2 et Classe_CPI2, 
 - on crée ou=CIMCPI2,ou=People, on met le groupe CIMCPI2 dedans,

généralisation : on crée une OU et un groupe à chaque fois que l'on a une nouvelle GPO, afin de ne pas devoir bouger les groupes et utilisateurs existants ?

###Filtres ldap
Pour la consultation ldap, la meilleure solution serait de rendre les filtres ldap de se3 utilisables aussi bien en AD qu'en se3. Ceci permettrait une migration en douceur.

* pour les utilisateurs : 
 (|(&(objectclass=person)(uid=toto))(&(objectclass=user)(cn=toto))
* pour les groupes :
 (|(&(objectclass=posixgroup)(cn=groupe))(&(objectclass=group)(cn=groupe)) 
* pour les machines : 
 
Pour l'ecriture, on utilise samba-tool


Pour les droits (ou=rights) :

on peut garder une ou distincte, fille de people, qui contiendra les groupes cn=se3_is_admin et compagnie. Pas de pb, les requètes ldap restent les mêmes.
on a donc : $rightsRdn=ou=rights,ou=people

pour les machines  : idem, on peut faire ce que l'on veut, et donc en particulier créer les parcs sous ou=computers. En revanche, la structure des parcs devient hiérarchique, une machine ne pouvant appartenir qu'à une ou, il faut les ranger de façon arborescente :

 ou=computers-+-ou=parcs-+-ou=physique+-salle201
              |          |            +-salle203
              |          +-ou=maths---+-salle101
              |                       +-salle110
              +-cn=machinesansparc
ou alors structure à plat, auquel cas il faut créer un groupe par parc.

##migration
###Etape 1 : préparation de l'annuaire
L'annuaire samba4 a une structure différente  : 

utilisateurs: uid devient cn. C'est le gros changement.
branche : ou=People -> cn=Users
dn : uid=,ou=People,dc -> cn=,cn=Users,dc
uid : prenom.nom -> cn
cn : Prenom Non -> displayName

groupes :  les groupes sont dans la même gbranche que les utilisateurs : pas de différences notables, ils peuvent être imbriqués ( un groupe peut être membre d'un autre groupe ). Conséquence, un groupe ne peut pas avoir le nom d'un utilisateur !

branche : ou=Groups -> cn=Users
memberUid -> member

machines : un seul enregistrement cn=poste,ou=Computers,dc=... Voir si on peut avoir les @mac et @IP pour dhcp ?

imprimantes : pas testé.

rights : les groupes deviennent des ou, idem pour les parcs
cn=truc_is_admin -> ou=truc

###Script de migration
####script préparatoire

* réallouer les doublons sambaSID
* générer les ldifs pour ou=Rights compatibles avec nouvelle structure
* génerer les ldifs pour ou=Parcs compatibles avec la nouvelle structure : mettre les machines correspondantes dans ou=sallexxx,ou=Parcs,dc=...
* génerer les ldifs pour ou=Restrictions : analyser la table restrictions pour rechercher les groupes et users avec des restrictions, et créer une ou correspondante.
* générer les ldifs pour ou=Templates : analyser les dossiers dans netlogon, et créer les ou correspondant aux templates
* générer les ldifs correspondant aux imprimantes et les ajouter aux ou correspondant aux parcs.

####migration avec l'outil samba4

* import des ldifs générés précédemment
* import des GPO avec logonpy ?


##Tests
Voici mes premières constatations (vieux !)

- la migration de l'annuaire passe bien, à condition d'avoir supprimé les doublons des SID, et les enregistrements invalides. On récupère bien les utilisateurs, les groupes, et les machines. En revanche les OU parcs, imprimantes et droits ne sont pas importés c'est logique car ce ne sont pas des objets samba. Il faudra donc prévoir un script maison pour cela.

- la structure de l'annuaire change :

    le dn utilisateur : uid=toto,ou=People,dc=truc,dc=org -> cn=toto,cn=Users,dc=truc,dc=org
    le dn groupe: cn=bidule,ou=Groups,dc=truc,dc=org -> cn=bidule,cn=Users,dc=truc,dc=org
    les membres sont tous en member=cn=toto,cn=Users,dc=truc,dc=org
    le dn machine: uid=xptest$,ou=Computers,dc=truc,dc=org -> cn=xptest,cn=Computers,dc=truc,dc=org

pour les ou :
   cn=parc1,ou=parcs,dc=truc,dc=org -> ou=parc1,ou=parcs,dc=truc,dc=org

- l'annuaire n'est plus accessible en bind anonyme, il faut s'authentifier. On n'utilise plus openldap mais le serveur intégré à samba4

- pour authentifier un utilisateur depuis l'annuaire il faut utiliser kerberos

- samba4 intègre une conf automatique de bind9, et donc un service dns dynamique pour le domaine.

- samba4 n'est pas pour le moment destiné à fournir le service de serveur de ficihers. c'est s3fs qui s'en charge, pour le moment il y a des soucis d'ACLs, mais cela devrait rentrer dans l'ordre assez vite. Il faudra probablement régénérer toutes les ACLS, car le mapping des utilisateurs change (les UID/GID fournis par winbind ne sont plus ceux que fournissait samba3/ldap)

Il y a donc plusieurs points à régler :

- authentification de l'interface se3 : Il faut utiliser le SSO kerberos, le module apache existe, c'est pas bien compliqué, c'est même une sacrée simplification par rapport au mécanisme existant !

- adaptation au nouveau schéma ldap : pas mal de code est impacté, mais mes premiers essais en faisant du remplacement brutal s/uid/cn/g fonctionnent presque ! En faisant cela proprement dans un IDE on doit pouvoir s'en sortir. On change les peoplerdn, grouprdn, etc... dans la table des parametres.

- gestion des utilisateurs : il faut utiliser samba-tool pour gérer des utilisateurs/groupes, en remplacement des scripts perl actuels. Plutôt une simplification, on n'a plus à gérer l'utilisateur unix.

- gestion des parcs : il faut modifier le code des pages pour créer les OU, qui reprennent exactement les mêmes fonctionnalités, mais en AD. En gros les parcs deviennent des OU, ainsi que les groupes ayant des templates. Migration à prévoir ! Dans un premier temps on peut utiliser l'outil microsoft de gestino des domaines AD.

- gestion des droits : soit on fait des groupes, soit on fait des OU. Les groupes permettent d'avoir des permissions sur des fichiers et des droits sur le domaine (administrateur...), les OU de déployer des stratégies. A priori, c'est plutôt des groupes donc. A noter que l'imbrication est autorisée : on peut mettre le groupe profs dans le groupe sovajon_is_admin, par exemple.

- scripts de logon : on est en ActiveDirectory, donc toutes les bidouilles actuelles ne sont plus nécessaires, on se borne à poser les scripts utiles au bon endroit (dans sysvol ?). Une solution consiste à provisionner les templates actuels dans des ou, cela peut être automatisé, on copie les scripts aux bons endroits dans Sysvol

- GPO : samba-tool gpo permet de créer des GPO, on peut donc scripter le passage depuis l'existant sans pb, puis il suffit de générer les .pol avec logonpy et de les mettre dans sysvol ! On peut donc garder tout l'existant, mais en l'utilisant en vraies gpo. Rien n'empêche d'utiliser les outils microsoft en +

- wpkg : pas d'impact à part la mise à jour des requêtes ldap sur les parcs.

- les imprimantes : voir comment on fait pour les stocker dans AD, je n'ai pas regardé.

- dhcp : grosse inconnue, vu que l'on a maintenant un dns dynamique, est-ce encore nécessaire de gérer les réservations ? Il n'y a pas de champ adresse ip et mac dans le cn=poste, mais on peut peut-être l'ajouter, si le schéma est compatible. A voir. En revanche il faut ajouter se3 comme serveur dns.

- mise au domaine : grosse simplification, plus besoin de clés particulières. un simple vbs fait l'affaire, et pour les postes déjà au domaine c'est automatique


correspondances : 

ou=People et ou=machines : a conserver
ou=groups : conserver les groupes samba (eleves, classes, equipes)
ou=rights, parcs : chaque groupe devient une ou (principe d'AD). 

Analyser les modifs à apporter aux scripts de logon sur le serveur samba3 ( imprimantes, mkhome... )
==libnss==

La résolution des uid ne se fait plus en ldap mais avec winbind : 

Installing and configuring

The current installation process put the library libnss_winbind.so in <PATH_TO_SAMBA>/lib (ie. /usr/local/samba/lib). Use a current checkout as described in Samba4/HOWTO.

 # ln -s /usr/local/samba/lib/libnss_winbind.so.2 /lib/libnss_winbind.so
 # ln -s /lib/libnss_winbind.so /lib/libnss_winbind.so.2

You need to instruct the system to use the nss winbind library when searching for users or groups. For this add the keywork winbind to the stanza passwd and group in /etc/nsswitch.conf.

It should look like:

 passwd:          compat winbind
 group:           compat winbind
 shadow:          files
 ...

il faut également ajouter 
        winbindd socket directory = /tmp/.winbindd

dans le smb.conf


 
==Authentification de l'interface==

On peut utiliser en priorité le module kerberos d'apache (voir plus haut) : avantage, on a une vraie SSO pour les postes windows. En secours, on s'authentifie en ldap




Assuming you got Samba4/DNS (bind9.81+) and Kerberos up and running, let's
start by setting up the web server.

Install apache2 + mod_auth_kerb

    Ubuntu/Debian
    # apt-get install apache2 libapache2-mod-auth-kerb
    # a2enmod ssl auth_kerb

Setup a minimal ssl-secured site

We need to setup a vhost which will host our secured intranet site.
NOTE: You don't need to use a secured site to get this example working, but
in production environments it's highly suggested to use one for security
reasons.
A minimal configuration might look like this:

file: /etc/apache2/sites-available/default-ssl

<IfModule mod_ssl.c>
<VirtualHost _default_:443>
    ServerAdmin webmaster@localhost

    DocumentRoot /var/www
    <Directory />
        Options FollowSymLinks
        AllowOverride None
    </Directory>
    <Directory /var/www/>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride None
        Order allow,deny
        allow from all
    </Directory>

    #########################################################
    # add a private directory using kerberos authentication #
    #########################################################

    <Directory /var/www/private>
        AuthType Kerberos
         AuthName "Intranet Login"
        KrbMethodNegotiate on
        KrbMethodK5Passwd on
        KrbVerifyKDC on
        KrbSaveCredentials off

        # our keytab
         Krb5Keytab  /etc/apache2/http.keytab

         # specify your realm (upper case - like the krb5.conf)
         KrbAuthRealms YOUR.REALM
         Require valid-user
      </Directory>

      # rest of file
      ...

Add the private directory to the filesystem
    # mkdir /var/www/private
Enable the ssl site
    # a2ensite default-ssl

Next step is to create a user - a service account which will silently
authenticate the currently logged in AD user (you) . To create the user
account, we will use the remote server administration tools provided by
Windows. If you followed the HOWTO
http://wiki.samba.org/index.php/Samba4/HOWTO#Step_1:_Installing_Windows_Remote_Administration_Tools_onto_Windows,
you should already have them.

Fire up the Active Directory Users and Computers snap-in and open the
predefined Users-folder. If you take a closer look at it's content, you'll
notice samba's DNS account in there, which is named 'dns-<hostname of dc>'
- let's stick to this unwritten convention and name the new account
'http-<hostname of dc>'. Choose a proper password and tick the 'Account
never expires'-option. The password is required later on, so don't forget
it.

Now that the account is created successfully, switch back to
Linux-commandline.

Our account needs a proper service principal name (SPN). Samba4 provides a
tool named 'ldbedit' to modify AD data. To add a proper SPN to the service
account type in the following command:

    # ldbedit -H /usr/local/samba/private/sam.ldb
"(samaccountname=http-<hostname of dc>)" -e <your favourite editor>

This will open up the specified account for manipulation. the '-e' option
lets you specify an editor to use (nano in my case). Just add the required
SPN

    servicePrincipalName: HTTP/yourdomain.tld

and save the file.

In my case, the entry looks like this:

 ...
 sAMAccountName: http-server-vm
 sAMAccountType: 805306368
 objectCategory: CN=Person,CN=Schema,CN=Configuration,DC=testnet,DC=dom
 userAccountControl: 590336
 description: HTTP Service Account for server-vm
 servicePrincipalName: HTTP/testnet.dom
 whenChanged: 20120624120002.0Z
 ...

Now we're ready to go on.

Back at Windows, refresh the content or reopen the Active Directory Users
and Computers snap-in. The properties of the service account now show an
additional tab named 'Delegation'. Tick the second option 'Trust User on
delegation of all services (Kerberos only)' - I don't know the exact
description, because I got the german version.

Now the service account is allowed the request authentication- and service
tickets for other user, which is what we want.

Next, we have to create a keytab for our account - this is the first point
of a common pitfall. For keytab-creation Samba provides the 'ktpass.sh'
shell script, which (by default) is located at
/usr/src/samba-master/source4/scripting/bin/. However, it doesn't work from
this path, as Matthieu Patou wrote on
http://samba.2283325.n4.nabble.com/samba4-keytab-management-tp2478287p2478297.html.
You have to copy it to samba/bin/ - for example:

    # cp /usr/src/samba-master/source4/scripting/bin/ktpass.sh /usr/local/samba/bin/

Create the keytab

    # kinit http-<hostname of dc>

    This will initialize the service account (Now you should remember the given password) 

    # ktpass.sh --out /etc/apache2/http.keytab --princ HTTP/yourdomain.tld --pass '*'

    Retype the password again - now ktpass should answer with 'Keytab file
/etc/apache2/http.keytab created with success'

    # chown www-data:www-data /etc/apache2/http.keytab
    # chmod 0400 /etc/apache2/http.keytab

    This will change the owner of the keytab to www-data (the default user, apache2 runs at) and make it readable only by this user - we want security, right?

Finally, it's time to restart the web server for changes to take effect. The last part is the client side setup - the browsers. Let's begin with firefox.

Firefox needs to know the trustworthy uri(s) to use negotiation. We simply need to set the appropriate configuration value and it will work out of the box.

Start firefox and go to the url 'about:config' - you'll get a warning, but don't panic, we will be careful - I promise 

Type 'negotiate' into the search field Now modify the entry 'network.negotiate-auth.trusted-uris' and type in your
domain name (e.g. testnet.dom).

You may get a warning, if you're using a self-signed certificate (like me) - just add an exception and the page will load. That's it! Open https://yourdomain.tld/private/ and you're in - fully authenticated as user@YOUR.REALM

On Internet Explorer, you have to add your site to the local intranet security zone to enable negotiation support. The certificate will be treated as insecure and IE will complain about that. Well, to be honest, I haven't found a proper way to install and trust it permanently, so I'll leave this up to you.

You may take a look at Samba's debug log (start it with -i -M single -d3)
to watch the whole authentication process. For convinience, here's my
output:

 Kerberos: TGS-REQ Administrator@TESTNET.DOM from
 ipv4:192.168.178.133:1088for HTTP/testnet.dom@TESTNET.DOM[renewable, forwardable]
 Kerberos: TGS-REQ authtime: 2012-06-28T18:28:22 starttime:
 2012-06-28T18:28:22 endtime: 2012-06-29T04:28:22 renew till:
 2012-07-05T18:28:22

If you see something like this, it works.

Feel free to add this to the wiki.

Cheers, Enrico

==Compatibilité LCS==
Les scripts d'import de l'annuaire sont communs, donc la modif portera sur les 2 systèmes. Doit-on conserver les 2 en synchro ? ou changer l'annuaire LCS (gros boulot!)?
==Implémentation des fonctions==
Actuellement c'est un peu le bazar, du php, dup perl, du python, du shell, et surtout des manipulations ldap un peu partout et pas seulement dans de des includes. Résultat le changement d'annuaire a pas mal d'impact un peu partout... Néanmoins on devrait pouvoir s'en sortir. La question est de savoir si on essaie de nettoyer tout cela : par ordre décroissant d'ambition, cela donne : 

* on repart sur un modèle objet propre MVC, smarty, templates...
* on réorganise le code php pour repasser tous le ldap en includes
* on search and replace sauvagement dans l'existant.

En pratique, quasiment tout le bourrinage ldap peut se faire avec samba-tool, ou directement à partir des libs python. Donc 80% des scripts n'ont plus de raison d'être... quasiment tout le perl dans scripts peut être remplacé par un samba-tool : exemple

Ajouter un utilisateur : 
 samba-tool user add toto.machin
 samba-tool group addmember Classe_truc toto.machin
 samba-tool group listmember Classe_truc

==Evolutions futures==

Paquet debian ?

Mode multi maitre ?

Editeur des GPO intégré en remplacement des pages clients windows de SE3 ?
