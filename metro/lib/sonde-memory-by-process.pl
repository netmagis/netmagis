# $Id: sonde-memory-by-process.pl,v 1.1.1.1 2008/06/13 08:55:51 pda Exp $	
#
#
# ###################################################################
# boggia : Creation : 27/03/08
#
# sonde generique permettant de recuperer une valeur pour un graphique 
# de type gauge sur un serveur
# travaille dans la mib privée ucd-davis
# oid .1.3.6.1.4.1.2021.8.1.X
# prend en paramètre une adresse IP de serveur
#		     communauté SNMP
#		     le nom de la gauge qui doit etre cree au prealable 
#		     sur le serveur
# exemples dans l'un des fichiers de /local/obj999/etc/update_rrd :
# get_tempsRep /local/obj999/db/tempsReponse/tRepWWWlistes-auth.ulp.u-strasbg.fr.rrd 
# 130.79.201.129 <community> listes-auth.ulp.u-strasbg.fr
# get_memory_by_proc /local/obj999/db/size/memoire_dhcp 130.79.208.190 <community> 
# memoire_dhcp

sub get_generic
{
    my ($base,$host,$community,$generic,$type_sonde) = @_;
    
    my $sonde_trouve = "";	

    if(! $community)
    {
	writelog("get_value",$config{'logopt'},"info",
                        "\t -> ERROR: ($host,$generic), Pas de communaute SNMP");
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
		writelog("get_time_www",$config{'logopt'},"info",
			"\t -> ERROR: SNMP connect error: ($host,$community,$generic), $error");
        }
	else
	{
	    # recherche de l'index par rapport au nom de l'URL
	    my $trouve_sonde = 0;
	    my $ligne = "";
	    my $index_sonde = "";

	    # on recherche l'URL dans le fichier nom<=>index	
	    my $t_liste_generic = @liste_generic;
	
	    for($i=0;$i<$t_liste_generic;$i++)
	    {
		if($liste_generic[$i] !~/^#/ && $liste_generic[$i] !~/^\s*$/)
		{
		    chomp $liste_generic[$i];
	            (my $ip, $sonde_trouve, my $ind) = split(/;/,$liste_generic[$i]);
  
	            #si l'interface recherchee est trouvee
	            #on remplit la variable index
	            if($generic eq $sonde_trouve && $ip eq $host && $ind ne "")
	            {
                    	$trouve_sonde = 1;
                       	$index_sonde = $ind;
			$i = $t_liste_generic;
 	            }
	        }
	    }
	
	    my $ok_interro = 0;
	    # si l'URL est présente dans le fichier nom<=>index,
	    # controle de cohérence de l'index par rapport au nom 
	    if($trouve_sonde == 1)
	    {
		#ifMib, description
		my $oid = "1.3.6.1.4.1.2021.8.1.2.$index_sonde";
		$r = $snmp->get_request(
		    -varbindlist   => [$oid],
		    -callback   => [ \&get_generic_name,$sonde,$base,$host,$community,$generic,$oid,$index_sonde,$type_sonde] );
	    }
	    # sinon, il faut rechercher l'index de l'URL et remplir le fichier nom<=>idex
	    else
	    {
		my @desc_generic=();
		# cherche liste des URL
		$param = $community."@".$host;
		&snmpmapOID("desc","1.3.6.1.4.1.2021.8.1.2");
	       	@desc_generic = &snmpwalk($param, "desc");

        	$nb_desc = @desc_generic;

		if($desc_generic[0] ne "")
		{
		    $index_sonde = "";

		    my $i;	
		    for($i=0;$i<$nb_desc;$i++)
		    {
   	             	if($desc_generic[$i]=~m/$generic/)
	        	{
			    chomp $desc_generic[$i];
			    $index_sonde = (split(/:/,$desc_generic[$i]))[0];
        		    #       print "index = $index_sonde\n";
	                    $i = $nb_desc;
			    $ok_interro = 1;
	               	}
		    }
		    # on trouve lURL à la suite du snmpwalk
		    # on remplit le fichier nom<=>index et on iterroge l'equipement
		    if($ok_interro == 1)
		    {
        	   	if($lock_liste_generic == 0)
                	{
			   $lock_liste_generic = 1;
	
			    $ligne = "$host;$generic;$index_sonde";
			    push @liste_generic,$ligne;
	
			    $maj_generic_file = 1;				
			    $lock_liste_generic = 0;	
			}

			my $oid_time_generic = "1.3.6.1.4.1.2021.8.1.101.$index_sonde";
                	$r = $snmp->get_request(
			    varbindlist   => [$oid_time_generic],
			    -callback   => [ \&get_time_generic,$base,$host,$generic,$oid_time_generic,$type_sonde] );
		    }	
		    else
		    {
			writelog("get_time_www",$config{'logopt'},"info",
			    "\t -> ERROR: URL $generic inexistante sur $host");
		    }
		}
		else
		{
		    writelog("get_time_www",$config{'logopt'},"info",
			"\t -> ERROR: $community\@$host ne répond pas");
		}
	    }
	}	
    }
}

sub get_generic_name 
{
	my ($session,$sonde,$base,$host,$community,$sonde_trouve,$oid,$id_generic,$type_sonde) = @_;	

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

		writelog("get_time_www",$config{'logopt'},"info",
			"\t -> ERROR: get_generic_name($host) Error: $error");
		
		$err=1;
    	} 
	else 
	{
       		$result = $session->var_bind_list->{$oid};
       		#print "get_if_name($host) $oid = $result\n";
    	}

	if($result=~m/$sonde_trouve/ && $err==0)
        #si le nom de l'interface a toujours le meme index
        {
                $ok_interro = 1;
                #print "\nL'interface trouvee correspond a son index reel\n";
        }
        elsif($err == 0)
        {
                $ok_interro = 0;
               
		writelog("get_time_www",$config{'logopt'},"info",
                	"\t -> ERROR: L'URL recherchee ($sonde_trouve) trouve ne correspond pas a son index reel");
		
		# cherche liste des interfaces
                my $param = $community."@".$host;
                &snmpmapOID("desc","1.3.6.1.4.1.2021.8.1.2");
                my @desc_generic = &snmpwalk($param, "desc");

                my $nb_desc = @desc_generic;

                my $index_sonde = "";
	
		my $i;
                for($i=0;$i<$nb_desc;$i++)
                {
                        if($desc_generic[$i]=~m/$sonde_trouve/)
                        {
                                chomp $desc_generic[$i];
                                $index_sonde = (split(/:/,$desc_generic[$i]))[0];
                                #       print "index = $index_sonde\n";
                                $i = $nb_desc;
                                $ok_interro = 1;
                        }
                }

		if($ok_interro == 1)
		{
			#print "tentative de correction\n";
			if($lock_liste_generic == 0)
                        {
	                        $lock_liste_generic = 1;
				my $t_liste_generic = @liste_generic;
				
				my $i;
				for($i=0;$i<$t_liste_generic;$i++)
				{
					(my $ip, my $generic, my $ind) = split(/;/,$liste_generic[$i]);
					if($ip eq $host && $sonde_trouve eq $generic)
					{
						$liste_generic[$i] = "$ip;$sonde_trouve;$index_sonde";
					}	
				}
				$lock_liste_generic = 0;
				$maj_generic_file = 1;
			}
			else
			{
				writelog("get_time_www",$config{'logopt'},"info",
					"\t -> ERROR: Fichier generic.txt locké. Pas de mise à jour");
			}
			$id_generic = $index_sonde;
		}
		else
		{
			writelog("get_time_www",$config{'logopt'},"info",
				"\t -> ERROR: URL $sonde_trouve inexistante sur $host. Pas de mise à jour.");
		}
        }

	if($id_generic ne "" && $ok_interro ==1)
	{
		my $oid_time_generic = "1.3.6.1.4.1.2021.8.1.101.$id_generic";

                $r = $snmp->get_request(
                	-varbindlist   => [$oid_time_generic],
                	-callback   => [ \&get_time_generic,$base,$host,$sonde_trouve,$oid_time_generic,$type_sonde] );
	}
}



# recupere le resultat des requetes SNMP sur les interfaces
sub get_time_generic
{
    my ($session,$base,$host,$sonde_trouve,$oid_time_generic,$type_sonde) = @_;

    my ($r_time_generic);
    if (!defined($session->var_bind_list))
    {
	my $error  = $session->error;

        writelog("get_time_www",$config{'logopt'},"info",
	    "\t -> ERROR: get_time_www($host) Error: $error");
    }
    else
    {
	$r_time_generic = $session->var_bind_list->{$oid_time_generic};

        RRDs::update ("$base","N:$r_time_generic");
        my $ERR=RRDs::error;
        if ($ERR)
        {
	    writelog("get_time_www",$config{'logopt'},"info",
		"\t -> ERROR while updating $base: $ERR");

            if($ERR =~/No such file or directory/)
            {
		if($base =~/$config{'path_rrd_db'}/)
                {
		    if($type_sonde eq "get_tempsRep")
		    {
			creeBaseTpsRepWWW($base);
			writelog("get_time_www",$config{'logopt'},"info",
                             "\t -> create $base");
			#system("echo \"$sonde_trouve-trep;GaugeTempsReponse;1;$base;Temps de reponse de $sonde_trouve\" >> $config{''}/index.graph");
		    }
		    elsif($type_sonde eq "get_memory_by_proc")
		    {
			creeBaseVolumeOctets($base);
			writelog("get_memory_by_proc",$config{'logopt'},"info",
                             "\t -> create $base");
                        #system("echo \"$sonde_trouve-membyproc;GaugeMemByProc;1;$base;Utilisation memoire de $sonde_trouve\" >> $config{''}/index.graph");
		    }
		    elsif($type_sonde eq "get_nb_mbuf_juniper")
                    {
                        creeBaseNbMbuf($base);
                        writelog("get_mbuf_juniper",$config{'logopt'},"info",
                             "\t -> create $base");
                        #system("echo \"$sonde_trouve-mbufjuniper;GaugeNbMbufJuniper;1;$base;Nombre de mbufs sur les Juniper $sonde_trouve\" >> $config{''}/index.graph");
                    }
		    elsif($type_sonde eq "get_fast_rep_time")
                    {
			creeBaseTpsRepWWWFast($base);
			writelog("get_fast_rep_time",$config{'logopt'},"info",
                             "\t -> create $base");
			#system("echo \"$sonde_trouve-trepFast;GaugeTempsReponse;1;$base;Temps de reponse de $sonde_trouve\" >> $config{''}/index.graph");
		    }
		    elsif($type_sonde eq "get_fast_memory_by_proc")
                    {
			creeBaseVolumeOctetsFast($base);
			writelog("get_fast_memory_by_proc",$config{'logopt'},"info",
                             "\t -> create $base");
			#system("echo \"$sonde_trouve-membyprocFast;GaugeMemByProc;1;$base;Utilisation memoire de $sonde_trouve\" >> $config{''}/index.graph");
                    }
		    elsif($type_sonde eq "get_value_generic")
                    {
                        creeBaseNbGeneric($base);
                        writelog("get_value_generic",$config{'logopt'},"info",
                             "\t -> create $base");
                        #system("echo \"$sonde_trouve-value_generic;GaugeGeneric;1;$base;Valeur pour $sonde_trouve\" >> $config{''}/index.graph");
                    }
                }
           }
        }
    }
}


return 1;
