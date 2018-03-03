<?php
   /**
   * Librairie de fonctions utilisees dans l'interface d'administration

   * @Version $Id: samba-tool.inc.php  2018-22-02 15:39:50Z jlcf $

   * @Projet  SambaEdu

   * @Note: Ce fichier de fonction doit etre appele par un include

   * @Licence Distribue sous la licence GPL
   */

   /**
   * file: samba-tool.inc.php
   * @Repertoire: includes/
   */

//=============================================================
// Ensemble de fonctions destinées à remplacer les scripts perl
// pour les opérations d'écritures dans l'AD SambaEdu
// userAdd.pl => /usr/share/sambaedu/sbin/userAdd.php 
//		function useradd($prenom, $nom, $userpwd, $naissance, $sexe, $categorie)
// userDel.pl => /usr/share/sambaedu/sbin/userDel.php 
//		function userdel($cn)

/*
./affichageleve.php:			exec ("/usr/share/se3/sbin/groupAdd.pl \"1\" $cn \"$description\"",$AllOutPut,$ReturnValue);
./add_user_right.php:        	exec ("/usr/share/se3/sbin/groupAddEntry.pl \"$cDn\" \"$pDn\"");
./del_user_group_direct.php:    exec ("/usr/share/se3/sbin/groupDelUser.pl $uid $cn",$AllOutPut,$ReturnValue);
./add_list_users_group.php:     exec("/usr/share/se3/sbin/groupAddUser.pl  $new_uids[$loop] $cn" ,$AllOutPut,$ReturnValue);
./del_user.php:        			exec ("/usr/share/se3/sbin/userDel.pl $uid",$AllOutPut,$ReturnValue);
./grouplist.php:				exec("/usr/share/se3/sbin/userChangePwd.pl '$uid_init' '$userpwd'", $AllOutPut, $ReturnValue);
./add_user.php:					exec ("/usr/share/se3/sbin/userAdd.pl \"$prenom\" \"$nom\" \"$userpwd\" \"$naissance\" \"$sexe\" \"$categorie\"",$AllOutPut,$ReturnValue);
./del_group.php:      			exec ("/usr/share/se3/sbin/groupDel.pl $cn",$AllOutPut,$ReturnValue);
./del_user_group.php:       		exec ("/usr/share/se3/sbin/groupDelUser.pl $members[$loop] $cn",$AllOutPut,$ReturnValue);
./add_group_right.php:        	exec ("/usr/share/se3/sbin/groupAddEntry.pl \"$cDn\" \"$pDn\"");
./add_group_right.php:        	exec ("/usr/share/se3/sbin/groupDelEntry.pl \"$cDn\" \"$pDn\"");
./add_user_group.php:        	exec ("/usr/share/se3/sbin/groupDelUser.pl $uid $categorie",$AllOutPut,$ReturnValue0);
./add_user_group.php:        	exec("/usr/share/se3/sbin/groupAddUser.pl $uid $new_categorie" ,$AllOutPut,$ReturnValue1);
./add_user_group.php:        	exec("/usr/share/se3/sbin/groupAddUser.pl $uid $new_categorie" ,$AllOutPut,$ReturnValue);
./add_user_group.php:          	exec("/usr/share/se3/sbin/groupAddUser.pl $uid $classe_gr[$loop]" ,$AllOutPut,$ReturnValue);
./add_user_group.php:          	exec("/usr/share/se3/sbin/groupAddUser.pl $uid $matiere_gr[$loop]" ,$AllOutPut,$ReturnValue);
./add_user_group.php:          	exec("/usr/share/se3/sbin/groupAddUser.pl $uid $cours_gr[$loop]" ,$AllOutPut,$ReturnValue);
./add_user_group.php:          	exec("/usr/share/se3/sbin/groupAddUser.pl $uid $equipe_gr[$loop]" ,$AllOutPut,$ReturnValue);
./add_user_group.php:          	exec("/usr/share/se3/sbin/groupAddUser.pl $uid $autres_gr[$loop]" ,$AllOutPut,$ReturnValue);
./people.php:					exec ("/usr/share/se3/sbin/getUserProfileInfo.pl $user[uid]",$AllOutPut,$ReturnValue);
./people.php:  					exec ("/usr/share/se3/sbin/getUserProfileInfo.pl $user[uid]",$AllOutPut,$ReturnValue);
./people.php:  					exec ("/usr/share/se3/sbin/getUserProfileInfo.pl $user[uid]",$AllOutPut,$ReturnValue);
./delete_right.php:             exec ("/usr/share/se3/sbin/groupDelEntry.pl \"$persDn\" \"$pDn\"");
./del_group_user.php:          	exec ("/usr/share/se3/sbin/groupDelUser.pl $uid $members[$loop] ",$AllOutPut,$ReturnValue);
./add_group.php:        			exec ("/usr/share/se3/sbin/groupAdd.pl $groupType $cn \"$description\"",$AllOutPut,$ReturnValue);
*/

require_once ("crob_ldap_functions.php");
/*
	Fonctions de crob_ldap_functions.php utilisées dans samba-tool.inc.php
	useradd() -> creer_cn()
*/

function sambatool ($command) {
	
	global $ldap_server;
	
	exec ("/usr/bin/samba-tool $command -k yes -H ldap://$ldap_server", $RET);
	return $RET;
}	


function userexist ($cn) {
	/*
	Return true if user exist false if not exist
	*/
	$command = "user list";
	$RES = sambatool ($command); 
	$key = array_search($cn, $RES);
	if ( !empty($key) ) return true; else return false;
}	


function useradd ($prenom, $nom, $userpwd, $naissance, $sexe, $categorie, $employeeNumber) {
	/*
	$sexe : M ou F
	$categorie : Eleves ou Profs ou Administratifs
	$naissance : AAAAMMJJ
	
	Return $cn if succes.
	*/
	
	global $ldap_server, $sedomainename, $cnpolicy;
	
	# Penser à utiliser escapeshellarg pour les données provenant d'une saisie utilisateur : nom, prenom...
	
	# Il faut determiner le login (attribut cn : use-username-as-cn) en fonction du nom prenom de l'uidpolicy...
	#$cn=strtolower("$prenom.$nom"); // Pour l'instant
	$cn=creer_cn($nom,$prenom);
	# Si $cn existe déja dans l'AD  (doublon) il faut en fabriquer un autre
	
	$office="$naissance,$sexe";
	
    if (!isset($userpwd)) {
        $userpwd = $naissance;
    }

    if (empty($employeeNumber)) {
        # Pas de champ job-title pour employeeNumber dans ce cas
        $command = "user create '$cn' '$userpwd' --use-username-as-cn --given-name='$prenom' --surname='$nom' --mail-address='$cn@$sedomainename' --physical-delivery-office='$office'";
    } else {
        $command = "user create '$cn' '$userpwd' --use-username-as-cn --given-name='$prenom' --surname='$nom' --mail-address='$cn@$sedomainename' --job-title='$employeeNumber' --physical-delivery-office='$office'";
    }

    $RES= sambatool ( $command );
    
    if ( count($RES) == 1 ) {
    	$newcn = explode("'", $RES[0]);
    	return $newcn[1];
    } 			
									
}


function userdel ($cn) { 
	/*
	Return true if userdel succes false if userdel fail
	*/	
	if ( userexist($cn) ) {
		$command = "user delete '$cn'";
		$RES = sambatool ($command); 
		return true;
	} else return false;
	
}	


function ouadd ($ou) {

}	

function groupadd ($cn, $description) {
	
}	

function groupdel ($cn) {

}	


?>