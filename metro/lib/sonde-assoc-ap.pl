# $Id: sonde-assoc-ap.pl,v 1.2 2008-08-01 13:11:53 boggia Exp $
# ###################################################################
# boggia : Creation : 25/03/08
# boggia : Modification : Creation de la fonction get_authaccess_list
#			  dans le but de creer le tableau de bord 
#			  WiFi pour les corrspondants reseau
#
# fonctions de traitement des associations et authentifications
# par SSID sur les AP WiFi
#   - generation de rapports d'assoc
#   - remplissage de bases rrdtools pour grapher les associations
#   - fermeture dans les bases PGSQL des sessions d'authentification 
#     en particulier pour le mode 802.1X lorsqu'une machine est 
#     definitivement deconnectée du reseau
#

# activation de la supervision du nb d'associations pour un SSID sur
# une interface
sub get_nbassocwifi
{
        my ($base,$host,$community,$param) = @_;

	my ($if,$ssid) = (split(/,/,$param))[0,1];

        $APSupSSID{$host}{$if}{$ssid}{'nbassocwifi'}{'base'} = $base;
        $APSupSSID{$host}{$if}{$ssid}{'nbassocwifi'}{'nb_clients'} = 0;
}


# activation de la supervision du nb d'authentification pour un SSID sur
# une interface
sub get_nbauthwifi
{
        my ($base,$host,$community,$param) = @_;

	my ($if,$ssid) = (split(/,/,$param))[0,1];
	
        $APSupSSID{$host}{$if}{$ssid}{'nbauthwifi'}{'base'} = $base;
        $APSupSSID{$host}{$if}{$ssid}{'nbauthwifi'}{'nb_clients'} = 0;
}


# on veut d'abord obtenir en SNMP la listes des interfaces physiques de l'AP
sub get_assoc_ap
{
	my ($base,$host,$community) = @_;

	my ($snmp, $error) = Net::SNMP->session(
                -hostname   	=> $host,
                -community   	=> $community,
                -port      	=> 161,
                -timeout   	=> $config{"snmp_timeout"},
		-retries	=> 2,
                -nonblocking   	=> 0x1,
		-version        => "2c" );

        if (!defined($snmp))
        {
		writelog("get_assoc_ap",$config{'logopt'},"info",
        		"\t -> ERROR: SNMP connect error: $error");
        }
	else
	{
	    my $assoc_oid = '.1.3.6.1.2.1.2.2.1.2';
	    my $res = $snmp->get_table(
		$assoc_oid,
                -callback   => [ \&get_assoc,$snmp,$base,$host,$assoc_oid,$community] );
	}
}


# on recupere ensuite en SNMP la listes des associations
sub get_assoc
{
        my ($this,$session,$base,$host,$assoc_oid,$community) = @_;

        my %liste_if;

        if(defined($this->var_bind_list()))
        {
                # Extract the response.
                my $hashref = $this->var_bind_list();

                my @liste = ();
                my $i=0;
                my ($j,$securise,$mac,$ssid,$t_liste,$char,$temp,$iface);

                # on met la liste des interface de l'AP dans un hash
                foreach my $key (keys %$hashref)
                {
                        my ($index) = (split(/$assoc_oid\./,$key))[1];
                        $liste_if{$index} = $hashref->{$key};

                        print "$host : $key = $hashref->{$key}\n";
                }

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
		    writelog("get_assoc_ap",$config{'logopt'},"info",
	                "\t -> ERROR: SNMP connect error: $error");
		}
		else
		{
		    my $assoc_oid = '1.3.6.1.4.1.9.9.273.1.2.1.1.6';
		    my $res = $snmp->get_table(
		    $assoc_oid,
		    -callback   => [ \&get_snmp_assoc_ap,$snmp,$base,$host,$assoc_oid,%liste_if] );
		}

        }
        else
        {
                writelog("get_assoc_ap",$config{'logopt'},"info",
                        "\t -> ERROR: $host aucune liste d'interfaces pour ce point d'accès");

		# on veut le nom de l'AP pour la supervision de l'etat de l'AP
		my $iaddr = inet_aton($host);
		my $hostname  = gethostbyaddr($iaddr, AF_INET);
		($hostname)=(split(/\./,$hostname))[0];
		
		# l'ap ne repond pas
                $liste_ap_state{"$hostname"} = -1;
        }
}


# traitement des donnees recueillies sur l'AP
sub get_snmp_assoc_ap
{
    my ($this,$session,$base,$host,$assoc_oid,%liste_if) = @_;

    my $nb_wpa = 0;
    my $nb_clair = 0;
    my @tab = ();
    my @ssid = ();
    my ($t_tab,$t_ssid);

    # calcul du temps machine lors du lancement du programme
    my $time_rrddb = time;
    my $rmodulo = $time_rrddb % 300;
    $time_rrddb = $time_rrddb - $rmodulo;

    # on souhaite utiliser le nom de l'ap pour les logs.
    my $iaddr = inet_aton($host);
    my $hostname  = gethostbyaddr($iaddr, AF_INET);
    ($hostname)=(split(/\./,$hostname))[0];

    if(!$hostname)
    {
        writelog("get_assoc_ap",$config{'logopt'},"info",
	    "\t -> ERROR: echec de resolution de $host = $hostname dans $base");
    }

    # si le point d'acces n'a pas encore ete interroge
    if(!exists $liste_ap_state{$hostname})
    {
	my $file_temp = "/tmp/$hostname.rap";
	
	if(defined($this->var_bind_list())) 
	{
	    	# Extract the response.
	    	my $key = '';
	    	my $hashref = $this->var_bind_list();
		
		my @liste = ();
		my $i=0;
		my ($j,$securise,$mac,$ssid,$t_liste,$char,$temp,$iface);

		foreach $key (keys %$hashref) 
		{
			# wpa ou non
        		$securise=$hashref->{$key};

        		if($securise == 1)
        		{
                		$tab[$i][2] = 1;
                		$nb_wpa ++;
        		}
        		else
        		{
                		$tab[$i][2] = 0;
                		$nb_clair ++;
        		}

			# MAC, SSID et INDEX interface
                        @liste = ();
                        $mac = "";
                        $ssid = "";
                        $iface = "";

			($key) = (split(/$assoc_oid\./,$key))[1];
        		
			@liste = split(/\./,$key);
        		$t_liste = @liste;

        		for($j=0;$j<$t_liste;$j++)
        		{
			    if($j == 0)
                            {
				$iface = $liste[$j];
                            }
			    elsif($j < ($t_liste - 6))
			    {
                        	if($liste[$j] > 32)
                        	{
				    $char = sprintf("%c", $liste[$j]);
                        	}
                        	else
                        	{
				    $char = "";
                        	}
                        	if($ssid eq "")
                        	{
				    $ssid = $char;
                        	}
                        	else
                        	{
				    $ssid = "$ssid$char";
                        	}
			    }
			    else
			    {
                        	$temp = sprintf("%.2x", $liste[$j]);
                        	if($mac eq "")
                        	{
                               		$mac = $temp;
                        	}
                        	else
                        	{
                               		$mac = "$mac:$temp";
                        	}
			    }
        		}

        		$tab[$i][0] = $mac;
        		$tab[$i][1] = $ssid;
			$tab[$i][3] = $iface;
        	
                        if(exists $APSupSSID{$host}{$liste_if{$iface}}{$ssid})
                        {
                                foreach my $key2 (keys %{$APSupSSID{$host}{$liste_if{$iface}}{$ssid}})
                                {
                                        if($key2 eq "nbassocwifi")
                                        {
                                                $APSupSSID{$host}{$liste_if{$iface}}{$ssid}{'nbassocwifi'}{'nb_clients'} ++;
                                        }
                                        elsif($key2 eq "nbauthwifi")
                                        {
                                                if(exists $mac_auth{$mac})
                                                {
                                                        $APSupSSID{$host}{$liste_if{$iface}}{$ssid}{'nbauthwifi'}{'nb_clients'} ++;
                                                }
                                        }
                                }
                        }
	
			$collsess{"$hostname"." "."$mac"." "."$ssid"} =  $tab[$i][2] ;

			$i++
                }
		$liste_ap{"$hostname"} = $i;
		
		# pour l'état de l'AP
		$liste_ap_state{"$hostname"} = $i;
	}
	else
	{
		# il n'y a pas d'associés dans le point d'accès
		$liste_ap{"$hostname"} = 0;
		my $error  = $this->error;

		# l'ap ne fait rien
                $liste_ap_state{"$hostname"} = 0;

		if($error=~m/No response from remote host/)
		{
			writelog("get_assoc_ap",$config{'logopt'},"info",
                        	"\t -> ERROR: get_snmp_assoc_ap($host) Error: $error");

			# l'AP ne répond pas
                	$liste_ap_state{"$hostname"} = -1;
		}
	}

	foreach my $key (keys %{$APSupSSID{$host}})
        {
                foreach my $key2 (keys %{$APSupSSID{$host}{$key}})
                {
                        foreach my $key3 (keys %{$APSupSSID{$host}{$key}{$key2}})
                        {
				RRDs::update ("$APSupSSID{$host}{$key}{$key2}{$key3}{'base'}","$time_rrddb:$APSupSSID{$host}{$key}{$key2}{$key3}{'nb_clients'}");
                        }
                }
        }

	RRDs::update ("$base","$time_rrddb:$nb_wpa:$nb_clair");
        my $ERR=RRDs::error;
        if($ERR)
        {
		writelog("get_assoc_ap",$config{'logopt'},"info",
                	"\t -> ERROR while updating $base: $ERR");
        }

	##### mise a jour des fichiers de log des associations
	#ouverture du fichier contenant la dernière ligne de rapport
	my $elem;
	my $ligne = "";

	my $size = -s $file_temp;
	if($size > 0)
	{
        	open(RAP, "$file_temp");
        	$ligne = <RAP>;
        print "\n$ligne\n";
        	close(RAP);
        	chomp $ligne;
	}

        $t_tab = @tab;
        if($ligne ne "")
        {
		#print "ICI :)";
		my @liste_connexions = ();
		my @tab_temp = ();
		my $t_liste_connexions;
		my ($i,$j,$ok,$k);

                @liste_connexions = split(/\|/,$ligne);
                $t_liste_connexions = @liste_connexions;
		$k = 0;
                for($i=0;$i<$t_liste_connexions;$i++)
                {
			if($liste_connexions[$i]=~/([0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}) ([0-9a-zA-Z1-9\-\_]{1,50}) ([0-9])/)
			{
			    $tab_temp[$k][0] = $1; 
			    $tab_temp[$k][1] = $2;
			    $tab_temp[$k][2] = $3;
			    print "temp = $tab_temp[$k][0],$tab_temp[$k][1],$tab_temp[$k][2]\n";
			    $k ++;
			}
			else
			{
			    print "liste_conn = $liste_connexions[$i]\n";
			}
                }
                #on vide les connexions disparues de tab_temp
                for($i=0;$i<$k;$i++)
                {
                        $ok = 0;
                        for($j=0;$j<$t_tab;$j++)
                        {
				#print "contenu tab = $tab[$j][0]\n";
                                if($tab[$j][0] eq $tab_temp[$i][0])
                                {
                                        $ok = 1;
                                }
                        }
                        if($ok == 0)
                        {
                                $tab_temp[$i][0] = "";
                                $tab_temp[$i][1] = "";
                                $tab_temp[$i][2] = "";
                        }
                }
		$t_liste_connexions = $k;
		while(($tab_temp[$t_liste_connexions-1][0] eq "") && ($t_liste_connexions>0))
                {
                        $t_liste_connexions --;
                }
                #on remplit tab_temp avec les nouvelles connexions
                for($j=0;$j<$t_tab;$j++)
                {
                        $ok = 0;
                        for($i=0;$i<$t_liste_connexions;$i++)
                        {
                                if($tab[$j][0] eq $tab_temp[$i][0])
                                {
                                        $tab_temp[$i][1] = $tab[$j][1];
                                        $tab_temp[$i][2] = $tab[$j][2];
                                        $ok = 1;
                                }
                        }
                        if($ok == 0)
                        {
                                for($i=0;$i<$t_liste_connexions;$i++)
                                {
                                        if($tab_temp[$i][0] eq "" && $ok == 0)
                                        {
                                                $tab_temp[$i][0] = $tab[$j][0];
                                                $tab_temp[$i][1] = $tab[$j][1];
                                                $tab_temp[$i][2] = $tab[$j][2];
                                                $ok = 1;
                                        }
                                }
                        }
                        if($ok == 0)
                        {
                                $tab_temp[$t_liste_connexions][0] = $tab[$j][0];
                                $tab_temp[$t_liste_connexions][1] = $tab[$j][1];
                                $tab_temp[$t_liste_connexions][2] = $tab[$j][2];
                                $t_liste_connexions ++;
                        }
                }
	
                my $date = `date "+%Y-%m-%d %H:%M:%S"`;
		my ($ligne_format,$remplissage);

                chomp $date;

		$ligne = "";
                $ligne_format = "$date ";
                for($j=0;$j<$t_liste_connexions;$j++)
                {
                        $ligne = "$ligne|$tab_temp[$j][0] $tab_temp[$j][1] $tab_temp[$j][2]";
                        if($tab_temp[$j][0] ne "")
                        {
                                $ligne_format = "$ligne_format| $tab_temp[$j][0]";
                        }
                        else
                        {
                                $ligne_format = "$ligne_format|                  ";
                        }
                        @ssid = split(//,$tab_temp[$j][1]);
                        $t_ssid = @ssid;
                        if($t_ssid < 15)
                        {
                                $ligne_format = "$ligne_format $tab_temp[$j][1]";
                                $remplissage = 15 - $t_ssid;
                                for($k=0;$k<$remplissage;$k++)
                                {
                                        $ligne_format = "$ligne_format ";
                                }
                        }
                        else
                        {
                                $ligne_format = "$ligne_format $tab_temp[$j][1]";
                        }
                        if($tab_temp[$j][2] ne "")
                        {
                                $ligne_format = "$ligne_format $tab_temp[$j][2] ";
                        }
                        else
                        {
                                $ligne_format = "$ligne_format   ";
                        }
                }
		$ligne =~s/^\|//;
                open(RAP, ">/tmp/$hostname.rap");
                print RAP "$ligne";
                close(RAP);


                #teste si le reppertoire existe deja
                opendir(DIR_RAPPORT,"$config{'path_rapport_ap'}");
                @REP=grep(!/^\.\.?$/, readdir DIR_RAPPORT);
                closedir(DIR_RAPPORT);
                my $existe_rep = 0;
                foreach $elem (@REP)
                {
                        #print "$elem\n";
                        if($elem eq $hostname)
                        {
                        #        print "Le repertoire existe déjà. La nouvelle base sera cree dans ce repertoire\n";
                                $existe_rep = 1;
                        }
                }

                #creation du repertoire
                if($existe_rep == 0)
                {
                        system("mkdir $config{'path_rapport_ap'}/$hostname");
                        system("chown www:obj999 $config{'path_rapport_ap'}/$hostname");
                }

                open(LOG, ">>$config{'path_rapport_ap'}/$hostname/assoc.log");
                print LOG "$ligne_format\n";
                close (LOG);
        }
	else
        {
		#print "PAR LA :)";
                $date = `date "+%Y-%m-%d %H:%M:%S"`;
                chomp $date;
                $ligne = "";
                $ligne_format = "$date ";

                for($j=0;$j<$t_tab;$j++)
                {
                        $ligne = "$ligne|$tab[$j][0] $tab[$j][1] $tab[$j][2]";
                        $ligne_format = "$ligne_format| $tab[$j][0]";
                        @ssid = split(//,$tab[$j][1]);
                        $t_ssid = @ssid;
                        if($t_ssid < 15)
                        {
                                $ligne_format = "$ligne_format $tab[$j][1]";
                                $remplissage = 15 - $t_ssid;
                                for($k=0;$k<$remplissage;$k++)
                                {
                                        $ligne_format = "$ligne_format ";
                                }
                        }
                        else
                        {
                                $ligne_format = "$ligne_format $tab[$j][1]";
                        }
                        $ligne_format = "$ligne_format $tab[$j][2] ";
                }
                $ligne =~s/^\|//;
                open(RAP, ">/tmp/$hostname.rap");
                print RAP "$ligne";
                close(RAP);

                #teste si le reppertoire existe deja
                opendir(DIR_RAPPORT,"$config{'path_rapport_ap'}");
                @REP=grep(!/^\.\.?$/, readdir DIR_RAPPORT);
                closedir(DIR_RAPPORT);
                my $existe_rep = 0;
		
                foreach $elem (@REP)
                {
                        #print "$elem : $hostname\n";
	                if($elem eq $hostname)
                        {
                                #print "Le repertoire existe déjà. La nouvelle base sera cree dans ce repertoire\n";
                                $existe_rep = 1;
                        }
                }
                #creation du repertoire
                if($existe_rep == 0)
                {
                        system("mkdir $config{'path_rapport_ap'}/$hostname");
                        system("chown www:obj999 $config{'path_rapport_ap'}/$hostname");
                }

		
                open(LOG, ">>$config{'path_rapport_ap'}/$hostname/assoc.log");
                print LOG "$ligne_format\n";
                close (LOG);
        }
    }
    # le point d'acces a deja ete interroge, il y a une sonde en double
    # a supprimer
    else
    {
	writelog("get_assoc_ap",$config{'logopt'},"info",
	    "\t -> ERROR : Sonde en double : $base $host");
    }

}



######################################################
# fonction qui permet de recuperer la liste des 
# utilisateurs WiFi authentifies dans la base mac
sub get_authaccess
{
    my ($sql,$cursor,$ideq,$idauthaccess,$mac,$essid);

    #ouverture de la base PSQL
    my $db =  DBI->connect("dbi:Pg:dbname=$config{'PGDATABASE'};host=$config{'PGHOST'}", $config{'PGUSER'}, $config{'PGPASSWORD'});

    if($db)
    {
	writelog("get_authaccess",$config{'logopt'},"info",
                "\t -> INFO DB : Connexion a $config{'PGDATABASE'}");	
	
	#
        # Détermine les dernière sessions actives pour les Authentifications
        # idauthaccess |   login    |        mac        | ideq |           debut
        # -------------|------------+-------------------+------+----------------------------
        #    1234      |  inv67109  | 00:04:23:92:81:40 |  469 | 2007-09-21 15:24:56.383913
        #    4567      |  3mgarza   | 00:1b:63:c6:63:a5 |  469 | 2007-09-21 15:25:00.440779
        #    8901      |  3nharari  | 00:13:02:9e:a1:b5 |  469 | 2007-09-21 15:16:59.316753
        $sql = "SELECT sessionauthaccess.idauthaccess,
                authaccess.login,
                authaccess.mac,
                authaccess.ideq,
                EXTRACT(EPOCH FROM sessionauthaccess.debut)
                FROM authaccess,sessionauthaccess
                WHERE sessionauthaccess.close=0
                AND authaccess.idauthaccess = sessionauthaccess.idauthaccess";

        $cursor = $db->prepare($sql);
        $cursor->execute;

        $index = 0;
        while( ($idauthaccess,$login,$mac,$ideq,$debut) = $cursor->fetchrow )
        {
                $total_authsess[$index][0] = $idauthaccess;
                $total_authsess[$index][1] = $login;
                $total_authsess[$index][2] = $mac;
                $total_authsess[$index][3] = $ideq;
                $total_authsess[$index][4] = $debut;
		$mac_auth{$mac} = $ideq;
                $index ++;

                #### DEBUG
                print RAP "total_authsess : $idauthaccess\t$login\t$mac\t$ideq\t$debut\n";
        }

        $cursor->finish;
	
	if($index == 0)
        {
            writelog("get_authaccess",$config{'logopt'},"info",
                "\t -> ERREUR DB : Echec chargement de la liste des authentifications actives de $config{'PGDATABASE'}");
        }
        else
        {
            writelog("get_authaccess",$config{'logopt'},"info",
                "\t -> INFO DB : nombres d'authentifies WiFi dans $config{'PGDATABASE'} : $index");
        }

    }
    else
    {
	writelog("get_authaccess",$config{'logopt'},"info",
                "\t -> ERROR : Connexion impossible a la base $config{'PGDATABASE'}");
    }
}



######################################################
# Fonction de mise a jour des associations sur les APs
# et de fermeture des sessions d'authentifications par 
# rapport aux associations
# dans la base SQL
sub set_assoc_ap_base
{
    my ($sql,$cursor,$ideq,$nb_ap,$idassocwifi,$mac,$essid);
 
    #ouverture de la base PSQL
    my $db =  DBI->connect("dbi:Pg:dbname=$config{'PGDATABASE'};host=$config{'PGHOST'}", $config{'PGUSER'}, $config{'PGPASSWORD'});

    if($db)
    {
	####DEBUG
	open(RAP, ">/tmp/fermeture_session");
	####

	writelog("get_assoc_ap",$config{'logopt'},"info",
                "\t -> INFO DB : Connexion à $config{'PGDATABASE'}");

	#
	# récuperation des ID des AP
	#
	$sql="SELECT ideq,nom FROM eq";
	$cursor = $db->prepare($sql);
        $cursor->execute;
        while( ($ideq,$nom_ap) = $cursor->fetchrow )
        {
	    $index_ap{$nom_ap} = $ideq;	
	    if($nom_ap=~/-ap[0-9]+/)
	    {
		$nb_ap++;
	    }
	}
	$cursor->finish;

	if($nb_ap == 0)
	{
	    writelog("get_assoc_ap",$config{'logopt'},"info",
		"\t -> ERREUR DB : Echec chargement de la liste des AP de $config{'PGDATABASE'}");
	}

	#
        # Détermine les dernière sessions actives pour tous les AP
        #
	# idassocwifi | ideq |        mac        |   essid
	#-------------+------+-------------------+------------
	#       21978 |  450 | 00:08:d3:04:15:ff | osiris
        #       30124 |  645 | 00:0c:f1:53:b6:88 | osiris-sec
        $sql = "SELECT assocwifi.idassocwifi,
		assocwifi.ideq,
                assocwifi.mac,
                assocwifi.essid
                FROM assocwifi,sessionassocwifi
                WHERE sessionassocwifi.close=0
                AND assocwifi.idassocwifi = sessionassocwifi.idassocwifi";

        $cursor = $db->prepare($sql);
        $cursor->execute;

	my $index = 0;
        while( ($idassocwifi,$ideq,$mac,$essid) = $cursor->fetchrow )
        {
                $total_activesess[$index][0] = $idassocwifi;
		$total_activesess[$index][1] = $ideq;
		$total_activesess[$index][2] = $mac;
		$total_activesess[$index][3] = $essid;
		$index ++;

		#### DEBUG
		print RAP "total_activesess : $idassocwifi\t$ideq\t$mac\t$essid\n";
        }

	$cursor->finish;

	if($index == 0)
        {
            writelog("get_assoc_ap",$config{'logopt'},"info",
                "\t -> ERREUR DB : Echec chargement de la liste des sessions actives de $config{'PGDATABASE'}");
        }
	else
	{
	    writelog("get_assoc_ap",$config{'logopt'},"info",
                "\t -> INFO DB : nombres d'associés WiFi dans $config{'PGDATABASE'} : $index");
	}

	# parcours de la liste des AP et mise a jour des associations
	foreach $key (keys %liste_ap)
        {
	    #print "$key = $liste_ap{$key}\n";
	    set_assoc_db($db,$key,$liste_ap{$key});
	}

	## DEBUG
	close(RAP);
	###

	# parcours de la liste des authentifications et fermeture des sessions
	# dont l'adresse MAC du client n'est plus enregistree dans les associations
	set_auth_db(@total_authsess);

	writelog("poller",$config{'logopt'},"info",
                "\t\t -> INFO DB : Fin de la mise à jour de $config{'PGDATABASE'}");

    }
    else
    {
        writelog("poller",$config{'logopt'},"info",
                "\t\t -> ERREUR DB : Impossible d'ouvrir $config{'PGDATABASE'} : $DBI::errstr");
    }
}

# fonction qui controle la fermeture des sessions des authentifies 
# par rapport aux associations sur les points d'accès
sub set_auth_db
{
    my (@total_authsess) = @_;
    
    my $t_total_authsess = @total_authsess;
    my $t_total_activesess = @total_activesess;
    my ($i,$j);

    my $time = time;

    open(RAP, ">>/tmp/fermeture_session");
    print RAP "################\nFermeture des ssessions\n";
   
    my $db =  DBI->connect("dbi:Pg:dbname=$config{'PGDATABASE'};host=$config{'PGHOST'}", $config{'PGUSER'}, $config{'PGPASSWORD'}); 
    # balaye la table des authentifies
    for($i=0;$i<$t_total_authsess;$i++)
    {
	my @tab_trouveactiveassoc = ();
	my @tab_trouveactiveauth = ();
	my $t_trouveactiveassoc = 0;
	my $t_trouveactiveauth = 0;
    
	if($total_authsess[$i][2]=~/([0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2})/)
	{
	    $tab_trouveactiveauth[$t_trouveactiveauth] = $total_authsess[$i];
	    $t_trouveactiveauth ++;
	    
	    # cherche si l'adresse mac existe plus d'une fois dans la liste des authentifies
	    for($j=$i+1;$j<$t_total_authsess;$j++)
	    {
		if($total_authsess[$i][2] eq $total_authsess[$j][2])
		{
		    $tab_trouveactiveauth[$t_trouveactiveauth] = $total_authsess[$j];
		    $t_trouveactiveauth ++;
		    $total_authsess[$j][2] = "ok";
		}
	    }

	    # cherche l'adresse mac dans la table des associes
	    for($j=0;$j<$t_total_activesess;$j++)
	    {
		if($total_authsess[$i][2] eq $total_activesess[$j][2])
		{
		    $tab_trouveactiveassoc[$t_trouveactiveassoc] = $total_activesess[$j];
		    $t_trouveactiveassoc ++;
		}
	    }
	}

	####### DEBUG ##########################################################
	print RAP "###################################\nauthentifies\n";
	for($j=0;$j<$t_trouveactiveauth;$j++)
	{
	    print RAP "$tab_trouveactiveauth[$j][0]\t$tab_trouveactiveauth[$j][1]\t$tab_trouveactiveauth[$j][2]\t$tab_trouveactiveauth[$j][3]\t$tab_trouveactiveauth[$j][4]\n";
	}
	print RAP "### associes\n";
	for($j=0;$j<$t_trouveactiveassoc;$j++)
        {
            print RAP "$tab_trouveactiveassoc[$j][0]\t$tab_trouveactiveassoc[$j][1]\t$tab_trouveactiveassoc[$j][2]\t$tab_trouveactiveassoc[$j][3]\n";
        }
	########################################################################

	###### traitement de chaque session d'authentifie ######
	for($j=0;$j<$t_trouveactiveauth;$j++)
        {
	    if($t_trouveactiveassoc == 1)
	    {
		# l'adresse MAC de l'authentifie se trouve une seule fois dans la 
		# table des associes
		if($t_trouveactiveauth == 1)
		{
		    #l'adresse MAC de la machine est enregistree une seule fois dans 
		    #chaque table. Cas le plus typique
		    if($ssid_osiris{$tab_trouveactiveassoc[$j][3]} eq $tab_trouveactiveauth[$j][3])
		    {
			#si le serveur d'authentification correspond au SSID
			print RAP "===> maj date $tab_trouveactiveauth[$j][2], set fin = now\n";

			my $r = $db->prepare( "
			    UPDATE sessionauthaccess
			    SET fin=now(),close=0
			    WHERE idauthaccess=$tab_trouveactiveauth[$j][0]
			    AND close=0" );
			
			if(! $r->execute)
			{
			    writelog("get_assoc_ap",$config{'logopt'},"info",
				"\t\t -> ERREUR DB : impossible de maj la session d'auth ($tab_trouveactiveauth[$j][0],$tab_trouveactiveauth[$j][1],$tab_trouveactiveauth[$j][2]");
			}

			$r->finish;
		    }
		    else
		    {
			#si le serveur d'authentification ne correspond pas au SSID
			print RAP "===> incoherence $tab_trouveactiveauth[$j][2] SSID ne correspond pas a auth\n";
		    }
		}
		elsif($t_trouveactiveauth > 1)
		{
		    #l'adresse MAC se trouve dans plusieurs authentifications
		    my $k;
		    my $date_deb = 0;
		    for($k=$j;$k<$t_trouveactiveauth;$k++)
		    {
			if($ssid_osiris{$tab_trouveactiveassoc[$j][3]} ne $tab_trouveactiveauth[$k][3])
			{
			    print RAP "<> test : $ssid_osiris{$tab_trouveactiveassoc[$j][3]},$tab_trouveactiveassoc[$j][3] ne $tab_trouveactiveauth[$k][3] = oui\n";
			    #si le serveur d'authentification ne correspond pas au SSID, on ferme
			    if(($time - 300) > $tab_trouveactiveauth[$k][4])
			    {
				# on ne ferme que les sessions ouvertes depuis plus de 60 secondes
				
				print RAP "===> fermeture $tab_trouveactiveauth[$k][2] SSID ne correspond pas a auth\n";
	
				my $r = $db->prepare( "
				    UPDATE sessionauthaccess
				    SET close=1
				    WHERE idauthaccess=$tab_trouveactiveauth[$k][0]
				    AND close=0" );
				if(! $r->execute)
				{
				    writelog("get_assoc_ap",$config{'logopt'},"info",
				    "\t\t -> ERREUR DB : impossible des fermer la session d'auth ($tab_trouveactiveauth[$k][0],$tab_trouveactiveauth[$k][1],$tab_trouveactiveauth[$k][2]");
				}

			    }
			    $tab_trouveactiveauth[$k][2] = "ok";
			}
			elsif($tab_trouveactiveauth[$k][4] > $date_deb)
			{
			    #si le serveur d'authentification correspond au SSID et la date d'auth est plus
			    #recente que la plus recente trouvee
			    $date_deb = $tab_trouveactiveauth[$k][4];
			}
		    }
		    for($k=$j;$k<$t_trouveactiveauth;$k++)
                    {
			if($tab_trouveactiveauth[$k][2] ne "ok")
			{
			    if($tab_trouveactiveauth[$k][4] == $date_deb)
			    {
				print RAP "===> mise a jour $tab_trouveactiveauth[$k][2] set fin = now\n";

				my $r = $db->prepare( "
				    UPDATE sessionauthaccess
				    SET fin=now(),close=0
				    WHERE idauthaccess=$tab_trouveactiveauth[$k][0]
				    AND close=0" );
				if(! $r->execute)
				{
				    writelog("get_assoc_ap",$config{'logopt'},"info",
					"\t\t -> ERREUR DB : impossible de maj la session d'auth ($tab_trouveactiveauth[$k][0],$tab_trouveactiveauth[$k][1],$tab_trouveactiveauth[$k][2]");
				}
			    }
			    else
			    {
				print RAP "===> fermeture $tab_trouveactiveauth[$k][1],$tab_trouveactiveauth[$k][2] session trop vieille\n";
				
				my $r = $db->prepare( "
                                    UPDATE sessionauthaccess
                                    SET close=1
                                    WHERE idauthaccess=$tab_trouveactiveauth[$k][0]
                                    AND close=0" );
				if(! $r->execute)
				{
				    writelog("get_assoc_ap",$config{'logopt'},"info",
					"\t\t -> ERREUR DB : impossible des fermer la session d'auth ($tab_trouveactiveauth[$k][0],$tab_trouveactiveauth[$k][1],$tab_trouveactiveauth[$k][2]");
				}

			    }
			}
		    }
		    $j = $t_trouveactiveauth;
		}
	    }
	    elsif($t_trouveactiveassoc > 1)
	    {
		
	    }
	    elsif(($time - 600) > $tab_trouveactiveauth[$j][4])
	    {
		# l'adresse MAC de l'authentifie n'existe pas dans la table des associes
		# on ferme la session
		print RAP "<> test ($time - 600) > $tab_trouveactiveauth[$j][4] ok\n";
		print RAP "===> close $tab_trouveactiveauth[$j][2], set fin = now and close = 1\n";

		my $r = $db->prepare( "
                    UPDATE sessionauthaccess
                    SET close=1
                    WHERE idauthaccess=$tab_trouveactiveauth[$j][0]
		    AND close=0" );
		if(! $r->execute)
                {
                    writelog("get_assoc_ap",$config{'logopt'},"info",
                        "\t\t -> ERREUR DB : impossible des fermer la session d'auth ($tab_trouveactiveauth[$j][0],$tab_trouveactiveauth[$j][1],$tab_trouveactiveauth[$j][2]");
                }


	    }
	    else
	    {
		# l'utilisateur est authentifie depuis trop peu de temps et n'est peut
		# pas encore détecté dans les associations
		print RAP "===> authentification trop recente\n";
	    }
	}
    }
  
    close(RAP);
}


sub set_assoc_db
{
	my ($db,$hostname,$nb_assoc) = @_;
	
	my ($sql,$cursor,$ideq,$idassocwifi,$mac,$essid,$crypt,$sess,$index,$r);
	my %assoc;
	my %activesess;
	my $t_activesess = @total_activesess;

	#
	# Détermine l'ID de l'équipement
	#
	$ideq = $index_ap{"$hostname".".$config{'defaultdomain'}"};

	# si aucune association sur l'AP. On ferme les associations existantes
	if($nb_assoc == 0)
	{
	    my $i;
	    
	    for($i=0;$i<$t_activesess;$i++)
	    {
		if($total_activesess[$i][1] == $ideq)
		{
		    my $temp = $total_activesess[$i][0];
		    $r = $db->prepare( "
			UPDATE sessionassocwifi
			SET fin=now(),close=1
                        WHERE idassocwifi=$temp
                        AND close=0" );
		    #############################################################################
		    if(! $r->execute)
		    {
			writelog("get_assoc_ap",$config{'logopt'},"info",
			"\t\t -> ERREUR DB : impossible des fermer les session actives pour $hostname");
		    }
		    ##############################################################################
		}	
	    }
	}
	# sinon
	else
	{
	    #
	    # recupere toutes les sessions actives pour un ap
	    #
	    for($index=0;$index<$t_activesess;$index++)
	    {
		if($total_activesess[$index][1] == $ideq)
		{
		    # activesess{00:0b:cd:5b:ed:77 osiris} = 21978
		    $activesess{"$total_activesess[$index][2]"." "."$total_activesess[$index][3]"} = $total_activesess[$index][0];
		}
            }
	    #
	    # Determine les associations existantes
	    #
	    # idassocwifi |        mac        |    essid    | crypt
	    #-------------+-------------------+-------------+-------
	    #        1383 | 00:0b:cd:5b:ec:26 | osiris-sec  | t
	    #        1384 | 00:0b:cd:5b:ed:63 | osiris      | f

	    $sql = "SELECT idassocwifi,mac,essid,crypt
        	FROM assocwifi
        	WHERE ideq = $ideq";
	    $cursor = $db->prepare($sql);
	    $cursor->execute;

	    while( ($idassocwifi,$mac,$essid,$crypt) = $cursor->fetchrow ) 
	    {
        	$assoc{"$mac"." "."$essid"} = $idassocwifi ;
        	#print "DEBUG : $mac $essid -> assoc\n";
	    }
	    $cursor->finish;

	    # Mise à jour des sessions actives
	    foreach $sess (keys %collsess) 
	    {	
		(my $h, my $mac_addr, my $ssid) = (split(/\s+/,$sess))[0,1,2];
		my $session = "$mac_addr $ssid";
	
		if($h eq $hostname)
		{
		    if(defined($activesess{$session})) 
		    {
                	$r = $db->prepare("
			    UPDATE sessionassocwifi
			    SET fin=now()
			    WHERE idassocwifi=$activesess{$session}
			    AND close=0");
#####################################################################
                	if(! $r->execute)
                       	{
			    writelog("poller",$config{'logopt'},"info",
				"\t\t -> ERREUR DB : impossible des fermer les session actives pour $hostname");
                       	}
#####################################################################
                	delete $activesess{$session};
		    } 
		    else 
		    { # Nouvelle sessions
                	$crypt = ( $collsess{$sess} ? "t" : "f" ) ;
                	if(defined($assoc{$session}))
			{
                        	#print "DEBUG : $hostname = $sess -> collsess\n";
                	}
                	else
                	{
			    #print "DEBUG  : $hostname = couple créé $sess = ($mac, $ssid)";
			    $r = $db->prepare("	
				INSERT INTO assocwifi		    
				(mac, ideq, essid, crypt)
				VALUES
				('$mac_addr', $ideq, '$ssid', '$crypt')");
#############################################################################
		            if(! $r->execute)
			    {
				writelog("poller",$config{'logopt'},"info",
				"\t\t -> ERREUR DB : impossible d'insérer le nouveau couple : ('$mac_addr', '$ideq', '$ssid', '$crypt')");
			    }	
#############################################################################
                	}
                	#
                	# Détermine l'ID de l'assoc. créée
                	#
                	$sql="SELECT idassocwifi FROM assocwifi
                       		WHERE mac='$mac_addr' AND ideq=$ideq
                       		AND essid='$ssid' AND crypt='$crypt'";
                	$cursor = $db->prepare($sql);
                	$cursor->execute;
                
			if( $idassocwifi = $cursor->fetchrow ) 
			{
			    #print "DEBUG  : idassoc créée $idassocwifi\n";
			    $r = $db->prepare( "
                            	INSERT INTO sessionassocwifi
                               	(idassocwifi, debut, fin, close)
                               	VALUES
                               	($idassocwifi, now(), now(), 0)" ) ;
##############################################################################
		            if(! $r->execute)
			    {
				writelog("poller",$config{'logopt'},"info",
				    "\t\t -> ERREUR DB : impossible d'insérer la nouvelle session $idassocwifi pour $rhostname");
			    }
##############################################################################
			    delete $collsess{$sess};
	               	}
        	       	$cursor->finish;
		    }	
		}
	    }
	    # sessions restante : à fermer
	    foreach $sess (keys %activesess) 
	    {
        	$r = $db->prepare( "
		    UPDATE sessionassocwifi
		    SET fin=now(),close=1
		    WHERE idassocwifi=$activesess{$sess}
		    AND close=0" );
#############################################################################
	 	if(! $r->execute)
                {
		    writelog("poller",$config{'logopt'},"info",
                       	"\t\t -> ERREUR DB : impossible de fermer la session $activesess{$sess} pour $rhostname");
                }
##############################################################################
	    }
	}

}

return 1;
