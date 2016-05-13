CREATE OR REPLACE VIEW dns.fqdn
    AS (
	SELECT rr.idrr, rr.name || '.' || domain.name AS name, rr.idview
		FROM dns.rr
		INNER JOIN dns.domain USING (iddom)
    )
    ;

CREATE OR REPLACE FUNCTION global.mklink (prefix TEXT, idrr INT)
    RETURNS TEXT AS $$
	BEGIN
	    RETURN CASE
			WHEN idrr IS NULL THEN ''
			ELSE prefix || CAST (idrr AS TEXT)
		    END ;
	END
    $$ LANGUAGE plpgsql
    ;

CREATE OR REPLACE VIEW dns.full_rr_id AS
    SELECT
		r.idrr AS idrr,
	    r.name AS name,
		r.iddom AS iddom,
	    domain.name AS domain,
	    global.mklink ('/domains/', r.iddom) AS domainlink,
		r.idview AS idview,
	    view.name AS view,
	    global.mklink ('/views/', r.idview) AS viewlink,
	    COALESCE (CAST (r.mac AS text), '') AS mac,
		r.idhinfo AS idhinfo,
	    hinfo.name AS hinfo,
	    '/hinfos/' || CAST (r.idhinfo AS text) AS hinfolink,
	    COALESCE (r.comment, '') AS comment,
	    COALESCE (r.respname, '') AS respname,
	    COALESCE (r.respmail, '') AS respmail,
	    COALESCE (dhcpprofile.name, '') AS dhcpprofile,
	    global.mklink ('/dhcpprofiles/', r.iddhcpprof) AS dhcpprofilelink,
		r.iddhcpprof AS iddhcpprofile,
	    r.sendsmtp,
	    r.ttl,
	    nmuser.login AS user,
	    global.mklink ('/users/', r.idcor) AS userlink,
		r.idcor AS idcor,
	    r.date AS lastmod,
		COALESCE (f1.idrr, -1) AS idcname,
	    COALESCE (f1.name, '') AS cname,
	    global.mklink ('/names/', f1.idrr) AS cnamelink,
	    COALESCE (sreq_aliases.aliases, '{}') AS aliases,
		COALESCE (f2.idrr, -1) AS idmboxhost,
		COALESCE (f2.idview, -1) AS idmboxhostview,
	    COALESCE (f2.name, '') AS mboxhost,
	    global.mklink ('/names/', f2.idrr) AS mboxhostlink,
	    COALESCE (sreq_mailaddr.mailaddr, '{}') AS mailaddr,
	    COALESCE (sreq_mx.mx, '{}') AS mx,
	    COALESCE (sreq_mxtarg.mxtarg, '{}') AS mxtarg,
	    COALESCE (sreq_ip.ip, '{}') AS ip
	FROM dns.rr r
	    INNER JOIN dns.domain USING (iddom)
	    INNER JOIN dns.view USING (idview)
	    INNER JOIN dns.hinfo USING (idhinfo)
	    LEFT OUTER JOIN dns.dhcpprofile USING (iddhcpprof)
	    INNER JOIN global.nmuser USING (idcor)
	    LEFT OUTER JOIN dns.rr_cname USING (idrr)
	    LEFT OUTER JOIN dns.fqdn f1 ON rr_cname.cname = f1.idrr
	    LEFT OUTER JOIN dns.mail_role mr ON r.idrr = mr.mailaddr
	    LEFT OUTER JOIN dns.fqdn f2 ON mr.mboxhost = f2.idrr
	    , LATERAL (
		SELECT array_agg (addr) AS ip
		    FROM dns.rr_ip
		    WHERE rr_ip.idrr = r.idrr
		) AS sreq_ip
	    , LATERAL (
		SELECT array_agg (json_build_object (
				'idalias', fqdn.idrr,
			    'alias', fqdn.name,
			    'aliaslink', global.mklink ('/names/', fqdn.idrr)
			)) AS aliases
		    FROM dns.rr_cname
			INNER JOIN dns.fqdn USING (idrr)
		    WHERE rr_cname.cname = r.idrr
		) AS sreq_aliases
	    , LATERAL (
		SELECT array_agg (json_build_object (
				'idmailaddr', fqdn.idrr,
				'idmailaddrview', fqdn.idview,
			    'mailaddr', fqdn.name,
			    'mailaddrlink', global.mklink ('/names/', fqdn.idrr)
			)) AS mailaddr
		    FROM dns.mail_role
			INNER JOIN dns.fqdn ON fqdn.idrr = mail_role.mailaddr
		    WHERE mboxhost = r.idrr
		) AS sreq_mailaddr
	    , LATERAL (
		SELECT array_agg (json_build_object (
				'idmx', fqdn.idrr,
			    'prio', prio,
			    'mx', fqdn.name,
			    'mxlink', global.mklink ('/names/', fqdn.idrr)
			)) AS mx
		    FROM dns.rr_mx
			INNER JOIN dns.fqdn ON rr_mx.mx = fqdn.idrr
		    WHERE rr_mx.idrr = r.idrr
		) AS sreq_mx
	    , LATERAL (
		SELECT array_agg (json_build_object (
				'idmxtarg', fqdn.idrr,
			    'mxtarg', fqdn.name,
			    'mxtarglink', global.mklink ('/names/', fqdn.idrr)
			)) AS mxtarg
		    FROM dns.rr_mx
			INNER JOIN dns.fqdn ON rr_mx.idrr = fqdn.idrr
		    WHERE rr_mx.mx = r.idrr
		) AS sreq_mxtarg
	;

CREATE OR REPLACE VIEW dns.full_rr AS
    SELECT
	    r.idrr AS idrr,
	    r.name AS name,
	    domain.name AS domain,
	    global.mklink ('/domains/', r.iddom) AS domainlink,
	    view.name AS view,
	    global.mklink ('/views/', r.idview) AS viewlink,
	    COALESCE (CAST (r.mac AS text), '') AS mac,
	    hinfo.name AS hinfo,
	    '/hinfos/' || CAST (r.idhinfo AS text) AS hinfolink,
	    COALESCE (r.comment, '') AS comment,
	    COALESCE (r.respname, '') AS respname,
	    COALESCE (r.respmail, '') AS respmail,
	    COALESCE (dhcpprofile.name, '') AS dhcpprof,
	    global.mklink ('/dhcpprofiles/', r.iddhcpprof) AS dhcpproflink,
	    r.sendsmtp,
	    r.ttl,
	    nmuser.login AS user,
	    global.mklink ('/users/', r.idcor) AS userlink,
	    r.date AS lastmod,
	    COALESCE (f1.name, '') AS cname,
	    global.mklink ('/names/', f1.idrr) AS cnamelink,
	    COALESCE (sreq_aliases.aliases, '{}') AS aliases,
	    COALESCE (f2.name, '') AS mboxhost,
	    global.mklink ('/names/', f2.idrr) AS mboxhostlink,
	    COALESCE (sreq_mailaddr.mailaddr, '{}') AS mailaddr,
	    COALESCE (sreq_mx.mx, '{}') AS mx,
	    COALESCE (sreq_mxtarg.mxtarg, '{}') AS mxtarg,
	    COALESCE (sreq_ip.ip, '{}') AS ip
	FROM dns.rr r
	    INNER JOIN dns.domain USING (iddom)
	    INNER JOIN dns.view USING (idview)
	    INNER JOIN dns.hinfo USING (idhinfo)
	    LEFT OUTER JOIN dns.dhcpprofile USING (iddhcpprof)
	    INNER JOIN global.nmuser USING (idcor)
	    LEFT OUTER JOIN dns.rr_cname USING (idrr)
	    LEFT OUTER JOIN dns.fqdn f1 ON rr_cname.cname = f1.idrr
	    LEFT OUTER JOIN dns.mail_role mr ON r.idrr = mr.mailaddr
	    LEFT OUTER JOIN dns.fqdn f2 ON mr.mboxhost = f2.idrr
	    , LATERAL (
		SELECT array_agg (addr) AS ip
		    FROM dns.rr_ip
		    WHERE rr_ip.idrr = r.idrr
		) AS sreq_ip
	    , LATERAL (
		SELECT array_agg (json_build_object (
			    'alias', fqdn.name,
			    'aliaslink', global.mklink ('/names/', fqdn.idrr)
			)) AS aliases
		    FROM dns.rr_cname
			INNER JOIN dns.fqdn USING (idrr)
		    WHERE rr_cname.cname = r.idrr
		) AS sreq_aliases
	    , LATERAL (
		SELECT array_agg (json_build_object (
			    'mailaddr', fqdn.name,
			    'mailaddrlink', global.mklink ('/names/', fqdn.idrr)
			)) AS mailaddr
		    FROM dns.mail_role
			INNER JOIN dns.fqdn ON fqdn.idrr = mail_role.mailaddr
		    WHERE mboxhost = r.idrr
		) AS sreq_mailaddr
	    , LATERAL (
		SELECT array_agg (json_build_object (
			    'prio', prio,
			    'mx', fqdn.name,
			    'mxlink', global.mklink ('/names/', fqdn.idrr)
			)) AS mx
		    FROM dns.rr_mx
			INNER JOIN dns.fqdn ON rr_mx.mx = fqdn.idrr
		    WHERE rr_mx.idrr = r.idrr
		) AS sreq_mx
	    , LATERAL (
		SELECT array_agg (json_build_object (
			    'mxtarg', fqdn.name,
			    'mxtarglink', global.mklink ('/names/', fqdn.idrr)
			)) AS mxtarg
		    FROM dns.rr_mx
			INNER JOIN dns.fqdn ON rr_mx.idrr = fqdn.idrr
		    WHERE rr_mx.mx = r.idrr
		) AS sreq_mxtarg
	;

-- SELECT row_to_json (r.*, 't') AS j
--     FROM dns.full_rr_id r
--     WHERE r.name = 'mailhost'
--     ;

