# $Id: sonde-if-snmp64.pl,v 1.1.1.1 2008/06/13 08:55:51 pda Exp $
#
#
# ###################################################################
# boggia : Creation : 27/03/08
#
# fonctions qui permettent de récupérer en SNMP les compteurs de
# trafic 64 bits
#

sub ifNom_counter64 
{
	my ($base,$host,$community,$if,$sonde,$periodicity) = @_;

	my ($oidin,$oidout,$result,$r);
	#cherche si trafic inverse sur l'interface ou pas
	my $inverse = 0;
	if($if =~m/^-/)
	{
        	$inverse = 1;
        	$if =~s/^-//;
	}
        
	# Paramétrage des requètes SNMP
       	my ($snmp, $error) = Net::SNMP->session(
        	-hostname   => $host,
        	-community   => $community,
       		-port      => 161,
       		-timeout   => $config{"snmp_timeout"},
		-retries        => 2,
      		-nonblocking   => 0x1, 
		-version	=> "2c" );
        
	if (!defined($snmp)) 
	{
		writelog("get_if_snmp64",$config{syslog_facility},"info",
			"\t -> ERROR: SNMP connect error: $error");
        }
	else
	{

	    #pour compatibilite avec conf basees sur l'index
	    if($if !~m/[a-zA-Z]/)
	    {
        	#conf avec index
        	#print "conf avec index\n";
		chomp $if;
		
		$oidin = "1.3.6.1.2.1.31.1.1.1.6.$if";
		$oidout = "1.3.6.1.2.1.31.1.1.1.10.$if";
		$result = $snmp->get_request(
                	-varbindlist   => [$oidin, $oidout],
                	-callback   => [ \&get_if_octet,$base,$host,$if,$oidin,$oidout,$inverse,2,$community,$periodicity] );

	    }
	    #sinon, recherche de l'index par rapport au nom de l'interface
	    else
	    {
		my $trouve_inter = 0;
		my $ligne = "";
		my $index_interface = "";

                if(exists $idxcache{$host}{$if})
                {
                	if($idxcache{$host}{$if} ne "")
                	{
                		$trouve_inter = 1;
                		$index_interface = $idxcache{$host}{$if};
                	}
                }
	
		my $ok_interro = 0;
		# si l'interface est présente dans le fichier nom<=>index,
		# controle de cohérence de l'index par rapport au nom 
		if($trouve_inter == 1)
		{
			#ifMib, description
			my $oid = "1.3.6.1.2.1.2.2.1.2.$index_interface";
			$r = $snmp->get_request(
				-varbindlist   => [$oid],
				-callback   => [ \&get_if64_name,$base,$host,$community,$if,$oid,$index_interface,$inverse,$periodicity] );

		}
		# sinon, il faut rechercher l'index de l'interface et remplir le fichier nom<=>idex
		else
		{
			# cherche liste des interfaces
			my $param;

			$param = $community."@".$host;
			&snmpmapOID("desc","1.3.6.1.2.1.2.2.1.2");
	        	@desc_inter = &snmpwalk($param, "desc");

        		$nb_desc = @desc_inter;
	
			if($desc_inter[0] ne "")
                        {
        			$index_interface = "";
				
				my $i;	
	        		for($i=0;$i<$nb_desc;$i++)
  		      		{
   	        	     		if($desc_inter[$i]=~m/$if/)
	                		{
						chomp $desc_inter[$i];
 		                       		$index_interface = (split(/:/,$desc_inter[$i]))[0];
	                	        	$i = $nb_desc;
                        			$ok_interro = 1;
                			}
        			}

				# on trouve l'interface a la suite du snmpwalk
				# on remplit le fichier nom<=>index et on iterroge l'equipement
				if($ok_interro == 1)
       		 		{
					$idxcache{$host}{$if} = $index_interface;
                                        $maj_cache_file = 1;
					
					$oidin = "1.3.6.1.2.1.31.1.1.1.6.$index_interface";
                			$oidout = "1.3.6.1.2.1.31.1.1.1.10.$index_interface";
                			$r = $snmp->get_request(
                        			-varbindlist   => [$oidin, $oidout],
                        			-callback   => [ \&get_if_octet,$base,$host,$if,$oidin,$oidout,$inverse,2,$community,$periodicity] );
				}
				else
				{
					writelog("get_if_snmp64",$config{syslog_facility},"info",
						"\t -> ERROR: interface $if inexistante sur $host");
				}
			}
			else
			{
				writelog("get_if_snmp64",$config{syslog_facility},"info",
                                	"\t -> ERROR: $community\@$host ne répond pas");
			}
		}
	    }
	}
}

sub get_if64_name 
{
	my ($session,$base,$host,$community,$if,$oid,$id_if,$inverse,$periodicity) = @_;	

	my $result;
	my $ok_interro;

	my ($snmp, $error) = Net::SNMP->session(
        	-hostname   => $host,
        	-community   => $community,
	        -port      => 161,
	        -timeout   => $config{"snmp_timeout"},
		-retries        => 2,
	        -nonblocking   => 0x1,
		-version        => "2c" );

	my $r;
	my $err=0;

	if (!defined($session->var_bind_list)) 
	{
       		my $error  = $session->error;
		
		writelog("get_if_snmp64",$config{syslog_facility},"info",
                	"\t -> ERROR: get_if_name($host) Error: $error");
		
		$err=1;
    	} 
	else 
	{
       		$result = $session->var_bind_list->{$oid};
    	}

	if($result=~m/$if/ && $err==0)
        #si le nom de l'interface a toujours le meme index
        {
                $ok_interro = 1;
                #print "\nL'interface trouvee correspond a son index reel\n";
        }
        elsif($err==0)
        {
                $ok_interro = 0;
              
		writelog("get_if_snmp64",$config{syslog_facility},"info", 
                	"\t -> ERROR: l'interface trouvee ne correspond pas a son index reel");
		
		# cherche liste des interfaces
                my $param = $community."@".$host;
                &snmpmapOID("desc","1.3.6.1.2.1.2.2.1.2");
                my @desc_inter = &snmpwalk($param, "desc");

                my $nb_desc = @desc_inter;

                my $index_interface = "";

		my $i;
                for($i=0;$i<$nb_desc;$i++)
                {
                        if($desc_inter[$i]=~m/$if/)
                        {
                                #print "$desc_inter[$i]\n";
                                chomp $desc_inter[$i];
                                $index_interface = (split(/:/,$desc_inter[$i]))[0];
                                #       print "index = $index_interface\n";
                                $i = $nb_desc;
                                $ok_interro = 1;
                        }
                }

		if($ok_interro == 1)
		{
			$idxcache{$host}{$if} = $index_interface;
                        $maj_cache_file = 1;
			$id_if = $index_interface;
		}
		else
		{
			writelog("get_if_snmp64",$config{syslog_facility},"info",
                		"\t -> ERROR: interface $if inexistante sur $host. Pas de mise à jour.");
			delete($idxcache{$host}{$if});
		}
        }

	if($id_if ne "" && $ok_interro ==1)
	{
		my $oidin = "1.3.6.1.2.1.31.1.1.1.6.$id_if";
                my $oidout = "1.3.6.1.2.1.31.1.1.1.10.$id_if";
                #print "if64 maj ($base,$host,$if,$oidin,$oidout,$inverse) \n";
		$r = $snmp->get_request(
                	-varbindlist   => [$oidin, $oidout],
                	-callback   => [ \&get_if_octet,$base,$host,$if,$oidin,$oidout,$inverse,2,$community,$periodicity] );
	}
}

return 1;
