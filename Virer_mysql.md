# Pourquoi
la base mysql actuelle contient la conf, les clés, les reservations dhcp et les logs de connexion. 

- Le code php mysql actuel est assez pourri, 
- l'accès depuis bash est très lent, du coup les infos sont dupliquées ailleurs

# Comment
## Configuration

Avec AD, il n'est plus nécessaire de stocker les mots de passe en clair. On peut donc mettre la table param dans un simple fichier texte : 

- name = "value"
- yaml
- ini
- xml
- json 

Ce fichier est lu par php, les scripts bash, le paquetage debian... Et par Ansible ?

**Remarque de flaf :** pour info Ansible utilise déjà des fichiers YAML
dans sa conf (ie dans `/etc/ansible/group_var/*.yaml`) pour définir ses
variables et il est aussi capable de lire un fichier YAML externe pour
définir d'autres variables. Donc le YAML peut être intéressant pour cela.
Je trouve que ça a l'avantage d'être un format structuré (c'est standardisé,
parsable dans beaucoup de langages), c'est typé (on peut mettre des tableaux,
des dictionnaires, des chaînes de caractères, des entiers, des booléens)
et c'est moins bavard et plus facile à lire que du json ou du xml (àmha).

Le problème c'est les scripts shell, qui sont nombreux. lire le yaml est sûrement possible, mais un peu complexe, et j'ai moyennement confiance dans les parsers imbitables en awk/sed/grep que l'on trouve sur le net. Alors qu'un key = value est directement lisible en bash, en php avec parse_ini_file(), et probablement dans tous les autres langages.

## Dhcp

Les infos de conf sont dans le fichier de conf.

Avec ipxe, il est probablement possible de  récuperer le nom de la machine lors du clonage depuis une page dynamique, ou utiliser le DNS

Le fichier unattend.csv n'est plus utile.

### avec reservations dhcp 

les correspondances nom-mac-ip sont renseignées dans AD cn=computers

### sans reservations dhcp

On utilise l'enregistrement DNS. (nom-ip)


## GPO

Les bases de clés sont dans des ficihers .admx

Les affectations sont dans AD, c'est fait pour cela...

## Logs de connexion 

L'info du dernier log est directement accessible dans cn=poste,cn=computers. Il faut donc la copier dans un fichier log




