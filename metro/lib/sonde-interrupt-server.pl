# $Id: sonde-interrupt-server.pl,v 1.1.1.1 2008/06/13 08:55:51 pda Exp $
#
#
# ###################################################################
# boggia : Creation : 27/03/08
#
# fonctions qui permettent de récupérer en SNMP le nombre 
# d'interruptions système d'un serveur
#

sub get_Interrupt_server
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
		writelog("get_interrupt_server",$config{'logopt'},"info",
                	"\t -> ERROR: SNMP connect error: $error");
        }

		
	my $oid = "1.3.6.1.4.1.2021.11.7.0";
	$r = $snmp->get_request(
		-varbindlist   => [$oid],
		-callback   => [ \&get_snmp_interrupt_server,$base,$host,$oid] );

}


sub get_snmp_interrupt_server
{
        my ($session,$base,$host,$oid) = @_;

        if (!defined($session->var_bind_list))
        {
                my $error  = $session->error;
		
		writelog("get_interrupt_server",$config{'logopt'},"info",
                	"\t -> ERROR: get_interrupt_server($host) Error: $error");
        }
        else
        {
                my $interrupt = $session->var_bind_list->{$oid};

		RRDs::update ("$base","N:$interrupt");
		my $ERR=RRDs::error;
		if ($ERR)
		{
			writelog("get_interrupt_server",$config{'logopt'},"info",
                		"\t -> ERROR while updating $base: $ERR");
		}
        }
}

return 1;
