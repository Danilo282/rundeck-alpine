FROM openjdk:8u171-jre-alpine as basic

LABEL maintainer "Hugo Fonseca <https://github.com/hugomcfonseca>"

ENV RDECK_VERSION=2.11.4 \
    RDECK_BASE=/var/lib/rundeck \
    RDECK_CONFIG=/etc/rundeck

COPY etc/rundeck/ /etc/rundeck/
COPY scripts/ ${RDECK_BASE}/scripts/

RUN PKGS="bash ca-certificates openssh-client"; apk add --update --no-cache ${PKGS} \
    && wget -qO ${RDECK_BASE}/rundeck.jar http://download.rundeck.org/jar/rundeck-launcher-${RDECK_VERSION}.jar \
    && echo -n "2bdac79aa28938b847266275b807ca031838830d *${RDECK_BASE}/rundeck.jar"| sha1sum -c - \
    && java -jar ${RDECK_BASE}/rundeck.jar --installonly -b ${RDECK_BASE} -c ${RDECK_CONFIG} \
    && mkdir -v -p "${RDECK_CONFIG}"/ssl  "${RDECK_CONFIG}"/keys "${RDECK_CONFIG}"/projects \
    && echo "Creating Rundeck user and group..." && addgroup rundeck && adduser -h ${RDECK_BASE} -D -s /bin/bash -G rundeck rundeck \
    && chmod -R u+x ${RDECK_BASE}/scripts/ \
    && rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

WORKDIR ${RDECK_BASE}

VOLUME [ "${RDECK_BASE}", "${RDECK_CONFIG}" ]

EXPOSE 4440 4443

FROM basic as templated

ENV \
    RDECK_KEYS_STORAGE_TYPE="db" \
    RDECK_PROJECT_STORAGE_TYPE="db" \
    RDECK_SSL_ENABLED="true" \
    RDECK_HOST="localhost" \
    RDECK_PORT=4440 \
    RDECK_URL="localhost:4440" \
    RDECK_THREADS_COUNT=10 \
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

ENV CONFD_VERSION=0.16.0 \
    CONFD_OPTS=-backend=env

COPY etc/confd /etc/confd/

RUN wget -qO /usr/local/bin/confd https://github.com/kelseyhightower/confd/releases/download/v${CONFD_VERSION}/confd-${CONFD_VERSION}-linux-amd64 \
    && chmod u+x /usr/local/bin/confd

FROM templated as production

ENV MYSQL_CONN_VERSION=8.0.11

COPY etc/supervisor /etc/supervisor/

RUN PKGS="curl jq python2 py-requests supervisor>=3.3.3"; apk add --update --no-cache ${PKGS} \
    && DEPS="py2-pip"; apk add --update --no-cache --virtual .deps ${DEPS} \
    && PIP_PKGS="pip wheel mysql-connector-python==${MYSQL_CONN_VERSION}"; pip install --upgrade ${PIP_PKGS} \
    && rm /etc/supervisord.conf \
    && ln -s /etc/supervisor/supervisord.conf /etc/supervisord.conf \
    && apk del .deps \
    && rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

CMD ${RDECK_BASE}/scripts/run_confd_templates.sh \
    && confd ${CONFD_OPTS} -onetime \
    && exec supervisord -n -c /etc/supervisor/supervisord.conf
