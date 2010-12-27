# $Id: sonde-cpu-server.pl,v 1.1.1.1 2008/06/13 08:55:51 pda Exp $
#
#
# ###################################################################
#  boggia : Creation : 27/03/08
#
# fonctions qui permettent d'obtenir en SNMP les infos sur 
# l'utilisation de la CPU d'un serveur
# - % CPU du systeme
# - % CPU des applications
#
sub get_CPU_server
{
	my ($base,$host,$community,$num_cpu) = @_;

	if($num_cpu eq "")
	{
	    $num_cpu = 0;
	}
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
		writelog("get_CPU_server",$config{'logopt'},"info",
			"\t -> ERROR: SNMP connect error: $error");
        }
		
	my $oid_cpu_sys = "1.3.6.1.4.1.2021.11.10.$num_cpu";
	my $oid_cpu_user = "1.3.6.1.4.1.2021.11.9.$num_cpu";
	$r = $snmp->get_request(
		-varbindlist   => [$oid_cpu_sys, $oid_cpu_user],
		-callback   => [ \&get_snmp_cpu_server,$base,$host,$oid_cpu_sys,$oid_cpu_user] );

}


sub get_snmp_cpu_server
{
        my ($session,$base,$host,$oid_cpu_sys,$oid_cpu_user) = @_;

        if (!defined($session->var_bind_list))
        {
                my $error  = $session->error;
		writelog("get_CPU_server",$config{'logopt'},"info",
			"\t -> ERROR: get_CPU_server($host) Error: $error");
        }
        else
        {
                my $cpu_sys = $session->var_bind_list->{$oid_cpu_sys};
                my $cpu_user = $session->var_bind_list->{$oid_cpu_user};
                #print "\nget_CPU_server($host) $oid_cpu_sys = $cpu_sys, $oid_cpu_user = $cpu_user";

		RRDs::update ("$base","N:$cpu_sys:$cpu_user");
                my $ERR=RRDs::error;
		if($ERR)
		{
			writelog("get_CPU_server",$config{'logopt'},"info",
				"\t -> ERROR while updating $base: $ERR");
			if($ERR =~/No such file or directory/)
			{
			    if($base =~/$config{'path_rrd_db'}/)
                            {
                                creeBaseCPU($base);
                                writelog("get_CPU_server",$config{'logopt'},"info",
                                    "\t -> create $base");

				my @decomp_rep = split(/\//,$base);
				my $t_decomp_rep = @decomp_rep;
				my ($nom_graph_ind) = (split(/\.rrd/,$decomp_rep[$t_decomp_rep - 1]))[0];
				if($nom_graph_ind ne "")
				{
				    #system("echo \"$nom_graph_ind;GaugeCPU;1;/local/obj999/db/CPU/$nom_graph_ind.rrd;Utilisation CPU de $nom_graph_ind\" >> $config{''}/index.graph");
                  
				}
                            }

			}
		}
        }
}

return 1;
