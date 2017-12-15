# Partages en mode "cloud"

Le modèle serveur de fichiers centralisé samba montre ses limites, notamment pour la distribution de documents aux élèves, et le travail en groupe. Utiliser un système de distribution web avec un client local de synchronisation avec un cache local est bien plus performant en terme de bande passante et de consommation de ressources disques, car les données côté serveur sont naturellement dédupliquées.

La solution Seafile / Seadrive est parfaitement adaptée au besoin : 

- serveur Seafile libre et très simple à installer et configurer,
- très stable et performant, demande très peu de ressources.
- client Seadrive multiplateforme (Win/Mac/Linux/Android/IOS)
- accès totalement transparent depuis l'extérieur en https

## interfaçage sambaedu

Le client seadrive peut être déployé en paquet wpkg  (lien xml). Il peut être préconfiguré en GPO de façon à ce que la seule intervention de l'utilisateur soit la saisie de son mot de passe à la première utilisation. 

L'utilisateur a ensuite sur son poste un lecteur S: qui regroupe toutes les bibliothèques ou les dossiers partagés auxquels il peut accéder.

(GPO utilisateur)

## Performances

Le client télécharge à la demande et cache les fichiers dans `%USERPROFILE%\seadrive\data` La limite est configurable (10 Go par défaut). La synchronisation de ce cache se fait suivant un algorithme basé sur Git, et est très efficace. Si on configure la stratégie d'effacement des profils locaux pour les conserver un certain temps, l'utilisateur qui se reconnecte sur un posteoù il a déjà travaillé quelques jours avant accèdera directement à ses ficihiers en local, avec juste la synchro des différences éventuelles. Si le profil a été effacé, seul d'index est téléchargé à l'ouverture de session, ce qui est très rapide. Sur les postes avec de gros disques, on peut raisonnablement garder les profiles plusieurs semaines... 

Il est impératif d'avoir une GPO qui exclut seafile/data du profile itinérant...

Un premier test comparatif avec un lecteur réseau samba sur des fichiers Solidworks volumineux (50 Mo) montrent un temps d'ouverture équivalent dans le cas où le cache est vide, et de 5 à 10 fois plus rapide dans le cas de fichiers cachés ! l'impact de seadrive sur l'ouverture de session semble être imperceptible, le lecteur S: apparaît quand il est prêt, mais ne bloque pas l'ouverture. (à confirmer).

Pour les Linux et Mac, un dossier seadrive est monté dans le home avec Fuse, et est donc accessible de façon transparente pour les applications car c'est un "vrai" montage, pas un gvfs.

Côté serveur, on est sur un protocole complètement asynchrone. Les perfs du serveur et du réseau n'influent que très peu sur l'expérience utilisateur. Le serveur seafile peut (DOIT ?) être en dmz, et peut tourner sur une vm, un conteneur ou même directement sur un NAS. Seafile enregistre les données sous forme de blocs dédupliqués, et est donc extrêmement efficace comme stockage pour les données dupliquée, comme par exemples les travaux élèves.
 
## Interface sambaedu

- Les utilisateurs sont automatiquement récupérés sur ldap/AD, et sont activés dans seafile à la première connexion sur l'interface Seafile.
- la récupération complète et automatique des groupes ldap est une fonction de la version seafile pro payante. Pour notre besoin très limité (peupler Classes et équipes), on peut développer une moulinette php qui peuplera et synchronisera ces groupes ! on peut aussi ne pas le faire, et ajouter individuellement les utilisateurs lors des partages.

### partages classes

Le partage classes se prête très bien au passage en mode cloud : on crée une bibliothèque partagée avec tous les membre de l'équipe par classe, on partage le dossier travail en lecture seule avec les élèves, et on partage chaque dossier individuel avec l'élève concerné. 

- modifier la page partages.php
- réécrire updateclasses.pl en php en utilisant seafile-php

La migration des données existantes sur le disque peut être faite manuellement classe par classe, ou alors automatisée, mais pas sûr que cela vaille le coup.

Le mécanisme de changement de classe devra être conservé : déplacement des données ou création de nouveaux dossiers?

### partages projets

Etant donné que les utilisateurs peuvent eux-même depuis l'interface seafile créer une bibliothèque et la partager avec l'autres personnes, il n'est peut-être pas utile de dupliquer ces fonctions.

### partages perso

Seafile crée automatiquement une bibliothèque pour `Mes Documents` Faut-il la définir comme emplacement par défaut Windows `S:\Ma Bibliothèque` au lieu de `K:\Docs` ? prévoir la migration des documents dans `k:\Docs` ? Que faire pour le bureau ?

### partages des ressources

- Il est inutile de partager `install`, qui doit rester un partage Samba pour l'installation  des postes. Idem pour `Progs`
- migrer `Docs` ?
- permettre la création de partages centralisés ?

Les premiers tests semblent confirmer que la quantité de données partagées a un coût très faible sur l'indexation de S: Si cela se confirme, il pourrait être intéressant de partager quasiment tout...

## soucis

- il faut être en mesure de configurer un service web https acessible de l'intérieur et de l'extérieur avec exactement la même adresse (maîtrise du dns externe et interne, du proxy, redirection 443 ou mieux reverse proxy SSL). C'est techniquement possible avec AMON...
- obligation d'avoir un certificat ssl en cas d'accès extérieur. 
- si le certificat n'est pas signé, la configuration du client est plus complexe pour l'utilisateur de base ( il faut décocher la case...)
- pas de vraie SSO : l'utilisateur doit taper son mot de passe à la première ouverture de session. Ceci est également vrai pour l'interface : cela oblige à créer les bibliothèques avec un compte dont le mot de passe est connu par l'interface (adminse3)



 
