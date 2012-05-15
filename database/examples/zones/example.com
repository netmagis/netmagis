;
; Zone example.com
;
;
; History
;   2004/04/13 : pda : design example zone
;

@	IN	SOA	ns1.example.com. hostmaster.example.com. (
		    2012042601		; serial
		    86400		; refresh = 1 day
		    3600		; retry = 1 h
		    3600000		; expire = 1000 hours (~ 41 day)
		    86400		; default ttl = 1 day
		)

;
; Default TLL for zone records
;
$TTL	86400

;
; Authoritative servers for this zone
;

			IN	NS	ns1.example.com.
			IN	NS	ns2.example.com.
			IN	NS	ns.myisp.com.

;
; Default MX for the domain itself
;

			IN	MX	10 mx1.example.com.
			IN	MX	20 mx2.example.com.

;
; hack
;

localhost		IN	A	127.0.0.1

; this plant delegates sub-zone management to us
plant1			IN	NS	ns1.example.com.
			IN	NS	ns2.example.com.

; this plant manages its own sub-zone
plant2			IN	NS	elsewhere.plant2.example.com.
			IN	NS	ns1.example.com.
			IN	NS	ns2.example.com.
elsewhere.plant2	IN	A	172.16.100.1

; CUT HERE -------------------------------------------------------------

; backbone
ns1			IN	A	172.16.1.1
			IN	AAAA	2001:db8:1234::1
ns2			IN	A	172.16.1.2
			IN	AAAA	2001:db8:1234::2
mx1			IN	A	172.16.1.3
			IN	AAAA	2001:db8:1234::3
mx2			IN	A	172.16.1.4
			IN	AAAA	2001:db8:1234::4

; switches
sw1			IN	A	192.16.1.101
sw2			IN	A	192.16.1.102

rtr			IN	A	172.16.1.254
			IN	AAAA	2001:db8:1234:4001::1/64
another-router		IN	A	172.16.1.253
			IN	AAAA	2001:db8:1234:4001::2/64

; router has address in some blocks
rtr			IN	A	192.168.1.254

; Marketing office
zeus			IN	A	172.16.11.1
jupiter			IN	CNAME	zeus
venus			IN	A	172.16.11.2
aphrodite		IN	A	172.16.11.3
rtr			IN	A	172.16.11.254
			IN	AAAA	2001:db8:1234:4011::1/64

; ITS
droopy			IN	A	172.16.12.1
www-dog			IN	CNAME	droopy
pluto			IN	A	172.16.12.2
dingo			IN	A	172.16.12.3
rtr			IN	A	172.16.12.254

; R&D
daffy			IN	A	172.16.13.1
www-tex			IN	CNAME	daffy
bugs			IN	A	172.16.13.2
screwy			IN	A	172.16.13.3
porky			IN	A	172.16.13.4
another-router		IN	A	172.16.13.254

; Plant2 (over 512 addresses)
bot1			IN	A	172.16.14.1
bot2			IN	A	172.16.14.2
quality			IN	A	172.16.14.3
management		IN	A	172.16.14.4
monitor			IN	A	172.16.14.5
another-router		IN	A	172.16.15.254
