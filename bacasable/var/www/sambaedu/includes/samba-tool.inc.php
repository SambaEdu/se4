<?php
   /**
   * Librairie de fonctions utilisees dans l'interface d'administration

   * @Version $Id: samba-tool.inc.php  2018-05-04  jlcf $

   * @Projet  SambaEdu

   * @Note: Ce fichier de fonction doit etre appele par un include

   * @Licence Distribue sous la licence GPL
   */

   /**
   * file: samba-tool.inc.php
   * @Repertoire: includes/
   */

//=============================================================
// Ensemble de fonctions destinées à remplacer les scripts sudo perl
// pour les opérations d'écritures dans l'AD SambaEdu


/*
 * function useradd ($prenom, $nom, $userpwd, $naissance, $sexe, $categorie, $employeeNumber) : Return $cn if succes.
 * 
 * function userdel ($cn) : Return true if userdel succes false if userdel fail
 * 
 * function groupadd ($cn, $inou, $description) : Return true if group is create false in other cases
 * 
 * function groupdel ($cn) : Return true if group is delete false in other cases
 * 
 * function groupaddmember ( $cn, $ingroup) : Return true if cn is add in ingroup false in other cases
 * 
 * function groupdelmember ($cn, $ingroup) : Return true if cn is remove of ingroup false in other cases
 * 
 *  A faire si nécessaire :
 * function grouplist ($filter) 
 * function groupaddlistmembers ( $cnlist, $ingroup) 
 * 
 */

//require_once ("crob_ldap_functions.php");
require_once ("/var/www/se3/includes/crob_ldap_functions.php");
/*
    Fonctions de crob_ldap_functions.php utilisées dans samba-tool.inc.php
    useradd() -> creer_cn()
*/

function sambatool ($command) {
    global $ldap_server;
    global $config;
    global $debug;

    if(isset($config['crobLdapTotallyDegraded'])) {
        if($debug=='y') {echo("/usr/bin/samba-tool $command -U Administrator --password=XXXXXXXXXXXX -H ldap://$ldap_server"."\n");}
        exec ("/usr/bin/samba-tool $command -U Administrator --password=".$config['adminPw']." -H ldap://$ldap_server", $RET);
    }
    else {
        if($debug=='y') {echo("/usr/bin/samba-tool $command -k yes -H ldap://$ldap_server"."\n");}
        exec ("/usr/bin/samba-tool $command -k yes -H ldap://$ldap_server", $RET);
    }
    return $RET;
}


function userexist ($cn) {
    /*
    Return true if user exist false if not exist
    */
    global $debug;

    $command = "user list";
    $RES = sambatool ($command); 
    /*
    if(($debug=='y')&&($cn=="clemence.thomas-malou")) {
        echo "<pre>\n";
        print_r($RES);
        echo "</pre>\n";
    }
    */
    $key = array_search($cn, $RES);
    /*
    if(($debug=='y')&&($cn=="clemence.thomas-malou")) {
        echo "<p style='color:red'>\$key = array_search($cn, $RES) = '$key';</p>\n";
    }
    */
    //if (!empty($key)) return true; else return false;
    // Si $key=0, le test retourne false (le premier cn du tableau n'est alors pas trouvé).
    if("$key"!="") return true; else return false;
}


function useradd ($prenom, $nom, $userpwd, $naissance, $sexe, $categorie, $employeeNumber) {

    /*
    $sexe : M ou F
    $categorie : Eleves ou Profs ou Administratifs
    $naissance : AAAAMMJJ
    
    Return $cn if succes.
    */
    
    global $ldap_server, $sedomainename, $cnpolicy;
    global $config;
    global $error;
    global $debug;

    # Penser à utiliser escapeshellarg pour les données provenant d'une saisie utilisateur : nom, prenom...

    // A FAIRE : D'abord chercher si title=$employeeNumber existe sinon on crée plusieurs utilisateurs avec le même title=$employeeNumber
    if($employeeNumber!='') {
        $cn=verif_employeeNumber($employeeNumber);
    }

    if($cn!='') {
        $error='Le compte existe deja pour le numero utilisateur '.$employeeNumber.'.';
    }
    else {
        # Il faut determiner le login (attribut cn : use-username-as-cn) en fonction du nom prenom de l'uidpolicy...
        # Si $cn existe déja dans l'AD  (doublon) il faut en fabriquer un autre
        $cn=creer_cn($nom,$prenom);

        $office="$naissance,$sexe";

        if((!isset($userpwd))||($userpwd=='')) {
            $userpwd = $naissance;
        }

        if($userpwd=='') {
            // la création est refusée par samba-tool si le mot de passe est vide (le mot de passe est alors demandé interactivement)
            $error='Le mot de passe ne peut pas etre vide.';
        }
        else {
            if (empty($employeeNumber)) {
                # Pas de champ job-title pour employeeNumber dans ce cas
                $command = "user create '$cn' '$userpwd' --use-username-as-cn --given-name='$prenom' --surname='$nom' --mail-address='$cn@$sedomainename' --physical-delivery-office='$office'";
                } else {
                $command = "user create '$cn' '$userpwd' --use-username-as-cn --given-name='$prenom' --surname='$nom' --mail-address='$cn@$sedomainename' --job-title='$employeeNumber' --physical-delivery-office='$office'";
            }

            $RES= sambatool ( $command );
            // A revoir !
            if ( count($RES) == 1 ) {

                if($debug=='y') {
                    echo "\n===================================\n";
                    echo "\$RES\n";
                    print_r($RES);
                    echo "\n===================================\n";
                }

                $newcn = explode("'", $RES[0]);
                if($debug=='y') {
                    echo "\n===================================\n";
                    echo "\$newcn\n";
                    print_r($newcn);
                    echo "\n===================================\n";
                }

                if($categorie!='') {
                    if($debug=='y') {
                        if(groupaddmember ($newcn[1], $categorie)) {
                            echo "Succes de l ajout de ".$newcn[1]." au groupe $categorie\n";
                        }
                        else {
                            echo "Echec de l ajout de ".$newcn[1]." au groupe $categorie\n";
                            $error="Echec de l ajout de ".$newcn[1]." au groupe $categorie\n";
                        }
                    }
                    else {
                        if(!groupaddmember ($newcn[1], $categorie)) {
                            $error="Echec de l ajout de ".$newcn[1]." au groupe $categorie\n";
                        }
                    }
                }

                return $newcn[1];
            }
        }
    }
}


function userdel ($cn) { 
    /*
    Return true if userdel succes false if userdel fail
    */    
    if ( userexist($cn) ) {
        $command = "user delete ". escapeshellarg($cn);
        $RES = sambatool ($command); 
        return true;
    } else return false;
    
}


function ouexist($ou, $dn_parent) {

    /*
    * Return true if OU exist false in other cases
    */

    global $ldap_server, $ldap_port;
    global $config;
    global $error;

    $contenu=array("name");
    $ds = ldap_connect("ldaps://".$ldap_server,$ldap_port);
    if ($ds) {
        /*
        ldap_set_option($ds, LDAP_OPT_PROTOCOL_VERSION, 3);
        ldap_set_option($ds, LDAP_OPT_REFERRALS, 0);
        $ret = ldap_sasl_bind($ds, 'null', 'null', 'GSSAPI');
        */
        $ret=crob_bind_ldap($ds);
        if ( $ret ) {
            $r = ldap_search ($ds,$dn_parent,"ou=$ou", $contenu);
            $info = ldap_get_entries($ds, $r);
            if ($info["count"] > 0) { 
                return true; 
            } else {
                return false;
            }    
        } else {
            $error="Echec du bind ldap\n";
            return false;
        }
    } else {
        $error="Impossible de se connecter au serveur LDAP\n";
        return false;
    }
}

function ouadd ($ou, $dn_parent) {

    /*
    * Return true if OU is create or if there already exists else in other cases
    */ 

    global $ldap_server, $ldap_port;
    global $config;
    global $error;

    $ds = ldap_connect("ldaps://".$ldap_server,$ldap_port);;  
    if ($ds) {
        /*
        ldap_set_option($ds, LDAP_OPT_PROTOCOL_VERSION, 3);
        ldap_set_option($ds, LDAP_OPT_REFERRALS, 0);
        $r = ldap_sasl_bind($ds, 'null', 'null', 'GSSAPI');
        */
        $r=crob_bind_ldap($ds);

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
        $error="Impossible de se connecter au serveur LDAP";
        return false;
    }
}


function oudel ($ou, $dn_parent) {
    global $ldap_server, $ldap_port;
    global $config;
    global $error;
    global $debug;

    $ds = ldap_connect("ldaps://".$ldap_server,$ldap_port);;  
    if ($ds) {
        /*
        ldap_set_option($ds, LDAP_OPT_PROTOCOL_VERSION, 3);
        ldap_set_option($ds, LDAP_OPT_REFERRALS, 0);
        $r = ldap_sasl_bind($ds, 'null', 'null', 'GSSAPI');
        */
        $r=crob_bind_ldap($ds);
        
        // On efface le OU
        if($debug=='y') {echo "ldap_delete($ds, \"ou=$ou,\".$dn_parent );\n";}
        $r = ldap_delete($ds, "ou=$ou,".$dn_parent );
        
        ldap_close($ds);
    } else {
        $error="Impossible de se connecter au serveur LDAP\n";
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
    global $config;
    global $error;

    $contenu=array("name");
    $ds = ldap_connect("ldaps://".$ldap_server,$ldap_port);;  
    if ($ds) {
        /*
        ldap_set_option($ds, LDAP_OPT_PROTOCOL_VERSION, 3);
        ldap_set_option($ds, LDAP_OPT_REFERRALS, 0);
        $ret = ldap_sasl_bind($ds, 'null', 'null', 'GSSAPI');
        */
        $ret=crob_bind_ldap($ds);
        if ( $ret ) {
            $r = ldap_search ($ds,$dn["groups"],"cn=$cn", $contenu);
            $info = ldap_get_entries($ds, $r);
            if ($info["count"] > 0) { 
                return true; 
            } else {
                return false;
            }    
        } else {
            $error="Echec du bind ldap\n";
            return false;
        }
    } else {
        $error="Impossible de se connecter au serveur LDAP\n";
        return false;
    }
}

function groupadd ($cn, $inou, $description) {

    global $dn;
    global $debug;
    global $error;

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
    //if ( !empty($cn) && !empty($inou) && !empty($description)) {
    if ( !empty($cn) && !empty($description)) {

        if(empty($inou)) {
            $command="group add ". escapeshellarg($cn) . " --groupou=ou=groups --description=".escapeshellarg($description);
        }
        else {
            // creation du ou si il n'existe pas 
            if ( !ouexist($inou,$dn["groups"]) ) {
                ouadd ($inou, $dn["groups"]);
            }

            $command="group add ". escapeshellarg($cn) . " --groupou=ou=" . escapeshellarg($inou). ",ou=groups --description=".escapeshellarg($description);
        }
        $RES= sambatool ( $command );
 
        if ( count($RES) == 1 ) {
            $group = explode(" ", $RES[0]); 
            if (  $group[2] == $cn ) {
                return true;
            } else { 
                $error="La création du groupe a retourné ".$group[2]." au lieu de ".$cn."\n";
                return false;
            }
        } else { 
            if ( count($RES) == 0 ) {
                $error="La création du groupe n'a rien retourné.\n";
            }
            else {
                $error="La création du groupe a retourné ".count($RES)." réponses (???).\n";
            }
            return false;
        }
        
    } else {
        $error='';
        if(empty($cn)) {
           $error.="Le CN du groupe ne peut pas être vide.\n";
        }
        //if(empty($inou)) {
        //   $error.="L'OU du groupe ne peut pas être vide.\n";
        //}
        if(empty($description)) {
           $error.="La description du groupe ne peut pas être vide.\n";
        }
        return false;
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
    global $error;

    if(groupexist($cn)) {
        $command="group delete ".escapeshellarg($cn);
        $RES= sambatool ( $command );

        if ( count($RES) == 1 ) {
            $group = explode(" ", $RES[0]); 
            if (  $group[2] == $cn ) {
                return true;
            } else { 
                $error='Erreur lors de la suppression du groupe '.$cn."\n";
                return false;
            }
        } else { 
            $error='Erreur lors de la suppression du groupe '.$cn." (count(\$RES)=".count($RES).")\n";
            return false;
        }
    }
    else {
        $error='Erreur lors de la suppression du groupe car le groupe '.$cn." n'existe pas.\n";
        return false;
    }
}

function groupaddmember ( $cn, $ingroup) {
    
    /*
     * Return true if cn is add in ingroup false in other cases
     */
    
    // le cn et le groupe exist ?
    global $error, $debug;

    if($debug=='y') {
        echo "groupaddmember ( $cn, $ingroup)\n";
    }

    if ( userexist ($cn) && groupexist ($ingroup) ) {
        // Ajout du cn in group
        $command="group addmembers ". escapeshellarg($ingroup) ." ". escapeshellarg($cn);
        //if($debug=='y') {echo "command : $command<br />\n";}
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
        if(!userexist ($cn)) {
            $error="Le cn $cn n'existe pas\n";
        }
        if(!groupexist($ingroup)) {
            $error="Le groupe $ingroup n'existe pas\n";
        }

        return false;
    }
}

function groupaddlistmembers ( $cnlist, $ingroup) {

}

function groupdelmember ($cn, $ingroup) {
    
    /*
     * Return true if cn is remove of ingroup false in other cases
     */
    global $error;

    // le cn et le groupe exist ?
    if ( userexist ($cn) && groupexist ($ingroup) ) {
        // Remove du cn in group
        $command="group removemembers ". escapeshellarg($ingroup) ." ". escapeshellarg($cn);
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
        $error='';
        if(!userexist ($cn)) {
            $error.="Le membre $cn n'existe pas.\n";
        }
        if(!groupexist ($ingroup)) {
            $error.="Le groupe $ingroup n'existe pas.\n";
        }
        return false;
    }
}

function is_member_group($cn, $ingroup, $avec_array_groups_members=false) {
    /*
    Return true if user $cn is member of group $ingroup
    */
    global $array_groups_members;

    if($avec_array_groups_members) {
        if((isset($avec_array_groups_members[$ingroup])) {
            if(in_array($cn, $avec_array_groups_members[$ingroup])) {
                return true;
            }
            else {
                return false;
            }
        }
        else {
            $command = "group listmembers ".$ingroup;
            $RES = sambatool ($command); 
            $array_groups_members[$ingroup]=$RES;
            $key = array_search($cn, $RES);
            //if ( !empty($key) ) return true; else return false;
            if("$key"!="") return true; else return false;
        }
    }
    else {
        $command = "group listmembers ".$ingroup;
        $RES = sambatool ($command); 
        $key = array_search($cn, $RES);
        //if ( !empty($key) ) return true; else return false;
        if("$key"!="") return true; else return false;
    }
}

function get_array_group_members($ingroup) {
    /*
    Return array members of group $ingroup
    */
    $command = "group listmembers ".$ingroup;
    $RES = sambatool ($command); 
    return $RES;
}

function get_array_groups($motif) {
    /*
    Retourne un tableau des cn des groupes correspondant au motif $motif
    */
    $command = "group list";
    $RES = sambatool ($command); 

    if($motif=='') {
        return $RES;
    }
    else {
        $tab=array();
        $tmp_tab=explode("|", $motif);
        for($loop=0;$loop<count($RES);$loop++) {
            if(!in_array($RES[$loop], $tab)) {
                for($loop2=0;$loop2<count($tmp_tab);$loop2++) {
                    if(trim($tmp_tab[$loop2])!='') {
                        if(preg_match("/".$tmp_tab[$loop2]."/", $RES[$loop])) {
                            $tab[]=$RES[$loop];
                            break;
                        }
                    }
                }
            }
        }
        return $tab;
    }
}

function vider_group($cn) {
    /*
    Vider le groupe $cn
    */
    global $error;
    $error='';

    $tab=get_array_group_members($cn);
    for($loop=0;$loop<count($tab);$loop++) {
        if(!groupdelmember($tab[$loop], $cn)) {
            $error.="Erreur lors de la suppression de ".$tab[$loop]." du groupe ".$cn."\n";
        }
    }
    if($error=='') {
        return true;
    }
    else {
        return false;
    }
}


function crob_bind_ldap($ds) {
    global $config;
    //global $ds;

    if(!isset($config['crobLdapTotallyDegraded'])) {
        //echo "crobLdapTotallyDegraded=n\n";
        ldap_set_option($ds, LDAP_OPT_PROTOCOL_VERSION, 3);
        ldap_set_option($ds, LDAP_OPT_REFERRALS, 0);
        $r = ldap_sasl_bind($ds, 'null', 'null', 'GSSAPI');
    }
    else {
        /*
        echo "crobLdapTotallyDegraded=y\n";
        echo "\$config['adminRdn']=".$config["adminRdn"]."\n";
        echo "\$config['adminDn']=".$config["adminDn"]."\n";
        echo "\$config['adminPw']=".$config["adminPw"]."\n";
        */
        $r=ldap_bind($ds, $config["adminRdn"], $config["adminPw"]);// Bind admin LDAP
    }
    return $r;
}

?>
