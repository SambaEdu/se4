<?php

   /**
   
   * Ajoute des utilisateurs aux groupes dans l'annuaire
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
   * file: add_list_users_group.php
   */

  
  
  include "entete.inc.php";
  include "ldap.inc.php";
  include "ihm.inc.php";

  require_once ("lang.inc.php");
  bindtextdomain('se3-annu',"/var/www/se3/locale");
  textdomain ('se3-annu');
      
  // Aide
  $_SESSION["pageaide"]="Annuaire";
  
  echo "<h1>".gettext("Annuaire")."</h1>";

  $cn=$_POST['cn'];
  if ($cn=="") { $cn=$_GET['cn']; }
  $new_cns=$_POST['new_cns'];
  $add_list_users_group=$_POST['add_list_users_group'];

  if (is_admin("Annu_is_admin",$login)=="Y") {

  	$filter="8_".$cn;	
	aff_trailer ("$filter");
    	if ( !$add_list_users_group ) {
      		echo "<H4>".gettext("Ajouter des membres au groupe :")." $cn</H4>\n";
      		// cas d'un groupe de type Equipe
      		if ( preg_match ("#Equipe_#", $cn) ) {
        		// Recherche de la liste des cn  des membres de ce groupe
        		$cns_act = search_cns ("(cn=$cn)");
        		// Reherche de la liste des professeurs
        		$cns_profs = search_cns ("(cn=Profs)");
        		// Constitution d'un tableau excluant les membres actuels
        		$k=0;
        		for ($i=0; $i < count($cns_profs); $i++ ) {
            			for ($j=0; $j < count($cns_act); $j++ ) {
              				if ( $cns_profs[$i]["cn"] == $cns_act[$j]["cn"] )  {
                				$exist = true;
                				break;
              				} else { $exist = false; }
            			}
            			if (!$exist) {
              				$cns_new_members[$k]["cn"] = $cns_profs[$i]["cn"];
              				$k++;
            			}
        		}
         		$people_new_members=search_people_groups ($cns_new_members,"(sn=*)","cat");
      		} elseif   ( preg_match ("#Classe_#", $cn) ) {
        		// Recherche de la liste des Eleves appartenant a une classe
        		$cns_eleves_classes =   search_cns ("(cn=Classe_*)");
        		##DEBUG
        		#echo "Eleves Classes>".  count($cns_eleves_classes)."<BR>";
        		#for ($i=0; $i < count($cns_eleves_classes ); $i++ ) {
        		#echo $cns_eleves_classes[$i]["cn"]."<BR>";
        		#}
        		##DEBUG
        		// Recherche de la liste des Eleves
        		$cns_eleves = search_cns ("(cn=Eleves)");
        		##DEBUG
        		#echo "Eleves >".  count($cns_eleves)."<BR>";
        		#for ($i=0; $i < count($cns_eleves); $i++ ) {
        		#echo $cns_eleves[$i]["cn"]."<BR>";
        		#}
        		##DEBUG
        		// Recherche des Eleves qui ne sont pas affectes a une classe
        		$k=0;
        		for ($i=0; $i < count($cns_eleves); $i++ ) {
        	  		$affect = false;
          			for ($j=0; $j < count($cns_eleves_classes); $j++ ) {
            				if ( $cns_eleves[$i]["cn"] == $cns_eleves_classes[$j]["cn"] ) {
              					$affect = true;
              					break;
            				}
          			}
            			if ($affect==false )  {
                			$cns_eleves_no_affect[$k]["cn"]=$cns_eleves[$i]["cn"];
                			$k++;
            			}
        		}
        		$people_new_members = search_people_groups ($cns_eleves_no_affect,"(sn=*)","cat");
        		##DEBUG
        		#echo "---->".  count($cns_eleves_no_affect)."<BR>";
        		#for ($i=0; $i < count($cns_eleves_no_affect); $i++ ) {
        		# echo $cns_eleves_no_affect[$i]["cn"]."<BR>";
        		# echo $people_new_members[$i]["fullname"]."<BR>";
        		#}
        		##DEBUG
      		}
      		
		// Affichage de la liste dans une boite de selection
      		if   ( count($people_new_members)>15) $size=15; else $size=count($people_new_members);
      		if ( count($people_new_members)>0) {
        		$form = "<form action=\"add_list_users_group.php\" method=\"post\">\n";
        		$form.="<p>".gettext("S&#233;lectionnez les membres &#224; ajouter au groupe :")."</p>\n";
        		$form.="<p><select size=\"".$size."\" name=\"new_cns[]\" multiple=\"multiple\">\n";
        		echo $form;
        		for ($loop=0; $loop < count($people_new_members); $loop++) {
          			echo "<option value=".$people_new_members[$loop]["cn"].">".$people_new_members[$loop]["fullname"];
         		}
        		$form="</select></p>\n";
        		$form.="<input type=\"hidden\" name=\"cn\" value=\"$cn\">\n";
        		$form.="<input type=\"hidden\" name=\"add_list_users_group\" value=\"true\">\n";
        		$form.="<input type=\"reset\" value=\"".gettext("R&#233;initialiser la s&#233;lection")."\">\n";
        		$form.="<input type=\"submit\" value=\"".gettext("Valider")."\">\n";
        		$form.="</form>\n";
        		echo $form;
      		} else {
        		echo "<font color=\"orange\">".gettext("Vous ne pouvez pas ajouter d'&#233;l&#232;ves car il n'existe plus d'&#233;l&#232;ves non affect&#233;s &#224; des classes !!")."</font><BR>";
      		}
    	}   else {
      		// Ajout des membres au groupe
       		echo "<H4>".gettext("Ajout des membres au groupe :")." <A href=\"group.php?filter=$cn\">$cn</A></H4>\n";
       		for ($loop=0; $loop < count ($new_cns) ; $loop++) {
          		exec("/usr/share/se3/sbin/groupAddUser.pl  $new_cns[$loop] $cn" ,$AllOutPut,$ReturnValue);
          		echo  gettext("Ajout de l'utilisateur")."&nbsp;".$new_cns[$loop]."&nbsp;";
          		if ($ReturnValue == 0 ) {
            			echo "<strong>".gettext("R&#233;ussi")."</strong><BR>";
          		} else { echo "</strong><font color=\"orange\">".gettext("Echec")."</font></strong><BR>"; $err++; }
       		}
    	}
  } else {
  	echo "<div class=error_msg>".gettext("Cette application, n&#233;cessite les droits d'administrateur du serveur LCS !")."</div>";
  }
  
  include ("pdp.inc.php");
?>
