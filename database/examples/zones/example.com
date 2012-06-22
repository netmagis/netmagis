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
			IN	AAAA	2001:db8:1234:4001::1
another-router		IN	A	172.16.1.253
			IN	AAAA	2001:db8:1234:4001::2

; router has address in some blocks
rtr			IN	A	192.168.1.254

; Marketing office
zeus			IN	A	172.16.11.1
jupiter			IN	CNAME	zeus
venus			IN	A	172.16.11.2
aphrodite		IN	A	172.16.11.3
; blocks of addresses (with holes) to demonstrate Netmagis IP address map
host10			IN	A	172.16.11.10
host11			IN	A	172.16.11.11
host12			IN	A	172.16.11.12
host13			IN	A	172.16.11.13
host14			IN	A	172.16.11.14
host15			IN	A	172.16.11.15
host16			IN	A	172.16.11.16
;host17			IN	A	172.16.11.17
;host18			IN	A	172.16.11.18
host19			IN	A	172.16.11.19
host20			IN	A	172.16.11.20
host21			IN	A	172.16.11.21
host22			IN	A	172.16.11.22
host23			IN	A	172.16.11.23
host24			IN	A	172.16.11.24
host25			IN	A	172.16.11.25
host26			IN	A	172.16.11.26
host27			IN	A	172.16.11.27
host28			IN	A	172.16.11.28
host29			IN	A	172.16.11.29
host30			IN	A	172.16.11.30
;host31			IN	A	172.16.11.31
;host32			IN	A	172.16.11.32
;host33			IN	A	172.16.11.33
;host34			IN	A	172.16.11.34
;host35			IN	A	172.16.11.35
host36			IN	A	172.16.11.36
host37			IN	A	172.16.11.37
host38			IN	A	172.16.11.38
host39			IN	A	172.16.11.39
host40			IN	A	172.16.11.40
host41			IN	A	172.16.11.41
host42			IN	A	172.16.11.42
host43			IN	A	172.16.11.43
host44			IN	A	172.16.11.44
host45			IN	A	172.16.11.45
host46			IN	A	172.16.11.46
host47			IN	A	172.16.11.47
host48			IN	A	172.16.11.48
host49			IN	A	172.16.11.49
host50			IN	A	172.16.11.50
host51			IN	A	172.16.11.51
;host52			IN	A	172.16.11.52
host53			IN	A	172.16.11.53
host54			IN	A	172.16.11.54
host55			IN	A	172.16.11.55
host56			IN	A	172.16.11.56
host57			IN	A	172.16.11.57
host58			IN	A	172.16.11.58
host59			IN	A	172.16.11.59
host60			IN	A	172.16.11.60
host61			IN	A	172.16.11.61
host62			IN	A	172.16.11.62
host63			IN	A	172.16.11.63
;host64			IN	A	172.16.11.64
;host65			IN	A	172.16.11.65
host66			IN	A	172.16.11.66
host67			IN	A	172.16.11.67
host68			IN	A	172.16.11.68
host69			IN	A	172.16.11.69
host70			IN	A	172.16.11.70
host71			IN	A	172.16.11.71
host72			IN	A	172.16.11.72
host73			IN	A	172.16.11.73
host74			IN	A	172.16.11.74
host75			IN	A	172.16.11.75
host76			IN	A	172.16.11.76
host77			IN	A	172.16.11.77
host78			IN	A	172.16.11.78
host79			IN	A	172.16.11.79
host80			IN	A	172.16.11.80
host81			IN	A	172.16.11.81
host82			IN	A	172.16.11.82
host83			IN	A	172.16.11.83
host84			IN	A	172.16.11.84
;host85			IN	A	172.16.11.85
;host86			IN	A	172.16.11.86
;host87			IN	A	172.16.11.87
;host88			IN	A	172.16.11.88
host89			IN	A	172.16.11.89
host90			IN	A	172.16.11.90
host91			IN	A	172.16.11.91
host92			IN	A	172.16.11.92
host93			IN	A	172.16.11.93
host94			IN	A	172.16.11.94
host95			IN	A	172.16.11.95
host96			IN	A	172.16.11.96
host97			IN	A	172.16.11.97
host98			IN	A	172.16.11.98
host99			IN	A	172.16.11.99
host100			IN	A	172.16.11.100
host101			IN	A	172.16.11.101
host102			IN	A	172.16.11.102
host103			IN	A	172.16.11.103
host104			IN	A	172.16.11.104
host105			IN	A	172.16.11.105
host106			IN	A	172.16.11.106
host107			IN	A	172.16.11.107
host108			IN	A	172.16.11.108
host109			IN	A	172.16.11.109
;host110		IN	A	172.16.11.110
;host111		IN	A	172.16.11.111
;host112		IN	A	172.16.11.112
;host113		IN	A	172.16.11.113
;host114		IN	A	172.16.11.114
host115			IN	A	172.16.11.115
host116			IN	A	172.16.11.116
host117			IN	A	172.16.11.117
host118			IN	A	172.16.11.118
host119			IN	A	172.16.11.119
host120			IN	A	172.16.11.120
host121			IN	A	172.16.11.121
host122			IN	A	172.16.11.122
host123			IN	A	172.16.11.123
host124			IN	A	172.16.11.124
host125			IN	A	172.16.11.125
host126			IN	A	172.16.11.126
host127			IN	A	172.16.11.127
host128			IN	A	172.16.11.128
host129			IN	A	172.16.11.129
host130			IN	A	172.16.11.130
host131			IN	A	172.16.11.131
host132			IN	A	172.16.11.132
host133			IN	A	172.16.11.133
host134			IN	A	172.16.11.134
host135			IN	A	172.16.11.135
host136			IN	A	172.16.11.136
host137			IN	A	172.16.11.137
host138			IN	A	172.16.11.138
host139			IN	A	172.16.11.139
host140			IN	A	172.16.11.140
host141			IN	A	172.16.11.141
host142			IN	A	172.16.11.142
host143			IN	A	172.16.11.143
host144			IN	A	172.16.11.144
host145			IN	A	172.16.11.145
host146			IN	A	172.16.11.146
host147			IN	A	172.16.11.147
host148			IN	A	172.16.11.148
host149			IN	A	172.16.11.149
host150			IN	A	172.16.11.150
host151			IN	A	172.16.11.151
host152			IN	A	172.16.11.152
host153			IN	A	172.16.11.153
host154			IN	A	172.16.11.154
host155			IN	A	172.16.11.155
host156			IN	A	172.16.11.156
host157			IN	A	172.16.11.157
host158			IN	A	172.16.11.158
host159			IN	A	172.16.11.159
host160			IN	A	172.16.11.160
host161			IN	A	172.16.11.161
host162			IN	A	172.16.11.162
host163			IN	A	172.16.11.163
host164			IN	A	172.16.11.164
host165			IN	A	172.16.11.165
host166			IN	A	172.16.11.166
host167			IN	A	172.16.11.167
host168			IN	A	172.16.11.168
host169			IN	A	172.16.11.169
host170			IN	A	172.16.11.170
host171			IN	A	172.16.11.171
host172			IN	A	172.16.11.172
host173			IN	A	172.16.11.173
host174			IN	A	172.16.11.174
host175			IN	A	172.16.11.175
host176			IN	A	172.16.11.176
host177			IN	A	172.16.11.177
host178			IN	A	172.16.11.178
host179			IN	A	172.16.11.179
host180			IN	A	172.16.11.180
host181			IN	A	172.16.11.181
host182			IN	A	172.16.11.182
host183			IN	A	172.16.11.183
host184			IN	A	172.16.11.184
host185			IN	A	172.16.11.185
host186			IN	A	172.16.11.186
host187			IN	A	172.16.11.187
host188			IN	A	172.16.11.188
host189			IN	A	172.16.11.189
host190			IN	A	172.16.11.190
host191			IN	A	172.16.11.191
host172			IN	A	192.16.11.192
host193			IN	A	172.16.11.193
host194			IN	A	172.16.11.194
host195			IN	A	172.16.11.195
host196			IN	A	172.16.11.196
host197			IN	A	172.16.11.197
host198			IN	A	172.16.11.198
host199			IN	A	172.16.11.199
;host200		IN	A	172.16.11.200
;host201		IN	A	172.16.11.201
;host202		IN	A	172.16.11.202
;host203		IN	A	172.16.11.203
;host204		IN	A	172.16.11.204
;host205		IN	A	172.16.11.205
;host206		IN	A	172.16.11.206
;host207		IN	A	172.16.11.207
;host208		IN	A	172.16.11.208
;host209		IN	A	172.16.11.209
;host210		IN	A	172.16.11.210
;host211		IN	A	172.16.11.211
;host212		IN	A	172.16.11.212
;host213		IN	A	172.16.11.213
;host214		IN	A	172.16.11.214
host215			IN	A	172.16.11.215
host216			IN	A	172.16.11.216
host217			IN	A	172.16.11.217
host218			IN	A	172.16.11.218
host219			IN	A	172.16.11.219
host220			IN	A	172.16.11.220
host221			IN	A	172.16.11.221
host222			IN	A	172.16.11.222
host223			IN	A	172.16.11.223
host224			IN	A	172.16.11.224
host225			IN	A	172.16.11.225
host226			IN	A	172.16.11.226
host227			IN	A	172.16.11.227
host228			IN	A	172.16.11.228
host229			IN	A	172.16.11.229
host230			IN	A	172.16.11.230
host231			IN	A	172.16.11.231
host232			IN	A	172.16.11.232
host233			IN	A	172.16.11.233
host234			IN	A	172.16.11.234
host235			IN	A	172.16.11.235
host236			IN	A	172.16.11.236
host237			IN	A	172.16.11.237
host238			IN	A	172.16.11.238
host239			IN	A	172.16.11.239
host240			IN	A	172.16.11.240
host241			IN	A	172.16.11.241
host242			IN	A	172.16.11.242
host243			IN	A	172.16.11.243
host244			IN	A	172.16.11.244
host245			IN	A	172.16.11.245
host246			IN	A	172.16.11.246
host247			IN	A	172.16.11.247
host248			IN	A	172.16.11.248
host249			IN	A	172.16.11.249
host250			IN	A	172.16.11.250
host251			IN	A	172.16.11.251
host252			IN	A	172.16.11.252
host253			IN	A	172.16.11.253

rtr			IN	A	172.16.11.254
			IN	AAAA	2001:db8:1234:4011::1

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

; Plant1 is a delegated sub-zone (see plant1.example.com)

; Plant2 is a delegated sub-zone (delegated out of our perimeter)
