--
-- Trigger declarations for Netmagis
--

DROP TRIGGER IF EXISTS tr_mod_vlan ON topo.vlan ;
DROP TRIGGER IF EXISTS tr_mod_eq ON topo.eq ;
DROP TRIGGER IF EXISTS tr_mod_addr ON dns.addr ;
DROP TRIGGER IF EXISTS tr_mod_host ON dns.host ;
DROP TRIGGER IF EXISTS tr_mod_alias ON dns.alias ;
DROP TRIGGER IF EXISTS tr_mod_mx ON dns.mx ;
DROP TRIGGER IF EXISTS tr_mod_name ON dns.name ;
DROP TRIGGER IF EXISTS tr_mod_relay ON dns.relaydom ;
DROP TRIGGER IF EXISTS tr_mod_zone ON dns.zone_forward ;
DROP TRIGGER IF EXISTS tr_mod_zone4 ON dns.zone_reverse4 ;
DROP TRIGGER IF EXISTS tr_mod_zone6 ON dns.zone_reverse6 ;
DROP TRIGGER IF EXISTS tr_mod_dhcprange ON dns.dhcprange ;
DROP TRIGGER IF EXISTS tr_mod_network ON dns.network ;
DROP TRIGGER IF EXISTS tr_mod_dhcpprofile ON dns.dhcpprofile ;
DROP TRIGGER IF EXISTS tr_phonetic ON pgauth.user ;
DROP TRIGGER IF EXISTS tr_mod_vlan ON topo.vlan ;

CREATE TRIGGER tr_mod_vlan
    AFTER INSERT OR UPDATE OR DELETE ON topo.vlan
    FOR EACH ROW EXECUTE PROCEDURE topo.mod_vlan () ;

CREATE TRIGGER tr_mod_eq
    AFTER INSERT OR UPDATE OR DELETE ON topo.eq
    FOR EACH ROW EXECUTE PROCEDURE topo.mod_routerdb () ;

CREATE TRIGGER tr_mod_addr
    AFTER INSERT OR UPDATE OR DELETE ON dns.addr
    FOR EACH ROW EXECUTE PROCEDURE dns.mod_addr () ;

CREATE TRIGGER tr_mod_host
    AFTER INSERT OR UPDATE OR DELETE ON dns.host
    FOR EACH ROW EXECUTE PROCEDURE dns.mod_host () ;

CREATE TRIGGER tr_mod_alias
    AFTER INSERT OR UPDATE OR DELETE ON dns.alias
    FOR EACH ROW EXECUTE PROCEDURE dns.mod_mx_alias () ;

CREATE TRIGGER tr_mod_mx
    AFTER INSERT OR UPDATE OR DELETE ON dns.mx
    FOR EACH ROW EXECUTE PROCEDURE dns.mod_mx_alias () ;

CREATE TRIGGER tr_mod_name
    AFTER INSERT OR UPDATE OR DELETE ON dns.name
    FOR EACH ROW EXECUTE PROCEDURE dns.mod_name () ;

CREATE TRIGGER tr_mod_relay
    AFTER INSERT OR UPDATE OR DELETE ON dns.relaydom
    FOR EACH ROW EXECUTE PROCEDURE dns.mod_relay () ;

CREATE TRIGGER tr_mod_zone
    BEFORE UPDATE ON dns.zone_forward
    FOR EACH ROW EXECUTE PROCEDURE dns.mod_zone () ;

CREATE TRIGGER tr_mod_zone4
    BEFORE UPDATE ON dns.zone_reverse4
    FOR EACH ROW EXECUTE PROCEDURE dns.mod_zone () ;

CREATE TRIGGER tr_mod_zone6
    BEFORE UPDATE ON dns.zone_reverse6
    FOR EACH ROW EXECUTE PROCEDURE dns.mod_zone () ;

CREATE TRIGGER tr_mod_dhcprange
    BEFORE UPDATE ON dns.dhcprange
    FOR EACH ROW EXECUTE PROCEDURE dns.mod_dhcp () ;

CREATE TRIGGER tr_mod_network
    BEFORE UPDATE ON dns.network
    FOR EACH ROW EXECUTE PROCEDURE dns.mod_dhcp () ;

CREATE TRIGGER tr_mod_dhcpprofile
    BEFORE UPDATE ON dns.dhcpprofile
    FOR EACH ROW EXECUTE PROCEDURE dns.mod_dhcp () ;

CREATE TRIGGER tr_phonetic
    BEFORE INSERT OR UPDATE ON pgauth.user
    FOR EACH ROW EXECUTE PROCEDURE pgauth.add_soundex () ;
