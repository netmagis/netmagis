######
# fonctions
######

sub get_portmac_cisco
{
	my ($base,$host,$community,$params) = @_;

	my %table_forwarding;
	# reference 
	my $p_table_forwarding = \%table_forwarding;	

	my($iflist,$vlan) = split(/:/,$params);

        $community = "$community" . "@" . "$vlan";

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
                writelog("portmac.cisco",$config{syslog_facility},"info",
                        "\t -> ERROR: SNMP connect error: $error");
        }
        else
        {
                my $Oid = "1.3.6.1.2.1.17.4.3.1.2";
                my $res = $snmp->get_table(
                        $Oid,
                        -callback   => [ \&get_qbridge_cisco,$snmp,$host,$community,$vlan,$iflist,$p_table_forwarding] );
        }
}


sub get_portmac_juniper
{
        my ($base,$host,$community,$params) = @_;

	my %table_forwarding;
        # reference 
        my $p_table_forwarding = \%table_forwarding;

	my($iflist,$vlanlist) = split(/:/,$params);

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
		writelog("portmac.juniper",$config{syslog_facility},"info",
                        "\t -> ERROR: SNMP connect error: $error");
        }
        else
        {
                my $Oid = "1.3.6.1.4.1.2636.3.40.1.5.1.5.1.5";
                my $res = $snmp->get_table(
                        $Oid,
                        -callback   => [ \&get_qbridge,$snmp,$host,$community,$vlanlist,$iflist,$p_table_forwarding] );
        }
}


sub get_portmac_hp
{
        my ($base,$host,$community,$params) = @_;

	my %table_forwarding;
        # reference 
        my $p_table_forwarding = \%table_forwarding;

	my($iflist,$vlanlist) = split(/:/,$params);

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
		writelog("portmac.juniper",$config{syslog_facility},"info",
                        "\t -> ERROR: SNMP connect error: $error");
        }
        else
        {
                my $Oid = "1.3.6.1.2.1.17.7.1.4.2.1.3.0";
                my $res = $snmp->get_table(
                        $Oid,
                        -callback   => [ \&get_qbridge,$snmp,$host,$community,$vlanlist,$iflist,$p_table_forwarding] );
        }
}



# get bridge index / mac address
sub get_qbridge_cisco
{
    my ($session,$snmp,$host,$community,$vlan,$iflist,$table_forwarding) = @_;

    if(defined($session->var_bind_list()))
    {
        # Extract the response.
        my $key = '';
        my $hashref = $session->var_bind_list();
        my $compteur = 0;

        foreach $key (keys %{$hashref})
        {
            chomp($key);

            if($key =~/([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/)
            {
                my $a = sprintf("%.2x", $1);
                my $b = sprintf("%.2x", $2);
                my $c = sprintf("%.2x", $3);
                my $d = sprintf("%.2x", $4);
                my $e = sprintf("%.2x", $5);
                my $f = sprintf("%.2x", $6);

                $table_forwarding->{$host}{$vlan}{"$a:$b:$c:$d:$e:$f"} = $hashref->{$key};
                $compteur ++;
            }
        }
        if (defined($snmp))
        {
                my $Oid = "1.3.6.1.2.1.17.1.4.1.2";
                my $res = $snmp->get_table(
                        $Oid,
                        -callback   => [ \&get_snmp_cisco_bridge_iface_index,$snmp,$host,$community,$vlan,$iflist,$table_forwarding] );
        }
     }
}



sub get_snmp_cisco_bridge_iface_index
{
    my ($session,$snmp,$host,$community,$vlan,$iflist,$table_forwarding) = @_;

    if(defined($session->var_bind_list()))
    {
        # Extract the response.
        my $key = '';
        my $hashref = $session->var_bind_list();

        foreach $key (keys %{$hashref})
        {
            chomp($key);

            $key =~ /([0-9]+)$/;

            foreach my $mac (keys %{$table_forwarding->{$host}{$vlan}})
            {
                if($table_forwarding->{$host}{$vlan}{$mac} eq "$1")
                {
                        $table_forwarding->{$host}{$vlan}{$mac} = $hashref->{$key};
                }
            }
        }

        if (defined($snmp))
        {
                my $Oid = "1.3.6.1.2.1.2.2.1.2";
                my $res = $snmp->get_table(
                        $Oid,
                        -callback   => [ \&get_snmp_index2ifacedesc_cisco,$snmp,$host,$community,$vlan,$iflist,$table_forwarding] );
        }
     }
}



sub get_snmp_index2ifacedesc_cisco
{
    my ($session,$snmp,$host,$community,$vlan,$iflist,$table_forwarding) = @_;

    if(defined($session->var_bind_list()))
    {
        # Extract the response.
        my $key = '';
        my $hashref = $session->var_bind_list();

        foreach $key (keys %{$hashref})
        {
            chomp($key);

            $key =~ /([0-9]+)$/;

            foreach my $mac (keys %{$table_forwarding->{$host}{$vlan}})
            {
                if($table_forwarding->{$host}{$vlan}{$mac} eq "$1")
                {
                        if(exists_in_iface_list($hashref->{$key},$iflist) == 1)
                        {
                                $table_forwarding->{$host}{$vlan}{$mac} = $hashref->{$key};
                        }
                        else
                        {
                                delete $table_forwarding->{$host}{$vlan}{$mac};
                        }
                }
            }
        }

	print_portmac_report($host,$table_forwarding);
     }
}



sub get_snmp_index2ifacedesc
{
    my ($session,$snmp,$host,$community,$vlanlist,$iflist,$table_forwarding) = @_;

    if(defined($session->var_bind_list()))
    {
        # Extract the response.
        my $key = '';
        my $hashref = $session->var_bind_list();

        foreach $key (keys %{$hashref})
        {
            chomp($key);

            $key =~ /([0-9]+)$/;

            foreach my $br_id (keys %{$table_forwarding->{$host}})
            {
                foreach my $mac (keys %{$table_forwarding->{$host}{$br_id}})
                {
                        if($table_forwarding->{$host}{$br_id}{$mac} eq "$1")
                        {
                                if(exists_in_iface_list($hashref->{$key},$iflist) == 1)
                                {
                                        $table_forwarding->{$host}{$br_id}{$mac} = $hashref->{$key};
                                }
                                else
                                {
                                        delete $table_forwarding->{$host}{$br_id}{$mac};
                                }
                        }
                }
            }
        }
		
	print_portmac_report($host,$table_forwarding);
     }
}



sub get_qbridge
{
        my ($session,$snmp,$host,$community,$vlanlist,$iflist) = @_;

        if(defined($session->var_bind_list()))
        {
                # Extract the response.
                my $key = '';
                my $hashref = $session->var_bind_list();

                foreach $key (keys %$hashref)
                {
                        chomp($key);

                        $key =~ /([0-9]+)$/;

                        $vlan2qbridge{vlan}{$$hashref{$key}} = $1;
                        $vlan2qbridge{br}{$1} = $$hashref{$key};
                }

                if (defined($snmp))
                {
                        my $Oid = "1.3.6.1.2.1.17.7.1.2.2.1.2";

                        # if only one vlan as parameters, modify the oid for the associated bridgeId
                        if(get_nb_vlan_in_list($vlanlist) == 1 && exists $vlan2qbridge{br}{$vlanlist})
                        {
                                $Oid = "$Oid.$vlan2qbridge{br}{$vlanlist}";
                        }

                        my $res = $snmp->get_table(
                        $Oid,
                        -callback   => [ \&get_snmp_qbridge,$snmp,$host,$community,$vlanlist,$iflist] );
                }
        }
}


sub get_snmp_qbridge
{
    my ($session,$snmp,$host,$community,$vlanlist,$iflist) = @_;

    if(defined($session->var_bind_list()))
    {
        # Extract the response.
        my $key = '';
        my $hashref = $session->var_bind_list();
        my $compteur = 0;

        foreach $key (keys %$hashref)
        {
            chomp($key);

            if($key =~/([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/)
            {
                my $br_id = $1;
                my $a = sprintf("%.2x", $2);
                my $b = sprintf("%.2x", $3);
                my $c = sprintf("%.2x", $4);
                my $d = sprintf("%.2x", $5);
                my $e = sprintf("%.2x", $6);
                my $f = sprintf("%.2x", $7);

                if("$a:$b:$c:$d:$e:$f" ne "00:00:00:00:00:00")
                {
                        $table_forwarding{$host}{$vlan2qbridge{vlan}{$br_id}}{"$a:$b:$c:$d:$e:$f"} = "$$hashref{$key}";
                        $compteur ++;
                }
            }
        }
        if (defined($snmp))
        {
                my $Oid = "1.3.6.1.2.1.17.1.4.1.2";
                my $res = $snmp->get_table(
                        $Oid,
                        -callback   => [ \&get_snmp_bridge_iface_index,$snmp,$host,$community,$vlanlist,$iflist] );
        }
     }
}


sub get_snmp_bridge_iface_index
{
    my ($session,$snmp,$host,$community,$vlanlist,$iflist) = @_;

    if(defined($session->var_bind_list()))
    {
        # Extract the response.
        my $key = '';
        my $hashref = $session->var_bind_list();

        foreach $key (keys %$hashref)
        {
            chomp($key);

            $key =~ /([0-9]+)$/;

            foreach my $br_id (keys %{$table_forwarding{$host}})
            {
                foreach my $mac (keys %{$table_forwarding{$host}{$br_id}})
                {
                        if($table_forwarding{$host}{$br_id}{$mac} eq "$1")
                        {
                                $table_forwarding{$host}{$br_id}{$mac} = $$hashref{$key};
                        }
                }
            }
        }
        if (defined($snmp))
        {
                my $Oid = "1.3.6.1.2.1.2.2.1.2";
                my $res = $snmp->get_table(
                        $Oid,
                        -callback   => [ \&get_snmp_index2ifacedesc,$snmp,$host,$community,$vlanlist,$iflist] );
        }
     }
}



# check if the interface given in argument is present in the 
# iface list
sub exists_in_iface_list
{
        my ($iface,$iflist) = @_;

        my @if = split(/,/,$iflist);

        foreach my $elem (@if)
        {
                if($iface eq $elem)
                {
                        return 1;
                }
        }

        return 0;
}

#####################################################
# function print_portmac_report
# print report for ipmac probe for the equipement specified as argument
sub print_portmac_report
{
        my ($host,$table_forwarding) = @_;

	foreach my $vlan (keys %{$table_forwarding->{$host}})
	{
        	if(open(REPORT,">$config{dir_report}/portmac_$host:$vlan"))
        	{
                	foreach my $mac (keys %{$table_forwarding->{$host}{$vlan}})
                	{
                        	print REPORT "$time{TIME_T};$mac;$table_forwarding->{$host}{$vlan}{$mac}\n"
                	}
               	 	close(REPORT);
        	}
        	else
        	{
                	writelog("portmac",$config{'syslog_facility'},"info",
                        "\t -> ERROR : fichier de cache : $!");
        	}
	}
}


return 1;
