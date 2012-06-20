;
; Zone plant1.example.com
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

; CUT HERE -------------------------------------------------------------

asterix			IN	A	172.16.14.1
www			IN	CNAME	asterix
obelix			IN	A	172.16.14.2
abraracourcix		IN	A	172.16.14.3
assurancetourix		IN	A	172.16.14.4
