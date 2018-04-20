#!/bin/bash
#
# $Id$
#
# Script destine a donner/enlever les droits Profs sur les dossiers de Classes
#

classe=$(echo "$*" | grep "classe="|cut -d"=" -f1|sed -e "s|[^A-Za-z0-9_]||g")

t=$(echo "$*" | grep "droits=n")
if [ -n "$t" ]; then
	if [ -z "$classe" ]; then
		# On retire les droits
		setfacl -R -x g:Profs /var/sambaedu/Classes
		setfacl -R -x d:g:Profs /var/sambaedu/Classes
	else
		# On retire les droits sur la classe choisie
		setfacl -R -x g:Profs /var/sambaedu/Classes/$classe
		setfacl -R -x d:g:Profs /var/sambaedu/Classes/$classe
	fi
else
	if [ -z "$classe" ]; then
		# On donne les droits lecture seule sur les fichiers et dossiers existants
		setfacl -m g:Profs:rx /var/sambaedu/Classes

		setfacl -R -m g:Profs:rx /var/sambaedu/Classes/Classe_*
		setfacl -R -m d:g:Profs:rx /var/sambaedu/Classes/Classe_*

		# On parcourt les dossiers de classes pour donner tous les droits a l'intérieur des dossiers eleves, _travail et _profs
		ls /var/sambaedu/Classes | grep "^Classe_" | while read rep_classe
		do
			setfacl -R -m g:Profs:rwx /var/sambaedu/Classes/$rep_classe/*
			setfacl -R -m d:g:Profs:rwx /var/sambaedu/Classes/$rep_classe/*
		done
	else
		if [ ! -e "/var/sambaedu/Classes/$classe" ]; then
			echo "ERREUR : Le dossier /var/sambaedu/Classes/$classe n'existe pas."
		else
			setfacl -m g:Profs:rx /var/sambaedu/Classes

			setfacl -R -m g:Profs:rx /var/sambaedu/Classes/$classe
			setfacl -R -m d:g:Profs:rx /var/sambaedu/Classes/$classe

			setfacl -R -m g:Profs:rwx /var/sambaedu/Classes/$classe/*
			setfacl -R -m d:g:Profs:rwx /var/sambaedu/Classes/$classe/*
		fi
	fi
fi
