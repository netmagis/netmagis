;
; Zone univ-machin.fr
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

			IN	MX	10 relais1.univ-machin.fr.
			IN	MX	20 relais2.univ-machin.fr.

;
; hack
;

localhost		IN	A	127.0.0.1

; this lab manages its own sub-zone
labo1			IN	NS	ailleurs.labo1.univ-machin.fr.
			IN	NS	ns1.univ-machin.fr.
			IN	NS	ns2.univ-machin.fr.
ailleurs.labo1		IN	A	172.16.100.1

; this lab delegates sub-zone management to us
labo2			IN	NS	ns1.univ-machin.fr.
			IN	NS	ns2.univ-machin.fr.

; CUT HERE -------------------------------------------------------------

; backbone
ns1			IN	A	172.16.1.1
			IN	AAAA	2001:660:1234::1
ns2			IN	A	172.16.1.2
			IN	AAAA	2001:660:1234::2
relais1			IN	A	172.16.1.3
			IN	AAAA	2001:660:1234::3
relais2			IN	A	172.16.1.4
			IN	AAAA	2001:660:1234::4
r-campus2		IN	A	172.16.1.253
			IN	AAAA	2001:660:1234:0:fffe::0
r-campus1		IN	A	172.16.1.254
			IN	AAAA	2001:660:1234:0:ffff::0

; r-campus1 also has addresses in ESIATF and labo2 networks
r-campus1		IN	A	192.168.1.254
			IN	A	172.16.20.254

; LMA : Laboratoire de mythologie antique
zeus			IN	A	172.16.11.1
jupiter			IN	CNAME	zeus
apollon			IN	A	172.16.11.2
aphrodite		IN	A	172.16.11.3
r-campus1		IN	A	172.16.11.254

; LEC : Laboratoire d'étude des canidés
droopy			IN	A	172.16.12.1
www-chien		IN	CNAME	droopy
pluto			IN	A	172.16.12.2
dingo			IN	A	172.16.12.3
r-campus1		IN	A	172.16.12.254

; LGA : Laboratoire du Génie des Alpages
athanase		IN	A	172.16.13.1
www-genie		IN	CNAME	athanase
trouillette		IN	A	172.16.13.2
cassolette		IN	A	172.16.13.3
boitalette		IN	A	172.16.13.4
r-campus2		IN	A	172.16.13.254

; Central services (over 512 addresses)
contentieux		IN	A	172.16.14.1
marches			IN	A	172.16.14.2
controle-de-gestion	IN	A	172.16.14.3
drh			IN	A	172.16.14.4
affaires-juridiques	IN	A	172.16.14.5
r-campus1		IN	A	172.16.15.254
