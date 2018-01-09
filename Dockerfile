FROM openjdk:8u151-jre-alpine

LABEL maintainer "Hugo Fonseca <hugofonseca93@hotmail.com>"

ENV \
    DEPS="py-pip" \
    PKGS="bash ca-certificates curl jq openssh-client py-requests supervisor" \
    MYSQL_CONN_VERSION="2.1.7" \
    \
    RDECK_VERSION="2.10.2" \
    RDECK_BASE="/var/lib/rundeck" \
    RDECK_CONFIG="/etc/rundeck" \
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
    CONSOLE_LOGS="false" \
    \
    CONFD_VERSION="0.14.0" \
    CONFD_OPTS="-backend=env"

# Copy artifacts
COPY scripts/ ${RDECK_BASE}/scripts/
COPY etc/ /etc/

RUN apk add --update --no-cache --virtual .deps $DEPS \
        && apk add --update --no-cache $PKGS \
        && pip install --upgrade pip wheel \
        && pip install http://dev.mysql.com/get/Downloads/Connector-Python/mysql-connector-python-${MYSQL_CONN_VERSION}.tar.gz \
        && echo "Downloading Rundeck..." && curl -skLo ${RDECK_BASE}/rundeck.jar http://download.rundeck.org/jar/rundeck-launcher-${RDECK_VERSION}.jar \
        && echo "Verifying Rundeck download..." && echo "cc1eba8868c6a9304b04c34a8ca2c7e572111929 *${RDECK_BASE}/rundeck.jar"| sha1sum -c - \
        && echo "Installing Rundeck..." && java -jar ${RDECK_BASE}/rundeck.jar --installonly -b ${RDECK_BASE} -c ${RDECK_CONFIG} \
        && echo "Downloading ConfD..." && curl -skLo /tmp/confd-${CONFD_VERSION} https://github.com/kelseyhightower/confd/releases/download/v${CONFD_VERSION}/confd-${CONFD_VERSION}-linux-amd64 \
        && mv /tmp/confd-${CONFD_VERSION} /bin/confd && chmod a+x /bin/confd \
        && rm /etc/supervisord.conf && ln -s /etc/supervisor/supervisord.conf /etc/supervisord.conf \
        && echo "Creating Rundeck user and group..." && addgroup rundeck && adduser -h ${RDECK_BASE} -D -s /bin/bash -G rundeck rundeck \
        && mkdir -v -p "${RDECK_CONFIG}"/ssl  "${RDECK_CONFIG}"/keys "${RDECK_CONFIG}"/projects \
        && echo "Changing ownership and permissions..." && chmod -R +x ${RDECK_BASE}/scripts/ \
        && apk del .deps && rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

WORKDIR ${RDECK_BASE}

VOLUME [ "${RDECK_BASE}", "${RDECK_CONFIG}" ]

EXPOSE 4440 4443

CMD ${RDECK_BASE}/scripts/run_confd_templates.sh \
        && /bin/confd ${CONFD_OPTS} -onetime \
        && exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
