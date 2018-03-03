
<?php

require ("config.inc.php");
require ("functions.inc.php");

echo "ldap_server $ldap_server<br />";
echo "lang : $lang<br />";

#echo "DBG > CN=administrator,CN=users,DC=sambaedu,DC=home<br />";
#echo "adminDN : $adminDn adminPWD : $adminPw<br />";

echo "<b>fonction user_valid_pwd</b> : vérification du couple login/pwd de l'utilisateur<br />";

if (user_valid_passwd ("jchretien", "Bri1lola") )  {
    echo "auth OK<br />";
        echo "<b>On cherche si jchretien possede le droit se_is_admin </b><br />";
        $RES=ldap_get_right("se_is_admin", "jchretien");
        echo "RES : $RES<br />";
} else
    echo "auth NOK<br />";




echo "<b>-----------------------</b><br />";
echo "<b>solution jLCF : on presente login/mdp</b><br />";
$ds = @ldap_connect("ldaps://".$ldap_server, $ldap_port);
if ($ds) {
    $ret = ldap_bind($ds, "CN=jchretien,CN=users,DC=sambaedu,DC=home", "Bri1lola");
    if ( $ret ) {
      echo "L'Authentification a reussie.<br />";
      #exec("kinit -k -t /home/adminse4/adminse4.keytab adminse4@SAMBAEDU.HOME",$Err);
      ldap_unbind ($ds);
    } else {
      echo "L'Authentification a echouee<br />";
    }
}



echo "<b>solution RTFM GSSAPI (on suppose qu'un ticket a été généré) </b><br />";
#$ldap_server='ldap://sambaedu.home';
#$ldap_port="389";

$ds = ldap_connect("ldap://".$ldap_server,$ldap_port);
if ($ds) {
    #ldap_set_option(NULL, LDAP_OPT_DEBUG_LEVEL, 3);
    ldap_set_option($ds, LDAP_OPT_PROTOCOL_VERSION, 3);
    ldap_set_option($ds, LDAP_OPT_REFERRALS, 0);
    $ret = ldap_sasl_bind($ds, 'null', 'null', 'GSSAPI');
    if ( $ret ) {
      echo "L'Authentification a reussie<br />";
    } else {
      echo "L'Authentification a echouee<br />";
    }
}

echo "<b>--------------------</b><br />";
echo "<b>samba-tool user list -k $ldap_server</b><br />";
exec ("samba-tool user list -k yes -H ldap://se4ad.".$ldap_server,$RES);
print_r ($RES);
?>
