-- CREATE VIEW dns.fqdn
--     AS (
-- 	SELECT rr.idrr, rr.name || '.' || domain.name AS name
-- 		FROM dns.rr
-- 		INNER JOIN dns.domain USING (iddom)
--     )
--     ;
-- 
-- CREATE FUNCTION dns.res_link (prefix TEXT, idrr INT)
--     RETURNS TEXT AS $$
-- 	BEGIN
-- 	    RETURN CASE
-- 			WHEN idrr IS NULL THEN ''
-- 			ELSE prefix || CAST (idrr AS TEXT)
-- 		    END ;
-- 	END
--     $$ LANGUAGE plpgsql
--     ;

SELECT row_to_json (x, 't') AS j
    FROM (
	SELECT r.name AS name,
		domain.name AS domain,
		'/domains/' || CAST (r.iddom AS text) AS domainlink,
		view.name AS view,
		'/views/' || CAST (r.idview AS text) AS viewlink,
		COALESCE (CAST (r.mac AS text), '') AS mac,
		hinfo.name AS hinfo,
		'/hinfos/' || CAST (r.idhinfo AS text) AS hinfolink,
		COALESCE (r.comment, '') AS comment,
		COALESCE (r.respname, '') AS respname,
		COALESCE (r.respmail, '') AS respmail,
		COALESCE (dhcpprofile.name, '') AS dhcpprofile,
		dns.res_link ('/dhcpprofiles/', r.iddhcpprof) AS dhcpprofilelink,
		r.sendsmtp,
		r.ttl,
		nmuser.login AS user,
		dns.res_link ('/users', r.idcor) AS userlink,
		r.date AS lastmod,
		COALESCE (f1.name, '') AS cname,
		dns.res_link ('/names', f1.idrr) AS cnamelink,
		COALESCE (sreq_aliases.aliases, '{}') AS aliases,
		COALESCE (f2.name, '') AS mboxhost,
		dns.res_link ('/names', f2.idrr) AS mboxhostlink,
		COALESCE (sreq_mailaddr.mailaddr, '{}') AS mailaddr,
		COALESCE (sreq_mx.mx, '{}') AS mx,
		COALESCE (sreq_mxtarg.mxtarg, '{}') AS mxtarg,
		COALESCE (sreq_addr.addr, '{}') AS addr
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
		,
		LATERAL (
		    SELECT array_agg (addr) AS addr
			FROM dns.rr_ip
			WHERE rr_ip.idrr = r.idrr
		    ) AS sreq_addr
		,
		LATERAL (
		    SELECT array_agg (json_build_object (
				'alias', fqdn.name,
				'aliaslink', dns.res_link ('/names/', fqdn.idrr)
			    )) AS aliases
			FROM dns.rr_cname
			    INNER JOIN dns.fqdn USING (idrr)
			WHERE rr_cname.cname = r.idrr
		    ) AS sreq_aliases
		,
		LATERAL (
		    SELECT array_agg (json_build_object (
				'mailaddr', fqdn.name,
				'mailaddrlink',
				    dns.res_link ('/names/', fqdn.idrr)
			    )) AS mailaddr
			FROM dns.mail_role
			    INNER JOIN dns.fqdn ON fqdn.idrr = mail_role.mailaddr
			WHERE mboxhost = r.idrr
		    ) AS sreq_mailaddr
		,
		LATERAL (
		    SELECT array_agg (json_build_object (
				'prio', prio,
				'mx', fqdn.name,
				'mxlink', dns.res_link ('/names/', fqdn.idrr)
			    )) AS mx
			FROM dns.rr_mx
			    INNER JOIN dns.fqdn ON rr_mx.mx = fqdn.idrr
			WHERE rr_mx.idrr = r.idrr
		    ) AS sreq_mx
		,
		LATERAL (
		    SELECT array_agg (json_build_object (
				'mxtarg', fqdn.name,
				'mxtarglink', dns.res_link ('/names/', fqdn.idrr)
			    )) AS mxtarg
			FROM dns.rr_mx
			    INNER JOIN dns.fqdn ON rr_mx.idrr = fqdn.idrr
			WHERE rr_mx.mx = r.idrr
		    ) AS sreq_mxtarg
	    where r.name = 'mailhost'
	) AS x
    ;


