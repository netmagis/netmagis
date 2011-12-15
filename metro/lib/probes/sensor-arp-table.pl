######
# fonctions
# collecte le contenu de la table ARP d'un routeur
# commande debug :
# snmpwalk -v2c -c o2get crc-ce1 1.3.6.1.2.1.4.22.1.2
######
sub get_arp_table
{
    my ($base,$host,$community) = @_;

    my ($snmp, $error) = Net::SNMP->session(
                -hostname       => $host,
                -community      => $community,
                -port           => 161,
                -timeout        => 10,
                -retries        => 2,
                -nonblocking    => 0x1,
                -version        => "2c",
        );

    if (!defined($snmp))
    {
        print "Erreur : $error\n";
    }
    else
    {
            my $Oid = "1.3.6.1.2.1.4.22.1.2";
            my $res = $snmp->get_table(
                    $Oid,
                    -callback   => [ \&get_snmp_arp_table,$base,$host,$community] );
        }
}

######
sub get_snmp_arp_table
{
    	my ($session,$base,$host,$community) = @_;

    	my %table_arp;
    	my $compteur = 0;

    	if(defined($session->var_bind_list()))
    	{
        	# Extract the response.
        	my $key = '';
        	my $hashref = $session->var_bind_list();

        	foreach $key (keys %$hashref)
        	{
            		$compteur ++;
            		chomp($key);

            		my $mac = set_Id2Mac($$hashref{$key});

       	    		if($key =~ /([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/ && $mac ne "0")
			{
	    			$table_arp{"$1.$2.$3.$4"} = $mac;
			}
    		}
     	}

     	# update rrd file
     	RRDs::update ($base,"$time{TIME_T}:$compteur");
     
     	my $ERR=RRDs::error;
     	if ($ERR)
     	{
     		writelog("ipmac",$config{syslog_facility},"info",
           	"\t -> ERROR while updating $base: $ERR");

		if($ERR =~/$base': No such file or directory/)
        	{
			# No rrd file, create it
		}
     	}

     	# print report file
    	print_ipmac_report($host,%table_arp);
}

#####################################################
# function print_ipmac_report
# print report for ipmac probe for the equipement specified as argument
sub print_ipmac_report
{
	my ($host,%table_arp) = @_;

	if(open(REPORT,">$config{dir_report}/ipmac_$host"))
	{
		foreach my $key (keys %table_arp)
		{
			print REPORT "$time{TIME_T};$key;$table_arp{$key}\n"
		}
        	close(REPORT);
	}
	else
	{
        	writelog("poller_$group$num_process",$config{'syslog_facility'},"info",
                	"\t -> ERROR : fichier de cache : $!");
	}	
}


######################################################
# fonction qui permet de recuperer la liste des
# des sessions ip/mac dans la base mac
sub update_ipmac
{
    #ouverture de la base PSQL
    #my $db =  DBI->connect("dbi:Pg:dbname=$config{'PGDATABASE'};host=$config{'PGHOST'}",
	#						$config{'PGUSER'},$config{'PGPASSWORD'});
    my $db =  DBI->connect("dbi:Pg:dbname='mac-test';host='bddmac-test'",
							'mac-test','DftBnj36');

    if($db)
    {
    	writelog("get_arp_table",$config{'logopt'},"info",
                "\t -> INFO DB : Connexion a $config{'PGDATABASE'}");


        # Determine les dernieres sessions actives ip/mac
		# idipmac |       ip       |        mac        |    debut         |    fin           |  close
		#---------+----------------+-------------------+------------------+------------------+---------
 		# 2271067 | 130.79.140.111 | 00:0c:76:54:86:ae | 1296644539.18042 | 1296644539.18042 |  0

        my $sql = "SELECT ipmac.idipmac,
				ipmac.ip,
				ipmac.mac,
				EXTRACT(EPOCH FROM sessionipmac.debut),
				EXTRACT(EPOCH FROM sessionipmac.fin),
				sessionipmac.close
				FROM ipmac,sessionipmac
				WHERE sessionipmac.close = 0
				AND ipmac.idipmac=sessionipmac.idipmac";

        my $cursor = $db->prepare($sql);
        $cursor->execute;

		my $time_t_now = time;
		my $date = time2sql($time_t_now);

        my $index = 0;
		my $r;

        while( my ($idipmac,$ip,$mac,$debut,$fin) = $cursor->fetchrow )
        {
			# liste toutes les sessions en cours
			if(clean_ipmacsess($fin,$time_t_now) == 1)
            {
                $ipmac{$idipmac}{ip} = $ip;
				$ipmac{$idipmac}{mac} = $mac;
				$ipmac{$idipmac}{debut} = $debut;
                $index ++;

            	# si le couple ip/mac enregistre dans la base est collecte sur les equipements
            	if($table_arp{$ip} eq $mac)
            	{
                	# on met a jour la session
                	# UPDATE ...
                	$r = $db->prepare( "
                    	UPDATE sessionipmac
                    	SET fin=TIMESTAMP '$date'
                    	WHERE idipmac=$idipmac
                    	AND close=0");

                    if(! $r->execute)
                    {
                        writelog("get_arp_table",$config{'logopt'},"info",
                               "\t\t -> ERREUR DB : impossible de mettre a jour la session ip/mac ($ip,$mac,$debut,$date)");
                    }
					$r->finish ;

					# on efface l'association ip/mac collectee apres avoir mis a jour la bdd
            		delete $table_arp{$ip}
            	}
            	else
            	{
                	# si aucune association ip/mac presente dans la base n'est collectee sur les equipements
					# et que la derniere date de fin mis a jour est anterieure a 10Min
                	# ou si l'adresse ip est associees a une autre adresse mac
                	# on ferme la session
                	$r = $db->prepare( "
                    	UPDATE sessionipmac SET close=1, fin=TIMESTAMP '$date'
                    	WHERE idipmac=$idipmac
                    	AND close = 0");

					if(! $r->execute)
                    {
                        writelog("get_arp_table",$config{'logopt'},"info",
                               "\t\t -> ERREUR DB : impossible de fermer la session ip/mac ($ip,$mac)");
                    }
					$r->finish ;
            	}
			}
            else
            {
                $r = $db->prepare( "
                    UPDATE sessionipmac
                    SET close=1
                    WHERE idipmac=$idipmac
                    AND close=0" );

                if(! $r->execute)
                {
                    writelog("get_arp_table",$config{'logopt'},"info",
                	          "\t\t -> ERREUR DB : impossible des fermer la session ip/mac ($ip,$mac,$debut,$fin)");
                }
				$r->finish ;
            }
        }

		# on parcours ce qu'il reste de la collecte ip/mac
		foreach my $ip (keys %table_arp)
		{
			my $idipmac;
			# on recupere l'id de l'association
			$r = $db->prepare("
				SELECT idipmac
				FROM ipmac
            	WHERE mac='$table_arp{$ip}'
                AND ip='$ip'");

			if(! $r->execute)
			{
				writelog("get_arp_table",$config{'logopt'},"info",
                              "\t\t -> ERREUR DB : impossible de recupere l'id de l'association ($ip,$mac)");
			}
			else
			{
				$idipmac = $r->fetchrow;
			}
			$r->finish ;

			# si le couple ip/mac existe dans ipmac
            if($idipmac =~/[0-9]/)
            {
				# on insert la nouvelle session
                $r = $db->prepare( "
                INSERT INTO sessionipmac
                (idipmac, debut, fin, close)
                VALUES
                ('$idipmac', '$date', '$date', 0)" ) ;

				if(! $r->execute)
                {
                	writelog("poller",$config{'logopt'},"info",
                    	"\t\t -> ERREUR DB : impossible d'insérer la nouvelle session $idipmac, debut = $date");
                }
				$r->finish ;
			}
			# si le couple ip/mac n'existe pas dans ipmac
			else
			{
				# on insert le nouveau couple ip/mac
				$r = $db->prepare( "
                INSERT INTO ipmac
                (ip, mac)
                VALUES
                ('$ip', '$table_arp{$ip}')" ) ;

                if(! $r->execute)
                {
                    writelog("poller",$config{'logopt'},"info",
                        "\t\t -> ERREUR DB : impossible d'insérer le nouveau couple ($ip/$table_arp{$ip})");
                }
				else
				{
					# on recupere l'id de l'association
            		$r = $db->prepare("
                		SELECT idipmac
                		FROM ipmac
                		WHERE mac='$table_arp{$ip}'
                		AND ip='$ip'");

            		if(! $r->execute)
            		{
                		writelog("get_arp_table",$config{'logopt'},"info",
                              "\t\t -> ERREUR DB : impossible de recupere l'id de l'association ($ip,$table_arp{$ip})");
            		}
					else
            		{
                		$idipmac = $r->fetchrow;

						if($idipmac =~/[0-9]/)
            			{
                			# on insert la nouvelle session
                			$r = $db->prepare( "
                			INSERT INTO sessionipmac
                			(idipmac, debut, fin, close)
                			VALUES
                			('$idipmac', '$date', '$date', 0)" ) ;

                			if(! $r->execute)
                			{
                    			writelog("poller",$config{'logopt'},"info",
                        			"\t\t -> ERREUR DB : impossible d'insérer la nouvelle session $idipmac, debut = $date");
                			}
                			$r->finish ;
            			}
            		}
            		$r->finish ;
				}

				$r->finish ;
			}
		}

        $cursor->finish;

    	if($index == 0)
        {
            writelog("get_arp_table",$config{'logopt'},"info",
                "\t -> ERREUR DB : Echec chargement de la liste des sessions ip/mac actives de $config{'PGDATABASE'}");
        }
        else
        {
            writelog("get_arp_table",$config{'logopt'},"info",
                "\t -> INFO DB : nombres de sessions ip/mac dans $config{'PGDATABASE'} : $index");
        }

    }
    else
    {
    writelog("get_arp_table",$config{'logopt'},"info",
                "\t -> ERROR : Connexion impossible a la base $config{'PGDATABASE'}");
    }
}


# nettoie les sessions oubliées encore actives
#
sub clean_ipmacsess
{
    my ($datefin,$time_t_now) = @_;

    # si la date en parametre + 1 jour est inferieure a la date
    if((dateSQL2time($datefin) + 86400) < $time_t_now)
    {
    	return 0;
    }
    else
    {
        return 1;
    }
}

return 1;
