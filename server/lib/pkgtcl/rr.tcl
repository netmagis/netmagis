package require Tcl 8.6
package require json
package require pgdb

package provide rr 0.1

namespace eval ::rr {
    namespace export read-by-id read-by-name found

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

    foreach key {idrr name iddom domain idview mac
		    iddhcpprof dhcpprof
		    idhinfo hinfo
		    sendsmtp ttl
		    comment respname respmail
		    idcor date
		    ip
		    mx
		    mxtarg
		    cname
		    aliases
		    mboxhost mailaddr} {
	namespace export get-$key

	proc get-$key {rr} "return \[dict get \$rr $key]"
    }
}
