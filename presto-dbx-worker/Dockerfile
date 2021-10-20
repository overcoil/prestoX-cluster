ARG VERSION
ARG DOCKERHUB_ID

FROM ${DOCKERHUB_ID}/presto-base:${VERSION}
LABEL maintainer="saj1th"

COPY etc /usr/local/presto/etc
EXPOSE 8081

WORKDIR /usr/local/presto
ENTRYPOINT [ "./scripts/presto.sh" ]
