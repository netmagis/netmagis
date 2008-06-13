# $Id: sonde-nb-connect-portcap.pl,v 1.1.1.1 2008-06-13 08:55:51 pda Exp $
#
#
# ###################################################################
# boggia : Creation : 27/03/08
#
# prend en parametre l'ip du portail captif et la communaute snmp
# renvoie le nombre de connexions simultanées
#
#
sub get_nb_connect_portcap
{
	my ($base,$host,$community) = @_;

	# Paramétrage des requètes SNMP
        my ($snmp, $error) = Net::SNMP->session(
                -hostname   	=> $host,
                -community  	=> $community,
                -port      	=> 161,
                -timeout   	=> $config{"snmp_timeout"},
		-retries	=> 2,
                -nonblocking   	=> 0x1,
		-version        => "2c" );

        if (!defined($snmp))
        {
		writelog("get_cnt_portcap",$config{'logopt'},"info",
                	"\t -> ERROR: SNMP connect error: $error");
        }

		
	my $oid = "1.3.6.1.4.1.2021.8.1.100.1";
	$r = $snmp->get_request(
		-varbindlist   => [$oid],
		-callback   => [ \&get_snmp_nb_connect_portcap,$base,$host,$oid] );

}


sub get_snmp_nb_connect_portcap
{
        my ($session,$base,$host,$oid) = @_;

        if (!defined($session->var_bind_list))
        {
                my $error  = $session->error;
	
		writelog("get_cnt_portcap",$config{'logopt'},"info",
                	"\t -> ERROR: get_nb_connect_portcap($host) Error: $error");
        }
        else
        {
                my $nb_connect = $session->var_bind_list->{$oid};
	
		RRDs::update ("$base","N:$nb_connect");
                my $ERR=RRDs::error;
		if($ERR)
		{
			writelog("get_cnt_portcap",$config{'logopt'},"info",
                		"\t -> ERROR while updating $base: $ERR");
		}
        }
}

return 1;
