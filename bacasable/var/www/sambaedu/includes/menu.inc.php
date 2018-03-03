<?php

   /**
   * Affiche le menu en appelant les includes de menu.d

   * @Version $Id  menu.inc.php 2647 2007-12-23 17:50:08Z plouf $

   * @Projet LCS / SambaEdu

   * @Auteurs Equipe TICE CRDP de caen
   * @auteurs wawa - crob - keyser - plouf

   * @Note Appelle

   * @Licence Distribue sous la licence GPL
   */

   /**

   * file: menu.inc.php
   * @Repertoire: includes/
   */


include "ldap.inc.php";

    // Fin Recherche de la nature mono ou multi serveur de la plateforme SE3
    //smono_srv= mono_srv();
    $mono_srv = true;// en attendant la modif de seach_machines
    //$menu_fond_ecran=$config["menu_fond_ecran"];
    $menu_unattended=$config["unattended"];

$liens=array(0
    );
    exec("ls /var/www/sambaedu/includes/menu.d/*.inc",$files,$return);
    for ($i=0; $i< count($files); $i++) {

   	if ($files[$i] == "/var/www/sambaedu/includes/menu.d/50ressources.inc") {
		if ($mono_srv == "true") {
    			include ($files[$i]);
		}

   	} elseif ($files[$i] == "/var/www/sambaedu/includes/menu.d/51ressources.inc") {
		if ($multi_srv == "true") {
    			include ($files[$i]);
		}

   	} elseif ($files[$i] == "/var/www/sambaedu/includes/menu.d/95sauvegarde.inc") {
		//if (($backuppc == "1") || ($savbandactiv == "1")) {
    			include ($files[$i]);
		//}

	} elseif ($files[$i] == "/var/www/sambaedu/includes/menu.d/90inventaire.inc") {
		if ($inventaire == "1") {
    			include ($files[$i]);
		}

	} elseif ($files[$i] == "/var/www/sambaedu/includes/menu.d/75secu.inc") {
		if ($antivirus == "1") {
    			include ($files[$i]);
		}

	} elseif ($files[$i] == "/var/www/se3/includes/menu.d/97dhcp.inc") {
		if ($dhcp == "1") {
    			include ($files[$i]);
		}

	} elseif ($files[$i] == "/var/www/sambaedu/includes/menu.d/98wpkg.inc") {
		if ($wpkg == "1") {
    			include ($files[$i]);
		}

	} else {
    		include ($files[$i]);
	}
    }

?>
