FROM openjdk:8u131-jre-alpine

LABEL maintainer "Hugo Fonseca <hugofonseca93@hotmail.com>"

ENV \
    DEPS="bash ca-certificates curl jq openssh-client py-mysqldb py-requests supervisor" \
    \
    RDECK_VERSION="2.10.0" \
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
    CONFD_OPTS="-backend=env -onetime"

# Copy artifacts
COPY scripts/ /var/lib/rundeck/scripts/
COPY rundeck-configs/. /etc/rundeck/
COPY etc/ /etc/

RUN \
    apk add --update --no-cache \
        $DEPS && \
    echo "Downloading Rundeck..." && curl -k -L -s http://download.rundeck.org/jar/rundeck-launcher-${RDECK_VERSION}.jar -o ${RDECK_BASE}/rundeck.jar && \
    echo "Verifying Rundeck download..." && echo "3ab683a614d22af0338b8b5194a3e07105d3979d *${RDECK_BASE}/rundeck.jar"| sha1sum -c - && \
    echo "Installing Rundeck..." && java -jar ${RDECK_BASE}/rundeck.jar --installonly -b ${RDECK_BASE} -c ${RDECK_CONFIG} && \
    echo "Downloading ConfD..." && curl -sSL https://github.com/kelseyhightower/confd/releases/download/v${CONFD_VERSION}/confd-${CONFD_VERSION}-linux-amd64 -o /tmp/confd-${CONFD_VERSION}-linux-amd64 && \
    mv /tmp/confd-${CONFD_VERSION}-linux-amd64 /bin/confd && chmod a+x /bin/confd && \
    rm /etc/supervisord.conf && ln -s /etc/supervisor/supervisord.conf /etc/supervisord.conf && \
    echo "Creating Rundeck user and group..." && addgroup rundeck && adduser -h ${RDECK_BASE} -D -s /bin/bash -G rundeck rundeck && \
    mkdir -v -p "${RDECK_CONFIG}"/ssl  "${RDECK_CONFIG}"/keys "${RDECK_CONFIG}"/projects && \
    echo "Changing ownership and permissions..." && chmod -R +x /var/lib/rundeck/scripts/ && \
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

WORKDIR ${RDECK_BASE}

VOLUME [ "${RDECK_BASE}", "${RDECK_CONFIG}" ]

EXPOSE 4440 4443

CMD \
    /var/lib/rundeck/scripts/run_confd_templates.sh && \
    exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf