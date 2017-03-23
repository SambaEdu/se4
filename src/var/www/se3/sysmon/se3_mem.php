<!-- Begin Head -->
<?
include 'entete.inc.php';
include 'ldap.inc.php';
include 'ihm.inc.php';
require_once 'lang.inc.php';
bindtextdomain('se3-infos',"/var/www/se3/locale");
textdomain ('se3-infos');

$login=isauth();
if (is_admin("se3_is_admin",$login)!="Y") { exit; }
?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<HTML>
<HEAD>
<TITLE>Monitoring server SE3 Usage memoire serveur se3</TITLE>
<META HTTP-EQUIV="Refresh" CONTENT="300">
<META HTTP-EQUIV="Pragma" CONTENT="no-cache">
<META HTTP-EQUIV="Cache-Control" content="no-cache">
<META HTTP-EQUIV="Expires" CONTENT="Mon, 27 Feb 2017 14:25:08 GMT">
<META HTTP-EQUIV="Generator" CONTENT="MRTG 2.10.13">
<META HTTP-EQUIV="Date" CONTENT="Mon, 27 Feb 2017 14:25:08 GMT">

<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
<!-- maxin d 56 -->
<!-- maxout d 0 -->
<!-- avin d 51 -->
<!-- avout d 0 -->
<!-- cuin d 43 --><!-- cuout d 0 --><!-- maxin w 0 -->
<!-- maxout w 0 -->
<!-- avin w 0 -->
<!-- avout w 0 -->
<!-- maxin m 0 -->
<!-- maxout m 0 -->
<!-- avin m 0 -->
<!-- avout m 0 -->
<!-- maxin y 0 -->
<!-- maxout y 0 -->
<!-- avin y 0 -->
<!-- avout y 0 -->

</HEAD>
<BODY #ffffff>
<H1>Usage memoire serveur se3 </H1> <TABLE> <TR><TD>System:</TD><TD>se3</TD></TR> </TABLE>
<HR>
Les statistiques ont &eacute;t&eacute; mises &agrave; jour le  <B>Lundi 27 F&eacute;vrier  2017  &agrave;  15:20</B>,<BR>
<B>'unknown'</B> &eacute;tait alors en marche depuis  <B>unknown</B>.
<!-- End Head -->
<!-- Begin `Daily' Graph (5 Minute -->
<HR>
<B>Graphique quotidien (sur 5 minutes : Moyenne)</B><BR>
<IMG VSPACE=10 WIDTH=500 HEIGHT=135 ALIGN=TOP 
     SRC="se3_mem-day.png" ALT="day">
 <TABLE CELLPADDING=0 CELLSPACING=0>
<TR>
  <TD ALIGN=right><SMALLMax <FONT COLOR="#00cc00">&nbsp;Mem used:&nbsp;</FONT></SMALL></TD>
  <TD ALIGN=left><SMALL>56.0 %
   </SMALL></TD>
  <TD WIDTH=5></TD>
  <TD ALIGN=right><SMALL>Moyenne <FONT COLOR="#00cc00">&nbsp;Mem used:&nbsp;</FONT></SMALL></TD>
  <TD ALIGN=left><SMALL>51.0 %
  </SMALL></TD>
  <TD WIDTH=5></TD>
  <TD ALIGN=right><SMALL>Actuel <FONT COLOR="#00cc00">&nbsp;Mem used:&nbsp;</FONT></SMALL></TD>
  <TD ALIGN=left><SMALL>43.0 %
  </SMALL></TD>
 </TR>

 <TR>
  <TD ALIGN=right><SMALLMax <FONT COLOR="#0000ff">&nbsp;Swap used:&nbsp;</FONT></SMALL></TD>
  <TD ALIGN=left><SMALL>0.0 %
  </SMALL></TD>
  <TD WIDTH=5></TD>
  <TD ALIGN=right><SMALL>Moyenne <FONT COLOR="#0000ff">&nbsp;Swap used:&nbsp;</FONT></SMALL></TD>
  <TD ALIGN=left><SMALL>0.0 %
  </SMALL></TD>
  <TD WIDTH=5></TD>
  <TD ALIGN=right><SMALL>Actuel <FONT COLOR="#0000ff">&nbsp;Swap used:&nbsp;</FONT></SMALL></TD>
  <TD ALIGN=left><SMALL>0.0 %
 </SMALL></TD>
 </TR> 
</TABLE>
<!-- End `Daily' Graph (5 Minute -->

<!-- Begin `Weekly' Graph (30 Minute -->
<HR>
<B>Graphique hebdomadaire (sur 30 minutes : Moyenne)</B><BR>
<IMG VSPACE=10 WIDTH=500 HEIGHT=135 ALIGN=TOP 
     SRC="se3_mem-week.png" ALT="week">
 <TABLE CELLPADDING=0 CELLSPACING=0>
<TR>
  <TD ALIGN=right><SMALLMax <FONT COLOR="#00cc00">&nbsp;Mem used:&nbsp;</FONT></SMALL></TD>
  <TD ALIGN=left><SMALL>0.0 %
   </SMALL></TD>
  <TD WIDTH=5></TD>
  <TD ALIGN=right><SMALL>Moyenne <FONT COLOR="#00cc00">&nbsp;Mem used:&nbsp;</FONT></SMALL></TD>
  <TD ALIGN=left><SMALL>0.0 %
  </SMALL></TD>
  <TD WIDTH=5></TD>
  <TD ALIGN=right><SMALL>Actuel <FONT COLOR="#00cc00">&nbsp;Mem used:&nbsp;</FONT></SMALL></TD>
  <TD ALIGN=left><SMALL>?????
  </SMALL></TD>
 </TR>

 <TR>
  <TD ALIGN=right><SMALLMax <FONT COLOR="#0000ff">&nbsp;Swap used:&nbsp;</FONT></SMALL></TD>
  <TD ALIGN=left><SMALL>0.0 %
  </SMALL></TD>
  <TD WIDTH=5></TD>
  <TD ALIGN=right><SMALL>Moyenne <FONT COLOR="#0000ff">&nbsp;Swap used:&nbsp;</FONT></SMALL></TD>
  <TD ALIGN=left><SMALL>0.0 %
  </SMALL></TD>
  <TD WIDTH=5></TD>
  <TD ALIGN=right><SMALL>Actuel <FONT COLOR="#0000ff">&nbsp;Swap used:&nbsp;</FONT></SMALL></TD>
  <TD ALIGN=left><SMALL>?????
 </SMALL></TD>
 </TR> 
</TABLE>
<!-- End `Weekly' Graph (30 Minute -->

<!-- Begin `Monthly' Graph (2 Hour -->
<HR>
<B>Graphique mensuel  (sur 2 heures : Moyenne)</B><BR>
<IMG VSPACE=10 WIDTH=500 HEIGHT=135 ALIGN=TOP 
     SRC="se3_mem-month.png" ALT="month">
 <TABLE CELLPADDING=0 CELLSPACING=0>
<TR>
  <TD ALIGN=right><SMALLMax <FONT COLOR="#00cc00">&nbsp;Mem used:&nbsp;</FONT></SMALL></TD>
  <TD ALIGN=left><SMALL>0.0 %
   </SMALL></TD>
  <TD WIDTH=5></TD>
  <TD ALIGN=right><SMALL>Moyenne <FONT COLOR="#00cc00">&nbsp;Mem used:&nbsp;</FONT></SMALL></TD>
  <TD ALIGN=left><SMALL>0.0 %
  </SMALL></TD>
  <TD WIDTH=5></TD>
  <TD ALIGN=right><SMALL>Actuel <FONT COLOR="#00cc00">&nbsp;Mem used:&nbsp;</FONT></SMALL></TD>
  <TD ALIGN=left><SMALL>?????
  </SMALL></TD>
 </TR>

 <TR>
  <TD ALIGN=right><SMALLMax <FONT COLOR="#0000ff">&nbsp;Swap used:&nbsp;</FONT></SMALL></TD>
  <TD ALIGN=left><SMALL>0.0 %
  </SMALL></TD>
  <TD WIDTH=5></TD>
  <TD ALIGN=right><SMALL>Moyenne <FONT COLOR="#0000ff">&nbsp;Swap used:&nbsp;</FONT></SMALL></TD>
  <TD ALIGN=left><SMALL>0.0 %
  </SMALL></TD>
  <TD WIDTH=5></TD>
  <TD ALIGN=right><SMALL>Actuel <FONT COLOR="#0000ff">&nbsp;Swap used:&nbsp;</FONT></SMALL></TD>
  <TD ALIGN=left><SMALL>?????
 </SMALL></TD>
 </TR> 
</TABLE>
<!-- End `Monthly' Graph (2 Hour -->

<!-- Begin `Yearly' Graph (1 Day -->
<HR>
<B>Graphique annuel (sur 1 jour : Moyenne)</B><BR>
<IMG VSPACE=10 WIDTH=500 HEIGHT=135 ALIGN=TOP 
     SRC="se3_mem-year.png" ALT="year">
 <TABLE CELLPADDING=0 CELLSPACING=0>
<TR>
  <TD ALIGN=right><SMALLMax <FONT COLOR="#00cc00">&nbsp;Mem used:&nbsp;</FONT></SMALL></TD>
  <TD ALIGN=left><SMALL>0.0 %
   </SMALL></TD>
  <TD WIDTH=5></TD>
  <TD ALIGN=right><SMALL>Moyenne <FONT COLOR="#00cc00">&nbsp;Mem used:&nbsp;</FONT></SMALL></TD>
  <TD ALIGN=left><SMALL>0.0 %
  </SMALL></TD>
  <TD WIDTH=5></TD>
  <TD ALIGN=right><SMALL>Actuel <FONT COLOR="#00cc00">&nbsp;Mem used:&nbsp;</FONT></SMALL></TD>
  <TD ALIGN=left><SMALL>?????
  </SMALL></TD>
 </TR>

 <TR>
  <TD ALIGN=right><SMALLMax <FONT COLOR="#0000ff">&nbsp;Swap used:&nbsp;</FONT></SMALL></TD>
  <TD ALIGN=left><SMALL>0.0 %
  </SMALL></TD>
  <TD WIDTH=5></TD>
  <TD ALIGN=right><SMALL>Moyenne <FONT COLOR="#0000ff">&nbsp;Swap used:&nbsp;</FONT></SMALL></TD>
  <TD ALIGN=left><SMALL>0.0 %
  </SMALL></TD>
  <TD WIDTH=5></TD>
  <TD ALIGN=right><SMALL>Actuel <FONT COLOR="#0000ff">&nbsp;Swap used:&nbsp;</FONT></SMALL></TD>
  <TD ALIGN=left><SMALL>?????
 </SMALL></TD>
 </TR> 
</TABLE>
<!-- End `Yearly' Graph (1 Day -->

<!-- Begin Legend -->
  <HR><BR>
  <TABLE WIDTH=500 BORDER=0 CELLPADDING=4 CELLSPACING=0>
   <TR><TD ALIGN=RIGHT><FONT SIZE=-1 COLOR="#00cc00">
      <B>VERT ###</B></FONT></TD>
      <TD><FONT SIZE=-1>Trafic d'entr&eacute;e en Bytes par seconde</FONT></TD></TR> 
   <TR><TD ALIGN=RIGHT><FONT SIZE=-1 COLOR="#0000ff">
      <B>BLEU ###</B></FONT></TD>
      <TD><FONT SIZE=-1>Sortiegoing Traffic in Bytes per Second</FONT></TD></TR> 
  </TABLE>
<!-- End Legend -->