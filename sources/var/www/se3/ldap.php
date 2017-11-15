<?php
 $filter = "(cn=*)";
//  $ds = @ldap_connect ( $ldap_server, $ldap_port );
  $ds = ldap_connect ( 'ldaps://se3.sambaedu3.maison' ) or die ("connexion impossible");
  if ( $ds ) {
 //   $r = @ldap_bind ( $ds, "cn=".$login.",".$dn["people"] , $password );
     ldap_set_option($ds, LDAP_OPT_DEBUG_LEVEL, 7);
     ldap_set_option ( $ds, LDAP_OPT_PROTOCOL_VERSION, 3);
     $r = ldap_bind ( $ds, 'CN=Administrator,CN=users,DC=sambaedu3,DC=maison', 'jahlove' );
     if ( $r ) {
/*      $read_result=@ldap_read ($ds, "cn=".$login.",".$dn["people"], $filter);
      if ($read_result) {
        $entrees = @ldap_get_entries($ds,$read_result);
        if ($entrees[0]["cn"][0]) {
          $ret= true;
        } else {
          $error = gettext("Mot de passe invalide");
        }
      } else {
        $error = gettext("Login invalide");
      }
*/
      echo "OK!<br>";
    } else {
      $error = gettext("L'Authentification a echoue");
    }
    @ldap_unbind ($ds);
    @ldap_close ($ds);
  } else {
    $error = gettext("Erreur de connection au serveur LDAP");
  }
  echo "$error<BR>\n";
?>
