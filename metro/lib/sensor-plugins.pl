# ###################################################################
# boggia : Creation : 18/02/2010
# boggia : Modification : 14/04/2010
#	modifiaction de la routine de lancement des scripts externe
# 	d'iindicateurs 
#
# fonctions de lancement des operations sur les indicateurs
#
sub get_plugins
{
        my ($nom_indicateur,$host,$snmp_com,$param,$sonde) = @_;

	#open(DEBUG,">>/var/tmp/debug");
	#print DEBUG "get_indicateur => ($nom_indicateur,$host,$snmp_com, $param)\n";

	# definition des fonctions d'indicateurs
	# 'nom de la sonde' => 'fonction d'indicateur correspondante'
	my %function_indic = (
	);

	# definition des programmes d'indicateurs
	# 'nom de la sonde' => 'script d'indicateur correspondant'
	#my %prog_indic = (
        #        'daily_distinct_wifi_users'             => "get_daily_distinct_wifi_users",
        #        'test_indicateurs'                      => "test_indicateurs",
	#	'get_total_pulse_machines'		=> "get_total_pulse_machines",
	#	'get-rt-stats'				=> "get-rt-stats",
	#	'get-sogo-total-users'			=> "get-sogo-total-users",
        #);

	# l'indicateur est executr par une fonction integree a obj999
	# celle-ci doitr etre declaree dans la table %function_indic
	if(defined($function_indic{$nom_indicateur}))
        {
                # formatage des parametres sous formes de liste
                my @l_param = split(/,/,$param);

                # lancement de la fonction d'indicateur avec les parametres
                $function_indic{$nom_indicateur}->(@l_param);
        }
	# l'indicateur est execute par un programme exterieur appele par obj999
	else
        {
		# formatage des parametres pour le lancement du script indicateur
        	if($param =~/,/)
       	 	{
                	$param =~ s/,/ /g;
        	}

		if($host ne "x" && $snmp_com ne "x")
		{
			$param = "$host $snmp_com $param";
		}
		
   		# lancement du script d'indicateur avec les parametres
		`$config{'dir_plugins'}/$nom_indicateur $param`;
	}
	#close(DEBUG);
}


return 1;
