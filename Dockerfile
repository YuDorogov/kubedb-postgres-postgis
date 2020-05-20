FROM debian:stretch as builder

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

RUN set -x \
  && apt-get update \
  && apt-get install -y --no-install-recommends apt-transport-https ca-certificates curl unzip

RUN set -x                                                                                                                                              \
  && curl -fsSL -o pg-leader-election-binaries.zip https://github.com/kubedb/pg-leader-election/releases/download/v0.1.0/pg-leader-election-binaries.zip \
  && unzip pg-leader-election-binaries.zip                                                                                                              \
  && chmod 755 pg-leader-election-binaries/linux_amd64/pg-leader-election

RUN set -x                                                                                             \
  && curl -fsSL -o wal-g https://github.com/kubedb/wal-g/releases/download/0.2.13-ac/wal-g-alpine-amd64 \
  && chmod 755 wal-g

FROM postgres:11-alpine

LABEL maintainer="Dorogov Yury t288ap@gmail.com"

ENV PV /var/pv
ENV PGDATA $PV/data
ENV PGWAL $PGDATA/pg_wal
ENV INITDB /var/initdb
ENV WALG_D /etc/wal-g.d/env

COPY --from=builder /pg-leader-election-binaries/linux_amd64/pg-leader-election /usr/bin/
COPY --from=builder /wal-g /usr/bin/

COPY scripts /scripts

VOLUME ["$PV"]

ENV STANDBY warm
ENV RESTORE false
ENV BACKUP_NAME LATEST
ENV PITR false
ENV ARCHIVE_S3_PREFIX ""
ENV ARCHIVE_S3_ENDPOINT ""
ENV RESTORE_S3_PREFIX ""
ENV RESTORE_S3_ENDPOINT ""

ENV ARCHIVE_GS_PREFIX ""
ENV RESTORE_GS_PREFIX ""

ENV ARCHIVE_AZ_PREFIX ""
ENV RESTORE_AZ_PREFIX ""

ENV ARCHIVE_SWIFT_PREFIX ""
ENV RESTORE_SWIFT_PREFIX ""

ENV ARCHIVE_FILE_PREFIX ""
ENV RESTORE_FILE_PREFIX ""
ENV POSTGIS_VERSION 3.0.1
ENV POSTGIS_SHA256 5451a34c0b9d65580b3ae44e01fefc9e1f437f3329bde6de8fefde66d025e228

RUN set -ex \
    \
    && apk add --no-cache --virtual .fetch-deps \
        ca-certificates \
        openssl \
        tar \
    \
    && wget -O postgis.tar.gz "https://github.com/postgis/postgis/archive/$POSTGIS_VERSION.tar.gz" \
    && echo "$POSTGIS_SHA256 *postgis.tar.gz" | sha256sum -c - \
    && mkdir -p /usr/src/postgis \
    && tar \
        --extract \
        --file postgis.tar.gz \
        --directory /usr/src/postgis \
        --strip-components 1 \
    && rm postgis.tar.gz \
    \
    && apk add --no-cache --virtual .build-deps \
        autoconf \
        automake \
        file \
        json-c-dev \
        libtool \
        libxml2-dev \
        make \
        perl \
        clang-dev \
        g++ \
        gcc \
        gdal-dev \
        geos-dev \
        llvm9-dev \
        proj-dev \
        protobuf-c-dev \
    && cd /usr/src/postgis \
    && ./autogen.sh \
# configure options taken from:
# https://anonscm.debian.org/cgit/pkg-grass/postgis.git/tree/debian/rules?h=jessie
    && ./configure \
#       --with-gui \
    && make -j$(nproc) \
    && make install \
    && apk add --no-cache --virtual .postgis-rundeps \
        json-c \
        geos \
        gdal \
        proj \
        libstdc++ \
        protobuf-c \
    && cd / \
    && rm -rf /usr/src/postgis \
    && apk del .fetch-deps .build-deps

#COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/10_postgis.sh
#COPY ./update-postgis.sh /usr/local/bin

ENTRYPOINT ["pg-leader-election"]

EXPOSE 5432