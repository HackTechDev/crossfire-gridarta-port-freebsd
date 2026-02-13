PORTNAME=	gridarta
DISTVERSION=	20260211
CATEGORIES=	games java

MASTER_SITES=	# none (custom fetch)
COMMIT=		50fae5
DISTNAME=	${PORTNAME}-${COMMIT}
DISTFILES=	${DISTNAME}.tar.gz

MAINTAINER=	lesanglierdesardennes@gmail.com
COMMENT=	Map editor for Atrinik/Crossfire/Daimonin (Gridarta)
WWW=		https://sourceforge.net/projects/gridarta/

LICENSE=	GPLv2

FETCH_DEPENDS=	git:devel/git
BUILD_DEPENDS=	gradle5:devel/gradle5

USES=		java
JAVA_VERSION=	8

NO_ARCH=	yes

JARDIR=		${JAVASHAREDIR}/${PORTNAME}
REPODIR=	${JARDIR}/repo

WRKSRC=		${WRKDIR}/${DISTNAME}

GRADLE_USER_HOME=	${WRKDIR}/gradle-home
MAKE_ENV+=	GRADLE_USER_HOME=${GRADLE_USER_HOME}

do-fetch:
	@${MKDIR} ${DISTDIR}
	@if [ -f ${DISTDIR}/${DISTFILES} ]; then \
		${ECHO_MSG} "=> ${DISTFILES} already exists in ${DISTDIR}"; \
	else \
		${ECHO_MSG} "=> Fetching ${PORTNAME} from git (commit ${COMMIT})"; \
		${RM} -rf ${WRKDIR}/.gitfetch-${PORTNAME}; \
		${MKDIR} ${WRKDIR}/.gitfetch-${PORTNAME}; \
		cd ${WRKDIR}/.gitfetch-${PORTNAME} && \
			git clone --no-checkout https://git.code.sf.net/p/gridarta/gridarta ${PORTNAME} && \
			cd ${PORTNAME} && \
			git checkout -q ${COMMIT} && \
			git archive --format=tar --prefix=${DISTNAME}/ ${COMMIT} | \
				${GZIP_CMD} -n > ${DISTDIR}/${DISTFILES}; \
	fi

post-patch:
	# Gradle 5.0 ne supporte pas archiveBaseName -> baseName
	@${REINPLACE_CMD} 's/archiveBaseName/baseName/g' \
		${WRKSRC}/src/*/build.gradle

do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} gradle5 \
		--gradle-user-home ${GRADLE_USER_HOME} \
		--no-daemon \
		jar

do-install:
	@${MKDIR} ${STAGEDIR}${JAVASHAREDIR}/${PORTNAME}
	@${MKDIR} ${STAGEDIR}${JAVAJARDIR}

	@${MKDIR} ${STAGEDIR}${JARDIR}
	@${MKDIR} ${STAGEDIR}${REPODIR}

	cd ${WRKSRC} && ${FIND} src -path '*/build/libs/*.jar' -type f -print | \
		${XARGS} -J % ${INSTALL_DATA} % ${STAGEDIR}${JAVASHAREDIR}/${PORTNAME}/

	cd ${WRKSRC}/repo && \
		${FIND} . -type f -name '*.jar' ! -name '*-sources.jar' -print | \
		${CPIO} -pdmuv ${STAGEDIR}${REPODIR}

	# Wrappers
	${INSTALL_SCRIPT} ${FILESDIR}/gridarta-atrinik ${STAGEDIR}${PREFIX}/bin/gridarta-atrinik
	${INSTALL_SCRIPT} ${FILESDIR}/gridarta-crossfire ${STAGEDIR}${PREFIX}/bin/gridarta-crossfire
	${INSTALL_SCRIPT} ${FILESDIR}/gridarta-daimonin ${STAGEDIR}${PREFIX}/bin/gridarta-daimonin

.include <bsd.port.mk>
