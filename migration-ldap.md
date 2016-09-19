# migration des parcs
##contraintes
 * une machine ou un groupe ne peut être qu'à un seul endroit (ou),
 * une machine ou groupe peut être dans autant de groupes que l'on veut,
 * une OU peut contenir n'importe quel objet,
 * les GPO s'appliquent aux OU
 * les droits s'appliquent aux groupes
 
On commence par faire un tri hierarchique des parcs existants, et on construit un arbre :
 * machines sans parc -> racine ou=Computers
 * machine dans parc, on crée un groupe + un OU 
 * * si le parc   
