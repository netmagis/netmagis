#
# TCL library for WebDNS
#
#
# History
#   2002/03/27 : pda/jean : design
#   2002/05/23 : pda/jean : add info-groupe
#   2004/01/14 : pda/jean : add IPv6
#   2004/08/04 : pda/jean : aadd MAC
#   2004/08/06 : pda/jean : extension of network access rights
#   2006/01/26 : jean     : bug fix in check-authorized-host (case ip EXIST)
#   2006/01/30 : jean     : alias message in check-authorized-host
#   2010/11/29 : pda      : i18n
#

lappend auto_path %PKGTCL%

package require msgcat			;# tcl

package require snit			;# tcllib
package require ip			;# tcllib

package require webapp
package require pgsql
package require arrgen

namespace import ::msgcat::*

##############################################################################
# Library parameters
##############################################################################

#
# Various table specifications
#

set libconf(tabperm) {
    global {
	chars {10 normal}
	align {left}
	botbar {yes}
	columns {75 25}
    }
    pattern DROIT {
	vbar {yes}
	column { }
	vbar {yes}
	column { }
	vbar {yes}
    }
}

set libconf(tabdreq) {
    global {
	chars {10 normal}
	align {left}
	botbar {yes}
	columns {20 80}
    }
    pattern DroitEq {
	vbar {yes}
	column { }
	vbar {yes}
	column {
	    chars {bold}
	    format {lines}
	}
	vbar {yes}
    }
}

set libconf(tabnetworks) {
    global {
	chars {10 normal}
	align {left}
	botbar {yes}
	columns {15 35 15 35}
    }
    pattern Reseau {
	vbar {yes}
	column {
	    align {center}
	    chars {14 bold}
	    multicolumn {4}
	}
	vbar {yes}
    }
    pattern Normal4 {
	vbar {yes}
	column { }
	vbar {yes}
	column {
	    chars {bold}
	}
	vbar {yes}
	column { }
	vbar {yes}
	column {
	    chars {bold}
	}
	vbar {yes}
    }
    pattern Droits {
	vbar {yes}
	column { }
	vbar {yes}
	column {
	    multicolumn {3}
	    chars {bold}
	    format {lines}
	}
	vbar {yes}
    }
}

set libconf(tabdomains) {
    global {
	chars {10 normal}
	align {left}
	botbar {yes}
	columns {50 25 25}
    }
    pattern Domaine {
	vbar {yes}
	column { }
	vbar {no}
	column { }
	vbar {no}
	column { }
	vbar {yes}
    }
}

set libconf(tabdhcpprofile) {
    global {
	chars {10 normal}
	align {left}
	botbar {yes}
	columns {25 75}
    }
    pattern DHCP {
	vbar {yes}
	column { }
	vbar {no}
	column {
	    format {lines}
	}
	vbar {yes}
    }
}

set libconf(tabmachine) {
    global {
	chars {10 normal}
	align {left}
	botbar {yes}
	columns {20 80}
    }
    pattern Normal {
	vbar {yes}
	column { }
	vbar {yes}
	column { }
	vbar {yes}
    }
}

set libconf(tabuser) {
    global {
	chars {10 normal}
	align {left}
	botbar {yes}
	columns {20 80}
    }
    pattern Normal {
	vbar {yes}
	column { }
	vbar {yes}
	column {
	    chars {gras}
	}
	vbar {yes}
    }
}

set libconf(tabeqstatus) {
    global {
	chars {10 normal}
	align {left}
	botbar {yes}
	columns {20 10 20 50}
    }
    pattern Title4 {
	chars {gras}
	vbar {yes}
	column { }
	vbar {yes}
	column { }
	vbar {yes}
	column { }
	vbar {yes}
	column { }
	vbar {yes}
    }
    pattern Normal4 {
	vbar {yes}
	column { }
	vbar {yes}
	column { }
	vbar {yes}
	column { }
	vbar {yes}
	column { }
	vbar {yes}
    }
}


set libconf(extractcoll)	"%TOPODIR%/bin/extractcoll %s < %GRAPH%"
set libconf(extracteq)		"%TOPODIR%/bin/extracteq %s %s < %GRAPH%"

# Cisco aironet frequency conversion table
array set libconf {
    freq:2412	1
    freq:2417	2
    freq:2422	3
    freq:2427	4
    freq:2432	5
    freq:2437	6
    freq:2442	7
    freq:2447	8
    freq:2452	9
    freq:2457	10
    freq:2462	11
}


##############################################################################
# WebDNS application framework
##############################################################################

#
# WebDNS access class
#
# This class is a simple way to initialize the whole context of all
# WebDNS programs (CGI scripts, daemons, command line utilities).
#
# Methods:
#   init-cgi
#	initialize context for a CGI script
#   init-script
#	initialize context for an autonomous program (not CGI)
#   end
#	properly close access to application and to database
#   nextprog, nextargs
#	return next action (prog and args), i.e. page to come back when
#	current action (travel in the application) is finished
#   euid
#	returns the effective login and id of user
#   urlset
#	register a named URL as a path and arguments. These components
#	will be used in the output page, or with the urlget method
#   urladd
#	adds an argument to a registered named URL
#   urlsetnext
#	adds a specified next action (see nextprog/nextargs) to a
#	registered named URL
#   urladdnext
#	adds the current next action (see nextprog/nextargs) to a
#	registered named URL
#   urlsubst
#	returns a substitution list (see ::webapp::file-subst) with all
#	registered URLs
#   urlget
#	returns (and de-register) a named URL
#   module
#	sets the current module, used for the links menu
#   error
#	returns an error page and close access to application
#   result
#	returns a page and close access to application
#   writelog
#	write a log message in the log system
#
# History
#   2001/06/18 : pda      : design
#   2002/12/26 : pda      : update and usage
#   2003/05/13 : pda/jean : integration in webdns and auth class usage
#   2007/10/05 : pda/jean : adaptation to "authuser" and "authbase" objects
#   2007/10/26 : jean     : add log
#   2010/10/25 : pda      : add dnsconfig
#   2010/11/05 : pda      : use a snit object
#   2010/11/09 : pda      : add init-script
#   2010/11/29 : pda      : i18n
#

snit::type ::dnscontext {
    # database handle
    variable db ""

    # locale in use : either specified by browser, or specified by user
    variable locale "C"
    # locale specified by browser
    variable blocale "C"
    # all available locales. Order is not important.
    variable avlocale {fr en}

    # log access
    variable log

    # uid, and effective uid
    variable uid ""
    variable euid ""
    variable eidcor -1

    # HTML error page
    variable errorpage ""

    # in order to come back from a travel in the WebDNS application
    variable dnextprog ""
    variable dnextargs ""

    # URL declared in the scripts
    # urltab(<name>) = {path {key val} {key val} {key val...}}
    # <name> = %[A-Z0-9]+% or "" for a temporary URL
    # urltab(<name>:nextprog) = <nextprog> or empty string
    # urltab(<name>:nextargs) = <nextargs> (if <nextprog> != empty string)
    variable urltab -array {}

    # where are we in the application?
    # authorized values: dns topo admin
    variable curmodule	""

    # current capacities (depending on user access rights or application
    # installation/parametrization)
    # possible values: admin dns topo
    variable curcap	{}

    # Links menu
    # This array has a tree structure:
    #	tab(:<module>)	{{<element>|:<module> <cap>}..{<element>|:<module> <cap>}}
    #   tab(<element>)	{<url> <desc>}
    #
    # The first type gives display order for a module
    #	- a module is one of the values of the "curmodule" variable,
    #		or a reference from another module (in this array)
    #	- each element or module is displayed only if the condition
    #		"cap" (capacity) is true for this user. Special "always"
    #		capacity means that this element or module is always
    #		displayed.
    #	- if a module is mentionned in the list, this module is
    #		recursively searched (which gives the tree structure,
    #		elements are the terminal nodes)
    # The second type gives the display of a particular element.
    variable links -array {
	:dns		{
			    {accueil always}
			    {consulter always}
			    {ajouter always}
			    {supprimer always}
			    {modifier always}
			    {rolesmail always}
			    {dhcprange always}
			    {passwd always}
			    {corresp always}
			    {whereami always}
			    {topotitle topo}
			    {mactitle mac}
			    {admtitle admin}
			}
	accueil		{%HOMEURL%/bin/accueil Welcome}
	consulter	{%HOMEURL%/bin/consulter Consult}
	ajouter		{%HOMEURL%/bin/ajout Add}
	supprimer	{%HOMEURL%/bin/suppr Delete}
	modifier	{%HOMEURL%/bin/modif Modify}
	rolesmail	{%HOMEURL%/bin/mail {Mail roles}}
	dhcprange	{%HOMEURL%/bin/dhcp {DHCP ranges}}
	passwd		{%PASSWDURL% Password}
	corresp		{%HOMEURL%/bin/corr Search}
	whereami	{%HOMEURL%/bin/corresp?critere=_ {Where am I?}}
	topotitle	{%HOMEURL%/bin/eq Topology}
	mactitle	{%HOMEURL%/bin/macindex Mac}
	admtitle	{%HOMEURL%/bin/admin Admin}
	:topo		{
			    {eq always}
			    {l2 always}
			    {l3 always}
			    {topotop admin}
			    {dnstitle dns}
			    {mactitle mac}
			    {admtitle admin}
			}
	eq		{%HOMEURL%/bin/eq Equipments}
	l2		{%HOMEURL%/bin/l2 Vlans}
	l3		{%HOMEURL%/bin/l3 Networks}
	dnstitle	{%HOMEURL%/bin/accueil DNS/DHCP}
	:admin		{
			    {admtitle always}
			    {consultmx always}
			    {consultnet always}
			    {listecorresp always}
			    {corresp always}
			    {modetabl always}
			    {modcommu always}
			    {modhinfo always}
			    {modreseau always}
			    {moddomaine always}
			    {admrelsel always}
			    {modzone always}
			    {modzone4 always}
			    {modzone6 always}
			    {moddhcpprofil always}
			    {modvlan always}
			    {modeqtype always}
			    {modeq always}
			    {admgrpsel always}
			    {admgenliste always}
			    {admparliste always}
			    {statcor always}
			    {statetab always}
			    {topotop topo}
			    {dnstitle dns}
			    {topotitle topo}
			    {mactitle mac}
			}
	consultmx	{%HOMEURL%/bin/consultmx {List MX}}
	consultnet	{%HOMEURL%/bin/consultnet {List networks}}
	listecorresp	{%HOMEURL%/bin/listecorresp {List users}}
	corresp		{%HOMEURL%/bin/corresp {Search}}
	modetabl	{%HOMEURL%/bin/admrefliste?type=etabl {Modify organizations}}
	modcommu	{%HOMEURL%/bin/admrefliste?type=commu {Modify communities}}
	modhinfo	{%HOMEURL%/bin/admrefliste?type=hinfo {Modify machine types}}
	modreseau	{%HOMEURL%/bin/admrefliste?type=reseau {Modify networks}}
	moddomaine	{%HOMEURL%/bin/admrefliste?type=domaine {Modify domains}}
	admrelsel	{%HOMEURL%/bin/admrelsel {Modify mailhost}}
	modzone		{%HOMEURL%/bin/admrefliste?type=zone {Modify zones}}
	modzone4	{%HOMEURL%/bin/admrefliste?type=zone4 {Modify reverse IPv4 zones}}
	modzone6	{%HOMEURL%/bin/admrefliste?type=zone6 {Modify reverse IPv6 zones}}
	moddhcpprofil	{%HOMEURL%/bin/admrefliste?type=dhcpprofil {Modify DHCP profiles}}
	modvlan		{%HOMEURL%/bin/admrefliste?type=vlan {Modify Vlans}}
	modeqtype	{%HOMEURL%/bin/admrefliste?type=eqtype {Modify equipment types}}
	modeq		{%HOMEURL%/bin/admrefliste?type=eq {Modify equipments}}
	admgrpsel	{%HOMEURL%/bin/admgrpsel {Modify users and groups}}
	admgenliste	{%HOMEURL%/bin/admgenliste {Force zone generation}}
	admparliste	{%HOMEURL%/bin/admparliste {Application parameters}}
	statcor		{%HOMEURL%/bin/statcor {Statistics by user}}
	statetab	{%HOMEURL%/bin/statetab {Statistics by organization}}
	topotop		{%HOMEURL%/bin/topotop {Topod status}}
	:mac		{
			    {macindex always}
			    {mac always}
			    {ipinact always}
			    {macstat always}
			    {dnstitle dns}
			    {topotitle topo}
			    {admtitle admin}
			}
	macindex	{%HOMEURL%/bin/macindex {MAC index}}
	mac		{%HOMEURL%/bin/mac {MAC search}}
	ipinact		{%HOMEURL%/bin/ipinact {Inactive addresses}}
	macstat		{%HOMEURL%/bin/macstat {MAC stats}}
    }

    ###########################################################################
    # Internal procedures
    ###########################################################################

    #
    # Common initialization work
    #
    # Input:
    #	- selfs : current object
    #	- _dbfd : database handle, in return
    #   - login : user's login
    #   - _tabuid : array containing, in return, user's characteristics
    #		(login, password, nom, prenom, mel, tel, fax, mobile, adr,
    #			idcor, idgrp, present)
    #
    # Output:
    #	- return value: empty string or error message
    #

    proc init-common {selfns _dbfd login _tabuid} {
	global ah
	upvar $_dbfd dbfd
	upvar $_tabuid tabuid

	#
	# Access to authentification mechanism (database or LDAP)
	#

	set ah [::webapp::authbase create %AUTO%]
	$ah configurelist %AUTH%

	#
	# Access to WebDNS database
	#

	set dbfd [ouvrir-base %BASE% msg]
	if {$dbfd eq ""} then {
	    return [format [mc "Error accessing database: %s"] $msg]
	}
	set db $dbfd

	#
	# Log initialization
	#

	set log [::webapp::log create %AUTO% \
				    -subsys webdns \
				    -method opened-postgresql \
				    -medium [list "db" $dbfd table global.log] \
			]
	set uid $login
	set euid $login

	#
	# Access to configuration parameters (stored in the database)
	#

	config ::dnsconfig
	dnsconfig setdb $dbfd

	#
	# Reads all user's characteristics. If this user is not
	# marked "present" in the database, get him out!
	#

	set n [read-user $dbfd $login tabuid msg]
	if {$n != 1} then {
	    return $msg
	}
	if {! $tabuid(present)} then {
	    return [format [mc "User '%s' not authorized"] $login]
	}
	set eidcor $tabuid(idcor)

	return ""
    }

    #
    # Builds up an URL
    #
    # Input:
    #   - path : URL path
    #   - largs : list of {{key val} {key val} ...} to add to URL
    #	- u, eu : uid and effective uid
    #	- l, bl : locale and browser locale
    # Output:
    #   - return value: URL
    #
    # Each element {key val} may optionnally be a single string "key=val",
    #	in which case it must be post-string encoded)
    #

    proc make-url {_urltab name u eu l bl} {
	upvar $_urltab urltab

	set path [lindex $urltab($name) 0]
	set largs [lreplace $urltab($name) 0 0]

	#
	# Two possible cases:
	# - URL is a local one (begins with a "/")
	# - URL is external (begins with "http://")
	# In the last case, don't add default arguments which are
	# specific to WebDNS application.
	#

	if {[regexp {^/} $path]} then {
	    #
	    # Add default arguments
	    #

	    # user susbtitution
	    if {$u ne $eu} then {
		lappend largs [list "uid" $u]
	    }

	    # defautl locale
	    if {$l ne $bl} then {
		lappend largs [list "l" $l]
	    }

	    # travel in the application
	    if {$urltab($name:nextprog) ne ""} then {
		lappend largs [list "nextprog" $urltab($name:nextprog)]
		lappend largs [list "nextargs" $urltab($name:nextargs)]
	    }

	    #
	    # Build-up the argument list
	    #

	    set l {}
	    foreach keyval $largs {
		if {[llength $keyval] == 1} then {
		    lappend l $keyval
		} else {
		    lassign $keyval k v
		    set v [::webapp::post-string $v]
		    lappend l "$k=$v"
		}
	    }

	    #
	    # Build-up URL from path and arguments
	    #

	    if {[llength $l] == 0} then {
		# no argument: simple case
		set url $path
	    } else {
		if {[string match {*\?*} $path]} then {
		    # already an argument in the path
		    set url [format "%s&%s" $path [join $l "&"]]
		} else {
		    # not yet an argument in the path
		    set url [format "%s?%s" $path [join $l "&"]]
		}
	    }
	} else {
	    set url $path
	}

	unset urltab($name)
	return $url
    }

    #
    # Recursive internal method to get links menu
    #
    # Input:
    #	- eorm = element (without ":") or module (with ":")
    # Output:
    #	- HTML code for the menu
    #

    method Get-links {eorm} {
	set h ""
	if {[info exists links($eorm)]} then {
	    set lks $links($eorm)

	    if {[string match ":*" $eorm]} then {
		foreach couple $lks {
		    lassign $couple neorm cond
		    if {$cond eq "always" || $cond in $curcap} then {
			append h [$self Get-links $neorm]
			append h "\n"
		    }
		}
	    } else {
		lassign $lks path msg
		$self urlset "" $path {}
		set url [make-url urltab "" $uid $euid $locale $blocale]

		append h [::webapp::helem "li" \
				[::webapp::helem "a" [mc $msg] "href" $url]]
		append h "\n"
	    }

	} else {
	    append h [::webapp::helem "li" \
				[format [mc "Unknown module '%s'"] $eorm] ]
	    append h "\n"
	}
	return $h
    }


    ###########################################################################
    # Initialize access to WebDNS, for a CGI script
    #
    # Input:
    #   - module : current module we are in ("dns", "admin" or "topo")
    #   - err : file containing the HTML error page
    #   - attr : needed attribute to execute the script
    #   - form : form fields specification
    #   - _ftab : array containing, in return, form values
    #   - _dbfd : database handle, in return
    #   - _login : user's login, in return
    #   - _tabuid : array containing, in return, user's characteristics
    #		(login, password, nom, prenom, mel, tel, fax, mobile, adr,
    #			idcor, idgrp, present)
    # Output:
    #   - return value: none
    #   - object d : WebDNS context
    #   - object $ah : access to authentication base
    #

    method init-cgi {module err attr form _ftab _dbfd _login _tabuid} {
	upvar $_ftab ftab
	upvar $_dbfd dbfd
	upvar $_login login
	upvar $_tabuid tabuid

	#
	# Builds-up a fictive context to easily return error messages
	#

	set login [::webapp::user]
	set uid $login
	set euid $login
	set curmodule "dns"
	set curcap {dns}
	set errorpage $err
	set locale "C"
	set blocale "C"

	#
	# Language negociation
	#

	set blocale [::webapp::locale $avlocale]
	set locale $blocale

	uplevel #0 mclocale $locale
	uplevel #0 mcload %TRANSMSGS%

	#
	# Maintenance mode : access is forbidden to all, except
	# for users specified in ROOT pattern.
	#

	set ftest %NOLOGIN%
	if {[file exists $ftest]} then {
	    if {$uid eq "" || ! ($uid in %ROOT%)} then {
		set fd [open $ftest "r"]
		set msg [read $fd]
		close $fd
		$self error $msg
	    }
	}

	#
	# Current module
	#

	set curmodule $module

	#
	# User's login
	#

	if {$login eq ""} then {
	    $self error [mc "No login: authentication failed"]
	}

	#
	# Common initialization work
	#

	set msg [init-common $selfns dbfd $login tabuid]
	if {$msg ne ""} then {
	    $self error $msg
	}

	#
	# Add default parameters in form analysis
	# Default parameters are:
	#   l : language
	#   uid : login to be substituted
	#   nextprog : next action, after current travel
	#   nextargs : arguments of next action, after current travel
	#

	lappend form {l 0 1}
	lappend form {uid 0 1}
	lappend form {nextprog 0 1}
	lappend form {nextargs 0 1}
	if {[llength [::webapp::get-data ftab $form]] == 0} then {
	    set msg [mc "Invalid input"]
	    if {%DEBUG%} then {
		append msg "\n$ftab(_error)"
	    }
	    $self error $msg
	}

	#
	# Is a specific language required ?
	#

	set l [string trim [lindex $ftab(l) 0]]
	if {$l in $avlocale} then {
	    set locale $l
	}

	mclocale $locale
	mcload %TRANSMSGS%

	#
	# Get next action
	#

	set dnextprog [string trim [lindex $ftab(nextprog) 0]]
	set dnextargs [string trim [lindex $ftab(nextargs) 0]]

	#
	# Perform user substitution (through the uid parameter)
	#

	set nuid [string trim [lindex $ftab(uid) 0]]
	if {$nuid ne "" && $tabuid(admin)} then {
	    array set tabouid [array get tabuid]
	    array unset tabuid

	    set uid $nuid
	    set login $nuid

	    set n [read-user $dbfd $login tabuid msg]
	    if {$n != 1} then {
		$self error $msg
	    }
	    if {! $tabuid(present)} then {
		$self error [format [mc "User '%s' not authorized"] $login]
	    }
	}

	#
	# Remove additionnal default parameters
	# If they were staying in ftab, they could be caught by a
	# "hide all ftab paramaters" in a CGI script.
	#

	foreach p {l uid nextprog nextargs} {
	    unset ftab($p)
	}

	#
	# Computes capacity, given local installation and/or user rights
	#

	set curcap	{}
	lappend curcap "dns"
	if {[dnsconfig get "topoactive"]} then {
	    lappend curcap "topo"
	}
	if {[dnsconfig get "macactive"] && $tabuid(droitmac)} then {
	    lappend curcap "mac"
	}
	if {$tabuid(admin)} then {
	    lappend curcap "admin"
	}

	#
	# Is this page an "admin" only page ?
	#

	if {[llength $attr] > 0} then {
	    # XXX : for now, test only one attribute
	    if {! [user-attribute $dbfd $tabuid(idcor) $attr]} then {
		$self error [format [mc "User '%s' not authorized"] $login]
	    }
	}
    }

    ###########################################################################
    # Initialize access to WebDNS, for an autonomous program (command
    # line utility, daemon, etc.)
    #
    # Input:
    #   - _dbfd : database handle, in return
    #   - login : user's login
    #   - _tabuid : array containing, in return, user's characteristics
    #		(login, password, nom, prenom, mel, tel, fax, mobile, adr,
    #			idcor, idgrp, present)
    # Output:
    #   - return value: error message or empty string
    #   - object d : WebDNS context
    #   - object $ah : access to authentication base
    #

    method init-script {_dbfd login _tabuid} {
	upvar $_dbfd dbfd
	upvar $_tabuid tabuid

	#
	# Locale
	#

	uplevel #0 mclocale
	uplevel #0 mcload %TRANSMSGS%

	#
	# Maintenance mode
	#

	if {[file exists %NOLOGIN%]} then {
	    set fd [open %NOLOGIN% "r"]
	    set message [read $fd]
	    close $fd
	    return [format [mc "Connection refused (%s)"] $message]
	}

	#
	# Common initialization work
	#

	set msg [init-common $selfns dbfd $login tabuid]
	if {$msg ne ""} then {
	    return $msg
	}

	return ""
    }

    ###########################################################################
    # Ends access to WebDNS (CGI script or autonomous program)
    #
    # Input:
    #   - none
    # Output:
    #   - return value: none
    #

    method end {} {
	fermer-base $db
    }

    ###########################################################################
    # Returns an error and properly close access to application (and database)
    #
    # Input:
    #   - msg : (translated) error message
    # Output:
    #   - return value: none (this method don't return)
    #

    method error {msg} {
	set msg [::webapp::html-string $msg]
	regsub -all "\n" $msg "<br>" msg
	$self result $errorpage [list [list %MESSAGE% $msg]]
	exit 0
    }

    ###########################################################################
    # Sends a page and properly close access to application (and database)
    #
    # Input:
    #   - page : HTML or LaTeX page containing templates
    #   - lsubst : substitution list for template values
    # Output:
    #   - return value: none
    #

    method result {page lsubst} {
	#
	# Define the output format from file extension
	#

	switch -glob $page {
	    *.html {
		set fmt html
		set dir %DESTDIR%/lib
	    }
	    *.tex {
		set fmt pdf
		set dir %DESTDIR%/lib
	    }
	    default {
		set fmt "unknown"
		set dir %DESTDIR%/lib
	    }
	}

	#
	# Constitute the links menu
	#
	if {$fmt eq "html"} then {

	    set linkmenu [$self Get-links ":$curmodule"]
	    lappend lsubst [list %BANDEAU% $linkmenu]

	    foreach s [$self urlsubst] {
		lappend lsubst $s
	    }
	}

	#
	# Send resulting page
	#

	::webapp::send $fmt [::webapp::file-subst "$dir/$page" $lsubst]
	$self end
    }

    ###########################################################################
    # Get the next action (i.e. where we must come back after the current
    # travel)
    #
    # Input: none
    # Output:
    #   - return value: <nextprog> or <nextargs>, depending on method
    #

    method nextprog {} {
	return $dnextprog
    }

    method nextargs {} {
	return $dnextargs
    }

    ###########################################################################
    # Get the effective login and idcor of the user
    #
    # Input: none
    # Output:
    #   - return value: list {login idcor}
    #

    method euid {} {
	return [list $euid $eidcor]
    }

    ###########################################################################
    # URL framework
    #

    method urlset {name path {largs {}}} {
	set urltab($name) [linsert $largs 0 $path]
	set urltab($name:nextprog) ""
    }

    method urladd {name largs} {
	set url($name) [concat $url($name) $largs]
    }

    method urlsetnext {name nextprog nextargs} {
	set urltab($name:nextprog) $nextprog
	set urltab($name:nextargs) $nextargs
    }

    method urladdnext {name} {
	if {$dnextprog eq ""} then {
	    set urltab($name:nextprog) ""
	} else {
	    set urltab($name:nextprog) $dnextprog
	    set urltab($name:nextargs) $dnextargs
	}
    }

    method urlsubst {} {
	set lsubst {}
	foreach name [array names urltab] {
	    if {! [string match "*:*" $name]} then {
		set url [$self urlget $name]
		lappend lsubst [list $name $url]
	    }
	}
	return $lsubst
    }

    method urlget {name} {
	set path [lindex $urltab($name) 0]
	set largs [lreplace $urltab($name) 0 0]
	set url [make-url urltab $name $uid $euid $locale $blocale]
	return $url
    }


    ###########################################################################
    # Sets the context used for the links menu
    #
    # Input:
    #   - module : module name (see curmodule and links variables)
    # Output: none
    #

    method module {module} {
	set idx ":$module"
	if {! [info exists links($idx)]} then {
	    # This is an internal error
	    error "'$module' is not a valid module"
	}
	set curmodule $module
    }

    ###########################################################################
    # Write a line in the log system
    # 
    # Input:
    #	- event : event name (examples : supprhost, suppralias etc.)
    #	- message : log message (example: parameters of the event)
    #
    # Output: none
    #
    # History :
    #   2007/10/?? : jean : design
    #   2010/11/09 : pda  : dnscontext object and no more login parameter
    #

    method writelog {event msg} {
	global env

	if {[info exists env(REMOTE_ADDR) ]} then {
	    set ip $env(REMOTE_ADDR)    
	} else {
	    set ip ""
	}

	$log log "" $event $euid $ip $msg
    }
}

##############################################################################
# Configuration parameters
##############################################################################

#
# Configuration parameters class
#
# This class is a simple way to access to configuration parameters
# of the WebDNS application.
#
# Methods:
# - setdb $dbfd
#	set the database handle used to access parameters
# - class
#	returns all known classes
# - desc class-or-key
#	returns the description associated with class or key
# - keys [ class ]
#	returns all keys associed with the class, or all known keys
# - keytype key
#	returns type of a given key, under the format {string|bool|text|menu x}
#	X is present only for the "menu" type.
# - keyhelp key
#	returns the help message associated with a key
# - get key
#	returns the value associated with a key
# - set key val
#	set the value associated with a key and returns an empty string or
#	an error message.
#
# History
#   2001/03/21 : pda      : design getconfig/setconfig
#   2010/10/25 : pda      : transform into a class
#   2010/12/04 : pda      : i18n
#

snit::type ::config {
    # database handle
    variable db ""

    # configuration parameter specification
    # {{class class-spec} {class class-spec} ...}
    # class = class name
    # class-spec = {{key type} {key type} ...}
    variable configspec {
	{dns
	    {datefmt {string}}
	    {jourfmt {string}}
	}
	{dhcp
	    {default_lease_time {string}}
	    {max_lease_time {string}}
	    {min_lease_time {string}}
	}
	{topo
	    {topoactive {bool}}
	    {topofrom {string}}
	    {topoto {string}}
	}
	{mac
	    {macactive {bool}}
	}
	{auth
	    {authmailfrom {bool}}
	    {mailfrom {string}}
	    {authmailreplyto {bool}}
	    {mailreplyto {string}}
	    {authmailcc {bool}}
	    {mailcc {string}}
	    {authmailbcc {bool}}
	    {mailbcc {string}}
	    {authmailsubject {bool}}
	    {mailsubject {string}}
	    {authmailbody {bool}}
	    {mailbody {text}}
	    {groupes {string}}
	}
    }

    #
    # Internal representation of parameter specification
    #
    # (class)			{<cl1> ... <cln>}
    # (class:<cl1>)		{<k1> ... <kn>}
    # (key:<k1>:type)		{string|bool|text|menu ...}
    #

    variable internal -array {}

    constructor {} {
	set internal(class) {}
	foreach class $configspec {

	    set classname [lindex $class 0]
	    lappend internal(class) $classname
	    set internal(class:$classname) {}

	    foreach key [lreplace $class 0 0] {
		lassign $key keyname keytype

		lappend internal(class:$classname) $keyname
		set internal(key:$keyname:type) $keytype
	    }
	}
    }

    method setdb {dbfd} {
	set db $dbfd
    }

    # returns all classes
    method class {} {
	return $internal(class)
    }

    # returns textual description of the given class or key
    method desc {cork} {
	set r $cork
	if {[info exists internal(class:$cork)]} then {
	    set r [mc "cfg:$cork"]
	} elseif {[info exists internal(key:$cork:type)]} {
	    set r [mc "cfg:$cork:desc"]
	}
	return $r
    }

    # returns all keys associated with a class (default  : all classes)
    method keys {{class {}}} {
	if {[llength $class] == 0} then {
	    set class $internal(class)
	}
	set lk {}
	foreach c $class {
	    set lk [concat $lk $internal(class:$c)]
	}
	return $lk
    }

    # returns key type
    method keytype {key} {
	set r ""
	if {[info exists internal(key:$key:type)]} then {
	    set r $internal(key:$key:type)
	}
	return $r
    }

    # returns key help
    method keyhelp {key} {
	set r $key
	if {[info exists internal(key:$key:type)]} then {
	    set r [mc "cfg:$key:help"]
	}
	return $r
    }

    # returns key value
    method get {key} {
	if {[info exists internal(key:$key:type)]} then {
	    set found 0
	    pg_select $db "SELECT * FROM global.config WHERE clef = '$key'" tab {
		set val $tab(valeur)
		set found 1
	    }
	    if {! $found} then {
		switch $internal(key:$key:type) {
		    string	{ set val "" }
		    bool	{ set val 0 }
		    set text	{ set val "" }
		    set menu	{ set val "" }
		    default	{ set val "type unknown" }
		}
	    }
	} else {
	    error [format [mc "Unknown configuration key '%s'"] $key]
	}
	return $val
    }

    # set key value
    # returns empty string if ok, or an error message
    method set {key val} {
	set r ""
	set k [::pgsql::quote $key]
	set sql "DELETE FROM global.config WHERE clef = '$k'"
	if {[::pgsql::execsql $db $sql msg]} then {
	    set v [::pgsql::quote $val]
	    set sql "INSERT INTO global.config VALUES ('$k', '$v')"
	    if {! [::pgsql::execsql $db $sql msg]} then {
		set r [format [mc {Cannot set key '%1$s' to '%2$s': %3$s}] $key $val $msg]
	    }
	} else {
	    set r [format [mc {Cannot fetch key '%1$s': %2$s}] $key $msg]
	}

	return $r
    }
}

##############################################################################
# Cosmetic
##############################################################################

#
# Format a string such as it correctly displays in an array
#
# Input:
#   - parameters:
#	- string : string to display
# Output:
#   - return value: same string, with "&nbsp;" if empty
#
# History
#   2002/05/23 : pda      : design
#   2010/11/29 : pda      : i18n
#

proc html-tab-string {string} {
    set v [::webapp::html-string $string]
    if {[string trim $v] eq ""} then {
	set v "&nbsp;"
    }
    return $v
}

#
# Display user data in an HTML array
#
# Input:
#   - parameters:
#	- tabuid : array containing user's attributes
#   - global variables :
#	- libconf(tabuser) : array specification
# Output:
#   - return value: HTML code ready to use
#
# History
#   2002/07/25 : pda      : design
#   2003/05/13 : pda/jean : use tabuid
#   2010/11/29 : pda      : i18n
#

proc display-user {_tabuid} {
    global libconf
    upvar $_tabuid tabuid

    set lines {}
    lappend lines [list Normal [mc "User"] "$tabuid(nom) $tabuid(prenom)"]
    foreach {txt key} {
			Login	login
			Mail	mel
			Phone	tel
			Mobile	mobile
			Fax	fax
			Address	adr
		    } {
	lappend lines [list Normal [mc $txt] $tabuid($key)]
    }
    return [::arrgen::output "html" $libconf(tabuser) $lines]
}

#
# Display group data in an HTML array
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- idgrp : group id
#   - global variables libconf(tab*) : array specification
# Output:
#   - return value: list of 7 HTML strings
#
# History
#   2002/05/23 : pda/jean : specification et design
#   2005/04/06 : pda      : add DHCP profiles
#   2007/10/23 : pda/jean : add users
#   2008/07/23 : pda/jean : add group permissions
#   2010/10/31 : pda      : add ttl permission
#   2010/11/03 : pda/jean : add equipment permissions
#   2010/11/30 : pda/jean : add mac permissions
#   2010/12/01 : pda      : i18n
#

proc display-group {dbfd idgrp} {
    global libconf

    #
    # Get specific permissions: admin, droitsmtp, droitttl and droitmac
    #

    set lines {}
    set sql "SELECT admin, droitsmtp, droitttl, droitmac
			FROM global.groupe
			WHERE idgrp = $idgrp"
    pg_select $dbfd $sql tab {
	if {$tab(admin)} then {
	    set admin [mc "yes"]
	} else {
	    set admin [mc "no"]
	}
	if {$tab(droitsmtp)} then {
	    set droitsmtp [mc "yes"]
	} else {
	    set droitsmtp [mc "no"]
	}
	if {$tab(droitttl)} then {
	    set droitttl [mc "yes"]
	} else {
	    set droitttl [mc "no"]
	}
	if {$tab(droitmac)} then {
	    set droitmac [mc "yes"]
	} else {
	    set droitmac [mc "no"]
	}
	lappend lines [list DROIT [mc "WebDNS administration"] $admin]
	lappend lines [list DROIT [mc "SMTP authorization management"] $droitsmtp]
	lappend lines [list DROIT [mc "TTL management"] $droitttl]
	lappend lines [list DROIT [mc "MAC module access"] $droitmac]
    }
    if {[llength $lines] > 0} then {
	set tabperm [::arrgen::output "html" $libconf(tabperm) $lines]
    } else {
	set tabperm [mc "Error on group permissions"]
    }

    #
    # Get the list of users in this group
    #

    set luser {}
    set sql "SELECT login FROM global.corresp WHERE idgrp=$idgrp ORDER BY login"
    pg_select $dbfd $sql tab {
	lappend luser [::webapp::html-string $tab(login)]
    }
    set tabuser [join $luser ", "]

    #
    # Get IP ranges allowed to the group
    #

    set lines {}
    set sql "SELECT r.idreseau,
			r.nom, r.localisation, r.adr4, r.adr6,
			d.dhcp, d.acl,
			e.nom AS etabl,
			c.nom AS commu
		FROM dns.reseau r, dns.dr_reseau d, dns.etablissement e, dns.communaute c
		WHERE d.idgrp = $idgrp
			AND d.idreseau = r.idreseau
			AND e.idetabl = r.idetabl
			AND c.idcommu = r.idcommu
		ORDER BY d.tri, r.adr4, r.adr6"
    pg_select $dbfd $sql tab {
	set r_nom 	[::webapp::html-string $tab(nom)]
	set r_loc	[::webapp::html-string $tab(localisation)]
	set r_etabl	$tab(etabl)
	set r_commu	$tab(commu)
	set r_dhcp	$tab(dhcp)
	set r_acl	$tab(acl)

	# dispaddr : used for a pleasant address formatting
	set dispaddr {}
	# where : part of the WHERE clause for address selection
	set where  {}
	foreach a {adr4 adr6} {
	    if {$tab($a) ne ""} then {
		lappend dispaddr $tab($a)
		lappend where "adr <<= '$tab($a)'"
	    }
	}
	set dispaddr [join $dispaddr ", "]
	set where [join $where " OR "]

	lappend lines [list Reseau $r_nom]
	lappend lines [list Normal4 [mc "Location"] $r_loc \
				[mc "Organization"] $r_etabl]
	lappend lines [list Normal4 [mc "Range"] $dispaddr \
				[mc "Community"] $r_commu]

	set perm {}

	set pnet {}
	if {$r_dhcp} then { lappend pnet "dhcp" }
	if {$r_acl} then { lappend pnet "acl" }
	if {[llength $pnet] > 0} then {
	    lappend perm [join $pnet ", "]
	}
	set sql2 "SELECT adr, allow_deny
			FROM dns.dr_ip
			WHERE ($where)
			    AND idgrp = $idgrp
			ORDER BY adr"
	pg_select $dbfd $sql2 tab2 {
	    if {$tab2(allow_deny)} then {
		set x "+"
	    } else {
		set x "-"
	    }
	    lappend perm "$x $tab2(adr)"
	}

	lappend lines [list Droits [mc "Permissions"] [join $perm "\n"]]
    }

    if {[llength $lines] > 0} then {
	set tabnetworks [::arrgen::output "html" $libconf(tabnetworks) $lines]
    } else {
	set tabnetworks [mc "No allowed network"]
    }

    #
    # Get IP permissions out of network ranges identified above.
    #

    set lines {}
    set found 0
    set sql "SELECT adr, allow_deny
		    FROM dns.dr_ip
		    WHERE NOT (adr <<= ANY (
				SELECT r.adr4
					FROM dns.reseau r, dns.dr_reseau d
					WHERE r.idreseau = d.idreseau
						AND d.idgrp = $idgrp
				UNION
				SELECT r.adr6
					FROM dns.reseau r, dns.dr_reseau d
					WHERE r.idreseau = d.idreseau
						AND d.idgrp = $idgrp
				    ) )
			AND idgrp = $idgrp
		    ORDER BY adr"
    set perm {}
    pg_select $dbfd $sql tab {
	set found 1
	if {$tab(allow_deny)} then {
	    set x "+"
	} else {
	    set x "-"
	}
	lappend perm "$x $tab(adr)"
    }
    lappend lines [list Droits [mc "Permissions"] [join $perm "\n"]]

    if {$found} then {
	set tabcidrnonet [::arrgen::output "html" $libconf(tabnetworks) $lines]
    } else {
	set tabcidrnonet [mc "None (it's all right)"]
    }

    #
    # Get domains
    #

    set lines {}
    set sql "SELECT domaine.nom AS nom, dr_dom.rolemail, dr_dom.roleweb \
			FROM dns.dr_dom, dns.domaine
			WHERE dr_dom.iddom = domaine.iddom \
				AND dr_dom.idgrp = $idgrp \
			ORDER BY dr_dom.tri, domaine.nom"
    pg_select $dbfd $sql tab {
	set rm ""
	if {$tab(rolemail)} then {
	    set rm [mc "Mail role management"]
	}
	set rw ""
	if {$tab(roleweb)} then {
	    set rw [mc "Web role management"]
	}

	lappend lines [list Domaine $tab(nom) $rm $rw]
    }
    if {[llength $lines] > 0} then {
	set tabdomains [::arrgen::output "html" $libconf(tabdomains) $lines]
    } else {
	set tabdomains [mc "No allowed domain"]
    }

    #
    # Get DHCP profiles
    #

    set lines {}
    set sql "SELECT p.nom, dr.tri, p.texte
			FROM dns.dhcpprofil p, dns.dr_dhcpprofil dr
			WHERE p.iddhcpprofil = dr.iddhcpprofil
				AND dr.idgrp = $idgrp
			ORDER BY dr.tri, p.nom"
    pg_select $dbfd $sql tab {
	lappend lines [list DHCP $tab(nom) $tab(texte)]
    }
    if {[llength $lines] > 0} then {
	set tabdhcpprofile [::arrgen::output "html" $libconf(tabdhcpprofile) $lines]
    } else {
	set tabdhcpprofile [mc "No allowed DHCP profile"]
    }

    #
    # Get equipment permissions
    #

    set lines {}
    foreach {rw text} [list 0 [mc "Read"] 1 [mc "Write"]] {
	set sql "SELECT allow_deny, pattern
			    FROM topo.dr_eq
			    WHERE idgrp = $idgrp AND rw = $rw
			    ORDER BY rw, allow_deny DESC, pattern"
	set perm ""
	pg_select $dbfd $sql tab {
	    if {$tab(allow_deny) eq "0"} then {
		set allow_deny "-"
	    } else {
		set allow_deny "+"
	    }
	    append perm "$allow_deny $tab(pattern)\n"
	}
	if {$perm eq ""} then {
	    set perm [mc "No permission"]
	}
	lappend lines [list DroitEq $text $perm]
    }
    set tabdreq [::arrgen::output "html" $libconf(tabdreq) $lines]

    #
    # Return informations
    #

    return [list    $tabperm \
		    $tabuser \
		    $tabnetworks \
		    $tabcidrnonet \
		    $tabdomains \
		    $tabdhcpprofile \
		    $tabdreq \
	    ]
}

##############################################################################
# Access to database
##############################################################################

#
# Initialize access to database
#
# Input:
#   - parameters:
#	- base : database connection parameters
#	- _msg : error message, if any
# Output:
#   - return value: database handle, or empty string if error
#
# History
#   2001/01/27 : pda      : design
#   2001/10/09 : pda      : use conninfo to access database
#   2010/11/29 : pda      : i18n
#

proc ouvrir-base {base _msg} {
    upvar $_msg msg
    global debug

    if {[catch {set dbfd [pg_connect -conninfo $base]} msg]} then {
	set dbfd ""
    }

    return $dbfd
}

#
# Shutdown database access
#
# Input:
#   - parameters:
#	- dbfd : database handle
# Output:
#   - return value: none
#
# History
#   2001/01/27 : pda      : design
#   2010/11/29 : pda      : i18n
#

proc fermer-base {dbfd} {
    pg_disconnect $dbfd
}

##############################################################################
# User access rights management
##############################################################################

#
# Search attributes associated to a user
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- idcor : user id
#	- attr : attribute to check (table column)
# Output:
#   - return value: information found
#
# History
#   2000/07/26 : pda      : design
#   2002/05/03 : pda/jean : use in webdns
#   2002/05/06 : pda/jean : groups
#   2010/11/29 : pda      : i18n
#

proc user-attribute {dbfd idcor attr} {
    set v 0
    set sql "SELECT groupe.$attr \
			FROM global.groupe, global.corresp \
			WHERE corresp.idcor = $idcor \
			    AND corresp.idgrp = groupe.idgrp"
    pg_select $dbfd $sql tab {
	set v "$tab($attr)"
    }
    return $v
}

#
# Read informations associated to a user
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- login : user login
#	- _tabuid : array containing, in return:
#		login	login of the user
#		nom	user name
#		prenom	user christian name
#		mel	user mail
#		tel	user phone
#		mobile	user mobile phone
#		fax	user fax
#		adr	user address
#		idcor	user id in the database
#		idgrp	group id in the database
#		groupe	group name
#		present	1 if "present" in the database
#		admin	1 if admin
#		droitsmtp 1 if permission to add hosts authorized to emit with SMTP
#		droitttl 1 if permission to edit host TTL
#		droitmac 1 if permission to use the MAC module
#		reseaux	list of authorized networks
#		eq	regexp matching authorized equipments
#		flagsr	flags -n/-e/-E/etc to use in topo programs
#		flagsw	flags -n/-e/-E/etc to use in topo programs
# Output:
#   - return value: -1 if error, or number of found entries
#   - parameter _tabuid : values in return
#   - parameter _msg : empty string (if return == 1) or message (if return != 1)
#
# History
#   2003/05/13 : pda/jean : design
#   2007/10/05 : pda/jean : adaptation to "authuser" and "authbase" objects
#   2010/11/09 : pda      : renaming (car plus de recherche par id)
#   2010/11/29 : pda      : i18n
#

proc read-user {dbfd login _tabuid _msg} {
    global ah
    upvar $_tabuid tabuid
    upvar $_msg msg

    catch {unset tabuid}

    #
    # Attributes common to all applications
    #

    set u [::webapp::authuser create %AUTO%]
    if {[catch {set n [$ah getuser $login $u]} m]} then {
	set msg [format [mc "Authentication base problem: %s"] $m]
	return -1
    }
    
    switch $n {
	0 {
	    set msg [format [mc "User '%s' is not in the authentication base"] $login]
	    return 0
	}
	1 { 
	    set msg ""
	}
	default {
	    set msg [format [mc "Found more than one entry for login '%s' in the authentication base"] $login]
	    return $n
	}
    }

    foreach c {login password nom prenom mel tel mobile fax adr} {
	set tabuid($c) [$u get $c]
    }

    $u destroy

    #
    # WebDNS specific characteristics
    #

    set qlogin [::pgsql::quote $login]
    set tabuid(idcor) -1
    set sql "SELECT * FROM global.corresp, global.groupe
			WHERE corresp.login = '$qlogin'
			    AND corresp.idgrp = groupe.idgrp"
    pg_select $dbfd $sql tab {
	set tabuid(idcor)	$tab(idcor)
	set tabuid(idgrp)	$tab(idgrp)
	set tabuid(present)	$tab(present)
	set tabuid(groupe)	$tab(nom)
	set tabuid(admin)	$tab(admin)
	set tabuid(droitsmtp)	$tab(droitsmtp)
	set tabuid(droitttl)	$tab(droitttl)
	set tabuid(droitmac)	$tab(droitmac)
    }

    if {$tabuid(idcor) == -1} then {
	set msg [format [mc "User '%s' is not in the WebDNS base"] $login]
	return -1
    }

    #
    # Topo specific characteristics
    #

    # Read authorized CIDR
    set tabuid(reseaux) [allowed-networks $dbfd $tabuid(idgrp) "consult"]

    # Read regexp to allow or deny access to equipments
    set tabuid(eqr) [read-authorized-eq $dbfd 0 $tabuid(idgrp)]
    set tabuid(eqw) [read-authorized-eq $dbfd 1 $tabuid(idgrp)]

    # Build flags to restrict graph to a subset according to
    # user rights.
    set flagsr {}
    set flagsw {}
    foreach rw {r w} {
	set flags {}
	if {$tabuid(admin)} then {
	    # Administrator sees the whole graph
	    lappend flags "-a"

	    # Even if he sees the whole graph, administrator has not
	    # the right to modify non terminal interfaces
	    if {$rw eq "w"} then {
		lappend flags "-t"
	    }

	} else {
	    lassign $tabuid(eq$rw) lallow ldeny

	    # Build networks rights first: the user has access to
	    # all interfaces that "his" networks reach (except if
	    # has no right on an equipment)
	    foreach r $tabuid(reseaux) {
		set r4 [lindex $r 1]
		if {$r4 ne ""} then {
		    lappend flags "-n" $r4
		}
		set r6 [lindex $r 2]
		if {$r6 ne ""} then {
		    lappend flags "-n" $r6
		}
	    }

	    # Next, build access rights on equipements (part 1)
	    # The user has access to the whole equipment (including
	    # interfaces)
	    foreach pat $lallow {
		lappend flags "-e" $pat
	    }

	    # Next, build access rights on equipements (part 2)
	    # The user has no access to the whole equipment, even
	    # if some parts (equipement or interfaces reached by
	    # a network) have been selected previously).
	    foreach pat $ldeny {
		lappend flags "-E" $pat
	    }

	    # Last, the user don't have right to modify:
	    # - non terminal interfaces
	    # - interfaces which transport a foreign network
	    if {$rw eq "w"} then {
		lappend flags "-t" "-m"
	    }
	}
	set tabuid(flags$rw) [join $flags " "]
    }

    return 1
}

##############################################################################
# Database management : resources records
##############################################################################

#
# Get all informations associated with a name
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- name : name to search for
#	- iddom : id of the domain in which to search for the name
#	- _trr : empty array
# Output:
#   - return value: 1 if ok, 0 if not found
#   - _trr parameter : see read-rr-by-id
#
# History
#   2002/04/11 : pda/jean : design
#   2002/04/19 : pda/jean : add name and iddom
#   2002/04/19 : pda/jean : use read-rr-by-id
#   2010/11/29 : pda      : i18n
#

proc read-rr-by-name {dbfd name iddom _trr} {
    upvar $_trr trr

    set qname [::pgsql::quote $name]
    set found 0
    set sql "SELECT idrr FROM dns.rr WHERE nom = '$qname' AND iddom = $iddom"
    pg_select $dbfd $sql tab {
	set found 1
	set idrr $tab(idrr)
    }

    if {$found} then {
	set found [read-rr-by-id $dbfd $idrr trr]
    }

    return $found
}

#
# Get all informations associated with a RR given by one of its IP address
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- addr : address to search for
#	- _trr : empty array
# Output:
#   - return value: 1 if ok, 0 if not found
#   - _trr parameter : see read-rr-by-id
#
# Note: the given address is supposed to be syntaxically correct.
#
# History
#   2002/04/26 : pda/jean : design
#   2010/11/29 : pda      : i18n
#

proc read-rr-by-ip {dbfd addr _trr} {
    upvar $_trr trr

    set found 0
    set sql "SELECT idrr FROM dns.rr_ip WHERE adr = '$addr'"
    pg_select $dbfd $sql tab {
	set found 1
	set idrr $tab(idrr)
    }

    if {$found} then {
	set found [read-rr-by-id $dbfd $idrr trr]
    }

    return $found
}

#
# Get all informations associated with a RR.
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- idrr : RR id to search for
#	- _trr : empty array
# Output:
#   - return value: 1 if ok, 0 if not found
#   - parameter _trr :
#	_trr(idrr) : id of RR found
#	_trr(nom) : name (first component of the FQDN)
#	_trr(iddom) : domain id
#	_trr(domaine) : domain name
#	_trr(mac) : MAC address
#	_trr(iddhcpprofil) : DHCP profile id, or 0 if none
#IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
#	_trr(dhcpprofil) : DHCP profile name, or "Aucun profil DHCP"
#	_trr(idhinfo) : machine info id
#	_trr(hinfo) : machine info text
#	_trr(droitsmtp) : 1 if host has the right to emit with non auth SMTP
#	_trr(ttl) : TTL of the host (for all its IP addresses)
#	_trr(commentaire) : comments
#	_trr(respnom) : name of the responsible person
#	_trr(respmel) : mail of the responsible person
#	_trr(idcor) : id of user who has done the last modification
#	_trr(date) : date of last modification
#	_trr(ip) : list of all IP adresses
#	_trr(mx) : MX list {{prio idrr} {prio idrr} ...}
#	_trr(cname) : id of pointed RR, if the name is an alias
#	_trr(aliases) : list of ids of all RR pointing to this object
#IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
#	_trr(rolemail) : id of herbegeur
#IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
#	_trr(adrmail) : idrr of mail addresses hosted on this host
#IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
#	_trr(roleweb) : 1 si role web pour ce rr
#
# History
#   2002/04/19 : pda/jean : design
#   2002/06/02 : pda/jean : hinfo becomes an index in a table
#   2004/02/06 : pda/jean : add rolemail, adrmail and roleweb
#   2004/08/05 : pda/jean : simplification and add mac
#   2005/04/08 : pda/jean : add dhcpprofil
#   2008/07/24 : pda/jean : add droitsmtp
#   2010/10/31 : pda      : add ttl
#   2010/11/29 : pda      : i18n
#

proc read-rr-by-id {dbfd idrr _trr} {
    upvar $_trr trr

    set fields {nom iddom
	mac iddhcpprofil idhinfo droitsmtp ttl commentaire respnom respmel
	idcor date}

    catch {unset trr}
    set trr(idrr) $idrr

    set found 0
    set columns [join $fields ", "]
    set sql "SELECT $columns FROM dns.rr WHERE idrr = $idrr"
    pg_select $dbfd $sql tab {
	set found 1
	foreach v $fields {
	    set trr($v) $tab($v)
	}
    }

    if {$found} then {
	set trr(domaine) ""
	if {$trr(iddhcpprofil) eq ""} then {
	    set trr(iddhcpprofil) 0
	    set trr(dhcpprofil) [mc "No profile"]
	} else {
	    set sql "SELECT nom FROM dns.dhcpprofil
				WHERE iddhcpprofil = $trr(iddhcpprofil)"
	    pg_select $dbfd $sql tab {
		set trr(dhcpprofil) $tab(nom)
	    }
	}
	set sql "SELECT texte FROM dns.hinfo WHERE idhinfo = $trr(idhinfo)"
	pg_select $dbfd $sql tab {
	    set trr(hinfo) $tab(texte)
	}
	set sql "SELECT nom FROM dns.domaine WHERE iddom = $trr(iddom)"
	pg_select $dbfd $sql tab {
	    set trr(domaine) $tab(nom)
	}
	set trr(ip) {}
	pg_select $dbfd "SELECT adr FROM dns.rr_ip WHERE idrr = $idrr" tab {
	    lappend trr(ip) $tab(adr)
	}
	set trr(mx) {}
	pg_select $dbfd "SELECT priorite,mx FROM dns.rr_mx WHERE idrr = $idrr" tab {
	    lappend trr(mx) [list $tab(priorite) $tab(mx)]
	}
	set trr(cname) ""
	pg_select $dbfd "SELECT cname FROM dns.rr_cname WHERE idrr = $idrr" tab {
	    set trr(cname) $tab(cname)
	}
	set trr(aliases) {}
	pg_select $dbfd "SELECT idrr FROM dns.rr_cname WHERE cname = $idrr" tab {
	    lappend trr(aliases) $tab(idrr)
	}
	set trr(rolemail) ""
	pg_select $dbfd "SELECT heberg FROM dns.role_mail WHERE idrr = $idrr" tab {
	    set trr(rolemail) $tab(heberg)
	}
	set trr(adrmail) {}
	pg_select $dbfd "SELECT idrr FROM dns.role_mail WHERE heberg = $idrr" tab {
	    lappend trr(adrmail) $tab(idrr)
	}
	set trr(roleweb) 0
	pg_select $dbfd "SELECT 1 FROM dns.role_web WHERE idrr = $idrr" tab {
	    set trr(roleweb) 1
	}
    }

    return $found
}

#
# Delete an RR given its id
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- idrr : id of RR to delete
#	- _msg : error message in return
# Output:
#   - return value: 1 if ok, 0 if error
#   - parameter _msg : error message if any
#
# History
#   2002/04/19 : pda/jean : design
#   2010/11/29 : pda      : i18n
#

proc del-rr-by-id {dbfd idrr _msg} {
    upvar $_msg msg

    set sql "DELETE FROM dns.rr WHERE idrr = $idrr"
    return [::pgsql::execsql $dbfd $sql msg]
}

#
# Delete an alias
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- idrr : id of RR to delete (CNAME RR)
#	- _msg : error message in return
# Output:
#   - return value: 1 if ok, 0 if error
#   - parameter _msg : error message if any
#
# History
#   2002/04/19 : pda/jean : design
#   2010/11/29 : pda      : i18n
#

proc del-alias-by-id {dbfd idrr _msg} {
    upvar $_msg msg

    set ok 0
    set sql "DELETE FROM dns.rr_cname WHERE idrr = $idrr"
    if {[::pgsql::execsql $dbfd $sql msg]} then {
	if {[del-rr-by-id $dbfd $idrr msg]} then {
	    set ok 1
	}
    }
    return $ok
}

#
# Delete an IP address
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- idrr : RR id
#	- addr : address to delete
#	- _msg : error message in return
# Output:
#   - return value: 1 if ok, 0 if error
#   - parameter _msg : error message if any
#
# History
#   2002/04/19 : pda/jean : design
#   2010/11/29 : pda      : i18n
#

proc del-ip-address {dbfd idrr addr _msg} {
    upvar $_msg msg

    set ok 0
    set sql "DELETE FROM dns.rr_ip WHERE idrr = $idrr AND adr = '$addr'"
    if {[::pgsql::execsql $dbfd $sql msg]} then {
	set ok 1
    }
    return $ok
}

#
# Delet all MX associated with an RR
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- idrr : RR id of MX
#	- _msg : error message in return
# Output:
#   - return value: 1 if ok, 0 if error
#   - parameter _msg : error message if any
#
# History
#   2002/04/19 : pda/jean : design
#   2010/11/29 : pda      : i18n
#

proc del-mx-by-id {dbfd idrr _msg} {
    upvar $_msg msg

    set ok 0
    set sql "DELETE FROM dns.rr_mx WHERE idrr = $idrr"
    if {[::pgsql::execsql $dbfd $sql msg]} then {
	set ok 1
    }
    return $ok
}

#
# Delete a rolemail
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- idrr : RR id
#	- _msg : error message in return
# Output:
#   - return value: 1 if ok, 0 if error
#   - parameter _msg : error message if any
#
# History
#   2004/02/06 : pda/jean : design
#   2010/11/29 : pda      : i18n
#

proc del-rolemail-by-id {dbfd idrr _msg} {
    upvar $_msg msg

    set ok 0
    set sql "DELETE FROM dns.role_mail WHERE idrr = $idrr"
    if {[::pgsql::execsql $dbfd $sql msg]} then {
	set ok 1
    }
    return $ok
}

#
# XXX : NOT USED
#
# Delete a roleweb
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- idrr : RR id
#	- _msg : error message in return
# Output:
#   - return value: 1 if ok, 0 if error
#   - parameter _msg : error message if any
#
# History
#   2004/02/06 : pda/jean : design
#   2010/11/29 : pda      : i18n
#

proc del-roleweb-by-id {dbfd idrr _msg} {
    upvar $_msg msg

    set ok 0
    set sql "DELETE FROM dns.role_web WHERE idrr = $idrr"
    if {[::pgsql::execsql $dbfd $sql msg]} then {
	set ok 1
    }
    return $ok
}

#
# Deleta an RR and all associated dependancies
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- _trr : RR informations (see read-rr-by-id)
#	- _msg : error message in return
# Output:
#   - return value: 1 if ok, 0 if error
#   - parameter _msg : error message if any
#
# History
#   2002/04/19 : pda/jean : design
#   2004/02/06 : pda/jean : add rolemail and roleweb
#   2010/11/29 : pda      : i18n
#

proc del-rr-and-dependancies {dbfd _trr _msg} {
    upvar $_trr trr
    upvar $_msg msg

    set idrr $trr(idrr)

    #
    # If this host holds mail addresses, don't delete it.
    #

    if {[llength $trr(adrmail)] > 0} then {
	set msg "This host holds mail addresses"
	return 0
    }

    #
    # Delete roles pointing to this host (and not names which
    # are other things such as mail domains)
    #

    if {! [del-roleweb-by-id $dbfd $idrr msg]} then {
	return 0
    }

    #
    # Delete all aliases pointing to this object
    #

    foreach a $trr(aliases) {
	if {! [del-alias-by-id $dbfd $a msg]} then {
	    return 0
	}
    }

    #
    # Delete all IP addresses
    #

    foreach a $trr(ip) {
	if {! [del-ip-address $dbfd $idrr $a msg]} then {
	    return 0
	}
    }

    #
    # Delete all MX
    #

    if {! [del-mx-by-id $dbfd $idrr msg]} then {
	return 0
    }

    #
    # Delete the RR itself (if possible)
    #

    set msg [del-orphaned-rr $dbfd $idrr]
    if {$msg ne ""} then {
	return 0
    }

    #
    # Finished !
    #

    return 1
}

#
# Delete an RR if nothing points to it (IP address, alias, mail domain, etc.)
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- idrr : RR id
# Output:
#   - return value: empty string or error message
#
# Note : if the RR is not an orphaned one, it is not delete and
#	an empty string is returned (it is a normal case, not an error).
#
# History
#   2004/02/13 : pda/jean : design
#   2010/11/29 : pda      : i18n
#

proc del-orphaned-rr {dbfd idrr} {
    set msg ""
    if {[read-rr-by-id $dbfd $idrr trr]} then {
	set orphaned 1
	foreach x {ip mx aliases rolemail adrmail} {
	    if {$trr($x) ne ""} then {
		set orphaned 0
		break
	    }
	}
	if {$orphaned && $trr(roleweb)} then {
	    set orphaned 0
	}

	if {$orphaned} then {
	    if {[del-rr-by-id $dbfd $trr(idrr) msg]} then {
		# it worked, but this function may have modified "msg"
		set msg ""
	    }
	}
    }
    return $msg
}

#
# Add a new RR
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- name : name of RR to create (syntax must be conform to RFC)
#	- iddom : domain id
#	- mac : MAC address, or empty string
#	- iddhcpprofil : DHCP profile id, or 0
#	- idhinfo : HINFO or empty string (default is searched in the database)
#	- droitsmtp : 1 if ok to emit with non auth SMTP
#	- ttl : TTL value, or -1 for default value
#	- comment : commment
#	- respnom : responsible person name
#	- respmel : responsible person mail
#	- idcor : user id
#	- _trr : in return, will contain RR information
# Output:
#   - return value: empty string, or error message
#   - parameter _trr : see read-rr-by-id
#
# Warning: name syntax is supposed to be valid. Do not forget to call
#	check-name-syntax before calling this function.
#
# History
#   2004/02/13 : pda/jean : design
#   2004/08/05 : pda/jean : add mac
#   2004/10/05 : pda      : change date format
#   2005/04/08 : pda/jean : add dhcpprofil
#   2008/07/24 : pda/jean : add droitsmtp
#   2010/10/31 : pda      : add ttl
#   2010/11/29 : pda      : i18n
#

proc add-rr {dbfd name iddom mac iddhcpprofil idhinfo droitsmtp ttl
				comment respnom respmel idcor _trr} {
    upvar $_trr trr

    if {$mac eq ""} then {
	set qmac NULL
    } else {
	set qmac "'[::pgsql::quote $mac]'"
    }
    set qcomment [::pgsql::quote $comment]
    set qrespnom [::pgsql::quote $respnom]
    set qrespmel [::pgsql::quote $respmel]
    set hinfodef ""
    set hinfoval ""
    if {$idhinfo ne ""} then {
	set hinfodef "idhinfo,"
	set hinfoval "$idhinfo, "
    }
    if {$iddhcpprofil == 0} then {
	set iddhcpprofil NULL
    }
    set sql "INSERT INTO dns.rr
		    (nom, iddom, mac, iddhcpprofil, $hinfodef
			droitsmtp, ttl, commentaire, respnom, respmel,
			idcor)
		VALUES
		    ('$name', $iddom, $qmac, $iddhcpprofil, $hinfoval
			$droitsmtp, $ttl, '$qcomment', '$qrespnom', '$qrespmel',
			$idcor)
		    "
    if {[::pgsql::execsql $dbfd $sql msg]} then {
	set msg ""
	if {! [read-rr-by-name $dbfd $name $iddom trr]} then {
	    set msg [format [mc "Internal error: '%s' inserted, but not found in database"] \
			    $name]

	}
    } else {
	set msg [format [mc "RR addition impossible: %s"] $msg]
    }
    return $msg
}

#
# Update date and user id when a RR is modified
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- idrr : RR id
# Output:
#   - return value: empty string or error message
#
# History
#   2002/05/03 : pda/jean : design
#   2004/10/05 : pda      : change date format
#   2010/11/13 : pda      : use effective uid
#   2010/11/29 : pda      : i18n
#

proc touch-rr {dbfd idrr} {
    set date [clock format [clock seconds]]
    set idcor [lindex [d euid] 1]
    set sql "UPDATE dns.rr SET idcor = $idcor, date = '$date' WHERE idrr = $idrr"
    if {[::pgsql::execsql $dbfd $sql msg]} then {
       set msg ""
    } else {
	set msg [format [mc "RR update impossible: %s"] $msg]
    }
    return $msg
}

#
# Display a RR with HTML
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- idrr : RR id to search for, or -1 if _trr is already initialized
#	- _trr : empty array, or initialized array (id idrr=-1)
# Output:
#   - return value: empty string or error message
#   - parameter _trr : see read-rr-by-id
#   - global variables :
#	- libconf(tabmachine) : array specification
#
# History
#   2008/07/25 : pda/jean : design
#   2010/10/31 : pda      : ajout ttl
#   2010/11/29 : pda      : i18n
#

proc display-rr {dbfd idrr _trr} {
    global libconf
    upvar $_trr trr

    #
    # Read RR if needed
    #

    if {$idrr != -1 && [read-rr-by-id $dbfd $idrr trr] == -1} then {
	return ""
    }

    #
    # Display all fields
    #

    set lines {}

    # name
    lappend lines [list Normal [mc "Name"] "$trr(nom).$trr(domaine)"]

    # IP address(es)
    switch [llength $trr(ip)] {
	0 {
	    set at [mc "IP address"]
	    set aa [mc "(none)"]
	}
	1 {
	    set at [mc "IP address"]
	    set aa $trr(ip)
	}
	default {
	    set at [mc "IP addresses"]
	    set aa $trr(ip)
	}
    }
    lappend lines [list Normal $at $aa]

    # MAC address
    lappend lines [list Normal [mc "MAC address"] $trr(mac)]

    # DHCP profile
    lappend lines [list Normal [mc "DHCP profile"] $trr(dhcpprofil)]

    # Machine type
    lappend lines [list Normal [mc "Type"] $trr(hinfo)]

    # Right to emit with non auth SMTP : display only if it is used
    # (i.e. if there is at least one group wich owns this right)
    set sql "SELECT COUNT(*) AS ndroitsmtp FROM global.groupe WHERE droitsmtp = 1"
    set ndroitsmtp 0
    pg_select $dbfd $sql tab {
	set ndroitsmtp $tab(ndroitsmtp)
    }
    if {$ndroitsmtp > 0} then {
	if {$trr(droitsmtp)} then {
	    set droitsmtp [mc "Yes"]
	} else {
	    set droitsmtp [mc "No"]
	}
	lappend lines [list Normal [mc "SMTP emit right"] $droitsmtp]
    }

    # TTL : display only if it used
    # (i.e. if there is at least one group wich owns this right and there
    # is a value)
    set sql "SELECT COUNT(*) AS ndroitttl FROM global.groupe WHERE droitttl = 1"
    set ndroitttl 0
    pg_select $dbfd $sql tab {
	set ndroitttl $tab(ndroitttl)
    }
    if {$ndroitttl > 0} then {
	set ttl $trr(ttl)
	if {$ttl != -1} then {
	    lappend lines [list Normal [mc "TTL"] $ttl]
	}
    }

    # comment
    lappend lines [list Normal [mc "Comment"] $trr(commentaire)]

    # responsible (name)
    lappend lines [list Normal [mc "Responsible (name)"] $trr(respnom)]

    # responsible (mail)
    lappend lines [list Normal [mc "Responsible (mail)"] $trr(respmel)]

    # aliases
    set la {}
    foreach idalias $trr(aliases) {
	if {[read-rr-by-id $dbfd $idalias ta]} then {
	    lappend la "$ta(nom).$ta(domaine)"
	}
    }
    if {[llength $la] > 0} then {
	lappend lines [list Normal [mc "Aliases"] [join $la " "]]
    }

    set html [::arrgen::output "html" $libconf(tabmachine) $lines]
    return $html
}

##############################################################################
# Syntax check
##############################################################################

#
# Check FQDN syntax according to RFC 1035.
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- fqdn : name to test
#	- _name : host name in return
#	- _domain : host domain in return
#	- _iddom : domain id in return
# Output:
#   - return value: empty string or error message
#   - parameter _name : host name found
#   - parameter _domain : host domain found
#   - parameter _iddom : domain id found, or -1 if error
#
# History
#   2004/09/21 : pda/jean : design
#   2004/09/29 : pda/jean : add _domain parameter
#   2010/11/29 : pda      : i18n
#

proc check-fqdn-syntax {dbfd fqdn _name _domain _iddom} {
    upvar $_name name
    upvar $_domain domain
    upvar $_iddom iddom

    if {! [regexp {^([^\.]+)\.(.*)$} $fqdn bidon name domain]} then {
	return [format [mc "Invalid FQDN '%s'"] $fqdn]
    }

    set msg [check-name-syntax $name]
    if {$msg ne ""} then {
	return $msg
    }

    set iddom [read-domain $dbfd $domain]
    if {$iddom < 0} then {
	return [format [mc "Invalid domain '%s'"] $domain]
    }

    return ""
}

#
# Check host name syntax (first part of a FQDN) according to RFC 1035
#
# Input:
#   - parameters:
#	- name : name to test
# Output:
#   - return value: empty string or error message
#
# History
#   2002/04/11 : pda/jean : design
#   2010/11/29 : pda      : i18n
#

proc check-name-syntax {name} {
    # general case: a letter-or-digit at the beginning, a letter-or-digit
    # at the end (minus forbidden at the end) and letter-or-digit-or-minus
    # between.
    set re1 {[a-zA-Z0-9][-a-zA-Z0-9]*[a-zA-Z0-9]}
    # particular case: only one letter
    set re2 {[a-zA-Z0-9]}

    if {[regexp "^$re1$" $name] || [regexp "^$re2$" $name]} then {
	set msg ""
    } else {
	set msg [format [mc "Invalid name '%s'"] $name]
    }

    return $msg
}

#
# Check IP address (IPv4 or IPv6) syntax
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- addr : address to test
#	- type : "inet", "cidr", "loosecidr", "macaddr", "inet4", "cidr4"
# Output:
#   - return value: empty string or error message
#
# Note :
#   - type "cidr" is strict, "host" bits must be 0 (i.e.: "1.1.1.0/24"
#	is valid, but not "1.1.1.1/24")
#   - type "loosecidr" accepts "host" bits set to 1
#
# History
#   2002/04/11 : pda/jean : design
#   2002/05/06 : pda/jean : add type cidr
#   2002/05/23 : pda/jean : accept simplified cidr (a.b/x)
#   2004/01/09 : pda/jean : add IPv6 et radical simplification
#   2004/10/08 : pda/jean : add inet4
#   2004/10/20 : jean     : forbid / for anything else than cidr type
#   2008/07/22 : pda      : add type loosecidr (accepts /)
#   2010/10/07 : pda      : add type cidr4
#

proc check-ip-syntax {dbfd addr type} {

    switch $type {
	inet4 {
	    set cast "inet"
	    set fam  4
	}
	cidr4 {
	    set cast "cidr"
	    set type "cidr"
	    set fam  4
	}
	loosecidr {
	    set cast "inet"
	    set fam ""
	}
	default {
	    set cast $type
	    set fam ""
	}
    }
    set addr [::pgsql::quote $addr]
    set sql "SELECT $cast\('$addr'\) ;"
    set r ""
    if {[::pgsql::execsql $dbfd $sql msg]} then {
	if {$fam ne ""} then {
	    pg_select $dbfd "SELECT family ('$addr') AS fam" tab {
		if {$tab(fam) != $fam} then {
		    set r [format [mc {'%1$s' is not a valid IPv%2$s address}] $addr $fam]
		}
	    }
	}
	if {! ($type eq "cidr" || $type eq "loosecidr")} then {
	    if {[regexp {/}  $addr ]} then {
		set r [format [mc "The '/' character is not valid in the address '%s'"] $addr]
	    }
	}
    } else {
	set r [format [mc "Invalid syntax for '%s'"] $addr]
    }
    return $r
}

#
# Check MAC address syntax
#
# Input:
#   - parameters:
#	- addr : address to test
# Output:
#   - return value: empty string or error message
#
# History
#   2004/08/04 : pda/jean : design
#   2010/11/29 : pda      : i18n
#

proc check-mac-syntax {dbfd mac} {
    return [check-ip-syntax $dbfd $mac "macaddr"]
}

#
# XXX : NOT USED
#
# Check a DHCP profile id
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- iddhcpprofil : id of DHCP profile, or 0
#	- _dhcpprofil : variable contenant en retour le nom du profil
#	- _msgvar : in return : error message
# Output:
#   - return value: 1 if ok, 0 if error
#   - _dhcpprofil : name of found profile (or "No profile")
#   - _msg : error message, if any
#
# History
#   2005/04/08 : pda/jean : design
#   2010/11/29 : pda      : i18n
#

proc check-iddhcpprofil {dbfd iddhcpprofil _dhcpprofil _msg} {
    upvar $_dhcpprofil dhcpprofil
    upvar $_msg msg

    set msg ""

    if {! [regexp -- {^[0-9]+$} $iddhcpprofil]} then {
	set msg [mc "Invalid syntax for DHCP profile"]
    } else {
	if {$iddhcpprofil != 0} then {
	    set sql "SELECT nom FROM dns.dhcpprofil
				WHERE iddhcpprofil = $iddhcpprofil"
	    set msg "Profil DHCP invalide ($iddhcpprofil)"
	    pg_select $dbfd $sql tab {
		set dhcpprofil $tab(nom)
		set msg ""
	    }
	} else {
	    set dhcpprofil [mc "No profile"]
	}
    }

    return [string equal $msg ""]
}

##############################################################################
# Domain validation
##############################################################################

#
# Search for a domain name in the database
#
# Input:
#   - parameters:
#       - dbfd : database handle
#	- domain : domain to search (not terminated by a ".")
# Output:
#   - return value: id of domain if found, -1 if not found
#
# History
#   2002/04/11 : pda/jean : design
#   2010/11/29 : pda      : i18n
#

proc read-domain {dbfd domain} {
    set domain [::pgsql::quote $domain]
    set iddom -1
    pg_select $dbfd "SELECT iddom FROM dns.domaine WHERE nom = '$domain'" tab {
	set iddom $tab(iddom)
    }
    return $iddom
}

#
# Checks if the domain is authorized for this user
#
# Input:
#   - parameters:
#       - dbfd : database handle
#	- idcor : user id
#	- _iddom : domain id or -1 to read from domain
#	- _domain : domain, or "" to read from iddom
#	- roles : roles to test (column names in dr_dom)
# Output:
#   - return value: empty string or error message
#   - parameters _iddom and _domain : fetched values
#
# History
#   2002/04/11 : pda/jean : design
#   2002/05/06 : pda/jean : use groups
#   2004/02/06 : pda/jean : add roles
#   2010/11/29 : pda      : i18n
#

proc check-domain {dbfd idcor _iddom _domain roles} {
    upvar $_iddom iddom
    upvar $_domain domain

    set msg ""

    #
    # Read domain if needed
    #
    if {$iddom == -1} then {
	set iddom [read-domain $dbfd $domain]
	if {$iddom == -1} then {
	    set msg [format [mc "Domain '%s' not found"] $domain]
	}
    } elseif {$domain eq ""} then {
	set sql "SELECT domaine FROM dns.domaine WHERE iddom = $iddom"
	pg_select $dbfd $sql tab {
	    set domain $tab(domaine)
	}
	if {$domain eq ""} then {
	    set msg [format [mc "Domain-id '%s' not found"] $iddom]
	}
    }

    #
    # Check if we have rights on this domain
    #
    if {$msg eq ""} then {
	set where ""
	foreach r $roles {
	    append where "AND dr_dom.$r > 0 "
	}

	set found 0
	set sql "SELECT dr_dom.iddom FROM dns.dr_dom, global.corresp
			    WHERE corresp.idcor = $idcor
				    AND corresp.idgrp = dr_dom.idgrp
				    AND dr_dom.iddom = $iddom
				    $where
				    "
	pg_select $dbfd $sql tab {
	    set found 1
	}
	if {! $found} then {
	    set msg [format [mc "You don't have rights on domain '%s'"] $domain]
	}
    }

    return $msg
}

#
# Check if the IP address is authorized for this user
#
# Input:
#   - parameters:
#       - dbfd : database handle
#	- idcor : user id
#	- addr : IP address to test
# Output:
#   - return value: 1 if ok, 0 if error
#
# History
#   2002/04/11 : pda/jean : design
#   2002/05/06 : pda/jean : use groups
#   2004/01/14 : pda/jean : add IPv6
#   2010/11/29 : pda      : i18n
#

proc check-authorized-ip {dbfd idcor adr} {
    set r 0
    set sql "SELECT valide_ip_cor ('$adr', $idcor) AS ok"
    pg_select $dbfd $sql tab {
	set r [string equal $tab(ok) "t"]
    }
    return $r
}

#
# Check if the user has adequate rights to a machine, by checking
# that he own all IP addresses
#
# Input:
#   - parameters:
#       - dbfd : database handle
#	- idcor : user id
#	- idrr : RR id to search for, or -1 if _trr is already initialized
#	- _trr : see read-rr-by-name
# Output:
#   - return value: 1 if ok, 0 if error
#
# History
#   2002/04/19 : pda/jean : design
#   2010/11/29 : pda      : i18n
#

proc check-name-by-addresses {dbfd idcor idrr _trr} {
    upvar $_trr trr

    set ok 1

    #
    # Read RR if needed
    #

    if {$idrr != -1 && [read-rr-by-id $dbfd $idrr trr] == -1} then {
	set trr(ip) {}
	set ok 1
    }

    #
    # Check all addresses
    #

    foreach ip $trr(ip) {
	if {! [check-authorized-ip $dbfd $idcor $ip]} then {
	    set ok 0
	    break
	}
    }

    return $ok
}

#
# Check if the user as the right to add/modify/delete a given name
# according to a given context.
#
# Input:
#   - parameters:
#       - dbfd : database handle
#	- idcor : user id
#	- name : name to test (first component of FQDN)
#	- domain : domain to test (the n-1 last components of FQDN)
#	- trr : in return, information on the host (see read-rr-by-id)
#	- context : the context to check
# Output:
#   - return value: empty string or error message
#   - parameter trr : contains informations on the RR found, or if the RR
#	doesn't exist, trr(idrr) = "" and trr(iddom) = domain id
#
# Detail of tests:
#    According to context:
#	"host"
#	    check-domain (domain, idcor, "")
#	    if name.domain is ALIAS then error
#	    if name.domain is MX then error
#	    if name.domain is ADDRMAIL
#		then check-all-IP-addresses (mail host, idcor)
#		      check-domain (domain, idcor, "")
#	    if name.domain has IP addresses
#		then check-all-IP-addresses (machine, idcor)
#	    if no test is false, then OK
#	"existing-host"
#	    identical to "host", but the name must be have at least one IP address
#	"del-name"
#	    check-domain (domain, idcor, "")
#	    if name.domain is ALIAS
#		then check-all-IP-addresses (pointed host, idcor)
#	    if name.domain is MX then error
#	    if name.domain has IP addresses
#		then check-all-IP-addresses (machine, idcor)
#	    if name.domain is ADDRMAIL
#		then check-all-IP-addresses (mail host, idcor)
#		      check-domain (domain, idcor, "")
#	    if no test is false, then OK
#	"alias"
#	    check-domain (domain, idcor, "")
#	    if name.domain is ALIAS then error
#	    if name.domain is MX then error
#	    if name.domain is ADDRMAIL then error
#	    if name.domain has IP addresses then error
#	    if no test is false, then OK
#	"mx"
#	    check-domain (domain, idcor, "")
#	    if name.domain is ALIAS then error
#	    if name.domain is MX
#		then check-all-IP-addresses (mail exchangers, idcor)
#	    if name.domain is ADDRMAIL then error
#	    if no test is false, then OK
#	"addrmail"
#	    check-domain (domain, idcor, "rolemail")
#	    if name.domain is ALIAS then error
#	    if name.domain is MX then error
#	    if name.domain is ADDRMAIL
#		check-all-IP-addresses (mail host, idcor)
#		      check-domain (domain, idcor, "")
#	    if name.domain is HEBERGEUR
#		check that is does not hold mail for another host besides itself
#	    if name.domain has IP addresses
#		check-all-IP-addresses (name.domain, idcor)
#	    if no test is false, then OK
#
#    check-IP-addresses (host, idcor)
#	if there is no address
#	    then error
#	    else check that all IP addresses are mine (with an AND)
#	end if
#
# History
#   2004/02/27 : pda/jean : specification
#   2004/02/27 : pda/jean : coding
#   2004/03/01 : pda/jean : use trr(iddom) instead of iddom
#   2010/11/29 : pda      : i18n
#

proc check-authorized-host {dbfd idcor name domain _trr context} {
    upvar $_trr trr

    array set testrights {
	host	{
		    {domain	{}}
		    {alias	REJECT}
		    {mx		REJECT}
		    {ip		CHECK}
		    {addrmail	CHECK}
		}
	existing-host	{
		    {domain	{}}
		    {alias	REJECT}
		    {mx		REJECT}
		    {ip		CHECK}
		    {ip		EXISTS}
		    {addrmail	CHECK}
		}
	alias	{
		    {domain	{}}
		    {alias	REJECT}
		    {mx		REJECT}
		    {ip		REJECT}
		    {addrmail	REJECT}
		}
	del-name	{
		    {domain	{}}
		    {alias	CHECK}
		    {mx		REJECT}
		    {ip		CHECK}
		    {addrmail	CHECK}
		}
	mx	{
		    {domain	{}}
		    {alias	REJECT}
		    {mx		CHECK}
		    {ip		CHECK}
		    {addrmail	REJECT}
		}
	addrmail	{
		    {domain	rolemail}
		    {alias	REJECT}
		    {mx		REJECT}
		    {addrmail	CHECK}
		    {hebergeur	CHECK}
		    {ip		CHECK}
		}
    }


    #
    # Get the list of actions associated with the context
    #

    if {! [info exists testrights($context)]} then {
	return [format [mc "Internal error: invalid context '%s'"] $context]
    }

    #
    # Process tests in the given order, and break as soon as a test fails
    #

    set fqdn "$name.$domain"
    set exists 0
    foreach a $testrights($context) {
	set parm [lindex $a 1]
	switch [lindex $a 0] {
	    domain {
		set iddom -1
		set msg [check-domain $dbfd $idcor iddom domain $parm]
		if {$msg ne ""} then {
		    return $msg
		}

		set exists [read-rr-by-name $dbfd $name $iddom trr]
		if {! $exists} then {
		    set trr(idrr) ""
		    set trr(iddom) $iddom
		}
	    }
	    alias {
		if {$exists} then {
		    set idrr $trr(cname)
		    if {$idrr ne ""} then {
			switch $parm {
			    REJECT {
				read-rr-by-id $dbfd $idrr talias
				set alias "$talias(nom).$talias(domaine)"
				return [format [mc {'%1$s' is an alias of '%2$s'}] $fqdn $alias]
			    }
			    CHECK {
				set ok [check-name-by-addresses $dbfd $idcor $idrr t]
				if {! $ok} then {
				    return [format [mc "You don't have rights on '%s'"] $fqdn]
				}
			    }
			    default {
				return [format [mc {Internal error: invalid parameter '%1$s' for '%2$s'}] $parm "$context/$a"]
			    }
			}
		    }
		}
	    }
	    mx {
		if {$exists} then {
		    set lmx $trr(mx)
		    foreach mx $lmx {
			switch $parm {
			    REJECT {
				return [format [mc "'%s' is a MX"] $fqfn]
			    }
			    CHECK {
				set idrr [lindex $mx 1]
				set ok [check-name-by-addresses $dbfd $idcor $idrr t]
				if {! $ok} then {
				    return [format [mc "You don't have rights on '%s'"] $fqdn]
				}
			    }
			    default {
				return [format [mc {Internal error: invalid parameter '%1$s' for '%2$s'}] $parm "$context/$a"]
			    }
			}
		    }
		}
	    }
	    addrmail {
		if {$exists} then {
		    set idrr $trr(rolemail)
		    if {$idrr ne ""} then {
			switch $parm {
			    REJECT {
				# IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
				return [format [mc "'%s' is a mail role"] $fqdn]
			    }
			    CHECK {
				if {! [read-rr-by-id $dbfd $idrr trrh]} then {
				    return [format [mc "Internal error: id '%s' doesn't exists for a mail host"] $idrr]
				}

				# IP address check
				set ok [check-name-by-addresses $dbfd $idcor -1 trrh]
				if {! $ok} then {
				    return [format [mc "You don't have rights on host holding mail for '%s'"] $fqdn]
				}

				# Mail host checking
				set bidon -1
				set msg [check-domain $dbfd $idcor bidon trrh(domaine) ""]
				if {$msg ne ""} then {
				    set r [format [mc "You don't have rights on host holding mail for '%s'"] $fqdn]
				    append r "\n$msg"
				    return $r
				}
			    }
			    default {
				return [format [mc {Internal error: invalid parameter '%1$s' for '%2$s'}] $parm "$context/$a"]
			    }
			}
		    }
		}
	    }
	    hebergeur {
		if {$exists} then {
		    set ladr $trr(adrmail)
		    switch $parm {
			REJECT {
			    if {[llength $ladr] > 0} then {
				return [format [mc "'%s' is a mail host for mail domains"] $fqdn]
			    }
			}
			CHECK {
			    # remove the name from the list of mail
			    # domains hosted on this host
			    set pos [lsearch -exact $ladr $trr(idrr)]
			    if {$pos != -1} then {
				set ladr [lreplace $ladr $pos $pos]
			    }
			    if {[llength $ladr] > 0} then {
				return [format [mc "'%s' is a mail host for mail domains"] $fqdn]
			    }
			}
			default {
			    return [format [mc {Internal error: invalid parameter '%1$s' for '%2$s'}] $parm "$context/$a"]
			}
		    }
		}
	    }
	    ip {
		if {$exists} then {
		    switch $parm {
			REJECT {
			    return [format [mc "'%s' has IP addresses] $fqfn]
			}
			EXISTS {
			    if {$trr(ip) eq ""} then {
				return [format [mc "Name '%s' is not a host"] $fqdn]
			    }
			}
			CHECK {
			    set ok [check-name-by-addresses $dbfd $idcor -1 trr]
			    if {! $ok} then {
				return [format [mc "You don't have rights on '%s'"] $fqdn]
			    }
			}
			default {
			    return [format [mc {Internal error: invalid parameter '%1$s' for '%2$s'}] $parm "$context/$a"]
			}
		    }
		} else {
		    if {$parm eq "EXISTS"} {
			return [format [mc "Name '%s' does not exist"] $fqdn]
		    }
		}
	    }
	}
    }

    return ""
}

#
# Check MX informations (given form field values)
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- prio : priority read from the form
#	- name : MX name, read from the form
#	- domain : MX domain name, read from the form
#	- idcor : user id
#	- _msg : error message
# Output:
#   - return value: list {prio idmx} where
#	- prio = numeric priority (int syntax ok)
#	- idmx = existing RR id
#   - parameters:
#	- _msg : empty string or error message
#
# History
#   2003/04/25 : pda/jean : design
#   2004/03/04 : pda/jean : common procedure
#   2010/11/29 : pda      : i18n
#

proc check-mx-target {dbfd prio name domain idcor _msg} {
    upvar $_msg msg

    #
    # Syntaxic checking of priority
    #

    if {! [regexp {^[0-9]+$} $prio]} then {
	set msg [format [mc {Invalid MX priority '%1$s' for '%2$s'}] $prio "$name.$domain"]
	return {}
    }

    #
    # Check relay, domain, etc.
    #

    set msg [check-authorized-host $dbfd $idcor $name $domain trr "existing-host"]
    if {$msg ne ""} then {
	return $msg
    }

    #
    # Build up the result
    #

    return [list $prio $trr(idrr)]
}

#
# Check MX
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- name : MX name
#	- _iddom : in return, domain id
#	- domain : MX domain name
#	- idcor : user id
#	- _exists : 1 if RR exists, 0 if not
#	- _trr : RR information read from database
# Output:
#   - return value: empty string or error message
#   - parameter _trr : RR information on return
#
# History
#   2010/12/09 : pda      : isolate common code
#

proc check-authorized-mx {dbfd idcor name _iddom domain _exists _trr} {
    upvar $_exists exists
    upvar $_iddom iddom
    upvar $_trr trr

    #
    # Validate MX name and domain
    #

    set msg [check-name-syntax $name]
    if {$msg ne ""} then {
	d error $msg
    }

    set iddom -1
    set msg [check-domain $dbfd $idcor iddom domain ""]
    if {$msg ne ""} then {
	d error $msg
    }

    #
    # Get information about this name if it already exists
    #

    set exists [read-rr-by-name $dbfd $name $iddom trr]
    if {$exists} then {
	#
	# If it already exists, check that it is not a A or CNAME or
	# anything else which is not a MX
	#

	if {[llength $trr(ip)] > 0} then {
	    return [format [mc "'%s' already has IP addresses"] $name]
	}
	if {[llength $trr(cname)] > 0} then {
	    return [format [mc "'%s' is an alias"] $name]
	}

	#
	# MX exists, we must check that the user has permissions
	# to access all referenced domains.
	#

	foreach mx $trr(mx) {
	    set idmx [lindex $mx 1]
	    if {! [read-rr-by-id $dbfd $idmx tabmx]} then {
		return [format [mc "Internal error: rr_mx table references RR '%s', not found in the rr table"] $idmx]
	    }
	    set iddom $tabmx(iddom)
	    set msg [check-domain $dbfd $idcor iddom tabmx(domaine) ""]
	    if {$msg ne ""} then {
		return [format [mc {MX '%1$s' points to a domain on which you don't have rights\n%2$s}] "$tabmx(nom).$tabmx(domaine)" $msg]
	    }
	}
    }

    return ""
}

#
# Check domains and mail relays
#
# Input:
#   - parameters:
#       - dbfd : database handle
#	- idcor : user id
#	- _iddom : in return, id of found domain
#	- domain : the domain to search
# Output:
#   - return value: empty string or error message
#   - parameter iddom : id of found domain, or -1 if error
#
# History
#   2004/03/04 : pda/jean : design
#   2010/11/29 : pda      : i18n
#

proc check-domain-relay {dbfd idcor _iddom domain} {
    upvar $_iddom iddom

    #
    # Check the domain
    #

    set msg [check-domain $dbfd $idcor iddom domain "rolemail"]
    if {$msg ne ""} then {
	return $msg
    }

    #
    # Check that we own all specified relays
    #

    set sql "SELECT r.nom AS nom, d.nom AS domaine
		FROM dns.relais_dom rd, dns.rr r, dns.domaine d
		WHERE rd.iddom = $iddom
			AND r.iddom = d.iddom
			AND rd.mx = r.idrr
		"
    pg_select $dbfd $sql tab {
	set msg [check-authorized-host $dbfd $idcor $tab(nom) $tab(domaine) trr "existing-host"]
	if {$msg ne ""} then {
	    return [format [mc {You don't have rights to some relays of domain '%1$s': %2$s}] $domain $msg]
	}
    }

    return ""
}

#
# Check a mail role
#
# Input:
#   - parameters:
#       - dbfd : database handle
#	- idcor : user id
#	- name : name of the role (mail domain)
#	- domain : domain of the role (mail domain)
#	- trr : in return, contains trr (see read-rr-by-id)
#	- trrh : in return, contains hosting trr (see read-rr-by-id)
# Output:
#   - return value: empty string or error message
#   - parameter trr : if RR is found, contains RR, else trr(idrr)="" and
#	trr(iddom)=domain-id
#   - parameter trrh : if trr(rolemail) exists, trrh contains RR. Else,
#	trr is a false RR containing at lease trrh(nom) and trrh(domaine)
#	trrh(nom) et trrh(domaine)
#
# History
#   2004/02/12 : pda/jean : design
#   2004/02/27 : pda/jean : centralization of access rights
#   2004/03/01 : pda/jean : add trr and trrh
#   2010/11/29 : pda      : i18n
#

proc check-role-mail {dbfd idcor name domain _trr _trrh} {
    upvar $_trr trr
    upvar $_trrh trrh

    set fqdn "$name.$domain"

    #
    # Access rights check
    #

    set msg [check-authorized-host $dbfd $idcor $name $domain trr "addrmail"]
    if {$msg ne ""} then {
	return $msg
    }

    #
    # Get hosting RR
    #

    catch {unset trrh}
    set trrh(nom)     ""
    set trrh(domaine) ""

    if {$trr(idrr) ne ""} then {
	set h $trr(rolemail)
	if {$h ne ""} then {
	    #
	    # Name is an existing mail address. Do we have rights on it?
	    #
	    if {! [read-rr-by-id $dbfd $h trrh]} then {
		return [format [mc {Internal error on '%1$s': id '%2$s' of mail host not found}] \
				$fqdn $h]
	    }
	}
    }

    return ""
}

#
# Check that no static DHCP association (IP address with an associate
# non null MAC address) is within a DHCP range
#
# Input:
#   - parameters:
#       - dbfd : database handle
#	- mac : MAC address (empty or not empty)
#	- lip : IP (IPv4 and IPv6) address list
# Output:
#   - return value: empty string or error message
#
# History
#   2004/08/04 : pda/jean : design
#   2010/11/29 : pda      : i18n
#

proc check-static-dhcp {dbfd mac lip} {
    set r ""
    if {$mac ne ""} then {
	foreach ip $lip {
	    set sql "SELECT min, max
			    FROM dns.dhcprange
			    WHERE '$ip' >= min AND '$ip' <= max"
	    pg_select $dbfd $sql tab {
		set r [format [mc {Impossible to use MAC address '%1$s' because IP address '%2$s' is in DHCP dynamic range [%3$s..%4$s]}] \
				$mac $ip $tab(min) $tab(max)]
	    }
	    if {$r ne ""} then {
		break
	    }
	}
    }
    return $r
}

#
# Check possible values for a TTL (see RFC 2181)
#
# Input:
#   - parameters:
#	- ttl : value to check
# Output:
#   - return value: empty string or error message
#
# History
#   2010/11/02 : pda/jean : design, from jean's code
#   2010/11/29 : pda      : i18n
#

proc check-ttl {ttl} {
    set r ""
    # 2^31-1
    set maxttl [expr 0x7fffffff]
    if {! [regexp {^\d+$} $ttl]} then {
	set r [mc "Invalid TTL: must be a positive integer"]
    } else {
	if {$ttl > $maxttl} then {
	    set r [format [mc "Invalid TTL: must be less than %s"] $maxttl]
	}
    }
    return $r
}

##############################################################################
# User checking
##############################################################################

#
# Check syntax of a group name
#
# Input:
#   - parameters:
#       - group : name of group
# Output:
#   - return value: empty string or error message
#
# History
#   2008/02/13 : pda/jean : design
#   2010/11/29 : pda      : i18n
#

proc check-group-syntax {group} {
    if {[regexp {^[-A-Za-z0-9]*$} $group]} then {
	set r ""
    } else {
	set r [format [mc "Invalid group name '%s' (allowed chars: letters, digits and minus symbol)"] $group]
    }
    return $r
}


##############################################################################
# Hinfo checking
##############################################################################

#
# Returns HINFO index in the database
#
# Input:
#   - dbfd : database handle
#   - text : hinfo to search
# Output:
#   - return value: index, or -1 if not found
#
# History
#   2002/05/03 : pda/jean : design
#   2010/11/29 : pda      : i18n
#

proc read-hinfo {dbfd text} {
    set qtext [::pgsql::quote $text]
    set idhinfo -1
    pg_select $dbfd "SELECT idhinfo FROM dns.hinfo WHERE texte = '$qtext'" tab {
	set idhinfo $tab(idhinfo)
    }
    return $idhinfo
}

##############################################################################
# DHCP profile checking
##############################################################################

#
# Returns DHCP profile index in the database
#
# Input:
#   - dbfd : database handle
#   - text : profile name to search, or ""
# Output:
#   - return value: index, or -1 if not found
#
# History
#   2005/04/11 : pda/jean : design
#   2010/11/29 : pda      : i18n
#

proc read-dhcp-profile {dbfd text} {
    if {$text ne ""} then {
	set iddhcpprofil 0
    } else {
	set qtext [::pgsql::quote $text]
	set sql "SELECT iddhcpprofil FROM dns.dhcpprofil WHERE nom = '$qtext'"
	set iddhcpprofil -1
	pg_select $dbfd $sql tab {
	    set iddhcpprofil $tab(iddhcpprofil)
	}
    }
    return $iddhcpprofil
}

##############################################################################
# WebDNS standard HTML menus
##############################################################################

#
# Get a ready to use HTML menu to set HINFO values.
#
# Input:
#   - dbfd : database handle
#   - field : field name
#   - defval : default hinfo (textual value)
# Output:
#   - return value: ready to use HTML string
#
# History
#   2002/05/03 : pda/jean : design
#   2010/12/01 : pda      : i18n
#

proc menu-hinfo {dbfd field defval} {
    set lhinfo {}
    set sql "SELECT texte FROM dns.hinfo \
				WHERE present = 1 \
				ORDER BY tri, texte"
    set i 0
    set defindex 0
    pg_select $dbfd $sql tab {
	lappend lhinfo [list $tab(texte) $tab(texte)]
	if {$tab(texte) eq $defval} then {
	    set defindex $i
	}
	incr i
    }
    return [::webapp::form-menu $field 1 0 $lhinfo [list $defindex]]
}

#
# Get a ready to use HTML menu to set DHCP profile value, or a hidden
# field if the group do not have access to any DHCP Profile.
#
# Input:
#   - dbfd : database handle
#   - field : field name
#   - idcor : user id
#   - iddhcpprofil : default selected profile, or 0
# Output:
#   - return value: list with 2 HTML strings {title menu}
#
# History
#   2005/04/08 : pda/jean : design
#   2008/07/23 : pda/jean : change output format
#   2010/11/29 : pda      : i18n
#

proc menu-dhcp-profile {dbfd field idcor iddhcpprofil} {
    #
    # Get all DHCP profiles for this group
    #

    set sql "SELECT p.iddhcpprofil, p.nom
		FROM dns.dr_dhcpprofil dr, dns.dhcpprofil p, global.corresp c
		WHERE c.idcor = $idcor
		    AND dr.idgrp = c.idgrp
		    AND dr.iddhcpprofil = p.iddhcpprofil
		ORDER BY dr.tri ASC, p.nom"
    set lprof {}
    set lsel {}
    set idx 1
    pg_select $dbfd $sql tab {
	lappend lprof [list $tab(iddhcpprofil) $tab(nom)]
	if {$tab(iddhcpprofil) == $iddhcpprofil} then {
	    lappend lsel $idx
	}
	incr idx
    }

    #
    # Is there at least one profile?
    #

    if {[llength $lprof] > 0} then {
	#
	# Is the default selected profile in our list?
	#

	if {$iddhcpprofil != 0 && [llength $lsel] == 0} then {
	    #
	    # We must add it at the end of the list.
	    #

	    set sql "SELECT iddhcpprofil, nom
			    FROM dns.dhcpprofil
			    WHERE iddhcpprofil = $iddhcpprofil"
	    pg_select $dbfd $sql tab {
		lappend lprof [list $tab(iddhcpprofil) $tab(nom)]
		lappend lsel $idx
	    }
	}

	#
	# Special case at the beginning of the list
	#

	set lprof [linsert $lprof 0 [list 0 [mc "No profile"]]]

	set title [mc "DHCP profile"]
	set html [::webapp::form-menu $field 1 0 $lprof $lsel]

    } else {
	#
	# No profile found. We hide the field.
	#

	set title ""
	set html [::webapp::form-hidden $field $iddhcpprofil]
    }

    return [list $title $html]
}

#
# Get an HTML button "SMTP emit right" for a host, or a hidden field
# if the group do not have the according right.
#
# Input:
#   - dbfd : database handle
#   - field : field name
#   - _tabuid : user characteristics
#   - droitsmtp : default selected value
# Output:
#   - return value: list with 2 HTML strings {title menu}
#
# History
#   2008/07/23 : pda/jean : design
#   2008/07/24 : pda/jean : use idcor instead of idgrp
#   2010/12/01 : pda      : i18n
#   2010/12/05 : pda      : use tabuid instead of idcor
#

proc menu-droitsmtp {dbfd field _tabuid droitsmtp} {
    upvar $_tabuid tabuid

    #
    # Get group access right, in order to display or hide the button
    #


    if {$tabuid(droitsmtp)} then {
	set title [mc "Use SMTP"]
	set html [::webapp::form-bool $field $droitsmtp]
    } else {
	set title ""
	set html [::webapp::form-hidden $field $droitsmtp]
    }

    return [list $title $html]
}

#
# Get an HTML input form for a host TTL value, or a hidden field
# if the group do not have the according right.
#
# Input:
#   - dbfd : database handle
#   - field : field name
#   - _tabuid : user characteristics
#   - ttl : default value
# Output:
#   - return value: ready to use HTML string
#
# History
#   2010/10/31 : pda      : design
#   2010/12/01 : pda      : i18n
#   2010/12/05 : pda      : use tabuid instead of idcor
#

proc menu-ttl {dbfd field _tabuid ttl} {
    upvar $_tabuid tabuid

    #
    # Convert the TTL value from the database in something which can be
    # displayed: the value "-1" means "no TTL set for this host", which
    # should be displayed as an empty string.
    #

    if {$ttl == -1} then {
	set ttl ""
    }

    #
    # Get the group permission.
    #

    if {$tabuid(droitttl)} then {
	set title [mc "TTL"]
	set html [::webapp::form-text $field 1 6 10 $ttl]
	append html " "
	append html [mc "(in seconds)"]
    } else {
	set title ""
	set html [::webapp::form-hidden $field $ttl]
    }

    return [list $title $html]
}


#
# Get an HTML menu to select a domain. This may be either a simple
# text with a hidden field if the group has access to only one domain,
# or a dropdown menu.
#
# Input:
#   - dbfd : database handle
#   - idcor : user id
#   - field : field name
#   - where : SQL where clause (without SQL keyword "where") or empty string
#   - sel : name of domain to pre-select, or empty string
# Output:
#   - return value: HTML string
#
# History :
#   2002/04/11 : pda/jean : coding
#   2002/04/23 : pda      : add display priority
#   2002/05/03 : pda/jean : migrated in the libdns
#   2002/05/06 : pda/jean : use groups
#   2003/04/24 : pda/jean : decompose in two procedures
#   2004/02/06 : pda/jean : add where clause
#   2004/02/12 : pda/jean : add sel parameter
#   2010/11/15 : pda      : delete err parameter
#

proc menu-domain {dbfd idcor field where sel} {
    set lcouples [couple-domains $dbfd $idcor $where]

    set lsel [lsearch -exact $lcouples [list $sel $sel]]
    if {$lsel == -1} then {
	set lsel {}
    }

    #
    # If there is only one domain, present it as a text. If more
    # than one domaine, use a dropdown menu.
    #

    set ndom [llength $lcouples]
    switch -- $ndom {
	0	{
	    d error [mc "Sorry, but you do not have any active domain"]
	}
	1	{
	    set d [lindex [lindex $lcouples 0] 0]
	    set h [::webapp::hidden $field $d]
	    set html "$d $h"
	}
	default	{
	    set html [::webapp::form-menu $field 1 0 $lcouples $lsel]
	}
    }

    return $html
}

#
# Returns a list of couples {name name} for each authorized domain
#
# Input:
#   - dbfd : database handle
#   - idcor : user id
#   - where : SQL where clause (without SQL keyword "where") or empty string
# Output:
#   - return value: liste of couples
#
# History :
#   2003/04/24 : pda/jean : coding
#   2004/02/06 : pda/jean : add where clause
#   2010/12/01 : pda      : i18n
#

proc couple-domains {dbfd idcor where} {
    if {$where ne ""} then {
	set where " AND $where"
    }

    set lcouples {}
    set sql "SELECT domaine.nom
		FROM dns.domaine, dns.dr_dom, global.corresp
		WHERE domaine.iddom = dr_dom.iddom
		    AND dr_dom.idgrp = corresp.idgrp
		    AND corresp.idcor = $idcor
		    $where
		ORDER BY dr_dom.tri ASC"
    pg_select $dbfd $sql tab {
	lappend lcouples [list $tab(nom) $tab(nom)]
    }

    return $lcouples
}

##############################################################################
# Network management
##############################################################################

#
# Return list of networks for a given group and a given privilege
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- idgrp : group id
#	- droit : "consult", "dhcp" or "acl"
# Output:
#   - return value: list of networks {idnet cidr4 cidr6 name}
#
# History
#   2004/01/16 : pda/jean : specification and design
#   2004/08/06 : pda/jean : extend permissions on networks
#   2004/10/05 : pda/jean : adapt to new permissions
#   2006/05/24 : pda/jean/boggia : extract in a primary function
#   2010/12/01 : pda      : i18n
#

proc allowed-networks {dbfd idgrp priv} {
    #
    # Build a WHERE clause from the given privilege
    #

    switch -- $priv {
	consult {
	    set w1 ""
	    set w2 ""
	}
	dhcp {
	    set w1 "AND d.$priv > 0"
	    set w2 "AND r.$priv > 0"
	}
	acl {
	    set w1 "AND d.$priv > 0"
	    set w2 ""
	}
    }

    #
    # Get all allowed networks for this group and for this privilege
    #

    set lnet {}
    set sql "SELECT r.idreseau, r.nom, r.adr4, r.adr6
			FROM dns.reseau r, dns.dr_reseau d
			WHERE r.idreseau = d.idreseau
			    AND d.idgrp = $idgrp
			    $w1 $w2
			ORDER BY adr4, adr6"
    pg_select $dbfd $sql tab {
	lappend lnet [list $tab(idreseau) $tab(adr4) $tab(adr6) $tab(nom)]
    }

    return $lnet
}

#
# Returns the list of networks allowed for a group (with a given privilege)
# ready to use with form-menu.
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- idgrp : group id
#	- priv : "consult", "dhcp" or "acl"
# Output:
#   - return value: list of elements {id name}
#
# History
#   2006/05/24 : pda/jean/boggia : extract procedure heart in allowed-networks
#   2010/12/01 : pda      : i18n
#

proc read-networks {dbfd idgrp priv} {
    set lnet {}
    foreach r [allowed-networks $dbfd $idgrp $priv] {
	lassign $r idnet cidr4 cidr6 name
	set name [::webapp::html-string $name]
	lappend lnet [list $idnet [format "%s\t%s\t(%s)" $cidr4 $cidr6 $name]]
    }
    return $lnet
}

#
# Check a network id as returned in a form field. This check is done
# according to a given group and a given privilege.
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- netid : id of network to check
#	- idgrp : group id
#	- priv : "consult", "dhcp" or "acl"
#	- version : 4, 6 or {4 6}
#	- _msg : empty string or error message
# Output:
#   - return value: list of cidr
#   - parameter _msg : empty string or error message
#
# History
#   2004/10/05 : pda/jean : specification and design
#   2010/12/01 : pda      : i18n
#

proc check-netid {dbfd netid idgrp priv version _msg} {
    upvar $_msg msg

    #
    # Check syntax of id
    #
    set netid [string trim $netid]
    if {! [regexp {^[0-9]+$} $netid]} then {
	set msg [format [mc "Invalid network id '%s'"] $netid]
	return {}
    }

    #
    # Convert privilege into an sql where clause
    #

    switch -- $priv {
	consult {
	    set w1 ""
	    set w2 ""
	    set c [mc "You cannot read this network"]
	}
	dhcp {
	    set w1 "AND d.$priv > 0"
	    set w2 "AND r.$priv > 0"
	    set c [mc "You do not have DHCP access to this network"]
	}
	acl {
	    set w1 "AND d.$priv > 0"
	    set w2 ""
	    set c [mc "You do not have ACL access to this network"]
	}
    }

    #
    # Check network and read associated CIDR(s)
    #

    set lcidr {}
    set msg ""

    set sql "SELECT r.adr4, r.adr6
		    FROM dns.dr_reseau d, dns.reseau r
		    WHERE d.idgrp = $idgrp
			AND d.idreseau = r.idreseau
			AND r.idreseau = $netid
			$w1 $w2"
    set cidrplage4 ""
    set cidrplage6 ""
    pg_select $dbfd $sql tab {
	set cidrplage4 $tab(adr4)
	set cidrplage6 $tab(adr6)
    }

    if {[lsearch -exact $version 4] == -1} then {
	set cidrplage4 ""
    }
    if {[lsearch -exact $version 6] == -1} then {
	set cidrplage6 ""
    }

    set empty4 [string equal $cidrplage4 ""]
    set empty6 [string equal $cidrplage6 ""]

    switch -glob $empty4-$empty6 {
	1-1 {
	    set msg $c
	}
	0-1 {
	    lappend lcidr $cidrplage4
	}
	1-0 {
	    lappend lcidr $cidrplage6
	}
	0-0 {
	    lappend lcidr $cidrplage4
	    lappend lcidr $cidrplage6
	}
    }

    return $lcidr
}

##############################################################################
# Edition of tabular data
##############################################################################

#
# Generate HTML code to displau and edit table content.
#
# Input:
#   - parameters:
#	- cwidth : list of column widths {w1 w2 ... wn} (unit = %)
#	- ctitle : list of column titles specification, each element
#		is {type value} where type = "html" or "text"
#	- cspec : list of column specifications, each element
#		is {id type defval}, where
#		- id : column id in the table, and name of firld (idNN or idnNN)
#		- type : "text", "string N", "bool", "menu L", "textarea {W H}"
#		- defval : default value for new lines
#	- dbfd : database handle
#	- sql : SQL request to get column values (notably the id column)
#	- idnum : column name of the numeric id
#	- _tab : in return, will contail the generated HTML code
# Output:
#   - return value: empty string or error message
#   - parameter _tab : HTML code
#
# History
#   2001/11/01 : pda      : specification and documentation
#   2001/11/01 : pda      : coding
#   2002/05/03 : pda/jean : add type menu
#   2002/05/06 : pda/jean : add type textarea
#   2002/05/16 : pda      : convert to arrgen
#   2010/12/04 : pda      : i18n
#

proc display-tabular {cwidth ctitle cspec dbfd sql idnum _tab} {
    upvar $_tab tab

    #
    # Minimal integrity test on column number.
    #

    if {[llength $ctitle] != [llength $cspec] || \
		[llength $ctitle] != [llength $cwidth]} then {
	return [mc "Internal error: invalid tabular specification"]
    }

    #
    # Build-up the arrgen array specification.
    #

    set aspec [_build-array-spec $cwidth $ctitle $cspec]
    set lines {}

    #
    # Display title line
    #

    set l {}
    lappend l "Title"
    foreach t $ctitle {
	lappend l [lindex $t 1]
    }
    lappend lines $l

    #
    # Display existing lines from the database
    #

    pg_select $dbfd $sql tabsql {
	set tabsql(:$idnum) $tabsql($idnum)
	lappend lines [_display-tabular-line $cspec tabsql $idnum]
    }

    #
    # Add empty lines at the end to let user enter new values
    #

    foreach s $cspec {
	lassign $s id type defval
	set tabdef($id) $defval
    }

    for {set i 1} {$i <= 5} {incr i} {
	set tabdef(:$idnum) "n$i"
	lappend lines [_display-tabular-line $cspec tabdef $idnum]
    }

    #
    # Generates HTML code and returns
    #

    set tab [::arrgen::output "html" $aspec $lines]

    return ""
}

#
# Build-up a table specification (for arrgen) from display-tabular parameters
#
# Input:
#   - parameters: see display-tabular
# Output:
#   - return value: an "arrgen" specification
#
# History
#   2001/11/01 : pda      : design and documentation
#   2002/05/16 : pda      : convert to arrgen
#   2010/12/04 : pda      : i18n
#

proc _build-array-spec {cwidth ctitle cspec} {
    #
    # First, build-up Title pattern
    #

    set titpat "pattern Title {"
    foreach t $ctitle {
	append titpat "vbar {yes} "
	append titpat "chars {bold} "
	append titpat "align {center} "
	append titpat "column { "
	append titpat "  botbar {yes} "
	if {[lindex $t 0] ne "text"} then {
	    append titpat "  format {raw} "
	}
	append titpat "} "
    }
    append titpat "vbar {yes} "
    append titpat "} "

    #
    # Next, normal lines
    #

    set norpat "pattern Normal {"
    foreach t $cspec {
	append norpat "topbar {yes} "
	append norpat "vbar {yes} "
	append norpat "column { "
	append norpat "  align {center} "
	append norpat "  botbar {yes} "
	set type [lindex [lindex $t 1] 0]
	if {$type ne "text"} then {
	    append norpat "  format {raw} "
	}
	append norpat "} "
    }
    append norpat "vbar {yes} "
    append norpat "} "

    #
    # Finally, global specifications
    #

    return "global { chars {10 normal} columns {$cwidth} } $titpat $norpat"
}

#
# Display a line of tabular data
#
# Input:
#   - parameters:
#	- cspec : see display-tabular
#	- tab : array indexed by fields specified in cspec (see display-tabular)
#	- idnum : column name of the numeric id
# Output:
#   - return value: an "arrgen" line
#
# History
#   2001/11/01 : pda      : specification and documentation
#   2001/11/01 : pda      : design
#   2002/05/03 : pda/jean : add type menu
#   2002/05/06 : pda/jean : add type textarea
#   2002/05/16 : pda      : convert to arrgen
#   2010/12/04 : pda      : i18n
#

proc _display-tabular-line {cspec _tab idnum} {
    upvar $_tab tab

    set line {Normal}
    foreach s $cspec {
	lassign $s id type defval

	set value $tab($id)

	lassign $type typekw typeopt

	set num $tab(:$idnum)
	set ref $id$num

	switch $typekw {
	    text {
		set item $value
	    }
	    string {
		set item [::webapp::form-text $ref 1 $typeopt 0 $value]
	    }
	    bool {
		set item [::webapp::form-bool $ref $value]
	    }
	    menu {
		set sel 0
		set i 0
		foreach e $typeopt {
		    set v [lindex $e 0]
		    if {$v eq $value} then {
			set sel $i
		    }
		    incr i
		}
		set item [::webapp::form-menu $ref 1 0 $typeopt [list $sel]]
	    }
	    textarea {
		lassign $typeopt width height
		set item [::webapp::form-text $ref $height $width 0 $value]
	    }
	}
	lappend line $item
    }

    return $line
}

##############################################################################
# Storing tabular data
##############################################################################

#
# Get modifications from a form generated by display-tabular and
# store them if necessary in the database.
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- cspec : column specifications (see below)
#	- idnum : column name of the numeric id
#	- table : name of the SQL table to modify
#	- _ftab : array containing form field values
# Output:
#   - return value: empty string or error message
#
# Notes :
#   - format of "cspec" is {{column defval} ...}, where:
#	- column is the column id in the table
#	- defval, if present, is the default value to store in the table
#		if the value is not provided
#   - first column of "cspec" is the key used to know if an entry must
#	be added or delete.
#
# History
#   2001/11/02 : pda      : specification and documentation
#   2001/11/02 : pda      : coding
#   2002/05/03 : pda/jean : remove an old constraint
#   2010/12/04 : pda      : i18n
#

proc store-tabular {dbfd cspec idnum table _ftab} {
    upvar $_ftab ftab

    #
    # Lock the table
    #

    if {! [::pgsql::execsql $dbfd "BEGIN WORK ; LOCK $table" msg]} then {
	return [format [mc "Unable to lock table (%s)"] $msg]
    }

    #
    # Last used id
    #

    set max 0
    pg_select $dbfd "SELECT MAX($idnum) FROM $table" tab {
	set max $tab(max)
    }

    #
    # Key to know if an entry must be deleted (for existing ids) or
    # added (for new ids)
    #

    set key [lindex [lindex $cspec 0] 0]

    #
    # Traversal of existing ids in the database
    #

    set id 1

    for {set id 1} {$id <= $max} {incr id} {
	if {[info exists ftab(${key}${id})]} {
	    _fill-tabval $cspec "" $id ftab tabval

	    if {$tabval($key) eq ""} then {
		#
		# Delete entry
		#

		set ok [_store-tabular-del $dbfd msg $id $idnum $table]
		if {! $ok} then {
		    #
		    # When deletion is not possible, we must return an
		    # appropriate message, with the old value.
		    #
		    set oldkey ""
		    pg_select $dbfd "SELECT $key FROM $table \
				    WHERE $idnum = $id" t {
			set oldkey $t($key)
		    }
		    ::pgsql::execsql $dbfd "ABORT WORK" m
		    return [format [mc {Error deleting '%1$s' (%2$s)}] $oldkey $msg]
		}
	    } else {
		#
		# Modify entry
		#

		set ok [_store-tabular-mod $dbfd msg $id $idnum $table tabval]
		if {! $ok} then {
		    ::pgsql::execsql $dbfd "ABORT WORK" m
		    return [format [mc {Error modifying '%1$s' (%2$s)}] $tabval($key) $msg]

		}
	    }
	}
    }

    #
    # New entries
    #

    set idnew 1
    while {[info exists ftab(${key}n${idnew})]} {
	_fill-tabval $cspec "n" $idnew ftab tabval

	if {$tabval($key) ne ""} then {
	    #
	    # Add entry
	    #

	    set ok [_store-tabular-add $dbfd msg $table tabval]
	    if {! $ok} then {
		::pgsql::execsql $dbfd "ABORT WORK" m
		return [format [mc {Error adding '%1$s' (%2$s)}] $tabval($key) $msg]
	    }
	}

	incr idnew
    }

    #
    # Unlock and commit modifications
    #

    if {! [::pgsql::execsql $dbfd "COMMIT WORK" msg]} then {
	::pgsql::execsql $dbfd "ABORT WORK" m
	return [format [mc "Unable to commit, modification cancelled (%s)"] $msg]
    }

    return ""
}

#
# Read form field values, and add default values, notably for boolean
# types (checkboxes) which may be not present.
#
# Input:
#   - parameters:
#	- cspec : see store-tabular
#	- prefix : "" (existing entry) or "n" (new entry)
#	- num : entry number
#	- _ftab : form field values (see webapp/get-data)
#	- _tabval : array to fill
# Output:
#   - return value: none
#   - parameter _tabval : array filled with usable values
#
# Example :
#   - if cspec = {{login} {name}} and prefix = "n" and num = "5"
#     then we search ftab(loginn5) et ftab(namen5) and we place found
#	(or default) values in in tabval(login) and tabval(name)
#
# History :
#   2001/04/01 : pda      : design
#   2001/04/03 : pda      : documentation
#   2001/11/02 : pda      : extension
#   2010/12/04 : pda      : i18n
#

proc _fill-tabval {cspec prefix num _ftab _tabval} {
    upvar $_ftab ftab
    upvar $_tabval tabval

    foreach coldefval $cspec {

	set col [lindex $coldefval 0]

	if {[llength $coldefval] == 2} then {
	    #
	    # Default value: we do not get them from the form
	    #

	    set val [lindex $coldefval 1]

	} else {
	    #
	    # No default value : we search a value in the form data.
	    # If not found, it is a boolean which has not been checked.
	    # The value is thus 0.
	    #

	    set form ${col}${prefix}${num}

	    if {[info exists ftab($form)]} then {
		set val [string trim [lindex $ftab($form) 0]]
	    } else {
		set val {0}
	    }
	}

	set tabval($col) $val
    }
}

#
# Modify an entry
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- _msg : in return, error message if any
#	- id : id (value) of entry to modify
#	- idnum : column name of the numeric id
#	- table : name of the SQL table to modify
#	- _tabval : array containing new values
# Output:
#   - return value: 1 if ok, 0 if error
#   - parameters:
#	- msg : error message if an error occurred
#
# History :
#   2001/04/01 : pda      : design
#   2001/04/03 : pda      : documentation
#   2001/11/02 : pda      : generalization
#   2004/01/20 : pda/jean : add NULL if empty string (for ipv6)
#   2010/12/04 : pda      : i18n
#

proc _store-tabular-mod {dbfd _msg id idnum table _tabval} {
    upvar $_msg msg
    upvar $_tabval tabval

    #
    # There is no need to modify anything if all values are identical.
    #

    set diff 0
    pg_select $dbfd "SELECT * FROM $table WHERE $idnum = $id" tab {
	foreach attribut [array names tabval] {
	    if {[string compare $tabval($attribut) $tab($attribut)] != 0} then {
		set diff 1
		break
	    }
	}
    }

    set ok 1

    if {$diff} then {
	#
	# It's diffent, we must do the work...
	#

	set l {}
	foreach attr [array names tabval] {
	    if {$tabval($attr) eq ""} then {
		set v "NULL"
	    } else {
		set v "'[::pgsql::quote $tabval($attr)]'"
	    }
	    lappend l "$attr = $v"
	}
	set sql "UPDATE $table SET [join $l ,] WHERE $idnum = $id"
	set ok [::pgsql::execsql $dbfd $sql msg]
    }

    return $ok
}

#
# Entry deletion
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- _msg : in return, error message if any
#	- id : id (value) of entry to delete
#	- idnum : column name of the numeric id
#	- table : name of the SQL table to modify
# Output:
#   - return value: 1 if ok, 0 if error
#   - parameters:
#	- msg : error message if an error occurred
#
# History :
#   2001/04/03 : pda      : design
#   2001/11/02 : pda      : generalization
#   2002/05/03 : pda/jean : remove an old constraint
#   2010/12/04 : pda      : i18n
#

proc _store-tabular-del {dbfd _msg id idnum table} {
    upvar $_msg msg

    set sql "DELETE FROM $table WHERE $idnum = $id"
    return [::pgsql::execsql $dbfd $sql msg]
}

#
# Entry addition
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- _msg : in return, error message if any
#	- table : name of the SQL table to modify
#	- _tabval : array containing new values
# Output:
#   - return value: 1 if ok, 0 if error
#   - parameters:
#	- msg : error message if an error occurred
#
# History :
#   2001/04/01 : pda      : design
#   2001/04/03 : pda      : documentation
#   2001/11/02 : pda      : generalization
#   2004/01/20 : pda/jean : add NULL attribute if empty string (for ipv6)
#   2010/12/04 : pda      : i18n
#

proc _store-tabular-add {dbfd _msg table _tabval} {
    upvar $_msg msg
    upvar $_tabval tabval

    #
    # Column names
    #
    set cols [array names tabval]

    #
    # Column values
    #
    set vals {}
    foreach c $cols {
	if {$tabval($c) eq ""} then {
	    set v "NULL"
	} else {
	    set v "'[::pgsql::quote $tabval($c)]'"
	}
	lappend vals $v
    }

    set sql "INSERT INTO $table ([join $cols ,]) VALUES ([join $vals ,])"
    return [::pgsql::execsql $dbfd $sql msg]
}

##############################################################################
# Topo library
##############################################################################

#
# Read topo status
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- admin : 1 if user is administrator
# Output:
#   - return value: HTML status message, or empty (if user is not admin
#	or if there is no message)
#
# History
#   2010/11/15 : pda      : extract in an autonomous function
#   2010/11/23 : pda      : use keepstate table
#   2010/12/04 : pda      : i18n
#

proc topo-status {dbfd admin} {
    set msgsta ""
    if {$admin} then {
	set found 0
	set sql "SELECT * FROM topo.keepstate WHERE type = 'anaconf'"
	pg_select $dbfd $sql tab {
	    set date $tab(date)
	    set msg  $tab(message)
	    set found 1
	}
	if {! $found} then {
	    set msg [mc "No message from anaconf"]
	    set date [mc "(no date)"]
	} elseif {$msg eq "Resuming normal operation"} then {
	    set msg ""
	}

	if {$msg ne ""} then {
	    set msg [::webapp::html-string $msg]
	    regsub -all "\n" $msg "<br>" msg

	    set text [::webapp::helem "p" [mc "Topod messages"]]
	    append text [::webapp::helem "p" \
			    [::webapp::helem "font" $msg "color" "#ff0000"] \
			    ]
	    append text [::webapp::helem "p" [format [mc "... since %s"] $date]]

	    set msgsta [::webapp::helem "div" $text "class" "alerte"]
	}
    }
    return $msgsta
}

#
# Compare two interface names, used in sort operations.
#
# Input:
#   - parameters:
#       - i1, i2 : interface names
# Output:
#   - return value: -1, 0 or 1 (see string compare)
#
# History
#   2006/12/29 : pda      : design
#   2010/12/04 : pda      : i18n
#

proc compare-interfaces {i1 i2} {
    #
    # Isolate all words
    # Eg: "GigabitEthernet1/0/1" -> " GigabitEthernet 1/0/1"
    #
    regsub -all {[A-Za-z]+} $i1 { & } i1
    regsub -all {[A-Za-z]+} $i2 { & } i2
    #
    # Remove all special characters
    # Eg: " GigabitEthernet 1/0/1" -> " GigabitEthernet 1 0 1"
    #
    regsub -all {[^A-Za-z0-9]+} $i1 { } i1
    regsub -all {[^A-Za-z0-9]+} $i2 { } i2
    #
    # Remove unneeded spaces
    #
    set i1 [string trim $i1]
    set i2 [string trim $i2]

    #
    # Compare word by word
    #
    set r 0
    foreach m1 [split $i1] m2 [split $i2] {
	if {[regexp {^[0-9]+$} $m1] && [regexp {^[0-9]+$} $m2]} then {
	    if {$m1 < $m2} then {
		set r -1
	    } elseif {$m1 > $m2} then {
		set r 1
	    } else {
		set r 0
	    }
	} else {
	    set r [string compare $m1 $m2]
	}
	if {$r != 0} then {
	    break
	}
    }

    return $r
}

#
# Compare two IP addresses, used in sort operations.
#
# Input:
#   - parameters:
#       - ip1, ip2 : IP addresses (IPv4 or IPv6)
# Output:
#   - return value: -1, 0 ou 1 (see string compare)
#
# History
#   2006/06/20 : pda      : design
#   2006/06/22 : pda      : documentation
#   2010/12/04 : pda      : i18n
#

proc compare-ip {ip1 ip2} {
    set ip1 [::ip::normalize $ip1]
    set v1  [::ip::version $ip1]
    set ip2 [::ip::normalize $ip2]
    set v2  [::ip::version $ip2]

    set r 0
    if {$v1 == 4 && $v2 == 4} then {
	set l1 [split [::ip::prefix $ip1] "."]
	set l2 [split [::ip::prefix $ip2] "."]
	foreach e1 $l1 e2 $l2 {
	    if {$e1 < $e2} then {
		set r -1
		break
	    } elseif {$e1 > $e2} then {
		set r 1
		break
	    }
	}
    } elseif {$v1 == 6 && $v2 == 6} then {
	set l1 [split [::ip::prefix $ip1] ":"]
	set l2 [split [::ip::prefix $ip2] ":"]
	foreach e1 $l1 e2 $l2 {
	    if {"0x$e1" < "0x$e2"} then {
		set r -1
		break
	    } elseif {"0x$e1" > "0x$e2"} then {
		set r 1
		break
	    }
	}
    } else {
	set r [expr $v1 < $v2]
    }
    return $r
}

#
# Check if an IP address (IPv4 or IPv6) is in an address range
#
# Input:
#   - parameters:
#       - ip : IP address (or CIDR) to check
#	- net : address range
# Output:
#   - return value: 0 (ip not in range) or 1 (ip is in range)
#
# History
#   2006/06/22 : pda      : design
#   2010/12/04 : pda      : i18n
#

proc ip-in {ip net} {
    set v [::ip::version $net]
    if {[::ip::version $ip] != $v} then {
	return 0
    }

    set defmask [expr "$v==4 ? 32 : 128"]

    set ip [::ip::normalize $ip]
    set net [::ip::normalize $net]

    set mask [::ip::mask $net]
    if {$mask eq ""} then {
	set mask $defmask
    }

    set prefnet [::ip::prefix $net]
    regsub {(/[0-9]+)?$} $ip "/$mask" ip2
    set prefip  [::ip::prefix $ip2]

    return [string equal $prefip $prefnet]
}

#
# Check metrology id 
# Valide l'id du point de collecte par rapport aux droits du correspondant.
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- id : id du point de collecte (ou id+id+...)
#	- _tabuid : user characteristics
#	- _title : title of graph
# Output:
#   - return value: empty string or error message
#   - parameter _title : title of graph found
#
# History
#   2006/08/09 : pda/boggia : design
#   2006/12/29 : pda        : parameter vlan
#   2008/07/30 : pda        : adapt to new extractcoll
#   2008/07/30 : pda        : multiple ids
#   2008/07/31 : pda        : add "|"
#   2010/12/04 : pda        : i18n
#

proc check-metro-id {dbfd id _tabuid _title} {
    upvar $_tabuid tabuid
    upvar $_title title
    global libconf

    #
    # If ids are more than one
    #

    set lid [split $id "+|"]

    #
    # Get the metrology sensor list, according to user permissions
    #

    set cmd [format $libconf(extractcoll) $tabuid(flagsr)]

    if {[catch {set fd [open "| $cmd" "r"]} msg]} then {
	return [format [mc "Cannot read sensor list: %s"] $msg]
    }
    while {[gets $fd line] > -1} {
	lassign [split $line] kw i
	set n [lsearch -exact $lid $i]
	if {$n >= 0} then {
	    set idtab($i) $line
	    if {[info exists firstkw]} then {
		if {$firstkw ne $kw} then {
		    return [mc "Divergent sensor types"]
		}
	    } else {
		set firstkw $kw
	    }
	    set lid [lreplace $lid $n $n]
	}
    }
    catch {close $fd}

    #
    # Error if id is not found
    #

    if {[llength $lid] > 0} then {
	return [format [mc "Sensor '%s' not found"] $id]
    }

    #
    # Try to guess an appropriate title
    # 

    set lid [array names idtab]
    switch [llength $lid] {
	0 {
	    return [mc "No sensor selected"]
	}
	1 {
	    set i [lindex $lid 0]
	    set l $idtab($i)
	    switch $firstkw {
		trafic {
		    set eq    [lindex $l 2]
		    set iface [lindex $l 4]
		    set vlan  [lindex $l 5]

		    if {$vlan ne "-"} then {
			set t [mc {Traffic on vlan %1$s of interface %2$s of %3$s}]
		    } else {
			set t [mc {Traffic on interface %2$s of %3$s}]
		    }
		    set title [format $t $vlan $iface $eq]
		}
		nbauthwifi -
		nbassocwifi {
		    set eq    [lindex $l 2]
		    set iface [lindex $l 4]
		    set ssid  [lindex $l 5]

		    if {$firstkw eq "nbauthwifi"} then {
			set t [mc {Number of auhentified users on ssid %1$s of interface %2$s of %3$s}]
		    } else {
			set t [mc {Number of associated hosts on ssid %1$s of interface %2$s of %3$s}]
		    }
		    set title [format $t $ssid $iface $eq]
		}
		default {
		    return [mc "Internal error: invalid extractcoll output format"]
		}
	    }
	}
	default {
	    switch $firstkw {
		trafic {
		    set le {}
		    foreach i $lid {
			set l $idtab($i)
			set eq    [lindex $l 2]
			set iface [lindex $l 4]
			set vlan  [lindex $l 5]

			set e "$eq/$iface"
			if {$vlan ne "-"} then {
			    append e ".$vlan"
			}
			lappend le $e
		    }
		    set le [join $le ", "]
		    set title [format [mc "Traffic on interfaces %s"] $le]
		}
		nbauthwifi -
		nbassocwifi {
		    if {$firstkw eq "nbauthwifi"} then {
			set t [mc "Number of auhentified users on %s"]
		    } else {
			set t [mc "Number of associated hosts on %s"]
		    }
		    foreach i $lid {
			set l $idtab($i)
			set eq    [lindex $l 2]
			set iface [lindex $l 4]
			set ssid  [lindex $l 5]

			set e "$eq/$iface ($ssid)"
			lappend le $e
		    }
		    set le [join $le ", "]
		    set title [format $t $le]
		}
		default {
		    return [mc "Internal error: invalid extractcoll output format"]
		}
	    }
	}
    }

    return ""
}

#
# Get regexp giving authorized equipments for a given group.
#
# Input:
#   - parameters:
#       - dbfd : database handle
#	- rw : read (0) or write (1)
#	- idgrp : group id
# Output:
#   - return value: {{re_allow_1 ... re_allow_n} {re_deny_1 ... re_deny_n}}
#
# History
#   2006/08/10 : pda/boggia : design with an on-disk file
#   2010/11/03 : pda/jean   : data are now in the database
#   2010/12/05 : pda        : i18n
#

proc read-authorized-eq {dbfd rw idgrp} {
    set r {}
    foreach allow_deny {1 0} {
	set sql "SELECT pattern
			FROM topo.dr_eq
			WHERE idgrp = $idgrp
			    AND rw = $rw
			    AND allow_deny = $allow_deny"
	set d {}
	pg_select $dbfd $sql tab {
	    lappend d $tab(pattern)
	}
	lappend r $d
    }
    return $r
}

#
# Fetch a graph from the metrology host and return it back.
#
# Input:
#   - parameters:
#       - url : URL of the graph on the metrology host
# Output:
#   - none : the fetched graph is printed on stdout with usual HTTP headers
#
# History
#   2006/05/17 : jean       : design for dhcplog
#   2006/08/09 : pda/boggia : extract and use in this library
#   2010/11/15 : pda        : remove err parameter
#   2010/12/05 : pda        : i18n
#

proc gengraph {url} {
    package require http			;# tcllib

    set token [::http::geturl $url]
    set status [::http::status $token]

    if {$status ne "ok"} then {
	set code [::http::code $token]
	d error [format [mc "No access: %s"] $code]
    }

    upvar #0 $token state

    # 
    # Determine image type
    # 

    array set meta $state(meta)
    switch -exact $meta(Content-Type) {
	image/png {
	    set contenttype "png"
	}
	image/jpeg {
	    set contenttype "jpeg"
	}
	image/gif {
	    set contenttype "gif"
	}
	default {
	    set contenttype "html"
	}
    }

    # 
    # Return the result back
    # 

    ::webapp::send $contenttype $state(body)
}

#
# Decode a date (supposed to be input by a human)
#
# Input:
#   - parameters:
#       - date : date imput by an user in a form
#	- hour : hour (from 00:00:00 to 23:59:59)
# Output:
#   - return value: converted date in potsgresql format, or "" if no date
#
# History
#   2000/07/18 : pda      : design
#   2000/07/23 : pda      : add hour
#   2001/03/12 : pda      : extract in this library
#   2008/07/30 : pda      : add special case for 24h (= 23:59:59)
#   2010/12/05 : pda      : i18n
#

proc decode-date {date hour} {
    set date [string trim $date]
    if {$date eq ""} then {
	set datepg ""
    }
    if {$hour eq "24"} then {
	set hour "23:59:59"
    }
    set l [split $date "/"]
    lassign $l dd mm yyyy
    switch [llength $l] {
	1	{
	    set mm   [clock format [clock seconds] -format "%m"]
	    set yyyy [clock format [clock seconds] -format "%Y"]
	    set datepg "$mm/$dd/$yyyy $hour"
	}
	2	{
	    set yyyy [clock format [clock seconds] -format "%Y"]
	    set datepg "$mm/$dd/$yyyy $hour"
	}
	3	{
	    set datepg "$mm/$dd/$yyyy $hour"
	}
	default	{
	    set datepg ""
	}
    }

    if {$datepg ne ""} then {
	if {[catch {clock scan $datepg}]} then {
	    set datepg ""
	}
    }
    return $datepg
}

#
# Convert a 802.11b/g radio frequency (2.4 GHz band) into a channel
#
# Input:
#   - parameters:
#       - freq : frequency
#   - global variable libconf(freq:<frequency>) : conversion table
# Output:
#   - return value: channel
#
# History
#   2008/07/30 : pda      : design
#   2008/10/17 : pda      : channel "dfs"
#   2010/12/05 : pda      : i18n
#

proc conv-channel {freq} {
    global libconf

    switch -- $freq {
	dfs {
	    set channel "auto"
	}
	default {
	    if {[info exists libconf(freq:$freq)]} then {
		set channel $libconf(freq:$freq)
	    } else {
		set channel "$freq MHz"
	    }
	}
    }
    return $channel
}

#
# Read list of interfaces on an equipment
#
# Input:
#   - parameters:
#	- eq : equipment name
#	- _tabuid : user's characteristics (including graph flags)
#   - global variables :
#	- libconf(extracteq) : call to extracteq
# Output:
#   - return value: {eq type model location iflist liferr arrayif arrayvlan}
#	where
#	- iflist is the sorted list of interfaces
#	- liferr is the list of interfaces which are are writable but not
#		readable (e.g. this is an error)
#	- arrayif (ready for "array set") gives an array indexed by
#		interface name:
#		tab(iface) {name edit radio stat mode desc link native {vlan...}}
#		(see extracteq output format)
#	- arrayvlan (ready for "array set") gives an array indexed by vlanid:
#		tab(id) {desc-in-hex voip-0-or-1}
#
# History
#   2010/11/03 : pda      : design
#   2010/11/15 : pda      : remove parameter err
#   2010/11/23 : pda/jean : get writable interfaces
#   2010/11/25 : pda      : add manual
#   2010/12/05 : pda      : i18n
#

proc eq-iflist {eq _tabuid} {
    global libconf
    upvar $_tabuid tabuid

    #
    # First call to extracteq : get the list of "readable" interfaces
    #

    set found 0

    set cmd [format $libconf(extracteq) $tabuid(flagsr) $eq]
    set fd [open "|$cmd" "r"]
    while {[gets $fd line] > -1} {
	switch [lindex $line 0] {
	    eq {
		set r [lreplace $line 0 0]

		set location [lindex $r 3]
		if {$location eq "-"} then {
		    set location ""
		} else {
		    set location [binary format H* $location]
		}
		set r [lreplace $r 3 3 $location]

		# manual = "manual" or "auto"
		set manual [lindex $r 4]
		set r [lreplace $r 4 4]

		set found 1
	    }
	    iface {
		set if [lindex $line 1]
		# prepare "edit" item, which may be set in the second
		# call to extracteq
		set line [linsert $line 2 "-"]
		set tabiface($if) [lreplace $line 0 0]
	    }
	}
    }
    if {[catch {close $fd} msg]} then {
	d error [format [mc {Error during extraction of readable interfaces from '%1$s': %2$s}] $eq $msg]
    }

    if {! $found} then {
	d error [format [mc "Equipment '%s' not found"] $eq]
    }

    #
    # Second call to exctracteq : get the list of "writable" interfaces
    #

    set liferr {}

    if {$manual eq "auto"} then {
	set cmd [format $libconf(extracteq) $tabuid(flagsw) $eq]
	set fd [open "|$cmd" "r"]
	while {[gets $fd line] > -1} {
	    switch [lindex $line 0] {
		iface {
		    set if [lindex $line 1]
		    if {! [info exists tabiface($if)]} then {
			# add this interface to the list of error interfaces
			lappend liferr $if
		    } else {
			# set the "edit" attribute on this interface
			set tabiface($if) [lreplace $tabiface($if) 1 1 "edit"]
		    }
		}
		vlan {
		    lassign $line bidon id desc voip
		    set tabvlan($id) [list $desc $voip]
		}
	    }
	}
	if {[catch {close $fd} msg]} then {
	    d error [format [mc {Error during extraction of writable interfaces from '%1$s': %2$s}] $eq $msg]
	}

	set liferr [lsort -command compare-interfaces $liferr]
    }

    lappend r $liferr

    #
    # Sort interfaces
    #

    set iflist [lsort -command compare-interfaces [array names tabiface]]

    #
    # Return value
    #

    lappend r $iflist
    lappend r [array get tabiface]
    lappend r [array get tabvlan]

    return $r
}

#
# Get graph and equipment status
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- eq : equipment name
#	- iface (optional) : interface name
# Output:
#   - return value: HTML text giving graph and equipment status
#
# History:
#   2010/11/29 : pda/jean : design
#   2010/12/05 : pda      : i18n
#

proc eq-graph-status {dbfd eq {iface {}}} {
    global libconf

    #
    # Search for equipment idrr in the database
    #
    
    if {! [regexp {^([^.]+)\.(.+)$} $eq bidon host domain]} then {
        set host $eq
        set domain %DEFDOM%
    }

    set iddom [read-domain $dbfd $domain]
    if {$iddom == -1} then {
	d error [format [mc "Domain '%s' not found"] $domain]
    }
    if {! [read-rr-by-name $dbfd $host $iddom tabrr]} then {
	d error [format [mc "Equipment '%s' not found"] $eq]
    }
    set idrr $tabrr(idrr)

    #
    # Search for unprocessed modifications and build information.
    #

    set wif ""
    if {$iface ne ""} then {
	set qiface [::pgsql::quote $iface]
	set wif "AND iface = '$qiface'"
    }

    set sql "SELECT * FROM topo.ifchanges
			WHERE idrr = $idrr AND processed = 0 $wif
			ORDER BY reqdate DESC"
    set lines {}
    lappend lines [list Title4 [mc "Date"] [mc "Login"] [mc "Interface"] [mc "Change"]]
    pg_select $dbfd $sql tab {
	set ifdesc $tab(ifdesc)
	set ethervlan $tab(ethervlan)
	set voicevlan $tab(voicevlan)
	set chg [format [mc "description='%s'"] $ifdesc]
	if {$ethervlan == -1} then {
	    append chg ", "
	    append chg [mc "deactivated interface"]
	} else {
	    append chg ", "
	    append chg [format [mc "vlan=%s"] $ethervlan]
	    if {$voicevlan != -1} then {
		append chg ", "
		append chg [format [mc "voip=%s"] $voicevlan]
	    }
	}
	lappend lines [list Normal4 $tab(reqdate) $tab(login) $tab(iface) $chg]
    }
    if {[llength $lines] == 1} then {
	set ifchg ""
    } else {
	set ifchg [::webapp::helem "p" [mc "Changes currently processed:"]]
	append ifchg [::arrgen::output "html" $libconf(tabeqstatus) $lines]
    }

    #
    # Search for current topod status
    #

    set sql "SELECT message FROM topo.keepstate WHERE type = 'status'"
    set action ""
    pg_select $dbfd $sql tab {
	catch {lassign [lindex $tab(message) 0] date action}
    }

    switch -nocase -glob $action {
	rancid* -
	building* {
	    set graph [::webapp::helem "p" [mc "Graph currenty re-builded. Informations presented here are not necessarily consistent with current equipement configuration."]]
	}
	default {
	    set graph ""
	}
    }

    #
    # Present information from $ifchg and $graph
    #

    if {$ifchg eq "" && $graph eq ""} then {
	set html ""
    } else {
	set html "$graph\n$ifchg"
	set html [::webapp::helem "font" $html "color" "#ff0000"]
	set html "<hr>$html<hr>"
    }

    return $html
}
