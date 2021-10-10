ARG VERSION

FROM saj1th/presto-base:${VERSION}
LABEL maintainer="saj1th"

ADD etc /usr/local/presto/etc

EXPOSE 8080

WORKDIR /usr/local/presto
ENTRYPOINT ["./scripts/presto.sh"]
