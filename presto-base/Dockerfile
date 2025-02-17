#
# This docker image is for launching test purpose presto cluster.
#

FROM openjdk:11-slim
LABEL maintainer=${DOCKERHUB_ID}

ARG VERSION
ENV PRESTO_VERSION=${VERSION}
ENV PRESTO_HOME=/usr/local/presto
ENV BASE_URL=https://repo1.maven.org/maven2

# install dev tools
RUN apt-get update
RUN apt-get install -y \
    curl \
    tar \
    sudo \
    rsync \
    python \
    wget \
    python3-pip \
    python-dev \
    build-essential \
    uuid-runtime \
    less

RUN apt-get install -y  python-is-python3   

RUN pip3 install jinja2


ENV JAVA_HOME /usr/java/default
ENV PATH $PATH:$JAVA_HOME/bin

# Add presto-cli
WORKDIR /usr/local/bin
RUN wget -q ${BASE_URL}/com/facebook/presto/presto-cli/${PRESTO_VERSION}/presto-cli-${PRESTO_VERSION}-executable.jar
RUN chmod +x presto-cli-${PRESTO_VERSION}-executable.jar
RUN mv presto-cli-${PRESTO_VERSION}-executable.jar presto-cli

WORKDIR /usr/local
# ADD presto-server-${PRESTO_VERSION}.tar.gz /usr/local
RUN wget -q ${BASE_URL}/com/facebook/presto/presto-server/${PRESTO_VERSION}/presto-server-${PRESTO_VERSION}.tar.gz
RUN tar xvzf presto-server-${PRESTO_VERSION}.tar.gz -C /usr/local/
RUN ln -s /usr/local/presto-server-${PRESTO_VERSION} $PRESTO_HOME

ADD scripts ${PRESTO_HOME}/scripts

ADD deltatables ${PRESTO_HOME}/deltatables

# Create data dir
RUN mkdir -p $PRESTO_HOME/data
VOLUME ["$PRESTO_HOME/data"]
