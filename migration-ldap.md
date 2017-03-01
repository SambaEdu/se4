# conformité de l'annuaire se3
## doublons
aucun doublon de sambaSID, cn, displayname ne doit être présent dans l'annuaire. La page se3 permet de régler ce problème avant la migration
## comptes spécifiques
le compte root doit avoir un SID valable  avant la migration. Il sera mappé par AD vers Administrator 
Attention, le compte admin est semble-t-il supprimé lors de la migration
# migration des parcs
##contraintes
 * une machine ou un groupe ne peut être qu'à un seul endroit (ou),
 * une machine ou groupe peut être dans autant de groupes que l'on veut,
 * une OU peut contenir n'importe quel objet,
 * les GPO s'appliquent aux OU
 * les droits s'appliquent aux groupes

##Organisation
les machines sont rangées dans cn=machines

donc la branche cn=Computers contient les cn=nome_machine

ou=Parcs qui contient les ou=nom_parc qui contient cn=nom_parc.

* Les machines sont membres des groupes cn=nom_parc,ou=parcs
* les GPO sont appliquées sur ou=nom_parc
* 
# migration des groupes et utilisateurs
##contraintes
* un utilisateur ne peut être qu'à un seul endroit (ou)
* un utilisateur ou un groupe peut être dans autant de groupes que l'on veut

##organisation
les utilisateurs  sont rangés dans cn=users

ou=groups contient ou=classe_truc,ou=Profs

lorsque on crée un groupe (classe, equipe ) on crée une OU correspondant et on les met dedans


D'abord on migre les comptes et groupes via `samba-tool migratedomain`
Ensuite on mouline les groupes, parcs et droits pour créer les ou et groupes manquants avec `samba-tool`, ou direct en python (à voir)

# migration des enregistrements dhcp
AD comporte un service de DNS dynamique, ce qui fait qu'il n'est pas forcément utile de mettre des adresses reservées par dhcp, car tous les postes au domaines auront en pratique un enregistrement DNS.
On peut malgré tout on veut conserver la possibilité de réservation IP
## reservation ip dhcp
le script makedhcpconf devra etre capable de : 

* lire/créer/changer l'ip dans l'enregistrement DNS avec `samba-tool dns`
* générer le fichier dhcp.conf à partir des données AD
* stocker un attribut (TXT?) disant que l'ip est reservée ?

A priori il n'est plus nécesssaire d'enregistrer les postes dans la table sql. Seul le paramétrage des sous réseaux est nécessaire ( à moins qu'on puisse faire cela en zone DNS ?)

## postes non AD
si on veut reserver l'ip de machines qui ne sont pas au domaine, peut-on stocker leur enregistrement dans AD ? oui a priori

## fonctionnement 

* si un poste obtient une ip dynamique, rien n'est inscrit dans AD DNS
* si le poste est au domaine, l'enregistrement DNS est mis à jour.

cas d'une reservation : régénération de dhcp.conf

* ecriture DNS `A` et `TXT=reserved`
* lecture dans DNS des enregistrements `TXT=reserved`
* génération dhcpd.conf


