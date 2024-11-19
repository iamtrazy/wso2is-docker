# Stage 1: Download and unzip WSO2 idenntity server files
FROM alpine:latest AS unzipper
ARG WSO2_SERVER_NAME=wso2is
ARG WSO2_SERVER_VERSION=7.0.0
ARG WSO2_SERVER_REPOSITORY=product-is
ARG WSO2_SERVER=${WSO2_SERVER_NAME}-${WSO2_SERVER_VERSION}
# Hosted wso2is-7.0.0 distribution URL.
ARG WSO2_SERVER_DIST_URL=https://github.com/wso2/${WSO2_SERVER_REPOSITORY}/releases/download/v${WSO2_SERVER_VERSION}/${WSO2_SERVER}.zip

RUN apk add --no-cache unzip wget && \
    wget -O ${WSO2_SERVER}.zip "${WSO2_SERVER_DIST_URL}" && \
    unzip ${WSO2_SERVER}.zip

# set base Docker image to Liberica JRE 11 runtime
FROM bellsoft/liberica-runtime-container:jre-11.0.25-musl
LABEL maintainer="iamtrazy <iamtrazy@proton.me>"
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8' 

ENV JAVA_VERSION=jre-11.0.25

# build arguments for WSO2 product installation
ARG WSO2_SERVER_NAME=wso2is
ARG WSO2_SERVER_VERSION=7.0.0
ARG WSO2_SERVER_REPOSITORY=product-is
ARG WSO2_SERVER=${WSO2_SERVER_NAME}-${WSO2_SERVER_VERSION}
ARG WSO2_SERVER_HOME=/home/choreouser/${WSO2_SERVER}
# build arguments for external artifacts
ARG DNS_JAVA_VERSION=2.1.8
ARG MYSQL_CONNECTOR_VERSION=8.0.29
# build argument for MOTD
ARG MOTD='printf "\n\
    Welcome to WSO2 Docker Resources \n\
    --------------------------------- \n\
    This Docker container comprises of a WSO2 product, running with its latest GA release \n\
    which is under the Apache License, Version 2.0. \n\
    Read more about Apache License, Version 2.0 here @ http://www.apache.org/licenses/LICENSE-2.0.\n"'

ENV ENV="/home/choreouser/.ashrc"

# create the non-root user and group and set MOTD login message
RUN \
    addgroup -S -g 10014 choreo \
    && adduser -S -u 10014 -h /home/choreouser -G choreo choreouser \
    && echo ${MOTD} > ${ENV}

# switch to the non-root user and group for rest of the RUN tasks and change the workdir
USER 10014
WORKDIR /home/choreouser
# create Java prefs dir
# this is to avoid warning logs printed by FileSystemPreferences class
RUN \
    mkdir -p ~/.java/.systemPrefs \
    && mkdir -p ~/.java/.userPrefs \
    && chmod -R 755 ~/.java \
    && chown -R choreouser:choreo ~/.java

COPY --from=unzipper --chown=choreouser:choreo ${WSO2_SERVER} /home/choreouser/${WSO2_SERVER}

# add MySQL JDBC connector to server home as a third party library
ADD --chown=choreouser:choreo https://repo1.maven.org/maven2/mysql/mysql-connector-java/${MYSQL_CONNECTOR_VERSION}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar ${WSO2_SERVER_HOME}/repository/components/dropins/

# set environment variables
ENV JAVA_OPTS="-Xms128m -Xmx128m -Djava.util.prefs.systemRoot=/home/choreouser/.java -Djava.util.prefs.userRoot=/home/choreouser" \
    WORKING_DIRECTORY=/home/choreouser \
    WSO2_SERVER_HOME=${WSO2_SERVER_HOME}

# copy init script to user home
COPY --chown=choreouser:choreo docker-entrypoint.sh /home/choreouser/
RUN chmod 755 /home/choreouser/docker-entrypoint.sh

# expose ports
EXPOSE 4000 9763 9443

# initiate container and start WSO2 Carbon server
ENTRYPOINT ["/home/choreouser/docker-entrypoint.sh"]
