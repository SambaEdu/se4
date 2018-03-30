<?php
   /**
   * Librairie de fonctions utilisees dans l'interface d'administration

   * @Version $Id: samba-tool.inc.php  2018-29-03  jlcf $

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
	# Si $cn existe déja dans l'AD  (doublon) il faut en fabriquer un autre
	$cn=creer_cn($nom,$prenom);

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
    // A revoir !
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


function ouexist($ou, $dn_parent) {
    
    /*
    * Return true if OU exist false in other cases
    */
    
    global $ldap_server, $ldap_port;
    
    $contenu=array("name");
    $ds = ldap_connect("ldap://".$ldap_server,$ldap_port);;  
    if ($ds) {
        ldap_set_option($ds, LDAP_OPT_PROTOCOL_VERSION, 3);
        ldap_set_option($ds, LDAP_OPT_REFERRALS, 0);
        $ret = ldap_sasl_bind($ds, 'null', 'null', 'GSSAPI');
        if ( $ret ) {
            $r = ldap_search ($ds,$dn_parent,"ou=$ou", $contenu);
            $info = ldap_get_entries($ds, $r);
            if ($info["count"] > 0) { 
                return true; 
            } else {
                return false;
            }    
        } else {
            echo "Echec du bind sasl";
            return false;
        }
    } else {
        echo "Impossible de se connecter au serveur LDAP";
        return false;
    }        
}

function ouadd ($ou, $dn_parent) {
    
    /*
    * Return true if OU is create or if there already exists else in other cases
    */ 
    
    global $ldap_server, $ldap_port;
    
    $ds = ldap_connect("ldap://".$ldap_server,$ldap_port);;  
    if ($ds) {
        ldap_set_option($ds, LDAP_OPT_PROTOCOL_VERSION, 3);
        ldap_set_option($ds, LDAP_OPT_REFERRALS, 0);
        $r = ldap_sasl_bind($ds, 'null', 'null', 'GSSAPI');

        // Prépare les données
        $info["ou"] = "$ou";
        $info["name"] = "$ou";
        $info["objectclass"] = "top";
        $info["objectclass"] = "organizationalUnit";    

        // Ajoute le OU si il n'existe pas
        if (!ouexist($ou, $dn_parent) ) {
                $r = ldap_add($ds, "ou=$ou," .$dn_parent, $info);
        }
        ldap_close($ds);
        
        if (ouexist($ou, $dn_parent)) { 
            return true;
        } else {
            return false;
        }        
    } else {
        echo "Impossible de se connecter au serveur LDAP";
        return false;
    }
}


function oudel ($ou, $dn_parent) {
    global $ldap_server, $ldap_port;
    
    $ds = ldap_connect("ldap://".$ldap_server,$ldap_port);;  
    if ($ds) {
        ldap_set_option($ds, LDAP_OPT_PROTOCOL_VERSION, 3);
        ldap_set_option($ds, LDAP_OPT_REFERRALS, 0);
        $r = ldap_sasl_bind($ds, 'null', 'null', 'GSSAPI');
        
        // On efface le OU
        
        $r = ldap_delete($ds, "ou=$ou, ".$dn_parent );
        
        ldap_close($ds);
    } else {
        echo "Impossible de se connecter au serveur LDAP";
    }
}        


/*
 * Samba-Tool
 * Available subcommands:
  add            - Creates a new AD group.
  addmembers     - Add members to an AD group.
  delete         - Deletes an AD group.
  list           - List all groups.
  listmembers    - List all members of an AD group.
  removemembers  - Remove members from an AD group.
 */

function grouplist ($filter) {
    
    /*
     * Return a array of cn répondant au critere filter
     */
}

function groupexist ($cn) {
    
    /*
     * Return true if cn group exist
     */
    
    global $ldap_server, $ldap_port, $dn;
    
    $contenu=array("name");
    $ds = ldap_connect("ldap://".$ldap_server,$ldap_port);;  
    if ($ds) {
        ldap_set_option($ds, LDAP_OPT_PROTOCOL_VERSION, 3);
        ldap_set_option($ds, LDAP_OPT_REFERRALS, 0);
        $ret = ldap_sasl_bind($ds, 'null', 'null', 'GSSAPI');
        if ( $ret ) {
            $r = ldap_search ($ds,$dn["groups"],"cn=$cn", $contenu);
            $info = ldap_get_entries($ds, $r);
            if ($info["count"] > 0) { 
                return true; 
            } else {
                return false;
            }    
        } else {
            echo "Echec du bind sasl";
            return false;
        }
    } else {
        echo "Impossible de se connecter au serveur LDAP";
        return false;
    } 
    
}

function groupadd ($cn, $inou, $description) {
    
    global $dn;
    
    /* 
     * Principe :
     * samba-tool group add Classe_TARCU --groupou='ou=2TC,ou=groups' --description="Groupe Classe TARCU"
     * La commande retourne en cas de succes : Added group Classe_TARCU
     */
    
    /*
     * $cn : cn du groupe, exemple Classe_TARCU
     * $inou : ou de destination dans ou=Groups,ou=$inou,cn=$cn 
     * $description : la description du groupe
     */
    
    /*
     * Return true if group is create false in other cases
     */
    if ( !empty($cn) && !empty($inou) && !empty($description)) {
        
        // creation du ou si il n'existe pas 
        if ( !ouexist($inou,$dn["groups"]) ) {
            ouadd ($inou, $dn["groups"]);
        }    
        
        $command="group add $cn --groupou='ou=$inou, ou=groups' --description='$description'";
        $RES= sambatool ( $command );
 
        if ( count($RES) == 1 ) {
            $group = explode(" ", $RES[0]); 
            if (  $group[2] == $cn ) {
                return true;
            } else { 
                return false;
            }
        } else { 
            return false;
        }
        
    } else {
        return fasle;
    }
}	

function groupdel ($cn) {
    
    /*
     * Principe : samba-tool group delete Classe_TARCU
     * La commande retourne en cas de succes  : Deleted group Classe_TARCU
     */
    
    /*
     * $cn : cn du groupe a supprimer
     */
    
    /*
     * Return true if group is delete false in other cases
     */
    
    $command="group delete $cn";
    $RES= sambatool ( $command );
 
    if ( count($RES) == 1 ) {
    	$group = explode(" ", $RES[0]); 
        if (  $group[2] == $cn ) {
            return true;
        } else { 
            return false;
        }
    } else { 
        return false;
    }    	  

}

function groupaddmember ( $cn, $ingroup) {
    
    /*
     * Return true if cn is add in ingroup false in other cases
     */
    
    // le cn et le groupe exist ?
    if ( userexist ($cn) && groupexist ($ingroup) ) {
        // Ajout du cn in group
        $command="group addmembers $ingroup $cn";
        $RES= sambatool ( $command );
        
        if ( count($RES) == 1 ) {
            $ERROR = explode(":", $RES[0]); 
            if (  $ERROR[0] == "ERROR(exception)" ) {
                return false;
            } else { 
                return true;
            }
        } else { 
            return false;
        } 
        
    } else {
        return false;
    }
}

function groupaddlistmembers ( $cnlist, $ingroup) {
        
}

function groupdelmember ($cn, $ingroup) {
    
    /*
     * Return true if cn is remove of ingroup false in other cases
     */
    
    // le cn et le groupe exist ?
    if ( userexist ($cn) && groupexist ($ingroup) ) {
        // Remove du cn in group
        $command="group removemembers $ingroup $cn";
        $RES= sambatool ( $command );
        
        if ( count($RES) == 1 ) {
            $ERROR = explode(":", $RES[0]); 
            if (  $ERROR[0] == "ERROR(exception)" ) {
                return false;
            } else { 
                return true;
            }
        } else { 
            return false;
        } 
        
    } else {
        return false;
    }
}


?>