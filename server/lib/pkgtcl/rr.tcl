package require Tcl 8.6
package require json
package require pgdb

package provide rr 0.1

#
# This package provides an interface to read RR from database and
# access various attributes.
#
# Functions:
# - read-by-id $db $idrr
#	return a RR object, which may be empty
# - read-by-name $db $name $iddom $idview
#	return a RR object, which may be empty
# - found $rr
#	return 1 if the RR has been found, 0 if is has not been found
# - get-idrr $rr
#	return the idrr
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
# - get-mac $rr
#	return the MAC address or an empty string
# - get-iddhcpprof $rr
#	return the DHCP profile id, or 0 if none
# - get-dhcpprof $rr
#	return the DHCP profile name, or an empty string
#			(XXX WARNING OLD code was returing "No profile")
# - get-idhinfo $rr
#	return the idhinfo
# - get-hinfo $rr
#	return the hinfo text
# - get-sendsmtp $rr
#	return 1 if host has the right to emit with non auth SMTP, or 0
# - get-ttl $rr
#	return the ttl (0...n) for all its IP addresses
# - get-comment $rr
#	return the comment
# - get-respname $rr
#	return the name of the responsible person
# - get-respmail $rr
#	return the mail address of the responsible person
# - get-idcor $rr
#       return the id of user who has done the last modification
# - get-date $rr
#       return the date of last modification (SQL timestamp format)
# - get-ip $rr
#	return the list of all IP addresses {addr addr...}
#			(XXX OLD {{idview addr} ...})
# - get-mx $rr
#	return the list of target MX for this name {{prio idrr} {prio idrr}...}
#			(XXX OLD {{idview prio idrr} {idview prio idrr} ...})
# - get-mxtarg $rr
#	return the list of MX which target this host {idrr idrr...}
# - get-cname $rr
#	return the idrr of the referenced host if $rr is an alias
# - get-aliases $rr
#	return the list of idrr for aliases to this host
# - get-mboxhost $rr
#	return the idrr of the mailbox host for this mail address
# - get-mailaddr $rr
#	return the list of idrr of mail addresses if $rr is a mbox host
#			(XXX OLD {{idview idmailaddr idviewmailaddr} ...})
#

namespace eval ::rr {
    namespace export read-by-id read-by-name \
		    found \
		    get-mx get-fqdn

    proc read-by-name {db name iddom idview} {
	set qname [pg_quote $name]
	set where "rr.name = $qname
			AND rr.iddom = $iddom
			AND rr.idview = $idview"
	return [Read-where $db $where]
    }

    proc read-by-id {db idrr} {
	set where "rr.idrr = $idrr"
	return [Read-where $db $where]
    }

    proc Read-where {db where} {
	set found 0
	set sql "SELECT row_to_json (j) FROM (
		    SELECT rr.idrr, rr.name AS name,
			    rr.iddom AS iddom, domain.name AS domain,
			    rr.idview AS idview,
			    COALESCE (CAST (rr.mac AS text), '') AS mac,
			    COALESCE (rr.iddhcpprof, 0) AS iddhcpprof,
			    COALESCE (dhcpprofile.name, '') AS dhcpprof,
			    rr.idhinfo, hinfo.name AS hinfo,
			    rr.sendsmtp, rr.ttl,
			    rr.comment, rr.respname, rr.respmail,
			    rr.idcor, rr.date,
			    COALESCE (sreq_ip.ip, '{}') AS ip,
			    COALESCE (sreq_mx.mx, '{}') AS mx,
			    COALESCE (sreq_mxtarg.mxtarg, '{}') AS mxtarg,
			    COALESCE (CAST (cn.cname AS text), '') AS cname,
			    COALESCE (sreq_aliases.aliases, '{}') AS aliases,
			    COALESCE (CAST (mail_role.mboxhost AS text), '')
				    AS mboxhost,
			    COALESCE (sreq_mailaddr.mailaddr, '{}') AS mailaddr
			FROM dns.rr
			    INNER JOIN dns.domain USING (iddom)
			    INNER JOIN dns.hinfo USING (idhinfo)
			    LEFT OUTER JOIN dns.dhcpprofile USING (iddhcpprof)
			    LEFT OUTER JOIN dns.rr_cname cn USING (idrr)
			    LEFT OUTER JOIN dns.mail_role ON (mailaddr = idrr)
			    , LATERAL (
				    SELECT array_agg (addr) AS ip
					FROM dns.rr_ip
					WHERE rr_ip.idrr = rr.idrr
				) AS sreq_ip
			    , LATERAL (
				    SELECT array_agg (json_build_object (
							'idmx', rr_mx.mx,
							'prio', rr_mx.prio
					    )) AS mx
					FROM dns.rr_mx
					WHERE rr_mx.idrr = rr.idrr
				) AS sreq_mx
			    , LATERAL (
				SELECT array_agg (rr_mx.idrr) AS mxtarg
				    FROM dns.rr_mx
				    WHERE rr_mx.mx = rr.idrr
				) AS sreq_mxtarg
			    , LATERAL (
				    SELECT array_agg (rr_cname.idrr) AS aliases
					FROM dns.rr_cname
					WHERE rr_cname.cname = rr.idrr
				    ) AS sreq_aliases
			    , LATERAL (
				    SELECT array_agg (mailaddr) AS mailaddr
					FROM dns.mail_role
					WHERE mail_role.mboxhost = rr.idrr
				    ) AS sreq_mailaddr
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

    # Define all getters, except mx
    foreach key {idrr name iddom domain idview mac
		    iddhcpprof dhcpprof
		    idhinfo hinfo
		    sendsmtp ttl
		    comment respname respmail
		    idcor date
		    ip
		    mxtarg
		    cname
		    aliases
		    mboxhost mailaddr} {
	namespace export get-$key

	proc get-$key {rr} "return \[dict get \$rr $key]"
    }

    proc get-mx {rr} {
	set r {}
	foreach j [dict get $rr "mx"] {
	    lappend r [list [dict get $j "prio"] [dict get $j "idmx"]]
	}
	return $r
    }

    proc get-fqdn {rr} {
	set name [dict get $rr "name"]
	set domain [dict get $rr "domain"]
	return "$name.$domain"
    }
}
