ARG VERSION
ARG DOCKERHUB_ID

FROM ${DOCKERHUB_ID}/presto-base:${VERSION}
LABEL maintainer="saj1th"

ADD etc /usr/local/presto/etc

RUN ls -laR /usr/local/presto/etc/

EXPOSE 8080

WORKDIR /usr/local/presto
ENTRYPOINT ["./scripts/presto.sh"]
