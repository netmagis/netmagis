CREATE SCHEMA mac ;

-- Generic session table which will be used to associate some
-- data (ip-mac, port-mac-vlan) with a start and a stop date
CREATE TABLE mac.session (
    start	TIMESTAMP,  		-- session start
    stop	TIMESTAMP,  		-- session stop
    src		INET,			-- origin of the information
    closed	BOOLEAN			-- 1 if session timed out
) ;

-- Postgresql composite type to instantiate a generic session
-- as an IP-MAC session
CREATE TYPE mac.ipmac_t AS (
    ip		INET,			-- IP address
    mac		MACADDR			-- MAC address
);

-- IP-MAC session instance
CREATE TABLE mac.ipmac (
    data	mac.ipmac_t
) INHERITS (mac.session) ;

CREATE INDEX ON mac.ipmac (src);
CREATE INDEX ON mac.ipmac (data);
CREATE INDEX ON mac.ipmac (closed);
CREATE INDEX ON mac.ipmac (stop);
CREATE INDEX ON mac.ipmac (start);
CREATE INDEX ON mac.ipmac ( ((data).ip) );
CREATE INDEX ON mac.ipmac ( ((data).mac) );

CREATE TYPE mac.portmac_t AS (
    mac		MACADDR,		-- MAC address
    port	TEXT,			-- port name
    vlanid	INTEGER			-- VLAN id
) ;

CREATE TABLE mac.portmac (
    data	mac.portmac_t
) INHERITS (mac.session) ;

CREATE INDEX ON mac.portmac (src);
CREATE INDEX ON mac.portmac (data);
CREATE INDEX ON mac.portmac (closed);
CREATE INDEX ON mac.portmac (stop);
CREATE INDEX ON mac.portmac (start);
CREATE INDEX ON mac.portmac ( ((data).mac) );
CREATE INDEX ON mac.portmac ( ((data).port) );
CREATE INDEX ON mac.portmac ( ((data).vlanid) );
