<?php


   /**

   * Liste les  groupes
   * @Version $Id$

   * @Projet LCS / SambaEdu

   * @auteurs jLCF jean-luc.chretien@tice.ac-caen.fr
   * @auteurs oluve olivier.le_monnier@crdp.ac-caen.fr
   * @auteurs wawa  olivier.lecluse@crdp.ac-caen.fr
   * @auteurs Equipe Tice academie de Caen

   * @Licence Distribue selon les termes de la licence GPL

   * @note
   */

   /**

   * @Repertoire: annu
   * file: grouplist_csv.php
   */



//====================================
// Portion de code correspondant a la partie entete.inc.php sans l'affichage HTML

@session_start();
$_SESSION["pageaide"]="Table_des_mati&#232;res";

require ("config.inc.php");
require_once ("functions.inc.php");

require_once ("lang.inc.php");
bindtextdomain('se3-core',"/var/www/se3/locale");
textdomain ('se3-core');

// HTMLPurifier
require_once ("traitement_data.inc.php");

$login=isauth();


// Prise en compte de la page demandee initialement - leb 25/6/2005
if ($login == "") {
	//	header("Location:$urlauth");
	$request = $PHP_SELF;
	if ( $_SERVER['QUERY_STRING'] != "") $request .= "?".$_SERVER['QUERY_STRING'];
	echo "<script language=\"JavaScript\" type=\"text/javascript\">\n<!--\n";
	echo "top.location.href = '$urlauth?request=" . rawurlencode($request) . "';\n";
	echo "//-->\n</script>\n";
} else {
//====================================
	//include "entete.inc.php";
	include "ldap.inc.php";
	include "ihm.inc.php";

	/*
	require_once ("lang.inc.php");
	bindtextdomain('se3-annu',"/var/www/se3/locale");
	textdomain ('se3-annu');

	// Aide
	$_SESSION["pageaide"]="Annuaire";
	*/

	$filter=$_GET['filter'];

	if ((is_admin("Annu_is_admin",$login)=="Y") || (is_admin("sovajon_is_admin",$login)=="Y")) {


	require ("crob_ldap_functions.php");
	//crob_init();

	//==============================================
	function search_people_groups2 ($cns,$filter,$order) {


		/**

		* Recherche des utilisateurs dans la branche people a partir d'un tableau d'cns nons tries
		* Function: search_people_groups2


		* @Parametres 	$order - "cat"   => Tri par categorie (Eleves, Equipe...) - "group" => Tri par intitule de group (ex: 1GEA, TGEA...)
		* @Parametres $cns - Tableau d'cns d'utilisateurs
		* @Parametres $filter - Filtre de recherche

		* @Return Retourne un tableau des utilisateurs repondant au filtre de recherche
		*/

		// Fonction modifeie pour recueprer aussi le mail

		global $ldap_server, $ldap_port, $dn;
		global $error;
		$error="";

		// LDAP attributs
		$ldap_user_attr = array(
				"cn",                 // Nom complet
				"sn",                 // Nom
				"gecos",            // Nom prenom (cn sans accents), Date de naissance,Sexe (F/M),Status administrateur LCS (Y/N)
				"sexe",
				"mail"
		);

		if (!$filter) $filter="(sn=*)";
		$ds = @ldap_connect ( $ldap_server, $ldap_port );
		if ( $ds ) {
			$r = @ldap_bind ( $ds ); // Bind anonyme
			if ($r) {
				$loop1=0;
				for ($loop=0; $loop < count($cns); $loop++) {

					//foreach($cns[$loop] as $key => $value){
					//	echo "\$cns[$loop][$key]=".$cns[$loop][$key]."<br />\n";
					//}
					/*
					// On recupere des:
						$cns[0][prof]=0
						$cns[0][cn]=chabotf
						$cns[0][group]=3_B2
						$cns[0][cat]=Classe
					*/

					$result = @ldap_read ( $ds, "cn=".$cns[$loop]["cn"].",".$dn["people"], $filter, $ldap_user_attr );
					if ($result) {
						$info = @ldap_get_entries ( $ds, $result );
						if ( $info["count"]) {

							// Ajout pour r&#233;cup&#233;rer le mail:
							$attribut_tmp=array("mail");
							$tabtmp=get_tab_attribut("people", "cn=".$cns[$loop]["cn"], $attribut_tmp);
							$cns[$loop]["mail"]=$tabtmp[0];

							// traitement du gecos pour identification du sexe
							$gecos = $info[0]["gecos"][0];
							$tmp = preg_split ("/[\,]/",$gecos,4);
							#echo "debug ".$info["count"]." init ".$init." loop ".$loop."<BR>";
							$ret[$loop1] = array (
								"cn"           => $cns[$loop]["cn"],
								"fullname"      => utf8_decode($info[0]["cn"][0]),
								"name"          => utf8_decode($info[0]["sn"][0]),
								"sexe"          => $tmp[2],
								"owner"         => $cns[$loop]["owner"],
								"group"         => $cns[$loop]["group"],
								"cat"           => $cns[$loop]["cat"],
								"gecos"         => $gecos,
								"prof"          => $cns[$loop]["prof"],
								"mail"          => $cns[$loop]["mail"]
							);

							/*
							foreach($ret[$loop1] as $key => $value){
								echo "\$ret[$loop1][$key]=".$ret[$loop1][$key]."<br />\n";
							}
							*/

							$loop1++;
						}

						@ldap_free_result ( $result );
					}
				}
			} else {
				$error = gettext("Echec du bind anonyme");
			}

			@ldap_close ( $ds );
		} else $error = gettext("Erreur de connection au serveur LDAP");


		if (count($ret)) {
			# Correction tri du tableau
			# Tri par critere categorie ou intitule de groupe
			if ( $order == "cat" ) usort ($ret, "cmp_cat");
			elseif ( $order == "group" ) usort ($ret, "cmp_group");
			# Recherche du nombre de catgories ou d'intitules de groupe
			$i = 0;
			for ( $loop=0; $loop < count($ret); $loop++) {
				if ( $ret[$loop][$order] != $ret[$loop-1][$order]) {
					$tab_order[$i] = $ret[$loop][$order];
					$i++;
				}
			}

			if (count($tab_order) > 0 ) {
				# On decoupe le tableau $ret en autant de sous tableaux $tmp que de criteres $order
				for ($i=0; $i < count($tab_order); $i++) {
					$j=0;
					for ( $loop=0; $loop < count($ret); $loop++) {
						if ( $ret[$loop][$order] == $tab_order[$i] ) {
							$ret_tmp[$i][$j] = $ret[$loop];
							$j++;
						}
					}
				}

				# Tri alpabetique des sous tableaux
				for ( $loop=0; $loop < count($ret_tmp); $loop++) usort ($ret_tmp[$loop], "cmp_name");

				# Reassemblage des tableaux temporaires
				$ret_final = array();
				for ($loop=0; $loop < count($tab_order); $loop++)  $ret_final = array_merge ($ret_final, $ret_tmp[$loop]);
				return $ret_final;
			} else {
				usort ($ret, "cmp_name");
				return $ret;
			}
		}
	}
	//==============================================


		$group=search_groups ("(cn=".$filter.")");
		$cns = search_cns ("(cn=".$filter.")");
		//$people = search_people_groups ($cns,"(sn=*)","cat");
		$people = search_people_groups2 ($cns,"(sn=*)","cat");
		#$TimeStamp_1=microtime();
		#############
		# DEBUG     #
		#############
		#echo "<u>debug</u> :Temps de recherche = ".duree($TimeStamp_0,$TimeStamp_1)."&nbsp;s<BR><BR>";
		#############
		# Fin DEBUG #
		#############
		if (count($people)) {

			//$nom_fic = "nom_du_groupe.csv";
			$nom_fic = "$filter.csv";
			$now = gmdate('D, d M Y H:i:s') . ' GMT';
			header('Content-Type: text/x-csv');
			header('Expires: ' . $now);
			// lem9 & loic1: IE need specific headers
			if (preg_match('/MSIE/', $_SERVER['HTTP_USER_AGENT'])) {
				header('Content-Disposition: inline; filename="' . $nom_fic . '"');
				header('Cache-Control: must-revalidate, post-check=0, pre-check=0');
				header('Pragma: public');
			} else {
				header('Content-Disposition: attachment; filename="' . $nom_fic . '"');
				header('Pragma: no-cache');
			}

			//$contenu_fichier='';
			$contenu_fichier="Login;Nom complet;Nom;Prenom;Naissance;Sexe;Email\n";

			for ($loop=0; $loop < count($people); $loop++) {
				preg_match("/([0-9]{8})/",$people[$loop]["gecos"],$naiss);
				$contenu_fichier.=$people[$loop]["cn"].";".$people[$loop]["fullname"].";".$people[$loop]["name"].";".getprenom($people[$loop]["fullname"],$people[$loop]["name"]).";".$naiss[0].";".$people[$loop]["sexe"].";".$people[$loop]["mail"]."\n";
			}
			echo $contenu_fichier;
		} else {
			include "entete.inc.php";
			echo " <STRONG>".gettext("Pas de membres")." </STRONG> ".gettext(" dans le groupe")." $filter.<BR>";
			include ("pdp.inc.php");
		}
	}
}
?>
