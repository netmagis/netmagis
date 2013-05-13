#
# TCL library for Netmagis
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
#   2010/12/17 : pda      : reworked installation and parameters
#   2011/01/02 : pda      : integration of libauth in libdns
#   2011/07/29 : pda      : renamed to libnetmagis
#

##############################################################################
# Configuration file processing
##############################################################################

#
# Read configuration file
#
# Input:
#   - parameters:
#	- file : configuration file
# Output:
#   - none (program ends if an error is encountered)
#
# History
#   2010/12/17 : pda      : design
#

proc read-local-conf-file {file} {
    global netmagisconf

    if {[catch {set fd [open "$file" "r"]} msg]} then {
	puts stderr "Cannot open configuration file '$file'"
	exit 1
    }
    set lineno 1
    set errors false
    while {[gets $fd line] >= 0} {
	regsub {#.*} $line {} line
	regsub {\s*$} $line {} line
	if {$line ne ""} then {
	    if {[regexp {(\S+)\s+"(.*)"} $line m key val]} then {
		set netmagisconf($key) $val
	    } elseif {[regexp {(\S+)\s+(.*)} $line m key val]} then {
		set netmagisconf($key) $val
	    } else {
		puts stderr "$file($lineno): unrecognized line $line"
		set errors true
	    }
	}
	incr lineno
    }
    close $fd
    if {$errors} then {
	exit 1
    }
}

#
# Get configuration key
#
# Input:
#   - parameters:
#	- key : configuration key
# Output:
#   - return value: configuration value or empty string
#
# History
#   2010/12/17 : pda      : design
#   2010/12/19 : pda      : empty string if key is not found
#

proc get-local-conf {key} {
    global netmagisconf

    if {[info exists netmagisconf($key)]} then {
	set v $netmagisconf($key)
    } else {
	set v ""
    }
    return $v
}

#
# Get database handle
#
# Input:
#   - parameters:
#	- prefix : prefix for configuration keys (e.g. db for dbhost/dbname/...)
# Output:
#   - return value: conninfo script for pg_connect
#
# History
#   2010/12/17 : pda      : design
#   2011/01/21 : pda      : add port specification
#   2013/02/08 : pda/jean : fix bug in values containing special characters
#

proc get-conninfo {prefix} {
    set conninfo {}
    foreach f {{host host} {port port} {dbname name}
			{user user} {password password}} {
	lassign $f connkey suffix
	set v [get-local-conf "$prefix$suffix"]
	regsub {['\\]} $v {\\&} v
	lappend conninfo "$connkey='$v'"
    }
    return [join $conninfo " "]
}

##############################################################################
# Library initialization
##############################################################################

read-local-conf-file %CONFFILE%

lappend auto_path [get-local-conf "pkgtcl"]
set debug [get-local-conf "debug"]

package require msgcat			;# tcl
namespace import ::msgcat::*

package require snit			;# tcllib
package require ip			;# tcllib

package require webapp
package require pgsql
package require arrgen

package require md5

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
    pattern PermEq {
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
    pattern Network {
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
    pattern Perm {
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

set libconf(tabviews) {
    global {
	chars {10 normal}
	align {left}
	botbar {yes}
	columns {75 25}
    }
    pattern Normal {
	vbar {yes}
	column { }
	vbar {no}
	column { }
	vbar {yes}
    }
}

set libconf(tabdomains) {
    global {
	chars {10 normal}
	align {left}
	botbar {yes}
	columns {66 33}
    }
    pattern Domaine {
	vbar {yes}
	column { }
	vbar {no}
	column { }
	vbar {no}
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
	column {
	    format {raw}
	}
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


set libconf(extractcoll)	"extractcoll %s"
set libconf(extracteq)		"extracteq %s %s"

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
# Netmagis application framework
##############################################################################

#
# Netmagis access class
#
# This class is a simple way to initialize the whole context of all
# Netmagis programs (CGI scripts, daemons, command line utilities).
#
# Methods:
#   cgi-register
#	register a CGI script and conditions to execute it
#   cgi-dispatch
#	dispatch execution to a registered CGI script
#   init-script
#	initialize context for an autonomous program (not CGI)
#   locale
#	set current locale
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
#   errimg
#	returns an error image and close access to application
#   result
#	returns a page and close access to application
#   writelog
#	write a log message in the log system
#   dblock, dbabort, dbcommit
#	database locking/unlocking operations
#
# History
#   2001/06/18 : pda      : design
#   2002/12/26 : pda      : update and usage
#   2003/05/13 : pda/jean : integration in netmagis and auth class usage
#   2007/10/05 : pda/jean : adaptation to "authuser" and "authbase" objects
#   2007/10/26 : jean     : add log
#   2010/10/25 : pda      : add dnsconfig
#   2010/11/05 : pda      : use a snit object
#   2010/11/09 : pda      : add init-script
#   2010/11/29 : pda      : i18n
#   2010/12/21 : pda/jean : add version in class
#   2011/02/18 : pda      : add scriptmode
#   2012/01/02 : pda      : add errimg
#

snit::type ::netmagis {
    # Netmagis version
    variable version "%NMVERSION%"

    # cgi script dispatching (see cgi-register)
    # critform : list of field names
    # critscript : list {{crit form script} {crit form script} ...}
    variable critform {}
    variable critscript {}

    # database handle
    variable db ""

    # mode : script, cgi, daemon
    variable scriptmode ""

    # in script or daemon mode, name of executing program
    variable scriptargv0

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
    variable errorpage "error.html"

    # HTML home page
    variable homepage "index"

    # in order to come back from a travel in the Netmagis application
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
			    {index always}
			    {net always}
			    {add always}
			    {del always}
			    {mod always}
			    {mail always}
			    {dhcprange always}
			    {search always}
			    {whereami always}
			    {topotitle topo}
			    {passwd pgauth}
			    {mactitle mac}
			    {admtitle admin}
			}
	index		{index Welcome}
	net		{net Consult}
	add		{add Add}
	del		{del Delete}
	mod		{mod Modify}
	mail		{mail {Mail roles}}
	dhcprange	{dhcp {DHCP ranges}}
	passwd		{pgapasswd Password}
	search		{search Search}
	whereami	{search?q=_ {Where am I?}}
	topotitle	{eq Topology}
	mactitle	{macindex Mac}
	admtitle	{admindex Admin}
	:topo		{
			    {eq always}
			    {l2 always}
			    {l3 always}
			    {genl topogenl}
			    {topotop admin}
			    {dnstitle dns}
			    {mactitle mac}
			    {admtitle admin}
			}
	eq		{eq Equipments}
	l2		{l2 Vlans}
	l3		{l3 Networks}
	dnstitle	{index DNS/DHCP}
	genl		{genl {Link number}}
	:admin		{
			    {admtitle always}
			    {pgatitle authadmin}
			    {admlmx always}
			    {lnet always}
			    {lusers always}
			    {search always}
			    {modorg always}
			    {modcommu always}
			    {modhinfo always}
			    {modnetwork always}
			    {moddomain always}
			    {admmrel always}
			    {admmx always}
			    {modview always}
			    {modzone always}
			    {modzone4 always}
			    {modzone6 always}
			    {moddhcpprofil always}
			    {modvlan always}
			    {modeqtype always}
			    {modeq always}
			    {modconfcmd always}
			    {moddotattr always}
			    {admgrp always}
			    {admzgen always}
			    {admpar always}
			    {statuser always}
			    {statorg always}
			    {topotop topo}
			    {dnstitle dns}
			    {topotitle topo}
			    {mactitle mac}
			}
	pgatitle	{pgaindex {Internal Auth}}
	admlmx		{admlmx {List MX}}
	lnet		{lnet {List networks}}
	lusers		{lusers {List users}}
	modorg		{admref?type=org {Modify organizations}}
	modcommu	{admref?type=commu {Modify communities}}
	modhinfo	{admref?type=hinfo {Modify machine types}}
	modnetwork	{admref?type=net {Modify networks}}
	moddomain	{admref?type=domain {Modify domains}}
	admmrel		{admmrel {Modify mailhost}}
	admmx		{admmx {Modify MX}}
	modview		{admref?type=view {Modify views}}
	modzone		{admref?type=zone {Modify zones}}
	modzone4	{admref?type=zone4 {Modify reverse IPv4 zones}}
	modzone6	{admref?type=zone6 {Modify reverse IPv6 zones}}
	moddhcpprofil	{admref?type=dhcpprofil {Modify DHCP profiles}}
	modvlan		{admref?type=vlan {Modify Vlans}}
	modeqtype	{admref?type=eqtype {Modify equipment types}}
	modeq		{admref?type=eq {Modify equipments}}
	modconfcmd	{admref?type=confcmd {Modify configuration commands}}
	moddotattr	{admref?type=dotattr {Modify Graphviz attributes}}
	admgrp		{admgrp {Modify users and groups}}
	admzgen		{admzgen {Force zone generation}}
	admpar		{admpar {Application parameters}}
	statuser	{statuser {Statistics by user}}
	statorg		{statorg {Statistics by organization}}
	topotop		{topotop {Topod status}}
	:mac		{
			    {macindex always}
			    {mac always}
			    {ipinact always}
			    {macstat always}
			    {dnstitle dns}
			    {topotitle topo}
			    {admtitle admin}
			}
	macindex	{macindex {MAC index}}
	mac		{mac {MAC search}}
	ipinact		{ipinact {Inactive addresses}}
	macstat		{macstat {MAC stats}}
	:pgauth	{
			    {admtitle always}
			    {pgatitle authadmin}
			    {pgaalst authadmin}
			    {pgaaprn authadmin}
			    {pgaaadd authadmin}
			    {pgaamod authadmin}
			    {pgaadel authadmin}
			    {pgaapasswd authadmin}
			    {pgarlst authadmin}
			    {pgaradd authadmin}
			    {pgarmod authadmin}
			    {pgardel authadmin}
			    {dnstitle dns}
			    {topotitle topo}
			    {mactitle mac}
			}
	pgaalst		{pgaacc?action=list {List accounts}}
	pgaaprn		{pgaacc?action=print {Print accounts}}
	pgaaadd		{pgaacc?action=add {Add account}}
	pgaamod		{pgaacc?action=mod {Modify account}}
	pgaadel		{pgaacc?action=del {Remove account}}
	pgaapasswd	{pgaacc?action=passwd {Change account password}}
	pgarlst		{pgarealm?action=list {List realms}}
	pgaradd		{pgarealm?action=add {Add realm}}
	pgarmod		{pgarealm?action=mod {Modify realm}}
	pgardel		{pgarealm?action=del {Remove realm}}
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
    #   - smode : script mode ("cgi" or "script")
    #   - login : user's login
    #   - anon : "anon" (don't fetch identity in auth database) or "id" (fetch)
    #	- usedefuser : use default user name if login is not found
    #   - _tabuid : array containing, in return, user's characteristics
    #		(login, password, nom, prenom, mel, tel, fax, mobile, adr,
    #			idcor, idgrp, present)
    #
    # Output:
    #	- return value: empty string or error message
    #

    proc init-common {selfns _dbfd smode login anon usedefuser _tabuid} {
	global ah
	upvar $_dbfd dbfd
	upvar $_tabuid tabuid

	set scriptmode $smode

	#
	# Access to Netmagis database
	#

	set conninfo [get-conninfo "dnsdb"]
	set dbfd [ouvrir-base $conninfo msg]
	if {$dbfd eq ""} then {
	    return [mc "Error accessing database: %s" $msg]
	}

	#
	# Log initialization
	#

	set log [::webapp::log create %AUTO% \
				    -subsys netmagis \
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
	# Check compatibility with database schema version
	# - empty string : pre-2.2 schema
	# - non empty string : integer containing schema version 
	# Netmagis version (x.y.... => xy) must match schema version.
	#

	if {! [regsub {^(\d+)\.(\d+).*} $version {\1\2} nver]} then {
	    return [mc "Internal error: Netmagis version number '%s' unrecognized" $version]
	}

	set sver [dnsconfig  get "schemaversion"]
	if {$sver eq ""} then {
	    return [mc "Database schema is too old. See http://netmagis.org/upgrade.sql"]
	} elseif {$sver < $nver} then {
	    return [mc "Database schema is too old. See http://netmagis.org/upgrade.sql"]
	} elseif {$sver > $nver} then {
	    return [mc {Database schema '%1$s' is not yet recognized by Netmagis %2$s} $sver $version]
	}

	#
	# Access to authentification mechanism (database or LDAP)
	#

	set am [dnsconfig get "authmethod"]
	switch $am {
	    pgsql {
		set m {-method opened-postgresql}
		lappend m "-db" $dbfd
	    }
	    ldap {
		foreach v {ldapurl ldapbinddn ldapbindpw ldapbasedn
				ldapsearchlogin ldapattrlogin ldapattrpassword
				ldapattrname ldapattrgivenname ldapattrmail
				ldapattrphone ldapattrmobile ldapattrfax
				ldapattraddr} {
		    set $v [dnsconfig get $v]
		}
		set m {-method ldap}
		lappend m "-db" [list \
				    "url" $ldapurl \
				    "binddn" $ldapbinddn \
				    "bindpw" $ldapbindpw \
				    "base" $ldapbasedn \
				    "searchuid" $ldapsearchlogin \
				    ]
		lappend m "-attrmap" [list \
					"login" $ldapattrlogin \
					"password" $ldapattrpassword \
					"nom" $ldapattrname \
					"prenom" $ldapattrgivenname \
					"mel" $ldapattrmail \
					"tel" $ldapattrphone \
					"mobile" $ldapattrmobile \
					"fax" $ldapattrfax \
					"adr" $ldapattraddr \
					]
	    }
	    default {
		return [mc "Unrecognized authentication method '%s'" $am]
	    }
	}

	switch $anon {
	    id {
		set ah [::webapp::authbase create %AUTO%]
		$ah configurelist $m
	    }
	    anon {
		set ah ""
	    }
	}

	#
	# Reads all user's characteristics. If this user is not
	# marked "present" in the database, get him out!
	#

	set n [read-user $dbfd $login tabuid msg]
	switch $n {
	    0 {
		if {$usedefuser} then {
		    set login [dnsconfig get "defuser"]

		    set uid $login
		    set euid $login
		    set n [read-user $dbfd $login tabuid msg]
		}
		# IF user is not found
		#    OR (able to use default user AND default user is not found)
		if {$n != 1} then {
		    return $msg
		}
	    }
	    1 {
	    	# Set at least the login
	    	set tabuid(login) $login
	    }
	    default {
		return $msg
	    }
	}
	if {! $tabuid(present)} then {
	    return [mc "User '%s' not authorized" $login]
	}
	set eidcor $tabuid(idcor)

	#
	# Initializes user object
	#
	::nmuser create ::u
	u setdb $dbfd
	u setlogin $login

	#
	# Access to Netmagis is now initialized
	#

	set db $dbfd

	return ""
    }

    #
    # Builds up an URL
    #
    # Input:
    #   - _urltab : name of an array containing :
    #		urltab($name): the list {path {key val} {key val} ...}
    #		urltab($name:nextprog) program
    #		urltab($name:nextargs) arguments
    #   - name : index in urltab
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
	# - URL is a local one (does not begin with "http://")
	# - URL is external (begins with "http://")
	# In the last case, don't add default arguments which are
	# specific to Netmagis application.
	#

	if {! [regexp {^https?://} $path]} then {
	    #
	    # Add default arguments
	    #

	    # user susbtitution
	    if {$u ne $eu} then {
		lappend largs [list "uid" $u]
	    }

	    # default locale
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
	    append h [::webapp::helem "li" [mc "Unknown module '%s'" $eorm] ]
	    append h "\n"
	}
	return $h
    }

    ###########################################################################
    # Register a CGI script
    #
    # Input:
    #	- crit : criterion list {field regexp field regexp ...}
    #	- form : form field specification (see webapp::get-data)
    #   - script : script to execute if criterion matches.
    #		Variables defined in script:
    #		- dbfd : database descriptor
    #		- ftab : field array (see webapp::get-data)
    #		- tabuid : user's characteristics
    #		(login, password, nom, prenom, mel, tel, fax, mobile, adr,
    #			idcor, idgrp, present)
    # Output: (none)
    #

    method cgi-register {crit form script} {
	#
	# Memorize field name from criterion
	#
	foreach {f re} $crit {
	    lappend critform $f
	}

	#
	# Memorize criterion, form and script
	#
	lappend critscript [list $crit $form $script]
    }

    ###########################################################################
    # Dispatch to CGI actions
    #
    # Input:
    #   - module : current module we are in ("dns", "admin" or "topo")
    #   - attr : needed attribute to execute the script
    # Output:
    #   - return value: none
    #   - object d : Netmagis context
    #   - object $ah : access to authentication base
    #

    method cgi-dispatch {module attr} {
	#
	# Builds-up a fictive context to easily return error messages
	#

	set login [::webapp::user]
	set uid $login
	set euid $login
	set curmodule "dns"
	set curcap {dns}
	set locale "C"
	set blocale "C"
	set scriptmode "cgi"

	set debug [get-local-conf "debug"]

	#
	# Language negociation
	#

	set blocale [::webapp::locale $avlocale]
	$self locale $blocale

	#
	# Maintenance mode : access is forbidden to all, except
	# for users specified in ROOT pattern.
	#

	set ftest [get-local-conf "nologin"]
	set rootusers [get-local-conf "rootusers"]
	if {! [catch [lindex $rootusers 0]]} then {
	    $self error "Invalid 'rootusers' configuration parameter"
	}

	if {[file exists $ftest]} then {
	    if {$uid eq "" || ! ($uid in $rootusers)} then {
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

	set msg [init-common $selfns dbfd "cgi" $login "id" false tabuid]
	if {$msg ne ""} then {
	    $self error $msg
	}

	::html create ::h

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

	#
	# Add dispatch criterions
	#

	foreach f [lsort -unique $critform] {
	    lappend form [list $f 0 1]
	}

	#
	# Get variables
	#

	if {[llength [::webapp::get-data ftab $form]] == 0} then {
	    set msg [mc "Invalid input"]
	    if {$debug} then {
		append msg "\n$ftab(_error)"
	    }
	    $self error $msg
	}

	#
	# Is a specific language required ?
	#

	set l [string trim [lindex $ftab(l) 0]]
	if {$l ne ""} then {
	    $self locale $l
	}

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
		$self error [mc "User '%s' not authorized" $login]
	    }

	    u setlogin $login
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
	if {$tabuid(droitgenl)} then {
	    lappend curcap "topogenl"
	}
	if {$tabuid(admin)} then {
	    lappend curcap "admin"
	}
	if {[dnsconfig get "authmethod"] eq "pgsql"} then {
	    lappend curcap "pgauth"
	    set qlogin [::pgsql::quote $login]
	    set sql "SELECT r.admin
			    FROM pgauth.realm r, pgauth.member m
			    WHERE r.realm = m.realm
				AND login = '$qlogin'"
	    pg_select $dbfd $sql tab {
		if {$tab(admin)} then {
		    lappend curcap "authadmin"
		}
	    }
	}

	#
	# Is this page an "admin" only page ?
	#

	if {[llength $attr] > 0} then {
	    # XXX : for now, test only one attribute
	    if {! ($attr in $curcap)} then {
		$self error [mc "User '%s' not authorized" $login]
	    }
	}

	#
	# Find script according to criterion
	#

	set ok 0
	foreach cfs $critscript {
	    lassign $cfs crit form script
	    set ok 1
	    foreach {f re} $crit {
		set v [string trim [lindex $ftab($f) 0]]
		if {! [regexp "^$re$" $v]} then {
		    set ok 0
		    break
		}
	    }
	    if {$ok} {
		break
	    }
	}

	if {! $ok} then {
	    $self error [mc "Cannot find registered CGI action"]
	}

	#
	# Criterion ok
	# Get additional form variables and import them into current context
	#

	if {[llength $form] > 0} then {
	    if {[llength [::webapp::get-data ftab $form]] == 0} then {
		set msg [mc "Invalid input"]
		if {$debug} then {
		    append msg "\n$ftab(_error)"
		}
		$self error $msg
	    }
	}

	#
	# Prepare variable import
	#

	foreach f [lsort -unique $critform] {
	    lappend form [list $f 0 1]
	}
	set script "::webapp::import-vars ftab \$form ; $script"

	#
	# Execute script
	#

	set r [catch $script msg]
	# r=0 (OK), 1 (ERROR), 2 (RETURN), 3 (BREAK) or 4 (CONTINUE)
	if {$r == 1} then {
	    global errorInfo

	    ::webapp::cgi-err $errorInfo $debug
	}

	return 0
    }

    ###########################################################################
    # Initialize access to Netmagis, for an autonomous program (command
    # line utility, daemon, etc.)
    #
    # Input:
    #   - _dbfd : database handle, in return
    #   - argv0 : script argv0
    #   - usedefuser : use default user name if login is not found
    #   - _tabuid : array containing, in return, user's characteristics
    #		(login, password, nom, prenom, mel, tel, fax, mobile, adr,
    #			idcor, idgrp, present)
    # Output:
    #   - return value: error message or empty string
    #   - object d : Netmagis context
    #   - object $ah : access to authentication base
    #

    method init-script {_dbfd argv0 usedefuser _tabuid} {
	upvar $_dbfd dbfd
	upvar $_tabuid tabuid

	set scriptmode "script"

	#
	# Locale
	#

	uplevel #0 mclocale
	uplevel #0 mcload [get-local-conf "msgsdir"]

	#
	# Look for user's login
	#

	set cmd [get-local-conf "whoami"]
	if {[catch {exec sh -c $cmd} msg]} then {
	    return "Cannot get login name ($msg)"
	}
	set login $msg

	#
	# Common initialization work
	#

	set msg [init-common $selfns dbfd "script" $login "anon" $usedefuser tabuid]
	if {$msg ne ""} then {
	    return $msg
	}

	regsub {.*/} $argv0 {} argv0
	set scriptargv0 $argv0

	return ""
    }

    ###########################################################################
    # Ends access to Netmagis (CGI script or autonomous program)
    #
    # Input:
    #   - none
    # Output:
    #   - return value: none
    #

    method end {} {
	fermer-base $db
    }


    method locale {{l {}}} {
	set locale "C"
	if {$l in $avlocale} then {
	    set locale $l
	}

	uplevel #0 mclocale $locale
	uplevel #0 mcload [get-local-conf "msgsdir"]

	return $locale
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
	switch $scriptmode {
	    cgi {
		set msg [::webapp::html-string $msg]
		regsub -all "\n" $msg "<br>" msg
		$self result $errorpage [list [list %MESSAGE% $msg]]
		exit 0
	    }
	    daemon -
	    script {
		puts stderr "$scriptargv0: $msg"
		$self end
		exit 1
	    }
	}
    }

    ###########################################################################
    # Returns an error as an image and properly close access to application
    # (and database)
    #
    # Input:
    #   - msg : (translated) error message
    # Output:
    #   - return value: none (this method don't return)
    #

    method errimg {msg} {
	switch $scriptmode {
	    cgi {
		::webapp::send png [errimg $msg]
		$self end
		exit 1
	    }
	    daemon -
	    default {
		# should not occur
		puts stderr "$scriptargv0: $msg"
		$self end
		exit 1
	    }
	}
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
	    *.html { set fmt html }
	    *.tex { set fmt pdf }
	    default { set fmt "unknown" }
	}

	#
	# Handle internationalized template files
	#

	set found 0
	foreach l [concat [mcpreferences] "C"] {
	    set tdir [get-local-conf "templatedir"]
	    set file "$tdir/$l/$page"
	    if {[file exists $file]} then {
		set found 1
		break
	    }
	}
	if {! $found} then {
	    error "Template file '$page' not found in locale: [mcpreferences]"
	}

	#
	# Constitute the links menu if the database access is initialized
	#

	if {$fmt eq "html"} then {
	    if {$db eq ""} then {
		set linksmenu ""
	    } else {
		set linksmenu [$self Get-links ":$curmodule"]

		foreach l $avlocale {
		    if {$l ne $locale} then {
			set utab(L) [list $homepage]
			set utab(L:nextprog) ""
			set url [make-url utab "L" $uid $euid $l $blocale]
			append linksmenu [::webapp::helem "li" \
				    [::webapp::helem "a" "\[$l\]" "href" $url] \
				]
		    }
		}
	    }

	    lappend lsubst [list %LINKS% $linksmenu]

	    foreach s [$self urlsubst] {
		lappend lsubst $s
	    }

	    lappend lsubst [list %VERSION% $version]
	}

	#
	# Path to pdflatex
	#

	if {$fmt eq "pdf"} then {
	    set path [get-local-conf "pdflatex"]
	    if {$path ne ""} then {
		::webapp::cmdpath "pdflatex" $path
	    }

	    set pageformat [string tolower [::dnsconfig get "pageformat"]]
	    switch -- $pageformat {
		letter { set pageformat "letterpaper" }
		a4 -
		default { set pageformat "a4paper" }
	    }
	    lappend lsubst [list %PAGEFORMAT% $pageformat]
	}

	#
	# Send resulting page
	#

	::webapp::send $fmt [::webapp::file-subst $file $lsubst]
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

    #
    # Transaction processing
    #

    method dblock {tablelist} {
	set msg ""
	if {! [::pgsql::lock $db $tablelist msg]} then {
	    if {[llength $tablelist] == 0} then {
		set tl [join $tablelist ", "]
		set msg [mc {Cannot lock table(s) %1$s: %2$s} $tl $msg]
	    } else {
		set msg [mc "Cannot lock database: %s" $msg]
	    }
	    if {$scriptmode eq "cgi"} then {
		$self error $msg
	    }
	}
	return $msg
    }

    method dbcommit {op} {
	set msg ""
	if {! [::pgsql::unlock $db "commit" msg]} then {
	    set msg [$self dbabort $op $msg]
	}
	return $msg
    }

    method dbabort {op msg} {
	::pgsql::unlock $db "abort" m
	set msg [mc {Cannot perform operation "%1$s": %2$s} $op $msg]
	if {$scriptmode eq "cgi"} then {
	    $self error $msg
	}
	return $msg
    }
}

::netmagis create d

##############################################################################
# Configuration parameters
##############################################################################

#
# Configuration parameters class
#
# This class is a simple way to access to configuration parameters
# of the Netmagis application.
#
# Methods:
# - setdb dbfd
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
#   2012/10/27 : pda      : add read-only mode
#

snit::type ::config {
    # database handle
    variable db ""

    # configuration parameter specification
    # {{class class-spec} {class class-spec} ...}
    # class = class name
    # class-spec = {{key ro/rw type} {key ro/rw type} ...}
    variable configspec {
	{general
	    {datefmt rw {string}}
	    {jourfmt rw {string}}
	    {authmethod rw {menu {{pgsql Internal} {ldap {LDAP}}}}}
	    {pageformat rw {menu {{a4 A4} {letter Letter}}} }
	    {schemaversion ro {string}}
	}
	{dns
	    {defuser rw {string}}
	}
	{dhcp
	    {dhcpdefdomain rw {string}}
	    {dhcpdefdnslist rw {string}}
	    {default_lease_time rw {string}}
	    {max_lease_time rw {string}}
	    {min_lease_time rw {string}}
	}
	{topo
	    {topoactive rw {bool}}
	    {defdomain rw {string}}
	    {topofrom rw {string}}
	    {topoto rw {string}}
	    {topographddelay rw {string}}
	    {toposendddelay rw {string}}
	    {topomaxstatus rw {string}}
	    {sensorexpire rw {string}}
	    {modeqexpire rw {string}}
	    {ifchangeexpire rw {string}}
	    {fullrancidmin rw {string}}
	    {fullrancidmax rw {string}}
	}
	{mac
	    {macactive rw {bool}}
	}
	{authldap
	    {ldapurl rw {string}}
	    {ldapbinddn rw {string}}
	    {ldapbindpw rw {string}}
	    {ldapbasedn rw {string}}
	    {ldapsearchlogin rw {string}}
	    {ldapattrlogin rw {string}}
	    {ldapattrpassword rw {string}}
	    {ldapattrname rw {string}}
	    {ldapattrgivenname rw {string}}
	    {ldapattrmail rw {string}}
	    {ldapattrphone rw {string}}
	    {ldapattrmobile rw {string}}
	    {ldapattrfax rw {string}}
	    {ldapattraddr rw {string}}
	}
	{authpgsql
	    {authpgminpwlen rw {string}}
	    {authpgmaxpwlen rw {string}}
	    {authpgmailfrom rw {string}}
	    {authpgmailreplyto rw {string}}
	    {authpgmailcc rw {string}}
	    {authpgmailbcc rw {string}}
	    {authpgmailsubject rw {string}}
	    {authpgmailbody rw {text}}
	    {authpggroupes rw {string}}
	}
    }

    #
    # Internal representation of parameter specification
    #
    # (class)			{<cl1> ... <cln>}
    # (class:<cl1>)		{<k1> ... <kn>}
    # (key:<k1>:type)		{string|bool|text|menu ...}
    # (key:<k1>:rw)		ro|rw
    #

    variable internal -array {}

    constructor {} {
	set internal(class) {}
	foreach class $configspec {

	    set classname [lindex $class 0]
	    lappend internal(class) $classname
	    set internal(class:$classname) {}

	    foreach key [lreplace $class 0 0] {
		lassign $key keyname keyrw keytype

		lappend internal(class:$classname) $keyname
		set internal(key:$keyname:type) $keytype
		set internal(key:$keyname:rw) $keyrw
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

    # returns key rw/ro
    method keyrw {key} {
	set r ""
	if {[info exists internal(key:$key:rw)]} then {
	    set r $internal(key:$key:rw)
	}
	return $r
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
	    pg_select $db "SELECT * FROM global.config WHERE key = '$key'" tab {
		set val $tab(value)
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
	    error [mc "Unknown configuration key '%s'" $key]
	}
	return $val
    }

    # set key value
    # returns empty string if ok, or an error message
    method set {key val} {
	if {[info exists internal(key:$key:rw)]} then {
	    if {$internal(key:$key:rw) eq "rw"} then {
		set r ""
		set k [::pgsql::quote $key]
		set sql "DELETE FROM global.config WHERE key = '$k'"
		if {[::pgsql::execsql $db $sql msg]} then {
		    set v [::pgsql::quote $val]
		    set sql "INSERT INTO global.config (key, value)
		    				VALUES ('$k', '$v')"
		    if {! [::pgsql::execsql $db $sql msg]} then {
			set r [mc {Cannot set key '%1$s' to '%2$s': %3$s} $key $val $msg]
		    }
		} else {
		    set r [mc {Cannot fetch key '%1$s': %2$s} $key $msg]
		}
	    } else {
		set r [mc {Cannot modify read-only key '%s'} $key]
	    }
	} else {
	    error [mc "Unknown configuration key '%s'" $key]
	}

	return $r
    }
}

##############################################################################
# User characteristics
##############################################################################

#
# Netmagis user characteristics class
#
# This class stores all informations related to current Netmagis user
#
# Methods:
# - setdb dbfd
#	set the database handle used to access parameters
# - setlogin login
#	set the login name
#
# ....
#
# - viewname id
#	returns view name associated to view id (or empty string if error)
# - viewid name
#	returns view id associated to view name (or -1 if error)
# - myviewids
#	get all authorized view ids
# - isallowedview id
#	check if a view is authorized (1 if ok, 0 if not)
#
# - domainname id
#	returns domain name associated to domain id (or empty string if error)
# - domainid name
#	returns domain id associated to domain name (or -1 if error)
# - myiddom
#	get all authorized domain ids
# - isalloweddom id
#	check if a domain is authorized (1 if ok, 0 if not)
#
# History
#   2012/10/31 : pda/jean : design
#

snit::type ::nmuser {
    # database handle
    variable db ""
    # login of user
    variable login ""

    # Group management
    # Group information is loaded
    variable groupsloaded 0
    # allgroups(id:<id>)=name
    # allgroups(name:<name>)=id
    variable allgroups -array {}

    # View management
    # view information is loaded
    variable viewsloaded 0
    # allviews(id:<id>)=name
    # allviews(name:<name>)=id
    variable allviews -array {}
    # authviews(<id>)=1
    variable authviews -array {}
    # myviewids : sorted list of views
    variable myviewids {}

    # Domain management
    # domain information is loaded
    variable domainloaded 0
    # alldom(id:<id>)=name
    # alldom(name:<name>)=id
    variable alldom -array {}
    # authdom(<id>)=1
    variable authdom -array {}
    # myiddoms : sorted list of domains
    variable myiddom {}

    method setdb {dbfd} {
	set db $dbfd
    }

    method setlogin {newlogin} {
	if {$login ne $newlogin} then {
	    set viewsisloaded 0
	}
	set login $newlogin
    }


    #######################################################################
    # Group management
    #######################################################################

    proc load-groups {selfns} {
	array unset allgroups

	set sql "SELECT * FROM global.groupe"
	pg_select $db $sql tab {
	    set idgrp $tab(idgrp)
	    set name  $tab(nom)
	    set allgroups(id:$idgrp) $name
	    set allgroups(name:$name) $idgrp
	}
	set groupsloaded 1
    }

    method groupname {id} {
	if {! $groupsloaded} then {
	    load-groups $selfns
	}
	set r -1
	if {[info exists allgroups(id:$id)]} then {
	    set r $allgroups(id:$id)
	}
	return $r
    }

    method groupid {name} {
	if {! $groupsloaded} then {
	    load-groups $selfns
	}
	set r ""
	if {[info exists allgroups(name:$name)]} then {
	    set r $allgroups(name:$name)
	}
	return $r
    }

    #######################################################################
    # View management
    #######################################################################

    proc load-views {selfns} {
	array unset allviews
	array unset authviews
	set myviewids {}

	set sql "SELECT * FROM dns.view"
	pg_select $db $sql tab {
	    set idview $tab(idview)
	    set name   $tab(name)
	    set allviews(id:$idview) $name
	    set allviews(name:$name) $idview
	}

	set qlogin [::pgsql::quote $login]
	set sql "SELECT p.idview
			FROM dns.p_view p, dns.view v, global.corresp c
			WHERE p.idgrp = c.idgrp
			    AND p.idview = v.idview
			    AND c.login = '$qlogin'
			ORDER BY p.sort ASC, v.name ASC"
	pg_select $db $sql tab {
	    set idview $tab(idview)
	    set authviews($idview) 1
	    lappend myviewids $tab(idview)
	}

	set viewsloaded 1
    }

    method viewname {id} {
	if {! $viewsloaded} then {
	    load-views $selfns
	}
	set r -1
	if {[info exists allviews(id:$id)]} then {
	    set r $allviews(id:$id)
	}
	return $r
    }

    method viewid {name} {
	if {! $viewsloaded} then {
	    load-views $selfns
	}
	set r ""
	if {[info exists allviews(name:$name)]} then {
	    set r $allviews(name:$name)
	}
	return $r
    }

    method myviewids {} {
	if {! $viewsloaded} then {
	    load-views $selfns
	}
	return $myviewids
    }

    method isallowedview {id} {
	if {! $viewsloaded} then {
	    load-views $selfns
	}
	return [info exists authviews($id)]
    }

    #######################################################################
    # Domain management
    #######################################################################

    proc load-domains {selfns} {
	array unset alldom
	array unset authdom
	set myiddom {}

	set sql "SELECT * FROM dns.domain"
	pg_select $db $sql tab {
	    set iddom $tab(iddom)
	    set name   $tab(name)
	    set alldom(id:$iddom) $name
	    set alldom(name:$name) $iddom
	}

	set qlogin [::pgsql::quote $login]
	set sql "SELECT p.iddom
			FROM dns.p_dom p, dns.domain d, global.corresp c
			WHERE p.idgrp = c.idgrp
			    AND p.iddom = d.iddom
			    AND c.login = '$qlogin'
			ORDER BY p.sort ASC, d.name ASC"
	pg_select $db $sql tab {
	    set iddom $tab(iddom)
	    set authdom($iddom) 1
	    lappend myiddom $tab(iddom)
	}

	set domainloaded 1
    }

    method domainname {id} {
	if {! $domainloaded} then {
	    load-domains $selfns
	}
	set r -1
	if {[info exists alldom(id:$id)]} then {
	    set r $alldom(id:$id)
	}
	return $r
    }

    method domainid {name} {
	if {! $domainloaded} then {
	    load-domains $selfns
	}
	set r ""
	if {[info exists alldom(name:$name)]} then {
	    set r $alldom(name:$name)
	}
	return $r
    }

    method myiddom {} {
	if {! $domainloaded} then {
	    load-domains $selfns
	}
	return $myiddom
    }

    method isalloweddom {id} {
	if {! $domainloaded} then {
	    load-domains $selfns
	}
	return [info exists authdom($id)]
    }

}

##############################################################################
# File installation class
##############################################################################

#
# File installation class
#
# This class is meant to simplify installation of new files in tree
# hierarchy.
#
# When a file is added, its contents are written in a ".new" file and
# the name is queued in internal instance variable fileq.
# When a commit is requested, all original files are renamed into ".old"
# files and ".new" file replace original files.
# When an abort is requested, all ".new" files are removed.
#
# Methods:
# - init
#	reset a new file list
# - add filename filecontent
#	add a new file based on its contents (as a textual value)
#	returns empty string if succeeds
# - abort
#	reset new files
# - commit
#	apply modifications
#	returns empty string if succeeds
# - uncommit
#	undo previous commit
#	returns empty string if succeeds
#
# History
#   2011/06/05 : pda      : design
#

snit::type ::fileinst {
    # file queue
    variable fileq {}

    # state
    variable state "init"

    # reset queue to empty state
    method init {} {
	set fileq {}
    }

    # add a file contents into the queue
    method add {name contents} {
	if {$state eq "init" || $state eq "nonempty"} then {
	    set nf "$name.new"
	    catch {file delete -force $nf}
	    if {! [catch {set fd [open "$nf" "w"]} err]} then {
		puts -nonewline $fd $contents
		if {! [catch {close $fd} err]} then {
		    lappend fileq $name
		    set err ""
		}
	    }
	    set state "nonempty"
	} else {
	    set err "cannot add file: state != 'init' && state != 'nonempty'"
	}
	return $err
    }

    # commit new files
    method commit {} {
	set err ""
	if {$state eq "init" || $state eq "nonempty"} then {

	    # we use a "for" loop instead of a "foreach" since the index i
	    # will be used if anything goes wrong
	    set n [llength $fileq]
	    for {set i 0} {$i < $n} {incr i} {
		set f [lindex $fileq $i]
		set nf "$f.new"
		set of "$f.old"

		# make a backup of original file if it exists
		catch {file delete -force $of}
		if {[file exists $f]} then {
		    if {[catch {file rename -force $f $of} msg]} then {
			set err "cannot rename $f to $of\n$msg"
			break
		    }
		}
		
		# install new file
		if {[catch {file rename $nf $f} msg]} then {
		    set err "cannot rename $nf to $f\n$msg"
		    break
		}
	    }

	    if {$err eq ""} then {
		set state "commit"
	    } else {
		for {set j 0} {$j <= $i} {incr j} {
		    set f [lindex $fileq $j]
		    set nf "$f.new"
		    set of "$f.old"

		    if {! [file exists $nf]} then {
			catch {file rename -force $f $nf}
		    }

		    if {[file exists $of]} then {
			catch {file rename -force $of $f}
		    }
		}
	    }
	} else {
	    set err "cannot add file: state != 'init' && state != 'nonempty'"
	}

	return $err
    }

    # undo previous commit
    method uncommit {} {
	if {$state eq "commit"} then {
	    set err ""
	    set n [llength $fileq]
	    for {set i 0} {$i < $n} {incr i} {
		set f [lindex $fileq $i]
		set nf "$f.new"
		set of "$f.old"

		if {[catch {file rename -force $f $nf} msg]} then {
		    append err "cannot rename $f to $nf\n$msg\n"
		} else {
		    if {[file exists $of]} then {
			if {[catch {file rename -force $of $f} msg]} then {
			    append err "cannot rename $of to $f\n$msg\n"
			}
		    }
		}
	    }
	} else {
	    set err "cannot commit: state != 'commit'"
	}
	return $err
    }

    # abort new files
    method abort {} {
	foreach f $fileq {
	    catch {file delete -force "$f.new"}
	}
	set fileq {}
    }
}

#
# Compare old file contents with new contents as a variable
#
# Input:
#   - parameters
#	- file: name of file
#	- text: new file content
#	- _errmsg: variable containing error message in return
# Output:
#   - return value: -1 (error), 0 (no change), or 1 (change)
#   - variable _errmsg: error message, if return value = -1
#
# History
#   2004/03/09 : pda/jean : design
#   2011/05/14 : pda      : use configuration variables
#   2011/05/22 : pda      : make it simpler
#

proc compare-file-with-text {file text _errmsg} {
    upvar $_errmsg errmsg

    set r 1
    if {[file exists $file]} then {
	if {[catch {set fd [open $file "r"]} errmsg]} then {
	    set r -1
	} else {
	    set old [read $fd]
	    close $fd

	    if {$old eq $text} then {
		set r 0
	    }
	}
    }

    return $r
}

#
# Show difference between old file and new contents
#
# Input:
#   - parameters
#	- fd : file descriptor
#	- cmd: diff command
#	- file: name of file
#	- text: new file content
#	- _errmsg: variable containing error message in return
# Output:
#   - return value: 1 (ok) or 0 (error)
#   - variable _errmsg: error message, if return value = 0
#
# History
#   2011/05/22 : pda      : specification
#   2011/06/10 : pda      : add fd parameter
#   2011/06/10 : pda      : add special case for non-existant file
#

proc show-diff-file-text {fd cmd file text} {
    if {! [file exists $file]} then {
	set file "/dev/null"
    }
    set c [format $cmd $file]
    append c "|| exit 0"
    catch {exec sh -c $c << $text} r
    puts $fd $r
}

##############################################################################
# Graphviz graphs
##############################################################################

#
# Graph generation class with Graphviz
#
# This class is a simple way to generate a Netmagis graph.
#
# Methods:
# - reset
#	reset graph parameters
#	set the output format for the graph
# - title <string>
#	set graph title (default: empty string, hence no title)
# - node <nodename> { <attr> ... } (with <attr> ::= "name=value")
#	set a node
# - link <nodename> <nodename> { <attr> ... }
#	mark a link between nodes
# - graphviz <png|pdf> <engine> <dot path> <ps2pdf path>
#	calls graphviz on the current graph and returns 1 if success
#	and 0 if error.
# - error
#	returns error message from graphviz call (if graphviz method returned 0)
# - output
#	returns generated graph (if graphviz method returned 1)
#
# History
#   2011/12/29 : pda      : design
#   2012/01/18 : pda      : only one dot command for all layout engines
#

snit::type ::gvgraph {

    variable title  ""
    variable nnodes 0
    variable nodesandlinks {}
    variable error ""
    variable output ""

    # graph skeleton
    #	%1$s : nodes and links
    #	%2$s : graph title
    #	%3$s : layout engine (dot or neato)
    #	%4$s : page & size attributes (meaningful only for PDF graphs)
    variable skeleton -array {
	map {
	    graph g {
		layout = %3$s;
		charset = "UTF-8";
		fontsize = 14;
		fontname = Helvetica;
		margin = .3;
		center = true;
		orientation = portrait;
		maxiter = 1000 ;
		node [fontname=Helvetica,fontsize=10, color=grey];
		edge [fontname=Helvetica,fontsize=8, len=1.4, labelfontname=Helvetica, labelfontsize=6, color=grey];
		overlap = false;
		spline = true;
		%1$s
		%2$s
	    }
	}
	png {
	    graph g {
		layout = %3$s;
		charset = "UTF-8";
		fontsize = 14;
		fontname = Helvetica;
		margin = .3;
		center = true;
		orientation = portrait;
		maxiter = 1000 ;
		node [fontname=Helvetica,fontsize=10, color=grey];
		edge [fontname=Helvetica,fontsize=8, len=1.4, labelfontname=Helvetica, labelfontsize=6, color=grey];
		overlap = false;
		spline = true;
		%1$s
		%2$s
	    }
	}
	pdf {
	    graph g {
		layout = %3$s;
		charset = "UTF-8";
		fontsize = 14;
		fontname = Helvetica;
		margin = .3;
		center = true;
		%4$s
		orientation = landscape;
		maxiter = 1000 ;
		node [fontname=Helvetica,fontsize=10, color=grey];
		edge [fontname=Helvetica,fontsize=8, len=1.4, labelfontname=Helvetica, labelfontsize=6, color=grey];
		overlap = false;
		spline = true;
		%1$s
		%2$s
	    }
	}
    }

    # %1$s : path to the dot cmd
    # %2$s : path to the ps2pdf cmd
    # %3$s : dot file name
    # %4$s : error file name
    variable gvcmd -array {
	map {|%1$s -Tcmapx %3$s 2>%4$s}
	png {|%1$s -Tpng %3$s 2>%4$s}
	pdf {|%1$s -Tps %3$s 2>%4$s | %2$s - -}
    }

    # reset graph to initial state
    method reset {} {
	set title ""
	set nodesandlinks {}
	set nnodes 0
	set error ""
	set output ""
    }

    # returns an error message if format is not valid
    method check-format {format} {
	if {! [info exists skeleton($format)]} then {
	    return [format [mc "Invalid format '%s'"] $format]
	}
	return ""

    }

    # set title of the graph (empty string means no title)
    method title {t} {
	set title $t
    }

    # add a node to the graph
    method node {name attrlist} {
	set attr [join $attrlist ","]
	lappend nodesandlinks "\"$name\" \[$attr\];"
    }

    # add a link to the graph
    method link {n1 n2 attrlist} {
	set attr [join $attrlist ","]
	lappend nodesandlinks "\"$n1\" -- \"$n2\" \[$attr\];"
    }

    # calls graphviz and returns 1 if no error. Caller must use
    # error and output methods to get the result.
    method graphviz {format engine dotcmd ps2pdfcmd} {
	#
	# Barks if format is invalid
	#
	set error [$self check-format $format]
	if {$error ne ""} then {
	    return 0
	}

	# temporary file
	set tmp "/tmp/gv-[pid]"

	#
	# Builds the gv (dot) file for the graph
	#

	# title
	if {$title eq ""} then {
	    set t ""
	} else {
	    set t "label = \"$title\";\n"
	}

	# page format
	set pageformat [string tolower [::dnsconfig get "pageformat"]]
	switch -- $pageformat {
	    letter { set paper {page = "8.5,11"; size = "10.3,7.8";} }
	    a4 -
	    default { set paper {page = "8.26,11.69"; size = "11,7.6";} }
	}

	set dot [format $skeleton($format) \
			[join $nodesandlinks "\n"] \
			$t \
			$engine \
			$paper
		    ]

	set fd [open "$tmp.gv" "w"]
	fconfigure $fd -encoding utf-8
	puts $fd $dot
	close $fd

	#
	# Calls graphviz
	#

	set cmd [format $gvcmd($format) $dotcmd $ps2pdfcmd $tmp.gv $tmp.err]

	if {[catch {open $cmd "r"} fd]} then {
	    set error [format [mc "Error generating graph: %s"] $fd]
	    set r 0
	} else {
	    fconfigure $fd -translation binary
	    set output [read $fd]
	    if {[catch {close $fd} error]} then {
		set r 0
	    } else {
		set r 1
	    }
	}

	#
	# Has an error occurred?
	#

	if {$r == 0} then {
	    if {! [catch {open $tmp.err "r"} fderr]} then {
		append error "\n"
		append error [read $fderr]
		close $fderr
	    }
	}

	file delete -force -- $tmp.gv $tmp.err

	#
	# Returns appropriate code : 1 (success) or 0 (failure)
	#

	return $r
    }

    # returns the error message resulting from the previous graphviz invocation
    method error {} {
	return $error
    }

    # returns the output resulting from the previous graphviz invocation
    method output {} {
	return $output
    }
}

##############################################################################
# Generates an error message as a bitmap image
##############################################################################

proc errimg {msg} {
    set gv [::gvgraph %AUTO%]
    $gv node "ERROR $msg" {shape=rectangle color=red style=filled}
    if {[$gv graphviz "png" "dot" [get-local-conf "dot"] ""]} then {
	set img [$gv output]
    } else {
	# ouch! This is a text...
	set img [$gv error]
    }
    $gv destroy
    return $img
}

##############################################################################
# Get graphviz node attributes from a regular expression
##############################################################################

#
# Initialize data structure for dotattr-match-get
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- type : 2 or 3, depending upon the type of graph
#	- _tabdot : empty data structure for pattern matching
# Output:
#   - return value: none
#   - parameter _tabdot:
#	tabdot(_) {<re> ... <re>}		(in matching order)
#	tabdot(<re>) <attributes>
#
# History
#   2012/01/09 : pda      : design
#

proc dotattr-match-init {dbfd type _tabdot} {
    upvar $_tabdot tabdot

    catch {unset tabdot}
    set sql "SELECT regexp, gvattr FROM topo.dotattr
				WHERE type = $type ORDER BY rank"
    set tabdot(_) {}
    pg_select $dbfd $sql tab {
	set re $tab(regexp)
	set at $tab(gvattr)
	lappend tabdot(_) $re
	set tabdot($re) $at
    }
}

#
# Match a string against regexp in order to find graphviz node attributes
#
# Input:
#   - parameters:
#	- string : string to match (x/y for L2 graph, x for L3 graph)
#	- _tabdot : array initialized by dotattr-match-init
# Output:
#   - return value: graphviz attributes
#
# History
#   2012/01/09 : pda      : design
#

proc dotattr-match-get {str _tabdot} {
    upvar $_tabdot tabdot

    set attr {}
    foreach re $tabdot(_) {
	if {[regexp $re $str]} then {
	    set attr $tabdot($re)
	    break
	}
    }
    return $attr
}


##############################################################################
# HTML mask/unmask class
##############################################################################

#
# HTML class
#
# This class provides methods to simplify HTML writing
#
# Methods:
# - reset
#	reset HTML parameters
# - mask-next
#	increment mask counter
# - mask-link <text>
#	HTML code for the link to unmask/mask text
# - mask-text <text>
#	HTML code to mask the text (such as it may be unmasked by the link)
#
# Note: this class needs an "invdisp" Javascript function in the
#   HTML page
#
# History
#   2012/12/19 : pda/jean : design
#

snit::type ::html {

    variable mask_counter 0

    # reset to initial state
    method reset {} {
	set mask_counter 0
    }

    # increment mask counter
    method mask-next {} {
	incr mask_counter
    }

    # HTML code for the link to unmask/mask text
    method mask-link {text} {
	return [::webapp::helem "a" $text \
				"href" "#" \
				"onclick" "invdisp('hv$mask_counter')" \
				]
    }

    # HTML code to mask the text (such as it may be unmasked by the link)
    method mask-text {text} {
	return [::webapp::helem "div" $text \
				"id" "hv$mask_counter" \
				"style" "display:none" \
				]
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
#   - return value: list of 8 HTML strings
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
#   2012/01/21 : jean     : add generate link number permissions
#   2012/10/08 : pda/jean : add views
#

proc display-group {dbfd idgrp} {
    global libconf

    #
    # Get specific permissions: admin, droitsmtp, droitttl, droitmac and droitgenl
    #

    set lines {}
    set sql "SELECT admin, droitsmtp, droitttl, droitmac, droitgenl
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
	if {$tab(droitgenl)} then {
	    set droitgenl [mc "yes"]
	} else {
	    set droitgenl [mc "no"]
	}
	lappend lines [list DROIT [mc "Netmagis administration"] $admin]
	lappend lines [list DROIT [mc "SMTP authorization management"] $droitsmtp]
	lappend lines [list DROIT [mc "TTL management"] $droitttl]
	lappend lines [list DROIT [mc "MAC module access"] $droitmac]
	lappend lines [list DROIT [mc "Generate link numbers"] $droitgenl]
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
    set sql "SELECT n.idnet,
			n.name, n.location, n.addr4, n.addr6,
			p.dhcp, p.acl,
			o.name AS org,
			c.name AS commu
		FROM dns.network n, dns.p_network p,
			dns.organization o, dns.community c
		WHERE p.idgrp = $idgrp
			AND p.idnet = n.idnet
			AND o.idorg = n.idorg
			AND c.idcommu = n.idcommu
		ORDER BY p.sort, n.addr4, n.addr6"
    pg_select $dbfd $sql tab {
	set n_name 	[::webapp::html-string $tab(name)]
	set n_loc	[::webapp::html-string $tab(location)]
	set n_org	$tab(org)
	set n_commu	$tab(commu)
	set n_dhcp	$tab(dhcp)
	set n_acl	$tab(acl)

	# dispaddr : used for a pleasant address formatting
	set dispaddr {}
	# where : part of the WHERE clause for address selection
	set where  {}
	foreach a {addr4 addr6} {
	    if {$tab($a) ne ""} then {
		lappend dispaddr $tab($a)
		lappend where "addr <<= '$tab($a)'"
	    }
	}
	set dispaddr [join $dispaddr ", "]
	set where [join $where " OR "]

	lappend lines [list Network $n_name]
	lappend lines [list Normal4 [mc "Location"] $n_loc \
				[mc "Organization"] $n_org]
	lappend lines [list Normal4 [mc "Range"] $dispaddr \
				[mc "Community"] $n_commu]

	set perm {}

	set pnet {}
	if {$n_dhcp} then { lappend pnet "dhcp" }
	if {$n_acl} then { lappend pnet "acl" }
	if {[llength $pnet] > 0} then {
	    lappend perm [join $pnet ", "]
	}
	set sql2 "SELECT addr, allow_deny
			FROM dns.p_ip
			WHERE ($where)
			    AND idgrp = $idgrp
			ORDER BY addr"
	pg_select $dbfd $sql2 tab2 {
	    if {$tab2(allow_deny)} then {
		set x "+"
	    } else {
		set x "-"
	    }
	    lappend perm "$x $tab2(addr)"
	}

	lappend lines [list Perm [mc "Permissions"] [join $perm "\n"]]
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
    set sql "SELECT addr, allow_deny
		    FROM dns.p_ip
		    WHERE NOT (addr <<= ANY (
				SELECT n.addr4
					FROM dns.network n, dns.p_network p
					WHERE n.idnet = p.idnet
						AND p.idgrp = $idgrp
				UNION
				SELECT n.addr6
					FROM dns.network n, dns.p_network p
					WHERE n.idnet = p.idnet
						AND p.idgrp = $idgrp
				    ) )
			AND idgrp = $idgrp
		    ORDER BY addr"
    set perm {}
    pg_select $dbfd $sql tab {
	set found 1
	if {$tab(allow_deny)} then {
	    set x "+"
	} else {
	    set x "-"
	}
	lappend perm "$x $tab(addr)"
    }
    lappend lines [list Perm [mc "Permissions"] [join $perm "\n"]]

    if {$found} then {
	set tabcidralone [::arrgen::output "html" $libconf(tabnetworks) $lines]
    } else {
	set tabcidralone [mc "None (it's ok)"]
    }

    #
    # Get views
    #

    set lines {}
    set sql "SELECT view.name AS name, p_view.selected
			FROM dns.p_view, dns.view
			WHERE p_view.idview = view.idview
				AND p_view.idgrp = $idgrp
			ORDER BY p_view.sort ASC, view.name ASC"
    pg_select $dbfd $sql tab {
	set sel ""
	if {$tab(selected)} then {
	    set sel [mc "Selected by default"]
	}

	lappend lines [list Normal $tab(name) $sel]
    }
    if {[llength $lines] > 0} then {
	set tabviews [::arrgen::output "html" $libconf(tabviews) $lines]
    } else {
	set tabviews [mc "No allowed view"]
    }

    #
    # Get domains
    #

    set lines {}
    set sql "SELECT domain.name AS name, p_dom.rolemail
			FROM dns.p_dom, dns.domain
			WHERE p_dom.iddom = domain.iddom
				AND p_dom.idgrp = $idgrp
			ORDER BY p_dom.sort, domain.name"
    pg_select $dbfd $sql tab {
	set rm ""
	if {$tab(rolemail)} then {
	    set rm [mc "Mail role management"]
	}
	lappend lines [list Domaine $tab(name) $rm]
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
	lappend lines [list PermEq $text $perm]
    }
    set tabdreq [::arrgen::output "html" $libconf(tabdreq) $lines]

    #
    # Return informations
    #

    return [list    $tabperm \
		    $tabuser \
		    $tabnetworks \
		    $tabcidralone \
		    $tabviews \
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
    if {$dbfd ne ""} then {
	pg_disconnect $dbfd
    }
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
#   2002/05/03 : pda/jean : use in netmagis
#   2002/05/06 : pda/jean : groups
#   2010/11/29 : pda      : i18n
#

proc user-attribute {dbfd idcor attr} {
    set v 0
    set sql "SELECT groupe.$attr
			FROM global.groupe, global.corresp
			WHERE corresp.idcor = $idcor
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
#		nom	user name [if ah global variable is set]
#		prenom	user christian name [if ah global variable is set]
#		mel	user mail [if ah global variable is set]
#		tel	user phone [if ah global variable is set]
#		mobile	user mobile phone [if ah global variable is set]
#		fax	user fax [if ah global variable is set]
#		adr	user address [if ah global variable is set]
#		idcor	user id in the database
#		idgrp	group id in the database
#		groupe	group name
#		present	1 if "present" in the database
#		admin	1 if admin
#		droitsmtp 1 if permission to add hosts authorized to emit with SMTP
#		droitttl 1 if permission to edit host TTL
#		droitmac 1 if permission to use the MAC module
#		droitgenl 1 if permission to generate a link number
#		networks list of authorized networks
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
#   2011/06/17 : pda      : add test on ah global variable
#   2012/01/21 : jean     : add generate link number permission
#

proc read-user {dbfd login _tabuid _msg} {
    global ah
    upvar $_tabuid tabuid
    upvar $_msg msg

    catch {unset tabuid}

    if {$ah ne ""} then {
	#
	# Attributes common to all applications
	#

	set u [::webapp::authuser create %AUTO%]
	if {[catch {set n [$ah getuser $login $u]} m]} then {
	    set msg [mc "Authentication base problem: %s" $m]
	    return -1
	}
	
	switch $n {
	    0 {
		set msg [mc "User '%s' is not in the authentication base" $login]
		return 0
	    }
	    1 { 
		set msg ""
	    }
	    default {
		set msg [mc "Found more than one entry for login '%s' in the authentication base" $login]
		return $n
	    }
	}

	foreach c {login password nom prenom mel tel mobile fax adr} {
	    set tabuid($c) [$u get $c]
	}

	$u destroy
    }

    #
    # Netmagis specific characteristics
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
	set tabuid(droitgenl)	$tab(droitgenl)
    }

    if {$tabuid(idcor) == -1} then {
	set msg [mc "User '%s' is not in the Netmagis base" $login]
	return 0
    }

    #
    # Topo specific characteristics
    #

    # Read authorized CIDR
    set tabuid(networks) [allowed-networks $dbfd $tabuid(idgrp) "consult"]

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
	    foreach r $tabuid(networks) {
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
# Return all RR with a given name (in different views)
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- name : name to search for
#	- iddom : id of the domain in which to search for the name
# Output:
#   - return value: { {idrr idview} {idrr idview} ...}
#
# History
#   2013/04/05 : pda/jean : design
#

proc all-rr-by-name {dbfd name iddom} {
    set qname [::pgsql::quote $name]
    set sql "SELECT idrr, idview FROM dns.rr
    				WHERE nom = '$qname' AND iddom = $iddom"
    set l {}
    pg_select $dbfd $sql tab {
	lappend l [list $tab(idrr) $tab(idview)]
    }

    return $l
}

#
# Get all informations associated with a name
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- name : name to search for
#	- iddom : id of the domain in which to search for the name
#	- idview: view id
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
#   2013/04/05 : pda/jean : add view
#

proc read-rr-by-name {dbfd name iddom idview _trr} {
    upvar $_trr trr

    set qname [::pgsql::quote $name]
    set found 0
    set sql "SELECT idrr FROM dns.rr
			    WHERE nom = '$qname'
				AND iddom = $iddom
				AND idview = $idview"
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
# Get all informations associated with a RR given by the MAC Address
#
# Input:
#   - parameters:
#       - dbfd : database handle
#       - addr : address to search for
#       - _trr : empty array
# Output:
#   - return value: 1 if ok, 0 if not found
#   - _trr parameter : see read-rr-by-id
#
# Note: the given address is supposed to be syntaxically correct.
#
# History
#   2012/04/28 : jean : integrated patch from Benoit.Mandy@u-bordeaux4.fr
#

proc read-rr-by-mac {dbfd addr _trr} {
    upvar $_trr trr

    set found 0
    set sql "SELECT idrr FROM dns.rr WHERE mac = '$addr'"
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
#	- idview : id of view
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

proc read-rr-by-ip {dbfd addr idview _trr} {
    upvar $_trr trr

    set found 0
    set sql "SELECT i.idrr
			FROM dns.rr_ip i, dns.rr r
    			WHERE i.idrr = r.idrr
			    AND i.adr = '$addr'
			    AND r.idview = $idview"
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
#	_trr(idview) : view id
#	_trr(domain) : domain name
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
#	_trr(ip) : list of all IP adresses {{idview addr} ...}
#	_trr(mx) : MX list {{idview prio idrr} {idview prio idrr} ...}
#	_trr(cname) : list of pointed RR, if name is an alias {{idview idrr}...}
#	_trr(aliases) : list of all RR pointing to this object {{idview idrr}..}
#IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
#	_trr(rolemail) : id of herbegeur {{idview idheberg idviewheb} ...}
#IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
#	_trr(adrmail) : idrr of mail addresses hosted on this host
#		{{idview idrradr idviewadr} ...}
#IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
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
#   2012/10/08 : pda/jean : views
#   2013/04/05 : pda/jean : temporary hack for views
#   2013/04/10 : pda/jean : remove roleweb
#

proc read-rr-by-id {dbfd idrr _trr} {
    upvar $_trr trr

    set fields {nom iddom idview
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
	set idview $trr(idview)
	set trr(domain) ""
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
	set sql "SELECT text FROM dns.hinfo WHERE idhinfo = $trr(idhinfo)"
	pg_select $dbfd $sql tab {
	    set trr(hinfo) $tab(text)
	}
	set sql "SELECT name FROM dns.domain WHERE iddom = $trr(iddom)"
	pg_select $dbfd $sql tab {
	    set trr(domain) $tab(name)
	}
	set trr(ip) {}
	set sql "SELECT adr FROM dns.rr_ip WHERE idrr = $idrr"
	pg_select $dbfd $sql tab {
	    lappend trr(ip) [list $idview $tab(adr)]
	}
	set trr(mx) {}
	set sql "SELECT prio, mx FROM dns.rr_mx WHERE idrr = $idrr"
	pg_select $dbfd $sql tab {
	    lappend trr(mx) [list $idview $tab(prio) $tab(mx)]
	}
	set trr(cname) ""
	set sql "SELECT cname FROM dns.rr_cname WHERE idrr = $idrr"
	pg_select $dbfd $sql tab {
	    lappend trr(cname) [list $idview $tab(cname)]
	}
	set trr(aliases) {}
	set sql "SELECT idrr FROM dns.rr_cname WHERE cname = $idrr"
	pg_select $dbfd $sql tab {
	    lappend trr(aliases) [list $idview $tab(idrr)]
	}
	# is this name a mail address?
	set trr(rolemail) ""
	set sql "SELECT rm.heberg, rrh.idview AS idviewheb
			    FROM dns.role_mail rm, dns.rr rrh
			    WHERE rm.idrr = $idrr
				AND rm.heberg = rrh.idrr"
	pg_select $dbfd $sql tab {
	    lappend trr(rolemail) [list $idviewrr $tab(heberg) $tab(idviewheb)]
	}
	# all mail addresses pointing to this host
	set trr(adrmail) {}
	set sql "SELECT rra.idrr, rra.idview AS idviewrr
			    FROM dns.role_mail rm, dns.rr rra
			    WHERE heberg = $idrr
				AND rm.idrr = rra.idrr"
	pg_select $dbfd $sql tab {
	    lappend trr(adrmail) [list $idview $tab(idrr) $tab(idviewrr)]
	}
    }

    return $found
}

#
# Get RR information filtered for a view
#
# Input:
#   - parameters:
#       - _trr : see read-rr-by-id
#	- idview : view
# Output:
#   - return value: list of IP addresses
#
# History
#   2012/10/08 : pda/jean : design
#

proc rr-ip-by-view {_trr idview} {
    upvar $_trr trr

    set lip {}
    if {[info exists trr(ip)]} then {
	foreach ipview $trr(ip) {
	    lassign $ipview id ip
	    if {$id == $idview} then {
		lappend lip $ip
	    }
	}
    }
    return $lip
}

proc rr-cname-by-view {_trr idview} {
    upvar $_trr trr

    set r ""
    if {[info exists trr(cname)]} then {
	foreach cv $trr(cname) {
	    lassign $cv id cname
	    if {$id == $idview} then {
		set r $cname
		break
	    }
	}
    }
    return $r
}

proc rr-aliases-by-view {_trr idview} {
    upvar $_trr trr

    set laliases {}
    if {[info exists trr(aliases)]} then {
	foreach alview $trr(aliases) {
	    lassign $alview id idalias
	    if {$id == $idview} then {
		lappend laliases $idalias
	    }
	}
    }
    return $laliases
}

proc rr-mx-by-view {_trr idview} {
    upvar $_trr trr

    set lmx {}
    if {[info exists trr(mx)]} then {
	foreach mxview $trr(mx) {
	    lassign $mxview id prio idrr
	    if {$id == $idview} then {
		lappend lmx [list $prio $idrr]
	    }
	}
    }
    return $lmx
}

proc rr-rolemail-by-view {_trr idview} {
    upvar $_trr trr

    set lrm {}
    if {[info exists trr(rolemail)]} then {
	foreach rmview $trr(rolemail) {
	    lassign $rmview id idheb idviewheb
	    if {$id == $idview} then {
		set lrm [list $idheb $idviewheb]
	    }
	}
    }
    return $lrm
}

proc rr-adrmail-by-view {_trr idview} {
    upvar $_trr trr

    set lam {}
    if {[info exists trr(adrmail)]} then {
	foreach amview $trr(adrmail) {
	    lassign $amview id idrradr idviewadr
	    if {$id == $idview} then {
		lappend lam [list $idrradr $idviewadr]
	    }
	}
    }
    return $lam
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
#   - return value: error message or empty string
#
# History
#   2002/04/19 : pda/jean : design
#   2010/11/29 : pda      : i18n
#   2012/11/13 : pda/jean : add views
#   2013/03/28 : pda/jean : interface simplification
#   2013/04/10 : pda/jean : remove views
#

proc del-alias-by-id {dbfd idrr} {
    set msg ""
    set sql "DELETE FROM dns.rr_cname WHERE rr_cname.idrr = rr.idrr"
    if {[::pgsql::execsql $dbfd $sql msg]} then {
	set msg [del-orphaned-rr $dbfd $idrr]
    }
    return $msg
}

#
# Delete all IP address for a RR
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- idrr : RR id
# Output:
#   - return value: error message or empty string
#
# History
#   2002/04/19 : pda/jean : design
#   2010/11/29 : pda      : i18n
#   2012/11/13 : pda/jean : add views
#   2012/11/14 : pda/jean : delete addr parameter
#   2013/03/28 : pda/jean : interface simplification
#   2013/04/10 : pda/jean : remove views
#

proc del-all-ip-addresses {dbfd idrr} {
    set msg ""
    set sql "DELETE FROM dns.rr_ip WHERE idrr = $idrr"
    if {[::pgsql::execsql $dbfd $sql msg]} then {
	set msg ""
    }
    return $msg
}

#
# Delet all MX associated with an RR
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- idrr : RR id of MX
# Output:
#   - return value: error message or empty string
#
# History
#   2002/04/19 : pda/jean : design
#   2010/11/29 : pda      : i18n
#   2012/11/13 : pda/jean : add views
#   2013/03/28 : pda/jean : interface simplification
#   2013/04/10 : pda/jean : remove views
#

proc del-mx-by-id {dbfd idrr} {
    set msg ""
    set sql "DELETE FROM dns.rr_mx WHERE idrr = $idrr"
    if {[::pgsql::execsql $dbfd $sql msg]} then {
	set msg ""
    }
    return $msg
}

#
# Delete a rolemail
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- idrr : RR id
# Output:
#   - return value: error message or empty string
#
# History
#   2004/02/06 : pda/jean : design
#   2010/11/29 : pda      : i18n
#   2012/11/13 : pda/jean : add views
#   2013/03/28 : pda/jean : interface simplification
#   2013/04/10 : pda/jean : remove views
#

proc del-rolemail-by-id {dbfd idrr} {
    set msg ""
    set sql "DELETE FROM dns.role_mail rm WHERE rm.idrr = $idrr"
    if {[::pgsql::execsql $dbfd $sql msg]} then {
	set msg ""
    }
    return $msg
}

#
# Delete an RR and all associated dependancies
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- _trr : RR informations (see read-rr-by-id)
# Output:
#   - return value: error message or empty string
#
# History
#   2002/04/19 : pda/jean : design
#   2004/02/06 : pda/jean : add rolemail and roleweb
#   2010/11/29 : pda      : i18n
#   2012/11/13 : pda/jean : add views
#   2013/03/28 : pda/jean : interface simplification
#   2013/04/10 : pda/jean : remove views
#

proc del-rr-and-dependancies {dbfd _trr} {
    upvar $_trr trr

    set idrr $trr(idrr)
    set idview $trr(idview)

    #
    # If this host holds mail addresses, don't delete it.
    #

    set addrmail [rr-adrmail-by-view trr $idview]
    if {[llength $addrmail] > 0} then {
	return [mc "This host holds mail addresses"]
    }

    #
    # Delete all aliases pointing to this object
    #

    foreach a [rr-aliases-by-view trr $idview] {
	set msg [del-alias-by-id $dbfd $a]
	if {$msg ne ""} then {
	    return $msg
	}
    }

    #
    # Delete all IP addresses
    #

    set msg [del-all-ip-addresses $dbfd $idrr]
    if {$msg ne ""} then {
	return $msg
    }

    #
    # Delete all MX
    #

    set msg [del-mx-by-id $dbfd $idrr]
    if {$msg ne ""} then {
	return $msg
    }

    #
    # Delete the RR itself (if possible)
    #

    set msg [del-orphaned-rr $dbfd $idrr]
    if {$msg ne ""} then {
	return $msg
    }

    #
    # Finished !
    #

    return ""
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
# Note : if the RR is not an orphaned one, it is not deleted and
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
	foreach x {ip mx aliases cname rolemail adrmail} {
	    if {$trr($x) ne ""} then {
		set orphaned 0
		break
	    }
	}

	if {$orphaned} then {
	    set sql "DELETE FROM dns.rr WHERE idrr = $idrr"
	    if {[::pgsql::execsql $dbfd $sql msg]} then {
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
#	- idview: view id
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
#   2013/04/05 : pda/jean : add views
#

proc add-rr {dbfd name iddom idview mac iddhcpprofil idhinfo droitsmtp ttl
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
		    (nom, iddom, idview, mac, iddhcpprofil, $hinfodef
			droitsmtp, ttl, commentaire, respnom, respmel,
			idcor)
		VALUES
		    ('$name', $iddom, $idview, $qmac, $iddhcpprofil, $hinfoval
			$droitsmtp, $ttl, '$qcomment', '$qrespnom', '$qrespmel',
			$idcor)
		    "
    if {[::pgsql::execsql $dbfd $sql msg]} then {
	set msg ""
	if {! [read-rr-by-name $dbfd $name $iddom $idview trr]} then {
	    set msg [mc "Internal error: '%s' inserted, but not found in database" $name]

	}
    } else {
	set msg [mc "RR addition impossible: %s" $msg]
    }
    return $msg
}

#
# Add host
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- _trr: trr of existing fqdn or empty trr
#	- name : name of RR to create (syntax must be conform to RFC)
#	- iddom : domain id
#	- idview: view id
#	- addr: (single) IP address to add
#	- mac : MAC address, or empty string
#	- iddhcpprofil : DHCP profile id, or 0
#	- idhinfo : idhinfo or empty string
#	- droitsmtp : 1 if ok to emit with non auth SMTP
#	- ttl : TTL value, or -1 for default value
#	- comment : commment
#	- respname : responsible person name
#	- respmail : responsible person mail
#	- idcor : user id
# Output:
#   - return value: empty string, or error message
#   - parameter _trr: completed RR
#
# History
#   2013/03/28 : pda/jean : shared code between www/cgi/ and utils/
#   2013/04/10 : pda/jean : accept only one view
#

proc add-host {dbfd _trr name iddom idview addr mac iddhcpprofil idhinfo droitsmtp ttl comment respname respmail idcor} {
    upvar $_trr trr

    #
    # Handle one of two cases:
    # - object does not have an IP address, or
    # - it have IP address(es) and user has confirmed
    # Insert object in database : (RR + IP addr) or only (IP addr)
    #

    d dblock {dns.rr dns.rr_ip}

    if {$trr(idrr) == ""} then {
	#
	# Name did not exist, thus we insert a new RR
	#
	set msg [add-rr $dbfd $name $iddom $idview \
			$mac $iddhcpprofil $idhinfo $droitsmtp $ttl \
			$comment $respname $respmail $idcor trr]
	if {$msg ne ""} then {
	    d dbabort [mc "add %s" $name] $msg
	}

    } else {
	#
	# RR was existing. Host informations may have been modified.
	# Update only if needed.
	#

	if {$trr(ip) eq ""} then {
	    #
	    # Addition to an existing RR (eg: declare a host when
	    # only mail role was existing).
	    #
	    if {! ($mac eq $trr(mac)
			&& $iddhcpprofil eq $trr(iddhcpprofil)
		    	&& $hinfo eq $trr(hinfo)
		    	&& $droitsmtp eq $trr(droitsmtp)
		    	&& $ttl eq $trr(ttl)
		    	&& $comment eq $trr(commentaire)
		    	&& $respname eq $trr(respnom)
		    	&& $respmail eq $trr(respmel))} then {
		if {$mac eq ""} then {
		    set qmac NULL
		} else {
		    set qmac "'[::pgsql::quote $mac]'"
		}
		set qcomment  [::pgsql::quote $comment]
		set qrespname [::pgsql::quote $respname]
		set qrespmail [::pgsql::quote $respmail]
		if {$iddhcpprofil == 0} then {
		    set iddhcpprofil NULL
		}
		set sql "UPDATE dns.rr SET
					mac = $qmac,
					iddhcpprofil = $iddhcpprofil,
					idhinfo = $idhinfo,
					droitsmtp = $droitsmtp,
					ttl = $ttl,
					commentaire = '$qcomment',
					respnom = '$qrespname',
					respmel = '$qrespmail'
				    WHERE idrr = $trr(idrr)"
		if {! [::pgsql::execsql $dbfd $sql msg]} then {
		    d dbabort [mc "modify %s" [mc "host information"]] $msg
		}
	    }
	}
    }

    set sql "INSERT INTO dns.rr_ip (idrr, adr) VALUES ($trr(idrr), '$addr')"
    if {! [::pgsql::execsql $dbfd $sql msg]} then {
       d dbabort [mc "add %s" $addr] $msg
    }

    #
    # Keep a note about user
    #

    set msg [touch-rr $dbfd $trr(idrr)]
    if {$msg ne ""} then {
	d dbabort [mc "modify %s" [mc "RR"]] $msg
    }

    set domain [u domainname $iddom]

    d dbcommit [mc "add %s" "$name.$domain"]
    d writelog "addhost" "add $name.$domain ($addr)/[u viewname $idview]"

    return ""
}

#
# Add alias
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- _trr: trr of existing fqdn or empty trr
#	- name : name of RR to create (syntax must be conform to RFC)
#	- domain : domain name
#	- idview: view id
#	- nameref: name of existing host
#	- domainref: domain name of existing host
#	- idcor : user id
# Output:
#   - return value: empty string, or error message
#   - parameter _trr: completed RR
#
# History
#   2013/03/28 : pda/jean : shared code between www/cgi/ and utils/
#   2013/04/10 : pda/jean : accept only one view
#

proc add-alias {dbfd name domain idview nameref domainref idcor} {
    #
    # Check alias and host permissions
    #

    set msg [check-authorized-host $dbfd $idcor $name $domain $idview trr "alias"]
    if {$msg ne ""} then {
	return $msg
    }
    set iddom $trr(iddom)

    set msg [check-authorized-host $dbfd $idcor $nameref $domainref $idview trrref "existing-host"]
    if {$msg ne ""} then {
	return $msg
    }

    #
    # All test are ok, we just have to insert new alias
    #

    d dblock {dns.rr dns.rr_cname}

    #
    # This name was unknown, insert a new RR for new alias name
    #

    if {$trr(idrr) eq ""} then {
	set msg [add-rr $dbfd $name $iddom $idview "" 0 "" 0 -1 "" "" "" $idcor trr]
	if {$msg ne ""} then {
	    d dbabort [mc "add %s" $name] $msg
	}
    }

    #
    # Add alias link between alias and host
    #

    set sql "INSERT INTO dns.rr_cname (idrr, cname)
			VALUES ($trr(idrr), $trrref(idrr))"
    if {! [::pgsql::execsql $dbfd $sql msg]} then {
	d dbabort [mc "add %s" [mc "alias"]] $msg
    }

    d dbcommit [mc "add %s" "$name.$domain"]
    d writelog "addalias" "add alias $name.$domain/[u viewname $idview] -> $nameref.$domainref"

    return ""
}

#
# Delete a host or an alias
#
# Input:
#   - parameters:
#	- dbfd: database handle
#	- trr: RR of name to remove
#	- idview: view id
# Output:
#   - return value: empty string, or error message
#
# Note: we assume that an SQL transaction is already started
#    by the calling procedure. No abort is done in this procedure.
#
# History
#   2013/03/28 : pda/jean : shared code between www/cgi/ and utils/
#

proc del-host {dbfd _trr idview} {
    upvar $_trr trr

    set fqdn "$trr(nom).$trr(domain)"
    set vn [u viewname $idview]

    set cname [rr-cname-by-view trr $idview]
    if {$cname ne ""} then {
	set msg [del-alias-by-id $dbfd $trr(idrr)]
	if {$msg ne ""} then {
	    return $msg
	}

	set p "?"
	if {[read-rr-by-id $dbfd $cname tc]} then {
	    set p "$tc(nom).$tc(domain)"
	}
	d writelog "delalias" "delete alias $fqdn/$vn -> $p"
    } else {
	#
	# This is not an alias: delete all RR dependancies:
	# - aliases pointing this object
	# - MX
	# - IP addresses
	#
	set msg [del-rr-and-dependancies $dbfd trr]
	if {$msg ne ""} then {
	    return $msg
	}
	d writelog "delname" "delete all of $fqdn/$vn"
    }

    return ""
}

#
# Delete one IP address 
#
# Input:
#   - parameters:
#	- dbfd: database handle
#	- addr: IP address to remove
#	- trr: RR in which this address is located
#	- idview: view id
#	- _delobj: will contain in return the deleted object
# Output:
#   - return value: empty string, or error message
#   - parameter delobj: an IP address or a name if the whole object has
#	been removed
#
# Note: we assume that an SQL transaction is already started
#    by the calling procedure. No abort is done in this procedure.
#
# History
#   2013/03/28 : pda/jean : shared code between www/cgi/ and utils/
#

proc del-ip {dbfd addr _trr idview _delobj} {
    upvar $_trr trr
    upvar $_delobj delobj

    set fqdn "$trr(nom).$trr(domain)"
    set vn [u viewname $idview]

    set lip [rr-ip-by-view trr $idview]
    if {[llength $lip] > 1} then {
	#
	# Only delete one of these addresses
	#

	set sql "DELETE FROM dns.rr_ip i
			USING dns.rr r
			WHERE r.idrr = i.idrr
			    AND i.adr = '$addr'
			    AND r.idview = $idview"
	if {! [::pgsql::execsql $dbfd $sql msg]} then {
	    return $msg
	}

	set msg [touch-rr $dbfd $trr(idrr)]
	if {$msg ne ""} then {
	    return $msg
	}

	d writelog "deladdr" "delete address $addr from $fqdn/$vn"
	set delobj $addr
    } else {
	#
	# Delete the whole object
	#

	set msg [del-rr-and-dependancies $dbfd trr]
	if {$msg ne ""} then {
	    return $msg
	}
	d writelog "deladdr" "delete address $object -> delete all $fqdn/$vn"
	set delobj $fqdn
    }

    return ""
}

#
# Update references to a RR when a new RR is created after a host renaming
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- oidrr: id of old RR
#	- nidrr: id of new RR
#	- idview: view id
# Output:
#   - return value: empty string, or error message
#
# History
#   2012/12/07 : pda/jean : design
#

proc update-host-refs {dbfd oidrr nidrr} {
    set sql {}
    lappend sql "UPDATE dns.role_mail
			    SET heberg = $nidrr
			    WHERE heberg = $oidrr"
    lappend sql "UPDATE dns.rr_ip
			    SET idrr = $nidrr
			    WHERE idrr = $oidrr"
    lappend sql "UPDATE dns.rr_cname
			    SET cname = $nidrr
			    WHERE cname = $oidrr"
    lappend sql "UPDATE dns.rr_mx
			    SET mx = $nidrr
			    WHERE mx = $oidrr"
    lappend sql "UPDATE dns.relay_dom
			    SET mx = $nidrr
			    WHERE mx = $oidrr"
    lappend sql "UPDATE topo.ifchanges
			    SET idrr = $nidrr
			    WHERE idrr = $oidrr"
    set sql [join $sql ";"]
    if {[::pgsql::execsql $dbfd $sql msg]} then {
	set msg ""
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
    set msg ""
    if {! [::pgsql::execsql $dbfd $sql msg]} then {
	set msg [mc "RR update impossible: %s" $msg]
    }
    return $msg
}

#
# Get group ids of all allowed groups for a list of IP addresses
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- laddr : IP addresses to test
# Output:
#   - return value: list of group ids
#
# History
#   2013/02/27 : pda/jean : design
#

proc allowed-groups {dbfd laddr} {
    array set algrp {}

    foreach addr $laddr {
	#
	# Look for groups which have access to this IP address.
	#

	set sql "SELECT g.idgrp
			FROM global.groupe g, dns.p_network p, dns.network n
			WHERE g.idgrp = p.idgrp
			    AND p.idnet = n.idnet
			    AND ('$addr' <<= n.addr4 OR '$addr' <<= n.addr6)
			    "
	set lidgrp {}
	pg_select $dbfd $sql tab {
	    lappend lidgrp $tab(idgrp)
	}

	#
	# Among selected groups, search for those who have access to
	# this host (checking all other permissions).
	#

	foreach idgrp $lidgrp {
	    set sql "SELECT dns.check_ip_grp ('$addr', $idgrp) AS ok"
	    pg_select $dbfd $sql tab {
		if {$tab(ok) eq "t"} then {
		    set algrp($idgrp) {}
		}
	    }
	}
    }

    return [array names algrp]
}

#
# Display a RR with HTML
#
# Input:
#   - parameters:
#	- dbfd : database handle
#	- idrr : RR id to search for, or -1 if _trr is already initialized
#	- _trr : empty array, or initialized array (id idrr=-1)
#	- idview : view id, or empty string to get all views
#	- rrtmpl: URL template for some fields (see below)
# Output:
#   - return value: empty string or error message
#   - parameter _trr : see read-rr-by-id
#   - global variables :
#	- libconf(tabmachine) : array specification
#
# Note:
#  - rrtmpl is a string ready for "array set" which has the following
#	structure {key tmpl key tmpl ...}
#	where key is one of:
#		ip
#		allowed-groups
#		<may be more in the future>
#	and tmpl has the following format:
#		{url {formkey formval} {formkey formval}
#	where url is the script name or any url (http://another.host/a/path)
#	and formkey/formval are CGI parameters, where formval is formatted
#	with value depending upon key:
#		ip: %1$s <- ip, %2$s <- idview
#		allowed-groups: %1$s <- groupname, %2$s <- ""
#
# History
#   2008/07/25 : pda/jean : design
#   2010/10/31 : pda      : add ttl
#   2010/11/29 : pda      : i18n
#   2012/10/31 : pda/jean : add views
#   2012/11/20 : pda/jean : add view filter to display a single view
#   2013/03/06 : pda/jean : add rrtmpl
#

proc display-rr {dbfd idrr _trr idview rrtmpl} {
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

    #
    # Special case if it is a CNAME in the view
    #

    if {$idview ne ""} then {
	set cname [rr-cname-by-view trr $idview]
	if {$cname ne ""} then {
	    set fqdn "$trr(nom).$trr(domain)"
	    if {! [read-rr-by-id $dbfd $cname tc]} then {
		return [mc {Cannot read host-id %s} $idalias]
	    }

	    set fqdn2 "$tc(nom).$tc(domain)"
	    lappend lines [list Normal [mc "Alias name"] $fqdn]
	    lappend lines [list Normal [mc "Points to"] $fqdn2]
	}
    }

    #
    # Standard case
    #

    if {$lines eq ""} then {
	# name
	lappend lines [list Normal [mc "Name"] "$trr(nom).$trr(domain)"]

	# IP address(es)
	set lip [rr-ip-by-view trr $idview]
	set nip [llength $lip]
	if {$nip <= 1} then {
	    set at [mc "IP address"]
	} else {
	    set at [mc "IP addresses"]
	}
	if {$nip == 0} then {
	    set aa [mc "(none)"]
	} else {
	    set aa {}
	    foreach ip $lip {
		lappend aa [get-rr-tmpl "ip" $rrtmpl $ip $ip $idview]
	    }
	    set aa [join $aa ", "]
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
	if {$idview eq ""} then {
	    foreach va $trr(aliases) {
		lassign $va idview idalias
		if {[read-rr-by-id $dbfd $idalias ta]} then {
		    lappend la "$ta(nom).$ta(domain) ([u viewname $idview])"
		}
	    }
	} else {
	    foreach idalias [rr-aliases-by-view trr $idview] {
		if {[read-rr-by-id $dbfd $idalias ta]} then {
		    lappend la "$ta(nom).$ta(domain)"
		}
	    }
	}
	if {[llength $la] > 0} then {
	    lappend lines [list Normal [mc "Aliases"] [join $la " "]]
	}

	# mail addresses recognized by this host
	set la {}
	foreach i [rr-adrmail-by-view trr $idview] {
	    lassign $i idadrmail idviewa
	    if {[read-rr-by-id $dbfd $idadrmail ta]} then {
		lappend la "$ta(nom).$ta(domain)/[u viewname $idviewa]"
	    }
	}
	if {[llength $la] > 0} then {
	    lappend lines [list Normal [mc "Mail addresses"] [join $la " "]]
	}

	#
	# Allowed groups
	#

	set lidgrp [allowed-groups $dbfd $lip]
	set lg {}
	foreach idgrp $lidgrp {
	    set g [u groupname $idgrp]
	    lappend lg [get-rr-tmpl "allowed-groups" $rrtmpl $g $g ""]
	}
	set lg [lsort $lg]
	lappend lines [list Normal [mc "Allowed groups"] [join $lg " "]]
    }

    set html [::arrgen::output "html" $libconf(tabmachine) $lines]
    return $html
}

proc get-rr-tmpl {key rrtmpl text arg1 arg2} {
    array set tmpl $rrtmpl

    set text [::webapp::html-string $text]
    if {[info exists tmpl($key)]} then {
	set uarg [lreplace $tmpl($key) 0 0]
	set uarg [format $uarg $arg1 $arg2]
	d urlset "" [lindex $tmpl($key) 0] $uarg
	set url [d urlget ""]
	set link [::webapp::helem "a" $text "href" $url]
    } else {
	set link $text
    }
    return $link
}

#
# Generates HTML code for a host description initially invisible
# and a link to toggle its visibility.
#
# Input:
#   - parameters:
#	- dbfd: database handle
#	- _trr: initialized array (see read-rr-by-id)
#	- idview: view id in which this host must be shown
#	- rrtmpl: URL template for some fields (see display-rr)
# Output:
#   - return value: list {<link> <desc>} where:
#	- link is the HTML code for the link to the host name
#	- desc is the HTML code for the host information display
#
# Note: this function needs an "invdisp" Javascript function in the
#   HTML page
#
# History
#   2012/11/20 : pda/jean : design
#   2012/11/29 : pda/jean : move to a library function
#   2013/03/06 : pda/jean : add rrtmpl
#

proc display-rr-masked {dbfd _trr idview rrtmpl} {
    upvar $_trr trr

    h mask-next
    set link [h mask-link "$trr(nom).$trr(domain)"]
    set desc [h mask-text [display-rr $dbfd -1 trr $idview $rrtmpl]]
    return [list $link $desc] 
}

##############################################################################
# Read domains
##############################################################################

#
# Read all domains from database
#
# Input:
#   - parameters:
#	- dbfd: database handle
#	- _tabdom: array to fill with domain names
#	- _tabid: array to fill with domain ids
# Output:
#   - parameter _tabdom: tabdom(<domainname>) <id>
#   - parameter _tabid: tabdom(<id>) <domainname>
#
# History
#   2011/03/20 : pda      : place in library
#

proc read-all-domains {dbfd _tabdom _tabid} {
    upvar $_tabdom tabdom
    upvar $_tabid  tabid

    set sql "SELECT name, iddom FROM dns.domain"
    pg_select $dbfd $sql tab {
	set tabdom($tab(name)) $tab(iddom)
	set tabid($tab(iddom)) $tab(name)
    }
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
#	- _iddom : domain id in return (leave empty to not check domain existence)
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
#   2011/02/18 : pda      : iddom is optional
#

proc check-fqdn-syntax {dbfd fqdn _name _domain {_iddom {}}} {
    upvar $_name name
    upvar $_domain domain

    if {! [regexp {^([^\.]+)\.(.*)$} $fqdn bidon name domain]} then {
	return [mc "Invalid FQDN '%s'" $fqdn]
    }

    set msg [check-name-syntax $name]
    if {$msg ne ""} then {
	return $msg
    }

    if {$_iddom ne ""} then {
	upvar $_iddom iddom

	set iddom [read-domain $dbfd $domain]
	if {$iddom < 0} then {
	    return [mc "Invalid domain '%s'" $domain]
	}
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
	set msg [mc "Invalid name '%s'" $name]
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
		    set r [mc {'%1$s' is not a valid IPv%2$s address} $addr $fam]
		}
	    }
	}
	if {! ($type eq "cidr" || $type eq "loosecidr")} then {
	    if {[regexp {/}  $addr ]} then {
		set r [mc "The '/' character is not valid in the address '%s'" $addr]
	    }
	}
    } else {
	set r [mc "Invalid syntax for IP address '%s'" $addr]
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
	set msg [mc "Invalid syntax '%s' for DHCP profile" $iddhcpprofil]
    } else {
	if {$iddhcpprofil != 0} then {
	    set sql "SELECT nom FROM dns.dhcpprofil
				WHERE iddhcpprofil = $iddhcpprofil"
	    set msg [mc "Invalid DHCP profile '%s'" $iddhcpprofil]
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
# View validation
##############################################################################

#
# Checks if the selected views are authorized for this user
#
# Input:
#   - parameters:
#	- views : list of view ids given by the user
# Output:
#   - return value: empty string or error message
#
# History
#   2012/10/30 : pda/jean : design
#   2012/10/31 : pda/jean : use nmuser class
#

proc check-views {views} {
    set msg ""

    if {[llength $views] == 0} then {
	set msg [mc "You must select at least one view"]

    } else {
	#
	# Check authorized views
	#

	set bad {}
	foreach id $views {
	    if {! [u isallowedview $id]} then {
		set name [u viewname $id]
		if {$name eq ""} then {
		    set name $id
		}
		lappend bad $name
	    }
	}

	if {[llength $bad]> 0} then {
	    set bad [join $bad ", "]
	    set msg [mc "You don't have access to these views: %s" $bad]
	}
    }

    return $msg
}

#
# Filter given view ids for host/address deletion/modification
#
# Input:
#   - dbfd: database handle
#   - _tabuid: user characteristics
#   - mode: type of object ("host", "host-or-alias", "addr" or "rolemail")
#		to delete/modify
#   - object: FQDN or IP address
#   - idviews: list of idviews specified by user, may be empty for all views
#   - _chkv: contains, in return, parameters of filtered views
# Output:
#   - return value: empty string or error message
#   - array chkv:
#	chkv(<idview>) = {<viewname> <errmsg or ""> <trr-ready-for-array-set>}
#	chkv(idviews) = list of checked view ids
#	chkv(ok) = list of view ids ok
#	chkv(err) = list of view ids in error
#
# Note:
#   - "host" and "addr" modes are for host edition
#	object may be a fqdn or an IP address
#   - "host-or-alias" and "addr" modes are for host deletion
#	object may be a fqdn or an IP address
#   - "rolemail" mode is for mail role edition
#	object must be a fqdn
#
# History
#   2012/11/14 : pda/jean : design
#   2012/11/29 : pda/jean : isolate as a library function
#   2012/12/07 : pda/jean : generalization
#   2013/03/13 : pda/jean : distinguish alias case
#

proc filter-views {dbfd _tabuid mode object idviews _chkv} {
    upvar $_tabuid tabuid
    upvar $_chkv chkv

    set chkv(ok) {}
    set chkv(err) {}

    #
    # Are views selected?
    #

    set nviews [llength $idviews]
    if {$nviews == 0} then {
	#
	# No view selected by user.  We must check all our views
	# in order to search deletion/modification candidates.
	#
	set myviewids [u myviewids]
	if {[llength $myviewids] == 0} then {
	    return [mc "Sorry, but you do not have access to any view"]
	}
    } else {
	#
	# User has selected one or more views. This is a confirmation.
	# 
	set myviewids $idviews
	set msg [check-views $myviewids]
	if {$msg ne ""} then {
	    return $msg
	}
    }

    #
    # Split FQDN into name and domain
    #
    if {$mode in {host host-or-alias rolemail}} then {
	set msg [check-fqdn-syntax $dbfd $object name domain]
	if {$msg ne ""} then {
	    return $msg
	}
    }

    #
    # Check object in all views
    #

    set nok 0
    set nerr 0
    set mvi {}
    foreach idview $myviewids {
	set vn [u viewname $idview]

	set found 0
	set err 0

	switch $mode {
	    host {
		set found 1
		set msg [check-authorized-host $dbfd $tabuid(idcor) $name $domain $idview trr "del-name"]

		if {$msg ne ""} then {
		    set err 1
		} else {
		    #
		    # Is it an alias in this view?
		    #

		    set cname [rr-cname-by-view trr $idview]
		    if {$cname ne ""} then {
			set msg [mc {Name '%1$s' is an alias in view '%2$s'} $object $vn]
			set err 1
		    } else {
			set ip [rr-ip-by-view trr $idview]
			if {$ip eq ""} then {
			    set msg [mc {Name '%1$s' is not a host in view '%2$s'} $object $vn]
			    set err 1
			}
		    }
		}
	    }
	    host-or-alias {
		set found 1
		set msg [check-authorized-host $dbfd $tabuid(idcor) $name $domain $idview trr "del-name"]

		if {$msg ne ""} then {
		    set err 1
		} else {
		    #
		    # Is it an alias in this view?
		    #

		    set cname [rr-cname-by-view trr $idview]
		    if {$cname eq ""} then {
			#
			# It is not an alias, there must be at least an IP address
			#
			set ip [rr-ip-by-view trr $idview]
			if {$ip eq ""} then {
			    set msg [mc {Name '%1$s' is not a host in view '%2$s'} $object $vn]
			    set err 1
			}
		    }
		}
	    }
	    addr {
		#
		# IP address. Check that this address exists and get
		# all stored informations
		#

		if {[read-rr-by-ip $dbfd $object $idview trr]} then {
		    #
		    # Check access to this name
		    #

		    set found 1
		    set name   $trr(nom)
		    set domain $trr(domain)
		    set msg [check-authorized-host $dbfd $tabuid(idcor) $name $domain $idview bidon "del-name"]
		    if {$msg ne ""} then {
			set err 1
		    }
		}
	    }
	    rolemail {
		set found 1
		set msg [check-authorized-host $dbfd $tabuid(idcor) $name $domain $idview trr "del-addrmail"]

		if {$msg ne ""} then {
		    set err 1
		}
	    }
	    default {
		return "Internal error: unknown mode '$mode'"
	    }
	}

	if {$found} then {
	    if {$err} then {
		set chkv($idview) [list $vn $msg [array get trr]]
		lappend chkv(err) $idview
		incr nerr
	    } else {
		set chkv($idview) [list $vn "" [array get trr]]
		lappend chkv(ok) $idview
		incr nok
	    }
	    lappend mvi $idview
	}
    }
    set myviewids $mvi

    #
    # If asked for a name, check that name exists
    #

    if {$mode in {host host-or-alias} && $trr(idrr) eq ""} then {
	return [mc "Name '%s' does not exist" $object]
    }

    if {$mode eq "addr" && $nok + $nerr == 0} then {
	return [mc "Address '%s' not found" $object]
    }

    #
    # Check that :
    # - there is at least one view in which we can delete/modify a name
    # - there is no view in error, if some views are specified
    #

    if {$nok == 0 || ($nviews && $nerr > 0)} then {
	set msg ""
	foreach idview $myviewids {
	    lassign $chkv($idview) vn m t
	    if {$m ne ""} then {
		append msg [mc {Error detected in view '%1$s': %2$s} $vn $m]
		append msg "\n"
	    }
	}
	return $msg
    }

    #
    # At this point, myviewids contains:
    # - all user's view ids (good and in error) if confirmation is needed
    # - only good view ids if user has already confirmed
    # Views which do not include the searched IP address are not in myviewids
    #

    set chkv(idviews) $myviewids

    return ""
}

#
# HTML code for host/idview selection page
#
# Input:
#   - _chkv: parameters of filtered views
#   - next: script to call
# Output:
#   - return value: HTML code ready to be inserted in page
#
# History
#   2012/12/19 : pda/jean : design
#

proc html-select-view {_chkv next} {
    upvar $_chkv chkv

    set idviews $chkv(idviews)

    set html ""
    foreach idview $idviews {
	lassign $chkv($idview) vn msg t

	if {$msg eq ""} then {
	    array unset trr
	    array set trr $t

	    set fqdn "$trr(nom).$trr(domain)"

	    d urlset "" $next [list \
				    [list "action" "edit"] \
				    [list "nom" $trr(nom)] \
				    [list "domain" $trr(domain)] \
				    [list "idview" $idview] \
				]
	    d urladdnext ""
	    set url [d urlget ""]

	    set a [mc {<a href="%1$s">Modify '%2$s'</a> in view '%3$s'} $url $fqdn $vn]
	    append html [::webapp::helem "li" $a]
	    append html "\n"
	}
    }
    set html [::webapp::helem "ul" $html]

    return $html
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
    pg_select $dbfd "SELECT iddom FROM dns.domain WHERE name = '$domain'" tab {
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
#	- roles : roles to test (column names in p_dom)
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
	    set msg [mc "Domain '%s' not found" $domain]
	}
    } elseif {$domain eq ""} then {
	set sql "SELECT name FROM dns.domain WHERE iddom = $iddom"
	pg_select $dbfd $sql tab {
	    set domain $tab(name)
	}
	if {$domain eq ""} then {
	    set msg [mc "Domain-id '%s' not found" $iddom]
	}
    }

    #
    # Check if we have rights on this domain
    #
    if {$msg eq ""} then {
	set where ""
	foreach r $roles {
	    append where "AND p_dom.$r > 0 "
	}

	set found 0
	set sql "SELECT p_dom.iddom FROM dns.p_dom, global.corresp
			    WHERE corresp.idcor = $idcor
				    AND corresp.idgrp = p_dom.idgrp
				    AND p_dom.iddom = $iddom
				    $where
				    "
	pg_select $dbfd $sql tab {
	    set found 1
	}
	if {! $found} then {
	    set msg [mc "You don't have rights on domain '%s'" $domain]
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
    set sql "SELECT dns.check_ip_cor ('$adr', $idcor) AS ok"
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
#   2012/10/30 : pda/jean : add views
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
    # Check all addresses and views
    #

    if {[info exists trr(ip)]} then {
	foreach viewip $trr(ip) {
	    lassign $viewip idview ip
	    if {! [u isallowedview $idview]} then {
		set ok 0
		break
	    }
	    if {! [check-authorized-ip $dbfd $idcor $ip]} then {
		set ok 0
		break
	    }
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
#	- idview : view id in which this FQDN must be tested
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
#	    check-domain (domain, idcor, "") and views
#	    if name.domain is ALIAS then error
#	    if name.domain is MX then error
#	    if name.domain is ADDRMAIL
#		then check-all-IP-addresses (mail host, idcor)
#		      check-domain (domain, idcor, "")
#	    if name.domain has IP addresses
#		then check-all-IP-addresses (machine, idcor)
#	    if no test is false, then OK
#	"existing-host"
#	    identical to "host", but the name must have at least one IP address
#	"del-name"
#	    check-domain (domain, idcor, "") and views
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
#	    check-domain (domain, idcor, "") and views
#	    if name.domain is ALIAS then error
#	    if name.domain is MX then error
#	    if name.domain is ADDRMAIL then error
#	    if name.domain has IP addresses then error
#	    if no test is false, then OK
#	"mx"
#	    check-domain (domain, idcor, "") and views
#	    if name.domain is ALIAS then error
#	    if name.domain is MX
#		then check-all-IP-addresses (mail exchangers, idcor)
#	    if name.domain is ADDRMAIL then error
#	    if no test is false, then OK
#	"add-addrmail"
#	    check-domain (domain, idcor, "rolemail") and views
#	    if name.domain is ALIAS then error
#	    if name.domain is MX then error
#	    if name.domain is ADDRMAIL then error
#	    if name.domain is MAILHOST then error
#	    if name.domain has IP addresses
#		check-all-IP-addresses (name.domain, idcor)
#	    if no test is false, then OK
#	"del-addrmail"
#	    check-domain (domain, idcor, "rolemail") and views
#	    if name.domain is ALIAS then error
#	    if name.domain is MX then error
#	    if name.domain is NOT ADDRMAIL then error
#	    if name.domain is ADDRMAIL
#		check-all-IP-addresses (mail host, idcor)
#		check-domain (domain, idcor, "")
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
# Bug: this procedure is never called with the "mx" parameter
#
# History
#   2004/02/27 : pda/jean : specification
#   2004/02/27 : pda/jean : coding
#   2004/03/01 : pda/jean : use trr(iddom) instead of iddom
#   2010/11/29 : pda      : i18n
#   2012/10/30 : pda/jean : add views
#   2013/04/10 : pda/jean : accept only one view
#

proc check-authorized-host {dbfd idcor name domain idview _trr context} {
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
	add-addrmail	{
		    {domain	rolemail}
		    {alias	REJECT}
		    {mx		REJECT}
		    {addrmail	REJECT}
		    {mailhost	REJECT}
		    {ip		CHECK}
		}
	del-addrmail	{
		    {domain	rolemail}
		    {alias	REJECT}
		    {mx		REJECT}
		    {addrmail	CHECK}
		    {addrmail	EXISTS}
		    {ip		CHECK}
		}
    }


    #
    # Get the list of actions associated with the context
    #

    if {! [info exists testrights($context)]} then {
	return [mc "Internal error: invalid context '%s'" $context]
    }

    #
    # For each view, process tests in the given order, and break as
    # soon as a test fails
    #

    set fqdn "$name.$domain"

    foreach a $testrights($context) {
	set parm [lindex $a 1]
	switch [lindex $a 0] {
	    domain {
		set msg [check-views [list $idview]]
		if {$msg ne ""} then {
		    return $msg
		}
		set viewname [u viewname $idview]

		set iddom -1
		set msg [check-domain $dbfd $idcor iddom domain $parm]
		if {$msg ne ""} then {
		    return $msg
		}

		if {! [read-rr-by-name $dbfd $name $iddom $idview trr]} then {
		    set trr(idrr) ""
		    set trr(iddom) $iddom
		}
	    }
	    alias {
		set idcname [rr-cname-by-view trr $idview]
		if {$idcname ne ""} then {
		    read-rr-by-id $dbfd $idcname t
		    set fqdnref "$t(nom).$t(domain)"
		    switch $parm {
			REJECT {
			    return [mc {%1$s is an alias of host %2$s in view %3$s} $fqdn $fqdnref $viewname]
			}
			CHECK {
			    set ok [check-name-by-addresses $dbfd $idcor -1 t]
			    if {! $ok} then {
				return [mc {You don't have rights on some IP addresses of '%1$s' referenced by alias '%2$s'} $fqdnref $fqdn]
			    }
			}
			default {
			    return [mc {Internal error: invalid parameter '%1$s' for '%2$s'} $parm "$context/$a"]
			}
		    }
		}
	    }
	    mx {
		set lmx [rr-mx-by-view trr $idview]
		foreach mx $lmx {
		    switch $parm {
			REJECT {
			    return [mc "'%s' is a MX" $fqdn]
			}
			CHECK {
			    set idrr [lindex $mx 1]
			    set ok [check-name-by-addresses $dbfd $idcor $idrr t]
			    if {! $ok} then {
				set fqdnmx "$t(nom).$t(domain)"
				return [mc {You don't have rights on some IP addresses of '%1$s' referenced by MX '%2$s'} $fqdnmx $fqdn]
			    }
			}
			default {
			    return [mc {Internal error: invalid parameter '%1$s' for '%2$s'} $parm "$context/$a"]
			}
		    }
		}
	    }
	    addrmail {
		# get mailbox host for this address
		set rm [rr-rolemail-by-view trr $idview]
		if {$rm ne ""} then {
		    lassign $rm idrr idviewheb
		    switch $parm {
			REJECT {
			    # This name is already a mail address
			    # (it already has a mailbox host)
			    return [mc {'%1$s' is a mail role in view '%2$s'} $fqdn $viewname]
			}
			CHECK {
			    if {! [read-rr-by-id $dbfd $idrr trrh]} then {
				return [mc "Internal error: id '%s' doesn't exists for a mail host" $idrr]
			    }

			    # IP address check
			    set ok [check-name-by-addresses $dbfd $idcor -1 trrh]
			    if {! $ok} then {
				return [mc "You don't have rights on host holding mail for '%s'" $fqdn]
			    }

			    # Mail host checking
			    set bidon -1
			    set msg [check-domain $dbfd $idcor bidon trrh(domain) ""]
			    if {$msg ne ""} then {
				set r [mc "You don't have rights on host holding mail for '%s'" $fqdn]
				append r "\n$msg"
				return $r
			    }
			}
			EXISTS {
			    # nothing
			}
			default {
			    return [mc {Internal error: invalid parameter '%1$s' for '%2$s'} $parm "$context/$a"]
			}
		    }
		} else {
		    # this address has no mailbox host, so it is
		    # not a mail role
		    switch $parm {
			REJECT -
			CHECK {
			    # nothing
			}
			EXISTS {
			    return [mc {'%1$s' is not a mail role in view '%2$s'} $fqdn $viewname]
			}
			default {
			    return [mc {Internal error: invalid parameter '%1$s' for '%2$s'} $parm "$context/$a"]
			}
		    }
		}
	    }
	    mailhost {
		set ladr [rr-adrmail-by-view trr $idview]
		switch $parm {
		    REJECT {
			# remove the name (in all views) from the list
			# of mail domains hosted on this host
			while {[set pos [lsearch -exact -index 0 \
					    $ladr $trr(idrr)]] != -1} {
			    set ladr [lreplace $ladr $pos $pos]
			}
			if {[llength $ladr] > 0} then {
			    return [mc "'%s' is a mail host for mail domains" $fqdn]
			}
		    }
		    default {
			return [mc {Internal error: invalid parameter '%1$s' for '%2$s'} $parm "$context/$a"]
		    }
		}
	    }
	    ip {
		set lip [rr-ip-by-view trr $idview]
		switch $parm {
		    REJECT {
			if {[llength $lip] > 0} then {
			    return [mc {'%1$s' has IP addresses in view '%2$s'} $fqdn $viewname]
			}
		    }
		    EXISTS {
			if {[llength $lip] == 0} then {
			    return [mc {Name '%1$s' is not a host in view '%2$s'} $fqdn $viewname]
			}
		    }
		    CHECK {
			set ok [check-name-by-addresses $dbfd $idcor -1 trr]
			if {! $ok} then {
			    return [mc "You don't have rights on some IP addresses of '%s'" $fqdn]
			}
		    }
		    default {
			return [mc {Internal error: invalid parameter '%1$s' for '%2$s'} $parm "$context/$a"]
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
#	- idview : view id
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
#   2013/03/20 : pda      : add views
#

proc check-mx-target {dbfd prio name domain idview idcor _msg} {
    upvar $_msg msg

    #
    # Syntaxic checking of priority
    #

    if {! [regexp {^[0-9]+$} $prio]} then {
	set msg [mc {Invalid MX priority '%1$s' for '%2$s'} $prio "$name.$domain"]
	return {}
    }

    #
    # Check relay, domain, etc.
    #

    set msg [check-authorized-host $dbfd $idcor $name $domain $idview trr "existing-host"]
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
#	- idview: view id
#	- idcor : user id
#	- _exists : 1 if RR exists, 0 if not
#	- _trr : RR information read from database
# Output:
#   - return value: empty string or error message
#   - parameter _trr : RR information on return
#
# History
#   2010/12/09 : pda      : isolate common code
#   2013/03/21 : pda      : add views
#

proc check-authorized-mx {dbfd idcor name _iddom domain idview _exists _trr} {
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

    set exists [read-rr-by-name $dbfd $name $iddom $idview trr]
    if {$exists} then {
	#
	# If it already exists, check that it is not a A or CNAME or
	# anything else which is not a MX
	#

	if {[llength [rr-ip-by-view trr $idview]] > 0} then {
	    return [mc "'%s' already has IP addresses" $name]
	}
	set cname [rr-cname-by-view trr $idview]
	if {$cname ne ""} then {
	    return [mc "'%s' is an alias" $name]
	}

	#
	# MX exists, we must check that the user has permissions
	# to access all referenced domains.
	#

	foreach lmx [rr-mx-by-view trr $idview] {
	    lassign $lmx prio idmx
	    if {! [read-rr-by-id $dbfd $idmx tabmx]} then {
		return [mc "Internal error: rr_mx table references RR '%s', not found in the rr table" $idmx]
	    }
	    set iddom $tabmx(iddom)
	    set msg [check-domain $dbfd $idcor iddom tabmx(domain) ""]
	    if {$msg ne ""} then {
		return [mc {MX '%1$s' points to a domain on which you don't have rights\n%2$s} "$tabmx(nom).$tabmx(domain)" $msg]
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
#	- idview : view id
# Output:
#   - return value: empty string or error message
#   - parameter iddom : id of found domain, or -1 if error
#
# History
#   2004/03/04 : pda/jean : design
#   2010/11/29 : pda      : i18n
#   2013/03/20 : pda      : add views
#

proc check-domain-relay {dbfd idcor _iddom domain idview} {
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

    set sql "SELECT r.nom AS nom, d.name AS domain
		FROM dns.relay_dom rd, dns.rr r, dns.domain d
		WHERE rd.iddom = $iddom
			AND rd.mx = r.idrr
			AND r.iddom = d.iddom
			AND r.idview = $idview
		"
    pg_select $dbfd $sql tab {
	set msg [check-authorized-host $dbfd $idcor $tab(nom) $tab(domain) $idview trr "existing-host"]
	if {$msg ne ""} then {
	    return [mc {You don't have rights to some relays of domain '%1$s': %2$s} $domain $msg]
	}
    }

    return ""
}

#
# Check MAC against syntax errors and DHCP ranges
#
# Input:
#   - parameters:
#       - dbfd: database handle
#	- mac: MAC address (empty or not empty)
#	- trr: trr of host for which this MAC address is
#	- idview: view id
# Output:
#   - return value: empty string or error message
#
# History
#   2013/04/05 : pda/jean : design
#

proc check-mac {dbfd mac _trr idview} {
    upvar $_trr trr

    set msg ""
    if {$mac ne ""} then {
	set msg [check-mac-syntax $dbfd $mac]
	if {$msg eq ""} then {
	    set msg [check-static-dhcp $dbfd $mac [rr-ip-by-view trr $idview]]
	}
    }
    return $msg
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
		set r [mc {Impossible to use MAC address '%1$s' because IP address '%2$s' is in DHCP dynamic range [%3$s..%4$s]} $mac $ip $tab(min) $tab(max)]
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
	    set r [mc "Invalid TTL: must be less than %s" $maxttl]
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
	set r [mc "Invalid group name '%s' (allowed chars: letters, digits and minus symbol)" $group]
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
    pg_select $dbfd "SELECT idhinfo FROM dns.hinfo WHERE text = '$qtext'" tab {
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
    if {$text eq ""} then {
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
# Netmagis standard HTML menus
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
    set sql "SELECT text FROM dns.hinfo
				WHERE present = 1
				ORDER BY sort ASC, text ASC"
    set i 0
    set defindex 0
    pg_select $dbfd $sql tab {
	lappend lhinfo [list $tab(text) $tab(text)]
	if {$tab(text) eq $defval} then {
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
#   2002/05/03 : pda/jean : migrated in libdns
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
    # than one domain, use a dropdown menu.
    #

    set ndom [llength $lcouples]
    switch -- $ndom {
	0	{
	    d error [mc "Sorry, but you do not have any active domain"]
	}
	1	{
	    set v [lindex [lindex $lcouples 0] 0]
	    set h [::webapp::form-hidden $field $v]
	    set html "$v $h"
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
    set sql "SELECT domain.name
		FROM dns.domain, dns.p_dom, global.corresp
		WHERE domain.iddom = p_dom.iddom
		    AND p_dom.idgrp = corresp.idgrp
		    AND corresp.idcor = $idcor
		    $where
		ORDER BY p_dom.sort ASC, domain.name ASC"
    pg_select $dbfd $sql tab {
	lappend lcouples [list $tab(name) $tab(name)]
    }

    return $lcouples
}

#
# Get an HTML menu to select one view. This may be either a simple
# text with a hidden field if the group has access to only one view,
# or a menu.
#
# Input:
#   - dbfd : database handle
#   - idcor : user id
#   - field : field name
#   - sel : list of view id to pre-select, or empty list to pre-select
#	default views (those cited in the p_view.selected column)
# Output:
#   - return value: list {disp html} where disp=true if view menu
#	must be displayed, and html is html code (may be of "hidden"
#	input type) to be inserted.
#
# History :
#   2012/10/30 : pda/jean : design
#   2012/11/07 : pda/jean : add mult parameter and change return value
#   2013/04/10 : pda/jean : remove mult parameter
#

proc menu-view {dbfd idcor field sel} {
    set nsel [llength $sel]
    set lsel {}
    set lcouples {}
    set sql "SELECT v.idview, v.name, p.selected
		FROM dns.view v, dns.p_view p, global.corresp
		WHERE corresp.idcor = $idcor
		    AND p.idgrp = corresp.idgrp
		    AND v.idview = p.idview
		ORDER BY p.sort ASC, v.name ASC"
    set i 0
    pg_select $dbfd $sql tab {
	lappend lcouples [list $tab(idview) $tab(name)]
	if {$nsel == 0} then {
	    # no sel parameter given: use selected views for this group
	    if {$tab(selected)} then {
		lappend lsel $i
	    }
	} else {
	    # sel is a list of idviews
	    # search our idview in sel
	    if {[lsearch -exact $sel $tab(idview)] != -1} then {
		lappend lsel $i
	    }
	}
	incr i
    }

    set nviews [llength $lcouples]
    switch $nviews {
	0 {
	    d error [mc "Sorry, but you do not have access to any view"]
	}
	1 {
	    set idview [lindex [lindex $lcouples 0] 0]
	    set disp 0
	    set html [::webapp::form-hidden $field $idview]
	}
	default {
	    set disp 1
	    set html [::webapp::form-menu $field 1 0 $lcouples $lsel]
	}
    }

    return [list $disp $html]
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
	    set w1 "AND p.$priv > 0"
	    set w2 "AND n.$priv > 0"
	}
	acl {
	    set w1 "AND p.$priv > 0"
	    set w2 ""
	}
    }

    #
    # Get all allowed networks for this group and for this privilege
    #

    set lnet {}
    set sql "SELECT n.idnet, n.name, n.addr4, n.addr6
			FROM dns.network n, dns.p_network p
			WHERE n.idnet = p.idnet
			    AND p.idgrp = $idgrp
			    $w1 $w2
			ORDER BY addr4, addr6"
    pg_select $dbfd $sql tab {
	lappend lnet [list $tab(idnet) $tab(addr4) $tab(addr6) $tab(name)]
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
#   2012/04/26 : pda      : fix bug where non-html chars are replaced here
#

proc read-networks {dbfd idgrp priv} {
    set lnet {}
    foreach r [allowed-networks $dbfd $idgrp $priv] {
	lassign $r idnet cidr4 cidr6 name
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
	set msg [mc "Invalid network id '%s'" $netid]
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
	    set w1 "AND p.$priv > 0"
	    set w2 "AND n.$priv > 0"
	    set c [mc "You do not have DHCP access to this network"]
	}
	acl {
	    set w1 "AND p.$priv > 0"
	    set w2 ""
	    set c [mc "You do not have ACL access to this network"]
	}
    }

    #
    # Check network and read associated CIDR(s)
    #

    set lcidr {}
    set msg ""

    set sql "SELECT n.addr4, n.addr6
		    FROM dns.p_network p, dns.network n
		    WHERE p.idgrp = $idgrp
			AND p.idnet = n.idnet
			AND n.idnet = $netid
			$w1 $w2"
    set cidrplage4 ""
    set cidrplage6 ""
    pg_select $dbfd $sql tab {
	set cidrplage4 $tab(addr4)
	set cidrplage6 $tab(addr6)
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
# Generate HTML code to display and edit table content.
#
# Input:
#   - parameters:
#	- cwidth : list of column widths {w1 w2 ... wn} (unit = %)
#	- ctitle : list of column titles specification, each element
#		is {type value} where type = "html" or "text"
#	- cspec : list of column specifications, each element
#		is {id type defval}, where
#		- id : column id in the table, and name of field (idNN or idnNN)
#		- type : "text", "string N", "int N", "bool", "menu L",
#			"textarea {W H}" or "image URL"
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
	lappend lines [_display-tabular-line $cspec tabsql $idnum "existing"]
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
	lappend lines [_display-tabular-line $cspec tabdef $idnum "new"]
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
#	- new : "existing" or "new"
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
#   2012/01/02 : pda      : add parameter new
#

proc _display-tabular-line {cspec _tab idnum new} {
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
	    int {
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
	    image {
		if {$new eq "new"} then {
		    set item "&nbsp;"
		} else {
		    set item [format $typeopt $num]
		}
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
#	- check : name of a procedure to call on complete row
# Output:
#   - return value: none, this function exits if an error is encountered
#
# Notes :
#   - format of "cspec" is {{column type defval} ...}, where:
#	- column: column id in the table
#	- type : "text", "string N", "int N", "bool", "menu L",
#		"textarea {W H}" or "image URL"
#	- defval: the default value to store in the table
#		if the value is not provided
#   - first column of "cspec" is the key used to know if an entry must
#	be added or deleted.
#   - the check procedure will be called with parameters:
#		$check op dbfd _msg id idnum table _tabval
#	where:
#	- op : nop, mod, add, del
#	- dbfd : database handle
#	- _msg : error message if any
#	- id : id (value) of entry to modify (null if op == add)
#	- idnum : column name of the numeric id
#	- table : name of the SQL table to modify
#	- _tabval : array containing new values	(null if op == del)
#	the check procedure may modify _tabval.
#	It must returns 1 (ok) or 0 (err)
#
# History
#   2001/11/02 : pda      : specification and documentation
#   2001/11/02 : pda      : coding
#   2002/05/03 : pda/jean : remove an old constraint
#   2010/12/04 : pda      : i18n
#   2010/12/14 : pda      : use db lock methods
#   2012/01/03 : pda      : use ftab indexes rather than count until max index
#   2012/01/09 : pda      : add type to cspec and check parameter
#

proc store-tabular {dbfd cspec idnum table _ftab check} {
    upvar $_ftab ftab

    #
    # Lock the table
    #

    d dblock [list $table]

    #
    # Get used ids
    #

    set key [lindex [lindex $cspec 0] 0]

    set lid [array names ftab -regexp "^$key\[0-9\]+$"]
    regsub -all "\[\[:<:\]\]($key)(\[0-9\])" $lid {\2} lid
    set lid [lsort -increasing $lid]

    #
    # Get old ids, if we have to output a precise error message
    # when SQL transaction has aborted.
    #

    pg_select $dbfd "SELECT $key, $idnum FROM $table" tab {
	set okey $tab($idnum)
	set oldkeys($okey) $tab($key)
    }

    #
    # Traversal of existing ids in the database
    #

    foreach id $lid {
	if {[info exists ftab(${key}${id})]} {
	    _fill-tabval $cspec "" $id ftab tabval

	    if {$tabval($key) eq ""} then {
		#
		# Delete entry
		#

		set ok [_store-tabular-del $dbfd msg $id $idnum $table $check]
		if {! $ok} then {
		    #
		    # Deletion is not possible. Transaction may have been
		    # aborted. Look into the saved keys
		    #
		    set okey ""
		    if {[info exists oldkeys($id)]} then {
			set okey $oldkeys($id)
		    }
		    d dbabort [mc "delete %s" $okey] $msg
		}
	    } else {
		#
		# Modify entry
		#

		set ok [_store-tabular-mod $dbfd msg $id $idnum $table tabval $check]
		if {! $ok} then {
		    d dbabort [mc "modify %s" $tabval($key)] $msg
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

	    set ok [_store-tabular-add $dbfd msg $table tabval $check]
	    if {! $ok} then {
		d dbabort [mc "add %s" $tabval($key)] $msg
	    }
	}

	incr idnew
    }

    #
    # Unlock and commit modifications
    #

    d dbcommit [mc "store"]
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

    catch {unset tabval}

    foreach c $cspec {
	lassign $c var type defval

	set form ${var}${prefix}${num}

	if {[info exists ftab($form)]} then {
	    set tabval($var) [string trim [lindex $ftab($form) 0]]
	} else {
	    switch [lindex $type 0] {
		bool {
		    # boolean not checked is absent from form values
		    set tabval($var) 0
		}
		image {
		    # don't set variable
		    # the generated value is used as a comparison
		    # in order to check if value has been modified
		}
		default {
		    set tabval($var) $defval
		}
	    }
	}
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
#	- check : name of a procedure to call
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

proc _store-tabular-mod {dbfd _msg id idnum table _tabval check} {
    upvar $_msg msg
    upvar $_tabval tabval

    #
    # There is no need to modify anything if all values are identical.
    #

    set same 1
    pg_select $dbfd "SELECT * FROM $table WHERE $idnum = $id" tab {
	foreach attribut [array names tabval] {
	    if {$tabval($attribut) ne $tab($attribut)} then {
		set same 0
		break
	    }
	}
    }

    if {$same} then {
	set ok [$check "nop" $dbfd msg $id $idnum $table tabval]
    } else {
	#
	# It's different, we must do the work...
	#

	set ok [$check "mod" $dbfd msg $id $idnum $table tabval]
	if {$ok} then {
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

proc _store-tabular-del {dbfd _msg id idnum table check} {
    upvar $_msg msg

    set ok [$check "del" $dbfd msg $id $idnum $table {}]
    if {$ok} then {
	set sql "DELETE FROM $table WHERE $idnum = $id"
	set ok [::pgsql::execsql $dbfd $sql msg]
    }
    return $ok
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

proc _store-tabular-add {dbfd _msg table _tabval check} {
    upvar $_msg msg
    upvar $_tabval tabval

    set ok [$check "add" $dbfd msg {} {} $table tabval]
    if {$ok} then {
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
	set ok [::pgsql::execsql $dbfd $sql msg]
    }
    return $ok
}

##############################################################################
# Internal authentication functions
##############################################################################

#
# Internal (PostgreSQL) authenticaion management
#
# Historique
#   2003/05/30 : pda/jean : design
#   2003/06/12 : pda/jean : remove lsuser
#   2003/06/13 : pda/jean : add genpw, chpw and showuser
#   2003/06/27 : pda      : add edituser
#   2003/07/28 : pda      : split name and christian name
#   2003/12/11 : pda      : simplify
#   2005/05/25 : pda/jean : use ldap
#   2005/06/07 : pda/jean/zamboni : crypt command
#   2005/08/24 : pda      : add ldap port
#   2007/10/04 : jean     : ldap directory is no longer modified in setuser
#   2007/11/29 : pda/jean : merge old auth.tcl package and libauth.tcl
#   2011/01/02 : pda      : integration of libauth in libdns
#

# Fields in pgauth.user database table
set libconf(fields)	{login password nom prenom mel tel mobile fax adr}

# Fields : <title> <field spec> <form var name> <user>
# with <user> = 1 if field contains information about user (else : search only)
set libconf(editfields) {
    {Login 	{string 10} login	1}
    {Name	{string 40} nom		1}
    {Method	{yesno {%1$s Regular expression %2$s Phonetic}} phren 0}
    {{First name}	{string 40} prenom	1}
    {Method	{yesno {%1$s Regular expression %2$s Phonetic}} phrep 0}
    {Address	{text 3 40} adr		1}
    {Mail	{string 40} mel		1}
    {Phone	{string 15} tel		1}
    {Fax	{string 15} fax		1}
    {Mobile	{string 15} mobile	1}
}
set libconf(editrealms) {
    {{Realms}	{list multi ...} realms 1}
}

#
# Tabular formats (see arrgen(n)):
#	- tabuchoice : user selection with clickable login
#	- tabumod : user add/modify form
#	- tabulist : user list (to display or print)
#

set libconf(tabuchoice) {
    global {
	chars {10 normal}
	align {left}
	botbar {yes}
	columns {11 26 35 28 10}
	latex {
	    linewidth {267}
	}
    }
    pattern Title {
	title {yes}
	topbar {yes}
	chars {bold}
	align {center}
	vbar {yes}
	column { }
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
    pattern User {
	vbar {yes}
	column {
	    format {raw}
	}
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

set libconf(tabumod) {
    global {
	align {left}
	botbar {no}
	columns {25 75}
    }
    pattern {Normal} {
	vbar {no}
	column { }
	vbar {no}
	column {
	    format {raw}
	}
	vbar {no}
    }
}

set libconf(tabulist) {
    global {
	chars {10 normal}
	align {left}
	botbar {yes}
	columns {8 16 32 10 10 10 14 10}
	latex {
	    linewidth {267}
	}
    }
    pattern Title {
	title {yes}
	topbar {yes}
	chars {bold}
	align {center}
	vbar {yes}
	column { }
	vbar {yes}
	column { }
	vbar {yes}
	column { }
	vbar {yes}
	column { }
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
    pattern User {
	chars {8}
	vbar {yes}
	column { }
	vbar {yes}
	column { }
	vbar {yes}
	column { }
	vbar {yes}
	column { }
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

######################################
# User management
######################################

#
# Read user entry
#
# Input:
#   - parameters :
#	- dbfd : database handle
#	- login : user login
#	- tab : array containing, in return, user information
# Output:
#   - return value : 1 if found, 0 if not found
#   - parameter tab : 
#	tab(login)	login
#	tab(nom)	name
#	tab(prenom)	christian name
#	tab(mel)	email address
#	tab(tel)	phone number
#	tab(fax)	facsimile number
#	tab(mobile)	mobile phone number
#	tab(adr)	postal address
#	tab(encryption)	"crypt" if password is encrypted
#	tab(password)	password (crypted or not)
#	tab(realms)	list of realms to which user belongs
#
# History
#   2003/05/13 : pda/jean : design
#   2003/05/30 : pda/jean : add realms
#   2005/05/25 : pda/jean : add ldap code
#   2007/12/04 : pda/jean : remove ldap code
#   2010/12/29 : pda      : i18n and netmagis merge
#

proc pgauth-getuser {dbfd login _tab} {
    upvar $_tab tab
    global libconf

    set found 0
    set qlogin [::pgsql::quote $login]
    set sql "SELECT * FROM pgauth.user WHERE login = '$qlogin'"
    pg_select $dbfd $sql tabsql {
	foreach c $libconf(fields) {
	    set tab($c) $tabsql($c)
	}
	set found 1
    }
    set tab(realms) {}
    set sql "SELECT realm FROM pgauth.member WHERE login = '$qlogin'"
    pg_select $dbfd $sql tabsql {
	lappend tab(realms) $tabsql(realm)
    }
    return $found
}

#
# Modify or create a user
#
# Input:
#   - parameters :
#	- dbfd : database handle
#	- tab : see getuser
#	- transact : "transaction" (by default) or "no transaction"
# Output:
#   - return value : empty string or error message
#
# Note : if password field is nul, a crypted "*" is set by default
#	(meaning that this account is not active)
#
# History
#   2003/05/13 : pda/jean : design
#   2003/05/30 : pda/jean : add realms
#   2003/08/05 : pda      : add transactions
#   2007/12/04 : pda/jean : specialization for postgresql
#   2010/12/29 : pda      : i18n and netmagis merge
#

proc pgauth-setuser {dbfd _tab {transact transaction}} {
    upvar $_tab tab
    global libconf

    if {! [regexp -- {^[a-z][-a-z0-9\.]*$} $tab(login)]} then {
	return [mc {Invalid login syntax (^[a-z][-a-z0-9\.]*$)}]
    }

    if {$transact eq "transaction"} then {
	set tr 1
	d dblock {pgauth.user pgauth.member}
    } else {
	set tr 0
    }

    #
    # Remove user
    #
    set msg [pgauth-deluser $dbfd $tab(login) "no transaction"]
    if {$msg ne ""} then {
	if {$tr} then {
	    d dbabort [mc "delete %s" $tab(login)] $msg
	}
	return $msg
    }

    #
    # If password does not exist, invalid login
    #
    if {! [info exists tab(password)]} then {
	set tab(password) "*"
    }

    #
    # Insert user data in database
    #
    set cols {}
    set vals {}
    foreach c $libconf(fields) {
	if {[info exists tab($c)]} then {
	    lappend cols $c
	    lappend vals "'[::pgsql::quote $tab($c)]'"
	}
    }
    set cols [join $cols ","]
    set vals [join $vals ","]
    set sql "INSERT INTO pgauth.user ($cols) VALUES ($vals)"
    if {![::pgsql::execsql $dbfd $sql msg]} then {
	if {$tr} then {
	    d dbabort [mc "add %s" $tab(login)] $msg
	}
	return [mc {Unable to insert account '%1$s': %2$s} $tab(login) $msg]
    }

    #
    # Insert membership
    #
    set sql ""
    foreach r $tab(realms) {
	append sql "INSERT INTO pgauth.member (login, realm) VALUES
			('$tab(login)', '$r') ;"
    }
    if {! [::pgsql::execsql $dbfd $sql msg]} then {
	if {$tr} then {
	    d dbabort [mc "add %s" $tab(login)] $msg
	}
	return [mc {Unable to insert '%1$s' membership: %2$s} $tab(login) $msg]
    }

    #
    # Transaction end
    #
    if {$tr} then {
	d dbcommit [mc "add %s" $tab(login)]
    }

    return ""
}

#
# Remove user entry
#
# Input:
#   - parameters :
#	- dbfd : database handle
#	- login : login name
#	- transact : "transaction" (default) or "no transaction"
# Output:
#   - return value : empty string or error message
#
# History
#   2003/05/13 : pda/jean : design
#   2003/05/30 : pda/jean : add realms
#   2007/12/04 : pda/jean : specialization for postgresql
#   2010/12/29 : pda      : i18n and netmagis merge
#

proc pgauth-deluser {dbfd login {transact transaction}} {
    if {$transact eq "transaction"} then {
	set tr 1
	d dblock {pgauth.user pgauth.member}
    } else {
	set tr 0
    }

    set qlogin [::pgsql::quote $login]
    set sql "DELETE FROM pgauth.member WHERE login = '$qlogin'"
    if {! [::pgsql::execsql $dbfd $sql msg]} then {
	if {$tr} then {
	    d dbabort [mc "delete %s" $login] $msg
	}
	return $msg
    }

    set sql "DELETE FROM pgauth.user WHERE login = '$qlogin'"
    if {! [::pgsql::execsql $dbfd $sql msg]} then {
	if {$tr} then {
	    d dbabort [mc "delete %s" $login] $msg
	}
	return $msg
    }


    if {$tr} then {
	d dbcommit [mc "add %s" $login]
    }

    return ""
}

#
# Search a user with criterion
#
# Input:
#   - parameters :
#	- dbfd : database handle
#	- tabcrit : array containing criterion
#		login, nom, prenom, adr, mel, tel, mobile, fax, realm
#		or phnom, phprenom for phonetic searches
#	- sort (optional) : list {sort...} where
#		sort = +/- sort-criterion
# Output:
#   - return value : list of found logins
#
# Note : each criterion is a regexp (* and ? only)
#
# History
#   2003/06/06 : pda/jean : design
#   2003/08/01 : pda/jean : phonetic criterions
#   2003/08/11 : pda      : search "or" on more than one realm
#   2007/12/04 : pda/jean : specialization for postgresql
#   2010/12/29 : pda      : i18n and netmagis merge
#

proc pgauth-searchuser {dbfd _tabcrit {sort {+nom +prenom}}} {
    upvar $_tabcrit tabcrit

    #
    # Build-up the "where" clause
    #

    set clauses {}
    set nwheres 0
    set from ""
    foreach c {login phnom phprenom nom prenom adr mel tel mobile fax realm} {
	if {[info exists tabcrit($c)]} then {
	    set re $tabcrit($c)
	    if {$re ne ""} then {
		set re [::pgsql::quote $re]
		# quote SQL special characters
		regsub -all -- {%} $re {\\%} re
		regsub -all -- {_} $re {\\_} re
		# quote *our* special characters
		regsub -all -- {\*} $re {%} re
		regsub -all -- {\?} $re {_} re

		if {$c eq "realm"} then {
		    set from ", pgauth.member"
		    set table "pgauth.member"
		    lappend clauses "pgauth.user.login = member.login"
		} else {
		    set table "pgauth.user"
		}

		if {$c eq "phnom" || $c eq "phprenom"} then {
		    lappend clauses "$table.$c = pgauth.soundex('$re')"
		} elseif {$c eq "realm"} then {
		    set or {}
		    foreach r $tabcrit(realm) {
			set qr [::pgsql::quote $r]
			lappend or "$table.realm = '$qr'"
		    }
		    if {[llength $or] > 0} then {
			set sor [join $or " OR "]
			lappend clauses "($sor)"
		    }
		} else {
		    # ILIKE = LIKE sans tenir compte de la casse
		    lappend clauses "$table.$c ILIKE '$re'"
		}
		incr nwheres
	    }
	}
    }
    if {$nwheres > 0} then {
	set where [join $clauses " AND "]
	set where "WHERE $where"
    } else {
	set where ""
    }

    #
    # Build-up sort criterion
    #

    set sqlsort {}
    set sqldistinct {}
    foreach t $sort {
	set way [string range $t 0 0]
	set col [string range $t 1 end]
	switch -- $way {
	    -		{ set way "DESC" }
	    +  		-
	    default	{ set way "ASC" }
	}
	if {$col in {login nom prenom mel tel adr mobile fax}} then {
	    lappend sqlsort "pgauth.user.$col $way"
# XXX : I don't understand why I used this distinct clause
#	    lappend sqldistinct "pgauth.user.$col"
	}
    }
    if {[llength $sqlsort] == 0} then {
	set orderby ""
    } else {
	set orderby [join $sqlsort ", "]
	set orderby "ORDER BY $orderby"
    }

    if {[llength $sqldistinct] == 0} then {
	set distinct ""
    } else {
	set distinct [join $sqldistinct ", "]
	set distinct "DISTINCT ON ($distinct)"
    }

    #
    # Build the list of logins
    #

    set lusers {}
    set sql "SELECT $distinct pgauth.user.login
		FROM pgauth.user $from
		$where
		$orderby"
    pg_select $dbfd $sql tab {
	lappend lusers $tab(login)
    }

    return $lusers
}

#
# Crypt a password
#
# Input:
#   - parameters :
#	- str : string to crypt
# Output:
#   - return value : crypted string
#
# History
#   2003/05/13 : pda/jean : design
#   2005/07/22 : pda/jean : secure special characters
#   2010/12/29 : pda      : i18n and netmagis merge
#   2013/02/08 : pda/jean : apply schplurtz's patch
#

proc pgauth-crypt {str} {
    regsub -all {'} $str {'\\''} str
    set crypt [get-local-conf "crypt"]
    return [exec sh -c [format $crypt "'$str'"]]
}

#
# Generate a semi-random password
#
# Input:
#   - parameters : (none)
# Output:
#   - return value : generated clear-text password
#
# History
#   2003/06/13 : pda/jean : design
#   2010/12/29 : pda      : i18n and netmagis merge
#

proc pgauth-genpw {} {
    set pwgen [get-local-conf "pwgen"]
    return [exec sh -c $pwgen]
}

#
# Process password modification
#
# Input:
#   - parameters :
#	- dbfd : database handle
#	- login : user login
#	- action : list {action parameters} where:
#		action = "block"    (no parameter)
#		action = "generate" (no parameter)
#		action = "change"   (parameters = password twice)
#	- mail : {mail} or {nomail}, if the password must be sent by mail or not
#		In the "mail" case, this parameter is a list
#			{mail from replyto cc bcc subject body}
#	- _newpw : in return, new password
# Output:
#   - return value : empty string or error message
#
# History
#   2003/06/13 : pda/jean : design
#   2003/12/08 : pda      : more complete "mail" parameter
#   2010/12/29 : pda      : i18n and netmagis merge
#

proc pgauth-chpw {dbfd login action mail _newpw} {
    upvar $_newpw newpw
    global libconf

    if {! [pgauth-getuser $dbfd $login tab]} then {
	return [mc "Login '%s' does not exist" $login]
    }

    switch -- [lindex $action 0] {
	block {
	    set newpw [mc "<invalid>"]
	    set tab(password) "*"
	}
	generate {
	    set newpw [pgauth-genpw]
	    set tab(password) [pgauth-crypt $newpw]
	}
	change {
	    lassign $action c pw1 pw2

	    if {$pw1 ne $pw2} then {
		return [mc "Password mismatch"]
	    }
	    set newpw $pw1

	    if {[regexp {[\\'"`()]} $newpw]} then {
		return [mc "Invalid character in password"]
	    }

	    set minpwlen [::dnsconfig get "authpgminpwlen"]
	    set maxpwlen [::dnsconfig get "authpgmaxpwlen"]

	    if {[string length $newpw] < $minpwlen} then {
		return [mc "Password to short (< %s characters)" $minpwlen]
	    }
	    set newpw [string range $newpw 0 [expr $maxpwlen-1]]

	    set tab(password) [pgauth-crypt $newpw]
	}
	default {
	    return [mc "Internal error: invalid 'action' value (%s)" $action]
	}
    }

    if {[lindex $mail 0] eq "mail"} then {
	lassign $mail b from repl cc bcc subj body
	if {[::webapp::valid-email $tab(mel)]} then {
	    set body [format $body $login $newpw]
	    ::webapp::mail $from $repl $tab(mel) $cc $bcc $subj $body
	} else {
	    return [mc "Invalid mail address, password is not modified"]
	}
    }

    return [pgauth-setuser $dbfd tab]
}

######################################
# Pgsql realm management
######################################

#
# List existing realms
#
# Input:
#   - parameters :
#	- dbfd : database handle
#	- tab : in return, array containing realm list
#		tab(<realm>) {<descr> <list of users>}
# Output:
#   - return value : (none)
#
# History
#   2003/05/30 : pda/jean : design
#   2007/12/04 : pda/jean : specialization for postgresql
#   2010/12/27 : pda      : i18n and netmagis merge
#

proc pgauth-lsrealm {dbfd _tab} {
    upvar $_tab tab

    set sql "SELECT * FROM pgauth.realm"
    pg_select $dbfd $sql tabsql {
	set realm $tabsql(realm)
	set descr $tabsql(descr)
	set admin $tabsql(admin)
	set members {}
	set sqlm "SELECT login FROM pgauth.member WHERE realm = '$realm'"
	pg_select $dbfd $sqlm tabm {
	    lappend members $tabm(login)
	}
	set tab($realm) [list $descr $members $admin]
    }
}

#
# Add a PG realm into database
#
# Input:
#   - parameters :
#	- dbfd : database handle
#	- realm : realm name
#	- descr : realm description
#	- admin : 0 or 1
#	- _msg : in return, error message (if any)
# Output:
#   - return value : 1 (ok) or 0 (error)
#   - parameter _msg : error message if any
#
# History
#   2003/05/30 : pda/jean : design
#   2007/12/04 : pda/jean : specialization for postgresql
#   2010/12/27 : pda      : i18n and netmagis merge
#   2011/01/07 : pda      : add admin
#

proc pgauth-addrealm {dbfd realm descr admin _msg} {
    upvar $_msg msg

    set msg ""
    if {[regexp -- {^[a-z][-a-z0-9]*$} $realm]} then {
	set qrealm [::pgsql::quote $realm]
	set qdescr  [::pgsql::quote $descr]
	set sql "INSERT INTO pgauth.realm (realm, descr, admin)
				VALUES ('$qrealm', '$qdescr', $admin)"
	if {! [::pgsql::execsql $dbfd $sql m]} then {
	    set msg [mc {Unable to insert realm '%1$s': %2$s} $realm $m]
	}
    } else {
	set msg [mc {Invalid realm syntax (^[a-z][-a-z0-9]*$)}]
    }
    return [string equal $msg ""]
}

#
# Remove a realm from database
#
# Input:
#   - parameters :
#	- dbfd : database handle
#	- realm : realm name
#	- _msg : in return, error message (if any)
# Output:
#   - return value : 1 (ok) or 0 (error)
#   - parameter _msg : error message if any
#
# Note : this function do not remove realms which have members
#   (thanks to the SQL constraint)
#
# History
#   2003/05/30 : pda/jean : design
#   2007/12/04 : pda/jean : specialization for postgresql
#   2010/12/28 : pda      : i18n and netmagis merge
#

proc pgauth-delrealm {dbfd realm _msg} {
    upvar $_msg msg

    set msg ""
    set qrealm [::pgsql::quote $realm]
    set sql "DELETE FROM pgauth.realm WHERE realm = '$qrealm'"
    if {! [::pgsql::execsql $dbfd $sql m]} then {
	set msg [mc {Unable to remove realm '%1$s': %2$s} $realm $m]
    }
    return [string equal $msg ""]
}

#
# Modify a realm
#
# Input:
#   - parameters :
#	- dbfd : database handle
#	- realm : realm name
#	- descr : realm description
#	- admin : 0 or 1
#	- members : list of members
#	- _msg : in return, error message (if any)
# Output:
#   - return value : 1 (ok) or 0 (error)
#   - parameter _msg : error message if any
#
# History
#   2003/06/04 : pda/jean : design
#   2007/12/04 : pda/jean : specialization for postgresql
#   2010/12/29 : pda      : i18n and netmagis merge
#   2011/01/07 : pda      : add admin
#

proc pgauth-setrealm {dbfd realm descr admin members _msg} {
    upvar $_msg msg

    set qrealm [::pgsql::quote $realm]

    d dblock {}

    #
    # If realm does not exists, create it. If it exists, modify description.
    #

    set sql "SELECT realm FROM pgauth.realm WHERE realm = '$qrealm'"
    set found 0
    pg_select $dbfd $sql tab {
	set found 1
    }
    if {! $found} then {
	if {! [pgauth-addrealm $dbfd $realm $descr $admin msg]} then {
	    d dbabort [mc "add %s" $realm] $msg
	}
    } else {
	set qdescr [::pgsql::quote $descr]
	set sql "UPDATE pgauth.realm
			SET descr = '$qdescr', admin = $admin
			WHERE realm = '$qrealm'"
	if {! [::pgsql::execsql $dbfd $sql m]} then {
	    d dbabort [mc "modify %s" $realm] $msg
	}
    }

    #
    # Remove member list
    #
    set sql "DELETE FROM pgauth.member WHERE realm = '$qrealm'"
    if {! [::pgsql::execsql $dbfd $sql m]} then {
	d dbabort [mc "modify %s" $realm] $msg
    }

    #
    # Update member list
    #
    foreach login $members {
	set qlogin [::pgsql::quote $login]
	set sql "INSERT INTO pgauth.member (login, realm)
			VALUES ('$qlogin', '$qrealm')"
	if {! [::pgsql::execsql $dbfd $sql msg]} then {
	    d dbabort [mc "add %s" "$login/$realm"] $msg
	}
    }

    d dbcommit [mc "modify %s" $realm]

    set msg ""
    return 1
}

#
# Returns an HTML menu to select realms
#
# Input:
#   - parameters :
#	- dbfd : database handle
#	- var : name of form variable
#	- multiple : 1 if multiple choice, 0 if only one choice
#	- realmsel : list of preselected realms (or empty list)
# Output:
#   - return value : HTML code
#
# History
#   2003/06/03 : pda/jean : design
#   2003/06/13 : pda/jean : add parameter realmsel
#   2003/06/27 : pda      : package
#   2010/12/28 : pda      : i18n and netmagis merge
#

proc pgauth-htmlrealmmenu {dbfd var multiple realmsel} {
    #
    # Index pre-selected realms
    #
    foreach r $realmsel {
	set tabsel($r) ""
    }

    #
    # Get realm list
    #
    pgauth-lsrealm $dbfd tabrlm

    #
    # Build key/value list for the menu
    #

    set l {}
    set lsel {}
    set idx 0
    foreach r [lsort [array names tabrlm]] {
	lappend l [list $r $r]
	if {[info exists tabsel($r)]} then {
	    lappend lsel $idx
	}
	incr idx
    }

    #
    # Multiple choices?
    #

    if {$multiple} then {
	set size [llength [array names tabrlm]]
    } else {
	set size 1
    }

    return [::webapp::form-menu $var $size $multiple $l $lsel]
}

######################################
# HTML account management
######################################

#
# Heart of CGI script for applications which manage users.
#
# Input:
#   - parameters :
#	- e : execution environment of the script, as an indexed array:
#		dbfd : access to auth database
#		url : url of CGI script
#		realms : realms where application user can belong to.
#			If realms = {}, we can access every realm
#			If only one realm, realm list is not displayed when
#				adding a user
#		maxrealms : maximum number of realms displayed in the listbox
#			or 0 to use exact number of displayed realms
#		page-* : HTML/LaTeX templates
#			-index : index of different actions
#			-ok : action done
#			-add1 : first page of user add
#			-choice : choice of user, if more than one found
#			-mod : parameter modification
#			-del : confirm user removal
#			-passwd : actions on user password
#			-list : list of users
#			-listtex : list of users in latex format
#			-sel : user selection with criterion
#		specif : application specific user data
#				{{<title> <type>} ...}
#			(see ::webapp::form-field for type)
#		script-* : scripts to execute to access and display user
#			characteristics, specific to an application:
#			- getuser : display user information and returns a
#				list {value ...} in the same order than
#				in "specif" list
#			- deluser : remove user from application
#			- setuser : add or modify user in application
#			- chkuser : check if a user modification is authorized
#		mailfrom : mail header in case of password generation
#		mailreplyto : mail header in case of password generation
#		mailcc : mail header in case of password generation
#		mailbcc : mail header in case of password generation
#		mailsubject : mail header in case of password generation
#		mailbody : mail header in case of password generation
#	- ftab : form tab
# Output:
#   - return value : (none)
#   - stdout : an HTML page
#
# History
#   2003/07/29 : pda      : design
#   2003/07/31 : pda/jean : done
#   2003/12/14 : pda      : add mail*
#   2010/12/29 : pda      : i18n and netmagis merge
#   2011/01/07 : pda      : add ftab array
#

proc pgauth-accmanage {_e _ftab} {
    upvar $_e e
    upvar $_ftab ftab

    set form {
	{action 0 1}
	{state  0 1}
    }
    pgauth-get-data ftab $form
    ::webapp::import-vars ftab $form

    switch -- $action {
	add     { set l [pgauth-ac-add       e ftab $state] }
	list    -
	print   { set l [pgauth-ac-consprn   e ftab $state $action] }
	del     -
	mod     -
	passwd  { set l [pgauth-ac-delmodpwd e ftab $state $action] }
	default { set l [pgauth-ac-nothing   e ftab $state] }
    }
    lassign $l format page lsubst

    lappend lsubst [list %ACTION% $action]
    d urlset "%URLFORM%" $e(url) {}
    d result $page $lsubst
    exit 0
}

proc pgauth-get-data {_ftab form} {
    upvar $_ftab ftab

    if {[llength [::webapp::get-data ftab $form]] != [llength $form]} then {
	d error [mc "Invalid input '%s'" $ftab(_error)]
    }
}

proc pgauth-ac-nothing {_e _ftab state} {
    upvar $_e e
    upvar $_ftab ftab

    return [list "html" $e(page-index) {}]
}

proc pgauth-ac-add {_e _ftab state} {
    upvar $_e e
    upvar $_ftab ftab

    set lsubst {}
    switch -- $state {
	nom {
	    #
	    # User name has been introduced. Search this name.
	    #
	    set form {
		    {nom 1 1}
		}
	    pgauth-get-data ftab $form

	    set nom [lindex $ftab(nom) 0]
	    set tabcrit(phnom) $nom
	    set lusers [pgauth-searchuser $e(dbfd) tabcrit {+nom +prenom}]
	    set nbut [llength $lusers]

	    if {$nbut > 0} then {
		#
		# Some users match this name.
		#
		#	%ACTION%
		#	%MESSAGE%
		#	%LISTEUTILISATEURS%
		#	%AUCUN%
		#
		set qnom [::webapp::html-string $nom]
		set message [mc "Some accounts match '%s'. Choose one, or ask for a new account" $qnom]
		lappend lsubst [list %MESSAGE% $message]

		lappend lsubst [list %LISTEUTILISATEURS% \
				    [pgauth-ac-display-choice e $lusers "ajout"] \
				]

		d urlset "" $e(url) [list {action add} \
					{state nouveau} \
					[list "nom" $nom] \
				    ]
		set url [d urlget ""]
		set aucun [::webapp::helem "form" \
				    [::webapp::form-submit {} [mc "Create a new account"]]
				    "method" "post" "action" $url]
		lappend lsubst [list %AUCUN% $aucun]

		set page $e(page-choice)
	    } else {
		#
		# No user match. Prepare the form to add a new user.
		#
		#	%ACTION%
		#	%STATE%
		#	%LOGIN%
		#	%PARAMUTILISATEUR%
		#	%TITRE%
		#
		set lsubst [pgauth-ac-display-mod e "_new" $nom]
		set page $e(page-mod)
	    }
	}
	plusdun {
	    #
	    # One user selected. Prepare form to input user modifications.
	    #
	    #	%ACTION%
	    #	%STATE%
	    #	%LOGIN%
	    #	%PARAMUTILISATEUR%
	    #	%TITRE%
	    #
	    set form {
		    {login 1 1}
		}
	    pgauth-get-data ftab $form

	    set login [lindex $ftab(login) 0]
	    set lsubst [pgauth-ac-display-mod e $login ""]
	    set page $e(page-mod)
	}
	nouveau {
	    #
	    # User addition required. Prepare form to input a new user.
	    #
	    #	%ACTION%
	    #	%LOGIN%
	    #	%PARAMUTILISATEUR%
	    #
	    set form {
		    {nom 0 1}
		}
	    pgauth-get-data ftab $form

	    set nom [lindex $ftab(nom) 0]

	    set lsubst [pgauth-ac-display-mod e "_new" $nom]
	    set page $e(page-mod)
	}
	creation {
	    #
	    # New user data is given. Create user, and give control
	    # to the password modification page.
	    #
	    #	%ACTION% (passwd)
	    #	%LOGIN%
	    #
	    set form {
		    {login 1 1}
	    }
	    pgauth-get-data ftab $form

	    set login [lindex $ftab(login) 0]
	    if {[pgauth-getuser $e(dbfd) $login u]} then {
		d error [mc "Login '%s' already exists" $login]
	    }

	    #
	    # New user. Ignore supplementary and give control to
	    # the password modification page.
	    #
	    pgauth-ac-store-mod e ftab $login

	    set lsubst [concat $lsubst [pgauth-ac-display-passwd e $login]]
	    set page $e(page-passwd)
	}
	ok {
	    #
	    # Store modification of an existing user.
	    #
	    #	%TITREACTION% (ajout)
	    #	%COMPLEMENT%
	    #
	    set form {
		    {login 1 1}
	    }
	    pgauth-get-data ftab $form

	    set login [lindex $ftab(login) 0]
	    if {! [pgauth-getuser $e(dbfd) $login u]} then {
		d error [mc "Login '%s' does not exist" $login]
	    }

	    #
	    # Existing user in database
	    #
	    set lsubst [pgauth-ac-store-mod e ftab $login]
	    set page $e(page-ok)
	}
	default {
	    set page $e(page-add1)
	}
    }
    return [list "html" $page $lsubst]
}

proc pgauth-ac-consprn {_e _ftab state mode} {
    upvar $_e e
    upvar $_ftab ftab
    global libconf

    set lsubst {}
    set format "html"
    switch -- $state {
	criteres {
	    #
	    # Criterion is given
	    #
	    #	%NBUTILISATEURS%
	    #	%S%
	    #	%DATE%
	    #	%HEURE%
	    #	%TABLEAU%
	    #

	    set lusers [pgauth-ac-search-crit e ftab]
	    if {[llength $lusers] == 0} then {
		#
		# No user found. Display again the criterion selection page.
		#
		set lsubst [pgauth-ac-display-crit e ftab [mc "No account found"]]
		set page $e(page-sel)
	    } else {
		#
		# Guess output format
		#

		switch $mode {
		    list {
			set tabfmt "html"
			set page $e(page-list)
		    }
		    print {
			set format "pdf"
			set tabfmt "latex"
			set page $e(page-listtex)
		    }
		}

		#
		# Display user list
		#

		set lines {}
		lappend lines [list "Title" \
				    [mc "Login"] \
				    [mc "Name"] \
				    [mc "Address"] \
				    [mc "Mail"] \
				    [mc "Phone"] \
				    [mc "Fax"] \
				    [mc "Mobile"] \
				    [mc "Realms"] \
				]
		foreach login $lusers {
		    if {[pgauth-getuser $e(dbfd) $login tab]} then {
			set myrealms [pgauth-ac-my-realms e $tab(realms)]
			lappend lines [list "User" \
					    $tab(login) \
					    "$tab(nom) $tab(prenom)" \
					    $tab(adr) \
					    $tab(mel) \
					    $tab(tel) $tab(fax) $tab(mobile) \
					    $myrealms
					] \
		    }
		}
		set tableau [::arrgen::output $tabfmt $libconf(tabulist) $lines]

		#
		# Time
		#

		set date  [clock format [clock seconds] -format "%d/%m/%Y"]
		set heure [clock format [clock seconds] -format "%Hh%M"]

		lappend lsubst [list %TABLEAU% $tableau]
	    	lappend lsubst [list %NBUTILISATEURS% [llength $lusers]]
		lappend lsubst [list %DATE% $date]
		lappend lsubst [list %HEURE% $heure]
	    }
	}
	default {
	    #
	    # Initial page to select criteria
	    #
	    #	%ACTION%
	    #	%MESSAGE%
	    #	%CRITERES%
	    #
	    set lsubst [pgauth-ac-display-crit e ftab ""]
	    set page $e(page-sel)
	}
    }
    return [list $format $page $lsubst]
}

proc pgauth-ac-delmodpwd {_e _ftab state action} {
    upvar $_e e
    upvar $_ftab ftab

    switch -- $state {
	criteres {
	    #
	    # Criterion was given
	    #
	    #	%LOGIN%
	    #	%NOM%
	    #	%PRENOM%
	    #

	    set lusers [pgauth-ac-search-crit e ftab]
	    switch [llength $lusers] {
		0 {
		    #
		    # No user found
		    #
		    set lsubst [pgauth-ac-display-crit e ftab [mc "No account found"]]
		    set page $e(page-sel)
		}
		1 {
		    #
		    # Display page to remove, modify or change password
		    # of an user
		    #
		    set login [lindex $lusers 0]
		    switch -- $action {
			del {
			    set lsubst [pgauth-ac-display-del e $login]
			    set page $e(page-del)
			}
			mod {
			    set lsubst [pgauth-ac-display-mod e $login ""]
			    set page $e(page-mod)
			}
			passwd {
			    set lsubst [pgauth-ac-display-passwd e $login]
			    set page $e(page-passwd)
			}
			default {
			    d error [mc "Invalid input"]
			}
		    }
		}
		default {
		    #
		    # Some users match.
		    #
		    #	%ACTION%
		    #	%MESSAGE%
		    #	%LISTEUTILISATEURS%
		    #	%AUCUN%
		    #
		    set message [mc "Some accounts match criteria. Choose one"]
		    lappend lsubst [list %MESSAGE% $message]

		    lappend lsubst [list %LISTEUTILISATEURS% \
					[pgauth-ac-display-choice e $lusers $action] \
				    ]

		    lappend lsubst [list %AUCUN% ""]
		    set page $e(page-choice)
		}
	    }
	}
	plusdun {
	    #
	    # Display page to remove, modify or change password of an user
	    #
	    set form {
		{login 1 1}
	    }
	    pgauth-get-data ftab $form

	    set login [lindex $ftab(login) 0]

	    if {! [pgauth-getuser $e(dbfd) $login u]} then {
		d error [mc "Login '%s' does not exist" $login]
	    }

	    switch -- $action {
		del {
		    set lsubst [pgauth-ac-display-del e $login]
		    set page $e(page-del)
		}
		mod {
		    set lsubst [pgauth-ac-display-mod e $login ""]
		    set page $e(page-mod)
		}
		passwd {
		    set lsubst [pgauth-ac-display-passwd e $login]
		    set page $e(page-passwd)
		}
		default {
		    d error [mc "Invalid input"]
		}
	    }

	}
	ok {
	    #
	    # Perform action
	    #

	    set form {
		{login 1 1}
	    }
	    pgauth-get-data ftab $form

	    set login [lindex $ftab(login) 0]

	    if {! [pgauth-getuser $e(dbfd) $login u]} then {
		d error [mc "Login '%s' does not exist" $login]
	    }

	    set page $e(page-ok)
	    switch -- $action {
		del {
		    set lsubst [pgauth-ac-del-user e ftab $login]
		}
		mod {
		    set lsubst [pgauth-ac-store-mod e ftab $login]
		}
		passwd {
		    set lsubst [pgauth-ac-store-passwd e ftab $login]
		}
		default {
		    d error [mc "Invalid input"]
		}
	    }
	}
	default {
	    #
	    # Initial page for criteria
	    #
	    #	%ACTION%
	    #	%MESSAGE%
	    #	%CRITERES%
	    #
	    set lsubst [pgauth-ac-display-crit e ftab ""]
	    set page $e(page-sel)
	}
    }

    return [list "html" $page $lsubst]
}

#
# Utility functions for pgauth-accmanage
#

#
# Returns a realm list, extract from "realms" , where only authorized
# realms (i.e. those in e(realms)) are displayed. If e(realms) is
# empty, all realms may be displayed.
#

proc pgauth-ac-my-realms {_e realms} {
    upvar $_e e

    if {[llength $e(realms)] == 0} then {
	set rr $realms
    } else {
	foreach r $e(realms) {
	    set x($r) 0
	}
	set rr {}
	foreach r $realms {
	    if {[info exists x($r)]} then {
		lappend rr $r
	    }
	}
    }
    return $rr
}

#
# Returns a list of users with associated URLs
#
# Return : value for %LISTEUTILISATEURS%
#

proc pgauth-ac-display-choice {_e lusers action} {
    upvar $_e e
    global libconf

    set lines {}
    lappend lines [list "Title" \
			    [mc "Login"] \
			    [mc "Name"] \
			    [mc "Address"] \
			    [mc "Mail"] \
			    [mc "Realms"] \
			]
    foreach login $lusers {
	if {[pgauth-getuser $e(dbfd) $login tab]} then {
	    set hlogin [::webapp::html-string $login]
	    d urlset "" $e(url) [list [list "action" $action] \
					{state plusdun} \
					[list "login" $login] \
				    ]
	    set url [d urlget ""]
	    set urllogin [::webapp::helem "a" $hlogin "href" $url]
	    set myrealms [pgauth-ac-my-realms e $tab(realms)]
	    lappend lines [list "User" \
					$urllogin "$tab(nom) $tab(prenom)" \
					$tab(adr) $tab(mel) $myrealms
				    ]
	}
    }
    return [::arrgen::output "html" $libconf(tabuchoice) $lines]
}

#
# Returns a form part to input user information
#
# Retour : values for %LOGIN%, %PARAMUTILISATEUR%, %STATE% and %TITRE%
#

proc pgauth-ac-display-mod {_e login nom} {
    upvar $_e e
    global libconf

    #
    # Get auth data for user, or simulate them if this is a creation
    #

    set new [string equal $login "_new"]
    if {$new} then {
	array set u {
	    login {}
	    nom {}
	    prenom {}
	    adr {}
	    mel {}
	    tel {}
	    fax {}
	    mobile {}
	    realms {}
	}
	set u(nom) $nom
	set state "creation"
	set title [mc "Creation"]
    } else {
	if {! [pgauth-getuser $e(dbfd) $login u]} then {
	    d error [mc "Login '%s' does not exist" $login]
	}
	set state "ok"
	set title [mc "Modification"]
    }

    #
    # Realm edition choice
    #

    set menurealms [pgauth-build-realm-index $e(dbfd) "list" \
				0 $e(realms) $e(maxrealms) gidx]

    #
    # Get existing values, or default values for a new user
    #

    set valu [uplevel 3 [format $e(script-getuser) $login]]

    #
    # Input fields for user
    #

    set lines {}

    foreach c [concat $libconf(editfields) $libconf(editrealms)] {
	lassign $c ctitle spec var user
	if {$var eq "login" && ! $new} then {
	    #
	    # Special case for "login" field if editable
	    #
	    set t [::webapp::html-string $login]
	    append t [::webapp::form-hidden "login" $login]
	} elseif {$var eq "realms"} then {
	    #
	    # Special case for realms
	    #
	    if {[llength $menurealms] == 0} then {
		set t ""
	    } else {
		set lidx {}
		foreach r $u(realms) {
		    if {[info exists gidx($r)]} then {
			lappend lidx $gidx($r)
		    }
		}
		set t [::webapp::form-field $menurealms $var $lidx]
	    }
	} elseif {$user} then {
	    #
	    # General case : a field to modify
	    #
	    if {[lindex $spec 0] eq "yesno"} then {
		set spec [list "yesno" [mc [lindex $spec 1]]]
	    }
	    set t [::webapp::form-field $spec $var $u($var)]
	} else {
	    #
	    # Else, it is only a field for search (eg: phnom/phprenom)
	    #
	    set t ""
	}

	if {$t ne ""} then {
	    set l [list Normal [mc $ctitle] $t]
	    lappend lines $l
	}
    }

    #
    # Generate input field specific to the application
    #

    set n 0
    foreach c $e(specif) v $valu {
	lassign $c ctitle spec
	incr n
	set var "uvar$n"
	lappend lines [list "Normal" $ctitle [::webapp::form-field $spec $var $v]]
    }

    set paramutilisateur [::arrgen::output html $libconf(tabumod) $lines]

    #
    # Substitution lists
    #

    lappend lsubst [list %LOGIN%	    $login]
    lappend lsubst [list %PARAMUTILISATEUR% $paramutilisateur]
    lappend lsubst [list %STATE%	    $state]
    lappend lsubst [list %TITRE%	    $title]

    return $lsubst
}

#
# Store user information (new or modification)
#
# Return : values for %TITREACTION% and %COMPLEMENT%
#

proc pgauth-ac-store-mod {_e _ftab login} {
    upvar $_e e
    upvar $_ftab ftab
    global libconf

    #
    # Check if the script is authorized to modify user
    #
    set msg [uplevel 3 [format $e(script-chkuser) $login]]
    if {$msg ne ""} then {
	d error [mc {Unable to modify '%1$s': %2$s} $login $msg]
    }

    #
    # Extract field values
    #

    set form [pgauth-build-form-spec "mod" \
			[concat $libconf(editfields) $libconf(editrealms)] \
			$e(specif) \
		    ]
    pgauth-get-data ftab $form

    #
    # Get existing data from database
    #
    set u(realms) {}
    set new [expr ! [pgauth-getuser $e(dbfd) $login u]]

    d dblock {pgauth.user pgauth.member}

    #
    # Set user data. Realms will be set after.
    #
    foreach c $libconf(editfields) {
	lassign $c title spec var user
	if {$user} then {
	    set u($var) [lindex $ftab($var) 0]
	}
    }

    #
    # Realm management
    #	- if e(realms) is empty
    #		authorize all specific realms in form
    #	- if e(realms) contains only one element
    #		do not use form data, and add realm in database
    #	- lif e(realms) contains more than one element
    #		use form data, and set all realms present in e(realms)
    #
    pgauth-lsrealm $e(dbfd) tabrlm
    switch [llength $e(realms)] {
	0 {
	    foreach r $ftab(realms) {
		if {! [info exists tabrlm($r)]} then {
		    d error [mc "Invalid realm '%s'" $r]
		}
	    }
	    set u(realms) $ftab(realms)
	}
	1 {
	    set found 0
	    set er [lindex $e(realms) 0]
	    foreach r $u(realms) {
		if {$r eq $er} then {
		    set found 1
		    break
		}
	    }
	    if {! $found} then {
		lappend u(realms) $er
	    }
	}
	default {
	    foreach r $e(realms) {
		set ar($r) 1
	    }

	    # nr = u realms, minus realms from e(realms)
	    set nr {}
	    foreach r $u(realms) {
		if {! [info exists ar($r)]} then {
		    lappend nr $r
		}
	    }
	    set u(realms) $nr

	    # add form realms, if they are also in ar()
	    foreach r $ftab(realms) {
		if {! [info exists tabrlm($r)]} then {
		    d error [mc "Invalid realm '%s'" $r]
		}
		if {[info exists ar($r)]} then {
		    lappend u(realms) $r
		}
	    }
	}
    }

    #
    # Store user in database
    #
    set msg [pgauth-setuser $e(dbfd) u "no transaction"]
    if {$msg ne ""} then {
	d dbabort [mc "add %s" $login] $msg
    }


    #
    # Store application specific data
    #
    set lval {}
    set i 1
    while {[info exists ftab(uvar$i)]} {
	lappend lval $ftab(uvar$i)
	incr i
    }

    set msg [uplevel 3 [format $e(script-setuser) $login $lval]]
    if {$msg ne ""} then {
	d dbabort [mc "add %s" $login] $msg
    }

    #
    # C'est fini, on y va !
    #
    d dbcommit [mc "add %s" $login]

    if {$new} then {
	set title [mc "Account '%s' insertion" $login]
    } else {
	set title [mc "Account '%s' modification" $login]
    }

    set lsubst {}
    lappend lsubst [list %TITREACTION% $title]
    lappend lsubst [list %COMPLEMENT% ""]
    return $lsubst
}

#
# Display search criterion
#
# Return : values for %CRITERES% and %MESSAGE%
#

proc pgauth-ac-display-crit {_e _ftab msg} {
    upvar $_e e
    upvar $_ftab ftab
    global libconf

    #
    # Realm management
    #

    set menurealms [pgauth-build-realm-index $e(dbfd) "menu" 1 $e(realms) 1 {}]
    if {[llength $menurealms] == 0} then {
	set menurealms {hidden}
    }

    #
    # Generate input form
    #

    set lines {}
    foreach c [concat $libconf(editfields) $libconf(editrealms)] {
	lassign $c title spec var user
	if {$var eq "realms"} then {
	    set t [::webapp::form-field $menurealms $var ""]
	} else {
	    if {[lindex $spec 0] eq "yesno"} then {
		set spec [list "yesno" [mc [lindex $spec 1]]]
	    }
	    set t [::webapp::form-field $spec $var ""]
	}

	set l [list "Normal" [mc $title] $t]
	lappend lines $l
    }
    set crit [::arrgen::output html $libconf(tabumod) $lines]

    set lsubst {}
    lappend lsubst [list %CRITERES% $crit]
    lappend lsubst [list %MESSAGE% $msg]

    return $lsubst
}

#
# Exploit search criterion to return a list of users
#
# Return : list of found logins
#

proc pgauth-ac-search-crit {_e _ftab} {
    upvar $_e e
    upvar $_ftab ftab
    global libconf

    #
    # Get parameters
    #

    set form [pgauth-build-form-spec "crit" \
			[concat $libconf(editfields) $libconf(editrealms)] \
			{} \
		    ]
    pgauth-get-data ftab $form

    foreach f $form {
	set var [lindex $f 0]
	set $var [string trim [lindex $ftab($var) 0]]
    }

    #
    # If no clause is specified, return an appropriate message (without
    # returning all users, which could be long).
    # If we really want all users, one must explicit this by using the
    # "*" special character in a criterion.
    #

    set ncrit 0
    foreach var {login nom prenom mel adr realms} {
	if {[set $var] ne ""} then {
	    incr ncrit
	}
    }

    set allrealms 1
    if {! ($realms eq "_" || $realms eq "")} then {
	set allrealms 0
	incr ncrit
    }

    if {$ncrit == 0} then {
	d error [mc "You did not specify any criterion"]
    }

    #
    # Use phonetic search
    #

    if {[regexp {^[01]$} $phren] && $phren} then {
	set phnom ""
    } else {
	set phnom $nom
	set nom ""
    }

    if {[regexp {^[01]$} $phrep] && $phrep} then {
	set phprenom ""
    } else {
	set phprenom $prenom
	set prenom ""
    }

    #
    # Search with specified criterion
    #
    # Special case for realms: we search for the specified realm, or
    # all realms (those defined, or those found in database) is nothing
    # is specified.
    #

    foreach var {login nom prenom phnom phprenom mel adr} {
	set tabcrit($var) [set $var]
    }

    if {$allrealms} then {
	if {[llength $e(realms)] > 0} then {
	    set tabcrit(realm) $e(realms)
	}
    } else {
	set lr $e(realms)
	if {[llength $lr] == 0} then {
	    pgauth-lsrealm $e(dbfd) tabrlm
	    set lr [array names tabrlm]
	}
	if {[lsearch -exact $lr $realms] == -1} then {
	    d error [mc "Realm '%s' not found" $realms]
	}
	set tabcrit(realm) $realms
    }

    return [pgauth-searchuser $e(dbfd) tabcrit {+nom +prenom}]
}

#
# Display possible actions for a password change
#
# Return : values for %LOGIN%, %NOM% and %PRENOM%.
#

proc pgauth-ac-display-passwd {_e login} {
    upvar $_e e

    if {! [pgauth-getuser $e(dbfd) $login u]} then {
	d error [mc "Login '%s' does not exist" $login]
    }

    set login  [::webapp::html-string $login]
    set nom    [::webapp::html-string $u(nom)]
    set prenom [::webapp::html-string $u(prenom)]

    set minpwlen [::dnsconfig get "authpgminpwlen"]
    set maxpwlen [::dnsconfig get "authpgmaxpwlen"]

    set lsubst {}
    lappend lsubst [list %LOGIN%    $login]
    lappend lsubst [list %NOM%      $nom]
    lappend lsubst [list %PRENOM%   $prenom]
    lappend lsubst [list %MINPWLEN% $minpwlen]
    lappend lsubst [list %MAXPWLEN% $maxpwlen]

    return $lsubst
}

#
# Store a password
#
# Return : values for %TITREACTION% and %COMPLEMENT%
#

proc pgauth-ac-store-passwd {_e _ftab login} {
    upvar $_e e
    upvar $_ftab ftab

    #
    # Check if the script is authorized to modify user
    #
    set msg [uplevel 3 [format $e(script-chkuser) $login]]
    if {$msg ne ""} then {
	d error [mc {Unable to change password of '%1$s': %2$s} $login $msg]
    }

    #
    # Get form values
    #
    set form {
	{pw1	0 1}
	{pw2	0 1}
	{block	0 1}
	{gen	0 1}
	{change	0 1}
    }

    pgauth-get-data ftab $form
    ::webapp::import-vars ftab $form

    set hlogin [::webapp::html-string $login]

    if {$block ne ""} then {
	set msg [pgauth-chpw $e(dbfd) $login {block} "nomail" {}]
	set res [mc "Block account '%s'" $hlogin]
	set comp ""
    } elseif {$gen ne ""} then {
	set mail [list "mail" $e(mailfrom) $e(mailreplyto) \
			    $e(mailcc) $e(mailbcc) \
			    [encoding convertto iso8859-1 $e(mailsubject)] \
			    [encoding convertto iso8859-1 $e(mailbody)]]
	set msg [pgauth-chpw $e(dbfd) $login {generate} $mail newpw]
	set res [mc {Password generation (%1$s) for %2$s} $newpw $hlogin]
	set comp [mc "Password has been sent by mail"]
    } elseif {$change ne ""} then {
	set pw1 [lindex $ftab(pw1) 0]
	set pw2 [lindex $ftab(pw2) 0]
	set msg [pgauth-chpw $e(dbfd) $login [list "change" $pw1 $pw2] "nomail" {}]
	set res [mc "Password change for '%s'" $hlogin]
	set comp ""
    } else {
	d error [mc "Invalid input"]
    }

    if {$msg ne ""} then {
	d error $msg
    }

    #
    # Display result
    #

    set lsubst {}
    lappend lsubst [list %TITREACTION% $res]
    lappend lsubst [list %COMPLEMENT% $comp]

    return $lsubst
}

#
# Display removal confirmation page
#
# Return : value for %UTILISATEUR%
#

proc pgauth-ac-display-del {_e login} {
    upvar $_e e

    if {! [pgauth-getuser $e(dbfd) $login u]} then {
	return [mc "Login '%s' does not exist" $login]
    }

    set lsubst {}
    lappend lsubst [list %UTILISATEUR%  $login]
    lappend lsubst [list %LOGIN%  [::webapp::html-string $login]]
    return $lsubst
}

#
# Remove user
#
# Return : values for %TITREACTION% and %COMPLEMENT%
#

proc pgauth-ac-del-user {_e _ftab login} {
    upvar $_e e
    upvar $_ftab ftab

    #
    # Default messages
    #
    set msg [mc "Remove '%s' from application" $login]
    set comp [mc "Account is still active in authentication subsystem"]

    #
    # Check if the script is authorized to modify user
    #
    set msg [uplevel 3 [format $e(script-chkuser) $login]]
    if {$msg ne ""} then {
	d error [mc {Unable to modify '%1$s': %2$s} $login $msg]
    }

    #
    # Remove rights on application
    #
    set msg [uplevel 3 [format $e(script-deluser) $login]]
    if {$msg ne ""} then {
	d error $msg
    }

    #
    # Remove from realms
    #
    if {! [pgauth-getuser $e(dbfd) $login u]} then {
	set comp [mc "Login '%s' does not exist" $login]
    } else {
	set rmr {}
	set nr {}
	foreach r $u(realms) {
	    if {[lsearch -exact $e(realms) $r] == -1} then {
		# realm is not one of the realms to remove
		lappend nr $r
	    } else {
		# realm to remove
		lappend rmr $r
	    }
	}
	if {[llength $nr] != [llength $u(realms)]} then {
	    set u(realms) $nr
	    set m [pgauth-setuser $e(dbfd) u]
	    if {$m eq ""} then {
		set rmr [join $rmr ", "]
		set comp [mc "Account has been removed from realms: %s" $rmr]
	    } else {
		set comp [mc {Error while removing realms %1$s: %2$s} $rmr $m]
	    }
	}
    }

    set lsubst {}
    lappend lsubst [list %TITREACTION% [::webapp::html-string $msg]]
    lappend lsubst [list %COMPLEMENT% [::webapp::html-string $comp]]
    return $lsubst
}

#
# Build a form spec
#
# Input:
#	- modif : "mod" or "crit"
#	- spec1 : see variable libconf(editfields)
#	- spec2 : see e(specif) in pgauth-accmanage
# Output:
#	- list ready for get-data
#

proc pgauth-build-form-spec {modif spec1 spec2} {
    set form {}

    foreach c $spec1 {
	lassign $c title spec var user
	set kw [lindex $spec 0]
	if {$modif eq "mod"} then {
	    if {$user} then {
		switch -- $kw {
		    list	{ lappend form [list $var 0 99999] }
		    default	{ lappend form [list $var 1 1] }
		}
	    }
	} else {
	    switch -- $kw {
		list	{ lappend form [list $var 1 1] }
		default	{ lappend form [list $var 1 1] }
	    }
	}
    }

    set nvar 0
    foreach c $spec2 {
	incr nvar
	set kw [lindex [lindex $c 1] 0]
	set var "uvar$nvar"
	switch -- $kw {
	    list	{ lappend form [list $var 0 99999] }
	    default	{ lappend form [list $var 1 1] }
	}
    }

    return $form
}

#
# Build a menu or a listbox with realms
#
# Input:
#	- dbfd : database handle
#	- type : list or menu
#	- all : true if entry "All" should be displayed
#	- rlmlist : list of realms to manage
#	- maxrlm : max number of realms to display
#	- _gidx : in return, array of indexes
# Output :
#	- field ready to be displayed by form-field
#

proc pgauth-build-realm-index {dbfd type all rlmlist maxrlm _gidx} {
    upvar $_gidx gidx

    pgauth-lsrealm $dbfd tabrlm

    set menurealms {}
    set i 0
    switch [llength $rlmlist] {
	0 {
	    #
	    # Menu with all available realms
	    #
	    if {$all} then {
		lappend menurealms [list "_" [mc "All"]]
		incr i
	    }
	    foreach r [lsort [array names tabrlm]] {
		set gidx($r) $i
		lappend menurealms [list $r $r]
		incr i
	    }
	}
	1 {
	    #
	    # Don't authorize realm input
	    #
	}
	default {
	    #
	    # Authorize selected realm input
	    #
	    if {$all} then {
		lappend menurealms [list "_" [mc "All"]]
		incr i
	    }
	    foreach r $rlmlist {
		if {[info exists tabrlm($r)]} then {
		    set gidx($r) $i
		    lappend menurealms [list $r $r]
		} else {
		    lappend menurealms [list [mc "Invalid realm '%s'"] $r]
		}
		incr i
	    }
	}
    }

    set nrealms [llength $menurealms]
    if {$nrealms > 0} then {
	if {$maxrlm > 0 && $nrealms > $maxrlm} then {
	    set nrealms $maxrlm
	}
	if {$type eq "list"} then {
	    set menurealms [linsert $menurealms 0 "list" "multi" $nrealms]
	} else {
	    set menurealms [linsert $menurealms 0 "menu"]
	}
    }

    return $menurealms
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
	    append text [::webapp::helem "p" [mc "... since %s" $date]]

	    set msgsta [::webapp::helem "div" $text "class" "alerte"]
	}
    }
    return $msgsta
}

#
# Wrapper function to call topo programs on topo host
#
# Input:
#   - cmd: topo program with arguments
#   - _msg : in return, text read from program or error message
# Output:
#   - return value: 1 if ok, 0 if failure
#   - parameter _msg: text read or error message
#
# History
#   2010/12/14 : pda/jean : design
#   2010/12/19 : pda      : added topouser
#   2012/04/24 : pda      : the graph file is local to the www server
#

proc call-topo {cmd _msg} {
    upvar $_msg msg

    #
    # Quote shell metacharacters to prevent interpretation
    #
    regsub -all {[<>|;'"${}()&\[\]*?]} $cmd {\\&} cmd

    set topobindir [get-local-conf "topobindir"]
    set topograph  [get-local-conf "topograph"]
    set topohost   [get-local-conf "topohost"]

    set cmd "$topobindir/$cmd < $topograph"
    set r [catch {exec sh -c $cmd} msg option]
    return [expr !$r]
}

#
# Compare two interface names (for sort function)
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
    if {! [call-topo $cmd msg]} then {
	return [mc "Cannot read sensor list: %s" $msg]
    }
    foreach line [split $msg "\n"] {
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

    #
    # Error if id is not found
    #

    if {[llength $lid] > 0} then {
	return [mc "Sensor '%s' not found" $id]
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
		    set title [mc "Traffic on interfaces %s" $le]
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
	d error [mc "No access: %s" $code]
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
    if {! [call-topo $cmd msg]} then {
	d error [mc {Error during extraction of readable interfaces from '%1$s': %2$s} $eq $msg]
    }
    foreach line [split $msg "\n"] {
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

    if {! $found} then {
	d error [mc "Equipment '%s' not found" $eq]
    }

    #
    # Second call to exctracteq : get the list of "writable" interfaces
    #

    set liferr {}

    if {$manual eq "auto"} then {
	set cmd [format $libconf(extracteq) $tabuid(flagsw) $eq]
	if {! [call-topo $cmd msg]} then {
	    d error [mc {Error during extraction of writable interfaces from '%1$s': %2$s} $eq $msg]
	}
	foreach line [split $msg "\n"] {
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

    XXX fix bug below (read-rr-by-name without idview)

    #
    # Search for equipment idrr in the database
    #
    
    if {! [regexp {^([^.]+)\.(.+)$} $eq bidon host domain]} then {
        set host $eq
        set domain [dnsconfig get "defdomain"]
    }

    set iddom [read-domain $dbfd $domain]
    if {$iddom == -1} then {
	d error [mc "Domain '%s' not found" $domain]
    }
    if {! [read-rr-by-name $dbfd $host $iddom tabrr]} then {
	d error [mc "Equipment '%s' not found" $eq]
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
	set chg [mc "description='%s'" $ifdesc]
	if {$ethervlan == -1} then {
	    append chg ", "
	    append chg [mc "deactivated interface"]
	} else {
	    append chg ", "
	    append chg [mc "vlan=%s" $ethervlan]
	    if {$voicevlan != -1} then {
		append chg ", "
		append chg [mc "voip=%s" $voicevlan]
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


##############################################################################
# Topo*d subsystem
##############################################################################

#
# Set function tracing
#
# Input: 
#   - lfunct : list of function names
# Output: none
#
# History
#   2010/10/20 : pda/jean : minimal design
#   2010/12/15 : pda/jean : splitted in library
#

proc set-trace {lfunct} {
    foreach c $lfunct {
	trace add execution $c enter report-enter
	trace add execution $c leave report-leave
    }
}

proc report-enter {cmd enter} {
    puts "> $cmd"
}

proc report-leave {cmd code result leave} {
    puts "< $cmd -> $code/$result"
}

#
# Run a program as a daemon
#
# Input: 
#   - argv0  : path to the script
#   - argstr : argument string
# Output: none
#
# History
#   2012/03/27 : pda/jean : design
#

proc run-as-daemon {argv0 argstr} {
    exec sh -c "exec $argv0 $argstr" &
    exit 0
}

##############################################################################
# Utility functions
##############################################################################

#
# Initialize system logger
#
# Input: 
#   - logger : shell command line to log messages
# Output: none
#
# History
#   2010/12/15 : pda/jean : minimal design
#

set ctxt(logger) ""

proc set-log {logger} {
    global ctxt

    set ctxt(logger) $logger
}

#
# Add a message to the log
#
# Input: 
#   - msg : error/warning message
# Output: none
#
# History
#   2010/10/20 : pda/jean : minimal design
#

proc log-error {msg} {
    global ctxt

    if {[catch {open "|$ctxt(logger)" "w"} fd]} then {
	puts stderr "$msg (log to syslog: $fd)"
    } else {
	puts $fd $msg
	close $fd
    }
}

#
# Set verbosity level
#
# Input: 
#   - level : threshold (verbosity level) of messages to display
# Output:
#   - return value: none
#   - ctxt(verbose) : verbose threshold
#
# History
#   2010/10/21 : pda/jean : design
#

proc topo-set-verbose {level} {
    global ctxt

    set ctxt(verbose) $level
}

#
# Display debug message according to verbosity level
#
# Input: 
#   - msg : message
#   - level : verbosity level
# Output: none
#
# History
#   2010/10/21 : pda/jean : design
#

proc topo-verbositer {msg level} {
    global ctxt

    if {$level <= $ctxt(verbose)} then {
	puts stderr $msg
    }
}

##############################################################################
# Status management
##############################################################################

#
# Update status
# Status keeps last topo*d operations.
#
# Input: 
#   - status : current operation
# Output: none
#
# Note: status is in topo.keepstate table, topo.message is a list
# {{date1 msg1} {date2 msg2} ...} where 1 is the most recent entry.
# We keep only last N entries.
#
# History
#   2010/11/05 : pda/jean : design
#

proc reset-status {} {
    set sql "DELETE FROM topo.keepstate WHERE type = 'status'"
    toposqlexec $sql 2
}

proc set-status {status} {
    global ctxt

    set cur {}
    set sql "SELECT message FROM topo.keepstate WHERE type = 'status'"
    if {! [toposqlselect $sql tab { set cur $tab(message) } 2]} then {
	return
    }

    # insert new entry before all others
    set date [clock format [clock seconds]]
    set cur [linsert $cur 0 [list $date $status]]

    # remove oldest entries at the end
    if {[llength $cur] > $ctxt(maxstatus)} then {
	set cur [lreplace $cur $ctxt(maxstatus) end]
    }

    set qcur [::pgsql::quote $cur]

    set sql "DELETE FROM topo.keepstate WHERE type = 'status' ;
		INSERT INTO topo.keepstate (type, message)
			VALUES ('status', '$qcur')"
    toposqlexec $sql 2
}

##############################################################################
# Topo*d database handling
##############################################################################

#
# Connect to database if needed
#
# Input:
#   - chan : database channel
#   - ctxt(dbfd1), ctxt(dbfd2) : database handles for each channel
# Output:
#   - ctxt(dbfd<n>) : database handle updated
#
# History
#   2010/10/20 : pda/jean : documentation
#

proc lazy-connect {{chan 1}} {
    global ctxt

    set r 1
    if {[string equal $ctxt(dbfd$chan) ""]} then {
	set conninfo [get-conninfo "dnsdb"]
	set d [catch {set ctxt(dbfd$chan) [pg_connect -conninfo $conninfo]} msg]
	if {$d} then {
	    set r 0
	} else {
	    ::dnsconfig setdb $ctxt(dbfd$chan)
	    log-error "Connexion to database succeeded"
	}
    }
    return $r
}

#
# Execute a SQL request to get data (as with pg_select), and manage
# database reconnect
#
# Input: 
#   - sql : SQL request
#   - arrayname : array used in the script
#   - script : procedure ou script
#   - chan : optionnal channel (1 or 2)
# Output: 
#   - return value: 1 if ok, 0 if error
#
# History
#   2010/10/20 : pda/jean : design (woaw !)
#

proc toposqlselect {sql arrayname script {chan 1}} {
    global ctxt

    if {[lazy-connect $chan]} {
	set cmd [list pg_select $ctxt(dbfd$chan) $sql $arrayname $script]
	if {[catch {uplevel 1 $cmd} err]} then {
	    log-error "Connexion to database lost in toposqlselect ($err)"
	    catch {pg_disconnect $ctxt(dbfd$chan)}
	    set ctxt(dbfd$chan) ""
	    set r 0
	} else {
	    set r 1
	}
    } else {
	set r 0
    }
    return $r
}

#
# Execute a SQL request to modify data (INSERT, UPDATE or DELETE, as
# with pg_exec) and manage database reconnect
#
# Input: 
#   - sql : SQL request
#   - chan : optionnal channel (1 or 2)
# Output: 
#   - return value: 1 if ok, 0 if error
#
# History
#   2010/10/20 : pda/jean : design
#

proc toposqlexec {sql {chan 1}} {
    global ctxt

    if {[lazy-connect]} {
	if {[catch {pg_exec $ctxt(dbfd$chan) $sql} res]} then {
	    log-error "Connection to database lost in toposqlexec ($res)"
	    catch {pg_disconnect $ctxt(dbfd$chan)}
	    set ctxt(dbfd$chan) ""
	    set r 0
	} else {
	    switch -- [pg_result $res -status] {
		PGRES_COMMAND_OK -
		PGRES_TUPLES_OK -
		PGRES_EMPTY_QUERY {
		    set r 1
		    pg_result $res -clear
		}
		default {
		    set err [pg_result $res -error]
		    pg_result $res -clear
		    log-error "Internal error in toposqlexec. Connexion to database lost ($err)"
		    catch {pg_disconnect $ctxt(dbfd$chan)}
		    set ctxt(dbfd$chan) ""
		    set r 0
		}
	    }
	}
    } else {
	set r 0
    }
    return $r
}

#
# Start a SQL transaction and manage database reconnect
#
# Input: 
#   - chan : optionnal channel (1 or 2)
# Output: 
#   - return value: 1 if ok, 0 if error
#
# History
#   2010/10/21 : pda/jean : design
#

proc toposqllock {{chan 1}} {
    return [toposqlexec "START TRANSACTION" $chan]
}

#
# End a SQL transaction and manage database reconnect
#
# Input: 
#   - commit : "commit" or "abort"
# Output: 
#   - return value: 1 if ok, 0 if error
#
# History
#   2010/10/21 : pda/jean : design
#

proc toposqlunlock {commit {chan 1}} {
    switch $commit {
	commit { set sql "COMMIT WORK" }
	abort  { set sql "ABORT WORK" }
    }
    return [toposqlexec $sql $chan]
}


##############################################################################
# Topo*d mail management
##############################################################################

#
# Send a mail if event message changes
#
# Input:
#   - ev : event ("rancid", "anaconf", etc.)
#   - msg : event message
# Output:
#   - none
#
# History
#   2010/10/21 : pda/jean : design
#

proc keep-state-mail {ev msg} {
    #
    # Get previous message
    #

    set oldmsg ""
    set qev [::pgsql::quote $ev]
    set sql "SELECT message FROM topo.keepstate WHERE type = '$qev'"
    if {! [toposqlselect $sql tab { set oldmsg $tab(message) } 2]} then {
	# we don't know what to do...
	return
    }

    if {$msg ne $oldmsg} then {
	#
	# New message is different from previous one. We must
	# send it by mail and store it in keepstate table.
	#
	# Design choice: if database access is out of order, we
	# can't access keepstate. The choice is to not send mail.
	# The risk is we won't known new messages, but the advantage
	# is that our mailboxes will not be polluted by a new
	# identical mail every X seconds. On the other hand, risk
	# is minimized by the fact that no new change will be detected
	# and/or processed while database is out of order.
	#

	set qmsg [::pgsql::quote $msg]
	set sql "DELETE FROM topo.keepstate WHERE type = '$qev' ;
		    INSERT INTO topo.keepstate (type, message)
			    VALUES ('$qev', '$qmsg')"
	if {[toposqlexec $sql 2]} then {
	    #
	    # Database access is ok. Send the mail.
	    #

	    set from    [::dnsconfig get "topofrom"]
	    set to	[::dnsconfig get "topoto"]
	    set replyto	""
	    set cc	""
	    set bcc	""
	    set subject	"\[auto\] topod status changed for $ev"
	    ::webapp::mail $from $replyto $to $cc $bcc $subject $msg
	}
    }
}

##############################################################################
# Equipment types
##############################################################################

#
# Read type and model for all equipments in the graph.
#
# Input:
#   - _tabeq : name of array containing, in return, types and models
# Output:
#   - return value: empty string or error message
#   - tabeq : array, indexed by FQDN of equipement, containing:
#	tabeq(<eq>) {<type> <model>}
# 
# History
#   2010/02/25 : pda/jean : design
#   2010/10/21 : pda/jean : manage only fully qualified host names
#

set libconf(dumpgraph-read-eq-type) "dumpgraph -a -o eq"

proc read-eq-type {_tabeq} {
    global libconf
    upvar $_tabeq tabeq

    set-status "Reading equipement types"

    set defdom [dnsconfig get "defdomain"]

    set cmd $libconf(dumpgraph-read-eq-type)

    if {[call-topo $cmd msg]} then {
	foreach line [split $msg "\n"] {
	    switch [lindex $line 0] {
		eq {
		    array set t $line
		    set eq $t(eq)
		    set type $t(type)
		    set model $t(model)

		    append eq ".$defdom"

		    set tabeq($eq) [list $type $model]

		    array unset t
		}
	    }
	}
	set msg ""
    }

    return $msg
}

##############################################################################
# Detection of modifications in files
##############################################################################

#
# Detect modifications in a directory
#
# Input:
#   - dir : directory path
#   - _err : in return, empty string or error message
# Output:
#   - return value : list {{<code> <file> <date>} {<code> <file> <date>}...}
#	where <code> = "add", "del", "mod" or "err"
#	and <date> = date in clock_t format
#	if <code> = "err", error message is in "<date>"
#   - parameter err : in return, all error messages
# 
# History 
#   2010/11/12 : pda/jean : design
#

proc detect-dirmod {dir _err} {
    upvar $_err err

    set err ""

    #
    # First pass: get all files in directory and keep them in an array:
    #	ntab(<file>) <date>
    #
    foreach file [glob -nocomplain "$dir/*.eq"] {
	if {[catch {file mtime $file} date]} then {
	    append err "$date\n"
	} else {
	    set ntab($file) $date
	}
    }

    #
    # Second pass: get all files in database for this directory and
    # keep them in an array:
    #	otab(<file>) <date>
    #
    set sql "SELECT path, date FROM topo.filemonitor
				WHERE path ~ '^$dir/\[^/\]+$'"
    if {! [toposqlselect $sql tab { set otab($tab(path)) [clock scan $tab(date)] }]} then {
	append err "Cannot execute SQL SELECT query for $dir\n"
	return {}
    }

    #
    # Difference analysis
    #
    set r {}
    if {$err eq ""} then {
	foreach f [array names otab] {
	    if {[info exists ntab($f)]} then {
		if {$otab($f) != $ntab($f)} then {
		    lappend r [list "mod" $f $ntab($f)]
		}
		unset ntab($f)
	    } else {
		lappend r [list "del" $f ""]
	    }
	    unset otab($f)
	}

	foreach f [array names ntab] {
	    lappend r [list "add" $f $ntab($f)]
	}
    }

    return $r
}

#
# Detect if a file has been modified
#
# Input:
#   - path : directory path
# Output:
#   - return value : see detect-dirmod
#
# History 
#   2010/11/12 : pda/jean : design
#

proc detect-filemod {path} {
    set oldfmod -1
    set qpath [::pgsql::quote $path]
    set sql "SELECT date FROM topo.filemonitor WHERE path = '$qpath'"
    if {[toposqlselect $sql tab {set oldfmod [clock scan $tab(date)]}]} then {
	if {[catch {file mtime $path} newfmod]} then {
	    #
	    # Error: we suppose that file does not exist
	    #
	    if {$oldfmod == -1} then {
		# file did not exist before, does not exists now
		set r [list "err" $path "Error on '$path': $newfmod"]
	    } else {
		# file was existing, but not now
		set r [list "del" $path ""]
	    }
	    set newfmod ""
	} else {
	    #
	    # File exists
	    #
	    if {$oldfmod == -1} then {
		# the file is new
		set r [list "add" $path $newfmod]
	    } elseif {$oldfmod == $newfmod} then {
		# dates are the same: file has not been modified
		set r {}
	    } else {
		# file is modified
		set r [list "mod" $path $newfmod]
	    }
	}
    } else {
	set r [list $path "err" "Error on '$path' : SQL query failed"]
    }
    topo-verbositer "detect-filemod: $path => $r" 9

    return $r
}

#
# Update file modification times in database
#
# Input:
#   - lf : list (see detect-dirmod for format)
# Output:
#   - return value : 1 if ok, 0 if error
# 
# History 
#   2010/11/12 : pda/jean : design
#

proc sync-filemonitor {lf} {
    set sql {}
    foreach f $lf {
	lassign $f code path date
	set qpath [::pgsql::quote $path]
	switch $code {
	    add {
		set qdate [clock format $date]
		lappend sql "INSERT INTO topo.filemonitor (path, date)
					VALUES ('$qpath', '$qdate')"
	    }
	    mod {
		set qdate [clock format $date]
		lappend sql "UPDATE topo.filemonitor
					SET date = '$qdate'
					WHERE path = '$qpath'"
	    }
	    del {
		lappend sql "DELETE FROM topo.filemonitor
					WHERE path = '$qpath'"
	    }
	}
    }
    set r 1
    if {[llength $sql] > 0} then {
	set sql [join $sql ";"]
	set r [toposqlexec $sql]
    }

    return $r
}
