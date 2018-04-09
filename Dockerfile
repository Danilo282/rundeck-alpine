FROM openjdk:8u151-jre-alpine as basic

LABEL maintainer "Hugo Fonseca <https://github.com/hugomcfonseca>"

ENV RD_VERSION=2.10.8 \
    RD_BASE=/var/lib/rundeck \
    RD_CONFIG=/etc/rundeck \
    MYSQL_CONN_VERSION=8.0.6

COPY etc/rundeck/ /etc/rundeck/
COPY scripts/ ${RD_BASE}/scripts/

RUN PKGS="bash ca-certificates openssh-client"; apk add --update --no-cache ${PKGS} \
    && wget -qO ${RD_BASE}/rundeck.jar http://download.rundeck.org/jar/rundeck-launcher-${RD_VERSION}.jar \
    && echo -n "0ce13b4473cf2889e7b02cc32b7688b1bf3ab71a *${RD_BASE}/rundeck.jar"| sha1sum -c - \
    && java -jar ${RD_BASE}/rundeck.jar --installonly -b ${RD_BASE} -c ${RD_CONFIG} \
    && mkdir -v -p "${RD_CONFIG}"/ssl  "${RD_CONFIG}"/keys "${RD_CONFIG}"/projects \
    && echo "Creating Rundeck user and group..." && addgroup rundeck && adduser -h ${RD_BASE} -D -s /bin/bash -G rundeck rundeck \
    && chmod u+x ${RD_BASE}/scripts/ \
    && rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

WORKDIR ${RD_BASE}

VOLUME [ "${RD_BASE}", "${RD_CONFIG}" ]

EXPOSE 4440 4443

FROM basic as templated

ENV \
    RD_KEYS_STORAGE_TYPE="db" \
    RD_PROJECT_STORAGE_TYPE="db" \
    RD_SSL_ENABLED="true" \
    RD_HOST="localhost" \
    RD_PORT=4440 \
    RD_URL="localhost:4440" \
    RD_THREADS_COUNT=10 \
    LOG_LEVEL="INFO" \
    ADMIN_USER="admin" \
    ADMIN_PASSWORD="adminadmin" \
    SSH_USER="rundeck" \
    PROJECT_NODES={} \
    PROJECT_DESCRIPTION="" \
    PROJECT_ORGANIZATION="" \
    \
    DATASOURCE_DBNAME="rundeck" \
    DATASOURCE_HOST="mysql-host" \
    DATASOURCE_PASSWORD="" \
    DATASOURCE_PORT="3306" \
    DATASOURCE_USER="rundeck" \
    \
    KEYS_PRIV_KEY="" \
    KEYS_PUB_KEY="" \
    \
    SSL_KEYSTORE_PASSWORD="" \
    SSL_KEY_PASSWORD="" \
    SSL_TRUSTSTORE_PASSWORD="" \
    \
    CONSOLE_LOGS="false"

ENV CONFD_VERSION=0.15.0 \
    CONFD_OPTS=-backend=env

COPY etc/confd /etc/confd/

RUN wget -qO /bin/confd https://github.com/kelseyhightower/confd/releases/download/v${CONFD_VERSION}/confd-${CONFD_VERSION}-linux-amd64 \
    && chmod u+x /bin/confd

FROM templated as production

COPY etc/supervisor /etc/supervisor/

RUN PKGS="curl jq python2 py-requests supervisor>=3.3.3"; apk add --update --no-cache ${PKGS} \
    && DEPS="py2-pip"; apk add --update --no-cache --virtual .deps ${DEPS} \
    && PIP_PKGS="pip wheel mysql-connector-python==${MYSQL_CONN_VERSION}"; pip install --upgrade ${PIP_PKGS} \
    && rm /etc/supervisord.conf && ln -s /etc/supervisor/supervisord.conf /etc/supervisord.conf \
    && rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

CMD ${RD_BASE}/scripts/run_confd_templates.sh \
    && confd ${CONFD_OPTS} -onetime \
    && exec supervisord -n -c /etc/supervisor/supervisord.conf
