# $Id: sonde-mailq.pl,v 1.1.1.1 2008-06-13 08:55:51 pda Exp $
#
#
# ###################################################################
# boggia : Creation : 27/03/08
#
# fonctions qui permettent de récupérer en SNMP la taille de la mailq
# d'un serveur
#
sub get_mailq
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
		writelog("get_mailq",$config{'logopt'},"info",
                	"\t -> ERROR: SNMP connect error: $error");
        }

		
	my $oid = "1.3.6.1.4.1.2121.255.1.1";
	$r = $snmp->get_request(
		-varbindlist   => [$oid],
		-callback   => [ \&get_snmp_mailq,$base,$host,$oid] );

}


sub get_snmp_mailq
{
        my ($session,$base,$host,$oid) = @_;

        if (!defined($session->var_bind_list))
        {
                my $error  = $session->error;
	
		writelog("get_mailq",$config{'logopt'},"info",
                	"\t -> ERROR: get_mailq($host) Error: $error");
        }
        else
        {
                my $mailq = $session->var_bind_list->{$oid};
	
		RRDs::update ("$base","N:$mailq");
                my $ERR=RRDs::error;
		if($ERR)
		{
			writelog("get_mailq",$config{'logopt'},"info",
                		"\t -> ERROR while updating $base: $ERR");
		}
        }
}

return 1;
