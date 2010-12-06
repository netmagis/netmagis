# $Id: sonde-if-snmp64.pl,v 1.1.1.1 2008/06/13 08:55:51 pda Exp $
#
#
# ###################################################################
# boggia : Creation : 03/12/2010
#
# fonctions qui permettent de récupérer en SNMP les compteurs d'erreurs 
# des interfaces
#

sub ifNom_error 
{
	my ($base,$host,$community,$if) = @_;

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
		writelog("get_if_multicast64",$config{'logopt'},"info",
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
		
		$oidin = "1.3.6.1.2.1.2.2.1.14.$if";
		$oidout = "1.3.6.1.2.1.2.2.1.20.$if";
		$result = $snmp->get_request(
                	-varbindlist   => [$oidin, $oidout],
                	-callback   => [ \&get_if_octet,$base,$host,$if,$oidin,$oidout,$inverse,2,$community] );

	    }
	    #sinon, recherche de l'index par rapport au nom de l'interface
	    else
	    {
		my $trouve_inter = 0;
		my $ligne = "";
		my $index_interface = "";

		# on recherche l'interface dans le fichier nom<=>index	
		my $t_liste_if64 = @liste_if64;
	
		for($i=0;$i<$t_liste_if64;$i++)
		{
			if($liste_if64[$i] !~/^#/ && $liste_if64[$i] !~/^\s*$/)
			{
	                	chomp $liste_if64[$i];
	                        (my $ip, my $inter, my $ind) = split(/;/,$liste_if64[$i]);
  
	                      	#si l'interface recherchee est trouvee
	                       	#on remplit la variable index
	                    	if($inter eq $if && $ip eq $host && $ind ne "")
	                        {
                        		$trouve_inter = 1;
                        	      	$index_interface = $ind;
					$i = $t_liste_if64;
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
			my $oid = "1.3.6.1.2.1.2.2.1.2.$index_interface";
			$r = $snmp->get_request(
				-varbindlist   => [$oid],
				-callback   => [ \&get_if64_name, $sonde,$base,$host,$community,$if,$oid,$index_interface,$inverse,"broadcast"] );

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
                			if($lock_liste_if64 == 0)
                			{
						$lock_liste_if64 = 1;

						$ligne = "$host;$if;$index_interface";
						push @liste_if64,$ligne;
	
						$maj_if64_file = 1;				
						$lock_liste_if64 = 0;	
					}
					
					$oidin = "1.3.6.1.2.1.2.2.1.14.$index_interface";
                			$oidout = "1.3.6.1.2.1.2.2.1.20.$index_interface";
                			$r = $snmp->get_request(
                        			-varbindlist   => [$oidin, $oidout],
                        			-callback   => [ \&get_if_octet,$base,$host,$if,$oidin,$oidout,$inverse,2,$community] );
				}
				else
				{
					writelog("get_if_broadcast64",$config{'logopt'},"info",
						"\t -> ERROR: interface $if inexistante sur $host");
				}
			}
			else
			{
				writelog("get_if_broadcast64",$config{'logopt'},"info",
                                	"\t -> ERROR: $community\@$host ne répond pas");
			}
		}
	    }
	}
}


return 1;
