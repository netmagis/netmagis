# New ports collection makefile for:	PostgreSQL
# Date created:		November 13, 1998
# Whom:			Marc G. Fournier <scrappy@FreeBSD.org>
#
# $FreeBSD: ports/databases/postgresql91-server/Makefile,v 1.231 2011/10/20 21:07:29 crees Exp $
#

PORTNAME?=	netmagis
DISTVERSION?=	2.0b1
PORTREVISION?=	1
CATEGORIES?=	net-mgmt
MASTER_SITES=	XXXX
MASTER_SITE_SUBDIR=	XXXX
PKGNAMESUFFIX?=	-common

MAINTAINER?=	girgen@FreeBSD.org
COMMENT?=	The most advanced open-source network management system available anywhere

USE_TCL=	85+

USE_PGSQL=	yes
WANT_PGSQL_VER=	91

RUN_DEPENDS+=	dtplite:${PORTSDIR}/devel/tcllib \
		${LOCALBASE}/lib/pgtcl/pkgIndex.tcl:${PORTSDIR}/databases/pgtcl

.if $(PKGNAMESUFFIX) != "-common"
RUN_DEPENDS+=	netmagis-config:${PORTSDIR}/net-mgmt/netmagis-common
.endif

.if $(PKGNAMESUFFIX) == "-database"
RUN_DEPENDS+=	postmaster:${PORTSDIR}/databases/postgresql${PGSQL_VER}-server \
		pltcl_listmod:${PORTSDIR}/databases/postgresql-pltcl \
		pwgen:${PORTSDIR}/sysutils/pwgen2
.endif

.if $(PKGNAMESUFFIX) == "-www"
USE_APACHE=	2.2+
RUN_DEPENDS+=	pdflatex:${PORTSDIR}/print/teTeX-base \
		dot:${PORTSDIR}/graphics/graphviz \
		pwgen:${PORTSDIR}/sysutils/pwgen2 \
		/usr/local/libexec/apache22/mod_auth_pgsql.so:${PORTSDIR}/www/mod_auth_pgsql2/
# FIXME compile apache22 with option mod_auth_ldap
# FIXME add ap22-mod_auth_cas
.endif

.if $(PKGNAMESUFFIX) == "-topo"
RUN_DEPENDS+=	rancid-run:${PORTSDIR}/net-mgmt/rancid \
		fping:${PORTSDIR}/net/fping
.endif


##############################################################################
#WRKSRC=		${WRKDIR}/netmagis-${DISTVERSION}
#DIST_SUBDIR=	postgresql
#
#UNIQUENAME?=	${PORTNAME}91
#LATEST_LINK?=	${PKGNAMEPREFIX}${UNIQUENAME}${PKGNAMESUFFIX}
#
#PKGINSTALL?=	${PKGDIR}/pkg-install${PKGNAMESUFFIX}
#
#PG_USER?=	pgsql
#PG_GROUP?=	${PG_USER}
#PG_UID?=	70
#
##############################################################################


post-install:
	@if [ -f $(PKGMESSAGE) ] ; then $(CAT) $(PKGMESSAGE) ; fi

.include <bsd.port.mk>

# Variables used in netmagis Makefiles
MAKE_ARGS+=	DESTDIR=$(PREFIX)
MAKE_ARGS+=	TCLSH=$(TCLSH) TCLCONF=$(TCL_LIBDIR)/tclConfig.sh

.if $(PKGNAMESUFFIX) == "-topo" || $(PKGNAMESUFFIX) == "-www"
ALL_TARGET=all$(PKGNAMESUFFIX?=)
.else
ALL_TARGET=nothing
.endif

INSTALL_TARGET=	install$(PKGNAMESUFFIX)
