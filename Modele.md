Description du modèle de données manipulé par SambaEdu
# sources
## Base AD
- acces par ldap, ldb, samba-tool, console MS
- contient l'ensemble des données d'identification utilisateurs et machines.

## Partages utilisateur
- accès en système en fichier local, commandes smb
- contient les données de travail utilisateurs

## Partages système (netlogon, sysvol, install) 
- accès en système local ou commandes smb, console MS
- contient des données et scripts de configuration des machines (GPO) et des logiciels (wpkg)

## base SQL
- accès mysqlclient
- contient des données de configuration serveur, des données de session et des logs

# Modèle

## utilisateur

- role : prof, élève, administratif
- login
- nom 
- prénom
- date de naissance
- sexe
- employeeNumber
- email
 -photo
 - description
 -password
 
## groupe
 
 - type : classe, equipe, matière, partie_classe, projet, regroupement
 - nom
 - description
 - membres : utilisateurs ou groupes
 
## machine
 
 - nom 
 - description
 - os
 - ip
 
## imprimante

- nom
- description
- url
- driver ?
 
## parc
- nom
- type : salle, matériel
- description
- membres : machines, imprimantes, parcs

 
