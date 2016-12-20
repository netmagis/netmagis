package require Tcl 8.6
package require json
package require json::write
package require pgdb

package provide rr 0.1

#
# This package provides an interface to read RR from database and
# access various attributes.
#
# Functions:
# - read-by-idname $db $idname
#	return a RR object, which may be empty
# - read-by-idhost $db $idhost
#	return a RR object, which may be empty
# - read-by-name $db $name $iddom $idview
#	return a RR object, which may be empty
# - found $rr
#	return 1 if the RR has been found, 0 if is has not been found
# - not-a-rr
#	return an invalid rr (one which has not been found)
# - get-idname $rr
#	return the id of the name
# - get-name $rr
#	return the RR name (without domain)
# - get-iddom $rr
#	return the domain id
# - get-domain $rr
#	return the domain name
# - get-fqdn $rr
#	return the FQDN of the RR
# - get-idview $rr
#	return the view id
# - get-idhost $rr
#	return the idhost of the host, or -1 if the name is not a host
# - get-mac $rr
#	return the MAC address of the host or an empty string
# - get-iddhcpprof $rr
#	return the DHCP profile id of the host, or 0 if none
# - get-dhcpprof $rr
#	return the DHCP profile name of the host, or an empty string
# - get-idhinfo $rr
#	return the idhinfo of the host
# - get-hinfo $rr
#	return the hinfo text of the host
# - get-sendsmtp $rr
#	return 1 if host has the right to emit with non auth SMTP, or 0
# - get-ttlhost $rr
#	return the ttl (0...n) of the host for all its IP addresses
# - get-comment $rr
#	return the comment
# - get-respname $rr
#	return the name of the responsible person for the host
# - get-respmail $rr
#	return the mail address of the responsible person for the host
# - get-addr $rr
#	return the list of all IP addresses {addr addr...} of the host
# - get-mxhost $rr
#	return the list of MX target hosts for this name under the format
#	{{prio idrr ttl} {prio idrr ttl}...}
# - get-mxname $rr
#	return the list of MX names which target this host {idrr idrr...}
# - get-cname $rr
#	return the idhost of the target host if $rr is an alias, or -1
# - get-ttlcname $rr
#	return the TTL associated to the alias or -1
# - get-aliases $rr
#	return the list of names which are aliases of this host
# - get-mboxhost $rr
#	return the idhost of mailbox host for this mail address or -1
# - get-mailaddr $rr
#	return the list of idname of mail addresses if $rr is a mboxhost
# - get-relay $rr
#	return the list of iddom which target this host for relay {iddom ...}
# - add-name $db $name $iddom $idview
#	add the name into the database and return the new idname
# - add-host $db $idname $mac $iddhcpprof $idhinfo $comment $respname $respmail $sendsmtp $ttl
#	add the host into the database and return the new idhost
# - json-host $rr
#	return a host representation in JSON format
#

namespace eval ::rr {
    namespace export read-by-id read-by-name \
		    found not-a-rr \
		    get-mx get-fqdn \
		    add-name add-host \
		    json-host

    proc read-by-name {db name iddom idview} {
	set qname [pg_quote $name]
	set where "n.name = $qname
			AND n.iddom = $iddom
			AND n.idview = $idview"
	return [Read-where $db $where]
    }

    proc read-by-idname {db idname} {
	set where "n.idname = $idname"
	return [Read-where $db $where]
    }

    proc read-by-idhost {db idhost} {
	set where "h.idhost = $idhost"
	return [Read-where $db $where]
    }

    proc Read-where {db where} {
	set found 0
	set sql "SELECT row_to_json (j) FROM (
	    SELECT n.idname, n.name AS name,
		    n.iddom AS iddom, domain.name AS domain,
		    n.idview AS idview,
		    COALESCE (h.idhost, -1) AS idhost,
		    COALESCE (CAST (h.mac AS text), '') AS mac,
		    COALESCE (h.iddhcpprof, 0) AS iddhcpprof,
		    COALESCE (dhcpprofile.name, '') AS dhcpprof,
		    h.idhinfo, hinfo.name AS hinfo,
		    h.sendsmtp, h.ttl AS ttlhost,
		    h.comment, h.respname, h.respmail,
		    COALESCE (sreq_addr.addr, '{}') AS addr,
		    COALESCE (sreq_mxhost.mxhost, '{}') AS mxhost,
		    COALESCE (sreq_mxname.mxname, '{}') AS mxname,
		    COALESCE (a.idhost, -1) AS cname,
		    COALESCE (a.ttl, -1) AS ttlcname,
		    COALESCE (sreq_aliases.aliases, '{}') AS aliases,
		    COALESCE (mailrole.idhost, -1) AS mboxhost,
		    COALESCE (mailrole.ttl) AS ttlmboxhost,
		    COALESCE (sreq_mailaddr.mailaddr, '{}') AS mailaddr,
		    COALESCE (sreq_relay.relay, '{}') AS relay
		FROM dns.name n
		    INNER JOIN dns.domain USING (iddom)
		    LEFT OUTER JOIN dns.host h USING (idname)
		    LEFT OUTER JOIN dns.hinfo USING (idhinfo)
		    LEFT OUTER JOIN dns.dhcpprofile USING (iddhcpprof)
		    LEFT OUTER JOIN dns.alias a USING (idname)
		    LEFT OUTER JOIN dns.mailrole USING (idname)
		    , LATERAL (
			    SELECT array_agg (addr) AS addr
				FROM dns.addr
				WHERE addr.idhost = h.idhost
			) AS sreq_addr
		    , LATERAL (
			    SELECT array_agg (json_build_object (
						'idhost', mx.idhost,
						'prio', mx.prio,
						'ttl', mx.ttl
				    )) AS mxhost
				FROM dns.mx
				WHERE mx.idname = n.idname
			) AS sreq_mxhost
		    , LATERAL (
			SELECT array_agg (mx.idname) AS mxname
			    FROM dns.mx
			    WHERE mx.idhost = h.idhost
			) AS sreq_mxname
		    , LATERAL (
			    SELECT array_agg (alias.idname) AS aliases
				FROM dns.alias
				WHERE alias.idhost = h.idhost
			    ) AS sreq_aliases
		    , LATERAL (
			    SELECT array_agg (idname) AS mailaddr
				FROM dns.mailrole
				WHERE mailrole.idhost = h.idhost
			    ) AS sreq_mailaddr
		    , LATERAL (
			    SELECT array_agg (iddom) AS relay
				FROM dns.relaydom
				WHERE relaydom.idhost = h.idhost
			    ) AS sreq_relay
		WHERE $where
	    ) AS j
	"

	set rr [dict create]
	$db exec $sql tab {
	    set rr [::json::json2dict $tab(row_to_json)]
	}

	return $rr
    }

    proc found {rr} {
	return [expr [dict size $rr] > 0]
    }

    proc not-a-rr {} {
	return [dict create]
    }

    # Define all getters, except mx
    foreach key {idname name iddom domain idview
		    idhost mac iddhcpprof dhcpprof idhinfo hinfo
		    sendsmtp ttlhost
		    comment respname respmail
		    addr
		    mxname
		    cname ttlcname
		    aliases
		    mboxhost mailaddr
		    relay} {
	namespace export get-$key

	proc get-$key {rr} "return \[dict get \$rr $key]"
    }

    proc get-mxhost {rr} {
	set r {}
	foreach j [dict get $rr "mxhost"] {
	    lappend r [list [dict get $j "prio"] \
			    [dict get $j "idhost"] \
			    [dict get $j "ttl"] \
			    ]
	}
	return $r
    }

    proc get-fqdn {rr} {
	set name [dict get $rr "name"]
	set domain [dict get $rr "domain"]
	return "$name.$domain"
    }

    proc add-name {db name iddom idview} {
	set qname [pg_quote $name]
	set sql "INSERT INTO dns.name (name, iddom, idview)
		    VALUES ($qname, $iddom, $idview)
		    RETURNING idname"
	set idname -1
	$db exec $sql tab {
	    set idname $tab(idname)
	}
	return $idname
    }

    proc add-host {db idname mac iddhcpprof idhinfo comment respname respmail sendsmtp ttl} {
	set qmac NULL
	if {$mac ne ""} then {
	    set qmac [pg_quote $mac]
	}
	set qcomment  [pg_quote $comment]
	set qrespname [pg_quote $respname]
	set qrespmail [pg_quote $respmail]
	set qiddhcpprof NULL
	if {$iddhcpprof != -1} then {
	    set qiddhcpprof $iddhcpprof
	}

	set sql "INSERT INTO dns.host (idname, mac, iddhcpprof, idhinfo,
			    comment, respname, respmail, sendsmtp, ttl)
		    VALUES ($idname, $qmac, $qiddhcpprof, $idhinfo,
			    $qcomment, $qrespname, $qrespmail, $sendsmtp, $ttl)
		    RETURNING idhost"
	set idhost -1
	$db exec $sql tab {
	    set idhost $tab(idhost)
	}
	return $idhost
    }

    proc json-host {rr} {
	set l {}
	foreach a [dict get $rr "addr"] {
	    lappend l [::json::write string $a]
	}

	set j [::json::write object \
		    name [::json::write string [dict get $rr "name"]] \
		    iddom [dict get $rr "iddom"] \
		    idview [dict get $rr "idview"] \
		    mac [::json::write string [dict get $rr "mac"]] \
		    idhinfo [dict get $rr "idhinfo"] \
		    comment [::json::write string [dict get $rr "comment"]] \
		    respname [::json::write string [dict get $rr "respname"]] \
		    respmail [::json::write string [dict get $rr "respmail"]] \
		    iddhcpprof [dict get $rr "iddhcpprof"] \
		    sendsmtp [dict get $rr "sendsmtp"] \
		    ttl [dict get $rr "ttlhost"] \
		    addr [eval ::json::write array $l] \
		]
	return $j
    }

}
