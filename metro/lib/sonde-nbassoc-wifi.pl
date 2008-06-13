# $Id: sonde-nbassoc-wifi.pl,v 1.1.1.1 2008-06-13 08:55:51 pda Exp $
# ###################################################################
# boggia : Creation : 25/03/08
# boggia : Modification : Creation de la fonction get_authaccess_list
#			  dans le but de creer le tableau de bord 
#			  WiFi pour les corrspondants reseau
#
# fonctions de traitement des associations sur les AP WiFi
#   - generation de rapports d'assoc
#   - remplissage de bases rrdtools pour grapher les associations
#   - fermeture dans les bases PGSQL des sessions d'authentification 
#     en particulier pour le mode 802.1X lorsqu'une machine est 
#     definitivement deconnectée du reseau
#
sub get_nb_assocwifi
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
	    my $assoc_oid = '1.3.6.1.4.1.9.9.273.1.2.1.1.6';
	    my $res = $snmp->get_table(
		$assoc_oid,
                -callback   => [ \&get_snmp_assoc_ap,$snmp,$base,$host,$assoc_oid] );
	}
}

sub get_nb_assocwifi
{
	my ($this,$session,$base,$host,$assoc_oid) = @_;

	my $nb_wpa = 0;
        my $nb_clair = 0;
	my @tab = ();
	my @ssid = ();
	my ($t_tab,$t_ssid);
	
	# on souhaite utiliser le nom de l'ap pour les logs.
	my $iaddr = inet_aton($host);
        my $hostname  = gethostbyaddr($iaddr, AF_INET);
        ($hostname)=(split(/\./,$hostname))[0];

	if(!$hostname)
	{
	    writelog("get_assoc_ap",$config{'logopt'},"info",
                        "\t -> ERROR: echec de resolution de $host = $hostname dans $base");
	}

	my $file_temp = "/tmp/$hostname.rap";
	
	if(defined($this->var_bind_list())) 
	{
	    	# Extract the response.
	    	my $key = '';
	    	my $hashref = $this->var_bind_list();
		
		my @liste = ();
		my $i=0;
		my ($j,$securise,$mac,$ssid,$t_liste,$char,$temp);

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


			# MAC et SSID
        		@liste = ();
        		$mac = "";
        		$ssid = "";

			($key) = (split(/$assoc_oid\./,$key))[1];
        		
			@liste = split(/\./,$key);
        		$t_liste = @liste;

        		for($j=0;$j<$t_liste;$j++)
        		{
                		if($j < ($t_liste - 6))
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
        		
			$collsess{"$hostname"." "."$mac"." "."$ssid"} =  $tab[$i][2] ;

			$i++
                }
		$liste_ap{"$hostname"} = $i;
		
		# pour l'état de l'AP
		$liste_ap_state{"$hostname"} = $i;
	}
	else
	{
		#print "\nPas d'associés : ";
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
		#$this->error_status();
	}

	RRDs::update ("$base","N:$nb_wpa:$nb_clair");
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



return 1;
