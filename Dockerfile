FROM maven:3-jdk-11 as maven
FROM docker:stable as docker
FROM flyway/flyway:7-alpine as flyway

FROM ubuntu:20.04

#TERM=xterm provides nice colors and symbols
ENV TERM=xterm \
  LANG=C.UTF-8 \
  JAVA_HOME=/opt/java \
  MAVEN_HOME=/opt/maven \
  FLUTTER_HOME=/opt/flutter \
  FLUTTER_ROOT=/opt/flutter \
  PATH=$PATH:/opt/java/bin:/opt/maven/bin:/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin \
  JAVA_TOOL_OPTIONS="-XX:+UseContainerSupport" \
  DEBIAN_FRONTEND=noninteractive \
  DBUS_SESSION_BUS_ADDRESS=/dev/null \
  npm_config_loglevel=warn \
  npm_config_unsafe_perm=true \
  RUNNER_ALLOW_RUNASROOT=1

RUN apt-get update && apt-get upgrade -y
#telnet procps and python3-pip are required for aws cli
RUN apt-get install -y bash git vim wget curl ca-certificates less groff jq openssh-client telnet procps python3-pip \
  iputils-ping libxss1 gnupg postgresql-client zip unzip

# now that we have python and pip install, use them to upgrade pip
RUN pip3 install --upgrade pip

# now install aws cli v2
# uname -m returns whether we're on x86_64 or aarch64
RUN mkdir -p /tmp/awsv2 && \
  curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "/tmp/awsv2/awscliv2.zip" && \
  cd /tmp/awsv2 && \
  unzip ./awscliv2.zip && \
  chmod +x ./aws/install && \
  ./aws/install && \
  cd / && \
  rm -rf /tmp/awsv2

RUN rm -f /bin/sh && ln -s /bin/bash /bin/sh
RUN mkdir -p /work
WORKDIR /work

COPY --from=docker /usr/local/bin/docker /usr/local/bin/docker
COPY --from=maven /usr/share/maven /opt/maven
COPY --from=maven /usr/local/openjdk-11 /opt/java
COPY --from=flyway /flyway /flyway

# disabling installation of google-chrome sources, since it's not available on arm
# RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
#  echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list
# RUN apt-get update && apt-get install google-chrome-stable

# setup nodejs sources
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
# install xvfb, and nodejs
RUN apt-get update && apt-get install -y libgconf-2-4 xvfb nodejs
# upgrade npm and added required global libraries
RUN npm install --upgrade --global npm && npm install --upgrade --global @vue/cli

# install docker-compose
RUN curl -L "https://github.com/docker/compose/releases/download/1.28.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose
    
# install flutter
RUN mkdir -p /opt/flutter && git clone --depth 1 --branch 'stable' https://github.com/flutter/flutter.git /opt/flutter && flutter --version && flutter doctor
