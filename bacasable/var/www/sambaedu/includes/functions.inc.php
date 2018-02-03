<?php

   /**
   * Librairie de fonctions utilisees dans l'interface d'administration

   * @Version $Id: functions.inc.php 9186 2016-02-21 01:02:50Z keyser $

   * @Projet  SambaEdu

   * @Note: Ce fichier de fonction doit etre appele par un include

   * @Licence Distribue sous la licence GPL
   */

   /**

   * file: functions.inc.php
   * @Repertoire: includes/
   */

//=================================================

/**
* Verification du couple login / mot de passe d'un utilisateur

* @Parametres
* @Return  true si le mot de passe est valide, false dans les autres cas
* @Modif pour AD SMB4
*/

function user_valid_passwd ( $login, $password ) {
  global $ldap_server, $ldap_port, $dn;
  $ret = false;

  $ds = @ldap_connect ( "ldaps://".$ldap_server, $ldap_port );
  if ( $ds ) {
    $r = @ldap_bind ( $ds,"cn=".$login.",".$dn["people"] , $password );
    if ( $r ) {
                $ret = true;
    } else $error = gettext("Echec de l'Authentification.");
    @ldap_unbind ($ds);
    @ldap_close ($ds);
  } else $error = gettext("Erreur de connection au serveur AD");
  return $ret;
}


function isauth()
{
    /* Teste si une authentification est faite
                - Si non, renvoie ""
                - Si oui, renvoie l'uid de la personne
    */

    $login="";
    session_name("Sambaedu");
    @session_start();
    $login= (isset($_SESSION['login'])?$_SESSION['login']:"");
    return $login;
}

function open_session($login, $passwd,$al)
{
    global $urlauth, $authlink, $secook;
    global  $dbhost, $dbuser, $dbpass, $autologon, $REMOTE_ADDR;
    global $MsgError,$logpath,$defaultintlevel,$smbversion;

    $res=0;
    $loginauto="";

    // Initialisation
    $auth_ldap=0;

    if (($al!=1)&&("$autologon"=="1")){
		$logintstsecu=exec("sudo smbstatus -p | grep \"".$_SERVER['REMOTE_ADDR']."\" | grep -v root | grep -v nobody | grep -v adminse3  | grep -v unattend | wc -l");
		if ("$logintstsecu" == "1") {
			$loginauto=exec("sudo smbstatus -p |gawk '{if ($5==\"(".$_SERVER['REMOTE_ADDR'].")\") if ( ! index(\" root nobody unattend adminse3 \", \" \" $2 \" \")) {print $2;exit}}'");
		}

        # echo $loginauto . " __ smbstatus | grep $REMOTE_ADDR | grep home\  | head -n 1 | gawk -F' ' '{print $2}'";
        //$loginauto=exec("smbstatus | grep \"".$REMOTE_ADDR ."\" | head -n 1 | gawk -F' ' '{print $2}'");
        if ("$loginauto" != "") {
            $auth_ldap=1;
            $login=$loginauto;
        }
        //echo "-->";
    }

    if ($auth_ldap!=1) {
                        // decryptage du mot de passe
                        list ($passwd, $error,$ip_src,$timetotal) = decode_pass($passwd);
                        //echo $passwd;///exit;
                        // Si le decodage ne comporte pas d'erreur
                        if (!$error) {
                                $auth_ldap = user_valid_passwd ( $login ,  $passwd);
                                if (!$auth_ldap) $error=4;
                        }
                        if ($error) {
                                // Log en cas d'echec
                                $fp=fopen($logpath."auth.log","a");
                                if($fp) {
                                        fputs($fp,"[".$MsgError[$error]."] ".date("j/m/y:H:i")."|ip requete : ".$ip_src."|remote ip : ".remote_ip()."|Login : ".$login."|TimeStamp srv : ".time()."|TimeTotal : ".$timetotal."\n");
                                        fclose($fp);
                                }
                        }
    }
    if ($auth_ldap) {
    session_name("Sambaedu");
    @session_start();
    $_SESSION['login']=$login;
    $res=1;
    }
    return $res;
}


//=================================================

/**
* Ferme la session en cours

* @Parametres
* @Return
*/

function close_session()
{
    //Destruction session php Sambaedu
    session_name("Sambaedu");
    @session_start();
    // On detruit toutes les variables de session
    $_SESSION = array();
    // On detruit la session sur le serveur.
    session_destroy();
    // Destruction du cookie de session
    setcookie("Sambaedu", "", time() - 3600, "/", "", 0);
}


/**
* Recherche si $nom est present dans le droit $type

* @Parametres
* @Return
*/

function ldap_get_right_search ($type,$search_filter,$ldap)
{
    global $dn,$login;
    $ret="N";
    $typearr=explode("|","$type");
    $i=0;
    while (($ret=="N") and ($i < count($typearr))) {
      $base_search="cn=".$typearr[$i]."," . $dn["rights"];
      $search_attributes=array("cn");
      $result = ldap_read($ldap, $base_search, $search_filter, $search_attributes);
      if ($result) {
        if (ldap_count_entries ($ldap,$result) == 1) $ret="Y";
        ldap_free_result($result);
      } else {
    	// Analyse pour les membres d'un groupe
    	// jLCF 18 > A quoi sert cette section ?
        $base_search="cn=".$typearr[$i]."," . $dn["groups"];
        $result = @ldap_read($ldap, $base_search, "cn=$login", $search_attributes);
        if ($result) {
          if (ldap_count_entries ($ldap,$result) == 1) $ret="Y";
          ldap_free_result($result);
        }
      }
      $i++;
  }
    return $ret;
}




/**
* Determine si $login a le droit $type

* @Parametres
* @Return
*/


function ldap_get_right($type,$login)
{
    global $ldap_server, $ldap_port, $adminDn, $adminPw, $dn;

    $nom="cn=" . $login . "," . $dn["people"];

    $ret="N";

    $ldap = ldap_connect ("ldaps://".$ldap_server, $ldap_port);
    if ( !$ldap ) {
        echo "Error connecting to LDAP server";
    } else {
        if ( $adminDn != "")
            $r = ldap_bind ( $ldap, $adminDn, $adminPw );     // bind as administrator
        else
            $r = ldap_bind ( $ldap ); // bind as anonymous

        if (!$r)
            echo "Invalid Admin's login for LDAP Server";
        else {
            // Recherche du nom exact
            $search_filter = "(member=$nom)";
            //$ret=ldap_get_right_search ($type,$search_filter,$ldap,$base_search);
            $ret=ldap_get_right_search ($type,$search_filter,$ldap);
/*
            if ($ret=="N") {
            // Recherche sur les Posixgroups d'appartenance
                $result1 = @ldap_list ( $ldap, $dn["groups"], "memberUid=$login", array ("cn") );
                if ($result1) {
                $info = @ldap_get_entries ( $ldap, $result1 );
                   if ( $info["count"]) {
                    $loop=0;
                    while (($loop < $info["count"]) && ($ret=="N")){
                        $search_filter = "(member=cn=".$info[$loop]["cn"][0].",".$dn["groups"].")";
                        //$ret=ldap_get_right_search ($type,$search_filter,$ldap,$base_search,$search_attributes);
                        $ret=ldap_get_right_search ($type,$search_filter,$ldap);
                        $loop++;
                    }
                }
                @ldap_free_result ( $result1 );
                }
            }
*/
            #if ($ret=="N") {
            // Recherche sur les GroupsOfNames d'appartenance
                $result1 = @ldap_list ( $ldap, $dn["groups"], "member=cn=$login,".$dn["people"], array ("cn") );
                if ($result1) {
                	$info = @ldap_get_entries ( $ldap, $result1 );
              		if ( $info["count"]) {
                    	$loop=0;
                    	while (($loop < $info["count"]) && ($ret=="N")){
                        		$search_filter = "(member=cn=".$info[$loop]["cn"][0].",".$dn["groups"].")";
                        		//$ret=ldap_get_right_search ($type,$search_filter,$ldap,$base_search,$search_attributes);
                        		$ret=ldap_get_right_search ($type,$search_filter,$ldap);
                        		$loop++;
                    	}
                	}
                	@ldap_free_result ( $result1 );
                }
            #}
        }
    	ldap_close ($ldap);
    }
    return $ret;
}


?>