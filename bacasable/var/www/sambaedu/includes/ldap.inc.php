<?php

/**
 * Fonctions LDAP

 * @Version $Id$

 * @Projet LCS / SambaEdu

 * @Auteurs Equipe Tice academie de Caen
 * @Auteurs jLCF jean-luc.chretien@tice.ac-caen.fr

 * @Note: Ce fichier de fonction doit etre appele par un include

 * @Licence Distribue sous la licence GPL
 */
/**

 * file: ldap.inc.php
 * @Repertoire: includes/
 */
require_once ("lang.inc.php");
bindtextdomain('sambaedu-core', "/var/www/sambaedu/locale");
textdomain('sambaedu-core');

// Pour activer/desactiver la modification du givenName (Prenom) lors de la modification dans annu/mod_user_entry.php
$corriger_givenname_si_diff = "n";

//fonctions validées se4

function search_machines($filter, $branch) {

    /**
     * Recherche de machines dans l'ou $branch

     * @Parametres $filter - Un filtre de recherche permettant l'extraction de l'annuaire des machines
     * @Parametres $branch - L'ou correspondant a l'ou contenant les machines

     * @Return 	Retourne un tableau avec les machines
     */
   global $ldap_server, $ldap_port, $adminDn, $adminPw, $dn;

    global $error;

    // Initialisation
    $computers=array();

    // LDAP attributs
    if ("$branch" == "computers")
        $ldap_computer_attr = array(
            "cn", //nom d'origine
            "displayname", // Nom netbios avec $
            "dnshostname", // FDQN
            "location", // Emplacement
            "description"        // Description de la machine
        );
    else
        $ldap_computer_attr = array(
            "cn"
        );

    $ds = @ldap_connect ("ldaps://".$ldap_server, $ldap_port);
    if ($ds) {
        $r = @ldap_bind ( $ds, $adminDn, $adminPw ); // bind as administrator
        if ($r) {
            $result = @ldap_list($ds, $dn[$branch], $filter, $ldap_computer_attr);
            @ldap_sort($ds, $result, "cn");
            if ($result) {
                $info = ldap_get_entries($ds, $result);
                if ($info["count"]) {
                    for ($loop = 0; $loop < $info["count"]; $loop++) {
                        $computers[$loop]["cn"] = $info[$loop]["cn"][0];
                        if ("$branch" == "computers") {
                            $computers[$loop]["displayname"] = $info[$loop]["displayname"][0];
                            if(isset($info[$loop]["dnshostname"][0])) {$computers[$loop]["dnshostname"] = $info[$loop]["dnshostname"][0];}
                            if(isset($info[$loop]["location"][0])) {$computers[$loop]["location"] = $info[$loop]["location"][0];}
                            if(isset($info[$loop]["description"][0])) {$computers[$loop]["description"] = utf8_decode($info[$loop]["description"][0]);}
                        }
                    }
                }

                @ldap_free_result($result);
            }
        }

        @ldap_close($ds);
    }

    return $computers;
}



    ?>
