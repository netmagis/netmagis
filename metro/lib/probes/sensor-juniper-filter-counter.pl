# $Id$
#
#
# ###################################################################
# boggia : Creation : 05/02/09
#
# permet de recuperer les compteurs appliques sur les filtres dans les 
# routeurs juniper. Il s'agit de compteur 64 bits.
# ex de conf juniper:
# filter osirisv6-in {                                                   
#            term compter-paquets {                                             
#                then {
#                    count ipv6-in;
#                    next term;
#                }
#            }
#

sub get_juniper_filter_counter 
{
	my ($base,$host,$community,$filter) = @_;

	my ($oidin,$oidout,$result,$r);
        
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
		writelog("get_juniper_counter",$config{'logopt'},"info",
			"\t -> ERROR: SNMP connect error: $error");
        }
	else
	{
	    my $trouve_inter = 0;
	    my $ligne = "";
	    my $index_filter = "";

		# on recherche le filtre dans le fichier nom<=>index	
		my $t_liste_juniper_filter = @liste_juniper_filter;
	
		for($i=0;$i<$t_liste_juniper_filter;$i++)
		{
			if($liste_juniper_filter[$i] !~/^#/ && $liste_juniper_filter[$i] !~/^\s*$/)
			{
	                	chomp $liste_juniper_filter[$i];
	                        (my $ip, my $inter, my $ind) = split(/;/,$liste_juniper_filter[$i]);
  
	                      	#si le filtre recherche est trouve
	                       	#on remplit la variable index
	                    	if($inter eq $filter && $ip eq $host && $ind ne "")
	                        {
					system("echo \"TROUVE : $inter eq $filter && $ip eq $host && $ind ne rien\" >> /var/tmp/cache");
                        		$trouve_filter = 1;
                        	      	$index_filter = $ind;
					$i = $t_liste_juniper_filter;
 	                     	}
	               }
		}
	
		my $ok_interro = 0;
		# si le filtre est présent dans le fichier nom<=>index,
		# controle de cohérence de l'index par rapport au nom 
		if($trouve_filter == 1)
		{
			my $oid = "1.3.6.1.4.1.2636.3.5.2.1.6.$index_filter";
			$r = $snmp->get_request(
				-varbindlist   => [$oid],
				-callback   => [ \&get_filter_name, $base,$host,$community,$filter,$oid,$index_filter] );

		}
		# sinon, il faut rechercher l'index du filtre et remplir le fichier nom<=>idex
		else
		{
			# cherche liste des filtres
			my $param;

			$param = $community."@".$host;
			&snmpmapOID("desc","1.3.6.1.4.1.2636.3.5.2.1.6");
	        	@desc_filtre = &snmpwalk($param, "desc");

        		$nb_desc = @desc_filtre;
	
			if($desc_filtre[0] ne "")
                        {
        			$index_filter = "";
				
				my $i;	
	        		for($i=0;$i<$nb_desc;$i++)
  		      		{
   	        	     		if($desc_filtre[$i]=~m/$filter/)
	                		{
						chomp $desc_filtre[$i];
 		                       		$index_filter = (split(/:/,$desc_filtre[$i]))[0];
	                	        	$i = $nb_desc;
                        			$ok_interro = 1;
                			}
        			}

				# on trouve le filtre a la suite du snmpwalk
				# on remplit le fichier nom<=>index et on interroge l'equipement
				if($ok_interro == 1)
       		 		{
                			if($lock_liste_juniper_filter == 0)
                			{
						$lock_liste_juniper_filter = 1;

						$ligne = "$host;$filter;$index_filter";
						push @liste_juniper_filter,$ligne;
	
						$maj_juniper_filter_file = 1;				
						$lock_liste_juniper_filter = 0;	
					}
					
					$oid = "1.3.6.1.4.1.2636.3.5.2.1.5.$index_filter";
                			$r = $snmp->get_request(
                        			-varbindlist   => [$oid],
                        			-callback   => [ \&get_juniper_filter,$base,$host,$filter,$oid,$community] );
				}
				else
				{
					writelog("get_juniper_counter",$config{'logopt'},"info",
						"\t -> ERROR: filtre $filter inexistant sur $host");
				}
			}
			else
			{
				writelog("get_juniper_counter",$config{'logopt'},"info",
                                	"\t -> ERROR: $community\@$host ne répond pas");
			}
		}
	}
}


sub get_filter_name 
{
	my ($session,$base,$host,$community,$filter,$oid,$id_if) = @_;	

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
		
		writelog("get_juniper_counter",$config{'logopt'},"info",
                	"\t -> ERROR: get_juniper_counter($host) Error: $error");
		
		$err=1;
    	} 
	else 
	{
       		$result = $session->var_bind_list->{$oid};
    	}

	if($result=~m/$filter/ && $err==0)
        #si le nom du filtre a toujours le meme index
        {
                $ok_interro = 1;
        }
        elsif($err==0)
        {
                $ok_interro = 0;
              
		writelog("get_juniper_counter",$config{'logopt'},"info", 
                	"\t -> ERROR: le filtre trouve ne correspond pas a son index reel");
		
		# cherche liste des filtres
                my $param = $community."@".$host;
                &snmpmapOID("desc","1.3.6.1.4.1.2636.3.5.2.1.6");
                my @desc_filtre = &snmpwalk($param, "desc");

                my $nb_desc = @desc_filtre;

                my $index_filter = "";

		my $i;
                for($i=0;$i<$nb_desc;$i++)
                {
                        if($desc_filtre[$i]=~m/$filter/)
                        {
                                chomp $desc_filtre[$i];
                                $index_filter = (split(/:/,$desc_filtre[$i]))[0];
                                $i = $nb_desc;
                                $ok_interro = 1;
                        }
                }

		if($ok_interro == 1)
		{
			if($lock_liste_juniper_filter == 0)
                        {
	                        $lock_liste_juniper_filter = 1;
				my $t_liste_juniper_filter = @liste_juniper_filter;
				
				my $i;
				# cherche le nom du filtre dans le cache
				for($i=0;$i<$t_liste_juniper_filter;$i++)
				{
					(my $ip, my $inter, my $ind) = split(/;/,$liste_juniper_filter[$i]);

					if($ip eq $host && $filter eq $inter)
					{
						$liste_juniper_filter[$i] = "$ip;$filter;$index_filter";
					}	
				}
				$lock_liste_juniper_filter = 0;
				$maj_juniper_filter_file = 1;
			}
			else
			{
				writelog("get_juniper_counter",$config{'logopt'},"info",
                			"\t -> ERROR: Fichier if_juniper_filter.txt locké. Pas de mise à jour");
			}
			$id_if = $index_filter;
		}
		else
		{
			writelog("get_juniper_counter",$config{'logopt'},"info",
                		"\t -> ERROR: filtre $filter inexistant sur $host. Pas de mise à jour.");
		}
        }

	if($id_if ne "" && $ok_interro ==1)
	{
		my $oid = "1.3.6.1.4.1.2636.3.5.2.1.5.$id_if";
                #print "if64 maj ($base,$host,$if,$oidin,$oidout,$inverse) \n";
		$r = $snmp->get_request(
                	-varbindlist   => [$oid],
                	-callback   => [ \&get_juniper_filter,$base,$host,$filter,$oid,$community] );
	}
}



###############################################################
# recupere le resultat des requetes SNMP sur les interfaces
sub get_juniper_filter
{
        my ($session,$base,$host,$if,$oid,$community) = @_;

        my $r;
        if (!defined($session->var_bind_list))
        {
                my $error  = $session->error;

                writelog("metropoller_$group$num_process",$config{'logopt'},"info",
                        "\t -> ERROR: get_juniper_counter($host) Error: $error");
        }
        else
        {
                $r = $session->var_bind_list->{$oid};
                RRDs::update ("$base","N:$r");
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
                            my $speed = 10000000000;
                            creeBaseCounter($base,$speed);
                            writelog("get_juniper_filter_$group$num_process",$config{'logopt'},"info",
				"\t -> create $base,$host,$if,$oid,$speed");
    
			    #system("echo \"$hostname-$if;counter_generic;1;$base;\" >> $config{''}/index.graph");
                        }
                    }
                }
        }
}

return 1;
