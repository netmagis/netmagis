# $Id: sonde-bind-stat.pl,v 1.2 2008-06-26 07:13:14 boggia Exp $
# ###################################################################
# boggia : Creation : 25/03/08
#
# Interroge les serveurs DNS et renvoie les valeurs suivantes
# concernant le demon bind
#   - bind9_success
#   - bind9_failure
#   - bind9_nxdomain
#   - bind9_recursion
#   - bind9_referral
#   - bind9_nxrrset

sub get_bind_stat
{
	my ($base,$host,$community) = @_;

	# Paramétrage des requètes SNMP
        my ($snmp, $error) = Net::SNMP->session(
                -hostname   => $host,
                -community   => $community,
                -port      => 161,
                -timeout   => $config{"snmp_timeout"},
		-retries        => 2,
                -nonblocking   => 0x1 );

        if (!defined($snmp))
        {
		writelog("get_bind_stat",$config{'logopt'},"info",
			"\t -> ERROR: SNMP connect error: $error");
        }
		
	my $bind9_success = "1.3.6.1.4.1.2021.8.1.101.1";
	my $bind9_failure = "1.3.6.1.4.1.2021.8.1.101.2";
	my $bind9_nxdomain = "1.3.6.1.4.1.2021.8.1.101.3";
	my $bind9_recursion = "1.3.6.1.4.1.2021.8.1.101.4";
	my $bind9_referral = "1.3.6.1.4.1.2021.8.1.101.5";
	my $bind9_nxrrset = "1.3.6.1.4.1.2021.8.1.101.6";

	$r = $snmp->get_request(
		-varbindlist   => [$bind9_success,$bind9_failure,$bind9_nxdomain,$bind9_recursion,$bind9_referral,$bind9_nxrrset],
		-callback   => [ \&get_snmp_bind_stat,$base,$host,$bind9_success,$bind9_failure,$bind9_nxdomain,$bind9_recursion,$bind9_referral,$bind9_nxrrset] );

}


sub get_snmp_bind_stat
{
        my ($session,$base,$host,$bind9_success,$bind9_failure,$bind9_nxdomain,$bind9_recursion,$bind9_referral,$bind9_nxrrset) = @_;

        if (!defined($session->var_bind_list))
        {
                my $error  = $session->error;
		writelog("get_bind_stat",$config{'logopt'},"info",
			"\t -> ERROR: get_bind_stat($host) Error: $error");
        }
        else
        {
                my $success = $session->var_bind_list->{$bind9_success};
                my $failure = $session->var_bind_list->{$bind9_failure};
		my $nxdomain = $session->var_bind_list->{$bind9_nxdomain};
		my $recursion = $session->var_bind_list->{$bind9_recursion};
		my $referral = $session->var_bind_list->{$bind9_referral};
		my $nxrrset = $session->var_bind_list->{$bind9_nxrrset};

		RRDs::update ("$base","N:$success:$failure:$nxdomain:$recursion:$referral:$nxrrset");
                my $ERR=RRDs::error;
		if($ERR)
		{
			writelog("get_bind_stat",$config{'logopt'},"info",
				"\t -> ERROR while updating $base: $ERR");
	
			# si il y eu erreur parce que la base n'existe pas
			# il faut la créer
			if($ERR =~/No such file or directory/)
            		{
                		if($base =~/$config{'path_rrd_db'}/)
                		{
					# creation d'une nouvelle base
                        		creeBaseBind_stat($base);
					
                        		writelog("get_bind_stat",$config{'logopt'},"info",
                             			"\t -> create $base");
					
					# on veut le nom de l'AP pour la supervision de l'etat de l'AP
                			my $iaddr = inet_aton($host);
                			my $hostname  = gethostbyaddr($iaddr, AF_INET);
                			($hostname)=(split(/\./,$hostname))[0];
					# insertion de la ligne dans index.graph
                        		system("echo \"$hostname-bind;bind;1;$base;Statistiques de Bind sur $hostname\" >> $config{'path_etc'}/index.graph");
				}
			}
        	}
	}
}

return 1;
