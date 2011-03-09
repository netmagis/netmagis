;
; Zone labo2.univ-machin.fr
;
;
; History
;   2004/04/13 : pda : design example zone
;

@	IN	SOA	ns1.univ-machin.fr. hostmaster.univ-machin.fr. (
		    2004041301		; serial
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

			IN	NS	ns1.univ-machin.fr.
			IN	NS	ns2.univ-machin.fr.
			IN	NS	shiva.univ-bidule.fr.

;
; Default MX for the domain itself
;

			IN	MX	10 relais.univ-machin.fr.

;
; hack
;

localhost		IN	A	127.0.0.1

; CUT HERE -------------------------------------------------------------

asterix			IN	A	172.16.20.1
www			IN	CNAME	asterix
obelix			IN	A	172.16.20.2
abraracourcix		IN	A	172.16.20.3
assurancetourix		IN	A	172.16.20.4
