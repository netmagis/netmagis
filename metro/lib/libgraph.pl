#!/usr/bin/perl
# $Id: libgraph.pl,v 1.4 2008/07/30 15:49:32 boggia Exp $
###########################################################
# Creation : 21/05/08 : boggia
#
# Fichier contenant les fonctions de creation de graphiques
# RRDtools
###########################################################

sub genere_graph
{
    my ($type,$nb_rrd_bases,$ref_l,$output,$start,$end,$size,$commentaire) = @_;

    # liste des fonction de création de graphiques
    my %function_graph = (
        'trafic'		=> \&trafic,
	'trafic-moyen'          => \&trafic,
	'aggreg_trafic'		=> \&aggreg_trafic,
	'aggregation-trafic2-moyen' => \&aggreg_trafic,
	'aggregation-trafic2'	=> \&aggreg_trafic,
	'GaugeNbAuthWifi-site'	=> \&GaugeAuthWiFi,
	'GaugeNbConAp'		=> \&GaugeAssocWiFi,
	'GaugeNbAuthWifi'	=> \&GaugeAuthWiFi,
	'GaugeDHCPuse'		=> \&GaugeDHCPleases,
	'GaugeCPUCisco'		=> \&GaugeCPUCisco,
	'GaugeCPUJuniper'	=> \&GaugeCPUJuniper,
	'GaugeCPU'		=> \&GaugeCPUServer,
	'GaugeLoadAverage'	=> \&GaugeLoadAverage,
	'GaugeTempsReponse'	=> \&GaugeRespTime,
	'tpsDisk'		=> \&GaugeTPSDisk,
	'bind'			=> \&GaugeBind,
	'GaugeGeneric'		=> \&GaugeGeneric,
	'GaugeMailq'		=> \&GaugeMailq,
	'GaugeMemByProc'	=> \&GaugeMemByProc,
	'nbauthwifi'		=> \&nbauthwifi,
	'nbassocwifi'		=> \&nbassocwifi,
	'counter_generic'	=> \&counter_generic,
    );
    
    
    my %graph_size = (
	'petit'		=> "330x150",
	'moyen'		=> "550x250",
	'grand'		=> "750x250"
    );

    if(exists $graph_size{$size})
    {
	# si taille = petit, moyen ou grand : conversion en "longueur"x"hauteur"
	$size = $graph_size{$size};
    } 
    
    if($size !~ m/[0-9]+x[0-9]+/)
    {
	# le paramètre taille est malformé
	#print "Erreur : Paramètre $size incorrect";	
    }
    else
    {
	# appel de la fonction de creation du graphique
	$function_graph{$type}->($nb_rrd_bases,$ref_l,$output,$start,$end,$size,$commentaire);
    }
}



###########################################################
# Graph des authentifications WiFi
sub nbauthwifi
{
	my ($nb_rrd_bases,$ref_l,$output,$start,$end,$size,$commentaire) = @_;

	my $label = "authentifiés";
	if($commentaire eq "")
	{
		$commentaire = "Authentifiés WiFi";
		
	}
	
	GaugeWiFi($nb_rrd_bases,$ref_l,$output,$start,$end,$size,$commentaire,$label);
}



###########################################################
# Graph des associations WiFi
sub nbassocwifi
{
	my ($nb_rrd_bases,$ref_l,$output,$start,$end,$size,$commentaire) = @_;

	my $label = "associés";	
	if($commentaire eq "")
        {
                $commentaire = "Associés WiFi";
        }

	GaugeWiFi($nb_rrd_bases,$ref_l,$output,$start,$end,$size,$commentaire,$label);
}


###########################################################
# Fonction générique qui graphe les utilisateurs WiFi  
sub GaugeWiFi
{
	my ($nb_rrd_bases,$ref_l,$output,$start,$end,$size,$commentaire,$vertical_label) = @_;

	# dereferencement
    	my @l = @$ref_l;

    	if(@l == 1)
	{
		my ($width,$height) = split(/x/,$size);

        	my %color_lines = ( 	'avg'  => "3d8d8d",
                            		'max'  => "b8ff4d",
        	);

        	my $rrd = RRDTool::OO->new(
            		file => "$ref_l->[0]->[0]->{'base'}" );

        	my @liste_arg;
        	my $plusline="";
        	my $drawlineavg,$drawlinemax;

        	my $ttl = @{$l[0]};

		for(my $j=0;$j<$ttl;$j++)
        	{
			# dsname des bases a definir

            		my ($drawavg,$drawmax);
            		$drawavg->{'file'} = $l[0][$j]{'base'};
            		$drawavg->{'type'} = "hidden";
            		#$drawavg->{'dsname'} = "$ssid";
            		$drawavg->{'name'} = "avg$j";
            		$drawavg->{'cfunc'} = "AVERAGE";
           	 	$drawmax->{'file'} = $l[0][$j]{'base'};
            		$drawmax->{'type'} = "hidden";
            		#$drawmax->{'dsname'} = "$ssid";
           	 	$drawmax->{'name'} = "max$j";
            		$drawmax->{'cfunc'} = "MAX";
					
            		# calcul du cumul pour les donnes bases explicitement aggregees
            		# ex : Mescape-ap3.osiris.authwifi+Mescape-ap1.osiris.authwifi
            		# (afficher sous forme de ligne)
			if(exists $drawlineavg->{'cdef'})
            		{
                		$drawlineavg->{'cdef'}="$drawlineavg->{'cdef'},$drawavg->{'name'}";
                		$drawlinemax->{'cdef'}="$drawlinemax->{'cdef'},$drawmax->{'name'}";
                		$plusline = "$plusline,ADDNAN";
            		}
            		else
            		{
                		$drawlineavg->{'cdef'}=$drawavg->{'name'};
                		$drawlinemax->{'cdef'}=$drawmax->{'name'};
            		}
    
            		push @liste_arg,"draw";
            		push @liste_arg,$drawavg;
            		push @liste_arg,"draw";
            		push @liste_arg,$drawmax;
		}
		
		# pour additionner le resultat des valeurs
		$drawlineavg->{'cdef'}="$drawlineavg->{'cdef'}$plusline";
		$drawlinemax->{'cdef'}="$drawlinemax->{'cdef'}$plusline";

		# comparaison des legendes pour la mise en page
        	my @legend;
		my $t_legend;
		my $maxlengthlengend = 0;

        	if($l[0][0]{'legend'} ne "")
        	{
            		@legend = split(//,$l[0][0]{'legend'});
            		$maxlengthlengend = @legend;
			$t_legend = $maxlengthlengend;
        	}
        	$maxlengthlengend = $maxlengthlengend + 6;
	
		# ecriture de la legende en entree
        	my $spaces = get_spaces(0,$maxlengthlengend,11);
        	push @liste_arg,"comment";
        	push @liste_arg,"$spaces      min      max     moyen   actuel\\n";
        	my $gprintavg,$gprintmax;
        	$spaces = get_spaces($t_legend,$maxlengthlengend,8);
        	# ecriture de la courbe en input
        	$drawlineavg->{'type'} = "area";
        	$drawlineavg->{'color'} = $color_lines{'avg'};
        	$drawlineavg->{'name'} = "clients_avg";
		if($l[0][0]{'legend'} ne "")
		{
        		$drawlineavg->{'legend'} = "$l[0][0]{'legend'}";
		}
		else
		{
			$drawlineavg->{'legend'} = "clients";
		}
        	push @liste_arg,"draw";
        	push @liste_arg,$drawlineavg;
		# legende trafic in
        	push @liste_arg,"comment";
        	push @liste_arg,$spaces;
        	$gprintavg->{0}->{'draw'}="clients_avg";
        	$gprintavg->{0}->{'format'}="MIN:%5.0lf %S";
        	push @liste_arg,"gprint";
        	push @liste_arg,$gprintavg->{0};
        	$gprintavg->{1}->{'draw'}="clients_avg";
        	$gprintavg->{1}->{'format'}="MAX:%5.0lf %S";
        	push @liste_arg,"gprint";
        	push @liste_arg,$gprintavg->{1};
		$gprintavg->{2}->{'draw'}="clients_avg";
                $gprintavg->{2}->{'format'}="AVERAGE:%5.0lf %S";
                push @liste_arg,"gprint";
                push @liste_arg,$gprintavg->{2};
		$gprintavg->{3}->{'draw'}="clients_avg";
                $gprintavg->{3}->{'format'}="LAST:%5.0lf %S\\n";
                push @liste_arg,"gprint";
                push @liste_arg,$gprintavg->{3};

		# ecriture de la valeur MAX selon l'intervalle de temps
        	if(($end - $start) > 800000)
        	{
	                $spaces = get_spaces($t_legend,$maxlengthlengend,0);
	                # ecriture de la courbe en input
	                $drawlinemax->{'type'} = "line";
	                $drawlinemax->{'color'} = $color_lines{'max'};
	                $drawlinemax->{'name'} = "clients_max";
	                if($l[0][0]{'legend'} ne "")
	                {
	                        $drawlinemax->{'legend'} = "$l[0][0]{'legend'} (crête)";
	                }
	                else
	                {
	                        $drawlinemax->{'legend'} = "clients (crête)";
	                }
	                push @liste_arg,"draw";
	                push @liste_arg,$drawlinemax;
	                # legende trafic in
	                push @liste_arg,"comment";
	                push @liste_arg,$spaces;
	                $gprintmax->{0}->{'draw'}="clients_max";
	                $gprintmax->{0}->{'format'}="MIN:%5.0lf %S";
	                push @liste_arg,"gprint";
	                push @liste_arg,$gprintmax->{0};
	                $gprintmax->{1}->{'draw'}="clients_max";
	                $gprintmax->{1}->{'format'}="MAX:%5.0lf %S";
	                push @liste_arg,"gprint";
	                push @liste_arg,$gprintmax->{1};
	                $gprintmax->{2}->{'draw'}="clients_max";
	                $gprintmax->{2}->{'format'}="AVERAGE:%5.0lf %S";
	                push @liste_arg,"gprint";
	                push @liste_arg,$gprintmax->{2};
	                $gprintmax->{3}->{'draw'}="clients_max";
	                $gprintmax->{3}->{'format'}="LAST:%5.0lf %S";
	                push @liste_arg,"gprint";
	                push @liste_arg,$gprintmax->{3};
		}

		$rrd->graph(
			image           => "-",
        		title           => "$commentaire",
        		vertical_label  => "$vertical_label",
       	 		lower_limit     => 0,
        		units_exponent  => 0,
       			height          => $height,
        		width           => $width,
        		start           => $start,
        		end             => $end,
            		@liste_arg,
        	);

	}
    	elsif(@l > 1)
    	{
        	aggregGaugeWiFi($nb_rrd_bases,$ref_l,$output,$start,$end,$size,$commentaire,$vertical_label);
    	}
    	else
    	{
        	print "nombre de bases rrd incorrect : $nb_rrd_bases";
    	}
}



###########################################################
# Fonction générique qui graphe les utilisateurs WiFi
sub aggregGaugeWiFi
{
	my ($nb_rrd_bases,$ref_l,$output,$start,$end,$size,$commentaire,$vertical_label) = @_;

    	my ($width,$height) = split(/x/,$size);

    	my $couleur_cumul = "c9c9c9";
    	my @couleurs_flux = qw(ff0000 0055ff 00ff00 ffff00 000000 ff00ff 00c6ff 009800 ffa400 7f0000 ff6b01 7f007f a29951 ffa7cc 00007f 007f7f 007f00 a29900 827f00 4c4c4c 666666 665166 fbcbfb ffff8b ffc68b a2ffff ff5e5e fffdfc dec7c6 deebc6 deebee a299ea);

    	my $rrd = RRDTool::OO->new(file => "$ref_l->[0]->[0]->{'base'}");

    	my @liste_arg1;
    	my @liste_total;

    	# creation des parametres pour le cumul total
    	my $drawtotal;
    	$drawtotal->{'type'} = "area";
    	$drawtotal->{'color'} = $couleur_cumul;
    	$drawtotal->{'name'} = "total";
    	$drawtotal->{'legend'} = "cumul";
   
    	my $drawline;
    	# dereferencement
    	my @l = @$ref_l;
   
    	# creation d'objets draw de type hidden pour chaque courbe
    	my $tl = @l;
    	my $plus;
   	for(my $i=0;$i<$tl;$i++)
    	{
		my $ttl = @{$l[$i]};
		my $plusline="";
		for(my $j=0;$j<$ttl;$j++)
		{  
	    		my $draw;
	    		$draw->{'file'} = $l[$i][$j]{'base'};
	    		$draw->{'type'} = "hidden";
	    		#$drawin->{'dsname'} = "input";
	    		$draw->{'name'} = "$l[$i][$j]{'graph'}__clients";
	    		$draw->{'cfunc'} = "AVERAGE";
	    		$draw->{'name'} =~ s/\./__/g;
	    		# calcul du cumul total (afficher sour forme d'une aire)
	    		if(exists $drawtotal->{'cdef'})
	    		{
				$drawtotal->{'cdef'}="$drawtotal->{'cdef'},$draw->{'name'}";
				$plus = "$plus,ADDNAN";
	    		}
	    		else
	    		{
				$drawtotal->{'cdef'}=$draw->{'name'};
	    		}
	    		# calcul du cumul seulement pour les donnes bases explicitement aggregees
	    		# ex : Mescarpe-ap3.authwifi.osiris+Mescarpe-ap3.authwifi.osiris-sec
	    		# (afficher sous forme de ligne)
	    		if(exists $drawline->{$i}->{'cdef'})
	    		{		   
				$drawline->{$i}->{'cdef'}="$drawline->{$i}->{'cdef'},$draw->{'name'}";
				$plusline = "$plusline,ADDNAN"; 
	    		}
	    		else
	    		{
				$drawline->{$i}->{'cdef'}=$draw->{'name'};
	    		}

	    		push @liste_arg1,"draw";
	    		push @liste_arg1,$draw;
		}
		# pour additionner les valeurs aggregees
		$drawline->{$i}->{'cdef'}="$drawline->{$i}->{'cdef'}$plusline";
    	} 
    
    	# pour additionner les valeurs aggregees pour le cumul 
    	$drawtotal->{'cdef'}="$drawtotal->{'cdef'}$plus";
    
    	# ecriture du graphique de cumul en entree
    	push @liste_total,"draw";
    	push @liste_total,$drawtotal;

    	# comparaison des legendes pour la mise en page
    	my %llegend;
    	$llegend{'total'} = split(//,$drawtotal->{'legend'});
    	my $maxlengthlengend = $llegend{'total'};

    	for($i=0;$i<$tl;$i++)
    	{
        	if($l[$i][0]{'legend'} eq "")
        	{
            		$l[$i][0]{'legend'} = $l[$i][0]{'graph'};
        	}
        	$llegend{$i} = split(//,$l[$i][0]{'legend'});
        	if($maxlengthlengend < $llegend{$i})
        	{
            		$maxlengthlengend = $llegend{$i};
        	}
    	}
    	$maxlengthlengend = $maxlengthlengend + 4;

    	# ecriture de la legende en entree
    	my $spaces = get_spaces(0,$maxlengthlengend,8);
    	push @liste_arg1,"comment";
    	push @liste_arg1,"$spaces min      max     moyen   actuel\\n";
    	my $gprinttotal;
    	$spaces = get_spaces($llegend{'total'},$maxlengthlengend,0);
    	push @liste_total,"comment";
    	push @liste_total,$spaces;
	$gprinttotal->{0}->{'draw'}="total";
        $gprinttotal->{0}->{'format'}="MIN:%5.0lf %S";
        push @liste_total,"gprint";
        push @liste_total,$gprinttotal->{0};
    	$gprinttotal->{1}->{'draw'}="total";
    	$gprinttotal->{1}->{'format'}="MAX:%5.0lf %S";
    	push @liste_total,"gprint";
    	push @liste_total,$gprinttotal->{1};
    	$gprinttotal->{2}->{'draw'}="total";
    	$gprinttotal->{2}->{'format'}="AVERAGE:%5.0lf %S";
    	push @liste_total,"gprint";
    	push @liste_total,$gprinttotal->{2};
    	$gprinttotal->{3}->{'draw'}="total";
    	$gprinttotal->{3}->{'format'}="LAST:%5.0lf %S\\n";
    	push @liste_total,"gprint";
    	push @liste_total,$gprinttotal->{3};
    	
	my $gprint;
    	# on cree les objets draw pour afficher les lignes
    	for($i=0;$i<$tl;$i++)
    	{
		# ecriture de la courbe en input
		$drawline->{$i}->{'type'} = "line";
    		$drawline->{$i}->{'color'} = $couleurs_flux[$i];
		$drawline->{$i}->{'name'} = "ssid$i";
		# insertion de la legende
		$drawline->{$i}->{'legend'} = "$l[$i][0]{'legend'}";
		push @liste_total,"draw";
		push @liste_total,$drawline->{$i};
		$gprint->{$i}->{0}->{'draw'}=$drawline->{$i}->{'name'};
		$gprint->{$i}->{0}->{'format'}="MIN:%5.0lf %S";
		$spaces = get_spaces($llegend{$i},$maxlengthlengend,0);
		push @liste_total,"comment";
		push @liste_total,$spaces;
		push @liste_total,"gprint";
		push @liste_total,$gprint->{$i}->{0};
		$gprint->{$i}->{1}->{'draw'}=$drawline->{$i}->{'name'};
        	$gprint->{$i}->{1}->{'format'}="MAX:%5.0lf %S";
        	push @liste_total,"gprint";
        	push @liste_total,$gprint->{$i}->{1};
		$gprint->{$i}->{2}->{'draw'}=$drawline->{$i}->{'name'};
        	$gprint->{$i}->{2}->{'format'}="AVERAGE:%5.0lf %S";
        	push @liste_total,"gprint";
        	push @liste_total,$gprint->{$i}->{2};
		$gprint->{$i}->{3}->{'draw'}=$drawline->{$i}->{'name'};
                $gprint->{$i}->{3}->{'format'}="LAST:%5.0lf %S\\n";
                push @liste_total,"gprint";
                push @liste_total,$gprint->{$i}->{3};
    	}
	
	$rrd->graph(
        	image           => "-",
        	title           => "$commentaire",
        	vertical_label  => "$vertical_label",
        	lower_limit     => 0,
        	units_exponent  => 0,
       	 	height          => $height,
        	width           => $width,
        	start           => $start,
        	end             => $end,
        	@liste_arg1,
		@liste_total,
        );

}



###########################################################
# Graph de trafic
sub trafic
{
    my ($nb_rrd_bases,$ref_l,$output,$start,$end,$size,$commentaire) = @_;

    # dereferencement
    my @l = @$ref_l;
    
    if(@l == 1)
    {
	my ($width,$height) = split(/x/,$size);
	
	my %color_lines = ( 'input'  => "00dd00",
			    'output'  => "0000ff",
			    'maxinput'  => "b8ff4d",
                            'maxoutput'  => "ffa1e9",
	);

	$vertical_label = "Trafic Réseau";

	my $rrd = RRDTool::OO->new(
            file => "$ref_l->[0]->[0]->{'base'}",
	    #raise_error => 0,
	);

	my @liste_arg;
        my $plusline="";
	my $drawlinein,$drawlineout;

	my $ttl = @{$l[0]};

        for(my $j=0;$j<$ttl;$j++)
        {
            my ($drawin,$drawout,$drawinmax,$drawoutmax);
            $drawin->{'file'} = $l[0][$j]{'base'};
            $drawin->{'type'} = "hidden";
            $drawin->{'dsname'} = "input";
            $drawin->{'name'} = "$l[0][$j]{'graph'}__inputbytes";
            $drawin->{'cfunc'} = "AVERAGE";
            $drawout->{'file'} = $l[0][$j]{'base'};
            $drawout->{'type'} = "hidden";
            $drawout->{'dsname'} = "output";
            $drawout->{'name'} = "$l[0][$j]{'graph'}__outputbytes";
            $drawout->{'cfunc'} = "AVERAGE";
            $drawin->{'name'} =~ s/\./__/g;
            $drawout->{'name'} =~ s/\./__/g;
	    $drawinmax->{'file'} = $l[0][$j]{'base'};
            $drawinmax->{'type'} = "hidden";
            $drawinmax->{'dsname'} = "input";
            $drawinmax->{'name'} = "$l[0][$j]{'graph'}__maxinputbytes";
            $drawinmax->{'cfunc'} = "MAX";
            $drawoutmax->{'file'} = $l[0][$j]{'base'};
            $drawoutmax->{'type'} = "hidden";
            $drawoutmax->{'dsname'} = "output";
            $drawoutmax->{'name'} = "$l[0][$j]{'graph'}__maxoutputbytes";
            $drawoutmax->{'cfunc'} = "MAX";
            $drawinmax->{'name'} =~ s/\./__/g;
            $drawoutmax->{'name'} =~ s/\./__/g;
	    
            # calcul du cumul pour les donnes bases explicitement aggregees
            # ex : Mcrc-rc1.wifi-sec+Mle7-rc1.wifi-sec
            # (afficher sous forme de ligne)
            if(exists $drawlinein->{'cdef'})
            {
                $drawlinein->{'cdef'}="$drawlinein->{'cdef'},$drawin->{'name'}";
                $drawlineout->{'cdef'}="$drawlineout->{'cdef'},$drawout->{'name'}";
		$drawlineinmax->{'cdef'}="$drawlineinmax->{'cdef'},$drawinmax->{'name'}";
                $drawlineoutmax->{'cdef'}="$drawlineoutmax->{'cdef'},$drawoutmax->{'name'}";
                $plusline = "$plusline,ADDNAN";
            }
            else
            {
                $drawlinein->{'cdef'}=$drawin->{'name'};
                $drawlineout->{'cdef'}=$drawout->{'name'};
		$drawlineinmax->{'cdef'}=$drawinmax->{'name'};
                $drawlineoutmax->{'cdef'}=$drawoutmax->{'name'};
            }

            push @liste_arg,"draw";
            push @liste_arg,$drawin;
            push @liste_arg,"draw";
            push @liste_arg,$drawout;
	    push @liste_arg,"draw";
            push @liste_arg,$drawinmax;
	    push @liste_arg,"draw";
            push @liste_arg,$drawoutmax;
        }
        # pour convertir les valeurs de trafic des lignes en bits
        $drawlinein->{'cdef'}="$drawlinein->{'cdef'}$plusline,8,*";
        $drawlineout->{'cdef'}="$drawlineout->{'cdef'}$plusline,8,*";
	$drawlineinmax->{'cdef'}="$drawlineinmax->{'cdef'}$plusline,8,*";
        $drawlineoutmax->{'cdef'}="$drawlineoutmax->{'cdef'}$plusline,8,*";

	# comparaison des legendes pour la mise en page
	my %llegend;
	if($l[0][0]{'legend'} ne "")
        {
	    $llegend{'in'} = split(//,$l[0][0]{'legend'});
	    my $maxlengthlengend = $llegend{'in'};
	    $llegend{'out'} = split(//,$l[0][0]{'legend'});
	}
	else
	{
	    $llegend{'in'} = 0;
	    $llegend{'out'} = 0;
	}
	$maxlengthlengend = $maxlengthlengend + 6;

	# ecriture de la legende en entree
	my $spaces = get_spaces(0,$maxlengthlengend,17);
	push @liste_arg,"comment";
	push @liste_arg,"$spaces maximum          moyen        actuel\\n";
	my $gprintin,$gprintout,$gprintinmax,$gprintoutmax;
	$spaces = get_spaces($llegend{'in'},$maxlengthlengend,0);
	# ecriture de la courbe en input
	$drawlinein->{'type'} = "area";
	$drawlinein->{'color'} = $color_lines{'input'};
	$drawlinein->{'name'} = "inputbits";
	$drawlinein->{'legend'} = "$l[0][0]{'legend'} entrant";
	push @liste_arg,"draw";
	push @liste_arg,$drawlinein;
	# legende trafic in
	push @liste_arg,"comment";
	push @liste_arg,$spaces;
	$gprintin->{0}->{'draw'}="inputbits";
	$gprintin->{0}->{'format'}="MAX:%7.2lf %Sb/s";
	push @liste_arg,"gprint";
	push @liste_arg,$gprintin->{0};
	$gprintin->{1}->{'draw'}="inputbits";
	$gprintin->{1}->{'format'}="AVERAGE:%7.2lf %Sb/s";
	push @liste_arg,"gprint";
	push @liste_arg,$gprintin->{1};
	$gprintin->{2}->{'draw'}="inputbits";
	$gprintin->{2}->{'format'}="LAST:%7.2lf %Sb/s\\n";
	push @liste_arg,"gprint";
	push @liste_arg,$gprintin->{2};
	
	# ecriture des valeurs MAX selon l'intervalle de temps
	if(($end - $start) > 800000)
        {
	    # ecriture de la legende en entree
	    $spaces = get_spaces($llegend{'in'},$maxlengthlengend,-6);
	    # ecriture de la courbe en input
	    $drawlineinmax->{'type'} = "line";
	    $drawlineinmax->{'color'} = $color_lines{'maxinput'};
	    $drawlineinmax->{'name'} = "maxinputbits";
	    $drawlineinmax->{'legend'} = "$l[0][0]{'legend'} entrant crête";
	    push @liste_arg,"draw";
	    push @liste_arg,$drawlineinmax;
	    # legende trafic in
	    push @liste_arg,"comment";
	    push @liste_arg,$spaces;
	    $gprintinmax->{0}->{'draw'}="maxinputbits";
	    $gprintinmax->{0}->{'format'}="MAX:%7.2lf %Sb/s";
	    push @liste_arg,"gprint";
	    push @liste_arg,$gprintinmax->{0};
	    $gprintinmax->{1}->{'draw'}="maxinputbits";
	    $gprintinmax->{1}->{'format'}="AVERAGE:%7.2lf %Sb/s";
	    push @liste_arg,"gprint";
	    push @liste_arg,$gprintinmax->{1};
	    $gprintinmax->{2}->{'draw'}="maxinputbits";
	    $gprintinmax->{2}->{'format'}="LAST:%7.2lf %Sb/s\\n";
	    push @liste_arg,"gprint";
	    push @liste_arg,$gprintinmax->{2};

	    # ecriture de la legende en entree
            $spaces = get_spaces($llegend{'out'},$maxlengthlengend,-6);
            # ecriture de la courbe en input
            $drawlineoutmax->{'type'} = "line";
            $drawlineoutmax->{'color'} = $color_lines{'maxoutput'};
            $drawlineoutmax->{'name'} = "maxoutputbits";
            $drawlineoutmax->{'legend'} = "$l[0][0]{'legend'} sortant crête";
            push @liste_arg,"draw";
            push @liste_arg,$drawlineoutmax;
            # legende trafic in
            push @liste_arg,"comment";
            push @liste_arg,$spaces;
            $gprintoutmax->{0}->{'draw'}="maxoutputbits";
            $gprintoutmax->{0}->{'format'}="MAX:%7.2lf %Sb/s";
            push @liste_arg,"gprint";
            push @liste_arg,$gprintoutmax->{0};
            $gprintoutmax->{1}->{'draw'}="maxoutputbits";
            $gprintoutmax->{1}->{'format'}="AVERAGE:%7.2lf %Sb/s";
            push @liste_arg,"gprint";
            push @liste_arg,$gprintoutmax->{1};
            $gprintoutmax->{2}->{'draw'}="maxoutputbits";
            $gprintoutmax->{2}->{'format'}="LAST:%7.2lf %Sb/s\\n";
            push @liste_arg,"gprint";
            push @liste_arg,$gprintoutmax->{2};
        }

	# ecriture de la courbe en output
	$spaces = get_spaces($llegend{'out'},$maxlengthlengend,0);
	$drawlineout->{'type'} = "line";
        $drawlineout->{'color'} = $color_lines{'output'};
        $drawlineout->{'name'} = "outputbits";
	$drawlineout->{'legend'} = "$l[0][0]{'legend'} sortant";
	push @liste_arg,"draw";
        push @liste_arg,$drawlineout;
        # legende trafic out
        push @liste_arg,"comment";
        push @liste_arg,$spaces;
        $gprintout->{0}->{'draw'}="outputbits";
        $gprintout->{0}->{'format'}="MAX:%7.2lf %Sb/s";
        push @liste_arg,"gprint";
        push @liste_arg,$gprintout->{0};
        $gprintout->{1}->{'draw'}="outputbits";
        $gprintout->{1}->{'format'}="AVERAGE:%7.2lf %Sb/s";
        push @liste_arg,"gprint";
        push @liste_arg,$gprintout->{1};
        $gprintout->{2}->{'draw'}="outputbits";
        $gprintout->{2}->{'format'}="LAST:%7.2lf %Sb/s\\n";
        push @liste_arg,"gprint";
        push @liste_arg,$gprintout->{2};

	$rrd->graph(
            image           => "-",
            title           => "$commentaire",
            vertical_label  => "trafic",
            height          => $height,
            width           => $width,
            start           => $start,
            end             => $end,
            @liste_arg,
    	);

	$rrd->error_message();
    }
    elsif($nb_rrd_bases > 1 && $nb_rrd_bases < 20)
    {
	aggreg_trafic($nb_rrd_bases,$ref_l,$output,$start,$end,$size,$commentaire);
    }
    else
    {
	print "nombre de bases rrd incorrect : $nb_rrd_bases";
    }
}


###########################################################
# Graph de trafic aggrégé
sub aggreg_trafic
{
    my ($nb_rrd_bases,$ref_l,$output,$start,$end,$size,$commentaire) = @_;
    # parametre détail :    0 : n'affiche que le cumul de l'ensemble des bases
    #			    1 : affiche le détail pour chaque base
   
    my ($width,$height) = split(/x/,$size);

    my $couleur_cumul = "c9c9c9";
    my @couleurs_flux = qw(e207ff 0010ff ffbb00 32bc2d ff8800 ff0000 00ffaa 000000 fb96be 795634);

    my $rrd = RRDTool::OO->new(file => "$ref_l->[0]->[0]->{'base'}");

    my @liste_arg1;
    my @liste_total;

    # creation des parametres pour le cumul total
    my $drawtotalin,$drawtotalout;
    $drawtotalin->{'type'} = "area";
    $drawtotalin->{'color'} = $couleur_cumul;
    $drawtotalin->{'name'} = "totalinputbits";
    $drawtotalin->{'legend'} = "total entrant";
    $drawtotalout->{'type'} = "area";
    $drawtotalout->{'color'} = $couleur_cumul;
    $drawtotalout->{'name'} = "totaloutputbits";
    $drawtotalout->{'legend'} = "total sortant";
   
    my $drawlinein,$drawlineout; 
    # dereferencement
    my @l = @$ref_l;
   
    # creation d'objets draw de type hidden pour chaque courbe de trafic
    # en input et en output 
    my $tl = @l;
    my $plus;
    for(my $i=0;$i<$tl;$i++)
    {
	my $ttl = @{$l[$i]};
	my $plusline="";
	for(my $j=0;$j<$ttl;$j++)
	{  
	    my ($drawin,$drawout);
	    $drawin->{'file'} = $l[$i][$j]{'base'};
	    $drawin->{'type'} = "hidden";
	    $drawin->{'dsname'} = "input";
	    $drawin->{'name'} = "$l[$i][$j]{'graph'}__inputbytes";
	    $drawin->{'cfunc'} = "AVERAGE";
	    $drawout->{'file'} = $l[$i][$j]{'base'};
            $drawout->{'type'} = "hidden";
            $drawout->{'dsname'} = "output";
            $drawout->{'name'} = "$l[$i][$j]{'graph'}__outputbytes";
            $drawout->{'cfunc'} = "AVERAGE";
	    $drawin->{'name'} =~ s/\./__/g;
	    $drawout->{'name'} =~ s/\./__/g;
	    # calcul du cumul total (afficher sour forme d'une aire)
	    if(exists $drawtotalin->{'cdef'})
	    {
		$drawtotalin->{'cdef'}="$drawtotalin->{'cdef'},$drawin->{'name'}";
		$drawtotalout->{'cdef'}="$drawtotalout->{'cdef'},$drawout->{'name'}";
		$plus = "$plus,ADDNAN";
	    }
	    else
	    {
		$drawtotalin->{'cdef'}=$drawin->{'name'};
		$drawtotalout->{'cdef'}=$drawout->{'name'};
	    }
	    # calcul du cumul seulement pour les donnes bases explicitement aggregees
	    # ex : Mcrc-rc1.wifi-sec+Mle7-rc1.wifi-sec
	    # (afficher sous forme de ligne)
	    if(exists $drawlinein->{$i}->{'cdef'})
	    {		   
		$drawlinein->{$i}->{'cdef'}="$drawlinein->{$i}->{'cdef'},$drawin->{'name'}";
		$drawlineout->{$i}->{'cdef'}="$drawlineout->{$i}->{'cdef'},$drawout->{'name'}";
		$plusline = "$plusline,ADDNAN"; 
	    }
	    else
	    {
		$drawlinein->{$i}->{'cdef'}=$drawin->{'name'};
		$drawlineout->{$i}->{'cdef'}=$drawout->{'name'};
	    }

	    push @liste_arg1,"draw";
	    push @liste_arg1,$drawin;
	    push @liste_arg1,"draw";
	    push @liste_arg1,$drawout;
	}
	# pour convertir les valeurs de trafic des lignes en bits
	$drawlinein->{$i}->{'cdef'}="$drawlinein->{$i}->{'cdef'}$plusline,8,*";
	$drawlineout->{$i}->{'cdef'}="$drawlineout->{$i}->{'cdef'}$plusline,-8,*";	
    } 
    
    # pour convertir les valeurs de trafic du total en bits 
    $drawtotalin->{'cdef'}="$drawtotalin->{'cdef'}$plus,8,*";
    $drawtotalout->{'cdef'}="$drawtotalout->{'cdef'}$plus,-8,*"; 
    
    # objet hidden pour creer une valeur de trafic en output positive
    my $drawtotaloutpositif;
    $drawtotaloutpositif->{'type'} = "hidden";
    $drawtotaloutpositif->{'name'} = "totaloutputbitspos";
    $drawtotaloutpositif->{'cdef'} = "totaloutputbits,-1,*",
 
    # ecriture du graphique de cumul en entree
    push @liste_total,"draw";
    push @liste_total,$drawtotalin;

    # comparaison des legendes pour la mise en page
    my %llegend;
    $llegend{'totalin'} = split(//,$drawtotalin->{'legend'});
    my $maxlengthlengend = $llegend{'totalin'};
    $llegend{'totalout'} = split(//,$drawtotalout->{'legend'});
    if($maxlengthlengend < $llegend{'totalout'})
    {
        $maxlengthlengend = $llegend{'totalout'};
    }

    for($i=0;$i<$tl;$i++)
    {
        if($l[$i][0]{'legend'} eq "")
        {
            $l[$i][0]{'legend'} = $l[$i][0]{'graph'};
        }
        $llegend{$i} = split(//,$l[$i][0]{'legend'});
        if($maxlengthlengend < $llegend{$i})
        {
            $maxlengthlengend = $llegend{$i};
        }
    }
    $maxlengthlengend = $maxlengthlengend + 4;

    # ecriture de la legende en entree
    my $spaces = get_spaces(0,$maxlengthlengend,10);
    push @liste_arg1,"comment";
    push @liste_arg1,"$spaces maximum          moyen        actuel\\n";
    my $gprinttotalin,$gprinttotalout;
    $spaces = get_spaces($llegend{'totalin'},$maxlengthlengend,0);
    push @liste_total,"comment";
    push @liste_total,$spaces;
    $gprinttotalin->{0}->{'draw'}="totalinputbits";
    $gprinttotalin->{0}->{'format'}="MAX:%7.2lf %Sb/s";
    push @liste_total,"gprint";
    push @liste_total,$gprinttotalin->{0};
    $gprinttotalin->{1}->{'draw'}="totalinputbits";
    $gprinttotalin->{1}->{'format'}="AVERAGE:%7.2lf %Sb/s";
    push @liste_total,"gprint";
    push @liste_total,$gprinttotalin->{1};
    $gprinttotalin->{2}->{'draw'}="totalinputbits";
    $gprinttotalin->{2}->{'format'}="LAST:%7.2lf %Sb/s\\n";
    push @liste_total,"gprint";
    push @liste_total,$gprinttotalin->{2};
    # ecriture du graphique de cumul en sortie 
    push @liste_total,"draw";
    push @liste_total,$drawtotalout;
    # insere l'objet draw de type hidden avec les valeurs d'output positives
    push @liste_total,"draw";
    push @liste_total,$drawtotaloutpositif;
    # ecriture de la legende en sortie
    $spaces = get_spaces($llegend{'totalout'},$maxlengthlengend,0);
    push @liste_total,"comment";
    push @liste_total,$spaces;
    $gprinttotalout->{0}->{'draw'}="totaloutputbitspos";
    $gprinttotalout->{0}->{'format'}="MAX:%7.2lf %Sb/s";
    push @liste_total,"gprint";
    push @liste_total,$gprinttotalout->{0};
    $gprinttotalout->{1}->{'draw'}="totaloutputbitspos";
    $gprinttotalout->{1}->{'format'}="AVERAGE:%7.2lf %Sb/s";
    push @liste_total,"gprint";
    push @liste_total,$gprinttotalout->{1};
    $gprinttotalout->{2}->{'draw'}="totaloutputbitspos";
    $gprinttotalout->{2}->{'format'}="LAST:%7.2lf %Sb/s\\n";
    push @liste_total,"gprint";
    push @liste_total,$gprinttotalout->{2};

    my $drawlineoutpositif;
    my $gprintin,$gprintout;
    # on cree les objets draw pour afficher les lignes
    for($i=0;$i<$tl;$i++)
    {
	# ecriture de la courbe en input
	$drawlinein->{$i}->{'type'} = "line";
    	$drawlinein->{$i}->{'color'} = $couleurs_flux[$i];
	$drawlinein->{$i}->{'name'} = "input$i";
	$drawlineout->{$i}->{'type'} = "line";
	$drawlineout->{$i}->{'color'} = $couleurs_flux[$i];
	$drawlineout->{$i}->{'name'} = "output$i";
	# insertion de la legende
	$drawlinein->{$i}->{'legend'} = "$l[$i][0]{'legend'} in";
	$drawlineout->{$i}->{'legend'} = "$l[$i][0]{'legend'} out";
	push @liste_total,"draw";
	push @liste_total,$drawlinein->{$i};
	$gprintin->{$i}->{0}->{'draw'}=$drawlinein->{$i}->{'name'};
	$gprintin->{$i}->{0}->{'format'}="MAX:%7.2lf %Sb/s";
	$spaces = get_spaces($llegend{$i},$maxlengthlengend,-3);
	push @liste_total,"comment";
	push @liste_total,$spaces;
	push @liste_total,"gprint";
	push @liste_total,$gprintin->{$i}->{0};
	$gprintin->{$i}->{1}->{'draw'}=$drawlinein->{$i}->{'name'};
        $gprintin->{$i}->{1}->{'format'}="AVERAGE:%7.2lf %Sb/s";
        push @liste_total,"gprint";
        push @liste_total,$gprintin->{$i}->{1};
	$gprintin->{$i}->{2}->{'draw'}=$drawlinein->{$i}->{'name'};
        $gprintin->{$i}->{2}->{'format'}="LAST:%7.2lf %Sb/s\\n";
        push @liste_total,"gprint";
        push @liste_total,$gprintin->{$i}->{2};
	# ecriture de la courbe en output
	$drawlineoutpositif->{$i}->{'type'} = "hidden";
	$drawlineoutpositif->{$i}->{'name'} = "outputpos$i";
	$drawlineoutpositif->{$i}->{'cdef'} = "$drawlineout->{$i}->{'name'},-1,*",
	push @liste_total,"draw";
	push @liste_total,$drawlineout->{$i};
	# insere l'objet draw de type hidden avec les valeurs d'output positives
        push @liste_total,"draw";
        push @liste_total,$drawlineoutpositif->{$i};
	$gprintout->{$i}->{0}->{'draw'}=$drawlineoutpositif->{$i}->{'name'};
        $gprintout->{$i}->{0}->{'format'}="MAX:%7.2lf %Sb/s";
	$spaces = get_spaces($llegend{$i},$maxlengthlengend,-4);
        push @liste_total,"comment";
        push @liste_total,$spaces;
        push @liste_total,"gprint";
        push @liste_total,$gprintout->{$i}->{0};
        $gprintout->{$i}->{1}->{'draw'}=$drawlineoutpositif->{$i}->{'name'};
        $gprintout->{$i}->{1}->{'format'}="AVERAGE:%7.2lf %Sb/s";
        push @liste_total,"gprint";
        push @liste_total,$gprintout->{$i}->{1};
        $gprintout->{$i}->{2}->{'draw'}=$drawlineoutpositif->{$i}->{'name'};
        $gprintout->{$i}->{2}->{'format'}="LAST:%7.2lf %Sb/s\\n";
        push @liste_total,"gprint";
        push @liste_total,$gprintout->{$i}->{2};
    }

    $rrd->graph(
	    image           => "-",
            title           => "$commentaire",
            vertical_label  => "trafic",
            height          => $height,
            width           => $width,
            start           => $start,
            end             => $end,
	    @liste_arg1,
	    @liste_total,
    );
}


# cree une chaine de caracteres avec des espaces pour aligner les légendes
# parametres : nombre de caracteres de la legende, nombre de car. de la légende
#		la plus longue, ajustement en nombre de blancs.
sub get_spaces
{
    my ($nb_char,$maxlengthlengend,$ajust) = @_;
    
    my $string = " ";

    my $nb_spaces = $maxlengthlengend - $nb_char + $ajust;

    system("echo \"($nb_char,$maxlengthlengend,$ajust) => $nb_spaces\" >> /var/tmp/sortie.txt");

    for(my $i=0;$i<$nb_spaces;$i++)
    {
	$string = "$string ";
    }
    
    system("echo \"'$string'\" >> /var/tmp/sortie.txt"); 
    return $string;
}


sub GaugeAuthWiFi
{
    my ($nb_rrd_bases,$ref_l,$output,$start,$end,$size,$commentaire) = @_;

    # dereferencement
    my @l = @$ref_l;

    my ($width,$height) = split(/x/,$size);

    my $couleur_osirissec = "0000ff";
    my $couleur_osiris = "00ff00";
    my $couleur_cumul = "bcbcbc";
    my $couleur_osiris_max = "a1ff00";
    my $couleur_osirissec_max = "00aaff";
    my $couleur_cumul_max = "cccccc";

    if($commentaire eq "")  
    {
	$commentaire = "Clients WiFi authentifiés";
    }

    my $rrd = RRDTool::OO->new(file => "$ref_l->[0]->[0]->{'base'}");

    my $osiris_sec = "osiris-sec";
    my $osiris = "osiris";
    ############################################
    #	Hack temporaire pour le graphique global
    #
    if($ref_l->[0]->[0]->{'base'} =~ m/general\/authentifies_wifi\.rrd/)
    {
	$osiris_sec = "8021X";
	$osiris = "portail_captif";
    }
    ###########################################
    if(($end - $start) < 800000)
    {
	$rrd->graph(
	image           => "-",
        title           => "$commentaire",
        vertical_label  => "nb authentifiés",
	lower_limit	=> 0, 
	units_exponent	=> 0,
        height          => $height,
        width           => $width,
        start           => $start,
        end             => $end,
        draw            => {
	    type        => "hidden",
	    dsname      => $osiris_sec,
	    name        => 'osiris-sec',
	    cfunc       => 'AVERAGE',
        },
        draw            => {
            type        => "hidden",
            dsname      => $osiris ,
            name        => 'osiris',
            cfunc       => 'AVERAGE',
        },
        comment        => '                min      max    moyen    actuel\n',
        draw           => {
            type        => 'area',
            color       => $couleur_cumul,
            name        => "cumul",
            cdef        => "osiris,osiris-sec,ADDNAN",
            legend      => 'total',
        },
	comment        => '  ',
        gprint         => {
            draw      => 'cumul',
            format    => 'MIN:%5.0lf %S',
        },
	gprint         => {
            draw      => 'cumul',
            format    => 'MAX:%5.0lf %S',
        },
	gprint         => {
            draw      => 'cumul',
            format    => 'AVERAGE:%5.0lf %S',
        },
	gprint         => {
            draw      => 'cumul',
            format    => 'LAST:%5.0lf %S\\n',
        },
        draw            => {
            type        => 'line',
            color       => $couleur_osiris,
            cdef        => "osiris",
	    legend      => 'osiris',
        },
	comment        => ' ',
	gprint         => {
            draw      => 'osiris',
            format    => 'MIN:%5.0lf %S',
        },
        gprint         => {
            draw      => 'osiris',
            format    => 'MAX:%5.0lf %S',
        },
        gprint         => {
            draw      => 'osiris',
            format    => 'AVERAGE:%5.0lf %S',
        },
        gprint         => {
            draw      => 'osiris',
            format    => 'LAST:%5.0lf %S\\n',
        },
        draw            => {
            type        => 'line',
            color       => $couleur_osirissec,
            cdef        => "osiris-sec",
            legend      => '802.1X',
        },
	comment        => ' ',
        gprint         => {
            draw      => 'osiris-sec',
            format    => 'MIN:%5.0lf %S',
        },
        gprint         => {
            draw      => 'osiris-sec',
            format    => 'MAX:%5.0lf %S',
        },
        gprint         => {
            draw      => 'osiris-sec',
            format    => 'AVERAGE:%5.0lf %S',
        },
        gprint         => {
            draw      => 'osiris-sec',
            format    => 'LAST:%5.0lf %S\\n',
        },
	);
    }
    else
    {
        $rrd->graph(
        image           => "-",
        title           => "$commentaire",
        vertical_label  => "nb authentifiés",
        lower_limit     => 0,
        units_exponent  => 0,
        height          => $height,
        width           => $width,
        start           => $start,
        end             => $end,
        draw            => {
            type        => "hidden",
            dsname      => $osiris_sec,
            name        => 'osiris-sec',
            cfunc       => 'AVERAGE',
        },
        draw            => {
            type        => "hidden",
            dsname      => $osiris,
            name        => 'osiris',
            cfunc       => 'AVERAGE',
        },
	draw            => {
            type        => "hidden",
            dsname      => $osiris_sec,
            name        => 'maxosiris-sec',
            cfunc       => 'MAX',
        },
        draw            => {
            type        => "hidden",
            dsname      => $osiris,
            name        => 'maxosiris',
            cfunc       => 'MAX',
        },
        comment        => '                      min      max    moyen    actuel\n',
	draw           => {
            type        => 'area',
            color       => $couleur_cumul_max,
            name        => "cumulmax",
            cdef        => "maxosiris,maxosiris-sec,ADDNAN",
            legend      => 'total crête',
        },
	comment        => '  ',
	gprint         => {
            draw      => 'cumulmax',
            format    => 'MIN:%5.0lf %S',
        },
        gprint         => {
            draw      => 'cumulmax',
            format    => 'MAX:%5.0lf %S',
        },
        gprint         => {
            draw      => 'cumulmax',
            format    => 'AVERAGE:%5.0lf %S',
        },
        gprint         => {
            draw      => 'cumulmax',
            format    => 'LAST:%5.0lf %S\\n',
        },
        draw           => {
            type        => 'area',
            color       => $couleur_cumul,
            name        => "cumul",
            cdef        => "osiris,osiris-sec,ADDNAN",
            legend      => 'total',
        },
	comment        => '        ',
        gprint         => {
            draw      => 'cumul',
            format    => 'MIN:%5.0lf %S',
        },
        gprint         => {
            draw      => 'cumul',
            format    => 'MAX:%5.0lf %S',
        },
        gprint         => {
            draw      => 'cumul',
            format    => 'AVERAGE:%5.0lf %S',
        },
        gprint         => {
            draw      => 'cumul',
            format    => 'LAST:%5.0lf %S\\n',
        },
	draw            => {
            type        => 'line',
            color       => $couleur_osiris_max,
            cdef        => "maxosiris",
            legend      => 'osiris crête',
        },
	comment        => ' ',
        gprint         => {
            draw      => 'maxosiris',
            format    => 'MIN:%5.0lf %S',
        },
        gprint         => {
            draw      => 'maxosiris',
            format    => 'MAX:%5.0lf %S',
        },
        gprint         => {
            draw      => 'maxosiris',
            format    => 'AVERAGE:%5.0lf %S',
        },
        gprint         => {
            draw      => 'maxosiris',
            format    => 'LAST:%5.0lf %S\\n',
        },
	draw            => {
            type        => 'line',
            color       => $couleur_osirissec_max,
            cdef        => "maxosiris-sec",
            legend      => '802.1X crête',
        },
	comment        => ' ',
        gprint         => {
            draw      => 'maxosiris-sec',
            format    => 'MIN:%5.0lf %S',
        },
        gprint         => {
            draw      => 'maxosiris-sec',
            format    => 'MAX:%5.0lf %S',
        },
        gprint         => {
            draw      => 'maxosiris-sec',
            format    => 'AVERAGE:%5.0lf %S',
        },
        gprint         => {
            draw      => 'maxosiris-sec',
            format    => 'LAST:%5.0lf %S\\n',
        },
	draw            => {
            type        => 'line',
            color       => $couleur_osiris,
            cdef        => "osiris",
            legend      => 'osiris',
        },
	comment        => '       ',
        gprint         => {
            draw      => 'osiris',
            format    => 'MIN:%5.0lf %S',
        },
        gprint         => {
            draw      => 'osiris',
            format    => 'MAX:%5.0lf %S',
        },
        gprint         => {
            draw      => 'osiris',
            format    => 'AVERAGE:%5.0lf %S',
        },
        gprint         => {
            draw      => 'osiris',
            format    => 'LAST:%5.0lf %S\\n',
        },
        draw            => {
            type        => 'line',
            color       => $couleur_osirissec,
            cdef        => "osiris-sec",
            legend      => '802.1X',
        },
	comment        => '       ',
        gprint         => {
            draw      => 'osiris-sec',
            format    => 'MIN:%5.0lf %S',
        },
        gprint         => {
            draw      => 'osiris-sec',
            format    => 'MAX:%5.0lf %S',
        },
        gprint         => {
            draw      => 'osiris-sec',
            format    => 'AVERAGE:%5.0lf %S',
        },
        gprint         => {
            draw      => 'osiris-sec',
            format    => 'LAST:%5.0lf %S\\n',
        },
	);
    }
}


sub GaugeAssocWiFi
{
    my ($nb_rrd_bases,$ref_l,$output,$start,$end,$size,$commentaire) = @_;

    # dereferencement
    my @l = @$ref_l;

    my ($width,$height) = split(/x/,$size);

    my $couleur_osirissec = "ff0000";
    my $couleur_osiris = "00ff00";
    my $couleur_cumul = "bcbcbc";
    my $couleur_osiris_max = "a1ff00";
    my $couleur_osirissec_max = "ff91bd";
    my $couleur_cumul_max = "cccccc";

    if($commentaire eq "")
    {
        $commentaire = "Clients WiFi associés";
    }

    my $rrd = RRDTool::OO->new(file => "$ref_l->[0]->[0]->{'base'}");

    if(($end - $start) < 800000)
    {
	$rrd->graph(
	image           => "-",
        title           => "$commentaire",
        vertical_label  => "nb authentifiés",
	lower_limit	=> 0, 
	units_exponent	=> 0,
        height          => $height,
        width           => $width,
        start           => $start,
        end             => $end,
        draw            => {
	    type        => "hidden",
	    dsname      => "wpa",
	    name        => 'osiris-sec',
	    cfunc       => 'AVERAGE',
        },
        draw            => {
            type        => "hidden",
            dsname      => "clair",
            name        => 'osiris',
            cfunc       => 'AVERAGE',
        },
        comment        => '                min      max    moyen    actuel\n',
        draw           => {
            type        => 'area',
            color       => $couleur_cumul,
            name        => "cumul",
            cdef        => "osiris,osiris-sec,ADDNAN",
            legend      => 'total',
        },
	comment        => '  ',
        gprint         => {
            draw      => 'cumul',
            format    => 'MIN:%5.0lf %S',
        },
	gprint         => {
            draw      => 'cumul',
            format    => 'MAX:%5.0lf %S',
        },
	gprint         => {
            draw      => 'cumul',
            format    => 'AVERAGE:%5.0lf %S',
        },
	gprint         => {
            draw      => 'cumul',
            format    => 'LAST:%5.0lf %S\\n',
        },
        draw            => {
            type        => 'line',
            color       => $couleur_osiris,
            cdef        => "osiris",
	    legend      => 'osiris',
        },
	comment        => ' ',
	gprint         => {
            draw      => 'osiris',
            format    => 'MIN:%5.0lf %S',
        },
        gprint         => {
            draw      => 'osiris',
            format    => 'MAX:%5.0lf %S',
        },
        gprint         => {
            draw      => 'osiris',
            format    => 'AVERAGE:%5.0lf %S',
        },
        gprint         => {
            draw      => 'osiris',
            format    => 'LAST:%5.0lf %S\\n',
        },
        draw            => {
            type        => 'line',
            color       => $couleur_osirissec,
            cdef        => "osiris-sec",
            legend      => '802.1X',
        },
	comment        => ' ',
        gprint         => {
            draw      => 'osiris-sec',
            format    => 'MIN:%5.0lf %S',
        },
        gprint         => {
            draw      => 'osiris-sec',
            format    => 'MAX:%5.0lf %S',
        },
        gprint         => {
            draw      => 'osiris-sec',
            format    => 'AVERAGE:%5.0lf %S',
        },
        gprint         => {
            draw      => 'osiris-sec',
            format    => 'LAST:%5.0lf %S\\n',
        },
	);
    }
    else
    {
        $rrd->graph(
        image           => "-",
        title           => "$commentaire",
        vertical_label  => "nb authentifiés",
        lower_limit     => 0,
        units_exponent  => 0,
        height          => $height,
        width           => $width,
        start           => $start,
        end             => $end,
        draw            => {
            type        => "hidden",
            dsname      => "wpa",
            name        => 'osiris-sec',
            cfunc       => 'AVERAGE',
        },
        draw            => {
            type        => "hidden",
            dsname      => "clair",
            name        => 'osiris',
            cfunc       => 'AVERAGE',
        },
	draw            => {
            type        => "hidden",
            dsname      => "wpa",
            name        => 'maxosiris-sec',
            cfunc       => 'MAX',
        },
        draw            => {
            type        => "hidden",
            dsname      => "clair",
            name        => 'maxosiris',
            cfunc       => 'MAX',
        },
        comment        => '                      min      max    moyen    actuel\n',
	draw           => {
            type        => 'area',
            color       => $couleur_cumul_max,
            name        => "cumulmax",
            cdef        => "maxosiris,maxosiris-sec,ADDNAN",
            legend      => 'total crête',
        },
	comment        => '  ',
	gprint         => {
            draw      => 'cumulmax',
            format    => 'MIN:%5.0lf %S',
        },
        gprint         => {
            draw      => 'cumulmax',
            format    => 'MAX:%5.0lf %S',
        },
        gprint         => {
            draw      => 'cumulmax',
            format    => 'AVERAGE:%5.0lf %S',
        },
        gprint         => {
            draw      => 'cumulmax',
            format    => 'LAST:%5.0lf %S\\n',
        },
        draw           => {
            type        => 'area',
            color       => $couleur_cumul,
            name        => "cumul",
            cdef        => "osiris,osiris-sec,ADDNAN",
            legend      => 'total',
        },
	comment        => '        ',
        gprint         => {
            draw      => 'cumul',
            format    => 'MIN:%5.0lf %S',
        },
        gprint         => {
            draw      => 'cumul',
            format    => 'MAX:%5.0lf %S',
        },
        gprint         => {
            draw      => 'cumul',
            format    => 'AVERAGE:%5.0lf %S',
        },
        gprint         => {
            draw      => 'cumul',
            format    => 'LAST:%5.0lf %S\\n',
        },
	draw            => {
            type        => 'line',
            color       => $couleur_osiris_max,
            cdef        => "maxosiris",
            legend      => 'osiris crête',
        },
	comment        => ' ',
        gprint         => {
            draw      => 'maxosiris',
            format    => 'MIN:%5.0lf %S',
        },
        gprint         => {
            draw      => 'maxosiris',
            format    => 'MAX:%5.0lf %S',
        },
        gprint         => {
            draw      => 'maxosiris',
            format    => 'AVERAGE:%5.0lf %S',
        },
        gprint         => {
            draw      => 'maxosiris',
            format    => 'LAST:%5.0lf %S\\n',
        },
	draw            => {
            type        => 'line',
            color       => $couleur_osirissec_max,
            cdef        => "maxosiris-sec",
            legend      => '802.1X crête',
        },
	comment        => ' ',
        gprint         => {
            draw      => 'maxosiris-sec',
            format    => 'MIN:%5.0lf %S',
        },
        gprint         => {
            draw      => 'maxosiris-sec',
            format    => 'MAX:%5.0lf %S',
        },
        gprint         => {
            draw      => 'maxosiris-sec',
            format    => 'AVERAGE:%5.0lf %S',
        },
        gprint         => {
            draw      => 'maxosiris-sec',
            format    => 'LAST:%5.0lf %S\\n',
        },
	draw            => {
            type        => 'line',
            color       => $couleur_osiris,
            cdef        => "osiris",
            legend      => 'osiris',
        },
	comment        => '       ',
        gprint         => {
            draw      => 'osiris',
            format    => 'MIN:%5.0lf %S',
        },
        gprint         => {
            draw      => 'osiris',
            format    => 'MAX:%5.0lf %S',
        },
        gprint         => {
            draw      => 'osiris',
            format    => 'AVERAGE:%5.0lf %S',
        },
        gprint         => {
            draw      => 'osiris',
            format    => 'LAST:%5.0lf %S\\n',
        },
        draw            => {
            type        => 'line',
            color       => $couleur_osirissec,
            cdef        => "osiris-sec",
            legend      => '802.1X',
        },
	comment        => '       ',
        gprint         => {
            draw      => 'osiris-sec',
            format    => 'MIN:%5.0lf %S',
        },
        gprint         => {
            draw      => 'osiris-sec',
            format    => 'MAX:%5.0lf %S',
        },
        gprint         => {
            draw      => 'osiris-sec',
            format    => 'AVERAGE:%5.0lf %S',
        },
        gprint         => {
            draw      => 'osiris-sec',
            format    => 'LAST:%5.0lf %S\\n',
        },
	);
    }
}


sub GaugeDHCPleases
{
    my ($nb_rrd_bases,$ref_l,$output,$start,$end,$size,$commentaire) = @_;

    # dereferencement
    my @l = @$ref_l;

    my ($width,$height) = split(/x/,$size);

    my $couleur_inuse = "0000ff";
    my $couleur_avail = "ff0000";
    my $couleur_inuse_max = "a7c7cb";

    if($commentaire eq "")
    {
        $commentaire = "Baux DHCP actifs";
    }

    my $rrd = RRDTool::OO->new(file => "$ref_l->[0]->[0]->{'base'}");

    if(($end - $start) < 800000)
    {
	$rrd->graph(
	image           => "-",
        title           => "$commentaire",
        vertical_label  => "nb baux DHCP",
	lower_limit	=> 0, 
	units_exponent	=> 0,
        height          => $height,
        width           => $width,
        start           => $start,
        end             => $end,
        draw            => {
	    type        => "hidden",
	    dsname      => "avail",
	    name        => 'avail',
	    cfunc       => 'AVERAGE',
        },
        draw            => {
            type        => "hidden",
            dsname      => "inuse",
            name        => 'inuse',
            cfunc       => 'AVERAGE',
        },
        comment        => '                                 min    moyen    actuel\n',
        draw            => {
            type        => 'line',
            color       => $couleur_avail,
            cdef        => "avail",
	    legend      => 'Adresses IP disponibles',
        },
	comment        => ' ',
	gprint         => {
            draw      => 'avail',
            format    => 'MIN:%5.0lf %S',
        },
        gprint         => {
            draw      => 'avail',
            format    => 'AVERAGE:%5.0lf %S',
        },
        gprint         => {
            draw      => 'avail',
            format    => 'LAST:%5.0lf %S\\n',
        },
        draw            => {
            type        => 'line',
            color       => $couleur_inuse,
            cdef        => "inuse",
            legend      => 'Adresses IP allouées',
        },
	comment        => '    ',
        gprint         => {
            draw      => 'inuse',
            format    => 'MIN:%5.0lf %S',
        },
        gprint         => {
            draw      => 'inuse',
            format    => 'AVERAGE:%5.0lf %S',
        },
        gprint         => {
            draw      => 'inuse',
            format    => 'LAST:%5.0lf %S\\n',
        },
	);
    }
    else
    {
	$rrd->graph(
        image           => "-",
        title           => "$commentaire",
        vertical_label  => "nb baux DHCP",
        lower_limit     => 0,
        units_exponent  => 0,
        height          => $height,
        width           => $width,
        start           => $start,
        end             => $end,
	draw            => {
            type        => "hidden",
            dsname      => "avail",
            name        => 'avail',
            cfunc       => 'AVERAGE',
        },
        draw            => {
            type        => "hidden",
            dsname      => "inuse",
            name        => 'inuse',
            cfunc       => 'AVERAGE',
        },
	draw            => {
            type        => "hidden",
            dsname      => "inuse",
            name        => 'maxinuse',
            cfunc       => 'MAX',
        },
        comment        => '                                           min    moyen    actuel\n',
	draw            => {
            type        => 'line',
            color       => $couleur_avail,
            cdef        => "avail",
            legend      => 'Adresses IP disponibles',
        },
        comment        => '           ',
        gprint         => {
            draw      => 'avail',
            format    => 'MIN:%5.0lf %S',
        },
        gprint         => {
            draw      => 'avail',
            format    => 'AVERAGE:%5.0lf %S',
        },
        gprint         => {
            draw      => 'avail',
            format    => 'LAST:%5.0lf %S\\n',
        },
	draw            => {
            type        => 'line',
            color       => $couleur_inuse_max,
            cdef        => "maxinuse",
            legend      => 'Adresses IP allouées (en crête)',
        },
        comment        => '   ',
        gprint         => {
            draw      => 'maxinuse',
            format    => 'MIN:%5.0lf %S',
        },
        gprint         => {
            draw      => 'maxinuse',
            format    => 'AVERAGE:%5.0lf %S',
        },
        gprint         => {
            draw      => 'maxinuse',
            format    => 'LAST:%5.0lf %S\\n',
        },
        draw            => {
            type        => 'line',
            color       => $couleur_inuse,
            cdef        => "inuse",
            legend      => 'Adresses IP allouées (en moyenne)',
        },
        comment        => ' ',
        gprint         => {
            draw      => 'inuse',
            format    => 'MIN:%5.0lf %S',
        },
        gprint         => {
            draw      => 'inuse',
            format    => 'AVERAGE:%5.0lf %S',
        },
        gprint         => {
            draw      => 'inuse',
            format    => 'LAST:%5.0lf %S\\n',
        },
	);
    }
}


# afficher l'utilisation moyenne de la CPU des equipements Juniper
# sur les slots O et 1 des ssb et RE
sub GaugeCPUJuniper
{
    my ($nb_rrd_bases,$ref_l,$output,$start,$end,$size,$commentaire) = @_;

    # dereferencement
    my @l = @$ref_l;

    my ($width,$height) = split(/x/,$size);

    my $couleur0 = "8888ff";
    my $couleur1 = "0000ff";

    if($commentaire eq "")
    {
        $commentaire = "Utilisation CPU en %";
    }

    my $rrd = RRDTool::OO->new(file => "$ref_l->[0]->[0]->{'base'}");

    $rrd->graph(
	image           => "-",
        title           => "$commentaire",
        vertical_label  => "% CPU",
	lower_limit	=> 0, 
	units_exponent	=> 0,
        height          => $height,
        width           => $width,
        start           => $start,
        end             => $end,
        draw            => {
	    type        => "hidden",
	    dsname      => "cpu0",
	    name        => 'cpu0',
	    cfunc       => 'AVERAGE',
        },
        draw            => {
            type        => "hidden",
            dsname      => "cpu1",
            name        => 'cpu1',
            cfunc       => 'AVERAGE',
        },
        comment        => '                         min    max   moyen  actuel\n',
        draw            => {
            type        => 'line',
            color       => $couleur0,
            cdef        => "cpu0",
	    legend      => 'CPU sur le slot 0',
        },
	comment        => ' ',
	gprint         => {
            draw      => 'cpu0',
            format    => 'MIN:%3.0lf %S',
        },
	gprint         => {
            draw      => 'cpu0',
            format    => 'MAX:%3.0lf %S',
        },
        gprint         => {
            draw      => 'cpu0',
            format    => 'AVERAGE:%3.0lf %S',
        },
        gprint         => {
            draw      => 'cpu0',
            format    => 'LAST:%3.0lf %S\\n',
        },
        draw            => {
            type        => 'line',
            color       => $couleur1,
            cdef        => "cpu1",
            legend      => 'CPU sur le slot 1',
        },
        comment        => ' ',
        gprint         => {
            draw      => 'cpu1',
            format    => 'MIN:%3.0lf %S',
        },
        gprint         => {
            draw      => 'cpu1',
            format    => 'MAX:%3.0lf %S',
        },
        gprint         => {
            draw      => 'cpu1',
            format    => 'AVERAGE:%3.0lf %S',
        },
        gprint         => {
            draw      => 'cpu1',
            format    => 'LAST:%3.0lf %S\\n',
        },
    );
}


# afficher l'utilisation moyenne de la CPU des equipements Cisco
# sur 1m et sur 5m
sub GaugeCPUCisco
{
    my ($nb_rrd_bases,$ref_l,$output,$start,$end,$size,$commentaire) = @_;

    # dereferencement
    my @l = @$ref_l;

    my ($width,$height) = split(/x/,$size);

    my $couleur_1min = "8888ff";
    my $couleur_5min = "0000ff";

    if($commentaire eq "")
    {
        $commentaire = "Utilisation CPU en %";
    }

    my $rrd = RRDTool::OO->new(file => "$ref_l->[0]->[0]->{'base'}");

    $rrd->graph(
	image           => "-",
        title           => "$commentaire",
        vertical_label  => "% CPU",
	lower_limit	=> 0, 
	units_exponent	=> 0,
        height          => $height,
        width           => $width,
        start           => $start,
        end             => $end,
        draw            => {
	    type        => "hidden",
	    dsname      => "cpu_1min",
	    name        => 'cpu_1min',
	    cfunc       => 'AVERAGE',
        },
        draw            => {
            type        => "hidden",
            dsname      => "cpu_5min",
            name        => 'cpu_5min',
            cfunc       => 'AVERAGE',
        },
        comment        => '                             min    max   moyen  actuel\n',
        draw            => {
            type        => 'line',
            color       => $couleur_1min,
            cdef        => "cpu_1min",
	    legend      => 'Moyenne sur 1 minute',
        },
	comment        => '  ',
	gprint         => {
            draw      => 'cpu_1min',
            format    => 'MIN:%3.0lf %S',
        },
	gprint         => {
            draw      => 'cpu_1min',
            format    => 'MAX:%3.0lf %S',
        },
        gprint         => {
            draw      => 'cpu_1min',
            format    => 'AVERAGE:%3.0lf %S',
        },
        gprint         => {
            draw      => 'cpu_1min',
            format    => 'LAST:%3.0lf %S\\n',
        },
        draw            => {
            type        => 'line',
            color       => $couleur_5min,
            cdef        => "cpu_5min",
            legend      => 'Moyenne sur 5 minutes',
        },
        comment        => ' ',
        gprint         => {
            draw      => 'cpu_5min',
            format    => 'MIN:%3.0lf %S',
        },
        gprint         => {
            draw      => 'cpu_5min',
            format    => 'MAX:%3.0lf %S',
        },
        gprint         => {
            draw      => 'cpu_5min',
            format    => 'AVERAGE:%3.0lf %S',
        },
        gprint         => {
            draw      => 'cpu_5min',
            format    => 'LAST:%3.0lf %S\\n',
        },
    );
}


# afficher pour un serveur l'utilisation moyenne de la CPU 
# par le système et en mode user
sub GaugeCPUServer
{
    my ($nb_rrd_bases,$ref_l,$output,$start,$end,$size,$commentaire) = @_;

    # dereferencement
    my @l = @$ref_l;

    my ($width,$height) = split(/x/,$size);

    my $system = "ff0000";
    my $user = "0000ff";
    my $couleur_cumul = "707070";

    if($commentaire eq "")
    {
        $commentaire = "Utilisation CPU en %";
    }

    my $rrd = RRDTool::OO->new(file => "$ref_l->[0]->[0]->{'base'}");

    $rrd->graph(
	image           => "-",
        title           => "$commentaire",
        vertical_label  => "% CPU",
	lower_limit	=> 0, 
	units_exponent	=> 0,
        height          => $height,
        width           => $width,
        start           => $start,
        end             => $end,
        draw            => {
	    type        => "hidden",
	    dsname      => "cpu_system",
	    name        => 'cpu_system',
	    cfunc       => 'AVERAGE',
        },
        draw            => {
            type        => "hidden",
            dsname      => "cpu_user",
            name        => 'cpu_user',
            cfunc       => 'AVERAGE',
        },
        comment        => '              min    max   moyen  actuel\n',
	draw           => {
            type        => 'area',
            color       => $couleur_cumul,
            name        => "total",
            cdef        => "cpu_system,cpu_user,ADDNAN",
            legend      => 'total',
        },
        comment        => '   ',
	gprint         => {
            draw      => 'total',
            format    => 'MIN:%3.0lf %S',
        },
        gprint         => {
            draw      => 'total',
            format    => 'MAX:%3.0lf %S',
        },
        gprint         => {
            draw      => 'total',
            format    => 'AVERAGE:%3.0lf %S',
        },
        gprint         => {
            draw      => 'total',
            format    => 'LAST:%3.0lf %S\\n',
        },
        draw            => {
            type        => 'line',
            color       => $system,
            cdef        => "cpu_system",
	    legend      => 'system',
        },
	comment        => '  ',
	gprint         => {
            draw      => 'cpu_system',
            format    => 'MIN:%3.0lf %S',
        },
	gprint         => {
            draw      => 'cpu_system',
            format    => 'MAX:%3.0lf %S',
        },
        gprint         => {
            draw      => 'cpu_system',
            format    => 'AVERAGE:%3.0lf %S',
        },
        gprint         => {
            draw      => 'cpu_system',
            format    => 'LAST:%3.0lf %S\\n',
        },
        draw            => {
            type        => 'line',
            color       => $user,
            cdef        => "cpu_user",
            legend      => 'user',
        },
        comment        => '    ',
        gprint         => {
            draw      => 'cpu_user',
            format    => 'MIN:%3.0lf %S',
        },
        gprint         => {
            draw      => 'cpu_user',
            format    => 'MAX:%3.0lf %S',
        },
        gprint         => {
            draw      => 'cpu_user',
            format    => 'AVERAGE:%3.0lf %S',
        },
        gprint         => {
            draw      => 'cpu_user',
            format    => 'LAST:%3.0lf %S\\n',
        },
    );
}


# affiche la charge d'un serveur sur 5 minutes et 15 minutes
sub GaugeLoadAverage
{
    my ($nb_rrd_bases,$ref_l,$output,$start,$end,$size,$commentaire) = @_;

    # dereferencement
    my @l = @$ref_l;

    my ($width,$height) = split(/x/,$size);

    my $couleur_5min = "0000ff";
    my $couleur_15min = "ff6000";

    if($commentaire eq "")
    {
        $commentaire = "Load Average";
    }

    my $rrd = RRDTool::OO->new(file => "$ref_l->[0]->[0]->{'base'}");

    $rrd->graph(
	image           => "-",
        title           => "$commentaire",
        vertical_label  => "Load Average",
	lower_limit	=> 0, 
	units_exponent	=> 0,
        height          => $height,
        width           => $width,
        start           => $start,
        end             => $end,
        draw            => {
	    type        => "hidden",
	    dsname      => "load_5m",
	    name        => 'load_5m',
	    cfunc       => 'AVERAGE',
        },
        draw            => {
            type        => "hidden",
            dsname      => "load_15m",
            name        => 'load_15m',
            cfunc       => 'AVERAGE',
        },
        comment        => '                             min    max   moyen  actuel\n',
        draw            => {
            type        => 'line',
            color       => $couleur_5min,
            cdef        => "load_5m",
	    legend      => 'Moyenne sur 5 minutes',
        },
	comment        => '  ',
	gprint         => {
            draw      => 'load_5m',
            format    => 'MIN:%3.2lf',
        },
	gprint         => {
            draw      => 'load_5m',
            format    => 'MAX:%3.2lf',
        },
        gprint         => {
            draw      => 'load_5m',
            format    => 'AVERAGE:%3.2lf',
        },
        gprint         => {
            draw      => 'load_5m',
            format    => 'LAST:%3.2lf\\n',
        },
        draw            => {
            type        => 'line',
            color       => $couleur_15min,
            cdef        => "load_15m",
            legend      => 'Moyenne sur 15 minutes',
        },
        comment        => ' ',
        gprint         => {
            draw      => 'load_15m',
            format    => 'MIN:%3.2lf',
        },
        gprint         => {
            draw      => 'load_15m',
            format    => 'MAX:%3.2lf',
        },
        gprint         => {
            draw      => 'load_15m',
            format    => 'AVERAGE:%3.2lf',
        },
        gprint         => {
            draw      => 'load_15m',
            format    => 'LAST:%3.2lf\\n',
        },
    );
}


# affichage generique d'une gauge
# 
sub GaugeRespTime
{
    my ($nb_rrd_bases,$ref_l,$output,$start,$end,$size,$commentaire) = @_;

    # dereferencement
    my @l = @$ref_l;

    my ($width,$height) = split(/x/,$size);

    my $couleur = "0000ff";

    if($commentaire eq "")
    {
        $commentaire = "Temps de réponse";
    }

    my $rrd = RRDTool::OO->new(file => "$ref_l->[0]->[0]->{'base'}");

    $rrd->graph(
	image           => "-",
        title           => "$commentaire",
        vertical_label  => "Temps de réponse (sec)",
	lower_limit	=> 0, 
	units_exponent	=> 0,
        height          => $height,
        width           => $width,
        start           => $start,
        end             => $end,
        draw            => {
	    type        => "hidden",
	    dsname      => "time",
	    name        => 'time',
	    cfunc       => 'AVERAGE',
        },
        comment        => '                              min     max  moyen  actuel\n',
        draw            => {
            type        => 'line',
            color       => $couleur,
            cdef        => "time",
	    legend      => 'temps de réponse (s)',
        },
	comment        => '  ',
	gprint         => {
            draw      => 'time',
            format    => 'MIN:%3.3lf',
        },
	gprint         => {
            draw      => 'time',
            format    => 'MAX:%3.3lf',
        },
        gprint         => {
            draw      => 'time',
            format    => 'AVERAGE:%3.3lf',
        },
        gprint         => {
            draw      => 'time',
            format    => 'LAST:%3.3lf\\n',
        },
    );
}


# afficher le nombre de transactions par secondes pour un disque 
# en lecture et en ecriture
sub GaugeTPSDisk
{
    my ($nb_rrd_bases,$ref_l,$output,$start,$end,$size,$commentaire) = @_;

    # dereferencement
    my @l = @$ref_l;

    my ($width,$height) = split(/x/,$size);

    my $couleur_IOreads = "00ff00";
    my $couleur_IOwrites = "ffff00";
    my $couleur_cumul = "707070";

    if($commentaire eq "")
    {
        $commentaire = "Transactions par seconde";
    }

    my $rrd = RRDTool::OO->new(file => "$ref_l->[0]->[0]->{'base'}");

    $rrd->graph(
	image           => "-",
        title           => "$commentaire",
        vertical_label  => "TPS",
	lower_limit	=> 0, 
	units_exponent	=> 0,
        height          => $height,
        width           => $width,
        start           => $start,
        end             => $end,
        draw            => {
	    type        => "hidden",
	    dsname      => "ioreads",
	    name        => 'IOreads',
	    cfunc       => 'AVERAGE',
        },
        draw            => {
            type        => "hidden",
            dsname      => "iowrites",
            name        => 'IOwrites',
            cfunc       => 'AVERAGE',
        },
        comment        => '                     min      max     moyen   actuel\n',
	draw           => {
            type        => 'area',
            color       => $couleur_cumul,
            name        => "total",
            cdef        => "IOreads,IOwrites,+",
            legend      => 'total',
        },
        comment        => '       ',
	gprint         => {
            draw      => 'total',
            format    => 'MIN:%5.0lf %S',
        },
        gprint         => {
            draw      => 'total',
            format    => 'MAX:%5.0lf %S',
        },
        gprint         => {
            draw      => 'total',
            format    => 'AVERAGE:%5.0lf %S',
        },
        gprint         => {
            draw      => 'total',
            format    => 'LAST:%5.0lf %S\\n',
        },
        draw            => {
            type        => 'line',
            color       => $couleur_IOreads,
            cdef        => "IOreads",
	    legend      => 'IOreads',
        },
	comment        => '     ',
	gprint         => {
            draw      => 'IOreads',
            format    => 'MIN:%5.0lf %S',
        },
	gprint         => {
            draw      => 'IOreads',
            format    => 'MAX:%5.0lf %S',
        },
        gprint         => {
            draw      => 'IOreads',
            format    => 'AVERAGE:%5.0lf %S',
        },
        gprint         => {
            draw      => 'IOreads',
            format    => 'LAST:%5.0lf %S\\n',
        },
        draw            => {
            type        => 'line',
            color       => $couleur_IOwrites,
            cdef        => "IOwrites",
            legend      => 'IOwrites',
        },
        comment        => '    ',
        gprint         => {
            draw      => 'IOwrites',
            format    => 'MIN:%5.0lf %S',
        },
        gprint         => {
            draw      => 'IOwrites',
            format    => 'MAX:%5.0lf %S',
        },
        gprint         => {
            draw      => 'IOwrites',
            format    => 'AVERAGE:%5.0lf %S',
        },
        gprint         => {
            draw      => 'IOwrites',
            format    => 'LAST:%5.0lf %S\\n',
        },
    );
}



#  
# 
sub GaugeBind 
{
    my ($nb_rrd_bases,$ref_l,$output,$start,$end,$size,$commentaire) = @_;

    # dereferencement
    my @l = @$ref_l;

    my ($width,$height) = split(/x/,$size);

    my $couleur_success = "00ff00";
    my $couleur_failure = "ffff00";
    my $couleur_nxdomain = "00ffdc";
    my $couleur_recursion = "f600ff";
    my $couleur_referral = "0000ff";
    my $couleur_nxrrset = "ff0000";
    my $couleur_cumul = "cccccc";

    if($commentaire eq "")
    {
        $commentaire = "Statistiques des requêtes DNS";
    }

    my $rrd = RRDTool::OO->new(file => "$ref_l->[0]->[0]->{'base'}");

    $rrd->graph(
	image           => "-",
        title           => "$commentaire",
        vertical_label  => "Requêtes/s",
	lower_limit	=> 0, 
	units_exponent	=> 0,
        height          => $height,
        width           => $width,
        start           => $start,
        end             => $end,
        draw            => {
	    type        => "hidden",
	    dsname      => "success",
	    name        => 'success',
	    cfunc       => 'AVERAGE',
        },
        draw            => {
	    type        => "hidden",
	    dsname      => "failure",
	    name        => 'failure',
	    cfunc       => 'AVERAGE',
        },
        draw            => {
	    type        => "hidden",
	    dsname      => "nxdomain",
	    name        => 'nxdomain',
	    cfunc       => 'AVERAGE',
        },
        draw            => {
	    type        => "hidden",
	    dsname      => "recursion",
	    name        => 'recursion',
	    cfunc       => 'AVERAGE',
        },
        draw            => {
	    type        => "hidden",
	    dsname      => "referral",
	    name        => 'referral',
	    cfunc       => 'AVERAGE',
        },
        draw            => {
	    type        => "hidden",
	    dsname      => "nxrrset",
	    name        => 'nxrrset',
	    cfunc       => 'AVERAGE',
        },
        comment        => '                       min    max  moyen  actuel\n',
	draw           => {
            type        => 'area',
            color       => $couleur_cumul,
            name        => "total",
            cdef        => "success,failure,+,nxdomain,+,recursion,+,referral,+,nxrrset,+",
            legend      => 'total',
        },
        comment        => '         ',
	gprint         => {
            draw      => 'total',
            format    => 'MIN:%5.0lf',
        },
        gprint         => {
            draw      => 'total',
            format    => 'MAX:%5.0lf',
        },
        gprint         => {
            draw      => 'total',
            format    => 'AVERAGE:%5.0lf',
        },
        gprint         => {
            draw      => 'total',
            format    => 'LAST:%5.0lf\\n',
        },
        draw            => {
            type        => 'line',
            color       => $couleur_success,
            cdef        => "success",
	    legend      => 'success',
        },
	comment        => '       ',
	gprint         => {
            draw      => 'success',
            format    => 'MIN:%5.0lf',
        },
	gprint         => {
            draw      => 'success',
            format    => 'MAX:%5.0lf',
        },
        gprint         => {
            draw      => 'success',
            format    => 'AVERAGE:%5.0lf',
        },
        gprint         => {
            draw      => 'success',
            format    => 'LAST:%5.0lf\\n',
        },
	draw            => {
            type        => 'line',
            color       => $couleur_failure,
            cdef        => "failure",
            legend      => 'failure',
        },
        comment        => '       ',
        gprint         => {
            draw      => 'failure',
            format    => 'MIN:%5.0lf',
        },
        gprint         => {
            draw      => 'failure',
            format    => 'MAX:%5.0lf',
        },
        gprint         => {
            draw      => 'failure',
            format    => 'AVERAGE:%5.0lf',
        },
        gprint         => {
            draw      => 'failure',
            format    => 'LAST:%5.0lf\\n',
        },
	draw            => {
            type        => 'line',
            color       => $couleur_nxdomain,
            cdef        => "nxdomain",
            legend      => 'nxdomain',
        },
        comment        => '      ',
        gprint         => {
            draw      => 'nxdomain',
            format    => 'MIN:%5.0lf',
        },
        gprint         => {
            draw      => 'nxdomain',
            format    => 'MAX:%5.0lf',
        },
        gprint         => {
            draw      => 'nxdomain',
            format    => 'AVERAGE:%5.0lf',
        },
        gprint         => {
            draw      => 'nxdomain',
            format    => 'LAST:%5.0lf\\n',
        },
	draw            => {
            type        => 'line',
            color       => $couleur_recursion,
            cdef        => "recursion",
            legend      => 'recursion',
        },
        comment        => '     ',
        gprint         => {
            draw      => 'recursion',
            format    => 'MIN:%5.0lf',
        },
        gprint         => {
            draw      => 'recursion',
            format    => 'MAX:%5.0lf',
        },
        gprint         => {
            draw      => 'recursion',
            format    => 'AVERAGE:%5.0lf',
        },
        gprint         => {
            draw      => 'recursion',
            format    => 'LAST:%5.0lf\\n',
        },
	draw            => {
            type        => 'line',
            color       => $couleur_referral,
            cdef        => "referral",
            legend      => 'referral',
        },
        comment        => '      ',
        gprint         => {
            draw      => 'referral',
            format    => 'MIN:%5.0lf',
        },
        gprint         => {
            draw      => 'referral',
            format    => 'MAX:%5.0lf',
        },
        gprint         => {
            draw      => 'referral',
            format    => 'AVERAGE:%5.0lf',
        },
        gprint         => {
            draw      => 'referral',
            format    => 'LAST:%5.0lf\\n',
        },
	draw            => {
            type        => 'line',
            color       => $couleur_nxrrset,
            cdef        => "nxrrset",
            legend      => 'nxrrset',
        },
        comment        => '       ',
        gprint         => {
            draw      => 'nxrrset',
            format    => 'MIN:%5.0lf',
        },
        gprint         => {
            draw      => 'nxrrset',
            format    => 'MAX:%5.0lf',
        },
        gprint         => {
            draw      => 'nxrrset',
            format    => 'AVERAGE:%5.0lf',
        },
        gprint         => {
            draw      => 'nxrrset',
            format    => 'LAST:%5.0lf\\n',
        },
    );
}


# affichage generique d'une gauge
# 
sub GaugeGeneric
{
    my ($nb_rrd_bases,$ref_l,$output,$start,$end,$size,$commentaire) = @_;

    # dereferencement
    my @l = @$ref_l;

    my ($width,$height) = split(/x/,$size);

    $couleur_current = "0000ff";
    $couleur_max = "ffa1e9";

    if($commentaire eq "")
    {
        $commentaire = "unités";
    }

    my $rrd = RRDTool::OO->new(file => "$ref_l->[0]->[0]->{'base'}");
    
    if(($end - $start) < 800000)
    {
	$rrd->graph(
	image           => "-",
        title           => "$commentaire",
        vertical_label  => "jauge",
	lower_limit	=> 0, 
	units_exponent	=> 0,
        height          => $height,
        width           => $width,
        start           => $start,
        end             => $end,
        draw            => {
	    type        => "hidden",
	    dsname      => "value",
	    name        => 'value',
	    cfunc       => 'AVERAGE',
        },
        comment        => '                  min       max    moyen    actuel\n',
        draw            => {
            type        => 'line',
            color       => $couleur_current,
            cdef        => "value",
	    legend      => $commentaire,
        },
	comment        => '  ',
	gprint         => {
            draw      => 'value',
            format    => 'MIN:%7.0lf',
        },
	gprint         => {
            draw      => 'value',
            format    => 'MAX:%7.0lf',
        },
        gprint         => {
            draw      => 'value',
            format    => 'AVERAGE:%7.0lf',
        },
        gprint         => {
            draw      => 'value',
            format    => 'LAST:%7.0lf\\n',
        },
	);
    }
    else
    {
	$rrd->graph(
        image           => "-",
        title           => "$commentaire",
        vertical_label  => "jauge",
        lower_limit     => 0,
        units_exponent  => 0,
        height          => $height,
        width           => $width,
        start           => $start,
        end             => $end,
        draw            => {
            type        => "hidden",
            dsname      => "value",
            name        => 'value',
            cfunc       => 'AVERAGE',
        },
	draw            => {
            type        => "hidden",
            dsname      => "value",
            name        => 'maxvalue',
            cfunc       => 'MAX',
        },
        comment        => '                                min      max    moyen    actuel\n',
        draw            => {
            type        => 'line',
            color       => $couleur_max,
            cdef        => "maxvalue",
            legend      => "$commentaire (en crête)",
        },
	comment        => '    ',
        gprint         => {
            draw      => 'maxvalue',
            format    => 'MIN:%7.0lf',
        },
        gprint         => {
            draw      => 'maxvalue',
            format    => 'MAX:%7.0lf',
        },
        gprint         => {
            draw      => 'maxvalue',
            format    => 'AVERAGE:%7.0lf',
        },
        gprint         => {
            draw      => 'maxvalue',
            format    => 'LAST:%7.0lf\\n',
        },
	draw            => {
            type        => 'line',
            color       => $couleur_current,
            cdef        => "value",
            legend      => "$commentaire (en moyenne)",
        },
        comment        => '  ',
        gprint         => {
            draw      => 'value',
            format    => 'MIN:%7.0lf',
        },
        gprint         => {
            draw      => 'value',
            format    => 'MAX:%7.0lf',
        },
        gprint         => {
            draw      => 'value',
            format    => 'AVERAGE:%7.0lf',
        },
        gprint         => {
            draw      => 'value',
            format    => 'LAST:%7.0lf\\n',
        },
        );
    }
}


# affichage de la mailqueue d'un relayeur
# 
sub GaugeMailq
{
    my ($nb_rrd_bases,$ref_l,$output,$start,$end,$size,$commentaire) = @_;

    # dereferencement
    my @l = @$ref_l;

    my ($width,$height) = split(/x/,$size);

    $couleur_current = "9cfc15";
    $couleur_max = "ffa1e9";

    if($commentaire eq "")
    {
        $commentaire = "taille de la mailq";
    }

    my $rrd = RRDTool::OO->new(file => "$ref_l->[0]->[0]->{'base'}");
    
    if(($end - $start) < 800000)
    {
	$rrd->graph(
	image           => "-",
        title           => "$commentaire",
        vertical_label  => "nb mails",
	lower_limit	=> 0, 
	units_exponent	=> 0,
        height          => $height,
        width           => $width,
        start           => $start,
        end             => $end,
        draw            => {
	    type        => "hidden",
	    dsname      => "mailq",
	    name        => 'mailq',
	    cfunc       => 'AVERAGE',
        },
        comment        => '                               min     max     moyen    actuel\n',
        draw            => {
            type        => 'area',
            color       => $couleur_current,
            cdef        => "mailq",
	    legend      => $commentaire,
        },
	comment        => '  ',
	gprint         => {
            draw      => 'mailq',
            format    => 'MIN:%7.0lf',
        },
	gprint         => {
            draw      => 'mailq',
            format    => 'MAX:%7.0lf',
        },
        gprint         => {
            draw      => 'mailq',
            format    => 'AVERAGE:%7.0lf',
        },
        gprint         => {
            draw      => 'mailq',
            format    => 'LAST:%7.0lf\\n',
        },
	);
    }
    else
    {
	$rrd->graph(
        image           => "-",
        title           => "$commentaire",
        vertical_label  => "jauge",
        lower_limit     => 0,
        units_exponent  => 0,
        height          => $height,
        width           => $width,
        start           => $start,
        end             => $end,
        draw            => {
            type        => "hidden",
            dsname      => "mailq",
            name        => 'mailq',
            cfunc       => 'AVERAGE',
        },
	draw            => {
            type        => "hidden",
            dsname      => "mailq",
            name        => 'maxmailq',
            cfunc       => 'MAX',
        },
        comment        => '                                            min     max     moyen    actuel\n',
        draw            => {
            type        => 'area',
            color       => $couleur_max,
            cdef        => "maxmailq",
            legend      => "$commentaire (en crête)",
        },
	comment        => '    ',
        gprint         => {
            draw      => 'maxmailq',
            format    => 'MIN:%7.0lf',
        },
        gprint         => {
            draw      => 'maxmailq',
            format    => 'MAX:%7.0lf',
        },
        gprint         => {
            draw      => 'maxmailq',
            format    => 'AVERAGE:%7.0lf',
        },
        gprint         => {
            draw      => 'maxmailq',
            format    => 'LAST:%7.0lf\\n',
        },
	draw            => {
            type        => 'area',
            color       => $couleur_current,
            cdef        => "mailq",
            legend      => "$commentaire (en moyenne)",
        },
        comment        => '  ',
        gprint         => {
            draw      => 'mailq',
            format    => 'MIN:%7.0lf',
        },
        gprint         => {
            draw      => 'mailq',
            format    => 'MAX:%7.0lf',
        },
        gprint         => {
            draw      => 'mailq',
            format    => 'AVERAGE:%7.0lf',
        },
        gprint         => {
            draw      => 'mailq',
            format    => 'LAST:%7.0lf\\n',
        },
        );
    }
}



# affichage de la mémoire utilisée par un process
# 
sub GaugeMemByProc
{
    my ($nb_rrd_bases,$ref_l,$output,$start,$end,$size,$commentaire) = @_;

    # dereferencement
    my @l = @$ref_l;

    my ($width,$height) = split(/x/,$size);

    $couleur_current = "9cfc15";
    $couleur_max = "ffa1e9";

    if($commentaire eq "")
    {
        $commentaire = "place en mémoire";
    }

    my $rrd = RRDTool::OO->new(file => "$ref_l->[0]->[0]->{'base'}");
    
    if(($end - $start) < 800000)
    {
	$rrd->graph(
	image           => "-",
        title           => "$commentaire",
        vertical_label  => "octets",
	lower_limit	=> 0, 
        height          => $height,
        width           => $width,
        start           => $start,
        end             => $end,
        draw            => {
	    type        => "hidden",
	    dsname      => "octets",
	    name        => 'octets',
	    cfunc       => 'AVERAGE',
        },
        comment        => '                             min        max       moyen     actuel\n',
        draw            => {
            type        => 'area',
            color       => $couleur_current,
            cdef        => "octets",
	    legend      => $commentaire,
        },
	comment        => '  ',
	gprint         => {
            draw      => 'octets',
            format    => 'MIN:%7.2lf %S',
        },
	gprint         => {
            draw      => 'octets',
            format    => 'MAX:%7.2lf %S',
        },
        gprint         => {
            draw      => 'octets',
            format    => 'AVERAGE:%7.2lf %S',
        },
        gprint         => {
            draw      => 'octets',
            format    => 'LAST:%7.2lf %S\\n',
        },
	);
    }
    else
    {
	$rrd->graph(
        image           => "-",
        title           => "$commentaire",
        vertical_label  => "jauge",
        lower_limit     => 0,
        height          => $height,
        width           => $width,
        start           => $start,
        end             => $end,
        draw            => {
            type        => "hidden",
            dsname      => "octets",
            name        => 'octets',
            cfunc       => 'AVERAGE',
        },
	draw            => {
            type        => "hidden",
            dsname      => "octets",
            name        => 'maxoctets',
            cfunc       => 'MAX',
        },
        comment        => '                                           min       max       moyen      actuel\n',
        draw            => {
            type        => 'area',
            color       => $couleur_max,
            cdef        => "maxoctets",
            legend      => "$commentaire (en crête)",
        },
	comment        => '    ',
        gprint         => {
            draw      => 'maxoctets',
            format    => 'MIN:%7.2lf %S',
        },
        gprint         => {
            draw      => 'maxoctets',
            format    => 'MAX:%7.2lf %S',
        },
        gprint         => {
            draw      => 'maxoctets',
            format    => 'AVERAGE:%7.2lf %S',
        },
        gprint         => {
            draw      => 'maxoctets',
            format    => 'LAST:%7.2lf %S\\n',
        },
	draw            => {
            type        => 'area',
            color       => $couleur_current,
            cdef        => "octets",
            legend      => "$commentaire (en moyenne)",
        },
        comment        => '  ',
        gprint         => {
            draw      => 'octets',
            format    => 'MIN:%7.2lf %S',
        },
        gprint         => {
            draw      => 'octets',
            format    => 'MAX:%7.2lf %S',
        },
        gprint         => {
            draw      => 'octets',
            format    => 'AVERAGE:%7.2lf %S',
        },
        gprint         => {
            draw      => 'octets',
            format    => 'LAST:%7.2lf %S\\n',
        },
        );
    }
}


###########################################################
# Graph generique pour les compteurs
sub counter_generic
{
    my ($nb_rrd_bases,$ref_l,$output,$start,$end,$size,$commentaire) = @_;

    my ($width,$height) = split(/x/,$size);

    my @couleurs_flux = qw(00dd00 0000ff 0010ff ffbb00 32bc2d ff8800 );
    my @couleurs_max_flux = qw(b8ff4d ffa1e9 ff0000 000000 fb96be 795634);

    my $rrd = RRDTool::OO->new(file => "$ref_l->[0]->[0]->{'base'}");

    my @liste_arg1;

    my $drawline;
    my $drawlinemax;
    # dereferencement
    my @l = @$ref_l;

    # creation d'objets draw de type hidden pour chaque courbe de trafic
    my $tl = @l;
    for(my $i=0;$i<$tl;$i++)
    {
        my $ttl = @{$l[$i]};
        my $plusline="";
        for(my $j=0;$j<$ttl;$j++)
        {
            my $draw;
	    my $drawmax;

            $draw->{'file'} = $l[$i][$j]{'base'};
	    $drawmax->{'file'} = $l[$i][$j]{'base'};
	    
	    system("echo \"i=$i, j=$j, $l[$i][$j]{'base'}\" >> /tmp/genere_graph.out");
            
	    $draw->{'type'} = "hidden";
            $draw->{'dsname'} = "value";
            $draw->{'name'} = "$l[$i][$j]{'graph'}__value";
            $draw->{'cfunc'} = "AVERAGE";
            $draw->{'name'} =~ s/\./__/g;
            $drawmax->{'type'} = "hidden";
            $drawmax->{'dsname'} = "value";
            $drawmax->{'name'} = "$l[$i][$j]{'graph'}__maxvalue";
            $drawmax->{'cfunc'} = "MAX";
            $drawmax->{'name'} =~ s/\./__/g;

	    # pour convertir les valeurs de trafic des lignes en bits
	    $drawline->{$i}->{'cdef'}="$draw->{'name'}$plusline,8,*";
	    $drawlinemax->{$i}->{'cdef'}="$drawmax->{'name'}$plusline,8,*";

            push @liste_arg1,"draw";
            push @liste_arg1,$draw;
	    push @liste_arg1,"draw";
            push @liste_arg1,$drawmax;
        }
    }
    for($i=0;$i<$tl;$i++)
    {
        if($l[$i][0]{'legend'} eq "")
        {
            $l[$i][0]{'legend'} = $l[$i][0]{'graph'};
        }
        $llegend{$i} = split(//,$l[$i][0]{'legend'});
        if($maxlengthlengend < $llegend{$i})
        {
            $maxlengthlengend = $llegend{$i};
        }
    }
    $maxlengthlengend = $maxlengthlengend + 4;

    # ecriture de la legende en entree
    my $spaces = get_spaces(0,$maxlengthlengend,10);
    push @liste_arg1,"comment";
    push @liste_arg1,"$spaces maximum          moyen        actuel\\n";
    my $gprint,$gprintmax;

    # on cree les objets draw pour afficher les lignes
    for($i=0;$i<$tl;$i++)
    {
        # ecriture de la courbe en input
	if($i == 0)
	{
	    $drawline->{$i}->{'type'} = "area";
	}
	else
	{
	    $drawline->{$i}->{'type'} = "line";
	}
        $drawline->{$i}->{'color'} = $couleurs_flux[$i];
        $drawline->{$i}->{'name'} = "value$i";
        # insertion de la legende
        $drawline->{$i}->{'legend'} = "$l[$i][0]{'legend'}";
        push @liste_total,"draw";
        push @liste_total,$drawline->{$i};
        $gprint->{$i}->{0}->{'draw'}=$drawline->{$i}->{'name'};
        $gprint->{$i}->{0}->{'format'}="MAX:%7.2lf %Sb/s";
        $spaces = get_spaces($llegend{$i},$maxlengthlengend,-3);
        push @liste_total,"comment";
        push @liste_total,$spaces;
        push @liste_total,"gprint";
        push @liste_total,$gprint->{$i}->{0};
        $gprint->{$i}->{1}->{'draw'}=$drawline->{$i}->{'name'};
        $gprint->{$i}->{1}->{'format'}="AVERAGE:%7.2lf %Sb/s";
        push @liste_total,"gprint";
        push @liste_total,$gprint->{$i}->{1};
        $gprint->{$i}->{2}->{'draw'}=$drawline->{$i}->{'name'};
        $gprint->{$i}->{2}->{'format'}="LAST:%7.2lf %Sb/s\\n";
        push @liste_total,"gprint";
        push @liste_total,$gprint->{$i}->{2};

	# ecriture des valeurs MAX selon l'intervalle de temps
        if(($end - $start) > 800000)
	{
#	    # ecriture de la courbe en input
	    $drawlinemax->{$i}->{'type'} = "line";
	    $drawlinemax->{$i}->{'color'} = $couleurs_max_flux[$i];
	    $drawlinemax->{$i}->{'name'} = "valuemax$i";
#	    # insertion de la legende
	    $drawlinemax->{$i}->{'legend'} = "$l[$i][0]{'legend'}";
	    push @liste_total,"draw";
	    push @liste_total,$drawlinemax->{$i};
	    $gprintmax->{$i}->{0}->{'draw'}=$drawlinemax->{$i}->{'name'};
	    $gprintmax->{$i}->{0}->{'format'}="MAX:%7.2lf %Sb/s";
	    $spaces = get_spaces($llegend{$i},$maxlengthlengend,-3);
	    push @liste_total,"comment";
	    push @liste_total,$spaces;
	    push @liste_total,"gprint";
	    push @liste_total,$gprintmax->{$i}->{0};
	    $gprintmax->{$i}->{1}->{'draw'}=$drawlinemax->{$i}->{'name'};
	    $gprintmax->{$i}->{1}->{'format'}="AVERAGE:%7.2lf %Sb/s";
	    push @liste_total,"gprint";
	    push @liste_total,$gprintmax->{$i}->{1};
	    $gprintmax->{$i}->{2}->{'draw'}=$drawlinemax->{$i}->{'name'};
	    $gprintmax->{$i}->{2}->{'format'}="LAST:%7.2lf %Sb/s\\n";
	    push @liste_total,"gprint";
	    push @liste_total,$gprintmax->{$i}->{2};
	}
    }
        
    $rrd->graph(
            image           => "-",
            title           => "$commentaire",
            vertical_label  => "trafic",
            height          => $height,
            width           => $width,
            start           => $start,
            end             => $end,
            @liste_arg1,
            @liste_total,
    );
}


return 1;
