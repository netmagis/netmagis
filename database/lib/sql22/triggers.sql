--
-- Trigger declarations for Netmagis 2.2.x
--

CREATE TRIGGER tr_mod_vlan
    AFTER INSERT OR UPDATE OR DELETE ON topo.vlan
    FOR EACH ROW EXECUTE PROCEDURE topo.mod_vlan () ;

CREATE TRIGGER tr_mod_eq
    AFTER INSERT OR UPDATE OR DELETE ON topo.eq
    FOR EACH ROW EXECUTE PROCEDURE topo.mod_routerdb () ;

CREATE TRIGGER tr_mod_ip
    AFTER INSERT OR UPDATE OR DELETE ON dns.rr_ip
    FOR EACH ROW EXECUTE PROCEDURE dns.mod_ip () ;

CREATE TRIGGER tr_mod_cname
    AFTER INSERT OR UPDATE OR DELETE ON dns.rr_cname
    FOR EACH ROW EXECUTE PROCEDURE dns.mod_mxcname () ;

CREATE TRIGGER tr_mod_mx
    AFTER INSERT OR UPDATE OR DELETE ON dns.rr_mx
    FOR EACH ROW EXECUTE PROCEDURE dns.mod_mxcname () ;

CREATE TRIGGER tr_mod_rr
    AFTER INSERT OR UPDATE OR DELETE ON dns.rr
    FOR EACH ROW EXECUTE PROCEDURE dns.mod_rr () ;

CREATE TRIGGER tr_mod_relay
    AFTER INSERT OR UPDATE OR DELETE ON dns.relais_dom
    FOR EACH ROW EXECUTE PROCEDURE dns.mod_relay () ;

CREATE TRIGGER tr_mod_zone
    BEFORE UPDATE ON dns.zone_normale
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

CREATE TRIGGER tr_mod_dhcpprofil
    BEFORE UPDATE ON dns.dhcpprofil
    FOR EACH ROW EXECUTE PROCEDURE dns.mod_dhcp () ;

CREATE TRIGGER tr_phnom
    BEFORE INSERT OR UPDATE ON pgauth.user
    FOR EACH ROW EXECUTE PROCEDURE pgauth.add_soundex () ;
