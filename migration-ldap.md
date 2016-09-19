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
