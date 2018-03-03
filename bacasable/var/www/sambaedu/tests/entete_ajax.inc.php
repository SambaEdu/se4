<?php

   /**

   * Include de debut des pages utilsant ajax
   * @Version $Id$
   * @Projet LCS / SambaEdu
   * @auteurs Philippe Chadefaux  MrT
   * @Licence Distribue selon les termes de la licence GPL
   * @note
   * Modifications proposees par Sebastien Tack (MrT)
   * Optimisation du lancement des scripts bash par la technologie asynchrone Ajax.


   */

   /**

   * @Repertoire: /tests/
   * file: entete_ajax.inc.php
   */



session_name("Sambaedu");
@session_start();
$_SESSION["pageaide"]="Table_des_mati&#232;res";

require_once ("config.inc.php");
require_once ("functions.inc.php");

require_once ("lang.inc.php");
bindtextdomain('se4-core',"/var/www/sambaedu/locale");
textdomain ('se4-core');

require_once ("traitement_data.inc.php");

$login=$_SESSION['login'];


// Prise en compte de la page demandee initialement - leb 25/6/2005
if (($login == "") || (ldap_get_right("se3_is_admin",$login)!="Y") )  {
	//	header("Location:$urlauth");
	$request = $_SERVER['PHP_SELF'];
	if ( $_SERVER['QUERY_STRING'] != "") $request .= "?".$_SERVER['QUERY_STRING'];
	echo "<script language=\"JavaScript\" type=\"text/javascript\">\n<!--\n";
	echo "top.location.href = '$urlauth?request=" . rawurlencode($request) . "';\n";
	echo "//-->\n</script>\n";
}
?>
