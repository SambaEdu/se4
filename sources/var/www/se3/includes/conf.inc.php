<?php

  /**
  * Lecture des variables de conf

  * @Version $Id: config.inc.php.in 9184 2016-02-21 00:58:01Z keyser $

  * @Projet LCS / SambaEdu

  * @Auteurs Equipe Tice académie de Caen
  * @Auteurs « wawa »  olivier.lecluse@crdp.ac-caen.fr

  * @Note Ce fichier de fonction doit être appelé par un include dans entete.inc.php
  * @Note Ce fichier est complete a l'installation

  * @Licence Distribué sous la licence GPL
  */

   /**

   * file: conf.inc.php
   * @Repertoire: includes/
   */


/*
 * fonction pour récupérer la conf de se4 ou des modules de façon recursive dans /etc/se4/
 * @Parametres : "nom du module", "base" ou "all"
 * @return array["parametre"]
 */

function get_config_se4 ($module = "base") {
	$config=array();
	if ($module == "all") {
		$config = get_config_se4 ("base");
		if (!file_exists ('/etc/se4/se4.conf.d'))
			return (false);
		if ($handle = opendir('/etc/se4/se4.conf.d')) {
			unset ($module);
			while (false !== ($entry = readdir($handle))) {
				if ($entry != "." && $entry != "..") {
					$module = preg_replace ("/\.conf/", "", $entry);
					if (isset($module)) {
						$config = array_merge ($config, get_config_se4 ($module));
					}
				}
			}
			closedir($handle);
		}
		return ($config);
	} elseif ($module == "base") {
		$conf_file = "/etc/se4/se4.conf";
		if (!file_exists ($conf_file))
			return (false);
		$config = parse_ini_file ($conf_file);
		$config['adminDn'] = $config['adminRdn'].",".$config['ldap_base_dn'];
		$config['dn']['people'] = $config['peopleRdn'].",".$config['ldap_base_dn'];
		$config['dn']['groups'] = $config['groupsRdn'].",".$config['ldap_base_dn'];
		$config['dn']['rights'] = $config['rightsRdn'].",".$config['ldap_base_dn'];
		$config['dn']['parcs'] = $config ['parcsRdn'].",".$config['ldap_base_dn'];
		$config['dn']['computers'] = $config['computersRdn'].",".$config['ldap_base_dn'];
		$config['dn']['printers'] = $config['printersRdn'].",".$config['ldap_base_dn'];
		$config['dn']['trash'] = $config['trashRdn'].",".$config['ldap_base_dn'];
		
	} else {
		$conf_file = "/etc/se4/se4.conf.d/$module.conf";
		if (!file_exists ($conf_file))
			return (false);
		$config = parse_ini_file ($conf_file);
	}
	return ($config);
}

/*
 * fonction pour ecrire de se4 ou des modules d
 * @Parametres : "nom du module", parametre, valeur
 * @return succes
 */

function set_config_se4( $param, $valeur, $module = "base") {
	

	$config = get_config_se4 ($module);
	$config[$param] = $valeur;
	foreach($config as $key=>$value){
		$content .= $key."=".$value."\n";
	}
	//write it into file
	if ($module == "base") {
		$conf_file = "/etc/se4/se4.conf";
	} else { 
		$conf_file = "/etc/se4/se4.conf.d/$module.conf";
	}
	
	if (!$handle = fopen($conf_file))
		return false;
	
	$success = fwrite($handle, $content);
	fclose($handle);
	
	return $success;
}

/*
 * fonction pour récupérer la conf de se3 depuis mysql
 * Obsolète, présente pour assurer la transition
 * @Parametres : aucun
 * @return : $config
 */

function get_config_se3 () {
	# Récupération des paramètres de la base de données depuis la conf se3
	include config.inc.php;
	$config['authlink'] = $authlink;
	$config['dbhost'] = $dbhost;
	$config['dbname'] = $dbname;
	$config['dbuser'] = $dbuser;
	$config['dbpass'] = $dbpass;
	
	$config['srv_id'] = $sv_id;
	
	# Paramètres fixes
	
	$config['secook'] = $secook;
	$config['Pool']  = $Pool;
	$config['SessLen'] = $SessLen;
	# Model caracteres speciaux pour les mots de passe
	$config['char_spec'] = $char_spec;
	$config['ldap_login_attr'] = $ldap_login_attr;
	return ($config);	
}

/*
 * fonction pour récupérer la conf dans un tableau persistant 120s
 * @Parametres : [$force = true] pour forçer la lecture
 * @return : $config = tableau des parametres
 */

function get_config ($force = false) {
	while (apc_fetch('config_lock')) {
		sleep(1);
	}
	if (($force) || !($config = apc_fetch('config'))) {
		apc_add('config_lock',1,60);
		
		unset($config);
		$config = get_config_se4 ('all');
		if (!$config) {
			$config = get_config_se3();
		}
		
		apc_add('config', $config, 120);
		apc_delete('config_lock');
		if (!$config) {
			die ("Erreur de lecture de la configuration se4 ou se3");
		}
	}
	return($config);
}


/*
 * fonction pour écrire la conf dans les fichiers de conf
 * retourne le tableau $config et met à jour le cache 
 * @Parametres : parametre a fixer
 * @Parametres : valeur
 * @Parametres : module ( defaut = "base" )
 * @return :  $config ou false
 */

function set_config($param, $value, $module = "base") {

	while (apc_fetch('config_lock')) {
		sleep(1);
	}

	unset($config);
	$config = get_config_se4 ($module);
	$config[$param] = $valeur;
	foreach($config as $key=>$value){
		$content .= $key."=".$value."\n";
	}
	//write it into file
	if ($module == "base") {
		$conf_file = "/etc/se4/se4.conf";
	} else {
		$conf_file = "/etc/se4/se4.conf.d/$module.conf";
	}
	apc_add('config_lock',1,60);
	if (!$handle = fopen($conf_file)) {
		apc_delete('config_lock');
		die ("Erreur d'ecriture de la configuration se4 : $module $param $value");
	}	
	$res = fwrite($handle, $content);
	fclose($handle);
	apc_delete('config_lock');
	if (!$res) 
		die ("Erreur d'ecriture de la configuration se4 : $module $param $value");
	
	return (get_config (true));
}

# Paramètres LDAP
get_config ();

if ($config["version"] <= "4.0") {
	// compatibilité avec se3
	foreach ($config as $key=>$value) {
		${$key} = $value;
	}
	$adminDn      = "$adminRdn,$ldap_base_dn";
	
	# Declaration des «branches» de l'annuaire LCS/SE3 dans un tableau
	$dn = array();
	$dn["people"] = "$peopleRdn,$ldap_base_dn";
	$dn["groups"] = "$groupsRdn,$ldap_base_dn";
	$dn["rights"] = "$rightsRdn,$ldap_base_dn";
	$dn["parcs"] = "$parcsRdn,$ldap_base_dn";
	$dn["computers"] = "$computersRdn,$ldap_base_dn";
	$dn["printers"] = "$printersRdn,$ldap_base_dn";
	$dn["trash"] = "$trashRdn,$ldap_base_dn";
}


$urlauth=$urlse3."/auth.php";

# Gettext

chdir($path_to_wwwse3);
putenv("LANG=$lang");
putenv("LANGUAGE=$lang");
setlocale(LC_ALL, "C");
bindtextdomain("messages","./locale");
textdomain("messages");

?>
