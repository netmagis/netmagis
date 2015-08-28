# Created by: Pierre David <pdagog@gmail.com>, Jean Benoit <jean@unistra.fr>
# $FreeBSD: head/net-mgmt/netmagis-servers/Makefile 391542 2015-07-08 02:25:27Z pgollucci $

PORTNAME=	netmagis
PKGNAMESUFFIX=	-servers

COMMENT=	Netmagis module for dhcp, bind and mail servers

RUN_DEPENDS=	netmagis-config:${PORTSDIR}/net-mgmt/netmagis-common

MASTERDIR=	${.CURDIR}/../netmagis-common

PKGMESSAGE=	${.CURDIR}/pkg-message
PLIST=		${.CURDIR}/pkg-plist

.include "${MASTERDIR}/Makefile"
