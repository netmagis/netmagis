api-handler get {/sessions} logged {
	active 0
    } {
    set idcor [::n idcor]
    if {$active eq "" || $active eq "1"} then {
	set sql "SELECT COALESCE (json_agg (t), '\[\]') AS j FROM (
			SELECT token, 1 AS active, api, start, ip,
				lastaccess
			    FROM global.utmp
			    WHERE idcor = $idcor
		    ) AS t 
		    "
    } elseif {$active eq "0"} then {
	set sql "SELECT COALESCE (json_agg (t), '\[\]') AS j FROM (
			SELECT token, 0 AS active, api, start, ip,
				stop, stopreason
			    FROM global.wtmp
			    WHERE idcor = $idcor
		    ) AS t 
		    "
    } else {
	::scgi::serror 400 [mc "Invalid active value"]
    }
    ::dbdns exec $sql tab {
	set j $tab(j)
    }
    ::scgi::set-header Content-Type application/json
    ::scgi::set-body $j
}

##############################################################################

api-handler post {/sessions} any {
    } {
    # get body just to check it's a JSON body
    ::scgi::get-body-json $_parm

    set dbody [dict get $_parm "_bodydict"]

    set spec {
		{login text}
		{password text}
	    }
    if {! [::scgi::check-json-attr $dbody $spec]} then {
	::scgi::serror 412 [mc "Invalid JSON input"]
    }

    if {! [check-login $login]} then {
	::scgi::serror 412 [mc "Invalid login"]
    }

    set curlogin [::n login]
    if {$curlogin ne "" && $curlogin ne $login} then {
	::scgi::serror 403 [mc "You must close your session first"]
    }

    set srcaddr [::scgi::get-header "REMOTE_ADDR"]
    if {$srcaddr eq ""} then {
	set srcaddr "::1"
    }

    set am [::n confget "authmethod"]

    clean-authfail ::dbdns

    set delay [check-failed-delay ::dbdns "ip" $srcaddr]
    if {$delay > 0} then {
	set delay [update-authfail ::dbdns "ip" $srcaddr]
	::scgi::serror 429 [mc {IP address '%1$s' temporarily blocked. Retry in %2$d seconds} $srcaddr $delay]
    }

    set delay [check-failed-delay ::dbdns "login" $login]
    if {$delay > 0} then {
	set delay [update-authfail-both ::dbdns $srcaddr $login]
	::scgi::serror 429 [mc {Login '%1$s' temporarily blocked. Retry in %2$d secondes} $login $delay]
    }

    set ok [check-password ::dbdns $login $password]
    switch $ok {
	-1 {
	    # system error
	    ::scgi::serror 500 [mc "Login failed due to an internal error"]
	}
	0 {
	    # login unsuccessful
	    set delay [update-authfail-both ::dbdns $srcaddr $login]
	    if {$delay <= 0} then {
		::scgi::serror 403 [mc "Login failed"]
	    } else {
		::scgi::serror 403 [mc "Login failed. Please retry in %d seconds" $delay]
	    }
	}
	1 {
	    # login successful
	    set casticket ""
	    set msg [register-user-login ::dbdns $login $casticket]
	    if {$msg ne ""} then {
		::scgi::serror 500 $msg
	    }
	    reset-authfail ::dbdns "ip"    $srcaddr
	    reset-authfail ::dbdns "login" $login
	}
    }

#     # XXXX
#    if {$am eq "casldap"} then {
#	::webapp::redirect "start"
#	exit 0
#    }

    ::scgi::set-header Content-Type text/plain
    ::scgi::set-body [mc "Session opened"]
}

##############################################################################

# XXX : a user should be able to terminate any one of his sessions
# XXX : an admin should be able to terminate any of all existing sessions

api-handler delete {/sessions} no {
    } {
    set curlogin [::n login]
    if {$curlogin ne ""} then {
	set token [::scgi::get-cookie "session"]
	set idcor [::n idcor]

	set message [register-user-logout ::dbdns $idcor $token "" "logout"]
	if {$message ne ""} then {
	    ::scgi::serror 500 [mc "Internal server error (%s)" $message]
	}
	::n writelog "auth" "logout [::n login] $token" null null "" "" ""

	::scgi::del-cookie "session"
	::scgi::del-cookie "uid"
	::scgi::del-cookie "lang"

###	d uid "-"
###	d euid {- -1}
###	d module "anon"
###	# leave login unmodified for the "login" page
###
###	if {$am eq "casldap"} then {
###	    set casurl [dnsconfig get "casurl"]
###	    set home [::webapp::myurl 1]
###	    set url "$casurl/logout?service=$home/$conf(next-index)"
###	    ::webapp::redirect $url
###	    exit 0
###	}
    }

    ::scgi::set-header Content-Type text/plain
    ::scgi::set-body [mc "Session closed"]
}

##############################################################################
# Utility functions
##############################################################################

#
# Check user password against the crypted password stored in database
# and returns:
# - -1 if a system error occurred (msg sent via stderr in Apache log)
# - 0 if login was not successful
# - 1 if login was successful
#

proc check-password {dbfd login upw} {
    set success 0

    set am [::::n confget "authmethod"]
    switch $am {
	pgsql {
	    set qlogin [pg_quote $login]
	    set sql "SELECT password FROM pgauth.user WHERE login = $qlogin"
	    set dbpw ""
	    $dbfd exec $sql tab {
		set dbpw $tab(password)
	    }

	    if {[regexp {^\$1\$([^\$]+)\$} $dbpw dummy salt]} then {
		set crypted [::md5crypt::md5crypt $upw $salt]
		if {$crypted eq $dbpw} then {
		    set success 1
		}
	    }
	}
	ldap {
	    set url       [::::n confget "ldapurl"]
	    set binddn    [::::n confget "ldapbinddn"]
	    set bindpw    [::::n confget "ldapbindpw"]
	    set basedn    [::::n confget "ldapbasedn"]
	    set searchuid [::::n confget "ldapsearchlogin"]

	    set handle [::ldapx::ldap create %AUTO%]
	    if {[$handle connect $url $binddn $bindpw]} then {
		set filter [format $searchuid $login]

		set e [::ldapx::entry create %AUTO%]
		if {[catch {set n [$handle read $basedn $filter $e]} m]} then {
		    puts stderr "LDAP search for $login: $m"
		    return -1
		}
		$handle destroy

		switch $n {
		    0 {
			# no login found: success variable is already 0
		    }
		    1 {
			set userdn [$e dn]

			set handle [::ldapx::ldap create %AUTO%]
			if {[$handle connect $url $userdn $upw]} then {
			    set success 1
			}
			$handle destroy
		    }
		    default {
			# more than one login found
			puts stderr "More than one login found for '$login'. Check the ldapbasedn or ldapsearchlogin parameters."
			set success -1
		    }
		}

		$e destroy
	    } else {
		puts stderr "Cannot bind to ldap server: [$handle error]"
		$handle destroy
		set success -1
	    }
	}
    }

    return $success
}

proc register-user-login {dbfd login casticket} {

    #
    # Search id for the login
    #

    set qlogin [pg_quote $login]
    set idcor -1
    set sql "SELECT idcor FROM global.nmuser
			WHERE login = $qlogin AND present = 1"
    $dbfd exec $sql tab {
	set idcor $tab(idcor)
    }
    if {$idcor == -1} then {
	return [mc "Login '%s' does not exist" $login]
    }

    #
    # Generates a unique (at a given time) token
    # In order to test if a generated token is already used, we search it
    # in the global.tmp template table (which gathers all utmp and wtmp
    # lines)
    #

    set toklen [::::n confget "authtoklen"]

    $dbfd lock {global.utmp} {
	set found true
	while {$found} {
	    set token [get-random $toklen]
	    set qtoken [pg_quote $token]
	    set sql "SELECT idcor FROM global.tmp WHERE token = $qtoken"
	    set found false
	    $dbfd exec $sql tab {
		set found true
	    }
	}

	#
	# Register token in utmp table
	#

	set ip [::scgi::get-header "REMOTE_ADDR"]
	if {$ip ne ""} then {
	    set ip [pg_quote $ip]
	} else {
	    set ip NULL
	}
	set qcas NULL
	if {$casticket ne ""} then {
	    set qcas [pg_quote $casticket]
	}

	set sql "INSERT INTO global.utmp (idcor, token, casticket, ip)
		    VALUES ($idcor, $qtoken, $qcas, $ip)"
	if {! [$dbfd exec $sql msg]} then {
	    $dbfd abort
	    return [mc "Cannot register user login (%s)" $msg]
	}
    }

    #
    # Log successful flogin
    #

    ::n writelog "auth" "login $login $token" null null "" $login ""

    #
    # Set session cookie
    #

    ::scgi::set-cookie "session" $token 0 "" "" 0 0
    ::scgi::del-cookie "uid"

    return ""
}

proc register-user-logout {dbfd idcor token date reason} {
    set qtoken [pg_quote $token]
    set qreason [pg_quote $reason]

    if {$date eq ""} then {
	set qdate "now()"
    } else {
	set qdate [pg_quote $date]
    }

    set sql "INSERT INTO global.wtmp (idcor, token, api, start, ip, stop, stopreason)
		SELECT $idcor, token, api, start, ip, $qdate, $qreason
		    FROM global.utmp
		    WHERE idcor = $idcor and token = $qtoken
		    ;
	     DELETE FROM global.utmp
		    WHERE idcor = $idcor and token = $qtoken"
    if {! [$dbfd exec $sql msg]} then {
	return [mc "Cannot un-register connection (%s)" $msg]
    }
    return ""
}

##############################################################################
# Authentication failure management
##############################################################################

#
# Remove all failed authentications older than 1 day
#

proc clean-authfail {dbfd} {
    set sql "DELETE FROM global.authfail
		    WHERE lastfail < LOCALTIMESTAMP - INTERVAL '1 DAY'"
    if {! [$dbfd exec $sql msg]} then {
	puts stderr "Error in expiration of failed logins: $msg"
	# We don't exit with this error. In case the database is
	# failing, we will report another database error later
	# with an error message related to the action of the user.
    }
}

#
# Remove failed authentication entry (for login/ip) in case of successful login
#

proc reset-authfail {dbfd otype origin} {
    set qorigin [pg_quote $origin]
    set qtype   [pg_quote $otype]
    set sql "DELETE FROM global.authfail
		    WHERE otype = $qtype AND origin = $qorigin"
    if {! [$dbfd exec $sql msg]} then {
	puts stderr "Error in resetting failed $otype: $msg"
    }
}

#
# Update login/ip entry in case of failed login
# Returns delay until end of blocking period (<= 0 if no more blocking)
#

proc update-authfail {dbfd otype origin} {
    set failXthreshold1 [::::n confget "fail${otype}threshold1"]
    set failXthreshold2 [::::n confget "fail${otype}threshold2"]
    set failXdelay1     [::::n confget "fail${otype}delay1"]
    set failXdelay2     [::::n confget "fail${otype}delay2"]

    #
    # Start of critical section
    #

    $dbfd lock {global.authfail} {
	#
	# Get current status
	#

	set qorigin [pg_quote $origin]
	set qtype   [pg_quote $otype]
	set sql "SELECT nfail
			FROM global.authfail
			WHERE otype = $qtype AND origin = $qorigin"
	set nfail -1
	$dbfd exec $sql tab {
	    set nfail $tab(nfail)
	}

	#
	# Update current status according to various thresholds
	#

	if {$nfail == -1} then {
	    set sql "INSERT INTO global.authfail (origin, otype, nfail)
			VALUES ($qorigin, $qtype, 1)"
	} elseif {$nfail >= $failXthreshold2} then {
	    set sql "UPDATE global.authfail
			SET nfail = nfail+1,
			    lastfail = NOW (),
			    blockexpire = NOW() + '$failXdelay2 second'
			WHERE otype = $qtype AND origin = $qorigin"
	} elseif {$nfail >= $failXthreshold1} then {
	    set sql "UPDATE global.authfail
			SET nfail = nfail+1,
			    lastfail = NOW (),
			    blockexpire = NOW() + '$failXdelay1 second'
			WHERE otype = $qtype AND origin = $qorigin"
	} else {
	    set sql "UPDATE global.authfail
			SET nfail = nfail+1,
			    lastfail = NOW ()
			WHERE otype = $qtype AND origin = $qorigin"
	}

	if {! [$dbfd exec $sql]} then {
	    $dbfd abort
	}
    }

    #
    # Return delay until end of blocking
    #

    return [check-failed-delay $dbfd $otype $origin]
}

#
# In case of failed login attempt, ban both login and IP address
#

proc update-authfail-both {dbfd srcaddr login} {
    set d1 [update-authfail $dbfd "ip"    $srcaddr]
    set d2 [update-authfail $dbfd "login" $login]
    return [expr max($d1,$d2)]
}


#
# Delay until end of blocking period
#
# Input:
#   - dbfd: database handle
#   - otype: "ip" or "login"
#   - origin: IP address or login name
# Output:
#   - return value: delay (in seconds) until access is allowed
#	(or 0 if not blocked or negative value if access is allowed again)
#

proc check-failed-delay {dbfd otype origin} {
    set qorigin [pg_quote $origin]
    set qtype   [pg_quote $otype]
    set sql "SELECT EXTRACT (EPOCH FROM blockexpire - LOCALTIMESTAMP(0))
			AS delay
		FROM global.authfail
    		WHERE otype = $qtype AND origin = $qorigin
		    AND blockexpire IS NOT NULL"
    set delay 0
    $dbfd exec $sql tab {
	set delay $tab(delay)
    }
    return $delay
}

#
# Check login name validity
#
# Input:
#   - parameters:
#	- login : login name
# Output:
#   - return value: 1 (valid) or 0 (invalid)
#
# History
#   2015/05/07 : pda/jean : design
#

proc check-login {name} {
    return [expr {$name ne "" && ! [regexp {[()<>*]} $name]}]
}


proc get-random {nbytes} {
    # XXX
    set dev [::lc get "random"]
    if {[catch {set fd [open $dev {RDONLY BINARY}]} msg]} then {
	#
	# Silently fall-back to a non cryptographically secure random
	# if /dev/random is not available
	#
	expr srand([clock clicks -microseconds])
	set r ""
	for {set i 0} {$i < $nbytes} {incr i} {
	    append r [binary format "c" [expr int(rand()*256)]]
	}
    } else {
	#
	# Successful open: read random bytes
	#
	set r [read $fd $nbytes]
	close $fd
    }

    binary scan $r "H*" hex
    return $hex
}
