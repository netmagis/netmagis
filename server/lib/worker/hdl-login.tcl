api-handler get {/login} no {
	login 1
	pass 1
    } {
    ::scgi::set-cookie session bla 0 / "" 0 0
    ::scgi::set-header Content-Type text/html
    ::scgi::set-body "<html><title>login ok</title><body>welcome!</body></html>"
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

    set am [dnsconfig get "authmethod"]
    switch $am {
	pgsql {
	    set qlogin [pg_quote $login]
	    set sql "SELECT password FROM pgauth.user WHERE login = $qlogin"
	    set dbpw ""
	    $dbfd exec $sql tab {
		set dbpw $tab(password)
	    }

	    if {[pgauth-checkpw $upw $dbpw]} then {
		set success 1
	    } else {
		set success 0
	    }
	}
	ldap {
	    set url       [dnsconfig get "ldapurl"]
	    set binddn    [dnsconfig get "ldapbinddn"]
	    set bindpw    [dnsconfig get "ldapbindpw"]
	    set basedn    [dnsconfig get "ldapbasedn"]
	    set searchuid [dnsconfig get "ldapsearchlogin"]

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

#
# Register user login and redirect to the start page
#

proc welcome-user {dbfd login casticket} {
    global conf

    set msg [register-user-login $dbfd $login $casticket]
    if {$msg ne ""} then {
	d error $msg
    }

    #
    # Redirect user to the start page
    #

    array set ftab2 {
	lastlogin {{yes}}
    }
    puts stdout [::webapp::call-cgi [pwd]/$conf(next-start) ftab2]
}
