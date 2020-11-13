FROM maven:3-jdk-11 as maven
FROM docker:stable as docker

FROM ubuntu:20.04

#TERM=xterm provides nice colors and/or symbols
ENV TERM=xterm \
  LANG=C.UTF-8 \
  JAVA_HOME=/opt/jdk11 \
  MAVEN_HOME=/opt/maven \
  PATH=$PATH:/opt/jdk11/bin:/opt/maven/bin \
  JAVA_TOOL_OPTIONS="-XX:+UseContainerSupport" \
  DEBIAN_FRONTEND=noninteractive \
  RUNNER_ALLOW_RUNASROOT=1

RUN apt-get update && apt-get upgrade -y
#telnet procps and python3-pip are required for aws cli
RUN apt-get install -y bash git vim wget curl ca-certificates less groff jq openssh-client telnet procps python3-pip iputils-ping

# now that we have python and pip install, use them to install the aws cli
RUN pip3 install --upgrade pip && pip install --upgrade awscli

RUN rm -f /bin/sh && ln -s /bin/bash /bin/sh
RUN mkdir -p /work
WORKDIR /work

COPY --from=docker /usr/local/bin/docker /usr/local/bin/docker
COPY --from=maven /usr/share/maven /opt/maven
COPY --from=maven /usr/local/openjdk-11 /opt/jdk11

# setup node
# "fake" dbus address to prevent errors
ENV DBUS_SESSION_BUS_ADDRESS=/dev/null
# a few environment variables to make NPM installs easier
ENV npm_config_loglevel warn
# allow installing when the main user is root
ENV npm_config_unsafe_perm true
RUN apt-get install -y gnupg
# install google-chrome sources
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
  echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list
# setup nodejs sources
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
# install xvfb, google-chrome and nodejs
RUN apt-get update && apt-get install -y libgconf-2-4 xvfb google-chrome-stable nodejs
# upgrade npm and added required global libraries
RUN npm install --upgrade --global npm && npm install --upgrade --global @vue/cli
