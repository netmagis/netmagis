# ###################################################################
# boggia : Creation : 18/02/2010
# boggia : Modification : 
#
# fonctions de lancement des operations sur les indicateurs
#

sub get_indicateur
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
	my %prog_indic = (
                'daily_distinct_wifi_users'             => get_daily_distinct_wifi_users,
                'test_indicateurs'                      => test_indicateurs
        );

	if(defined($prog_indic{$nom_indicateur}))
        {
		# formatage des parametres pour le lancement du script indicateur
        	if($param =~/,/)
       	 	{
                	$param =~ s/,/ /g;
        	}

		#print DEBUG "=> $global_var{DIR_PROBES_INDICATEURS}/$function_indic{$nom_indicateur}($param)\n";
		
   		# lancement du script d'indicateur avec les parametres
		`$global_var{DIR_PROBES_INDICATEURS}/$function_indic{$nom_indicateur} $param`;
	}
	elsif(defined($function_indic{$nom_indicateur}))
	{
		# formatage des parametres sous formes de liste
		my @l_param = split(/,/,$param);
		
		# lancement de la fonction d'indicateur avec les parametres
		$function_indic{$nom_indicateur}->(@l_param);	
	}
	#close(DEBUG);
}


return 1;
