# $Id:$
#
#
# ###################################################################
# boggia : Creation : 17/02/09
#
# fonctions qui permettent de récupérer en SNMP les infos
# d'utilisation de la CPU sur la RE du Juniper M20
#
sub get_CPU_juniper
{
	my ($base,$host,$community,$carte) = @_;

	my %id_carte = (
                'ssb'              => 6,
		're'		   => 9,
	);

	# on definit par defaut la ssb
	if(!defined($id_carte{$carte}))
	{
	    writelog("get_CPU_juniper",$config{'logopt'},"info",
                        "\t -> ERROR: Nom de la carte a superviser manquant ou errone");
	}
	else
	{

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
		writelog("get_CPU_RE_juniper",$config{'logopt'},"info",
			"\t -> ERROR: SNMP connect error: $error");
	    }
		
	    my $oid_cpu_re0 = "1.3.6.1.4.1.2636.3.1.13.1.8.$id_carte{$carte}.1.0.0";

	    $r = $snmp->get_request(
		-varbindlist   => [$oid_cpu_re0],
		-callback   => [ \&get_snmp_cpu_re0,$base,$host,$community,$oid_cpu_re0,$carte,$id_carte{$carte}] );
	}
}


sub get_snmp_cpu_re0
{
        my ($session,$base,$host,$community,$oid_cpu_re0,$carte,$id_carte) = @_;

	my $cpu_re0;
	# si une re existe dans le slot 0
	if (defined($session->var_bind_list))
        {
	    $cpu_re0 = $session->var_bind_list->{$oid_cpu_re0};
	     
	    if($cpu_re0 !~/[0-9]+/)
	    {
		$cpu_re0 = 0;
	    }
	}
	# sinon on met la valeur a 0
	else
	{
	    $cpu_re0 = 0;
	}

	my ($snmp, $error) = Net::SNMP->session(
                -hostname   => $host,
                -community   => $community,
                -port      => 161,
                -timeout   => $config{"snmp_timeout"},
                -retries        => 2,
                -nonblocking   => 0x1,
                -version        => "2c" );
	
	if (!defined($snmp))
        {
                writelog("get_CPU_juniper",$config{'logopt'},"info",
                        "\t -> ERROR: SNMP connect error: $error");
        }
	
	my $oid_cpu_re1 = "1.3.6.1.4.1.2636.3.1.13.1.8.$id_carte.2.0.0";
        $r = $snmp->get_request(
                -varbindlist   => [$oid_cpu_re1],
                -callback   => [ \&get_snmp_cpu_re1,$base,$host,$cpu_re0,$oid_cpu_re1,$carte] );
}


sub get_snmp_cpu_re1
{
        my ($session,$base,$host,$cpu_re0,$oid_cpu_re1,$carte) = @_;

	my $cpu_re1;

	# si une re existe dans le slot 0
        if (defined($session->var_bind_list))
        {
            $cpu_re1 = $session->var_bind_list->{$oid_cpu_re1};
	    if($cpu_re1 !~/[0-9]+/)
            {
                $cpu_re1 = 0;
            }

        }
        # sinon on met la valeur a 0
        else
        {
            $cpu_re1 = 0;
        }

	RRDs::update ("$base","N:$cpu_re0:$cpu_re1");
        my $ERR=RRDs::error;
	if($ERR)
	{
		writelog("get_CPU_juniper",$config{'logopt'},"info",
			"\t -> ERROR while updating $base: $ERR");

		if($ERR =~/No such file or directory/)
		{
		    if($base =~/$config{'path_rrd_db'}/)
		    {
			creeBaseCPUJuniper($base);
			writelog("get_CPU_juniper",$config{'logopt'},"info",
			    "\t -> create $base");
			
			my $hostname = gethostnamebyaddr($host);

			#system("echo \"$hostname-cpu-$carte;GaugeCPUJuniper;1;$base;Utilisation CPU de la $carte sur les slot 0 et 1\" >> $config{''}/index.graph");

		  }
		}
	}
}

return 1;
