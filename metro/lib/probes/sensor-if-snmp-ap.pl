# $Id: sonde-if-snmp-ap.pl,v 1.1.1.1 2008/06/13 08:55:51 pda Exp $
#
#
# ###################################################################
# boggia : Creation : 27/03/08
#
# fonctions qui permettent de récupérer en SNMP les compteurs de
# trafic sur les AP WiFi
#

sub ifNom_ap 
{
	my ($base,$host,$community,$if) = @_;
	
	my $r ;
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
      		-nonblocking   => 0x1 );
        
	if (!defined($snmp)) 
	{
		writelog("get_if_snmp_ap",$config{'logopt'},"info",
                	"\t -> ERROR: SNMP connect error: $error");
        }

	#pour compatibilite avec conf basees sur l'index
	if($if !~m/[a-zA-Z]/)
	{
        	#conf avec index
        	#print "conf avec index\n";
		chomp $if;
		
		my $oidin = "1.3.6.1.2.1.2.2.1.10.$if";
		my $oidout = "1.3.6.1.2.1.2.2.1.16.$if";
		my $result = $snmp->get_request(
                	-varbindlist   => [$oidin, $oidout],
                	-callback   => [ \&get_if_octet,$base,$host,$if,$oidin,$oidout,$inverse,2,$community] );

	}
	#sinon, recherche de l'index par rapport au nom de l'interface
	else
	{
		my $trouve_inter = 0;
		my $ligne = "";
		my $index_interface = "";
		my $i;

		# on recherche l'interface dans le fichier nom<=>index	
		my $t_liste_if_ap = @liste_if_ap;
	
		for($i=0;$i<$t_liste_if_ap;$i++)
		{
			if($liste_if_ap[$i] !~/^#/ && $liste_if_ap[$i] !~/^\s*$/)
			{
	                	chomp $liste_if_ap[$i];
	                        (my $ip, my $inter, my $ind) = split(/;/,$liste_if_ap[$i]);
  
	                      	#si l'interface recherchee est trouvee
	                       	#on remplit la variable index
	                    	if($inter eq $if && $ip eq $host && $ind ne "")
	                        {
                        		$trouve_inter = 1;
                        	      	$index_interface = $ind;
					$i = $t_liste_if_ap;
        	                       	#print "\non trouve l'interface $index_interface\n";
 	                     	}
	               }
			

		}
	
		my $ok_interro = 0;
		# si l'interface est présente dans le fichier nom<=>index,
		# controle de cohérence de l'index par rapport au nom 
		if($trouve_inter == 1)
		{
			#ifMib, description
			my $oid = "1.3.6.1.2.1.31.1.1.1.1.$index_interface";
			$r = $snmp->get_request(
				-varbindlist   => [$oid],
				-callback   => [ \&get_if_name, $base,$host,$community,$if,$oid,$index_interface,$inverse] );

		}
		# sinon, il faut rechercher l'index de l'interface et remplir le fichier nom<=>idex
		else
		{
			# cherche liste des interfaces
			my @desc_inter = ();
			my $param;

			$param = $community."@".$host;
			&snmpmapOID("desc","1.3.6.1.2.1.31.1.1.1.1");
	        	@desc_inter = &snmpwalk($param, "desc");
			print "desc   $desc_inter[0]\n";
			print "i = $i\n";
        		$nb_desc = @desc_inter;

			if($desc_inter[0] ne "")
			{
        			$index_interface = "";

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

				# on trouve l'interface a la suite du snmpwalk
				# on remplit le fichier nom<=>index et on iterroge l'equipement
				if($ok_interro == 1)
     				{
                			if($lock_liste_ap == 0)
                			{
						$lock_liste_ap = 1;

						$ligne = "$host;$if;$index_interface";
						push @liste_if_ap,$ligne;
	
						$maj_if_ap_file = 1;				
						$lock_liste_ap = 0;	
					}
				
					my $oidin = "1.3.6.1.2.1.2.2.1.10.$index_interface";
	                		my $oidout = "1.3.6.1.2.1.2.2.1.16.$index_interface";
        	        		$r = $snmp->get_request(
                	        		-varbindlist   => [$oidin, $oidout],
                        			-callback   => [ \&get_if_octet,$base,$host,$if,$oidin,$oidout,$inverse,2,$community] );
				}
				else
				{
					writelog("get_if_snmp_ap",$config{'logopt'},"info",
                				"\t -> ERROR: Erreur, interface $if inexistante sur $host");
				}
			}
			else
                        {
				writelog("get_if_snmp_ap",$config{'logopt'},"info",
                                	"\t -> ERROR: $community\@$host ne répond pas");
                        }
		}
	}
}

sub get_if_name 
{
	my ($session,$base,$host,$community,$if,$oid,$id_if,$inverse) = @_;	

	my $result="";
	my $r="";
	my $ok_interro;
	#$id_if="";

	my ($snmp, $error) = Net::SNMP->session(
        	-hostname   => $host,
        	-community   => $community,
	        -port      => 161,
	        -timeout   => $config{"snmp_timeout"},
		-retries        => 2,
	        -nonblocking   => 0x1 );

	my $err=0;

	if (!defined($session->var_bind_list)) 
	{
       		my $error  = $session->error;
		
		writelog("get_if_snmp_ap",$config{'logopt'},"info",
                	"\t -> ERROR: get_if_name($host) Error: $error");
		
		$err=1;
    	} 
	else 
	{
       		$result = $session->var_bind_list->{$oid};
       		#print "get_if_name($host) $oid = $result\n";
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
               
		writelog("get_if_snmp_ap",$config{'logopt'},"info",
                	"\t -> ERROR: L'interface trouvee ne correspond pas a son index reel");
		
		# cherche liste des interfaces
                my $param = $community."@".$host;
                &snmpmapOID("desc","1.3.6.1.2.1.31.1.1.1.1");
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
			#print "tentative de correction\n";
			if($lock_liste_ap == 0)
                        {
	                        $lock_liste_ap = 1;
				my $t_liste_if_ap = @liste_if_ap;

				my $i;
				for($i=0;$i<$t_liste_if_ap;$i++)
				{
					(my $ip, my $inter, my $ind) = split(/;/,$liste_if_ap[$i]);
					if($ip eq $host && $if eq $inter)
					{
						$liste_if_ap[$i] = "$ip;$if;$index_interface";
					}	
				}
				$lock_liste_ap = 0;
				$maj_if_ap_file = 1;
			}
			else
			{
				writelog("get_if_snmp_ap",$config{'logopt'},"info",
                			"\t -> ERROR: Fichier interf_ap.txt locké. Pas de mise à jour");
			}
			$id_if = $index_interface;
		}
		else
		{
			writelog("get_if_snmp_ap",$config{'logopt'},"info",
                        	"\t -> ERROR: interface $if inexistante sur $host. Pas de mise à jour.");
		}
        }

	if($id_if ne "" && $ok_interro ==1)
	{
		my $oidin = "1.3.6.1.2.1.2.2.1.10.$id_if";
                my $oidout = "1.3.6.1.2.1.2.2.1.16.$id_if";
                $r = $snmp->get_request(
                	-varbindlist   => [$oidin, $oidout],
                	-callback   => [ \&get_if_octet,$base,$host,$if,$oidin,$oidout,$inverse,2,$community] );
	}
}

return 1;
