<?php
/**
 * Fonctions pour mapper les commandes samba-tool AD


 * @Projet SambaEdu

 * @Auteurs Denis Bonnenfant

 * @Note

 * @Licence Distribue sous la licence GPL
 */

/**

* file: samba-tool.inc.php
* @Repertoire: includes/
*/

class Samba_tool {

	private $command;

	private function run(){
		$command = "/usr/bin/samba-tool";
		exec ("$command $this->type , $this->args" );
		
	}
	
	
// gestion des utilisateurs

	public function smb_user_add ($smb_auth, $user, $attrs) {
		$this->run ($user,$attrs);	
	}
}
?>
				