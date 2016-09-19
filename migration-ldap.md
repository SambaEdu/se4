# migration des parcs
##contraintes
 * une machine ou un groupe ne peut être qu'à un seul endroit (ou),
 * une machine ou groupe peut être dans autant de groupes que l'on veut,
 * une OU peut contenir n'importe quel objet,
 * les GPO s'appliquent aux OU
 * les droits s'appliquent aux groupes
##Organisation
les machines sont rangées dans ou=Computers
On commence par faire un tri hierarchique des parcs existants, et on construit un arbre :
 * machines sans parc -> racine ou=Computers
 * machine dans parc, on crée un groupe + un OU 

# migration des groupes et utilisateurs
##contraintes
* un utilisateur ne peut être qu'à un seul endroit (ou)
* un utilisateur ou un groupe peut être dans autant de groupes que l'on veut

##organisation
les utilisateurs et groupes sont rangées dans un ou cn=users

lorsque on crée un groupe (classe, equipe ) on crée une OU et on les met dedans
