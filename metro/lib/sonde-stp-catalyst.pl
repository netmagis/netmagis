# $Id: sonde-stp-catalyst.pl,v 1.1.1.1 2008-06-13 08:55:51 pda Exp $
#
#
# ###################################################################
# boggia : Creation : 27/03/08
#
# fonctions qui permettent de récupérer en SNMP l'etat du spanning 
# tree sur les commutateurs Cisco
#
# Resultats possibles de requetes : 
#   1 - disabled
#   2 - blocking
#   3 - listening
#   4 - learning
#   5 - forwarding
#   6 - broken

sub get_stp_catalyst
{
    my ($base,$host,$community,$l_param) = @_; 
   
    my @fichier = ();
    # teste si l'equipement est toujours en cours d'interrogation
    #print "($host,$community,$l_param)\n";
    opendir(REPLOCK,$config{'dir_lock'});
    @fichier = grep(/$host/,readdir REPLOCK);
    closedir(REPLOCK);

    # si pas de lock
    if(! $fichier[0])
    {
	open(LOCK,">$config{'dir_lock'}/$host.lock");
        close(LOCK);

	my $dir_result = "$config{'dir_res_stp'}";
        open(FICH,">$dir_result/$host");
	close(FICH);

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
	    #writelog("get_stp_catalyst",$config{'logopt'},"info",
            #     "\t -> ERROR: SNMP connect error: $error");
	}
	else
	{
	    my $bridgeOid = "1.3.6.1.2.1.17.1.1.0";
	    my $r = $snmp->get_request(
                -varbindlist   => [$bridgeOid],
                -callback   => [ \&get_snmp_bridge_id,$host,$community,$l_param,$bridgeOid] );
	}
	
	unlink "$config{'dir_lock'}/$host.lock";	
    }
    else
    {
	#writelog("get_stp_catalyst",$config{'logopt'},"info",
        #         "\t -> WARNING : $host toujours en cours d'interrogation");
    }
}


sub get_snmp_bridge_id
{
    my ($session,$host,$communaute,$liste_vlans,$bridgeOid) = @_;

    if (!defined($session->var_bind_list))
    #l'equipement ne repond pas
    {
        my $error  = $session->error;
        #writelog("get_stp_catalyst",$config{'logopt'},"info",
        #         "\t -> ERROR: get_stp_catalyst($host) Error: $error");
        #print "ERROR: get_stp_catalyst($host) Error: $error\n";
    }
    else
    # l'equipement repond
    {
        # repertoire dans lequel seront stockes les resultats
        my $elem;

        my $bridgeId = $session->var_bind_list->{$bridgeOid};

        $bridgeId = set_Id2Mac($bridgeId);

	$BridgeID{$bridgeId} = $host;
        #print "\nget_snmp_bridge_id($host,$communaute) bridgeId = $bridgeId";

        my @vlans = split(/:/,$liste_vlans);

        foreach $elem (@vlans)
        {
            if($elem=~/[0-9]+/)
            {
                #print "vlan $elem :\n";

                my $community = "$communaute\@$elem";

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
                    #writelog("get_assoc_ap",$config{'logopt'},"info",
                    #    "\t -> ERROR: SNMP connect error: $error");
                    #print "ERROR: SNMP connect error: $error\n";
                }
                else
                {
                    #recuperation de la racine du spanning Tree
		    my $rootBridgeOid = "1.3.6.1.2.1.17.2.5.0";
		    my $r = $snmp->get_request(
			-varbindlist   => [$rootBridgeOid],
			-callback   => [ \&get_snmp_rootBridge,$host,$community,$elem,$rootBridgeOid,$bridgeId] );
                }
            }
        }
    }
}


sub get_snmp_rootBridge
{
    my ($session,$host,$community,$vlan,$rootBridgeOid,$bridgeId) = @_;

    if (!defined($session->var_bind_list))
    #l'equipement ne repond pas
    {
        my $error  = $session->error;
        #writelog("get_stp_catalyst",$config{'logopt'},"info",
        #         "\t -> ERROR: get_stp_catalyst($host) Error: $error");
        #print "ERROR: get_stp_catalyst($host) Error: $error\n";
    }
    else
    # l'equipement repond
    {
        # repertoire dans lequel seront stockes les resultats
        my $rootBridgeId = $session->var_bind_list->{$rootBridgeOid};

        $rootBridgeId = set_Id2Mac($rootBridgeId);

	#print "\nget_snmp_rootBridge($host,$community,$vlan,$rootBridgeOid) rootBridgeId = $rootBridgeId";
        #print "\nget_stp_catalyst($host) $bridgeId = $bridgeId";

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
	    #writelog("get_assoc_ap",$config{'logopt'},"info",
	    #    "\t -> ERROR: SNMP connect error: $error");
            ##print "ERROR: SNMP connect error: $error\n";
        }
        else
        {
            #recuperation du Root Port
            my $rootPortOid = "1.3.6.1.2.1.17.2.7.0";
            my $r = $snmp->get_request(
		-varbindlist   => [$rootPortOid],
                -callback   => [ \&get_snmp_rootPort,$host,$community,$vlan,$rootPortOid,$bridgeId,$rootBridgeId] );
        }
    }
}


sub get_snmp_rootPort
{
    my ($session,$host,$community,$vlan,$rootPortOid,$bridgeId,$rootBridgeId) = @_;

    if (!defined($session->var_bind_list))
    #l'equipement ne repond pas
    {
        my $error  = $session->error;
        #writelog("get_stp_catalyst",$config{'logopt'},"info",
        #         "\t -> ERROR: get_stp_catalyst($host) Error: $error");
	#print "ERROR: get_stp_catalyst($host) Error: $error\n";
    }
    else
    # l'equipement repond
    {
	my $rootPort = $session->var_bind_list->{$rootPortOid};
        #print "\nget_stp_catalyst($host) $bridgeId = $bridgeId";

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
	    #writelog("get_assoc_ap",$config{'logopt'},"info",
                   #    "\t -> ERROR: SNMP connect error: $error");
	    #print "ERROR: SNMP connect error: $error\n";
	}
	else
	{
	    my $state_oid = '1.3.6.1.2.1.17.2.15.1.3';
	    my $res = $snmp->get_table(
		$state_oid,
		-callback   => [ \&get_snmp_port_state,$host,$community,$vlan,$state_oid,$bridgeId,$rootBridgeId,$rootPort] );
	}
    }
}


# convertion de la reponse SNMP en adresse Mac
sub set_Id2Mac
{
    my ($Id) = @_;
    
    my @bridgeId = split(//,$Id);
    my $t_bridgeId = @bridgeId;
    $hexa = "";
    for($i=$t_bridgeId - 12;$i<$t_bridgeId;$i = $i+2)
    {
	$hexa = "$hexa" . "$bridgeId[$i]" . "$bridgeId[$i+1]:";
    }
    my ($h1,$h2,$h3,$h4,$h5,$h6) = split(/:/,$hexa);
    my $mac="$h1:$h2:$h3:$h4:$h5:$h6";

    return $mac;
}


sub get_snmp_port_state
{
    my ($session,$host,$community,$vlan,$state_oid,$bridgeId,$rootBridgeId,$rootPort) = @_;
		    
    if(defined($session->var_bind_list()))
    {
	# Extract the response.
        my $key = '';
        my $hashref = $session->var_bind_list();
	my $compteur = 0;

	my $dir_result = "$config{'dir_res_stp'}";
	open(FICH,">>$dir_result/$host");
	
	print FICH "\nVlan$vlan bridgeId=$bridgeId\n";
	print FICH "Vlan$vlan rootBridgeId=$rootBridgeId ($BridgeID{$rootBridgeId})\n";

	$stpInfos{"$host:$vlan:bridgeId"} = $bridgeId;
	$stpInfos{"$host:$vlan:rootBridgeId"} = $rootBridgeId;

	my $param = $community."@".$host;
	    
        foreach $key (keys %$hashref)
        {
	    my $nom_interf;
    
	    $compteur ++;
	    chomp($key);

	    my @decomp_oid = split(/\./,$key);
	    my $index_stp_if = pop(@decomp_oid);
	    my $etat = $$hashref{$key};

	    my $indexif = "1.3.6.1.2.1.17.1.4.1.2.$index_stp_if";

	    &snmpmapOID("indexif","1.3.6.1.2.1.17.1.4.1.2.$index_stp_if");
            my @desc_inter = &snmpget($param, "indexif");

            &snmpmapOID("index","1.3.6.1.2.1.2.2.1.2.$desc_inter[0]");
            my @nom_inter = &snmpget($param, "index");

	    print FICH "Vlan$vlan $nom_inter[0]";
	    
	    my $nom_etat;
	    if($etat == 1)
	    {
		print FICH "\tdisabled";
		$nom_etat = "disabled";
	    }
	    elsif($etat == 2)
	    {
		print FICH "\tblocking";
		$nom_etat = "blocking";
	    }
	    elsif($etat == 3)
	    {
		print FICH "\tlistening";
		$nom_etat = "listening";
	    }
	    elsif($etat == 4)
	    {
		print FICH "\tlearning";
		$nom_etat = "learning";
	    }
	    elsif($etat == 5)
	    {
		print FICH "\tforwarding";
		$nom_etat = "forwarding";
	    }
	    elsif($etat == 6)
	    {
		print FICH "\tbroken";
		$nom_etat = "broken";
	    }
	    if($index_stp_if == $rootPort)
	    {
		print FICH "\t-> root\n";
		$stpInfos{"$host:$vlan:rootPort"} = $nom_inter[0];
	    }
	    else
	    {
		print FICH "\n";
	    }
	    $stpPorts{"$host:$vlan:$nom_inter[0]"} = $nom_etat;
	}
	close (FICH);
	
	if($compteur == 0)
	{
	    #print "WARNING : $host, $vlan : aucun port actif dans l'instance de STP\n";
	}
    }
    else
    {
	#print "ERROR: get_stp_catalyst($host,$community) : etat des ports du STP, pas de reponse\n";
    }
}



sub compare_stp_state
{
    my ($key,$key2);
    open(FICH,">$config{'dir_res_stp'}/stp.output.tmp");

    foreach $key (keys %stpInfos)
    {
	if($key=~/(.*):(.*):bridgeId/)
	{
	    print FICH "\n";
	    print FICH "$1:$2:bridgeId = $stpInfos{\"$1:$2:bridgeId\"}\n";
	    print FICH "$1:$2:rootBridgeId = $stpInfos{\"$1:$2:rootBridgeId\"}($BridgeID{$stpInfos{\"$1:$2:rootBridgeId\"}})\n";
	    if(defined($stpInfos{"$1:$2:rootPort"}))
	    {
		print FICH "$1:$2:rootPort = $stpInfos{\"$1:$2:rootPort\"}\n";
	    }
	    else
	    {
		print FICH "$1:$2:bridgeId = AUCUN\n";
	    }

	    my $host = $1;
	    my $vlan = $2;
	    foreach $key2 (keys %stpPorts)
	    {
		if($key2=~/$host:$vlan:(.*)/)
		{
		    print FICH "$host:$vlan:$1 = $stpPorts{\"$host:$vlan:$1\"}\n";
		}
	    }
	}
    }
    close(FICH);

    system("sort -t: +1n +0d $config{'dir_res_stp'}/stp.output > $config{'dir_res_stp'}/stp.output.sorted");
    system("sort -t: +1n +0d $config{'dir_res_stp'}/stp.output.tmp > $config{'dir_res_stp'}/stp.output.tmp.sorted");
    
    my $message = "Alertes Spanning Tree\n\n";
    my $res = `diff -u $config{'dir_res_stp'}/stp.output.sorted $config{'dir_res_stp'}/stp.output.tmp.sorted`;
  
    if($res ne "")
    { 
	$message = "$message $res"; 
	#print "$message";
	#system("echo \"$message\" | mail -s \"[AUTO] Spanning Tree Topo changes\" seb\@crc.u-strasbg.fr");
	system("mv $config{'dir_res_stp'}/stp.output.tmp $config{'dir_res_stp'}/stp.output");
    }
}


return 1;



