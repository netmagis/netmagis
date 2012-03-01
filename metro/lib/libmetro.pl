# $Id: libmetro.pl,v 1.2 2008/06/26 07:13:14 boggia Exp $
###########################################################
#   Creation : 26/03/08 : boggia
#
#Fichier contenant les fonctions génériques des programmes
# de métrologie
###########################################################

use Sys::Syslog;
use Sys::Syslog qw(:DEFAULT setlogsock);  # Also gets setlogsock

###########################################################
# fonction de lecture de fichier de conf
# prend un fichier de conf et une variable recherchee en param
# renvoie la valeur de la variable
# appelee par :
# read_conf_file("nom_fichier_conf","variable_recherchee");
#
sub read_conf_file
{
    my ($file,$var) = @_;

    my $line;

    open(CONFFILE, $file);
    while($line=<CONFFILE>)
    {
        if( $line!~ /^#/ && $line!~ /^\s+/)
        {
            chomp $line;
            my ($variable,$value) = (split(/\s+/,$line))[0,1];
            if($variable eq $var)
            {
                close(CONFFILE);
                return $value;
            }
        }
    }
    close(CONFFILE);

    return "UNDEF";
}

###########################################################
# fonction de lecture de la globalite du fichier de conf
# prend un fichier de conf et stocke la totalité des
# variables du un tableau associatif
sub read_global_conf_file
{
    my ($file) = @_;

    my $line;

    open(CONFFILE, $file);
    while($line=<CONFFILE>)
    {
	if( $line!~ /^#/ && $line!~ /^\s+/)
	{
	    chomp $line;
	    my ($variable,$value) = (split(/\s+/,$line))[0,1];

	    $var{$variable} = $value;
	}
    }
    close(CONFFILE);

    return %var;
}


###########################################################
# function : test the existance of a lock file
sub check_lock_file
{
	my($dir,$file,$process) = @_;

	# test directory
	# if not exists create it
	if (-d $dir)
	{
		if (-e "$dir/$file")
		{
			#lock file exists
			return 1;
		}
		else
		{
			return 0;
		}
	}
	else
	{
		create_directory($dir,$process);

		# no lock file
		return 0;
	}
}


###########################################################
# function : create a lock file
sub create_lock_file
{
	my($dir,$file,$process) = @_;

        # check directory
        # if not exists create it
        if (-d $dir)
        {
		open(LOCK,">$dir/$file");
    		close(LOCK);
        }
        else
        {
		create_directory($dir,$process);
        	open(LOCK,">$dir/$file");
                close(LOCK);
        }
}

###########################################################
# function : delete a lock file
sub delete_lock_file
{
	my($file) = @_;

	unlink $file;
}

###########################################################
# function : create a directory
sub create_directory
{
	my($dir,$process,$facility) = @_;

	my $res = `mkdir -p $dir`;

        writelog("$process","$facility","info",
                "\t INFO : creation du repertoire $dir");
}


###########################################################
# fonction de nettoyage de chaines de caractères
# enlève les espaces à la fin d'une chaine de char
sub clean_var
{
    my ($string) = @_;

    my $s = $string;
    my $test = chop $s;

    if($test eq " ")
    {
	$string = $s;
    }

    return $string;
}


###########################################################
# resolution de nom inverse.
sub gethostnamebyaddr
{
    my ($ip) = @_;

    my $iaddr = inet_aton($ip);
    my $hostname  = gethostbyaddr($iaddr, AF_INET);
    ($hostname)=(split(/\./,$hostname))[0];

    return $hostname;
}


###########################################################
# resolution de nom.
sub getaddrbyhostname
{
    my ($hostname) = @_;

    my $packed_ip = gethostbyname($hostname);
    if (defined $packed_ip)
    {
 	return inet_ntoa($packed_ip);
    }
    else
    {
	return -1;
    }
}


#########################################################
# Convertit une chaine de date de la base SQL
# au format time_t en heure locale
#
sub dateSQL2time
{
    my ($date) = @_ ;

    my $gmt = 0;
    my @ltime ;
    my $t = 0;
    my ($a, $m, $j, $h, $mi, $s) ;

    # Format :
    # 2005-05-18 10:02:53.980149
    # 2007-04-27 12:03:17.980149
    if($date=~ /(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})/)
    {
        $a = $1 - 1900;
        $m = $2 - 1 ;
        $j = $3 ;
        $h = $4 ; $mi= $5 ; $s = $6 ;

        if($a < 70 || !$a)
        {
            $a = 70;
            $m = 0;
        }

        $t=mktime($s,$mi,$h,$j,$m,$a,0,0,0);
    }
    return $t ;
}


###########################################################
#
# Convertit une date en time_t au format SQL
#
sub time2sql {

    my $t = pop(@_) ;

    my @tm = localtime($t) ;

    my $datestring = strftime ("%Y-%m-%d %H:%M:%S", @tm) ;

    return $datestring ;
}

###########################################################
# conversion des débits max en bits/s en X*10eY
# 100000000 -> 1.0000000000+e08
sub convert_nb_to_exp
{
    my ($speed) = @_;

    if($speed=~/[0-9]+/)
    {
        my @chiffres = split(//,$speed);
        my $nb_exp = "$chiffres[0].";
        my $t_chiffres = @chiffres;
        my $i;
        for($i=1;$i<11;$i++)
        {
            if($chiffres[$i])
            {
                $nb_exp = "$nb_exp" . "$chiffres[$i]";
            }
            else
            {
                $nb_exp = "$nb_exp" . "0";
            }
        }
        $t_chiffres --;
        if($t_chiffres < 10)
        {
            $nb_exp = "$nb_exp" . "e+0$t_chiffres";
        }
        else
        {
            $nb_exp = "$nb_exp" . "e+$t_chiffres";
        }
        return $nb_exp;
    }
    else
    {
        return -1;
    }
}


##############################################
# convert SNMP phys addr octet string to
# readable mac address
sub set_Id2Mac
{
    my ($Id) = @_;

    my @hId = split(//,$Id);
    my $t_hId = @hId;
    my $hexa = "";
    my $i;

    for($i=$t_hId - 12;$i<$t_hId;$i = $i+2)
    {
        $hexa = "$hexa" . "$hId[$i]" . "$hId[$i+1]:";
    }

    my ($h1,$h2,$h3,$h4,$h5,$h6) = split(/:/,$hexa);

    my $mac="$h1:$h2:$h3:$h4:$h5:$h6";

    if($mac =~ /[0-9a-fA-F]+:[0-9a-fA-F]+:[0-9a-fA-F]+:[0-9a-fA-F]+:[0-9a-fA-F]+:[0-9a-fA-F]+/)
    {
	return $mac;
    }
    else
    {
	return 0;
    }
}


###########################################################
#
# Renvoie la date decomposee par champs dans un tableau nominatif.
# Prend en parametre l'heure en time_t
# Sinon utilise l'heure d'execution de la fonction
#
sub get_time
{
        my ($time) = @_;

        my %t;

        if($time !~/[0-9]+/)
        {
                $time = time;
        }

        ($t{SEC},$t{MIN},$t{HOUR},$t{MDAY},$t{MON},$t{YEAR},$t{WDAY},$t{YDAY},$t{isDST}) = localtime($time);

        $t{YEAR} += 1900;
        $t{MON} += 1;

	$t{TIME_T} = $time;

        return %t;
}


###########################################################
# donne une limite de débit maximum aux mesures inscrites
# dans une base
sub setBaseMaxSpeed
{
    my ($base,$speed) = @_;

    my $rrdtool = read_conf_file($conf_file,"rrdtool");
    my $maxspeed = convert_nb_to_exp($speed);
    system("$rrdtool tune $base --maximum input:$maxspeed");
    system("$rrdtool tune $base --maximum output:$maxspeed");
}


###########################################################
# retourne la vitesse d'une interface
sub get_snmp_ifspeed
{
    my ($param,$index,$interf,$facility) = @_;

    my $speed;

    # recherche de l'interface dans le tableau des interfaces
    foreach my $key (keys %global_conf)
    {
        if($key=~/^ifspeed_/)
        {
		my $nameif = $key;
		($nameif) = (split(/ifspeed_/,$key))[1];
		if($interf=~/$nameif/)
		{
                	$speed = $var{$key};
		}
        }
    }

    # si le nom de l'interface ne matche pas les interfaces connues
    if($speed eq "")
    {
        if($index eq "")
        {
                # recuperation de l'oid de l'interface
                $index = get_snmp_ifindex($param,$interf);
        }
        &snmpmapOID("speed","1.3.6.1.2.1.31.1.1.1.15.$index");
        my @speed = &snmpget($param, "speed");
        $speed = $speed[0];
    }

    if($speed ne "")
    {
        $speed = $speed*1000000;

        return $speed;
    }
    else
    {
        writelog("metrocreatedb","$facility","info",
            "\t ERREUR : Vitesse de ($param,$interf,index : $index) non definie, force à 100 Mb/s");
        return 100000000;
    }
}


###########################################################
# retourne l'index de l'interface par rapport a un nom
sub get_snmp_ifindex
{
    my ($param,$if) = @_;

    # recuperation de l'oid de l'interface
    &snmpmapOID("desc","1.3.6.1.2.1.2.2.1.2");
    my @desc_inter = &snmpwalk($param, "desc");
    my $nb_desc = @desc_inter;
    my $index_interface;
    my $i;
    for($i=0;$i<$nb_desc;$i++)
    {
        if($desc_inter[$i]=~m/$if/)
        {
            $index_interface = (split(/:/,$desc_inter[$i]))[0];
            $index_interface = (split(/\s/,$index_interface))[0];

            return $index_interface;
        }
    }
    return -1;
}


###########################################################
# creation de la Base RRD pour le trafic sur un port ainsi
# que la disponibilite reseau
sub creeBaseTrafic
{
    	my ($fichier,$speed,$facility,$period)=@_;

        if($period eq "* * * * *")
    	{
                creeBaseTrafic1min($fichier,$speed,$facility);
    	}
        else
        {
		my $rrdtool = read_conf_file($conf_file,"rrdtool");
                if(system("$rrdtool create $fichier DS:input:COUNTER:600:U:U DS:output:COUNTER:600:U:U RRA:AVERAGE:0.5:1:525600 RRA:AVERAGE:0.5:24:43800 RRA:MAX:0.5:24:43800") != 0)
		{
			  writelog("creeBaseTrafic","$facility","info",
                		"\t ERREUR : cannot execute $rrdtool : $!");
		}
		else
		{
        		setBaseMaxSpeed($fichier,$speed);
		}
        }
}

###########################################################
# creation de la Base RRD pour le trafic sur un port avec
# echantillon a 1 minute
sub creeBaseTrafic1min
{
    	my ($fichier,$speed,$facility)=@_;

	my $rrdtool = read_conf_file($conf_file,"rrdtool");

    	if(system("$rrdtool create $fichier -s 60 DS:input:COUNTER:120:U:U DS:output:COUNTER:120:U:U RRA:AVERAGE:0.5:1:525600 RRA:AVERAGE:0.5:24:43800 RRA:MAX:0.5:24:43800") == 0)
	{

	}
	else
	{
    		setBaseMaxSpeed($fichier,$speed);
	}
}


###########################################################
# creation de la Base RRD pour le trafic de broadcast sur
# un port ainsi que la disponibilite reseau
sub creeBaseBroadcast
{
    	my ($fichier,$speed,$period)=@_;

	my $rrdtool = read_conf_file($conf_file,"rrdtool");
        if($period eq "* * * * *")
    	{
        	system("$rrdtool create $fichier -s 60 DS:input:COUNTER:120:U:U DS:output:COUNTER:120:U:U RRA:AVERAGE:0.5:1:525600 RRA:AVERAGE:0.5:24:43800 RRA:MAX:0.5:24:43800");
    	}
    	else
    	{
        	system("$rrdtool create $fichier DS:input:COUNTER:600:U:U DS:output:COUNTER:600:U:U RRA:AVERAGE:0.5:1:210240 RRA:AVERAGE:0.5:24:8760 RRA:MAX:0.5:24:8760");
    	}
        setBaseMaxSpeed($fichier,$speed);
}


###########################################################
# creation d'une base rrd pour un compteur generique
sub creeBaseCounter
{
   	my ($fichier,$speed,$period) = @_;

    	my $rrdtool = read_conf_file($conf_file,"rrdtool");
	if($period eq "* * * * *")
    	{
        	system("$rrdtool create $fichier -s 60 DS:value:COUNTER:120:U:U RRA:AVERAGE:0.5:1:525600 RRA:AVERAGE:0.5:24:43800 RRA:MAX:0.5:24:43800");
    	}
        elsif($period eq "*/15 * * * *")
        {
                system("$rrdtool create $fichier -s 900 DS:value:COUNTER:1800:U:U RRA:AVERAGE:0.5:1:525600 RRA:AVERAGE:0.5:24:43800 RRA:MAX:0.5:24:43800");
        }
    	else
    	{
        	system("$rrdtool create $fichier DS:value:COUNTER:600:U:U RRA:AVERAGE:0.5:1:525600 RRA:AVERAGE:0.5:24:43800 RRA:MAX:0.5:24:43800");
    	}
   	my $maxspeed = convert_nb_to_exp($speed);
    	system("$rrdtool tune $fichier --maximum value:$maxspeed");
}

###########################################################
# creation d'une base RRD de trafic spécifique aux points
# d'acces
sub creeBaseOsirisAP
{
    my ($fichier,$speed)=@_;

    my $rrdtool = read_conf_file($conf_file,"rrdtool");
    system("$rrdtool create $fichier DS:input:COUNTER:600:U:U DS:output:COUNTER:600:U:U RRA:AVERAGE:0.5:1:210240 RRA:AVERAGE:0.5:24:43800 RRA:MAX:0.5:24:43800");
    setBaseMaxSpeed($fichier,$speed);
}

###########################################################
# creation d'une base d'associations aux AP
sub creeBaseApAssoc
{
    my ($fichier)=@_;

    my $rrdtool = read_conf_file($conf_file,"rrdtool");
    system("$rrdtool create $fichier DS:wpa:GAUGE:600:U:U DS:clair:GAUGE:600:U:U RRA:AVERAGE:0.5:1:210240 RRA:AVERAGE:0.5:24:43800 RRA:MAX:0.5:24:43800");
}

###########################################################
# METROi : creation d'une base d'associes ou d'authentifies
# pour un AP WiFi
sub creeBaseAuthassocwifi
{
    my ($fichier,$ssid)=@_;

    my $rrdtool = read_conf_file($conf_file,"rrdtool");
    system("/usr/bin/rrdtool create $fichier DS:$ssid:GAUGE:600:U:U RRA:AVERAGE:0.5:1:210240 RRA:AVERAGE:0.5:24:43800 RRA:MAX:0.5:24:43800");
}

###########################################################
# fonction de creation d'une base RRD pour une collecte des
# donnees en % de la CPU
sub creeBaseCPU
{
    my ($fichier)=@_;

    my $rrdtool = read_conf_file($conf_file,"rrdtool");
    system("$rrdtool create $fichier DS:cpu_system:GAUGE:600:U:U DS:cpu_user:GAUGE:600:U:U RRA:AVERAGE:0.5:1:210240 RRA:AVERAGE:0.5:24:43800 RRA:MAX:0.5:24:43800");
}

###########################################################
# fonction de creation d'une base RRD pour la collecte du
# nombre d'interruptions systeme d'une machine
sub creeBaseInterupt
{
    my ($fichier)=@_;

    my $rrdtool = read_conf_file($conf_file,"rrdtool");
    system("$rrdtool create $fichier DS:interruptions:GAUGE:600:U:U RRA:AVERAGE:0.5:1:210240 RRA:AVERAGE:0.5:24:43800 RRA:MAX:0.5:24:43800");
}

###########################################################
# fonction de creation d'une base RRD pour la collecte du
# load average d'une machine
sub creeBaseLoad
{
    my ($fichier)=@_;

    my $rrdtool = read_conf_file($conf_file,"rrdtool");
    system("$rrdtool create $fichier DS:load_5m:GAUGE:600:U:U DS:load_15m:GAUGE:600:U:U RRA:AVERAGE:0.5:1:210240 RRA:AVERAGE:0.5:24:43800 RRA:MAX:0.5:24:43800");
}

###########################################################
# fonction de creation d'une base RRD pour la collecte de
# l'utilisation de la memoire et du swap
sub creeBaseMemory
{
    my ($fichier)=@_;

    my $rrdtool = read_conf_file($conf_file,"rrdtool");
    system("$rrdtool create $fichier DS:memoire:GAUGE:600:U:U DS:swap:GAUGE:600:U:U RRA:AVERAGE:0.5:1:210240 RRA:AVERAGE:0.5:24:43800 RRA:MAX:0.5:24:43800");
}

###########################################################
# fonction de creation d'une base RRD pour la collecte de
# l'utilisation de la CPU d'un équipement Cisco
sub creeBaseCPUCisco
{
    my ($fichier)=@_;

    my $rrdtool = read_conf_file($conf_file,"rrdtool");
    system("$rrdtool create $fichier DS:cpu_1min:GAUGE:600:U:U DS:cpu_5min:GAUGE:600:U:U RRA:AVERAGE:0.5:1:210240 RRA:AVERAGE:0.5:24:43800 RRA:MAX:0.5:24:43800");
}


###########################################################
# fonction de creation d'une base RRD pour la collecte de
# l'utilisation de la CPU de la routing Engine d'un Juniper M20
sub creeBaseCPUJuniper
{
    my ($fichier)=@_;

    my $rrdtool = read_conf_file($conf_file,"rrdtool");
    system("$rrdtool create $fichier DS:cpu0:GAUGE:600:U:U DS:cpu1:GAUGE:600:U:U RRA:AVERAGE:0.5:1:210240 RRA:AVERAGE:0.5:24:43800 RRA:MAX:0.5:24:43800");
}

###########################################################
# fonction  qui crée une base qui stocke les stats du démon
# bind
sub creeBaseBind_stat
{
     my ($fichier)=@_;

     my $rrdtool = read_conf_file($conf_file,"rrdtool");

     system("$rrdtool create $fichier DS:success:COUNTER:600:U:U DS:failure:COUNTER:600:U:U DS:nxdomain:COUNTER:600:U:U DS:recursion:COUNTER:600:U:U DS:referral:COUNTER:600:U:U DS:nxrrset:COUNTER:600:U:U RRA:AVERAGE:0.5:1:525600 RRA:AVERAGE:0.5:24:43800 RRA:MAX:0.5:24:43800");
     system("/usr/bin/rrdtool tune $fichier --maximum success:3.0000000000e+04");
     system("/usr/bin/rrdtool tune $fichier --maximum failure:3.0000000000e+04");
     system("/usr/bin/rrdtool tune $fichier --maximum nxdomain:3.0000000000e+04");
     system("/usr/bin/rrdtool tune $fichier --maximum recursion:3.0000000000e+04");
     system("/usr/bin/rrdtool tune $fichier --maximum referral:3.0000000000e+04");
     system("/usr/bin/rrdtool tune $fichier --maximum nxrrset:3.0000000000e+04");
}

sub creeBaseTPSDisk
{
     my ($fichier)=@_;

     my $rrdtool = read_conf_file($conf_file,"rrdtool");

     system("$rrdtool create $fichier DS:ioreads:COUNTER:600:U:U DS:iowrites:COUNTER:600:U:U RRA:AVERAGE:0.5:1:210240 RRA:AVERAGE:0.5:24:43800 RRA:MAX:0.5:24:43800");
    system("$rrdtool tune $fichier --maximum ioreads:1.0000000000e+06 iowrites:1.0000000000e+06");
}


sub creeBaseMailq
{
     my ($fichier)=@_;

     my $rrdtool = read_conf_file($conf_file,"rrdtool");
     system("$rrdtool create $fichier DS:mailq:GAUGE:600:U:U RRA:AVERAGE:0.5:1:210240 RRA:AVERAGE:0.5:24:43800 RRA:MAX:0.5:24:43800");
}

sub creeBaseOsirisCE
{
     my ($fichier)=@_;

     my $rrdtool = read_conf_file($conf_file,"rrdtool");
     system("$rrdtool create $fichier  DS:input:COUNTER:600:U:U DS:output:COUNTER:600:U:U DS:erreur:GAUGE:600:U:U DS:ticket:GAUGE:600:U:U RRA:AVERAGE:0.5:1:525600 RRA:AVERAGE:0.5:24:43800 RRA:MAX:0.5:24:43800");
     system("$rrdtool tune $fichier --maximum input:2.0000000000e+09 output:2.0000000000e+09");
}

###########################################################
# fonction de creation d'une base RRD pour la collecte de
# de valeurs en secondes sous forme de jauge
sub creeBaseTpsRepWWW
{
     my ($fichier)=@_;

     my $rrdtool = read_conf_file($conf_file,"rrdtool");
     system("$rrdtool create $fichier DS:time:GAUGE:600:U:U RRA:AVERAGE:0.5:1:210240 RRA:AVERAGE:0.5:24:43800 RRA:MAX:0.5:24:43800");
}

###########################################################
# fonction de creation d'une base RRD pour la collecte de
# de valeurs en secondes sous forme de jauge pour une
# interrogation toutes les minutes
sub creeBaseTpsRepWWWFast
{
    my ($fichier)=@_;

    my $rrdtool = read_conf_file($conf_file,"rrdtool");
    system("$rrdtool create $fichier -s 60 DS:time:GAUGE:120:U:U RRA:AVERAGE:0.5:1:1051200 RRA:AVERAGE:0.5:60:43800 RRA:MAX:0.5:60:43800");
}

###########################################################
# fonction de creation d'une base RRD pour la collecte de
# de valeurs en octets sous forme de jauge
sub creeBaseVolumeOctets
{
    my ($fichier)=@_;

    my $rrdtool = read_conf_file($conf_file,"rrdtool");
    system("$rrdtool create $fichier DS:octets:GAUGE:600:U:U RRA:AVERAGE:0.5:1:210240 RRA:AVERAGE:0.5:24:43800 RRA:MAX:0.5:24:43800");
}

###########################################################
# fonction de creation d'une base RRD pour la collecte de
# de valeurs en octets sous forme de jauge
sub creeBaseNbMbuf
{
    my ($fichier)=@_;

    my $rrdtool = read_conf_file($conf_file,"rrdtool");
    system("$rrdtool create $fichier DS:mbuf:GAUGE:600:U:U RRA:AVERAGE:0.5:1:210240 RRA:AVERAGE:0.5:24:43800 RRA:MAX:0.5:24:43800");
}

###########################################################
# fonction de creation d'une base RRD pour la collecte de
# de valeurs en octets sous forme de jauge
sub creeBaseNbGeneric
{
    	my ($fichier,$period)=@_;

    	my $rrdtool = read_conf_file($conf_file,"rrdtool");

    	if($period eq "* * * * *")
    	{
    		system("$rrdtool create $fichier -s 60 DS:value:GAUGE:120:U:U RRA:AVERAGE:0.5:1:525600 RRA:AVERAGE:0.5:24:43800 RRA:MAX:0.5:24:43800");
    	}
	elsif($period eq "*/15 * * * *")
        {
		system("$rrdtool create $fichier -s 900 DS:value:GAUGE:1800:U:U RRA:AVERAGE:0.5:1:525600 RRA:AVERAGE:0.5:24:43800 RRA:MAX:0.5:24:43800");
	}
    	else
 	{
		system("$rrdtool create $fichier DS:value:GAUGE:600:U:U RRA:AVERAGE:0.5:1:210240 RRA:AVERAGE:0.5:24:43800 RRA:MAX:0.5:24:43800");
	}
}

###########################################################
# fonction de creation d'une base RRD pour la collecte de
# de valeurs en octets sous forme de jauge pour une
# interrogation toutes les minutes
sub creeBaseVolumeOctetsFast
{
    my ($fichier)=@_;

    my $rrdtool = read_conf_file($conf_file,"rrdtool");
    system("$rrdtool create $fichier DS:octets:GAUGE:120:U:U RRA:AVERAGE:0.5:1:210240 RRA:AVERAGE:0.5:24:43800 RRA:MAX:0.5:24:43800");
}

###########################################################
# fonction qui controle la validité'une adresse IP
# et son appartenance au reseau d'access
sub ctrl_ip
{
        my ($ip)=@_;
        my $ip_val = 0;

        if($ip =~/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/)
        {
		if($1<=255 && $2<=255 && $3<=255 && $4<=255)
                {
                        $ip_val = 1;
                }
        }
        else
        {
                return -1;
        }
        return($ip_val);
}

###########################################################
# controle snmp d'un host dans le but de recuperer le
# sysoid
# si ok, renvoie l'oid de l'equipement
# sinon renvoie -1
sub check_host
{
	my ($ip,$snmp_com) = @_;

	my $param = $snmp_com."@".$ip;
        &snmpmapOID("oid","1.3.6.1.2.1.1.2.0");
        my @sys_oid = &snmpget($param,"oid");

	if($sys_oid[0] ne "")
    	{
        	return $sys_oid[0];
    	}
    	else
    	{
        	writelog("check_host",$facility,"info",
            	"\t ERREUR : Echec interrogation SNMP pour sysoid ($param)");

		return -1;
    	}
}

###########################################################
# fonction d'ecriture des messages syslog
sub writelog
{
        my ($program,$facility,$level,$message) = @_;

        if(openlog($program,$facility,""))
        {
            syslog("$facility.$level",$message);
            closelog();
        }
        else
        {
            print "Impossible de logger\n";
        }
}

#############################################################
# lecture et affichage d'un tableau associatif a 2 dimensions
#
sub read_tab_asso
{
        my (%t) = @_;

        foreach my $key (sort keys %t)
        {
                print "$key {\n";
                foreach my $kkey (keys %{$t{$key}})
                {
                        print "\t$kkey -> $t{$key}{$kkey}\n";
                }
                print "}\n";
        }
}

#############################################################
# Connect to database
sub db_connect
{
        my ($dbname, $dbhost, $dbuser, $dbpassword) = @_;

	my $db =  DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost",
		$dbuser, $dbpassword);
	if (! $db) {
		print STDERR "Cannot connect to '$dbname': ". $DBI::errstr;
	}

	return $db ;
}

#############################################################
# Execute a SQL command, log the error
# return 0 if error, 1 otherwise
# Parameters:
#	db		: handle of an opened database
#	sql		: sql command
sub db_exec
{
	my ($db,$sql) = @_;

	my $r = 0;

	if($db->do($sql)) {
		$r = 1;
	} else {
		print STDERR "ERROR: (db_exec) failed in query '$sql': ".  $DBI::errstr;
		writelog($current_process_name, $current_log_facility, "err",
				"\t ERROR: (db_exec) failed in query '$sql': ".
				$DBI::errstr);
	}

	return $r;
}

#############################################################
# Set the current log facility
sub set_log_facility
{
	my $facility = shift;

	our $current_log_facility = $facility;
}
#############################################################
# Set the current process name
sub set_process_name
{
	my $name = shift;

	our $current_process_name = $name;
}


#############################################################
# List a directory
# return a list of file names matching a pattern or
# an empty list if the directory cannot be read
# Each file contains a full path
sub lsfiles
{
        my ($dir, $pattern) = @_;

        my @l = () ;
        my $d = $dir;

        # remove final slash
        $d =~ s,/$,,;
        if(opendir(DIR, $dir)) {
                @l = map {$d . "/" . $_} grep (/$pattern/, readdir(DIR));
                closedir(DIR);
        } else {
		writelog($current_process_name,$current_log_facility,"err",
			"\t ERROR : (lsfiles) cannot list directory $dir");
	}

        return @l;
}

#############################################################
# Load sessions from file
#
# Parameters : file name
#
# Each file has the following format :
#	timestamp;field1;field2;...
# Example for ipmac
#	1323794702;130.79.73.127;00:e0:4c:39:0b:1e
# Store each line into a hash where :
# 	- the key is the concatenation of all the fields
#		except timestamp, separated with ";"
#	- the value is the timestamp
# Example :
#	  $hash{"130.79.73.127;00:e0:4c:39:0b:1e"} = "2010-12-31 14:21:00"
#
# Return a hash reference
#
sub load_sessions
{
    my @files = @_;

    my $r = undef;
    my %sessions ;
    foreach my $f (@files) {
	if(open(F,$f)) {
	    while(<F>) {
		# Format : 1323794702;130.79.73.127;00:e0:4c:39:0b:1e
		my ($t,$data) = (/^(\d+);(.*)/);
		# Convert time_t to SQL timestamp
		$sessions{$data} = strftime("%Y-%m-%d %H:%M:%S", localtime($t));
	    }
	    close(F);
	} else {
	    writelog($current_process_name,$current_log_facility,"err",
			"\t ERROR: (load_session) cannot open '$f' ($!)");
	}
    }

    # If sessions not empty
    if(%sessions) {
	$r = \%sessions;
    }

    return $r;
}

################################################################
# Extract IP address of the polled source from a report filename
#
# The filename has the following format (where 1.2.3.4 is the ip address
# of the source) :
# 	/path/to/the/report/dir/probetype_1.2.3.4
#
# In some case the filename can have extra elements after the address :
# 	/path/to/the/report/dir/probetype_1.2.3.4_otherthings
#
sub guess_src_name
{
	my $filename = shift;

	my ($type,$address,$other) = split(/_/,$filename);
	if($address =~ m/([0-9.]+|[0-9a-f:]+)/) {
		return $address ;
	} else {
		return "";
	}
}

#############################################################
# Update all sessions in database
# Parameters:
#	db		: handle of an opened database
#	table		: table name
#	src		: source of the polled session
#	polled_sessions : hash of session polled
#
sub update_sessions
{
	my ($db,$table,$src,$polled_sessions) = @_;

	#db_exec($db,"START TRANSACTION");

	# Create a temporary table
	(my $underscored_src = $src) =~ s/[:.]/_/g;
	my $polled = sprintf('%s_%s', $table, $underscored_src );
	db_exec($db,"CREATE TABLE $polled (LIKE $table)");
# DEBUG START
my $macdbpassword=read_conf_file("%CONFFILE%","macdbpassword");
my $macdbhost=read_conf_file("%CONFFILE%","macdbhost");
my $macdbport=read_conf_file("%CONFFILE%","macdbport");
my $macdbname=read_conf_file("%CONFFILE%","macdbname");
my $macdbuser=read_conf_file("%CONFFILE%","macdbuser");
my $PSQL="PGPASSWORD=$macdbpassword psql -h $macdbhost -d $macdbname -U $macdbuser";

my $date;
chomp($date=`date`);
open(D,">>/tmp/DBG"); print D $date . " Created table $polled\n"; close(D);
# DEBUG END

	# Load polled session data into temporary table
	my $copyfields = "start,stop,src,closed,data";

	db_exec($db,"COPY $polled ($copyfields) FROM STDIN");
	foreach my $k (keys %{$polled_sessions}) {
		my $time = $polled_sessions->{$k};

		# Each key contains the data values separated by ';'
		$k =~ s{;}{,}g;
		# Since data is a composite type, it must be between parentheses
		# and separated by ','
		$db->pg_putcopydata("$time\t$time\t$src\tFALSE\t($k)\n");
# DEBUG START
open(D,">>/tmp/DBG");
chomp($date=`date`);
print D $date . " Inserting into table $polled: $time\t$time\t$src\tFALSE\t($k)\n";
close(D);
# DEBUG END

	}
	$db->pg_putcopyend();

# DEBUG START
open(D,">>/tmp/DBG");
chomp($date=`date`);
print D $date . " Will update the stop field in table $table for the following lines:\n";
close(D);
# DEBUG END

# DEBUG START
system("$PSQL -c \"SELECT * FROM $table, $polled WHERE $table.closed=FALSE AND $table.src='$src' AND $polled.data=$table.data\" >>/tmp/DBG");
# DEBUG END

	# Update open sessions matching all the polled session
	db_exec($db,"UPDATE $table SET stop=$polled.stop FROM $polled
			WHERE $table.closed=FALSE AND
				$table.src='$src' AND
				$polled.data=$table.data"
		);

# DEBUG START
open(D,">>/tmp/DBG");
chomp($date=`date`);
print D $date . " Will create new sessions in table $table with the following lines:\n";
close(D);
system("$PSQL -c \"SELECT start,stop,src,FALSE,data FROM $polled WHERE $polled.data NOT IN (	SELECT data FROM $table WHERE closed=FALSE AND src='$src')\" >>/tmp/DBG");
# DEBUG END

	# Create new sessions :
	# (for a given source)
	# - compare polled sessions <> previously open sessions
	# - create only sessions which are not in previously open sessions
	db_exec($db,"INSERT INTO $table (start,stop,src,closed,data)
			SELECT start,stop,src,FALSE,data FROM $polled
			WHERE $polled.data NOT IN (	SELECT data FROM $table
							WHERE closed=FALSE AND
								src='$src'
						)"
		);

# DEBUG START
open(D,">>/tmp/DBG");
chomp($date=`date`);
print D $date . " Will close these sessions in table $table :\n";
close(D);
system("$PSQL -c \"SELECT * FROM $table WHERE closed=FALSE AND src='$src' AND data NOT IN (SELECT data FROM $polled)\" >>/tmp/DBG");
# DEBUG END

	# Close old sessions :
	# close open sessions that do not appear in polled source
	db_exec($db,"UPDATE $table SET closed=TRUE
			WHERE closed=FALSE AND src='$src' AND
				data NOT IN (SELECT data FROM $polled)"
		);

	# Destroy temporary table
	db_exec($db,"DROP TABLE $polled");

	# Commit changes
	#db_exec($db,"COMMIT");
}

#############################################################
# Process all session files
# Parameters:
#	db		: handle of an opened database
#	table		: table name
#	dir		: report directory
#	sensortype      : filename pattern of the report files
#
sub process_sessions {
    my ($db, $table, $dir, $sensortype) = @_;

    my $lockdir = $global_conf{"metrodatadir"} . "/lock";

    my $process = "plugin-$sensortype";
    if(check_lock_file($lockdir,"$process.lock", $process)!= 0) {
	writelog($current_process_name,$current_log_facility,"err",
			"\t ERROR: (process_session) already running");
	return -1;
    }

    create_lock_file($lockdir, "$process.lock", $process);

    # Load data files
    my $pattern = sprintf("^%s_.*", $sensortype);
    my @filelist = lsfiles($dir, $pattern) ;

    # Get all unique source names that produced a report
    my %srclist ;
    foreach my $f (@filelist) {
        my $src = guess_src_name($f);
	if ($src ne "") {
	    $srclist{$src} = 1;
	}
    }

    # Update sessions for each source
    foreach my $src (keys %srclist) {

# DEBUG START
open(D,">>/tmp/DBG");
chomp($date=`date`);
print D $date . " plugin-$sensortype ($$) processing data for $src\n";
close(D);
# DEBUG END

	# Read all files for this source
	# The filename format is described in guess_src_name
	my $pattern = sprintf('^%s_(%s|%s_.*)$',$sensortype, $src, $src);
	my @files = lsfiles ($dir, $pattern);
# DEBUG START
open(D,">>/tmp/DBG");
chomp($date=`date`);
print D $date . " plugin-$sensortype ($$) files for $src:" . join(',',@files)."\n" ;
close(D);
# DEBUG END
	my $polled_sessions = load_sessions(@files);

	my $suppress = 0;

	if(! $polled_sessions) {
	    # No session means the file is empty -> remove it later
	    $suppress = 1;
	} else {
	    if(update_sessions($db,$table,$src,$polled_sessions)) {
		$suppress = 1;
	    }
	}
	if($suppress) {
# DEBUG START
# move files instead of delete
	    my $bkp = "$dir/report.$src/" . `date +%Y%m%d.%H%M%S` ;
	    system("mkdir -p $bkp");
	    chdir($dir);
	    system("mv " . join(" ",@files) . " $bkp");

#	    foreach my $f (@files) {
#		unlink($f);
#	    }

# DEBUG END

	}
    }

    delete_lock_file("$lockdir/$process.lock");
}

return 1;
