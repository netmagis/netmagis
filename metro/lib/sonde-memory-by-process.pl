# $Id: sonde-memory-by-process.pl,v 1.1.1.1 2008-06-13 08:55:51 pda Exp $	
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

sub get_url
{
    my ($base,$host,$community,$url,$type_sonde) = @_;
    
    my $sonde_trouve = "";	

    if(! $community)
    {
	writelog("get_value",$config{'logopt'},"info",
                        "\t -> ERROR: ($host,$url), Pas de communaute SNMP");
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
			"\t -> ERROR: SNMP connect error: ($host,$community,$url), $error");
        }
	else
	{
	    # recherche de l'index par rapport au nom de l'URL
	    my $trouve_sonde = 0;
	    my $ligne = "";
	    my $index_sonde = "";

	    # on recherche l'URL dans le fichier nom<=>index	
	    my $t_liste_url = @liste_url;
	
	    for($i=0;$i<$t_liste_url;$i++)
	    {
		if($liste_url[$i] !~/^#/ && $liste_url[$i] !~/^\s*$/)
		{
		    chomp $liste_url[$i];
	            (my $ip, $sonde_trouve, my $ind) = split(/;/,$liste_url[$i]);
  
	            #si l'interface recherchee est trouvee
	            #on remplit la variable index
	            if($url eq $sonde_trouve && $ip eq $host && $ind ne "")
	            {
                    	$trouve_sonde = 1;
                       	$index_sonde = $ind;
			$i = $t_liste_url;
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
		    -callback   => [ \&get_url_name,$sonde,$base,$host,$community,$url,$oid,$index_sonde,$type_sonde] );
	    }
	    # sinon, il faut rechercher l'index de l'URL et remplir le fichier nom<=>idex
	    else
	    {
		my @desc_url=();
		# cherche liste des URL
		$param = $community."@".$host;
		&snmpmapOID("desc","1.3.6.1.4.1.2021.8.1.2");
	       	@desc_url = &snmpwalk($param, "desc");

        	$nb_desc = @desc_url;

		if($desc_url[0] ne "")
		{
		    $index_sonde = "";

		    my $i;	
		    for($i=0;$i<$nb_desc;$i++)
		    {
   	             	if($desc_url[$i]=~m/$url/)
	        	{
			    #print "$desc_url[$i]\n";
			    chomp $desc_url[$i];
			    $index_sonde = (split(/:/,$desc_url[$i]))[0];
        		    #       print "index = $index_sonde\n";
	                    $i = $nb_desc;
			    $ok_interro = 1;
	               	}
		    }
		    # on trouve lURL à la suite du snmpwalk
		    # on remplit le fichier nom<=>index et on iterroge l'equipement
		    if($ok_interro == 1)
		    {
        	   	if($lock_liste_url == 0)
                	{
			   $lock_liste_url = 1;
	
			    $ligne = "$host;$url;$index_sonde";
			    push @liste_url,$ligne;
	
			    $maj_url_file = 1;				
			    $lock_liste_url = 0;	
			}

			my $oid_time_url = "1.3.6.1.4.1.2021.8.1.101.$index_sonde";
                	$r = $snmp->get_request(
			    varbindlist   => [$oid_time_url],
			    -callback   => [ \&get_time_url,$base,$host,$url,$oid_time_url,$type_sonde] );
		    }	
		    else
		    {
			writelog("get_time_www",$config{'logopt'},"info",
			    "\t -> ERROR: URL $url inexistante sur $host");
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

sub get_url_name 
{
	my ($session,$sonde,$base,$host,$community,$sonde_trouve,$oid,$id_url,$type_sonde) = @_;	

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
			"\t -> ERROR: get_url_name($host) Error: $error");
		
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
                my @desc_url = &snmpwalk($param, "desc");

                my $nb_desc = @desc_url;

                my $index_sonde = "";
	
		my $i;
                for($i=0;$i<$nb_desc;$i++)
                {
                        if($desc_url[$i]=~m/$sonde_trouve/)
                        {
                                #print "$desc_url[$i]\n";
                                chomp $desc_url[$i];
                                $index_sonde = (split(/:/,$desc_url[$i]))[0];
                                #       print "index = $index_sonde\n";
                                $i = $nb_desc;
                                $ok_interro = 1;
                        }
                }

		if($ok_interro == 1)
		{
			#print "tentative de correction\n";
			if($lock_liste_url == 0)
                        {
	                        $lock_liste_url = 1;
				my $t_liste_url = @liste_url;
				
				my $i;
				for($i=0;$i<$t_liste_url;$i++)
				{
					(my $ip, my $url, my $ind) = split(/;/,$liste_url[$i]);
					if($ip eq $host && $sonde_trouve eq $url)
					{
						$liste_url[$i] = "$ip;$sonde_trouve;$index_sonde";
					}	
				}
				$lock_liste_url = 0;
				$maj_url_file = 1;
			}
			else
			{
				writelog("get_time_www",$config{'logopt'},"info",
					"\t -> ERROR: Fichier url.txt locké. Pas de mise à jour");
			}
			$id_url = $index_sonde;
		}
		else
		{
			writelog("get_time_www",$config{'logopt'},"info",
				"\t -> ERROR: URL $sonde_trouve inexistante sur $host. Pas de mise à jour.");
		}
        }

	if($id_url ne "" && $ok_interro ==1)
	{
		my $oid_time_url = "1.3.6.1.4.1.2021.8.1.101.$id_url";

                $r = $snmp->get_request(
                	-varbindlist   => [$oid_time_url],
                	-callback   => [ \&get_time_url,$base,$host,$sonde_trouve,$oid_time_url,$type_sonde] );
	}
}



# recupere le resultat des requetes SNMP sur les interfaces
sub get_time_url
{
    my ($session,$base,$host,$sonde_trouve,$oid_time_url,$type_sonde) = @_;

    my ($r_time_url);
    if (!defined($session->var_bind_list))
    {
	my $error  = $session->error;

        writelog("get_time_www",$config{'logopt'},"info",
	    "\t -> ERROR: get_time_www($host) Error: $error");
    }
    else
    {
	$r_time_url = $session->var_bind_list->{$oid_time_url};

        RRDs::update ("$base","N:$r_time_url");
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
			system("echo \"$sonde_trouve-trep;GaugeTempsReponse;1;$base;Temps de reponse de $sonde_trouve\" >> $config{'path_etc'}/index.graph");
			#$sonde_trouve-trep;GaugeTempsReponse;1;$base;Temps de reponse de $sonde_trouve
		    }
		    elsif($type_sonde eq "get_memory_by_proc")
		    {
			creeBaseVolumeOctets($base);
			writelog("get_memory_by_proc",$config{'logopt'},"info",
                             "\t -> create $base");
                        system("echo \"$sonde_trouve-membyproc;GaugeMemByProc;1;$base;Utilisation memoire de $sonde_trouve\" >> $config{'path_etc'}/index.graph");
		    }
		    elsif($type_sonde eq "get_nb_mbuf_juniper")
                    {
                        creeBaseNbMbuf($base);
                        writelog("get_mbuf_juniper",$config{'logopt'},"info",
                             "\t -> create $base");
                        system("echo \"$sonde_trouve-mbufjuniper;GaugeNbMbufJuniper;1;$base;Nombre de mbufs sur les Juniper $sonde_trouve\" >> $config{'path_etc'}/index.graph");
                    }
		    elsif($type_sonde eq "get_fast_rep_time")
                    {
			creeBaseTpsRepWWWFast($base);
			writelog("get_fast_rep_time",$config{'logopt'},"info",
                             "\t -> create $base");
			system("echo \"$sonde_trouve-trepFast;GaugeTempsReponse;1;$base;Temps de reponse de $sonde_trouve\" >> $config{'path_etc'}/index.graph");
		    }
		    elsif($type_sonde eq "get_fast_memory_by_proc")
                    {
			creeBaseVolumeOctetsFast($base);
			writelog("get_fast_memory_by_proc",$config{'logopt'},"info",
                             "\t -> create $base");
			system("echo \"$sonde_trouve-membyprocFast;GaugeMemByProc;1;$base;Utilisation memoire de $sonde_trouve\" >> $config{'path_etc'}/index.graph");
                    }
		    elsif($type_sonde eq "get_value_generic")
                    {
                        creeBaseNbGeneric($base);
                        writelog("get_value_generic",$config{'logopt'},"info",
                             "\t -> create $base");
                        system("echo \"$sonde_trouve-value_generic;GaugeGeneric;1;$base;Valeur pour $sonde_trouve\" >> $config{'path_etc'}/index.graph");
                    }
                }
           }
        }
    }
}


return 1;
