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

package require snit			;# tcllib
package require msgcat			;# tcl

namespace import ::msgcat::*

##############################################################################
# Library parameters
##############################################################################

#
# Various table specifications
#

set libconf(tabdroits) {
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

set libconf(tabreseaux) {
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

set libconf(tabdomaines) {
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

set libconf(tabdhcpprofil) {
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

set libconf(tabcorresp) {
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

##############################################################################
# Gestion des programmes WebDNS
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
	admtitle	{%HOMEURL%/bin/admin Admin}
	:topo		{
			    {eq always}
			    {l2 always}
			    {l3 always}
			    {topotop admin}
			    {dnstitle dns}
			    {admtitle admin}
			}
	eq		{%HOMEURL%/bin/eq Equipments}
	l2		{%HOMEURL%/bin/l2 Vlans}
	l3		{%HOMEURL%/bin/l3 Networks}
	dnstitle	{%HOMEURL%/bin/accueil DNS/DHCP}
	:admin		{
			    {admtitle always}
			    {consultmx always}
			    {statcor always}
			    {statetab always}
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
			    {admgrpsel always}
			    {admgenliste always}
			    {admparliste always}
			    {topotop topo}
			    {dnstitle dns}
			    {topotitle topo}
			}
	consultmx	{%HOMEURL%/bin/consultmx {Consult MX}}
	statcor		{%HOMEURL%/bin/statcor {Statistics by user}}
	statetab	{%HOMEURL%/bin/statetab {Statistics by organization}}
	consultnet	{%HOMEURL%/bin/consultnet {Consult networks}}
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
	admgrpsel	{%HOMEURL%/bin/admgrpsel {Modify users and groups}}
	admgenliste	{%HOMEURL%/bin/admgenliste {Force zone generation}}
	admparliste	{%HOMEURL%/bin/admparliste {Application parameters}}
	topotop		{%HOMEURL%/bin/topotop {Topod status}}
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

	set msg [read-user $dbfd $login tabuid]
	if {$msg ne ""} then {
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

	    lassign [read-user $dbfd $login tabuid] msg arg
	    if {$msg ne ""} then {
		$self error [format [mc $msg] $arg]
	    }
	    if {! $tabuid(present)} then {
		$self error [format [mc "User '%s' not authorized"] $login]
	    }
	}

	#
	# Computes capacity, given local installation and/or user rights
	#

	set curcap	{}
	lappend curcap "dns"
	if {[dnsconfig get "topoactive"]} then {
	    lappend curcap "topo"
	}
	if {$tabuid(admin)} then {
	    lappend curcap "admin"
	}

	#
	# Is this page an "admin" only page ?
	#

	if {[llength $attr] > 0} then {
	    # XXX : for now, test only one attribute
	    if {! [attribut-correspondant $dbfd $tabuid(idcor) $attr]} then {
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
	    }
	    *.tex {
		set fmt pdf
	    }
	    default {
		set fmt "unknown"
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

	::webapp::send $fmt [::webapp::file-subst $page $lsubst]
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
# Cosmétique
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
#	- libconf(tabcorresp) : array specification
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
    return [::arrgen::output "html" $libconf(tabcorresp) $lines]
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
    set sql "SELECT groupe.$attribut \
			FROM global.groupe, global.corresp \
			WHERE corresp.idcor = $idcor \
			    AND corresp.idgrp = groupe.idgrp"
    pg_select $dbfd $sql tab {
	set v "$tab($attribut)"
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
#		idcor	user id in the database
#		idgrp	group id in the database
#		groupe	group name
#		present	1 if "present" in the database
#		admin	1 if admin
#		reseaux	list of authorized networks
#		eq	regexp matching authorized equipments
#		flagsr	flags -n/-e/-E/etc to use in topo programs
#		flagsw	flags -n/-e/-E/etc to use in topo programs
# Output:
#   - return value: empty string or error message
#   - parameter _tabuid : values in return
#
# History
#   2003/05/13 : pda/jean : design
#   2007/10/05 : pda/jean : adaptation to "authuser" and "authbase" objects
#   2010/11/09 : pda      : renaming (car plus de recherche par id)
#   2010/11/29 : pda      : i18n
#

proc read-user {dbfd login _tabuid} {
    global ah
    upvar $_tabuid tabuid

    catch {unset tabuid}

    #
    # Attributes common to all applications
    #

    set u [::webapp::authuser create %AUTO%]
    if {[catch {set n [$ah getuser $login $u]} msg]} then {
	return [format [mc "Authentication base problem: %s"] $msg]
    }
    
    switch $n {
	0 {
	    return [format [mc "User '%s' is not in the authentication base"] $login]
	}
	1 { 
	    # Rien
	}
	default {
	    return [mc "Found too many users"]
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
    }

    if {$tabuid(idcor) == -1} then {
	return [format [mc "User '%s' is not in the WebDNS base"] $login]
    }

    #
    # Topo specific characteristics
    #

    # Read authorized CIDR
    set tabuid(reseaux) [liste-reseaux-autorises $dbfd $tabuid(idgrp) "dhcp"]

    # Read regexp to allow or deny access to equipments
    set tabuid(eqr) [lire-eq-autorises $dbfd 0 $tabuid(idgrp)]
    set tabuid(eqw) [lire-eq-autorises $dbfd 1 $tabuid(idgrp)]

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

    return {}
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
#	_trr(adrmail) : les idrr des adresses de messagerie hébergées
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
	    set trr(dhcpprofil) "Aucun profil"
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
# Valide la syntaxe d'un FQDN complet au sens de la RFC 1035
# élargie pour accepter les chiffres en début de nom.
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- fqdn : name to test
#	- _name : contiendra en retour le nom de host
#	- _domain : contiendra en retour le domaine de host
#	- _iddom : contiendra en retour l'id du domaine
# Output:
#   - return value: empty string or error message
#   - parameter _name : le nom trouvé
#   - parameter _domain : le domaine trouvé
#   - parameter _iddom : l'id du domaine trouvé, ou -1 si erreur
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
#   2004/10/20 : jean     : forbit / for anything else than cidr type
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
		set r [mc "The '/' character is not valid in the address"]
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
    } elseif {$domaine eq ""} then {
	set sql "SELECT domaine FROM dns.domaine WHERE iddom = $iddom"
	pg_select $dbfd $sql tab {
	    set domain $tab(domaine)
	}
	if {domaine eq ""} then {
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
#		then check-all-IP-addresses (hébergeur, idcor)
#		      check-domain (domain, idcor, "")
#	    if name.domain has IP addresses
#		then check-all-IP-addresses (machine, idcor)
#	    if no test is false, then OK
#	"existing-host"
#	    idem "host", but the name must be have at least one IP address
#	"del-name"
#	    check-domain (domain, idcor, "")
#	    if name.domain is ALIAS
#		then check-all-IP-addresses (machine pointée, idcor)
#	    if name.domain is MX then error
#	    if name.domain has IP addresses
#		then check-all-IP-addresses (machine, idcor)
#	    if name.domain is ADDRMAIL
#		then check-all-IP-addresses (hébergeur, idcor)
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
#		then check-all-IP-addresses (échangeurs, idcor)
#	    if name.domain is ADDRMAIL then error
#	    if no test is false, then OK
#	"addrmail"
#	    check-domain (domain, idcor, "rolemail")
#	    if name.domain is ALIAS then error
#	    if name.domain is MX then error
#	    if name.domain is ADDRMAIL
#		check-all-IP-addresses (hébergeur, idcor)
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
				    return [format [mc "Internal error: id '%s' doesn't exists for a mailhost"] $idrr]
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
		    if {$parm eq "EXISTS"]} {
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

proc check-mx {dbfd prio name domain idcor _msg} {
    upvar $_msg msg

    #
    # Syntaxic checking of priority
    #

    if {! [regexp {^[0-9]+$} $prio]} then {
	set msg [format [mc "Invalid MX priority '%s'"] $prio]
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
	    return [format [mc {You don't have rights to some relays of domain '%1$s'\n%2$s}] \
			    $domain $msg]
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
# XXX : NOT USED
#
# Lit le groupe associé à un correspondant
#
# Input:
#   - parameters:
#       - dbfd : database handle
#	- idcor : l'id du correspondant
# Output:
#   - return value: id du groupe si trouvé, ou -1
#
# History
#   2002/05/06 : pda/jean : design
#

proc lire-groupe {dbfd idcor} {
    set idgrp -1
    set sql "SELECT idgrp FROM global.corresp WHERE idcor = $idcor"
    pg_select $dbfd $sql tab {
	set idgrp	$tab(idgrp)
    }
    return $idgrp
}

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
# Récupération d'informations pour les menus
##############################################################################

#
# Récupère les HINFO possibles sous forme d'un menu HTML prêt à l'emploi
#
# Input:
#   - dbfd : database handle
#   - champ : champ de formulaire (variable du CGI suivant)
#   - defval : hinfo (texte) par défaut
# Output:
#   - return value: code HTML prêt à l'emploi
#
# History
#   2002/05/03 : pda/jean : design
#

proc menu-hinfo {dbfd champ defval} {
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
    return [::webapp::form-menu $champ 1 0 $lhinfo [list $defindex]]
}

#
# Récupère les profils DHCP accessibles par le groupe sous forme d'un
# menu visible, ou un champ caché si le groupe n'a accès à aucun profil
# DHCP.
#
# Input:
#   - dbfd : database handle
#   - champ : champ de formulaire (variable du CGI suivant)
#   - idcor : identification du correspondant
#   - iddhcpprofil : identification du profil à sélectionner (le profil
#	pré-existant) ou 0
# Output:
#   - return value: liste avec deux éléments de code HTML prêt à l'emploi
#	(intitulé, menu de sélection)
#
# History
#   2005/04/08 : pda/jean : design
#   2008/07/23 : pda/jean : changement format sortie
#

proc menu-dhcpprofil {dbfd champ idcor iddhcpprofil} {
    #
    # Récupérer les profils DHCP visibles par le groupe
    # ainsi que le profil DHCP pré-existant
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
    # A-t'on trouvé au moins un profil ?
    #

    if {[llength $lprof] > 0} then {
	#
	# Est-ce que le profil pré-existant est bien dans notre
	# liste ?
	#

	if {$iddhcpprofil != 0 && [llength $lsel] == 0} then {
	    #
	    # Non. On va donc ajouter à la fin de la liste
	    # le profil pré-existant
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
	# Ajouter le cas spécial en début de liste
	#

	set lprof [linsert $lprof 0 {0 {Aucun profil}}]

	set intitule "Profil DHCP"
	set html [::webapp::form-menu iddhcpprofil 1 0 $lprof $lsel]

    } else {
	#
	# Aucun profil trouvé. On cache l'information
	#

	set intitule ""
	set html "<INPUT TYPE=HIDDEN NAME=\"$champ\" VALUE=\"$iddhcpprofil\">"
    }

    return [list $intitule $html]
}

#
# Récupère le droit d'émettre en SMTP d'une machine, ou un champ caché
# si le groupe n'a pas accès à la fonctionnalité
#
# Input:
#   - dbfd : database handle
#   - champ : champ de formulaire (variable du CGI suivant)
#   - idcor : identification du correspondant
#   - droitsmtp : valeur actuelle (donc à présélectionner)
# Output:
#   - return value: liste avec deux éléments de code HTML prêt à l'emploi
#	(intitulé, choix de sélection)
#
# History
#   2008/07/23 : pda/jean : design
#   2008/07/24 : pda/jean : utilisation de idcor plutôt que idgrp
#

proc menu-droitsmtp {dbfd champ idcor droitsmtp} {
    #
    # Récupérer le droit SMTP pour afficher ou non le bouton
    # d'autorisation d'émettre en SMTP non authentifié
    #

    set grdroitsmtp [droit-correspondant-smtp $dbfd $idcor]
    if {$grdroitsmtp} then {
	set intitule "Émettre en SMTP"
	set html [::webapp::form-bool $champ $droitsmtp]
    } else {
	set intitule ""
	set html "<INPUT TYPE=HIDDEN NAME=\"$champ\" VALUE=\"$droitsmtp\">"
    }

    return [list $intitule $html]
}

#
# Récupère le TTL d'une machine, ou un champ caché
# si le groupe n'a pas accès à la fonctionnalité
#
# Input:
#   - dbfd : database handle
#   - champ : champ de formulaire (variable du CGI suivant)
#   - idcor : identification du correspondant
#   - ttl : valeur actuelle issue de la base
# Output:
#   - return value: code HTML prêt à l'emploi
#
# History
#   2010/10/31 : pda      : design
#

proc menu-ttl {dbfd champ idcor ttl} {
    #
    # Convertir la valeur de TTL issue de la base en valeur "affichable"
    #

    if {$ttl == -1} then {
	set ttl ""
    }

    #
    # Récupérer le droit TTL pour afficher ou non le champ de formulaire
    #

    set grdroitttl [droit-correspondant-ttl $dbfd $idcor]
    if {$grdroitttl} then {
	set intitule "TTL"
	set html [::webapp::form-text $champ 1 6 10 $ttl]
	append html " (en secondes)"
    } else {
	set intitule ""
	set html "<INPUT TYPE=HIDDEN NAME=\"$champ\" VALUE=\"$ttl\">"
    }

    return [list $intitule $html]
}


#
# Fournit le code HTML pour une sélection de liste de domaines, soit
# sous forme de menus déroulants si le nombre de domaines autorisés
# est > 1, soit un texte simple avec un champ HIDDEN si = 1.
#
# Input:
#   - dbfd : database handle
#   - idcor : id du correspondant
#   - champ : champ de formulaire (variable du CGI suivant)
#   - where : clause where (sans le mot-clef "where") ou chaîne vide
#   - sel : nom du domaine à pré-sélectionner, ou chaîne vide
# Output:
#   - return value: code HTML généré
#
# History :
#   2002/04/11 : pda/jean : codage
#   2002/04/23 : pda      : ajout de la priorité d'affichage
#   2002/05/03 : pda/jean : migration en librairie
#   2002/05/06 : pda/jean : utilisation des groupes
#   2003/04/24 : pda/jean : décomposition en deux procédures
#   2004/02/06 : pda/jean : ajout de la clause where
#   2004/02/12 : pda/jean : ajout du parameter sel
#   2010/11/15 : pda      : suppression parameter err
#

proc menu-domaine {dbfd idcor champ where sel} {
    set lcouples [couple-domaine-par-corresp $dbfd $idcor $where]

    set lsel [lsearch -exact $lcouples [list $sel $sel]]
    if {$lsel == -1} then {
	set lsel {}
    }

    #
    # S'il n'y a qu'un seul domaine, le présenter en texte, sinon
    # présenter tous les domaines dans un menu déroulant
    #

    set taille [llength $lcouples]
    switch -- $taille {
	0	{
	    d error "Désolé, mais vous n'avez aucun domaine actif"
	}
	1	{
	    set d [lindex [lindex $lcouples 0] 0]
	    set html "$d <INPUT TYPE=\"HIDDEN\" NAME=\"$champ\" VALUE=\"$d\">"
	}
	default	{
	    set html [::webapp::form-menu $champ 1 0 $lcouples $lsel]
	}
    }

    return $html
}

#
# Retourne une liste de couples {nom nom} pour chaque domaine
# autorisé pour le correspondant.
#
# Input:
#   - dbfd : database handle
#   - idcor : id du correspondant
#   - where : clause where (sans le mot-clef "where") ou chaîne vide
# Output:
#   - return value: liste de couples
#
# History :
#   2003/04/24 : pda/jean : codage
#   2004/02/06 : pda/jean : ajout de la clause where
#

proc couple-domaine-par-corresp {dbfd idcor where} {
    #
    # Récupération des domaines auxquels le correspond a accès
    # et construction d'une liste {{domaine domaine}} pour l'appel
    # ultérieur à "form-menu"
    #

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
# Récupération des informations associées à un groupe
##############################################################################

#
# Récupère la liste des groupes
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- n : 1 s'il faut une liste à 1 élément, 2 s'il en faut 2, etc.
# Output:
#   - return value: liste des noms (ou des {noms noms}) des groupes
#
# History
#   2006/02/17 : pda/jean/zamboni : création
#   2007/10/10 : pda/jean         : ignorer le groupe des orphelins
#

proc liste-groupes {dbfd {n 1}} {
    set l {}
    for {set i 0} {$i < $n} {incr i} {
	lappend l "nom"
    }
    return [::pgsql::getcols $dbfd global.groupe "nom <> ''" "nom ASC" $l]
}

#
# Fournit du code HTML pour chaque groupe d'informations associé à un
# groupe : les droits généraux du groupe, les correspondants, les
# réseaux, les droits hors réseaux, les domaines, les profils DHCP
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- idgrp : identificateur du groupe
#   - variable globale libconf(tabreseaux) : spéc. de tableau
#   - variable globale libconf(tabdomaines) : spéc. de tableau
# Output:
#   - return value: liste à 7 éléments, chaque élément étant
#	le code HTML associé.
#
# History
#   2002/05/23 : pda/jean : spécification et design
#   2005/04/06 : pda      : ajout des profils dhcp
#   2007/10/23 : pda/jean : ajout des correspondants
#   2008/07/23 : pda/jean : ajout des droits du groupe
#   2010/10/31 : pda      : ajout des droits ttl
#   2010/11/03 : pda/jean : ajout des droits sur les équipements
#

proc info-groupe {dbfd idgrp} {
    global libconf

    #
    # Récupération des droits particuliers : admin, droitsmtp et droitttl
    #

    set lines {}
    set sql "SELECT admin, droitsmtp, droitttl
			FROM global.groupe
			WHERE idgrp = $idgrp"
    pg_select $dbfd $sql tab {
	if {$tab(admin)} then {
	    set admin "oui"
	} else {
	    set admin "non"
	}
	if {$tab(droitsmtp)} then {
	    set droitsmtp "oui"
	} else {
	    set droitsmtp "non"
	}
	if {$tab(droitttl)} then {
	    set droitttl "oui"
	} else {
	    set droitttl "non"
	}
	lappend lines [list DROIT "Administration de l'application" $admin]
	lappend lines [list DROIT "Gestion des émetteurs SMTP" $droitsmtp]
	lappend lines [list DROIT "Édition des TTL" $droitttl]
    }
    if {[llength $lines] > 0} then {
	set tabdroits [::arrgen::output "html" $libconf(tabdroits) $lines]
    } else {
	set tabdroits "Erreur sur les droits du groupe"
    }

    #
    # Récupération des correspondants
    #

    set lcor {}
    set sql "SELECT login FROM global.corresp WHERE idgrp=$idgrp ORDER BY login"
    pg_select $dbfd $sql tab {
	lappend lcor [::webapp::html-string $tab(login)]
    }
    set tabcorresp [join $lcor ", "]

    #
    # Récupération des plages auxquelles a droit le correspondant
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

	# affadr : utilisé pour l'affichage cosmétique des adresses
	set affadr {}
	# where : partie de la clause WHERE pour la sélection des adresses
	set where  {}
	foreach a {adr4 adr6} {
	    if {$tab($a) ne ""} then {
		lappend affadr $tab($a)
		lappend where  "adr <<= '$tab($a)'"
	    }
	}
	set affadr [join $affadr ", "]
	set where  [join $where  " OR "]

	lappend lines [list Reseau $r_nom]
	lappend lines [list Normal4 Localisation $r_loc \
				Établissement $r_etabl]
	lappend lines [list Normal4 Plage $affadr \
				Communauté $r_commu]

	set droits {}

	set dres {}
	if {$r_dhcp} then { lappend dres "dhcp" }
	if {$r_acl} then { lappend dres "acl" }
	if {[llength $dres] > 0} then {
	    lappend droits [join $dres ", "]
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
	    lappend droits "$x $tab2(adr)"
	}

	lappend lines [list Droits Droits [join $droits "\n"]]
    }

    if {[llength $lines] > 0} then {
	set tabreseaux [::arrgen::output "html" $libconf(tabreseaux) $lines]
    } else {
	set tabreseaux "Aucun réseau autorisé"
    }

    #
    # Sélectionner les droits hors des plages réseaux identifiées
    # ci-dessus.
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
    set droits {}
    pg_select $dbfd $sql tab {
	set found 1
	if {$tab(allow_deny)} then {
	    set x "+"
	} else {
	    set x "-"
	}
	lappend droits "$x $tab(adr)"
    }
    lappend lines [list Droits Droits [join $droits "\n"]]

    if {$found} then {
	set tabcidrhorsreseau [::arrgen::output "html" \
						$libconf(tabreseaux) $lines]
    } else {
	set tabcidrhorsreseau "Aucun (tout va bien)"
    }


    #
    # Sélectionner les domaines
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
	    set rm "Édition des rôles de messagerie"
	}
	set rw ""
	if {$tab(roleweb)} then {
	    set rw "Édition des rôles web"
	}

	lappend lines [list Domaine $tab(nom) $rm $rw]
    }
    if {[llength $lines] > 0} then {
	set tabdomaines [::arrgen::output "html" $libconf(tabdomaines) $lines]
    } else {
	set tabdomaines "Aucun domaine autorisé"
    }

    #
    # Sélectionner les profils DHCP
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
	set tabdhcpprofil [::arrgen::output "html" $libconf(tabdhcpprofil) $lines]
    } else {
	set tabdhcpprofil "Aucun profil DHCP autorisé"
    }

    #
    # Sélectionner les droits sur les équipements
    #

    set lines {}
    foreach {rw text} {0 Lecture 1 Modification} {
	set sql "SELECT allow_deny, pattern
			    FROM topo.dr_eq
			    WHERE idgrp = $idgrp AND rw = $rw
			    ORDER BY rw, allow_deny DESC, pattern"
	set dr ""
	pg_select $dbfd $sql tab {
	    if {$tab(allow_deny) eq "0"} then {
		set allow_deny "-"
	    } else {
		set allow_deny "+"
	    }
	    append dr "$allow_deny $tab(pattern)\n"
	}
	if {$dr eq ""} then {
	    set dr "Aucun droit"
	}
	lappend lines [list DroitEq $text $dr]
    }
    set tabdreq [::arrgen::output "html" $libconf(tabdreq) $lines]

    #
    # Renvoyer les informations
    #

    return [list    $tabdroits \
		    $tabcorresp \
		    $tabreseaux \
		    $tabcidrhorsreseau \
		    $tabdomaines \
		    $tabdhcpprofil \
		    $tabdreq \
	    ]
}

#
# Fournit la liste des réseaux associés à un groupe avec un certain droit.
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- idgrp : identificateur du groupe
#	- droit : "consult", "dhcp" ou "acl"
# Output:
#   - return value: liste des réseaux sous la forme
#		{idreseau cidr4 cidr6 nom-complet}
#
# History
#   2004/01/16 : pda/jean : spécification et design
#   2004/08/06 : pda/jean : extension des droits sur les réseaux
#   2004/10/05 : pda/jean : adaptation aux nouveaux droits
#   2006/05/24 : pda/jean/boggia : séparation en une fonction élémentaire
#

proc liste-reseaux-autorises {dbfd idgrp droit} {
    #
    # Mettre en forme les droits pour la clause where
    #

    switch -- $droit {
	consult {
	    set w1 ""
	    set w2 ""
	}
	dhcp {
	    set w1 "AND d.$droit > 0"
	    set w2 "AND r.$droit > 0"
	}
	acl {
	    set w1 "AND d.$droit > 0"
	    set w2 ""
	}
    }

    #
    # Récupérer tous les réseaux autorisés par le groupe selon ce droit
    #

    set lres {}
    set sql "SELECT r.idreseau, r.nom, r.adr4, r.adr6
			FROM dns.reseau r, dns.dr_reseau d
			WHERE r.idreseau = d.idreseau
			    AND d.idgrp = $idgrp
			    $w1 $w2
			ORDER BY adr4, adr6"
    pg_select $dbfd $sql tab {
	lappend lres [list $tab(idreseau) $tab(adr4) $tab(adr6) $tab(nom)]
    }

    return $lres
}

#
# Fournit la liste de réseaux associés à un groupe avec un certain droit,
# prête à être utilisée dans un menu.
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- idgrp : identificateur du groupe
#	- droit : "consult", "dhcp" ou "acl"
# Output:
#   - return value: liste des réseaux sous la forme {idreseau nom-complet}
#
# History
#   2006/05/24 : pda/jean/boggia : séparation du coeur de la fonction
#

proc liste-reseaux {dbfd idgrp droit} {
    #
    # Présente la liste élémentaire retournée par liste-reseaux-autorises
    #

    set lres {}
    foreach r [liste-reseaux-autorises $dbfd $idgrp $droit] {
	lappend lres [list [lindex $r 0] \
			[format "%s\t%s\t(%s)" \
				[lindex $r 1] \
				[lindex $r 2] \
				[::webapp::html-string [lindex $r 3]] \
			    ] \
			]
    }

    return $lres
}

#
# Valide un idreseau tel que retourné par un formulaire. Cette validation
# est réalisé dans le contexte d'un groupe, avec test d'un droit particulier.
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- idreseau : id à vérifier
#	- idgrp : identificateur du groupe
#	- droit : "consult", "dhcp" ou "acl"
#	- version : 4, 6 ou {4 6}
#	- _msg : message d'erreur en retour
# Output:
#   - return value: liste de CIDR, ou liste vide
#   - parameter _msg : message d'erreur en retour si liste vide
#
# History
#   2004/10/05 : pda/jean : spécification et design
#

proc valide-idreseau {dbfd idreseau idgrp droit version _msg} {
    upvar $_msg msg

    #
    # Valider le numéro de réseau au niveau syntaxique
    #
    set idreseau [string trim $idreseau]
    if {! [regexp {^[0-9]+$} $idreseau]} then {
	set msg "Plage réseau invalide ($idreseau)"
	return {}
    }

    #
    # Convertir le droit en clause where
    #

    switch -- $droit {
	consult {
	    set w1 ""
	    set w2 ""
	    set c "en consultation"
	}
	dhcp {
	    set w1 "AND d.$droit > 0"
	    set w2 "AND r.$droit > 0"
	    set c "pour le droit '$droit'"
	}
	acl {
	    set w1 "AND d.$droit > 0"
	    set w2 ""
	    set c "pour le droit '$droit'"
	}
    }

    #
    # Valider le numéro de réseau et récupérer le ou les CIDR associé(s)
    #

    set lcidr {}
    set msg ""

    set sql "SELECT r.adr4, r.adr6
		    FROM dns.dr_reseau d, dns.reseau r
		    WHERE d.idgrp = $idgrp
			AND d.idreseau = r.idreseau
			AND r.idreseau = $idreseau
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

    set vide4 [string equal $cidrplage4 ""]
    set vide6 [string equal $cidrplage6 ""]

    switch -glob $vide4-$vide6 {
	1-1 {
	    set msg "Vous n'avez pas accès à ce réseau $c"
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

#
# Indique si le groupe du correspondant a le droit d'autoriser des
# émetteurs SMTP.
#
# Input:
#   - parameters:
#       - dbfd : database handle
#	- idcor : user id
# Output:
#   - return value: 1 if ok, 0 if error
#
# History
#   2008/07/23 : pda/jean : design
#   2008/07/24 : pda/jean : changement de idgrp en idcor
#

proc droit-correspondant-smtp {dbfd idcor} {
    set sql "SELECT droitsmtp FROM global.groupe g, global.corresp c 
				WHERE g.idgrp = c.idgrp AND c.idcor = $idcor"
    set r 0
    pg_select $dbfd $sql tab {
	set r $tab(droitsmtp)
    }
    return $r
}

#
# Indique si le groupe du correspondant a le droit d'éditer les TTL
#
# Input:
#   - parameters:
#       - dbfd : database handle
#	- idcor : user id
# Output:
#   - return value: 1 if ok, 0 if error
#
# History
#   2010/10/31 : pda/jean : design
#

proc droit-correspondant-ttl {dbfd idcor} {
    set sql "SELECT droitttl FROM global.groupe g, global.corresp c 
				WHERE g.idgrp = c.idgrp AND c.idcor = $idcor"
    set r 0
    pg_select $dbfd $sql tab {
	set r $tab(droitttl)
    }
    return $r
}


##############################################################################
# Edition de valeurs de tableau
##############################################################################

#
# Présente le contenu d'une table pour édition des valeurs qui s'y trouvent
#
# Input:
#   - parameters:
#	- largeurs : largeurs des colonnes pour la spécification du tableau
#		au format {largeur1 largeur2 ... largeurn} (en %)
#	- titre : spécification des titres (format et valeur)
#		au format {type valeur} où type = texte ou html
#	- spec : spécification des lignes normales
#		au format {id type defval} où
#			- id : identificateur de la colonne dans la table
#				et nom du champ de formulaire (idNNN ou idnNNN)
#			- type : texte, string N, bool, menu L, textarea L H
#			- defval : valeur par défaut pour les nouvelles lignes
#	- dbfd : database handle
#	- sql : requête select contenant en particulier les champs "id"
#	- idnum : nom de la colonne représentant l'identificateur numérique
#	- _tab : tableau passé par variable, vide en entrée
# Output:
#   - return value: empty string or error message
#   - parameter _tab : un tableau HTML complet
#
# History
#   2001/11/01 : pda      : spécification et documentation
#   2001/11/01 : pda      : codage
#   2002/05/03 : pda/jean : type menu
#   2002/05/06 : pda/jean : type textarea
#   2002/05/16 : pda      : conversion à arrgen
#

proc edition-tableau {largeurs titre spec dbfd sql idnum _tab} {
    upvar $_tab tab

    #
    # Petit test d'intégrité sur le nombre de colonnes (doit être
    # identique dans les largeurs, dans les titres et dans les
    # lignes normales
    #

    if {[llength $titre] != [llength $spec] || \
	[llength $titre] != [llength $largeurs]} then {
	return "Interne (edition-tableau): Spécification de tableau invalide"
    }

    #
    # Construire la spécification du tableau : comme c'est fastidieux,
    # on l'a mis dans une procédure à part.
    #

    set spectableau [edition-tableau-motif $largeurs $titre $spec]
    set lines {}

    #
    # Sortir le titre
    #

    set ligne {}
    lappend ligne Titre
    foreach t $titre {
	lappend ligne [lindex $t 1]
    }
    lappend lines $ligne

    #
    # Sortir les lignes du tableau
    #

    pg_select $dbfd $sql tabsql {
	set tabsql(:$idnum) $tabsql($idnum)
	lappend lines [edition-ligne $spec tabsql $idnum]
    }

    #
    # Ajouter de nouvelles lignes
    #

    foreach s $spec {
	set key [lindex $s 0]
	set defval [lindex $s 2]
	set tabdef($key) $defval
    }

    for {set i 1} {$i <= 5} {incr i} {
	set tabdef(:$idnum) "n$i"
	lappend lines [edition-ligne $spec tabdef $idnum]
    }

    #
    # Transformer le tout en joli tableau
    #

    set tab [::arrgen::output "html" $spectableau $lines]

    #
    # Tout s'est bien passé !
    #

    return ""
}

#
# Construit une spécification de tableau pour arrgen à partir des
# parameters passés à edition-tableau
#
# Input:
#   - parameters:
#	- largeurs : largeurs des colonnes pour la spécification du tableau
#	- titre : spécification des titres (format et valeur)
#	- spec : spécification des lignes normales
# Output:
#   - return value: une spécification de tableau prête pour arrgen
#
# Note : voir la signification des parameters dans edition-tableau
#
# History
#   2001/11/01 : pda : design et documentation
#   2002/05/16 : pda : conversion à arrgen
#

proc edition-tableau-motif {largeurs titre spec} {
    #
    # Construire le motif des titres d'abord
    #
    set motif_titre "motif {Titre} {"
    foreach t $titre {
	append motif_titre "vbar {yes} "
	append motif_titre "chars {bold} "
	append motif_titre "align {center} "
	append motif_titre "column { "
	append motif_titre "  botbar {yes} "
	if {[string compare [lindex $t 0] "texte"] != 0} then {
	    append motif_titre "  format {raw} "
	}
	append motif_titre "} "
    }
    append motif_titre "vbar {yes} "
    append motif_titre "} "

    #
    # Ensuite, les lignes normales
    #
    set motif_normal "motif {Normal} {"
    foreach t $spec {
	append motif_normal "topbar {yes} "
	append motif_normal "vbar {yes} "
	append motif_normal "column { "
	append motif_normal "  align {center} "
	append motif_normal "  botbar {yes} "
	set type [lindex [lindex $t 1] 0]
	if {[string compare $type "texte"] != 0} then {
	    append motif_normal "  format {raw} "
	}
	append motif_normal "} "
    }
    append motif_normal "vbar {yes} "
    append motif_normal "} "

    #
    # Et enfin les spécifications globales
    #
    set spectableau "global { chars {12 normal} "
    append spectableau "columns {$largeurs} } $motif_titre $motif_normal"

    return $spectableau
}

#
# Présente le contenu d'une ligne d'une table
#
# Input:
#   - parameters:
#	- spec : spécification des lignes normales, voir edition-tableau
#	- tab : tableau indexé par les champs spécifiés dans spec
#	- idnum : nom de la colonne représentant l'identificateur numérique
# Output:
#   - return value: une ligne de tableau prête pour arrgen
#
# History
#   2001/11/01 : pda      : spécification et documentation
#   2001/11/01 : pda      : design
#   2002/05/03 : pda/jean : ajout du type menu
#   2002/05/06 : pda/jean : ajout du type textarea
#   2002/05/16 : pda      : conversion à arrgen
#

proc edition-ligne {spec _tab idnum} {
    upvar $_tab tab

    set ligne {Normal}
    foreach s $spec {
	set key [lindex $s 0]
	set valeur $tab($key)

	set type [lindex [lindex $s 1] 0]
	set opt [lindex [lindex $s 1] 1]

	set num $tab(:$idnum)
	set ref $key$num

	switch $type {
	    texte {
		set item $valeur
	    }
	    string {
		set item [::webapp::form-text $ref 1 $opt 0 $valeur]
	    }
	    bool {
		set checked ""
		if {$valeur} then { set checked " CHECKED" }
		set item "<INPUT TYPE=checkbox NAME=$ref VALUE=1$checked>"
	    }
	    menu {
		set sel 0
		set i 0
		foreach e $opt {
		    # recherche obligatoirement le premier élément de la liste
		    set id [lindex $e 0]
		    if {$id eq $valeur} then {
			set sel $i
		    }
		    incr i
		}
		set item [::webapp::form-menu $ref 1 0 $opt [list $sel]]
	    }
	    textarea {
		set largeur [lindex $opt 0]
		set hauteur [lindex $opt 1]
		set item [::webapp::form-text $ref $hauteur $largeur 0 $valeur]
	    }
	}
	lappend ligne $item
    }

    return $ligne
}

#
# Récupère les modifications d'un formulaire généré par edition-tableau
# et les enregistre dans la base si nécessaire
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- spec : spécification des colonnes à modifier (voir plus bas)
#	- idnum : nom de la colonne représentant l'identificateur numérique
#	- table : nom de la table à modifier
#	- _tab : tableau contenant les champs du formulaire
# Output:
#   - return value: empty string or error message
#
# Notes :
#   - le format du parameter "spec" est {{colonne defval} ...}, où :
#	- colonne est l'identificateur de la colonne dans la table
#	- defval, si présent, indique la valeur par défaut à mettre dans
#		la table car la valeur n'est pas fournie dans le formulaire
#   - la première colonne de "spec" est utilisée pour savoir s'il faut
#	ajouter ou supprimer l'entrée correspondante
#
# History
#   2001/11/02 : pda      : spécification et documentation
#   2001/11/02 : pda      : codage
#   2002/05/03 : pda/jean : suppression contrainte sur les tickets
#

proc enregistrer-tableau {dbfd spec idnum table _tab} {
    upvar $_tab ftab

    #
    # Verrouillage de la table concernée
    #

    if {! [::pgsql::execsql $dbfd "BEGIN WORK ; LOCK $table" msg]} then {
	return "Verrouillage impossible ('$msg')"
    }

    #
    # Dernier numéro d'enregistrement attribué
    #

    set max 0
    pg_select $dbfd "SELECT MAX($idnum) FROM $table" tab {
	set max $tab(max)
    }

    #
    # La clef pour savoir si une entrée doit être détruite (pour les
    # id existants) ou ajoutée (pour les nouveaux id)
    #


    set key [lindex [lindex $spec 0] 0]

    #
    # Parcours des numéros déjà existants dans la base
    #

    set id 1

    for {set id 1} {$id <= $max} {incr id} {
	if {[info exists ftab(${key}${id})]} {
	    remplir-tabval $spec "" $id ftab tabval

	    if {[string length $tabval($key)] == 0} then {
		#
		# Destruction de l'entrée.
		#

		set ok [retirer-entree $dbfd msg $id $idnum $table]
		if {! $ok} then {
		    ::pgsql::execsql $dbfd "ABORT WORK" m
		    #
		    # En cas de destruction impossible, il faut
		    # dire ce qu'on n'arrive pas à supprimer.
		    # Pour cela, il faut rechercher le vieux nom dans
		    # la base.
		    #

		    set oldkey ""
		    pg_select $dbfd "SELECT $key FROM $table \
				    WHERE $idnum = $id" t {
			set oldkey $t($key)
		    }
		    return "Erreur dans la suppression de '$oldkey' ('$msg')"
		}
	    } else {
		#
		# Modification de l'entrée
		#

		set ok [modifier-entree $dbfd msg $id $idnum $table tabval]
		if {! $ok} then {
		    ::pgsql::execsql $dbfd "ABORT WORK" m
		    return "Erreur dans la modification de '$tabval($key)' ('$msg')"
		}
	    }
	}
    }

    #
    # Nouvelles entrées
    #

    set idnew 1
    while {[info exists ftab(${key}n${idnew})]} {
	remplir-tabval $spec "n" $idnew ftab tabval

	if {[string length $tabval($key)] > 0} then {
	    #
	    # Ajout de l'entrée
	    #

	    set ok [ajouter-entree $dbfd msg $table tabval]
	    if {! $ok} then {
		::pgsql::execsql $dbfd "ABORT WORK" m
		return "Erreur dans l'ajout de '$tabval($key)' ('$msg')"
	    }
	}

	incr idnew
    }

    #
    # Déverrouillage, et enregistrement des modifications avant la sortie
    #

    if {! [::pgsql::execsql $dbfd "COMMIT WORK" msg]} then {
	::pgsql::execsql $dbfd "ABORT WORK" m
	return "Déverrouillage impossible, modification annulée ('$msg')"
    }

    return ""
}

#
# Lit les champs dans les formulaires, en complétant éventuellement pour
# les champs booléens (checkbox) qui peuvent ne pas être présents.
#
# Input:
#   - parameters:
#	- spec : voir enregistrer-tableau
#	- prefixe : "" (entrée existante) ou "n" (nouvelle entrée)
#	- num : numéro de l'entrée
#	- _ftab : le tableau issu de get-data
#	- _tabval : le tableau à remplir
# Output:
#   - return value: none
#   - parameter _tabval : contient les champs
#
# Note :
#   - si spec contient {{login} {nom}}, prefixe contient "n" et num "5"
#     alors on cherche ftab(loginn5) et ftab(nomn5)
#	 et on met ça dans tabval(login) et tabval(nom)
#
# History :
#   2001/04/01 : pda : design
#   2001/04/03 : pda : documentation
#   2001/11/02 : pda : reprise et extension
#

proc remplir-tabval {spec prefixe num _ftab _tabval} {
    upvar $_ftab ftab
    upvar $_tabval tabval

    foreach coldefval $spec {

	set col [lindex $coldefval 0]

	if {[llength $coldefval] == 2} then {
	    #
	    # Valeur par défaut : on ne la prend pas dans le formulaire
	    #

	    set val [lindex $coldefval 1]

	} else {

	    #
	    # Pas de valeur par défaut : on recherche dans le formulaire.
	    # Si on ne trouve pas dans le formulaire, c'est un booléen
	    # qui n'a pas été fourni, on prend 0 comme valeur.
	    #

	    set form ${col}${prefixe}${num}

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
# Modification d'une entrée
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- msg : variable contenant, en retour, le message d'erreur éventuel
#	- id : l'id (valeur) de l'entrée à modifier
#	- idnum : nom de la colonne des id de la table
#	- table : nom de la table à modifier
#	- _tabval : tableau contenant les valeurs à modifier
# Output:
#   - return value: 1 if ok, 0 if error
#   - parameters:
#	- msg : message d'erreur si erreur
#
# History :
#   2001/04/01 : pda : design
#   2001/04/03 : pda : documentation
#   2001/11/02 : pda : généralisation
#   2004/01/20 : pda/jean : ajout d'un attribut NULL si chaîne vide (pour ipv6)
#

proc modifier-entree {dbfd msg id idnum table _tabval} {
    upvar $msg m
    upvar $_tabval tabval

    #
    # Tout d'abord, il n'y a pas besoin de modifier quoi que ce soit
    # si toutes les valeurs sont identiques.
    #

    set different 0
    pg_select $dbfd "SELECT * FROM $table WHERE $idnum = $id" tab {
	foreach attribut [array names tabval] {
	    if {[string compare $tabval($attribut) $tab($attribut)] != 0} then {
		set different 1
		break
	    }
	}
    }

    set ok 1

    if {$different} then {
	#
	# C'est différent, il faut donc y aller...
	#

	set liste {}
	foreach attribut [array names tabval] {
	    if {$tabval($attribut) eq ""} then {
		set v "NULL"
	    } else {
		set v "'[::pgsql::quote $tabval($attribut)]'"
	    }
	    lappend liste "$attribut = $v"
	}
	set sql "UPDATE $table SET [join $liste ,] WHERE $idnum = $id"
	set ok [::pgsql::execsql $dbfd $sql m]
    }

    return $ok
}

#
# Retrait d'une entree
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- _msg : variable contenant, en retour, le message d'erreur éventuel
#	- id : l'id (valeur) de l'entrée à modifier
#	- idnum : nom de la colonne des id de la table
#	- table : nom de la table à modifier
# Output:
#   - return value: 1 if ok, 0 if error
#   - parameters:
#	- msg : message d'erreur si erreur
#
# History :
#   2001/04/03 : pda      : design
#   2001/11/02 : pda      : généralisation
#   2002/05/03 : pda/jean : suppression contrainte sur les tickets
#

proc retirer-entree {dbfd _msg id idnum table} {
    upvar $_msg msg

    set sql "DELETE FROM $table WHERE $idnum = $id"
    set ok [::pgsql::execsql $dbfd $sql msg]

    return $ok
}

#
# Ajout d'une entrée
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- msg : variable contenant, en retour, le message d'erreur éventuel
#	- table : nom de la table à modifier
#	- _tabval : tableau contenant les valeurs à ajouter
# Output:
#   - return value: 1 if ok, 0 if error
#   - parameters:
#	- msg : message d'erreur si erreur
#
# History :
#   2001/04/01 : pda : design
#   2001/04/03 : pda : documentation
#   2001/11/02 : pda : généralisation
#   2004/01/20 : pda/jean : ajout d'un attribut NULL si chaîne vide (pour ipv6)
#

proc ajouter-entree {dbfd msg table _tabval} {
    upvar $msg m
    upvar $_tabval tabval

    #
    # Nom des colonnes
    #
    set cols [array names tabval]

    #
    # Valeur des colonnes
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
    set ok [::pgsql::execsql $dbfd $sql m]
    return $ok
}

##############################################################################
# Accès aux parameters de configuration
##############################################################################

#
# Classe d'accès aux parameters de configuration
#
# Cette classe représente un moyen simple d'accéder aux parameters
# de configuration de l'application stockés dans la base WebDNS.
#
# Méthodes :
# - setdb $dbfd
#	positionne l'database handle de données dans laquelle sont
#	stockés les parameters
# - setlang
#	positionne la langue utilisée pour rechercher les descriptions
# - class
#	renvoie toutes les classes connues
# - desc class-or-key
#	renvoie la description associée à la classe ou à la clef
# - keys [ class ]
#	renvoie toutes les clefs associées à la classe, ou toutes
#	les clefs connues
# - keytype key
#	renvoie le type de la clef données, sous la forme d'une
#	liste {string|bool|text|menu x}. X n'est présent que pour
#	le type menu
# - keyhelp key
#	renvoie le message d'aide associé à une clef
# - get key
#	renvoie la valeur valeur associée à une clef
# - set key val
#	positionne la valeur associée à une clef, et retourne une
#	chaîne vide, ou un message d'erreur
#
# History
#   2001/03/21 : pda     : design de getconfig/setconfig
#   2003/12/08 : pda     : reprise depuis sos
#   2010/10/25 : pda     : transformation sous forme de classe
#

snit::type ::config {
    # database handle
    variable db ""

    # default language
    variable lang "fr"

    # configuration parameter specification
    variable configspec {
	{dns
	    {
		fr {Paramètres généraux}
		en {General parameters}
	    }
	    {datefmt {string}
		fr {{Format d'affichage des dates/heures}
		    {Format d'affichage des dates et des heures,
			utilisé dans l'édition et l'affichage des
			données. Voir la page de manuel clock(n)
			de Tcl.}
		}
	    }
	    {jourfmt {string}
		fr {{Format d'affichage des jours}
		    {Format d'affichage des dates (sans l'heure).
		    Voir la page de manuel clock(n) de Tcl.}
		}
	    }
	}
	{dhcp
	    {
		fr {Paramètres DHCP}
		en {DHCP parameters}
	    }
	    {default_lease_time {string}
		fr {{default_lease_time}
		    {Valeur du parameter DHCP "default_lease_time"
			utilisé lors de la génération d'intervalles
			dynamiques, en secondes. Cette valeur est
			utilisée si le parameter spécifique de
			l'intervalle est nul.}
		}
	    }
	    {max_lease_time {string}
		fr {{max_lease_time}
		    {Valeur du parameter DHCP "max_lease_time"
		    utilisé lors de la génération d'intervalles
		    dynamiques, en secondes.  Cette valeur est
		    utilisée si le parameter spécifique de l'intervalle
		    est nul.}
		}
	    }
	    {min_lease_time {string}
		fr {{min_lease_time}
		    {Valeur minimale des parameters DHCP spécifiés
			dans les intervalles dynamiques. Cette
			valeur permet uniquement d'éviter qu'un
			correspondant réseau précise des parameters
			de bail trop petits et génère un trafic
			important.}
		}
	    }
	}
	{topo
	    {
		fr {Paramètres de topo}
		en {Topology parameters}
	    }
	    {topoactive {bool}
		fr {{Activation de Topo}
		    {Cocher cette case pour activer l'accès à la
			fonctionnalité "Topo".}
		}
	    }
	    {topofrom {string}
		fr {{"From" des mails de topo}
		    {Champ "From" des mails envoyés par le démon topod
			lors des détections de modification ou
			d'anomalie.}
		}
	    }
	    {topoto {string}
		fr {{Destinataire des mails de topo}
		    {Champ "To" des mails envoyés par
			le démon topod lors des détection de
			modification ou d'anomalie.}
		}
	    }
	}
	{auth
	    {
		fr {Paramètres d'authentification}
		en {Authentification parameters}
	    }
	    {authmailfrom {bool}
		fr {{Utiliser le "From" spécifié dans "auth"}
		    {Utiliser l'information provenant de l'application
			"auth" plutôt que le champ suivant.}
		}
	    }
	    {mailfrom {string}
		fr {{"From" des mails de modification de passwd}
		    {Champ "From" des mails envoyés par l'application
			à un utilisateur lors des changements de
			mot de passe.}
		}
	    }
	    {authmailreplyto {bool}
		fr {{Utiliser le "Reply-To" spécifié dans "auth"}
		    {Utiliser l'information provenant de l'application
			"auth" plutôt que le champ suivant.}
		}
	    }
	    {mailreplyto {string}
		fr {{"Reply-To" des mails de modification de passwd}
		    {Champ "Reply-To" des mails envoyés par
			l'application à un utilisateur lors des
			changements de mot de passe.}
		}
	    }
	    {authmailcc {bool}
		fr {{Utiliser le "Cc" spécifié dans "auth"}
		    {tiliser l'information provenant de l'application
			"auth" plutôt que le champ suivant.}
		}
	    }
	    {mailcc {string}
		fr {{"Cc" des mails de modification de passwd}
		    {Destinataire(s) auxiliaires des mail envoyés
			par l'application à un utilisateur lors des
			changements de mot de passe.
			Cela peut éventuellement être une liste d'adresses,
			l'espace faisant office de séparateur.}
		}
	    }
	    {authmailbcc {bool}
		fr {{Utiliser le "Bcc" spécifié dans "auth"}
		    {Utiliser l'information provenant de l'application
			"auth" plutôt que le champ suivant.}
		}
	    }
	    {mailbcc {string}
		fr {{"Bcc" des mails de modification de passwd}
		    {Destinataire(s) caché(s) des mail envoyés par
			l'application à un utilisateur lors des
			changements de mot de passe.  Cela peut
			éventuellement être une liste d'adresses,
			l'espace faisant office de séparateur.}
		}
	    }
	    {authmailsubject {bool}
		fr {{Utiliser le "Subject" spécifié dans "auth"}
		    {Utiliser l'information provenant de l'application
			"auth" plutôt que le champ suivant.}
		}
	    }
	    {mailsubject {string}
		fr {{"Subject" des mails de moditication de passwd}
		    {Champ "Subject" des mails envoyés par
			l'application à un utilisateur lors des
			changements de mot de passe.}
		}
	    }
	    {authmailbody {bool}
		fr {{Utiliser le corps spécifié dans "auth"}
		    {Utiliser l'information provenant de l'application
			"auth" plutôt que le champ suivant.}
		}
	    }
	    {mailbody {text}
		fr {{Corps du mail de modification de passwd}
		    {Corps des mails envoyés par l'application à
			un utilisateur lors des changements de mot
			de passe. Les parameters suivants sont
			substitués: <ul><li>%1$s : login de
			l'utilisateur</li> <li>%2$s : mot de passe
			généré</li></ul>.}
		}
	    }
	    {groupes {string}
		fr {{Groupes Web autorisés}
		    {Liste de groupes (conformément à l'authentification
			Apache) autorisés pour la création d'un
			utilisateur.  Si la liste est vide, tous
			les groupes existants dans la base
			d'authentification sont autorisés.}
		}
	    }
	}
    }

    #
    # Internal representation of parameter specification
    #
    # (class)			{<cl1> ... <cln>}
    # (class:<cl1>)		{<k1> ... <kn>}
    # (class:<cl1>:desc:<lang>)	<desc>
    # (key:<k1>:type)		{string|bool|text|menu ...}
    # (key:<k1>:desc:<lang>)	<desc>
    # (key:<k1>:help:<lang>)	<text>
    #

    variable internal -array {}

    constructor {} {
	set internal(class) {}
	foreach class $configspec {
	    lassign $class classname classdesc

	    lappend internal(class) $classname
	    set internal(class:$classname) {}

	    array set t $classdesc
	    foreach lang [array names t] {
		set internal(class:$classname:desc:$lang) $t($lang)
	    }
	    unset t

	    foreach key [lreplace $class 0 1] {
		lassign $key keyname keytype

		lappend internal(class:$classname) $keyname
		set internal(key:$keyname:type) $keytype

		array set t [lreplace $key 0 1]
		foreach lang [array names t] {
		    lassign $t($lang) desc help
		    set internal(key:$keyname:desc:$lang) $desc
		    set internal(key:$keyname:help:$lang) $help
		}
		unset t
	    }
	}
    }

    method setdb {dbfd} {
	set db $dbfd
    }

    method setlang {lg} {
	set lang $lang
    }

    # returns all classes
    method class {} {
	return $internal(class)
    }

    # returns textual description of the given class or key
    method desc {cork} {
	set r $cork
	if {[info exists internal(class:$cork)]} then {
	    if {[info exists internal(class:$cork:desc:$lang)]} then {
		set r $internal(class:$cork:desc:$lang)
	    }
	} elseif {[info exists internal(key:$cork:type)]} {
	    if {[info exists internal(key:$cork:desc:$lang)]} then {
		set r $internal(key:$cork:desc:$lang)
	    }
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
	    if {[info exists internal(key:$key:help:$lang)]} then {
		set r $internal(key:$key:help:$lang)
	    }
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
	    error "Unknown configuration key '$key'"
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
		set r "Cannot set '$key' to '$val': $msg"
	    }
	} else {
	    set r "Cannot fetch '$key': $msg"
	}

	return $r
    }
}

##############################################################################
# Librairie topo
##############################################################################

#
# Librairie TCL pour l'application de topologie
#
# History
#   2006/06/05 : pda             : design de la partie topo
#   2006/05/24 : pda/jean/boggia : design de la partie metro
#   2007/01/11 : pda             : fusion des deux parties
#   2008/10/01 : pda             : ajout de message de statut de la topo
#

set libconf(topodir)	%TOPODIR%
set libconf(graph)	%GRAPH%
set libconf(status)	%STATUS%

set libconf(extractcoll)	"%TOPODIR%/bin/extractcoll %s < %GRAPH%"
set libconf(extracteq)		"%TOPODIR%/bin/extracteq %s %s < %GRAPH%"

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

#
# Lire l'état de topo
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- admin : 1 si l'utilisateur est admin, 0 sinon
# Output:
#   - return value: message de statut, ou chaîne vide (si l'utilisateur
#	n'est pas admin, ou s'il n'y a aucun message)
#
# History
#   2010/11/15 : pda      : séparation dans une fonction autonome
#   2010/11/23 : pda      : utilisation de la table keepstate
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
	    set msg "No message from anaconf"
	    set date "(no date)"
	} elseif {$msg eq "Resuming normal operation"} then {
	    set msg ""
	}

	if {$msg ne ""} then {
	    set msg [::webapp::html-string $msg]
	    regsub -all "\n" $msg "<br>" msg

	    set texte [::webapp::helem "p" "Erreur de topo"]
	    append texte [::webapp::helem "p" \
					[::webapp::helem "font" $msg \
						"color" "#ff0000" \
					    ] \
				]
	    append texte [::webapp::helem "p" "... depuis $date"]

	    set msgsta [::webapp::helem "div" $texte "class" "alerte"]
	}
    }
    return $msgsta
}

#
# Utilitaire pour le tri des interfaces : compare deux noms d'interface
#
# Input:
#   - parameters:
#       - i1, i2 : deux noms d'interfaces
# Output:
#   - return value: -1, 0 ou 1 (cf string compare)
#
# History
#   2006/12/29 : pda : design
#

proc compare-interfaces {i1 i2} {
    #
    # Isoler tous les mots
    # Ex: "GigabitEthernet1/0/1" -> " GigabitEthernet 1/0/1"
    #
    regsub -all {[A-Za-z]+} $i1 { & } i1
    regsub -all {[A-Za-z]+} $i2 { & } i2
    #
    # Retirer tous les caractères spéciaux
    # Ex: " GigabitEthernet 1/0/1" -> " GigabitEthernet 1 0 1"
    #
    regsub -all {[^A-Za-z0-9]+} $i1 { } i1
    regsub -all {[^A-Za-z0-9]+} $i2 { } i2
    #
    # Retirer les espaces superflus
    #
    set i1 [string trim $i1]
    set i2 [string trim $i2]

    #
    # Comparer mot par mot
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
# Utilitaire pour le tri des adresses IP : compare deux adresses IP
#
# Input:
#   - parameters:
#       - ip1, ip2 : les adresses à comparer
# Output:
#   - return value: -1, 0 ou 1
#
# History
#   2006/06/20 : pda             : design
#   2006/06/22 : pda             : documentation
#

proc comparer-ip {ip1 ip2} {
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
# Indique si une adresse IP est dans une classe
#
# Input:
#   - parameters:
#       - ip : adresse IP (ou CIDR) à tester
#	- net : CIDR de référence
# Output:
#   - return value: 0 (ip pas dans net) ou 1 (ip dans net)
#
# History
#   2006/06/22 : pda             : design
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
# Valide l'id du point de collecte par rapport aux droits du correspondant.
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- id : id du point de collecte (ou id+id+...)
#	- _tabcor : infos sur le correspondant
#	- _titre : titre du graphe
# Output:
#   - return value: empty string or error message
#   - parameter _titre : titre du graphe trouvé
#
# History
#   2006/08/09 : pda/boggia      : design
#   2006/12/29 : pda             : parametre vlan passé par variable
#   2008/07/30 : pda             : adaptation au nouvel extractcoll
#   2008/07/30 : pda             : codage de multiples id
#   2008/07/31 : pda             : ajout de |
#

proc verifier-metro-id {dbfd id _tabuid _titre} {
    upvar $_tabuid tabuid
    upvar $_titre titre
    global libconf

    #
    # Au cas où les id seraient multiples
    #

    set lid [split $id "+|"]

    #
    # Récupérer la liste des points de collecte
    #

    set cmd [format $libconf(extractcoll) $tabuid(flagsr)]

    if {[catch {set fd [open "| $cmd" "r"]} msg]} then {
	return "Impossible de lire les points de collecte: $msg"
    }

    while {[gets $fd ligne] > -1} {
	set l [split $ligne]
	set kw [lindex $l 0]
	set i  [lindex $l 1]
	set n [lsearch -exact $lid $i]
	if {$n >= 0} then {
	    set idtab($i) $ligne
	    if {[info exists firstkw]} then {
		if {$firstkw ne $kw} then {
		    return "Types de points de collecte divergents" 
		}
	    } else {
		set firstkw $kw
	    }
	    set lid [lreplace $lid $n $n]
	}
    }
    catch {close $fd}

    #
    # Erreur si id pas trouvé
    #

    if {[llength $lid] > 0} then {
	return "Point de collecte '$id' non trouvé"
    }

    #
    # Essayer de trouver un titre convenable
    # 

    set lid [array names idtab]
    switch [llength $lid] {
	0 {
	    return "Aucun point de collecte sélectionné"
	}
	1 {
	    set i [lindex $lid 0]
	    set l $idtab($i)
	    switch $firstkw {
		trafic {
		    set eq    [lindex $l 2]
		    set iface [lindex $l 4]
		    set vlan  [lindex $l 5]

		    set titre "Trafic sur"
		    if {$vlan ne "-"} then {
			append titre " le vlan $vlan"
		    }
		    append titre " de l'interface $iface de $eq"
		}
		nbauthwifi -
		nbassocwifi {
		    set eq    [lindex $l 2]
		    set iface [lindex $l 4]
		    set ssid  [lindex $l 5]

		    set titre "Nombre"
		    if {$firstkw eq "nbauthwifi"} then {
			append titre " d'utilisateurs authentifiés" 
		    } else {
			append titre " de machines associées" 
		    }
		    append titre " sur le ssid $ssid de l'interface $iface de $eq"
		}
		default {
		    return "Erreur interne sur extractcoll"
		}
	    }
	}
	default {
	    switch $firstkw {
		trafic {
		    set titre "Trafic"
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
		    set le [join $le " et "]
		    append titre " sur $le"
		}
		nbauthwifi -
		nbassocwifi {
		    if {$firstkw eq "nbauthwifi"} then {
			set titre "Nombre d'utilisateurs authentifiés"
		    } else {
			set titre "Nombre de machines associées"
		    }
		    foreach i $lid {
			set l $idtab($i)
			set eq    [lindex $l 2]
			set iface [lindex $l 4]
			set ssid  [lindex $l 5]

			set e "$eq/$iface ($ssid)"
			lappend le $e
		    }
		    set le [join $le " et "]
		    append titre " sur $le"
		}
		default {
		    return "Erreur interne sur extractcoll"
		}
	    }
	}
    }

    return ""
}

#
# Récupère une expression régulière caractérisant la liste des
# équipements autorisés.
#
# Input:
#   - parameters:
#       - dbfd : database handle
#	- rw : read (0) ou write (1)
#	- idgrp : id du groupe dans la base DNS
# Output:
#   - return value: liste de listes de la forme
#		{{re_allow_1 ... re_allow_n} {re_deny_1 ... re_deny_n}}
#
# History
#   2006/08/10 : pda/boggia      : création avec un fichier sur disque
#   2010/11/03 : pda/jean        : les données sont dans la base
#

proc lire-eq-autorises {dbfd rw idgrp} {

    set r {}

    #
    # Traiter d'abord les allow, puis les deny
    #

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
# Récupère un graphe du métrologiseur et le renvoie
#
# Input:
#   - parameters:
#       - url : l'URL pour aller chercher le graphe sur le métrologiseur
# Output:
#   - aucune sortie, le graphe est récupéré et renvoyé sur la sortie standard
#	avec l'en-tête HTTP qui va bien
#
# History
#   2006/05/17 : jean       : création pour dhcplog
#   2006/08/09 : pda/boggia : récupération, mise en fct et en librairie
#   2010/11/15 : pda        : suppression parameter err
#

proc gengraph {url} {
    package require http			;# tcllib

    set token [::http::geturl $url]
    set status [::http::status $token]

    if {$status ne "ok"} then {
	set code [::http::code $token]
	d error "Accès impossible ($code)"
    }

    upvar #0 $token state

    # 
    # Déterminer le type d'image
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
    # Renvoyer le résultat
    # 

    ::webapp::send $contenttype $state(body)
}

#
# Lit et décode une date entrée dans un formulaire
#
# Input:
#   - parameters:
#       - date : la date saisie par l'utilisateur dans le formulaire
#	- heure : heure (00:00:00 pour l'heure de début, 23:59:59 pour fin)
# Output:
#   - return value: la date en format postgresql, ou "" si rien
#
# History
#   2000/07/18 : pda : design
#   2000/07/23 : pda : ajout de l'heure
#   2001/03/12 : pda : mise en librairie
#   2008/07/30 : pda : ajout cas spécial pour 24h (= 23:59:59)
#

proc decoder-date {date heure} {
    set date [string trim $date]
    if {[string length $date] == 0} then {
	set datepg ""
    }
    if {$heure eq "24"} then {
	set heure "23:59:59"
    }
    set liste [split $date /]
    switch [llength $liste] {
	1	{
	    set jj   [lindex $liste 0]
	    set mm   [clock format [clock seconds] -format "%m"]
	    set yyyy [clock format [clock seconds] -format "%Y"]
	    set datepg "$mm/$jj/$yyyy $heure"
	}
	2	{
	    set jj   [lindex $liste 0]
	    set mm   [lindex $liste 1]
	    set yyyy [clock format [clock seconds] -format "%Y"]
	    set datepg "$mm/$jj/$yyyy $heure"
	}
	3	{
	    set jj   [lindex $liste 0]
	    set mm   [lindex $liste 1]
	    set yyyy [lindex $liste 2]
	    set datepg "$mm/$jj/$yyyy $heure"
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
# Convertit une fréquence radio 802.11b/g (bande des 2,4 GHz)
# en canal 802.11b/g
#
# Input:
#   - parameters:
#       - freq : la fréquence
# Output:
#   - return value: chaîne exprimant le canal
#
# History
#   2008/07/30 : pda : design
#   2008/10/17 : pda : canal "dfs"
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
# Récupère la liste des interfaces d'un équipement
#
# Input:
#   - parameters:
#	- eq : nom de l'équipement
#	- tabuid() : tableau contenant les flags de restriction pour l'utilisateur
#   - global variables :
#	- libconf(extracteq) : appel à extracteq
# Output:
#   - return value: liste de la forme
#		{eq type model location iflist liferr arrayif arrayvlan}
#	où
#	- iflist est la liste triée des interfaces
#	- liferr est la liste des interfaces en erreur (interface modifiable
#		mais non consultable)
#	- arrayif est prêt pour "array set" pour donner un tableau de la forme
#		tab(iface) {nom edit radio stat mode desc lien natif {vlan...}}
#		(cf sortie de extracteq)
#	- arrayvlan est prêt pour "array set" pour donner un tableau de la
#		forme tab(id) {desc-en-hexa voip-0-ou-1}
#
# History
#   2010/11/03 : pda      : création
#   2010/11/15 : pda      : suppression parameter err
#   2010/11/23 : pda/jean : parcours des interfaces modifiables
#   2010/11/25 : pda      : ajout manual
#

proc eq-iflist {eq _tabuid} {
    global libconf
    upvar $_tabuid tabuid

    #
    # Premier parcours : récupérer la liste des interfaces "consultables"
    #

    set found 0

    set cmd [format $libconf(extracteq) $tabuid(flagsr) $eq]
    set fd [open "|$cmd" "r"]
    while {[gets $fd ligne] > -1} {
	switch [lindex $ligne 0] {
	    eq {
		set r [lreplace $ligne 0 0]

		set location [lindex $r 3]
		if {$location eq "-"} then {
		    set location ""
		} else {
		    set location [binary format H* $location]
		}
		set r [lreplace $r 3 3 $location]

		# manual = "manual" ou "auto"
		set manual [lindex $r 4]
		set r [lreplace $r 4 4]

		set found 1
	    }
	    iface {
		set if [lindex $ligne 1]
		# préparer l'item "edit", qui sera positionné
		# (éventuellement) dans le deuxième parcours
		set ligne [linsert $ligne 2 "-"]
		set tabiface($if) [lreplace $ligne 0 0]
	    }
	}
    }
    if {[catch {close $fd} msg]} then {
	d error "Erreur lors de la lecture de l'équipement '$eq' (read)\n$msg"
    }

    if {! $found} then {
	d error "Equipement '$eq' not found"
    }

    #
    # Deuxième parcours : récupérer la liste des interfaces "modifiables"
    #

    set liferr {}

    if {$manual eq "auto"} then {
	set cmd [format $libconf(extracteq) $tabuid(flagsw) $eq]
	set fd [open "|$cmd" "r"]
	while {[gets $fd ligne] > -1} {
	    switch [lindex $ligne 0] {
		iface {
		    set if [lindex $ligne 1]
		    if {! [info exists tabiface($if)]} then {
			# ajouter cette interface à la liste des
			# interfaces en erreur
			lappend liferr $if
		    } else {
			# positionner l'item "edit" sur cette interface
			set tabiface($if) [lreplace $tabiface($if) 1 1 "edit"]
		    }
		}
		vlan {
		    lassign $ligne bidon id desc voip
		    set tabvlan($id) [list $desc $voip]
		}
	    }
	}
	if {[catch {close $fd} msg]} then {
	    d error "Erreur lors de la lecture de l'équipement '$eq' (write)\n$msg"
	}

	set liferr [lsort -command compare-interfaces $liferr]
    }

    lappend r $liferr

    #
    # Trier les interfaces pour les présenter dans le bon ordre
    #

    set iflist [lsort -command compare-interfaces [array names tabiface]]

    #
    # Présenter la valeur de retour
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

    set iddom [lire-domaine $dbfd $domain]
    if {$iddom == -1} then {
	d error "Erreur interne : domaine '$domain' non trouvé"
    }
    if {! [lire-rr-par-nom $dbfd $host $iddom tabrr]} then {
	d error "Erreur interne : équipement '$eq' non trouvé"
    }
    set idrr $tabrr(idrr)

    #
    # Search for unprocessed modifications and build
    # information.
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
    lappend lines [list Title4 "Date" "Login" "Interface" "Modif"]
    pg_select $dbfd $sql tab {
	set ifdesc $tab(ifdesc)
	set ethervlan $tab(ethervlan)
	set voicevlan $tab(voicevlan)
	set modif "description='$ifdesc'"
	if {$ethervlan == -1} then {
	    append modif ", interface désactivée"
	} else {
	    append modif ", vlan=$ethervlan"
	    if {$voicevlan != -1} then {
		append modif ", voip=$voicevlan"
	    }
	}
	lappend lines [list Normal4 $tab(reqdate) $tab(login) $tab(iface) $modif]
    }
    if {[llength $lines] == 1} then {
	set ifchg ""
    } else {
	set ifchg [::webapp::helem "p" "Modification(s) en cours de traitement"]
	append ifchg [::arrgen::output "html" $libconf(tabeqstatus) $lines]
    }

    #
    # Search for current topod status
    #

    set sql "SELECT message FROM topo.keepstate WHERE type = 'status'"
    set action ""
    pg_select $dbfd $sql tab {
	lassign [lindex $tab(message) 0] date action
    }

    switch -nocase -glob $action {
	rancid* -
	building* {
	    set graph [::webapp::helem "p" "Reconstruction du graphe en cours.
			Les informations fournies ne sont pas forcément
			cohérentes avec la réalité."]
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
