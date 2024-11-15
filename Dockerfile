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

# set Docker image build arguments
# build arguments for user/group configurations
ARG USER=wso2carbon
ARG USER_ID=802
ARG USER_GROUP=wso2
ARG USER_GROUP_ID=802
ARG USER_HOME=/home/${USER}
# build arguments for WSO2 product installation
ARG WSO2_SERVER_NAME=wso2is
ARG WSO2_SERVER_VERSION=7.0.0
ARG WSO2_SERVER_REPOSITORY=product-is
ARG WSO2_SERVER=${WSO2_SERVER_NAME}-${WSO2_SERVER_VERSION}
ARG WSO2_SERVER_HOME=${USER_HOME}/${WSO2_SERVER}
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

ENV ENV="/home/${USER}/.rc"

# create the non-root user and group and set MOTD login message
RUN \
    addgroup -S -g ${USER_GROUP_ID} ${USER_GROUP} \
    && adduser -S -u ${USER_ID} -h ${USER_HOME} -G ${USER_GROUP} ${USER} \
    && echo ${MOTD} > /home/${USER}/.rc \
    && chown ${USER}:${USER_GROUP} /home/${USER}/.rc

USER ${USER_ID}:${USER_GROUP}
# create Java prefs dir
# this is to avoid warning logs printed by FileSystemPreferences class
RUN \
    mkdir -p ${USER_HOME}/.java/.systemPrefs \
    && mkdir -p ${USER_HOME}/.java/.userPrefs \
    && chmod -R 755 ${USER_HOME}/.java \
    && chown -R ${USER}:${USER_GROUP} ${USER_HOME}/.java

# copy init script to user home
COPY --chown=${USER}:${USER_GROUP} docker-entrypoint.sh ${USER_HOME}/
COPY --from=unzipper --chown=${USER}:${USER_GROUP} ${WSO2_SERVER} ${USER_HOME}/${WSO2_SERVER}

# add MySQL JDBC connector to server home as a third party library
ADD --chown=${USER}:${USER_GROUP} https://repo1.maven.org/maven2/mysql/mysql-connector-java/${MYSQL_CONNECTOR_VERSION}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar ${WSO2_SERVER_HOME}/repository/components/dropins/

# Set the user and work directory.
WORKDIR ${USER_HOME}

# set environment variables
ENV JAVA_OPTS="-Djava.util.prefs.systemRoot=${USER_HOME}/.java -Djava.util.prefs.userRoot=${USER_HOME}" \
    WORKING_DIRECTORY=${USER_HOME} \
    WSO2_SERVER_HOME=${WSO2_SERVER_HOME}

# expose ports
EXPOSE 4000 9763 9443

# initiate container and start WSO2 Carbon server
ENTRYPOINT ["/home/wso2carbon/docker-entrypoint.sh"]