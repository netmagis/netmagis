# Created by: Pierre David <pdagog@gmail.com>, Jean Benoit <jean@unistra.fr>
# $FreeBSD: head/net-mgmt/netmagis-topo/Makefile 391542 2015-07-08 02:25:27Z pgollucci $

PORTNAME=	netmagis
PKGNAMESUFFIX=	-topo

COMMENT=	Netmagis topology module

RUN_DEPENDS=	netmagis-config:${PORTSDIR}/net-mgmt/netmagis-common \
		rancid-run:${PORTSDIR}/net-mgmt/rancid \
		fping:${PORTSDIR}/net/fping

USE_RC_SUBR=	topographd toposendd

MASTERDIR=	${.CURDIR}/../netmagis-common

FILESDIR=	${.CURDIR}/files
PKGMESSAGE=	${.CURDIR}/pkg-message
PLIST=		${.CURDIR}/pkg-plist

ALL_TARGET=build${PKGNAMESUFFIX?=}

post-stage:
	@${MKDIR} ${STAGEDIR}/var/netmagis/eqgen ${STAGEDIR}/var/netmagis/eqvirt

.include "${MASTERDIR}/Makefile"
