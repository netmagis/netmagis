# $Id: sonde-load-server.pl,v 1.1.1.1 2008/06/13 08:55:51 pda Exp $
#
#
# ###################################################################
# boggia : Creation : 27/03/08
#
# fonctions qui permettent de récupérer en SNMP le load average d'un
# serveur sur :
#   - 5 minutes
#   - 15 minutes
#

sub get_Load_server
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
		writelog("get_load_server",$config{'logopt'},"info",
                	"\t -> ERROR: SNMP connect error: $error");
        }
	else
	{
		my $oid_load5 = "1.3.6.1.4.1.2021.10.1.3.2";
		my $oid_load15 = "1.3.6.1.4.1.2021.10.1.3.3";
		$r = $snmp->get_request(
			-varbindlist   => [$oid_load5, $oid_load15],
			-callback   => [ \&get_snmp_load_server,$base,$host,$oid_load5,$oid_load15] );
	}
}


sub get_snmp_load_server
{
        my ($session,$base,$host,$oid_load5,$oid_load15) = @_;

        if (!defined($session->var_bind_list))
        {
                my $error  = $session->error;
	
		writelog("get_load_server",$config{'logopt'},"info",
                	"\t -> ERROR: get_load_server($host) Error: $error");
        }
        else
        {
                my $load5 = $session->var_bind_list->{$oid_load5};
                my $load15 = $session->var_bind_list->{$oid_load15};

		RRDs::update ("$base","N:$load5:$load15");
                my $ERR=RRDs::error;
		if($ERR)
		{
			writelog("get_load_server",$config{'logopt'},"info",
                		"\t -> ERROR while updating $base: $ERR");
		}
        }
}

return 1;
