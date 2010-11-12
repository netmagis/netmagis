DROP TABLE IF EXISTS topo.filemonitor, topo.vlan, topo.vlanmod ;

CREATE TABLE topo.filemonitor (
	path	TEXT,		-- path to file or directory
	date	TIMESTAMP (0)	-- last modification date
			    WITHOUT TIME ZONE
			    DEFAULT CURRENT_TIMESTAMP,

	PRIMARY KEY (path)
) ;

CREATE TABLE topo.vlan (
	vlanid	INT,		-- 1..4095
	descr	TEXT,		-- description
	voip	INT DEFAULT 0,	-- 1 if VoIP vlan, 0 if standard vlan

	PRIMARY KEY (vlanid)
) ;

GRANT ALL
    ON topo.filemonitor, topo.vlan
    TO dns, pda, jean ;

COPY topo.vlan (vlanid, descr) FROM stdin;
1	default
2	rch ulp dpt-info api
3	rch ulp curri
4	postes DI interne
5	interco fw postes DI
6	rch ulp observatoire
7	interco fw scd
8	rch ulp forum medecine
9	rch ulp forum medecine video
10	rch ulp isis
11	interco ulp ipcms
12	rch ulp medecine nucleaire
13	rch ulp scd dmz
14	crous arcona visconti
15	rch ulp ifare
16	rch ulp iut nord
17	rch ulp ecpm
18	toip
19	rch umb misha
20	rch ulp hemato
21	formation crc
22	umb bornes acces libre
23	umb palais-u salle ufr arts
24	rch ulp ics
25	rch ulp incub chimie2 libre
26	rch ulp incub tic3 2fy
27	rch ulp semia
28	rch ulp imfs
29	rch ulp incub tic2 libre
30	rch ulp incub chimie 3 ixelis
31	ens ulp maitrise physique
32	rch ulp eost
33	rch ulp irma
34	pfsync fw umb
35	umb imprimerie
36	umb dmz
37	umb gestion serveurs
38	umb sicd
39	rch ulp physique
40	rch ulp musee sismologie
41	scd postes pro
42	inserm adr 16
43	bnus
44	rch ulp ipst
45	interco misha
46	iufm vpn
47	cnrs dr 10
48	interco ulp neurochimie
49	rch ulp zoologie
50	umb salles etudiants
51	efs
52	rch urs iut sud
53	rch urs iut sud dpt-info
54	rch ulp geologie
55	efs hautepierre
56	vpn/wifi lab ibmp
57	rch urs pege
58	rch ulp pharma
59	rch ulp incub phosylab
60	ens ulp pharma
61	interco ulp umr7034
62	rch ulp incub tic1
63	rch ulp lebel bas
64	CDE logements
65	rch ulp ibmc
66	archi enseignement
67	archi administration
68	engees
70	interco ulp image et ville
71	rch ulp geographie
72	rch ulp lsiit
73	ens ulp ensps
74	ens ulp master info sec
75	rch ulp sertit
76	rch ulp ensps 1
77	rch ulp ensps 2
78	rch ulp igbmc prive
79	rch ulp esbs
80	rch ulp icps calculateur
81	rch ulp plateau bio
82	interco ulp igbmc
83	rch ulp psycho
84	rch ulp icps
85	rch insa 1
86	rch insa 2
88	rch ulp suas
89	iufm 141 interco
90	rch ulp multimedia
91	rch ulp ibmp
92	rch ulp ibmp bota
93	isu interco
94	rch ulp prive imfs
95	rch ulp ipcb
96	rch ulp zoologie new
97	rch umb (130.79.162.0/23)
98	rch umb (130.79.164.0/23)
99	umb interco
100	dpt-info rch ext
101	dpt-info ens ext
103	rch ulp ipb
105	rch ulp medecine bat 2 old
106	rch ulp primato
107	rch ulp maison du japon
108	rch ulp ircad
109	rch ulp medecine bat 3
110	rch ulp medecine bat 4
111	umb sauvegarde temp (prive)
112	rch ulp suas club de plongee
113	rch ulp chir a
114	rch ulp medical a
115	rch ulp dentaire
116	umb bornes acces libre patio
117	rch ulp amicale dentaire
118	interco iphc
119	mgt eq ATM Alactel
120	crous adm interco
121	rch ulp medb anapat clovis neuro
122	rch ulp psychiatrie
123	rch umb (130.79.160.0/23)
124	rectorat interco
125	rch ulp biblio chu et imagerie
126	umb invites (prive)
127	rch ulp incub chimie1 oncophyt
128	rch ulp incub chimie4 systems vi
129	cnrs sires
130	cnrs dr10
131	rch ulp microbio
132	ena prive archive
133	ena prive archive management
134	ena prive voip
135	rch ulp parodonto
136	cnrs xlab api
137	vpn-default
138	vpn/wifi lab+ DI
139	interco labou + pabx
141	interco ena
142	rch kfet lebel
143	rch curri lebel
144	univ-r espla
145	univ-r histo
146	univ-r hus
147	univ-r illkirch
148	ulp pole badge
149	rch ulp dermato
150	rch ulp ophtalmo
151	bnus wifi lecteurs
152	rch ulp orl
153	rch ulp anapath
154	rch ulp clovis vincent
155	rch ulp neurologie
156	rch ulp medical b
157	rch ulp poincare
158	rch ulp chir b
159	rch ulp lab med b
160	ens ulp master info
161	umb spiral (prive)
162	ulp prive gestion barriere secu
163	rch ulp srnu
164	crous cite flamboyants
165	iufm migration tmp
166	crous cite paul appell 1
167	crous cite paul appell 2
168	crous cite gallia
169	crous cite somme
170	crous cite cattleyas
171	crous cite weiss
172	crous cite heliotropes
173	crous cite robertsau
174	crous cite agapanthes
175	interco san imotep
176	rch ulp medecine bat 2
177	rch ulp prive med automates av
178	ena prive imprimante
179	rch umb prive mgt
180	rch umb prive gtb
181	rch umb prive toip
182	interco rarest2 - renater
183	interco rarest - rarest2
184	rch iut haguenau
185	rch uds reseau nomade
186	interco rarest <-> man colmar
187	interco rarest <-> uha mulhouse
188	di pedago br1
189	di pedago br2
190	di pedago prive 1
191	CDE recherche
192	CDE commun
193	CDE video
194	di pedago prive 2
195	uds rch iut sud portable
196	dpt-info rch int
197	dpt-info ens int
198	dpt-info ens T20 int
199	dpt-info ens T21 int
200	dpt-info ens amicales int
201	dpt-info TX
202	SFC Meinau - restaurant
208	tst openvpn serveur
209	tst openvpn client1
210	tst openvpn client2
211	test vpn wifi
212	interco portail captif wifi
213	curri interne serveurs
214	ulp pole adm
215	ulp pole rch
216	syndicat 1 - sncs
217	syndicat 2 - snirs
218	syndicat 3 - cfdt
219	syndicat 4 - snesup
220	syndicat 5 - cgt
221	syndicat 6 - fo
222	syndicat 7 - unsa
223	syndicats - salle reunion
226	interco hus
227	iufm prive meinau info
228	iufm prive meinau peda
229	iufm prive meinau camera
230	iufm prive meinau videoproj
231	iufm prive meinau borne affichag
232	iufm prive meinau video
233	iufm prive meinau imprimantes
234	ens ulp pege
235	adm siig etbac ulp
236	crih-efs prive
237	rch urs iut sud dpt-info 2
238	rch ulp anapath new
239	di-parc bac a sable
240	uds dun
241	mastere imfs eahp prive
242	osiris sur parsec
243	di-parc atelier
244	dpt-info API - interco firewall
245	simps libre acces
246	dsp impression srv
247	dsp impression copieur
248	dsp impression vpn
249	TPE CMS
250	PCBIS UMS 3286
251	prive urs-srv-image1
666	vpls-test
667	netflow-test
700	interco crc-rc1 <--> renater
702	interco crc-rc1 <--> belwue
703	interco crc-rc1 <--> espla-rc1
756	synchro-pcap-wifi
757	inserm U977
758	inserm U666F (Fac de medecine)
759	console hmc 327
760	sogo memcahe
761	inserm Haute-Dispo Firewall
762	inserm U666H (hopital)
763	inserm LGM (EA3949)
764	prive medecine retransmission co
765	test migration o3
766	di sync lb serveurs applis
767	di serveurs applis
768	rch insa 3
769	crous mulhouse
770	inserm virologie (U748)
771	inserm hautepierre (U682)
772	cnrs prive san
773	ipst-interne
776	dpi gtb gtc controle acces
777	dpi gtb gtc video
781	dpi gtb gtc2
783	pfsync lb3-lb4
784	sogo backend
785	dladl cral
786	dladl atelier
787	vpn-lab+ adr 16
788	adr 16 stockage
789	scd postes publics new
790	scd formation
791	toip uds tel misha
792	toip uds tel umb
793	Prise eth Amphi
794	vpn-lab+ obs
795	ldap composante load-balance
796	toip uds tel illkirch
797	toip uds tel histo
798	toip uds tel espla
799	toip uds serveur
800	management reseau
801	serveurs DI
802	di+dpi gtb onduleurs
803	management telephone
804	adm ulp histo + med
805	adm ulp lebel
806	adm ulp nord
807	adm ulp sud
808	adm umb (130.79.166.0/23)
809	adm urs 1 (130.79.234/23)
810	adm urs 2 (130.79.236.0/23)
811	management wifi ap
812	cnrs - medecine du travail
813	neurochem prive + vpn/wifi lab+
814	rch urs (130.79.186/23)
815	ens urs 2 (130.79.26/23)
816	ens urs 1 (130.79.24/23)
817	VLAN0817
818	pfsync portcap wifi
819	vpn/wifi lab+ eost
820	ens ulp ulpmm serveurs univ-r
821	management cg poe
822	rch umb (130.79.140.0/23)
823	vpn/wifi lab siig soc ext
824	pfsync firewall adm
825	interco fw adm
826	siig adm
827	siig dmz
828	crous adm
829	rch umn misha new
830	crous auth
831	dpt-info san
832	vpn/wifi lab neurochimie
833	vpn-lab+ ircad4
834	rectorat prive crdp
835	rectorat crdp
836	rectorat
837	crous univ-r
838	dpi gtb baes
839	dpi gtb gtc1
840	rch urs dmz
841	rch urs serveurs internes
842	rectorat ia67
843	interco urs
844	rch ulp bota
845	rch ulp ecpm interne
846	rch ulp chimie lebel haut
847	rch ulp chimie
848	vpn-lab+ physique
849	vpn/wifi lab+ ipcms int
850	ircad prive san
851	vpn-lab+ isis
852	vpn-lab+ ircad1
853	vpn-lab+ ircad2
854	vpn-lab+ hemato
855	vpn-lab geologie adm sys
856	vpn-lab inserm 575
857	vpn/wifi lab+ iut sud dpt-info
858	vpn-lab+ ensps ens
859	rch ulp pege
860	vpn-lab+ ircad3
861	ulpmm amphis
862	public_urs
863	rch ulp linc
864	vpn-lab+ umb
865	vpn-lab geologie usr
866	vpn/wifi lab adm ulp
867	vpn-lab siig usr
868	vpn-lab siig adm sys
869	vpn-lab+ igbmc
870	vpn-lab+ psycho linc
871	vpn-lab+ pharmaco umr 7034
872	iufm prive backup
873	adm uds
874	iufm prive telephonie
875	pfsync satis
876	rch ulp prive med monitoring
877	crous libre service
878	dpi gtb serveurs
879	vpn serveurs synchro
880	scd postes publics old
881	sauvegardes curri - ircad
882	dpt-info ens portable/vpn-lab+ i
883	wifi-lab adm imp
884	prive-expertise-recherche
885	vpn-lab dli
886	vpn/wifi lab+ ipcms ext
887	vpn-lab ics
888	san netapp di
889	rch ulp linc interne
890	mgt san
891	san crc
892	san curri
893	san ulpmm
894	pfsync fw insa
895	interco fw insa
896	vpn-lab umb adm
897	postes carte multiservices uha
898	san siig
899	vpn/wifi lab+ ipst
900	wifi ssid osiris
901	wifi-osiris-lab
902	wifi-osiris-sec
903	di maquettes infra
950	annuaire load-balance
951	dns load-balance
952	ipcms serveurs
953	adm insa
954	gestion insa
955	vpn-lab irma
956	vpn-lab+ master info
957	vpn-lab+ inserm u 682
958	adm ulp espla
959	adm iut haguenau
960	vpn-lab imfs
961	vpn adm enseignement recherche
962	rch ulp prive plateau bio
963	srv DI load-balancer
964	synchro pfsync lb
966	rectorat prive net-zcp-mdp
967	rectorat prive net-voip-mdp
968	iufm prive neudorf admin
969	iufm prive neudorf peda
970	iufm prive neudorf imprimantes
971	iufm prive selestat admin
972	iufm prive selestat peda
973	iufm prive selestat imprimantes
974	iufm prive guebwiller admin
975	iufm prive guebwiller peda
976	iufm prive guebwiller imprimante
977	iufm prive guebwiller cddp
978	iufm prive colmar admin
979	iufm prive colmar peda
980	iufm prive colmar imprimantes
981	adm new insa
982	DI serveurs windows
983	DI hebergement web interne
984	vpn-lab iut-nord
985	uha prive test
986	uha voip
988	cnrs sires 1
989	cnrs sires 2
990	vpn-lab esbs
991	vpn/wifi lab ibmc
992	iufm prive dmz interne
993	iufm prive dmz externe
994	iufm prive meinau admin
995	iufm prive scd/carel
996	wifi-lab lsiit
997	osiris3 tests
999	remote span
3000	VLAN3000
\.

CREATE OR REPLACE FUNCTION modif_vlan () RETURNS trigger AS $$
    BEGIN
	INSERT INTO topo.modeq (eq) VALUES ('_vlan') ;
	RETURN NEW ;
    END ;
    $$ LANGUAGE 'plpgsql' ;

CREATE TRIGGER tr_mod_vlan
    AFTER INSERT OR UPDATE OR DELETE
    ON topo.vlan
    FOR EACH ROW
    EXECUTE PROCEDURE modif_vlan () ;
