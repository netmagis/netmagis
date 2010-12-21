# $Id: sonde-tps-disk.pl,v 1.1.1.1 2008/06/13 08:55:51 pda Exp $
#
#
# ###################################################################
# boggia : Creation : 27/03/08
#
# fonctions qui permettent de récupérer en SNMP les transitions par
# seconde sur les disques des serveurs
#

sub tps_disk
{
    my ($base,$host,$community,$disk) = @_;
    
    my $dsk = "";	

    if(! $community)
    {
	writelog("get_tps_disk",$config{'logopt'},"info",
                        "\t -> ERROR: ($host,$disk), Pas de communaute SNMP");
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
      		-nonblocking   => 0x1, 
		-version	=> "2c" );
        
	if (!defined($snmp)) 
	{
		writelog("get_tps_disk",$config{'logopt'},"info",
			"\t -> ERROR: SNMP connect error: ($host,$community,$disk), $error");
        }
	else
	{
	    # recherche de l'index par rapport au nom du disque
	    my $trouve_disk = 0;
	    my $ligne = "";
	    my $index_disk = "";

	    # on recherche le disk dans le fichier nom<=>index	
	    my $t_liste_disk = @liste_disk;
	
	    for($i=0;$i<$t_liste_disk;$i++)
	    {
		if($liste_disk[$i] !~/^#/ && $liste_disk[$i] !~/^\s*$/)
		{
		    chomp $liste_disk[$i];
	            (my $ip, $dsk, my $ind) = split(/;/,$liste_disk[$i]);
  
	            #si l'interface recherchee est trouvee
	            #on remplit la variable index
	            if($disk eq $dsk && $ip eq $host && $ind ne "")
	            {
                    	$trouve_disk = 1;
                       	$index_disk = $ind;
			$i = $t_liste_disk;
 	            }
	        }
	    }
	
	    my $ok_interro = 0;
	    # si l'interface est présente dans le fichier nom<=>index,
	    # controle de cohérence de l'index par rapport au nom 
	    if($trouve_disk == 1)
	    {
		#ifMib, description
		my $oid = "1.3.6.1.4.1.2021.13.15.1.1.2.$index_disk";
		$r = $snmp->get_request(
		    -varbindlist   => [$oid],
		    -callback   => [ \&get_disk_name,$sonde,$base,$host,$community,$disk,$oid,$index_disk] );
	    }
	    # sinon, il faut rechercher l'index du disque et remplir le fichier nom<=>idex
	    else
	    {
		my @desc_disk=();
		# cherche liste des interfaces
		$param = $community."@".$host;
		&snmpmapOID("desc","1.3.6.1.4.1.2021.13.15.1.1.2");
	       	@desc_disk = &snmpwalk($param, "desc");

        	$nb_desc = @desc_disk;

		if($desc_disk[0] ne "")
		{
		    $index_disk = "";

		    my $i;	
		    for($i=0;$i<$nb_desc;$i++)
		    {
   	             	if($desc_disk[$i]=~m/$disk/)
	        	{
			    #print "$desc_disk[$i]\n";
			    chomp $desc_disk[$i];
			    $index_disk = (split(/:/,$desc_disk[$i]))[0];
        		    #       print "index = $index_disk\n";
	                    $i = $nb_desc;
			    $ok_interro = 1;
	               	}
		    }
		    # on trouve le disque a la suite du snmpwalk
		    # on remplit le fichier nom<=>index et on iterroge l'equipement
		    if($ok_interro == 1)
		    {
        	   	if($lock_liste_disk == 0)
                	{
			   $lock_liste_disk = 1;
	
			    $ligne = "$host;$disk;$index_disk";
			    push @liste_disk,$ligne;
	
			    $maj_disk_file = 1;				
			    $lock_liste_disk = 0;	
			}

			my $oid_diskIOReads = "1.3.6.1.4.1.2021.13.15.1.1.5.$index_disk";
			my $oid_diskIOWrites = "1.3.6.1.4.1.2021.13.15.1.1.6.$index_disk";			
                	$r = $snmp->get_request(
			    -varbindlist   => [$oid_diskIOReads, $oid_diskIOWrites],
			    -callback   => [ \&get_disk_tps,$base,$host,$disk,$oid_diskIOReads,$oid_diskIOWrites] );
		    }	
		    else
		    {
			writelog("get_tps_disk",$config{'logopt'},"info",
			    "\t -> ERROR: disque $disk inexistante sur $host");
		    }
		}
		else
		{
		    writelog("get_tps_disk",$config{'logopt'},"info",
			"\t -> ERROR: $community\@$host ne répond pas");
		}
	    }
    	}
    }
}

sub get_disk_name 
{
	my ($session,$sonde,$base,$host,$community,$dsk,$oid,$id_disk) = @_;	

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

		writelog("get_tps_disk",$config{'logopt'},"info",
			"\t -> ERROR: get_disk_name($host) Error: $error");
		
		$err=1;
    	} 
	else 
	{
       		$result = $session->var_bind_list->{$oid};
       		#print "get_if_name($host) $oid = $result\n";
    	}

	if($result=~m/$dsk/ && $err==0)
        #si le nom de l'interface a toujours le meme index
        {
                $ok_interro = 1;
                #print "\nL'interface trouvee correspond a son index reel\n";
        }
        elsif($err == 0)
        {
                $ok_interro = 0;
               
		writelog("get_tps_disk",$config{'logopt'},"info",
                	"\t -> ERROR: Le disque ($dsk) trouve ne correspond pas a son index reel");
		
		# cherche liste des interfaces
                my $param = $community."@".$host;
                &snmpmapOID("desc","1.3.6.1.4.1.2021.13.15.1.1.2");
                my @desc_disk = &snmpwalk($param, "desc");

                my $nb_desc = @desc_disk;

                my $index_disk = "";
	
		my $i;
                for($i=0;$i<$nb_desc;$i++)
                {
                        if($desc_disk[$i]=~m/$dsk/)
                        {
                                #print "$desc_disk[$i]\n";
                                chomp $desc_disk[$i];
                                $index_disk = (split(/:/,$desc_disk[$i]))[0];
                                #       print "index = $index_disk\n";
                                $i = $nb_desc;
                                $ok_interro = 1;
                        }
                }

		if($ok_interro == 1)
		{
			#print "tentative de correction\n";
			if($lock_liste_disk == 0)
                        {
	                        $lock_liste_disk = 1;
				my $t_liste_disk = @liste_disk;
				
				my $i;
				for($i=0;$i<$t_liste_disk;$i++)
				{
					(my $ip, my $disk, my $ind) = split(/;/,$liste_disk[$i]);
					if($ip eq $host && $dsk eq $disk)
					{
						$liste_disk[$i] = "$ip;$dsk;$index_disk";
					}	
				}
				$lock_liste_disk = 0;
				$maj_disk_file = 1;
			}
			else
			{
				writelog("get_tps_disk",$config{'logopt'},"info",
					"\t -> ERROR: Fichier disk.txt locké. Pas de mise à jour");
			}
			$id_disk = $index_disk;
		}
		else
		{
			writelog("get_tps_disk",$config{'logopt'},"info",
				"\t -> ERROR: disque $dsk inexistante sur $host. Pas de mise à jour.");
		}
        }

	if($id_disk ne "" && $ok_interro ==1)
	{
		my $oid_diskIOReads = "1.3.6.1.4.1.2021.13.15.1.1.5.$id_disk";
                my $oid_diskIOWrites = "1.3.6.1.4.1.2021.13.15.1.1.6.$id_disk";

                $r = $snmp->get_request(
                	-varbindlist   => [$oid_diskIOReads, $oid_diskIOWrites],
                	-callback   => [ \&get_disk_tps,$base,$host,$dsk,$oid_diskIOReads,$oid_diskIOWrites] );
	}
}



# recupere le resultat des requetes SNMP sur les interfaces
sub get_disk_tps
{
    my ($session,$base,$host,$dsk,$oid_diskIOReads,$oid_diskIOWrites) = @_;

    my ($r_IOReads,$r_IOWrites);
    if (!defined($session->var_bind_list))
    {
	my $error  = $session->error;

        writelog("get_tps_disk",$config{'logopt'},"info",
	    "\t -> ERROR: get_tps_disk($host) Error: $error");
    }
    else
    {
	$r_IOReads = $session->var_bind_list->{$oid_diskIOReads};
        $r_IOWrites = $session->var_bind_list->{$oid_diskIOWrites};

        RRDs::update ("$base","N:$r_IOReads:$r_IOWrites");
        my $ERR=RRDs::error;
        if ($ERR)
        {
	    writelog("get_tps_disk",$config{'logopt'},"info",
		"\t -> ERROR while updating $base: $ERR");
        }
    }
}


return 1;
