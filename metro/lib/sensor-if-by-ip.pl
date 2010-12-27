# $Id: sonde-if-by-ip.pl,v 1.1.1.1 2008/06/13 08:55:51 pda Exp $
#
#
# ###################################################################
# boggia : Creation : 27/03/08
#
# fonction qui recupere en SNMP le trafic sur une interface en 
# fonction de l'adresse IP qui lui est attribuee
#

sub get_if_by_ip
{
	my ($base,$host,$community,$ip) = @_;

	my $inverse = 0;
	# Paramétrage des requètes SNMP
        my ($snmp, $error) = Net::SNMP->session(
                -hostname   	=> $host,
                -community  	=> $community,
                -port      	=> 161,
                -timeout   	=> $config{"snmp_timeout"},
		-retries        => 2,
                -nonblocking   	=> 0x1,
		-version	=> "2c" );

        if (!defined($snmp))
        {
		writelog("get_if_by_ip",$config{'logopt'},"info",
			"\t -> ERROR: SNMP connect error: $error");
        }
	else
	{
		if(/^-/)
		{
        		$inverse = 1;
        		$ip =~s/^-//;
		}
		
		my $oid = "1.3.6.1.2.1.4.20.1.2.$ip";
	
		$r = $snmp->get_request(
			-varbindlist   => [$oid],
			-callback   => [ \&get_oid_if,$base,$host,$community,$oid,$inverse] );
	}
}


sub get_oid_if
{
	my($session,$base,$host,$community,$oid,$inverse) = @_;
	
	my $oid_if;
	
	if (!defined($session->var_bind_list))
        {
                my $error  = $session->error;
			
		writelog("get_if_by_ip",$config{'logopt'},"info",
			"\t -> ERROR: get_oid_if($host) Error: $error");
        }
	else
        {
                $oid_if = $session->var_bind_list->{$oid};
                #print "\nget_oid_if($host) $oid = $oid_if";

		if($oid_if=~m/[0-9]+/)
		{
			my ($snmp, $error) = Net::SNMP->session(
                		-hostname       => $host,
                		-community      => $community,
                		-port           => 161,
               	 		-timeout        => $config{"snmp_timeout"},
				-retries        => 2,
                		-nonblocking    => 0x1,
                		-version        => "2c" );

        		if (!defined($snmp))
        		{
				writelog("get_if_by_ip",$config{'logopt'},"info",
					"\t -> ERROR: SNMP connect error: $error");
        		}

			my $oidin = "1.3.6.1.2.1.31.1.1.1.6.$oid_if";
                	my $oidout = "1.3.6.1.2.1.31.1.1.1.10.$oid_if";
                	my $result = $snmp->get_request(
                        	-varbindlist   => [$oidin, $oidout],
                        	-callback   => [ \&get_if_octet,$base,$host,$oid_if,$oidin,$oidout,$inverse,2,$community] );
		}
		else
		{
			writelog("get_if_by_ip",$config{'logopt'},"info",
				"\t -> ERROR: get_oid_if($host) Error: OID invalide : $oid_if");
		}
	}

}


###############################################################
# recupere le resultat des requetes SNMP sur les interfaces
sub get_if_octet
{
        my ($session,$base,$host,$if,$oidin,$oidout,$inverse,$arg,$community) = @_;

        my ($r_in,$r_out);
        if (!defined($session->var_bind_list))
        {
                my $error  = $session->error;

                writelog("metropoller_$group$num_process",$config{'logopt'},"info",
                        "\t -> ERROR: get_if_octet($host) Error: $error");
        }
        else
        {
                $r_in = $session->var_bind_list->{$oidin};
                $r_out = $session->var_bind_list->{$oidout};
                #print "\nget_if_octet($host) $oidin = $r_in, $oidout = $r_out";

                if($inverse == 0)
                {
                        if($arg == 2)
                        {
                                RRDs::update ("$base","N:$r_in:$r_out");
                                my $ERR=RRDs::error;
                                if ($ERR)
                                {
                                        writelog("metropoller_$group$num_process",$config{'logopt'},"info",
                                                "\t -> ERROR while updating $base: $ERR");
					# s'il n'y a pas de base on en cree une
                                    	if($ERR =~/No such file or directory/)
                                    	{
                                        	if($base =~/$config{'path_rrd_db'}/)
                                        	{
                                            		my @decomp_oid = split(/\./,$oidin);
                                            		my $t_decomp_oid = @decomp_oid;
                                            		my $speed = get_snmp_ifspeed("$community\@$host",$decomp_oid[$t_decomp_oid-1]);
							# si OID compteur de broadcast
							if($oidin =~/1\.3\.6\.1\.2\.1\.31\.1\.1\.1\.3\./
								|| $oidin =~/1\.3\.6\.1\.2\.1\.31\.1\.1\.1\.2\./
                                                                || $oidin =~/1.3.6.1.2.1.2.2.1.14/)
							{
                                            			creeBaseBroadcast($base,$speed);
							}
							# sinon compteur de trafic
							else
							{	
								creeBaseTrafic($base,$speed);
							}
                                            		writelog("get_if_snmp_$group$num_process",$config{'logopt'},"info",
                                                	"\t -> create $base,$host,$if,$oidin,$oidout,$inverse,$arg,$speed");
                                        	}
                                    	}
                                }
                                #print "maj base rrd $base\n";
                        }
                        elsif($arg == 4)
                        {
                                RRDs::update ("$base","N:$r_in:$r_out:0:0");
                                my $ERR=RRDs::error;
                                if ($ERR)
                                {
                                    writelog("metropoller_$group$num_process",$config{'logopt'},"info",
                                                "\t -> ERROR while updating $base: $ERR");

                                    # s'il n'y a pas de base on en cree une
                                    if($ERR =~/No such file or directory/)
                                    {
                                        if($base =~/$config{'path_rrd_db'}/)
                                        {
                                            my @decomp_oid = split(/\./,$oidin);
                                            my $t_decomp_oid = @decomp_oid;
                                            my $speed = get_snmp_ifspeed("$community\@$host",$decomp_oid[$t_decomp_oid-1]);
                                            creeBaseTrafic($base,$speed);
                                            writelog("get_if_snmp_$group$num_process",$config{'logopt'},"info",
                                                "\t -> create $base,$host,$if,$oidin,$oidout,$inverse,$arg,$speed");
                                        }
                                    }
                                }
                        }
                }
                else
                {
                        if($arg == 2)
                        {
                                RRDs::update ("$base","N:$r_out:$r_in");
                                my $ERR=RRDs::error;
                                if ($ERR)
                                {
					writelog("metropoller_$group$num_process",$config{'logopt'},"info",
                                                "\t -> ERROR while updating $base: $ERR");
					# s'il n'y a pas de base, on en cree une
					if($ERR =~/No such file or directory/)
                                        {
                                                if($base =~/$config{'path_rrd_db'}/)
                                                {
                                                        my @decomp_oid = split(/\./,$oidin);
                                                        my $t_decomp_oid = @decomp_oid;
                                                        my $speed = get_snmp_ifspeed("$community\@$host",$decomp_oid[$t_decomp_oid-1]);
                                                        # si OID compteur de broadcast

                                                        if($oidin =~/1\.3\.6\.1\.2\.1\.31\.1\.1\.1\.3\./ 
								|| $oidin =~/1\.3\.6\.1\.2\.1\.31\.1\.1\.1\.2\./
								|| $oidin =~/1.3.6.1.2.1.2.2.1.14/)
                                                        {
                                                                creeBaseBroadcast($base,$speed);
                                                        }
                                                        # sinon compteur de trafic
                                                        else
                                                        {
                                                                creeBaseTrafic($base,$speed);
                                                        }
                                                        writelog("get_if_snmp_$group$num_process",$config{'logopt'},"info",
                                                        "\t -> create $base,$host,$if,$oidin,$oidout,$inverse,$arg,$speed");
                                                }
                                        }
                                }
                                #print "maj base inverse rrd $base\n";
                        }
                        elsif($arg == 4)
                        {
                                RRDs::update ("$base","N:$r_out:$r_in:0:0");
                                my $ERR=RRDs::error;
                                if ($ERR)
                                {
                                        writelog("metropoller_$group$num_process",$config{'logopt'},"info",
                                                "\t -> ERROR while updating $base: $ERR");
                                    # s'il n'y a pas de base on en cree une
                                    if($ERR =~/No such file or directory/)
                                    {
                                        if($base =~/$config{'path_rrd_db'}/)
                                        {
                                            my @decomp_oid = split(/\./,$oidin);
                                            my $t_decomp_oid = @decomp_oid;
                                            my $speed = get_snmp_ifspeed("$community\@$host",$decomp_oid[$t_decomp_oid-1]);
                                            creeBaseTrafic($base,$speed);
                                            writelog("get_if_snmp_$group$num_process",$config{'logopt'},"info",
                                                "\t -> create $base,$host,$if,$oidin,$oidout,$inverse,$arg,$speed");
                                        }
                                    }
                                }
                        }
                }
        }
}


return 1;
