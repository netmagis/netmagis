# $Id: sonde-mbuf-juniper.pl,v 1.1.1.1 2008-06-13 08:55:51 pda Exp $
#
#
# ###################################################################
# boggia : Creation : 27/03/08
#
# fonctions qui permettent de récupérer en SNMP le nombre de Mbufs 
# en attente de traitement sur un Juniper
#

sub get_MBUF_juniper
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
		writelog("get_MBUF_juniper",$config{'logopt'},"info",
			"\t -> ERROR: SNMP connect error: $error");
        }
		
	my $oid_cpu_1min = "1.3.6.1.4.1.2121.255.1.3";
	my $oid_cpu_5min = "1.3.6.1.4.1.2121.255.1.4";
	$r = $snmp->get_request(
		-varbindlist   => [$oid_cpu_1min, $oid_cpu_5min],
		-callback   => [ \&get_snmp_cpu_cisco,$base,$host,$oid_cpu_1min,$oid_cpu_5min] );
}


sub get_snmp_cpu_cisco
{
        my ($session,$base,$host,$oid_cpu_1min,$oid_cpu_5min) = @_;

        if (!defined($session->var_bind_list))
        {
                my $error  = $session->error;
		writelog("get_MBUF_juniper",$config{'logopt'},"info",
			"\t -> ERROR: get_MBUF_juniper($host) Error: $error");
        }
        else
        {
                my $cpu_1min = $session->var_bind_list->{$oid_cpu_1min};
                my $cpu_5min = $session->var_bind_list->{$oid_cpu_5min};
                #print "\nget_CPU_server($host) $oid_cpu_1min = $cpu_1min, $oid_cpu_5min = $cpu_5min";

		RRDs::update ("$base","N:$cpu_1min:$cpu_5min");
                my $ERR=RRDs::error;
		if($ERR)
		{
			writelog("get_MBUF_juniper",$config{'logopt'},"info",
				"\t -> ERROR while updating $base: $ERR");

			if($ERR =~/No such file or directory/)
			{
			    if($base =~/$config{'path_rrd_db'}/)
			    {
				creeBaseCPUCisco($base);
				writelog("get_MBUF_juniper",$config{'logopt'},"info",
				    "\t -> create $base");
			    }
			}
		}
        }
}

return 1;
