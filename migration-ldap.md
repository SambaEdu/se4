
page destinée aux notes concernant la migration d'un se3 existant
# conformité de l'annuaire se3
## doublons
aucun doublon de sambaSID, cn, displayname ne doit être présent dans l'annuaire. La page se3 permet de régler ce problème avant la migration
## comptes spécifiques

le compte root doit avoir un SID valable  avant la migration. Il sera mappé par AD vers Administrator 
Attention, le compte admin est semble-t-il supprimé lors de la migration

# migration des parcs
## Contraintes
 * une machine ou un groupe ne peut être qu'à un seul endroit (ou),
 * une machine ou groupe peut être dans autant de groupes que l'on veut,
 * une OU peut contenir n'importe quel objet,
 * les GPO s'appliquent aux OU
 * les droits s'appliquent aux groupes

## Organisation
les machines sont rangées dans cn=machines

donc la branche cn=Computers contient les cn=nome_machine

ou=Parcs qui contient les ou=nom_parc qui contient cn=nom_parc.

* Les machines sont membres des groupes cn=nom_parc,ou=parcs
* les GPO sont appliquées sur ou=nom_parc
* 
# migration des groupes et utilisateurs
## contraintes
* un utilisateur ne peut être qu'à un seul endroit (ou)
* un utilisateur ou un groupe peut être dans autant de groupes que l'on veut

## organisation
les utilisateurs  sont rangés dans cn=users

ou=groups contient ou=classe_truc,ou=Profs

lorsque on crée un groupe (classe, equipe ) on crée une OU correspondant et on les met dedans


D'abord on migre les comptes et groupes via `samba-tool migratedomain`
Ensuite on mouline les groupes, parcs et droits pour créer les ou et groupes manquants avec `samba-tool`, ou direct en python (à voir)

# migration des enregistrements dhcp
AD comporte un service de DNS dynamique, ce qui fait qu'il n'est pas forcément utile de mettre des adresses reservées par dhcp, car tous les postes au domaine auront en pratique un enregistrement DNS.

**_On peut malgré tout conserver la possibilité de réservation IP, mais ce n'est clairement pas une priorité_** 

Il existe la possibilité de configurer `isc-dhcp-server` pour qu'il mette à jour automatiquement les enregistrements DNS.  L'avantage c'est que *toutes* les machines auront un nom sur le réseau local.

https://wiki.archlinux.org/index.php/Samba/Active_Directory_domain_controller#DHCP

L'attribut "macAddress" peut être ajouté dans l'entrée de la machine. Il est donc possible d'avoir une base de donnée unique. En revanche il est contre-productif de stocker l'adresse IP. Il vaut mieux laisser le dhcp se débrouiller...


## reservation ip dhcp
le script makedhcpconf devra etre capable de : 

* lire/créer/changer l'ip dans l'enregistrement DNS avec `samba-tool dns`
* générer le fichier dhcp.conf à partir des données AD
* stocker un attribut (TXT?) disant que l'ip est reservée ?
* lire/ecrire/changer "macAddress" dans cn=poste : utile pour le clonage et le boot ipxe ?
* lire/ecrire/changer "ipHostNumber" dans cn=poste

A priori il n'est plus nécesssaire d'enregistrer les postes dans la table sql. Seul le paramétrage des sous réseaux dans le fichier de conf est nécessaire 

*Il faut ajouter 'objectClass: ieee802Device' dans cn=poste* Doit-on le faire pour chaque enregistrement, ou de façon globale ?

## postes non AD

si on veut reserver l'ip de machines qui ne sont pas au domaine, peut-on stocker leur enregistrement dans AD ? oui a priori. Cela peut être utile pour des équipements pour lesquels on veut une ip stable, mais qui n'auront pas de lien direct avec le serveur AD.

Pour les imprimantes IP, mettent-elles à jour leur enregistrement DNS dans AD ? *a verifier*

## fonctionnement 

* si un poste obtient une ip dynamique, rien n'est inscrit dans AD DNS
* si le poste est au domaine, l'enregistrement DNS est mis à jour.

cas d'une reservation : régénération de dhcp.conf

* ecriture DNS `A` et `TXT=reserved`
* lecture dans DNS des enregistrements `TXT=reserved`
* génération dhcpd.conf

## reservation de plages ip

Le filtrage de l'accès internet sur les routeurs se fait souvent par plages d'ip. En l'absence de Vlans, il faut pouvoir mettre les parcs de machines dans des plages d'ip. 

* reserver une ip fixe pour un poste : parc->poste->mac->ip : il faut stocker l'ip dans le cn=poste
* affecter une plage d'ip par parc : 

