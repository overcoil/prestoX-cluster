ARG VERSION

FROM saj1th/presto-base:${VERSION}
LABEL maintainer="saj1th"

COPY etc /usr/local/presto/etc
EXPOSE 8081

WORKDIR /usr/local/presto
ENTRYPOINT [ "./scripts/presto.sh" ]
